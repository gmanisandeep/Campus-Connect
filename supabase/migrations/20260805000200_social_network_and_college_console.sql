begin;

alter table public.institutions
  add column if not exists registration_status text not null default 'unclaimed'
    check (registration_status in ('unclaimed', 'claim_pending', 'verified', 'suspended', 'closed')),
  add column if not exists aishe_code text,
  add column if not exists official_website text,
  add column if not exists official_domains text[] not null default '{}',
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists district text,
  add column if not exists state text not null default 'Telangana',
  add column if not exists postal_code text,
  add column if not exists source_name text,
  add column if not exists source_url text,
  add column if not exists source_checked_at timestamptz;

create unique index if not exists institutions_aishe_code_uidx
  on public.institutions (aishe_code) where aishe_code is not null;
create index if not exists institutions_directory_search_idx
  on public.institutions (state, district, registration_status, name);

create table public.platform_administrators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.institution_claims (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  applicant_user_id uuid not null references auth.users(id) on delete cascade,
  applicant_name text not null check (char_length(btrim(applicant_name)) between 2 and 120),
  designation text not null check (char_length(btrim(designation)) between 2 and 120),
  employee_id text not null check (char_length(btrim(employee_id)) between 2 and 80),
  official_email text not null check (official_email = lower(btrim(official_email))),
  official_phone text not null check (char_length(btrim(official_phone)) between 8 and 24),
  authorization_document_path text not null,
  notes text check (notes is null or char_length(notes) <= 2000),
  status text not null default 'pending'
    check (status in ('pending', 'needs_information', 'approved', 'rejected', 'withdrawn')),
  reviewer_user_id uuid references auth.users(id) on delete set null,
  reviewer_notes text check (reviewer_notes is null or char_length(reviewer_notes) <= 2000),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  updated_at timestamptz not null default now()
);

create unique index institution_claims_one_pending_applicant_idx
  on public.institution_claims (applicant_user_id)
  where status in ('pending', 'needs_information');
create index institution_claims_review_queue_idx
  on public.institution_claims (status, submitted_at);

create table public.faculty_registrations (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  applicant_user_id uuid not null references auth.users(id) on delete cascade,
  employee_id text not null check (char_length(btrim(employee_id)) between 2 and 80),
  department text not null check (char_length(btrim(department)) between 2 and 120),
  designation text not null check (char_length(btrim(designation)) between 2 and 120),
  official_email text not null check (official_email = lower(btrim(official_email))),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'withdrawn')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewer_notes text check (reviewer_notes is null or char_length(reviewer_notes) <= 1000),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (institution_id, applicant_user_id)
);

create table public.social_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,30}$'),
  bio text not null default '' check (char_length(bio) <= 300),
  avatar_path text,
  is_public boolean not null default true,
  allow_message_requests text not null default 'everyone'
    check (allow_message_requests in ('everyone', 'verified', 'followers', 'nobody')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.social_blocks (
  blocker_user_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  check (blocker_user_id <> blocked_user_id)
);

create table public.social_follows (
  follower_user_id uuid not null references auth.users(id) on delete cascade,
  followed_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_user_id, followed_user_id),
  check (follower_user_id <> followed_user_id)
);

create table public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_user_id uuid not null references auth.users(id) on delete cascade,
  institution_id uuid references public.institutions(id) on delete set null,
  body text not null default '' check (char_length(body) <= 5000),
  visibility text not null default 'public'
    check (visibility in ('public', 'followers', 'college')),
  is_official boolean not null default false,
  comments_enabled boolean not null default true,
  moderation_status text not null default 'active'
    check (moderation_status in ('active', 'under_review', 'hidden', 'removed')),
  client_post_id uuid not null,
  published_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (author_user_id, client_post_id)
);

create index social_posts_feed_idx
  on public.social_posts (moderation_status, visibility, published_at desc);
create index social_posts_author_idx
  on public.social_posts (author_user_id, published_at desc);
create index social_posts_institution_idx
  on public.social_posts (institution_id, published_at desc)
  where institution_id is not null;

create table public.social_post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  storage_path text not null,
  media_kind text not null check (media_kind in ('image', 'video', 'document')),
  mime_type text not null,
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  duration_ms integer check (duration_ms is null or duration_ms >= 0),
  alt_text text not null default '' check (char_length(alt_text) <= 500),
  sort_order smallint not null default 0 check (sort_order between 0 and 9),
  unique (post_id, sort_order)
);

