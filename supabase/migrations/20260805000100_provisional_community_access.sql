begin;

create table public.community_feed_posts (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete restrict,
  title text not null check (
    title = btrim(title)
    and char_length(title) between 2 and 160
    and title !~ '[[:cntrl:]]'
  ),
  body text not null check (
    body = btrim(body)
    and char_length(body) between 1 and 4000
    and body !~ '[[:cntrl:]]'
  ),
  published_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint community_feed_expiry_valid check (
    expires_at is null or expires_at > published_at
  )
);

create index community_feed_scope_order_idx
on public.community_feed_posts (institution_id, published_at desc, id desc);

create table public.faculty_contact_threads (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  faculty_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint faculty_contact_distinct_people check (
    student_user_id <> faculty_user_id
  ),
  unique (institution_id, student_user_id, faculty_user_id)
);

create index faculty_contact_student_idx
on public.faculty_contact_threads (student_user_id, institution_id, updated_at desc);

create index faculty_contact_faculty_idx
on public.faculty_contact_threads (faculty_user_id, institution_id, updated_at desc);

create trigger faculty_contact_threads_set_updated_at
before update on public.faculty_contact_threads
for each row execute function public.set_updated_at();

create table public.faculty_contact_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.faculty_contact_threads(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  client_message_id uuid not null,
  body text not null check (
    body = btrim(body)
    and char_length(body) between 1 and 2000
    and body !~ '[[:cntrl:]]'
  ),
  sent_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '180 days'),
  constraint faculty_message_expiry_valid check (expires_at > sent_at),
  unique (sender_user_id, client_message_id)
);

create index faculty_contact_messages_thread_order_idx
on public.faculty_contact_messages (thread_id, sent_at, id);

alter table public.community_feed_posts enable row level security;
alter table public.faculty_contact_threads enable row level security;
alter table public.faculty_contact_messages enable row level security;

revoke all on table public.community_feed_posts
from public, anon, authenticated, service_role;
revoke all on table public.faculty_contact_threads
from public, anon, authenticated, service_role;
revoke all on table public.faculty_contact_messages
from public, anon, authenticated, service_role;

create or replace function private.has_community_access(
  target_institution_id uuid,
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.institution_memberships membership
    join public.institutions institution_record
      on institution_record.id = membership.institution_id
    where membership.institution_id = target_institution_id
      and membership.user_id = target_user_id
      and membership.status = 'active'
      and institution_record.is_active
  ) or exists (
    select 1
    from public.student_affiliation_requests request_record
    join public.institutions institution_record
      on institution_record.id = request_record.institution_id
    where request_record.institution_id = target_institution_id
      and request_record.user_id = target_user_id
      and request_record.status in ('pending', 'approved')
      and institution_record.is_active
  );
$$;

create or replace function private.has_active_role(
  target_institution_id uuid,
  target_user_id uuid,
  target_role_key text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.institution_memberships membership
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record on role_record.id = membership_role.role_id
    where membership.institution_id = target_institution_id
      and membership.user_id = target_user_id
      and membership.status = 'active'
      and role_record.key = target_role_key
  );
$$;

create or replace function private.resolve_community_institution(
  target_institution_id uuid,
  target_user_id uuid
)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  resolved_id uuid;
begin
  if target_institution_id is not null then
    if private.has_community_access(target_institution_id, target_user_id) then
      return target_institution_id;
    end if;
    raise exception using
      errcode = '42501',
      message = 'Community access is not available for this institution.';
  end if;

  select request_record.institution_id
  into resolved_id
  from public.student_affiliation_requests request_record
  where request_record.user_id = target_user_id
    and request_record.status = 'pending'
  order by request_record.updated_at desc, request_record.id
  limit 1;

  if resolved_id is null then
    raise exception using
      errcode = '42501',
      message = 'Choose an active campus before opening Community.';
  end if;
  return resolved_id;
end;
$$;

