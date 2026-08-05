begin;

create type public.affiliation_request_status as enum (
  'pending',
  'approved',
  'rejected',
  'cancelled'
);

insert into public.role_permissions (role_id, permission_id)
select role_record.id, permission_record.id
from public.roles role_record
cross join public.permissions permission_record
where role_record.key = 'institution_administrator'
  and permission_record.key = 'institution_manage'
on conflict (role_id, permission_id) do nothing;

create table public.student_affiliation_requests (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  official_name text not null check (
    official_name = btrim(official_name)
    and char_length(official_name) between 2 and 120
    and official_name !~ '[[:cntrl:]]'
  ),
  roll_number text not null check (
    roll_number = btrim(roll_number)
    and char_length(roll_number) between 2 and 64
    and roll_number !~ '[[:cntrl:]]'
  ),
  programme text not null check (
    programme = btrim(programme)
    and char_length(programme) between 2 and 160
    and programme !~ '[[:cntrl:]]'
  ),
  study_year smallint not null check (study_year between 1 and 8),
  status public.affiliation_request_status not null default 'pending',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  decision_note text check (
    decision_note is null
    or (
      decision_note = btrim(decision_note)
      and char_length(decision_note) between 2 and 500
      and decision_note !~ '[[:cntrl:]]'
    )
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint affiliation_review_state_valid check (
    (status = 'pending' and reviewed_by is null and reviewed_at is null)
    or (status = 'cancelled' and reviewed_by is null and reviewed_at is null)
    or (status = 'approved' and reviewed_by is not null and reviewed_at is not null)
    or (
      status = 'rejected'
      and reviewed_by is not null
      and reviewed_at is not null
      and decision_note is not null
    )
  )
);

create unique index affiliation_requests_one_pending_per_user_idx
  on public.student_affiliation_requests (user_id)
  where status = 'pending';

create unique index affiliation_requests_reserved_roll_idx
  on public.student_affiliation_requests (
    institution_id,
    lower(roll_number)
  )
  where status in ('pending', 'approved');

create index affiliation_requests_institution_status_created_idx
  on public.student_affiliation_requests (
    institution_id,
    status,
    created_at
  );

create trigger student_affiliation_requests_set_updated_at
before update on public.student_affiliation_requests
for each row execute function public.set_updated_at();

alter table public.student_affiliation_requests enable row level security;

create policy affiliation_requests_read_self
on public.student_affiliation_requests for select to authenticated
using (user_id = (select auth.uid()));

create policy affiliation_requests_read_institution_admin
on public.student_affiliation_requests for select to authenticated
using (
  private.has_permission(institution_id, 'institution_manage')
);

create or replace function public.list_active_institutions()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result jsonb;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', institution_record.id,
        'name', institution_record.name
      )
      order by institution_record.name, institution_record.id
    ),
    '[]'::jsonb
  )
  into result
  from public.institutions institution_record
  where institution_record.is_active;

  return result;
end;
$$;

create or replace function public.get_my_student_affiliation_request()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result jsonb;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  select jsonb_build_object(
    'id', request_record.id,
    'institution_id', institution_record.id,
    'institution_name', institution_record.name,
    'official_name', request_record.official_name,
    'roll_number', request_record.roll_number,
    'programme', request_record.programme,
    'study_year', request_record.study_year,
    'status', request_record.status,
    'decision_note', request_record.decision_note,
    'created_at', request_record.created_at,
    'updated_at', request_record.updated_at
  )
  into result
  from public.student_affiliation_requests request_record
  join public.institutions institution_record
    on institution_record.id = request_record.institution_id
  where request_record.user_id = current_user_id
    and request_record.status <> 'cancelled'
  order by
    case request_record.status
      when 'pending' then 0
      when 'rejected' then 1
      when 'approved' then 2
      else 3
    end,
    request_record.updated_at desc,
    request_record.id
  limit 1;

  return result;
end;
$$;