create table public.social_post_likes (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.social_post_saves (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.social_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete cascade,
  parent_comment_id uuid references public.social_comments(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  moderation_status text not null default 'active'
    check (moderation_status in ('active', 'under_review', 'hidden', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index social_comments_post_idx on public.social_comments (post_id, created_at);

create table public.social_reposts (
  post_id uuid not null references public.social_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  quote_body text check (quote_body is null or char_length(quote_body) <= 2000),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.social_message_requests (
  id uuid primary key default gen_random_uuid(),
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  opening_message text not null check (char_length(btrim(opening_message)) between 1 and 2000),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (sender_user_id <> recipient_user_id)
);
create unique index social_message_requests_pending_pair_idx
  on public.social_message_requests (sender_user_id, recipient_user_id)
  where status = 'pending';

create table public.social_threads (
  id uuid primary key default gen_random_uuid(),
  request_id uuid unique references public.social_message_requests(id) on delete set null,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.social_thread_members (
  thread_id uuid not null references public.social_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table public.social_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.social_threads(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  body text not null default '' check (char_length(body) <= 5000),
  attachment_path text,
  attachment_kind text check (attachment_kind is null or attachment_kind in ('image', 'video', 'document', 'post')),
  shared_post_id uuid references public.social_posts(id) on delete set null,
  client_message_id uuid not null,
  sent_at timestamptz not null default now(),
  unique (sender_user_id, client_message_id),
  check (body <> '' or attachment_path is not null or shared_post_id is not null)
);
create index social_messages_thread_idx on public.social_messages (thread_id, sent_at);

create table public.social_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid references public.social_posts(id) on delete cascade,
  comment_id uuid references public.social_comments(id) on delete cascade,
  reported_user_id uuid references auth.users(id) on delete cascade,
  reason text not null check (reason in ('spam', 'harassment', 'impersonation', 'hate', 'sexual', 'violence', 'copyright', 'other')),
  details text check (details is null or char_length(details) <= 2000),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  check (num_nonnulls(post_id, comment_id, reported_user_id) = 1)
);

create table public.social_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('follow', 'like', 'comment', 'repost', 'message_request', 'message', 'college_claim', 'faculty_registration')),
  post_id uuid references public.social_posts(id) on delete cascade,
  thread_id uuid references public.social_threads(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index social_notifications_recipient_idx
  on public.social_notifications (recipient_user_id, is_read, created_at desc);

create or replace function private.is_platform_administrator(target_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.platform_administrators administrator
    where administrator.user_id = target_user_id
  );
$$;

create or replace function private.users_block_each_other(first_user_id uuid, second_user_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.social_blocks block_record
    where (block_record.blocker_user_id = first_user_id and block_record.blocked_user_id = second_user_id)
       or (block_record.blocker_user_id = second_user_id and block_record.blocked_user_id = first_user_id)
  );
$$;

create or replace function private.can_view_social_post(viewer_id uuid, post_record public.social_posts)
returns boolean language sql stable security definer set search_path = '' as $$
  select post_record.moderation_status = 'active'
    and not private.users_block_each_other(viewer_id, post_record.author_user_id)
    and (
      post_record.visibility = 'public'
      or post_record.author_user_id = viewer_id
      or (post_record.visibility = 'followers' and exists (
        select 1 from public.social_follows follow_record
        where follow_record.follower_user_id = viewer_id
          and follow_record.followed_user_id = post_record.author_user_id
      ))
      or (post_record.visibility = 'college' and post_record.institution_id is not null and private.has_community_access(post_record.institution_id, viewer_id))
    );
$$;

create or replace function public.ensure_social_profile()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  viewer_id uuid := auth.uid();
  generated_username text;
  result_record public.social_profiles%rowtype;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  generated_username := 'campus_' || left(replace(viewer_id::text, '-', ''), 8)
    || right(replace(viewer_id::text, '-', ''), 8);
  insert into public.social_profiles (user_id, username)
  values (viewer_id, generated_username)
  on conflict (user_id) do nothing;
  select * into result_record from public.social_profiles where user_id = viewer_id;
  return to_jsonb(result_record);
end;
$$;

create or replace function public.update_social_profile(
  target_username text,
  target_bio text,
  target_avatar_path text default null,
  target_is_public boolean default true,
  target_allow_message_requests text default 'everyone'
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); result_record public.social_profiles%rowtype;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  insert into public.social_profiles (user_id, username, bio, avatar_path, is_public, allow_message_requests)
  values (viewer_id, lower(btrim(target_username)), btrim(target_bio), target_avatar_path, target_is_public, target_allow_message_requests)
  on conflict (user_id) do update set
    username = excluded.username, bio = excluded.bio, avatar_path = excluded.avatar_path,
    is_public = excluded.is_public, allow_message_requests = excluded.allow_message_requests, updated_at = now()
  returning * into result_record;
  return to_jsonb(result_record);
end;
$$;

create or replace function public.list_public_institutions(search_text text default null, result_limit integer default 100)
returns table (
  id uuid, name text, city text, district text, aishe_code text,
  registration_status text, official_website text
) language sql stable security definer set search_path = '' as $$
  select institution.id, institution.name, institution.city, institution.district,
         institution.aishe_code, institution.registration_status, institution.official_website
  from public.institutions institution
  where institution.is_active
    and institution.registration_status <> 'closed'
    and (search_text is null or institution.name ilike '%' || btrim(search_text) || '%')
  order by institution.name
  limit least(greatest(result_limit, 1), 250);
$$;

create or replace function public.submit_institution_claim(
  target_institution_id uuid,
  target_applicant_name text,
  target_designation text,
  target_employee_id text,
  target_official_email text,
  target_official_phone text,
  target_authorization_document_path text,
  target_notes text default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); claim_id uuid; domain_value text; allowed_domains text[];
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  select institution.official_domains into allowed_domains
  from public.institutions institution where institution.id = target_institution_id and institution.is_active;
  if not found then raise exception 'College not found'; end if;
  domain_value := split_part(lower(btrim(target_official_email)), '@', 2);
  if domain_value = '' then raise exception 'Use a valid official email'; end if;
  if cardinality(allowed_domains) > 0 and not (domain_value = any(allowed_domains)) then
    raise exception 'Use an approved college email domain';
  end if;
  insert into public.institution_claims (
    institution_id, applicant_user_id, applicant_name, designation, employee_id,
    official_email, official_phone, authorization_document_path, notes
  ) values (
    target_institution_id, viewer_id, btrim(target_applicant_name), btrim(target_designation),
    btrim(target_employee_id), lower(btrim(target_official_email)), btrim(target_official_phone),
    target_authorization_document_path, nullif(btrim(target_notes), '')
  ) returning id into claim_id;
  update public.institutions set registration_status = 'claim_pending', updated_at = now()
  where id = target_institution_id and registration_status = 'unclaimed';
  return claim_id;
end;
$$;

create or replace function public.review_institution_claim(
  target_claim_id uuid, target_decision text, target_reviewer_notes text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); claim_record public.institution_claims%rowtype; membership_id uuid; admin_role_id uuid;
begin
  if viewer_id is null or not private.is_platform_administrator(viewer_id) then raise exception 'Platform administrator required'; end if;
  if target_decision not in ('approved', 'rejected', 'needs_information') then raise exception 'Invalid decision'; end if;
  select * into claim_record from public.institution_claims where id = target_claim_id and status in ('pending', 'needs_information') for update;
  if not found then raise exception 'Claim is not pending'; end if;
  update public.institution_claims set status = target_decision, reviewer_user_id = viewer_id,
    reviewer_notes = nullif(btrim(target_reviewer_notes), ''), reviewed_at = case when target_decision = 'needs_information' then null else now() end,
    updated_at = now() where id = target_claim_id;
  if target_decision = 'approved' then
    update public.institutions set registration_status = 'verified', updated_at = now() where id = claim_record.institution_id;
    insert into public.institution_memberships (institution_id, user_id, status, invited_by)
    values (claim_record.institution_id, claim_record.applicant_user_id, 'active', viewer_id)
    on conflict (institution_id, user_id) do update set status = 'active', updated_at = now()
    returning id into membership_id;
    select id into admin_role_id from public.roles where key = 'institution_admin';
    insert into public.membership_roles (membership_id, role_id, assigned_by)
    values (membership_id, admin_role_id, viewer_id) on conflict do nothing;
  elsif target_decision = 'rejected' then
    update public.institutions set registration_status = 'unclaimed', updated_at = now()
    where id = claim_record.institution_id and not exists (
      select 1 from public.institution_claims another where another.institution_id = claim_record.institution_id and another.status = 'approved'
    );
  end if;
end;
$$;

create or replace function public.list_institution_claims_for_review()
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when private.is_platform_administrator(auth.uid()) then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', claim_record.id, 'institution_id', claim_record.institution_id,
      'institution_name', institution.name, 'applicant_name', claim_record.applicant_name,
      'designation', claim_record.designation, 'employee_id', claim_record.employee_id,
      'official_email', claim_record.official_email, 'official_phone', claim_record.official_phone,
      'authorization_document_path', claim_record.authorization_document_path,
      'notes', claim_record.notes, 'status', claim_record.status,
      'submitted_at', claim_record.submitted_at
    ) order by claim_record.submitted_at), '[]'::jsonb)
  else '[]'::jsonb end
  from public.institution_claims claim_record
  join public.institutions institution on institution.id = claim_record.institution_id
  where claim_record.status in ('pending', 'needs_information');
$$;

create or replace function public.submit_faculty_registration(
  target_institution_id uuid, target_employee_id text, target_department text,
  target_designation text, target_official_email text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); registration_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.institutions where id = target_institution_id and registration_status = 'verified') then
    raise exception 'College must be verified before Faculty can register';
  end if;
  insert into public.faculty_registrations (institution_id, applicant_user_id, employee_id, department, designation, official_email)
  values (target_institution_id, viewer_id, btrim(target_employee_id), btrim(target_department), btrim(target_designation), lower(btrim(target_official_email)))
  on conflict (institution_id, applicant_user_id) do update set
    employee_id = excluded.employee_id, department = excluded.department, designation = excluded.designation,
    official_email = excluded.official_email, status = 'pending', submitted_at = now(), reviewed_at = null
  returning id into registration_id;
  return registration_id;
end;
$$;

create or replace function public.review_faculty_registration(
  target_registration_id uuid, target_decision text, target_notes text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); request_record public.faculty_registrations%rowtype; membership_id uuid; faculty_role_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  if target_decision not in ('approved', 'rejected') then raise exception 'Invalid decision'; end if;
  select * into request_record from public.faculty_registrations where id = target_registration_id and status = 'pending' for update;
  if not found then raise exception 'Faculty registration is not pending'; end if;
  if not private.has_permission(request_record.institution_id, 'institution_manage') then raise exception 'Institution authority required'; end if;
  update public.faculty_registrations set status = target_decision, reviewed_by = viewer_id,
    reviewer_notes = nullif(btrim(target_notes), ''), reviewed_at = now() where id = target_registration_id;
  if target_decision = 'approved' then
    insert into public.institution_memberships (institution_id, user_id, status, invited_by)
    values (request_record.institution_id, request_record.applicant_user_id, 'active', viewer_id)
    on conflict (institution_id, user_id) do update set status = 'active', updated_at = now()
    returning id into membership_id;
    select id into faculty_role_id from public.roles where key = 'faculty';
    insert into public.membership_roles (membership_id, role_id, assigned_by)
    values (membership_id, faculty_role_id, viewer_id) on conflict do nothing;
  end if;
end;
$$;

create or replace function public.list_faculty_registrations_for_review(target_institution_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when private.has_permission(target_institution_id, 'institution_manage') then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', request_record.id, 'institution_id', request_record.institution_id,
      'applicant_user_id', request_record.applicant_user_id,
      'applicant_name', coalesce(profile_record.display_name, 'Campus member'),
      'employee_id', request_record.employee_id, 'department', request_record.department,
      'designation', request_record.designation, 'official_email', request_record.official_email,
      'status', request_record.status, 'submitted_at', request_record.submitted_at
    ) order by request_record.submitted_at), '[]'::jsonb)
  else '[]'::jsonb end
  from public.faculty_registrations request_record
  left join public.profiles profile_record on profile_record.user_id = request_record.applicant_user_id
  where request_record.institution_id = target_institution_id and request_record.status = 'pending';
$$;

create or replace function public.create_social_post(
  target_body text,
  target_visibility text,
  target_client_post_id uuid,
  target_institution_id uuid default null,
  target_is_official boolean default false,
  target_media jsonb default '[]'::jsonb
) returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); post_id uuid; media_record jsonb; media_count integer;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  perform public.ensure_social_profile();
  if target_visibility not in ('public', 'followers', 'college') then raise exception 'Invalid visibility'; end if;
  if target_visibility = 'college' and target_institution_id is null then
    target_institution_id := private.resolve_community_institution(null, viewer_id);
  end if;
  if target_visibility = 'college' and not private.has_community_access(target_institution_id, viewer_id) then
    raise exception 'College membership or pending affiliation required';
  end if;
  if target_is_official and (target_institution_id is null or not (
    private.has_permission(target_institution_id, 'announcements_publish') or private.has_permission(target_institution_id, 'institution_manage')
  )) then raise exception 'Official publishing permission required'; end if;
  media_count := jsonb_array_length(coalesce(target_media, '[]'::jsonb));
  if media_count > 10 then raise exception 'A post can contain at most 10 attachments'; end if;
  if char_length(btrim(coalesce(target_body, ''))) = 0 and media_count = 0 then raise exception 'Post cannot be empty'; end if;
  insert into public.social_posts (author_user_id, institution_id, body, visibility, is_official, client_post_id)
  values (viewer_id, target_institution_id, btrim(coalesce(target_body, '')), target_visibility, target_is_official, target_client_post_id)
  on conflict (author_user_id, client_post_id) do update set client_post_id = excluded.client_post_id
  returning id into post_id;
  for media_record in select value from jsonb_array_elements(coalesce(target_media, '[]'::jsonb)) loop
    if split_part(media_record->>'storage_path', '/', 1) <> viewer_id::text then raise exception 'Invalid media ownership'; end if;
    insert into public.social_post_media (post_id, storage_path, media_kind, mime_type, width, height, duration_ms, alt_text, sort_order)
    values (post_id, media_record->>'storage_path', media_record->>'media_kind', media_record->>'mime_type',
      nullif(media_record->>'width','')::integer, nullif(media_record->>'height','')::integer,
      nullif(media_record->>'duration_ms','')::integer, coalesce(media_record->>'alt_text',''), coalesce((media_record->>'sort_order')::smallint,0))
    on conflict (post_id, sort_order) do nothing;
  end loop;
  return post_id;