create or replace function public.get_my_community_overview(
  target_institution_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  resolved_institution_id uuid;
  institution_name text;
  is_faculty boolean;
  access_state text;
  feed_items jsonb;
  contact_items jsonb;
begin
  if current_user_id is null or not private.has_password_authentication() then
    raise exception using errcode = '42501', message = 'Password authentication is required.';
  end if;

  resolved_institution_id := private.resolve_community_institution(
    target_institution_id,
    current_user_id
  );

  select institution_record.name
  into institution_name
  from public.institutions institution_record
  where institution_record.id = resolved_institution_id
    and institution_record.is_active;

  if institution_name is null then
    raise exception using errcode = 'P0002', message = 'Institution is not available.';
  end if;

  is_faculty := private.has_active_role(
    resolved_institution_id,
    current_user_id,
    'faculty'
  );

  access_state := case when exists (
    select 1
    from public.student_affiliation_requests request_record
    where request_record.institution_id = resolved_institution_id
      and request_record.user_id = current_user_id
      and request_record.status = 'pending'
  ) then 'pending_verification' else 'verified' end;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', feed_record.id,
    'title', feed_record.title,
    'body', feed_record.body,
    'publisher_name', coalesce(author_profile.display_name, 'Campus office'),
    'published_at', feed_record.published_at
  ) order by feed_record.published_at desc, feed_record.id desc), '[]'::jsonb)
  into feed_items
  from public.community_feed_posts feed_record
  left join public.profiles author_profile
    on author_profile.user_id = feed_record.author_user_id
  where feed_record.institution_id = resolved_institution_id
    and (feed_record.expires_at is null or feed_record.expires_at > now());

  if is_faculty then
    select coalesce(jsonb_agg(jsonb_build_object(
      'participant_user_id', thread_record.student_user_id,
      'participant_name', coalesce(student_profile.display_name, 'Campus member'),
      'participant_role', 'Student',
      'thread_id', thread_record.id,
      'last_message', latest_message.body,
      'last_message_at', latest_message.sent_at
    ) order by thread_record.updated_at desc, thread_record.id), '[]'::jsonb)
    into contact_items
    from public.faculty_contact_threads thread_record
    left join public.profiles student_profile
      on student_profile.user_id = thread_record.student_user_id
    left join lateral (
      select message_record.body, message_record.sent_at
      from public.faculty_contact_messages message_record
      where message_record.thread_id = thread_record.id
        and message_record.expires_at > now()
      order by message_record.sent_at desc, message_record.id desc
      limit 1
    ) latest_message on true
    where thread_record.institution_id = resolved_institution_id
      and thread_record.faculty_user_id = current_user_id;
  else
    select coalesce(jsonb_agg(jsonb_build_object(
      'participant_user_id', membership.user_id,
      'participant_name', coalesce(faculty_profile.display_name, 'Faculty member'),
      'participant_role', 'Faculty',
      'thread_id', thread_record.id,
      'last_message', latest_message.body,
      'last_message_at', latest_message.sent_at
    ) order by coalesce(faculty_profile.display_name, 'Faculty member'), membership.user_id), '[]'::jsonb)
    into contact_items
    from public.institution_memberships membership
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record
      on role_record.id = membership_role.role_id and role_record.key = 'faculty'
    left join public.profiles faculty_profile on faculty_profile.user_id = membership.user_id
    left join public.faculty_contact_threads thread_record
      on thread_record.institution_id = resolved_institution_id
      and thread_record.student_user_id = current_user_id
      and thread_record.faculty_user_id = membership.user_id
    left join lateral (
      select message_record.body, message_record.sent_at
      from public.faculty_contact_messages message_record
      where message_record.thread_id = thread_record.id
        and message_record.expires_at > now()
      order by message_record.sent_at desc, message_record.id desc
      limit 1
    ) latest_message on true
    where membership.institution_id = resolved_institution_id
      and membership.status = 'active';
  end if;

  return jsonb_build_object(
    'institution_id', resolved_institution_id,
    'institution_name', institution_name,
    'access_state', access_state,
    'viewer_kind', case when is_faculty then 'faculty' else 'student' end,
    'feed', feed_items,
    'contacts', contact_items
  );
end;
$$;

create or replace function public.list_faculty_contact_messages(
  target_thread_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  thread_record public.faculty_contact_threads%rowtype;
  result jsonb;
begin
  if current_user_id is null or not private.has_password_authentication() then
    raise exception using errcode = '42501', message = 'Password authentication is required.';
  end if;

  select thread_value.* into thread_record
  from public.faculty_contact_threads thread_value
  where thread_value.id = target_thread_id
    and current_user_id in (thread_value.student_user_id, thread_value.faculty_user_id);

  if thread_record.id is null
     or not private.has_community_access(thread_record.institution_id, thread_record.student_user_id)
     or not private.has_active_role(thread_record.institution_id, thread_record.faculty_user_id, 'faculty') then
    raise exception using errcode = '42501', message = 'Conversation access is no longer available.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', message_record.id,
    'thread_id', message_record.thread_id,
    'sender_user_id', message_record.sender_user_id,
    'body', message_record.body,
    'sent_at', message_record.sent_at
  ) order by message_record.sent_at, message_record.id), '[]'::jsonb)
  into result
  from public.faculty_contact_messages message_record
  where message_record.thread_id = thread_record.id
    and message_record.expires_at > now();

  return result;
end;
$$;