create or replace function public.submit_student_affiliation_request(
  target_institution_id uuid,
  new_official_name text,
  new_roll_number text,
  new_programme text,
  new_study_year smallint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_name text := btrim(new_official_name);
  normalized_roll text := btrim(new_roll_number);
  normalized_programme text := btrim(new_programme);
  request_id uuid;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  if normalized_name is null
     or char_length(normalized_name) not between 2 and 120
     or normalized_name ~ '[[:cntrl:]]' then
    raise exception using
      errcode = '22023',
      message = 'Official name must contain between 2 and 120 characters.';
  end if;
  if normalized_roll is null
     or char_length(normalized_roll) not between 2 and 64
     or normalized_roll ~ '[[:cntrl:]]' then
    raise exception using
      errcode = '22023',
      message = 'Roll number must contain between 2 and 64 characters.';
  end if;
  if normalized_programme is null
     or char_length(normalized_programme) not between 2 and 160
     or normalized_programme ~ '[[:cntrl:]]' then
    raise exception using
      errcode = '22023',
      message = 'Programme must contain between 2 and 160 characters.';
  end if;
  if new_study_year is null or new_study_year not between 1 and 8 then
    raise exception using
      errcode = '22023',
      message = 'Study year must be between 1 and 8.';
  end if;

  perform 1
  from public.institutions institution_record
  where institution_record.id = target_institution_id
    and institution_record.is_active
  for share;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'Institution is not available.';
  end if;

  perform 1
  from public.institution_memberships membership
  join public.membership_roles membership_role
    on membership_role.membership_id = membership.id
  join public.roles role_record
    on role_record.id = membership_role.role_id
  where membership.user_id = current_user_id
    and membership.status = 'active'
    and role_record.key = 'student'
  for share of membership, membership_role, role_record;

  if found then
    raise exception using
      errcode = '23505',
      message = 'An active student membership already exists.';
  end if;

  insert into public.student_affiliation_requests (
    institution_id,
    user_id,
    official_name,
    roll_number,
    programme,
    study_year
  ) values (
    target_institution_id,
    current_user_id,
    normalized_name,
    normalized_roll,
    normalized_programme,
    new_study_year
  )
  returning id into request_id;

  return public.get_my_student_affiliation_request();
exception
  when unique_violation then
    raise exception using
      errcode = '23505',
      message = 'A matching affiliation request is already pending.';
end;
$$;

create or replace function public.cancel_my_student_affiliation_request(
  target_request_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  update public.student_affiliation_requests request_record
  set status = 'cancelled'
  where request_record.id = target_request_id
    and request_record.user_id = current_user_id
    and request_record.status = 'pending';

  if not found then
    raise exception using
      errcode = '42501',
      message = 'Pending request cannot be cancelled.';
  end if;
end;
$$;

create or replace function public.list_pending_student_affiliation_requests(
  target_institution_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result jsonb;
begin
  if current_user_id is null
     or not private.has_permission(
       target_institution_id,
       'institution_manage'
     ) then
    raise exception using
      errcode = '42501',
      message = 'Institution administrator access is required.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', request_record.id,
        'institution_id', institution_record.id,
        'institution_name', institution_record.name,
        'user_id', request_record.user_id,
        'email', auth_user.email,
        'official_name', request_record.official_name,
        'roll_number', request_record.roll_number,
        'programme', request_record.programme,
        'study_year', request_record.study_year,
        'status', request_record.status,
        'created_at', request_record.created_at,
        'updated_at', request_record.updated_at
      )
      order by request_record.created_at, request_record.id
    ),
    '[]'::jsonb
  )
  into result
  from public.student_affiliation_requests request_record
  join public.institutions institution_record
    on institution_record.id = request_record.institution_id
  join auth.users auth_user
    on auth_user.id = request_record.user_id
  where request_record.institution_id = target_institution_id
    and request_record.status = 'pending';

  return result;
end;
$$;