end;
$$;

create or replace function public.list_social_feed(
  feed_mode text default 'for_you',
  cursor_before timestamptz default null,
  page_size integer default 20
) returns jsonb language sql stable security definer set search_path = '' as $$
  with viewer as (select auth.uid() id),
  visible_posts as (
    select post_record.*
    from public.social_posts post_record, viewer
    where viewer.id is not null
      and private.can_view_social_post(viewer.id, post_record)
      and (cursor_before is null or post_record.published_at < cursor_before)
      and (
        feed_mode = 'for_you'
        or (feed_mode = 'following' and (post_record.author_user_id = viewer.id or exists (
          select 1 from public.social_follows follow_record where follow_record.follower_user_id = viewer.id and follow_record.followed_user_id = post_record.author_user_id
        )))
        or (feed_mode = 'college' and post_record.institution_id is not null and private.has_community_access(post_record.institution_id, viewer.id))
        or (feed_mode = 'saved' and exists (select 1 from public.social_post_saves save_record where save_record.user_id = viewer.id and save_record.post_id = post_record.id))
      )
    order by post_record.published_at desc
    limit least(greatest(page_size, 1), 50)
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', post_record.id,
      'body', post_record.body,
      'published_at', post_record.published_at,
      'visibility', post_record.visibility,
      'is_official', post_record.is_official,
      'author_user_id', post_record.author_user_id,
      'author_name', coalesce(profile_record.display_name, social_record.username, 'Campus member'),
      'username', social_record.username,
      'avatar_path', coalesce(social_record.avatar_path, profile_record.avatar_path),
      'institution_id', post_record.institution_id,
      'institution_name', institution.name,
      'like_count', (select count(*) from public.social_post_likes where post_id = post_record.id),
      'comment_count', (select count(*) from public.social_comments where post_id = post_record.id and moderation_status = 'active'),
      'repost_count', (select count(*) from public.social_reposts where post_id = post_record.id),
      'liked_by_viewer', exists (select 1 from public.social_post_likes where post_id = post_record.id and user_id = auth.uid()),
      'saved_by_viewer', exists (select 1 from public.social_post_saves where post_id = post_record.id and user_id = auth.uid()),
      'media', coalesce((select jsonb_agg(to_jsonb(media_record) order by media_record.sort_order) from public.social_post_media media_record where media_record.post_id = post_record.id), '[]'::jsonb)
    ) order by post_record.published_at desc
  ), '[]'::jsonb)
  from visible_posts post_record
  left join public.profiles profile_record on profile_record.user_id = post_record.author_user_id
  left join public.social_profiles social_record on social_record.user_id = post_record.author_user_id
  left join public.institutions institution on institution.id = post_record.institution_id;