create or replace function public.send_faculty_contact_message(
  target_institution_id uuid,
  target_thread_id uuid,
  target_faculty_user_id uuid,
  client_message_id uuid,
  new_body text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  resolved_institution_id uuid;
  thread_record public.faculty_contact_threads%rowtype;
  normalized_body text := btrim(new_body);
begin
  if current_user_id is null or not private.has_password_authentication() then
    raise exception using errcode = '42501', message = 'Password authentication is required.';
  end if;
  if normalized_body is null
     or char_length(normalized_body) not between 1 and 2000
     or normalized_body ~ '[[:cntrl:]]' then
    raise exception using errcode = '22023', message = 'Message must contain between 1 and 2000 characters.';
  end if;

  resolved_institution_id := private.resolve_community_institution(
    target_institution_id,
    current_user_id
  );

  if target_thread_id is null then
    if target_faculty_user_id is null
       or private.has_active_role(resolved_institution_id, current_user_id, 'faculty')
       or not private.has_active_role(resolved_institution_id, target_faculty_user_id, 'faculty') then
      raise exception using errcode = '42501', message = 'Choose an active Faculty member.';
    end if;

    insert into public.faculty_contact_threads (
      institution_id, student_user_id, faculty_user_id
    ) values (
      resolved_institution_id, current_user_id, target_faculty_user_id
    )
    on conflict (institution_id, student_user_id, faculty_user_id)
    do update set updated_at = public.faculty_contact_threads.updated_at
    returning * into thread_record;
  else
    select thread_value.* into thread_record
    from public.faculty_contact_threads thread_value
    where thread_value.id = target_thread_id
      and thread_value.institution_id = resolved_institution_id
      and current_user_id in (thread_value.student_user_id, thread_value.faculty_user_id)
    for update;

    if thread_record.id is null then
      raise exception using errcode = '42501', message = 'Conversation access is not available.';
    end if;
  end if;

  if not private.has_community_access(thread_record.institution_id, thread_record.student_user_id)
     or not private.has_active_role(thread_record.institution_id, thread_record.faculty_user_id, 'faculty') then
    raise exception using errcode = '42501', message = 'Conversation access is no longer available.';
  end if;

  delete from public.faculty_contact_messages expired_message
  where expired_message.thread_id = thread_record.id
    and expired_message.expires_at <= now();

  insert into public.faculty_contact_messages (
    thread_id, sender_user_id, client_message_id, body
  ) values (
    thread_record.id, current_user_id, client_message_id, normalized_body
  ) on conflict on constraint
    faculty_contact_messages_sender_user_id_client_message_id_key
  do nothing;

  update public.faculty_contact_threads thread_value
  set updated_at = now()
  where thread_value.id = thread_record.id;

  return jsonb_build_object(
    'thread_id', thread_record.id,
    'messages', public.list_faculty_contact_messages(thread_record.id)
  );
end;
$$;

create or replace function public.publish_community_feed_post(
  target_institution_id uuid,
  new_title text,
  new_body text,
  new_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  new_id uuid;
begin
  if current_user_id is null
     or not private.has_password_authentication()
     or not (
       private.has_permission(target_institution_id, 'announcements_publish')
       or private.has_permission(target_institution_id, 'institution_manage')
     ) then
    raise exception using errcode = '42501', message = 'Announcement publishing access is required.';
  end if;

  insert into public.community_feed_posts (
    institution_id, author_user_id, title, body, expires_at
  ) values (
    target_institution_id,
    current_user_id,
    btrim(new_title),
    btrim(new_body),
    new_expires_at
  ) returning id into new_id;
  return new_id;
end;
$$;

revoke all on function private.has_community_access(uuid, uuid)
from public, anon, authenticated, service_role;
revoke all on function private.has_active_role(uuid, uuid, text)
from public, anon, authenticated, service_role;
revoke all on function private.resolve_community_institution(uuid, uuid)
from public, anon, authenticated, service_role;

revoke all on function public.get_my_community_overview(uuid)
from public, anon, authenticated, service_role;
revoke all on function public.list_faculty_contact_messages(uuid)
from public, anon, authenticated, service_role;
revoke all on function public.send_faculty_contact_message(uuid, uuid, uuid, uuid, text)
from public, anon, authenticated, service_role;
revoke all on function public.publish_community_feed_post(uuid, text, text, timestamptz)
from public, anon, authenticated, service_role;

grant execute on function public.get_my_community_overview(uuid) to authenticated;
grant execute on function public.list_faculty_contact_messages(uuid) to authenticated;
grant execute on function public.send_faculty_contact_message(uuid, uuid, uuid, uuid, text) to authenticated;
grant execute on function public.publish_community_feed_post(uuid, text, text, timestamptz) to authenticated;

commit;