create or replace function public.review_student_affiliation_request(
  target_request_id uuid,
  approve_request boolean,
  new_decision_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_note text := nullif(btrim(new_decision_note), '');
  request_record public.student_affiliation_requests%rowtype;
  membership_record public.institution_memberships%rowtype;
  student_role_id uuid;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  select request_value.*
  into request_record
  from public.student_affiliation_requests request_value
  where request_value.id = target_request_id
    and request_value.status = 'pending'
  for update;

  if request_record.id is null
     or not private.has_permission(
       request_record.institution_id,
       'institution_manage'
     ) then
    raise exception using
      errcode = '42501',
      message = 'Pending request cannot be reviewed.';
  end if;

  if not approve_request and (
    normalized_note is null
    or char_length(normalized_note) not between 2 and 500
    or normalized_note ~ '[[:cntrl:]]'
  ) then
    raise exception using
      errcode = '22023',
      message = 'A rejection reason between 2 and 500 characters is required.';
  end if;
  if approve_request and normalized_note is not null and (
    char_length(normalized_note) not between 2 and 500
    or normalized_note ~ '[[:cntrl:]]'
  ) then
    raise exception using
      errcode = '22023',
      message = 'Decision note must contain between 2 and 500 characters.';
  end if;

  if approve_request then
    select membership.*
    into membership_record
    from public.institution_memberships membership
    where membership.institution_id = request_record.institution_id
      and membership.user_id = request_record.user_id
    for update;

    if membership_record.status = 'suspended' then
      raise exception using
        errcode = '42501',
        message = 'A suspended membership cannot be approved through this flow.';
    end if;

    insert into public.profiles (
      user_id,
      display_name,
      profile_completed_at
    ) values (
      request_record.user_id,
      request_record.official_name,
      now()
    )
    on conflict (user_id) do update
    set display_name = excluded.display_name,
        profile_completed_at = coalesce(
          public.profiles.profile_completed_at,
          excluded.profile_completed_at
        );

    insert into public.institution_memberships (
      institution_id,
      user_id,
      status,
      accepted_at
    ) values (
      request_record.institution_id,
      request_record.user_id,
      'active',
      now()
    )
    on conflict (institution_id, user_id) do update
    set status = 'active',
        invitation_expires_at = null,
        accepted_at = now();

    select membership.*
    into membership_record
    from public.institution_memberships membership
    where membership.institution_id = request_record.institution_id
      and membership.user_id = request_record.user_id;

    select role_record.id
    into student_role_id
    from public.roles role_record
    where role_record.key = 'student';

    if student_role_id is null then
      raise exception using
        errcode = 'P0002',
        message = 'Student role is not configured.';
    end if;

    insert into public.membership_roles (
      membership_id,
      role_id,
      assigned_by
    ) values (
      membership_record.id,
      student_role_id,
      current_user_id
    )
    on conflict (membership_id, role_id) do nothing;
  end if;

  update public.student_affiliation_requests request_value
  set status = case
        when approve_request then 'approved'::public.affiliation_request_status
        else 'rejected'::public.affiliation_request_status
      end,
      reviewed_by = current_user_id,
      reviewed_at = now(),
      decision_note = normalized_note
  where request_value.id = request_record.id;
end;
$$;

revoke all on table public.student_affiliation_requests
  from public, anon, authenticated, service_role;
grant select on table public.student_affiliation_requests to authenticated;
grant select, insert, update, delete on table public.student_affiliation_requests
  to service_role;

revoke all on function public.list_active_institutions()
  from public, anon, authenticated, service_role;
revoke all on function public.get_my_student_affiliation_request()
  from public, anon, authenticated, service_role;
revoke all on function public.submit_student_affiliation_request(
  uuid, text, text, text, smallint
) from public, anon, authenticated, service_role;
revoke all on function public.cancel_my_student_affiliation_request(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.list_pending_student_affiliation_requests(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.review_student_affiliation_request(
  uuid, boolean, text
) from public, anon, authenticated, service_role;

grant execute on function public.list_active_institutions()
  to authenticated;
grant execute on function public.get_my_student_affiliation_request()
  to authenticated;
grant execute on function public.submit_student_affiliation_request(
  uuid, text, text, text, smallint
) to authenticated;
grant execute on function public.cancel_my_student_affiliation_request(uuid)
  to authenticated;
grant execute on function public.list_pending_student_affiliation_requests(uuid)
  to authenticated;
grant execute on function public.review_student_affiliation_request(
  uuid, boolean, text
) to authenticated;

commit;