$$;

create or replace function public.toggle_social_like(target_post_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); author_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  select post_record.author_user_id into author_id from public.social_posts post_record where post_record.id = target_post_id and private.can_view_social_post(viewer_id, post_record);
  if not found then raise exception 'Post not found'; end if;
  delete from public.social_post_likes where post_id = target_post_id and user_id = viewer_id;
  if found then return false; end if;
  insert into public.social_post_likes (post_id, user_id) values (target_post_id, viewer_id);
  if author_id <> viewer_id then insert into public.social_notifications (recipient_user_id, actor_user_id, event_type, post_id) values (author_id, viewer_id, 'like', target_post_id); end if;
  return true;
end;
$$;

create or replace function public.toggle_social_save(target_post_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid();
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.social_posts post_record where post_record.id = target_post_id and private.can_view_social_post(viewer_id, post_record)) then raise exception 'Post not found'; end if;
  delete from public.social_post_saves where post_id = target_post_id and user_id = viewer_id;
  if found then return false; end if;
  insert into public.social_post_saves (post_id, user_id) values (target_post_id, viewer_id);
  return true;
end;
$$;

create or replace function public.toggle_social_follow(target_user_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid();
begin
  if viewer_id is null or viewer_id = target_user_id then raise exception 'Invalid follow target'; end if;
  if private.users_block_each_other(viewer_id, target_user_id) then raise exception 'Account unavailable'; end if;
  delete from public.social_follows where follower_user_id = viewer_id and followed_user_id = target_user_id;
  if found then return false; end if;
  insert into public.social_follows (follower_user_id, followed_user_id) values (viewer_id, target_user_id);
  insert into public.social_notifications (recipient_user_id, actor_user_id, event_type) values (target_user_id, viewer_id, 'follow');
  return true;
end;
$$;

create or replace function public.add_social_comment(target_post_id uuid, target_body text, target_parent_comment_id uuid default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); comment_id uuid; author_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  select post_record.author_user_id into author_id from public.social_posts post_record
  where post_record.id = target_post_id and post_record.comments_enabled and private.can_view_social_post(viewer_id, post_record);
  if not found then raise exception 'Comments are unavailable'; end if;
  if target_parent_comment_id is not null and not exists (select 1 from public.social_comments where id = target_parent_comment_id and post_id = target_post_id) then raise exception 'Parent comment not found'; end if;
  insert into public.social_comments (post_id, author_user_id, parent_comment_id, body)
  values (target_post_id, viewer_id, target_parent_comment_id, btrim(target_body)) returning id into comment_id;
  if author_id <> viewer_id then insert into public.social_notifications (recipient_user_id, actor_user_id, event_type, post_id) values (author_id, viewer_id, 'comment', target_post_id); end if;
  return comment_id;
end;
$$;

create or replace function public.list_social_comments(target_post_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', comment_record.id, 'body', comment_record.body, 'created_at', comment_record.created_at,
    'author_user_id', comment_record.author_user_id,
    'author_name', coalesce(profile_record.display_name, social_record.username, 'Campus member'),
    'username', social_record.username, 'parent_comment_id', comment_record.parent_comment_id
  ) order by comment_record.created_at), '[]'::jsonb)
  from public.social_comments comment_record
  left join public.profiles profile_record on profile_record.user_id = comment_record.author_user_id
  left join public.social_profiles social_record on social_record.user_id = comment_record.author_user_id
  where comment_record.post_id = target_post_id and comment_record.moderation_status = 'active'
    and exists (select 1 from public.social_posts post_record where post_record.id = target_post_id and private.can_view_social_post(auth.uid(), post_record));
$$;

create or replace function public.toggle_social_repost(target_post_id uuid, target_quote_body text default null)
returns boolean language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); author_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  select post_record.author_user_id into author_id from public.social_posts post_record where post_record.id = target_post_id and private.can_view_social_post(viewer_id, post_record);
  if not found then raise exception 'Post not found'; end if;
  delete from public.social_reposts where post_id = target_post_id and user_id = viewer_id;
  if found then return false; end if;
  insert into public.social_reposts (post_id, user_id, quote_body) values (target_post_id, viewer_id, nullif(btrim(target_quote_body), ''));
  if author_id <> viewer_id then insert into public.social_notifications (recipient_user_id, actor_user_id, event_type, post_id) values (author_id, viewer_id, 'repost', target_post_id); end if;
  return true;
end;
$$;

create or replace function public.send_social_message_request(target_recipient_user_id uuid, target_opening_message text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); request_id uuid; preference text;
begin
  if viewer_id is null or viewer_id = target_recipient_user_id then raise exception 'Invalid recipient'; end if;
  if private.users_block_each_other(viewer_id, target_recipient_user_id) then raise exception 'Account unavailable'; end if;
  select allow_message_requests into preference from public.social_profiles where user_id = target_recipient_user_id;
  if preference is null or preference = 'nobody' then raise exception 'This person is not accepting message requests'; end if;
  if preference = 'followers' and not exists (select 1 from public.social_follows where follower_user_id = target_recipient_user_id and followed_user_id = viewer_id) then raise exception 'Only followed accounts may send requests'; end if;
  if preference = 'verified' and not exists (select 1 from public.institution_memberships where user_id = viewer_id and status = 'active') then raise exception 'Only verified campus members may send requests'; end if;
  if exists (select 1 from public.social_message_requests where sender_user_id = viewer_id and recipient_user_id = target_recipient_user_id and created_at > now() - interval '24 hours' and status in ('declined','cancelled')) then raise exception 'Wait before sending another request'; end if;
  insert into public.social_message_requests (sender_user_id, recipient_user_id, opening_message)
  values (viewer_id, target_recipient_user_id, btrim(target_opening_message)) returning id into request_id;
  insert into public.social_notifications (recipient_user_id, actor_user_id, event_type) values (target_recipient_user_id, viewer_id, 'message_request');
  return request_id;
end;
$$;

create or replace function public.respond_social_message_request(target_request_id uuid, target_accept boolean)
returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); request_record public.social_message_requests%rowtype; thread_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  select * into request_record from public.social_message_requests where id = target_request_id and recipient_user_id = viewer_id and status = 'pending' for update;
  if not found then raise exception 'Request not found'; end if;
  update public.social_message_requests set status = case when target_accept then 'accepted' else 'declined' end, responded_at = now() where id = target_request_id;
  if not target_accept then return null; end if;
  insert into public.social_threads (request_id) values (target_request_id) returning id into thread_id;
  insert into public.social_thread_members (thread_id, user_id) values (thread_id, request_record.sender_user_id), (thread_id, request_record.recipient_user_id);
  insert into public.social_messages (thread_id, sender_user_id, body, client_message_id, sent_at)
  values (thread_id, request_record.sender_user_id, request_record.opening_message, gen_random_uuid(), request_record.created_at);
  return thread_id;
end;
$$;

create or replace function public.send_social_message(
  target_thread_id uuid, target_body text, target_client_message_id uuid,
  target_attachment_path text default null, target_attachment_kind text default null,
  target_shared_post_id uuid default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); message_id uuid; recipient_id uuid;
begin
  if viewer_id is null or not exists (select 1 from public.social_thread_members where thread_id = target_thread_id and user_id = viewer_id) then raise exception 'Conversation unavailable'; end if;
  select user_id into recipient_id from public.social_thread_members where thread_id = target_thread_id and user_id <> viewer_id limit 1;
  if private.users_block_each_other(viewer_id, recipient_id) then raise exception 'Conversation unavailable'; end if;
  if target_attachment_path is not null and split_part(target_attachment_path, '/', 1) <> viewer_id::text then raise exception 'Invalid attachment ownership'; end if;
  insert into public.social_messages (thread_id, sender_user_id, body, attachment_path, attachment_kind, shared_post_id, client_message_id)
  values (target_thread_id, viewer_id, btrim(coalesce(target_body,'')), target_attachment_path, target_attachment_kind, target_shared_post_id, target_client_message_id)
  on conflict (sender_user_id, client_message_id) do update set client_message_id = excluded.client_message_id
  returning id into message_id;
  update public.social_threads set last_message_at = now() where id = target_thread_id;
  insert into public.social_notifications (recipient_user_id, actor_user_id, event_type, thread_id) values (recipient_id, viewer_id, 'message', target_thread_id);
  return message_id;
end;
$$;

create or replace function public.get_social_inbox()
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'requests', coalesce((select jsonb_agg(jsonb_build_object(
      'id', request_record.id, 'sender_user_id', request_record.sender_user_id,
      'sender_name', coalesce(profile_record.display_name, social_record.username, 'Campus member'),
      'opening_message', request_record.opening_message, 'created_at', request_record.created_at
    ) order by request_record.created_at desc)
    from public.social_message_requests request_record
    left join public.profiles profile_record on profile_record.user_id = request_record.sender_user_id
    left join public.social_profiles social_record on social_record.user_id = request_record.sender_user_id
    where request_record.recipient_user_id = auth.uid() and request_record.status = 'pending'), '[]'::jsonb),
    'threads', coalesce((select jsonb_agg(jsonb_build_object(
      'id', thread_record.id, 'last_message_at', thread_record.last_message_at,
      'participant_user_id', other_member.user_id,
      'participant_name', coalesce(other_profile.display_name, other_social.username, 'Campus member'),
      'last_message', (select body from public.social_messages where thread_id = thread_record.id order by sent_at desc limit 1)
    ) order by thread_record.last_message_at desc)
    from public.social_threads thread_record
    join public.social_thread_members my_member on my_member.thread_id = thread_record.id and my_member.user_id = auth.uid()
    join public.social_thread_members other_member on other_member.thread_id = thread_record.id and other_member.user_id <> auth.uid()
    left join public.profiles other_profile on other_profile.user_id = other_member.user_id
    left join public.social_profiles other_social on other_social.user_id = other_member.user_id), '[]'::jsonb)
  );
$$;

create or replace function public.get_social_thread(target_thread_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', message_record.id, 'sender_user_id', message_record.sender_user_id,
    'body', message_record.body, 'attachment_path', message_record.attachment_path,
    'attachment_kind', message_record.attachment_kind, 'shared_post_id', message_record.shared_post_id,
    'sent_at', message_record.sent_at
  ) order by message_record.sent_at), '[]'::jsonb)
  from public.social_messages message_record
  where message_record.thread_id = target_thread_id
    and exists (select 1 from public.social_thread_members where thread_id = target_thread_id and user_id = auth.uid());
$$;

create or replace function public.block_social_user(target_user_id uuid, target_block boolean default true)
returns void language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid();
begin
  if viewer_id is null or viewer_id = target_user_id then raise exception 'Invalid account'; end if;
  if target_block then
    insert into public.social_blocks (blocker_user_id, blocked_user_id) values (viewer_id, target_user_id) on conflict do nothing;
    delete from public.social_follows where (follower_user_id = viewer_id and followed_user_id = target_user_id) or (follower_user_id = target_user_id and followed_user_id = viewer_id);
  else
    delete from public.social_blocks where blocker_user_id = viewer_id and blocked_user_id = target_user_id;
  end if;
end;
$$;

create or replace function public.report_social_content(
  target_reason text, target_details text default null, target_post_id uuid default null,
  target_comment_id uuid default null, target_user_id uuid default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare viewer_id uuid := auth.uid(); report_id uuid;
begin
  if viewer_id is null then raise exception 'Authentication required'; end if;
  insert into public.social_reports (reporter_user_id, post_id, comment_id, reported_user_id, reason, details)
  values (viewer_id, target_post_id, target_comment_id, target_user_id, target_reason, nullif(btrim(target_details), '')) returning id into report_id;
  return report_id;
end;
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'social-media', 'social-media', true, 52428800,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','application/pdf']
)
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('claim-documents', 'claim-documents', false, 10485760, array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy social_media_authenticated_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'social-media' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy social_media_owner_update on storage.objects
for update to authenticated using (
  bucket_id = 'social-media' and owner_id = auth.uid()::text
) with check (bucket_id = 'social-media' and owner_id = auth.uid()::text);
create policy social_media_owner_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'social-media' and owner_id = auth.uid()::text
);
create policy claim_documents_authenticated_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'claim-documents' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy claim_documents_owner_read on storage.objects
for select to authenticated using (
  bucket_id = 'claim-documents' and (owner_id = auth.uid()::text or private.is_platform_administrator(auth.uid()))
);
create policy claim_documents_owner_delete on storage.objects
for delete to authenticated using (
  bucket_id = 'claim-documents' and owner_id = auth.uid()::text
);

alter table public.platform_administrators enable row level security;
alter table public.institution_claims enable row level security;
alter table public.faculty_registrations enable row level security;
alter table public.social_profiles enable row level security;
alter table public.social_blocks enable row level security;
alter table public.social_follows enable row level security;
alter table public.social_posts enable row level security;
alter table public.social_post_media enable row level security;
alter table public.social_post_likes enable row level security;
alter table public.social_post_saves enable row level security;
alter table public.social_comments enable row level security;
alter table public.social_reposts enable row level security;
alter table public.social_message_requests enable row level security;
alter table public.social_threads enable row level security;
alter table public.social_thread_members enable row level security;
alter table public.social_messages enable row level security;
alter table public.social_reports enable row level security;
alter table public.social_notifications enable row level security;

revoke all on table public.platform_administrators, public.institution_claims, public.faculty_registrations,
  public.social_profiles, public.social_blocks, public.social_follows, public.social_posts, public.social_post_media,
  public.social_post_likes, public.social_post_saves, public.social_comments, public.social_reposts,
  public.social_message_requests, public.social_threads, public.social_thread_members, public.social_messages,
  public.social_reports, public.social_notifications from public, anon, authenticated, service_role;
grant all on table public.platform_administrators, public.institution_claims, public.faculty_registrations,
  public.social_profiles, public.social_blocks, public.social_follows, public.social_posts, public.social_post_media,
  public.social_post_likes, public.social_post_saves, public.social_comments, public.social_reposts,
  public.social_message_requests, public.social_threads, public.social_thread_members, public.social_messages,
  public.social_reports, public.social_notifications to service_role;

revoke all on function public.ensure_social_profile(),
  public.update_social_profile(text,text,text,boolean,text), public.list_public_institutions(text,integer),
  public.submit_institution_claim(uuid,text,text,text,text,text,text,text), public.review_institution_claim(uuid,text,text),
  public.list_institution_claims_for_review(), public.submit_faculty_registration(uuid,text,text,text,text),
  public.review_faculty_registration(uuid,text,text), public.list_faculty_registrations_for_review(uuid),
  public.create_social_post(text,text,uuid,uuid,boolean,jsonb), public.list_social_feed(text,timestamptz,integer),
  public.toggle_social_like(uuid), public.toggle_social_save(uuid), public.toggle_social_follow(uuid),
  public.add_social_comment(uuid,text,uuid), public.list_social_comments(uuid), public.toggle_social_repost(uuid,text),
  public.send_social_message_request(uuid,text), public.respond_social_message_request(uuid,boolean),
  public.send_social_message(uuid,text,uuid,text,text,uuid), public.get_social_inbox(), public.get_social_thread(uuid),
  public.block_social_user(uuid,boolean), public.report_social_content(text,text,uuid,uuid,uuid)
from public, anon, authenticated, service_role;

grant execute on function public.ensure_social_profile(),
  public.update_social_profile(text,text,text,boolean,text), public.list_public_institutions(text,integer),
  public.submit_institution_claim(uuid,text,text,text,text,text,text,text),
  public.list_institution_claims_for_review(), public.submit_faculty_registration(uuid,text,text,text,text),
  public.review_faculty_registration(uuid,text,text), public.list_faculty_registrations_for_review(uuid),
  public.create_social_post(text,text,uuid,uuid,boolean,jsonb), public.list_social_feed(text,timestamptz,integer),
  public.toggle_social_like(uuid), public.toggle_social_save(uuid), public.toggle_social_follow(uuid),
  public.add_social_comment(uuid,text,uuid), public.list_social_comments(uuid), public.toggle_social_repost(uuid,text),
  public.send_social_message_request(uuid,text), public.respond_social_message_request(uuid,boolean),
  public.send_social_message(uuid,text,uuid,text,text,uuid), public.get_social_inbox(), public.get_social_thread(uuid),
  public.block_social_user(uuid,boolean), public.report_social_content(text,text,uuid,uuid,uuid)
to authenticated;
grant execute on function public.review_institution_claim(uuid,text,text) to authenticated;

commit;
