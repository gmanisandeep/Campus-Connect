begin;

create type public.student_progression_status as enum (
  'regular',
  'on_leave',
  'repeating',
  'lateral_entry',
  'graduated'
);

create table public.institution_programmes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  name text not null check (
    name = btrim(name)
    and char_length(name) between 2 and 160
    and name !~ '[[:cntrl:]]'
  ),
  duration_months smallint not null check (duration_months between 6 and 120),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institution_id, id)
);

create unique index institution_programmes_name_idx
  on public.institution_programmes (institution_id, lower(name));

create trigger institution_programmes_set_updated_at
before update on public.institution_programmes
for each row execute function public.set_updated_at();

alter table public.student_affiliation_requests
  add column programme_id uuid,
  add column batch_start_year smallint,
  add column expected_completion_year smallint,
  add column progression_status public.student_progression_status,
  add column verified_current_year smallint;

alter table public.student_affiliation_requests
  alter column study_year drop not null,
  add constraint affiliation_request_programme_scope_fk
    foreign key (institution_id, programme_id)
    references public.institution_programmes (institution_id, id),
  add constraint affiliation_request_batch_years_valid check (
    (batch_start_year is null and expected_completion_year is null)
    or (
      batch_start_year between 2000 and 2100
      and expected_completion_year between batch_start_year + 1
        and batch_start_year + 12
    )
  ),
  add constraint affiliation_request_progression_payload_valid check (
    (programme_id is null and progression_status is null)
    or (programme_id is not null and progression_status is not null)
  ),
  add constraint affiliation_request_verified_year_valid check (
    verified_current_year is null
    or verified_current_year between 1 and 10
  );

alter table public.institution_memberships
  add constraint institution_memberships_identity_scope_unique
  unique (id, institution_id, user_id);

create table public.student_program_enrollments (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null unique
    references public.institution_memberships(id) on delete cascade,
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  programme_id uuid not null,
  roll_number text not null check (
    roll_number = btrim(roll_number)
    and char_length(roll_number) between 2 and 64
    and roll_number !~ '[[:cntrl:]]'
  ),
  batch_start_year smallint not null check (batch_start_year between 2000 and 2100),
  expected_completion_year smallint not null,
  current_year smallint not null check (current_year between 1 and 10),
  progression_status public.student_progression_status not null,
  verified_by uuid not null references auth.users(id) on delete restrict,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_enrollment_membership_scope_fk
    foreign key (membership_id, institution_id, user_id)
    references public.institution_memberships (id, institution_id, user_id),
  constraint student_enrollment_programme_scope_fk
    foreign key (institution_id, programme_id)
    references public.institution_programmes (institution_id, id),
  constraint student_enrollment_batch_years_valid check (
    expected_completion_year between batch_start_year + 1
      and batch_start_year + 12
  ),
  unique (id, institution_id, user_id),
  unique (institution_id, user_id)
);

create unique index student_enrollments_roll_casefold_idx
  on public.student_program_enrollments (institution_id, lower(roll_number));

create trigger student_program_enrollments_set_updated_at
before update on public.student_program_enrollments
for each row execute function public.set_updated_at();

create table public.student_progression_events (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null
    references public.student_program_enrollments(id) on delete cascade,
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  current_year smallint not null check (current_year between 1 and 10),
  progression_status public.student_progression_status not null,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  recorded_at timestamptz not null default now(),
  note text check (
    note is null
    or (
      note = btrim(note)
      and char_length(note) between 2 and 500
      and note !~ '[[:cntrl:]]'
    )
  ),
  constraint progression_event_enrollment_scope_fk
    foreign key (enrollment_id, institution_id, user_id)
    references public.student_program_enrollments (id, institution_id, user_id)
);

create index progression_events_enrollment_recorded_idx
  on public.student_progression_events (enrollment_id, recorded_at, id);

alter table public.institution_programmes enable row level security;
alter table public.student_program_enrollments enable row level security;
alter table public.student_progression_events enable row level security;

create policy institution_programmes_read_member
on public.institution_programmes for select to authenticated
using (private.is_active_member(institution_id));

create policy student_enrollments_read_self
on public.student_program_enrollments for select to authenticated
using (
  user_id = (select auth.uid())
  and private.has_password_authentication()
);

create policy student_enrollments_read_institution_admin
on public.student_program_enrollments for select to authenticated
using (private.has_permission(institution_id, 'institution_manage'));

create policy progression_events_read_self
on public.student_progression_events for select to authenticated
using (
  user_id = (select auth.uid())
  and private.has_password_authentication()
);

create policy progression_events_read_institution_admin
on public.student_progression_events for select to authenticated
using (private.has_permission(institution_id, 'institution_manage'));

create or replace function public.list_active_programmes()
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
        'id', programme_record.id,
        'institution_id', programme_record.institution_id,
        'name', programme_record.name,
        'duration_months', programme_record.duration_months
      )
      order by institution_record.name, programme_record.name, programme_record.id
    ),
    '[]'::jsonb
  )
  into result
  from public.institution_programmes programme_record
  join public.institutions institution_record
    on institution_record.id = programme_record.institution_id
  where institution_record.is_active
    and programme_record.is_active;

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
    'programme_id', request_record.programme_id,
    'programme', request_record.programme,
    'duration_months', programme_record.duration_months,
    'official_name', request_record.official_name,
    'roll_number', request_record.roll_number,
    'batch_start_year', request_record.batch_start_year,
    'expected_completion_year', request_record.expected_completion_year,
    'progression_status', request_record.progression_status,
    'verified_current_year', request_record.verified_current_year,
    'status', request_record.status,
    'decision_note', request_record.decision_note,
    'created_at', request_record.created_at,
    'updated_at', request_record.updated_at
  )
  into result
  from public.student_affiliation_requests request_record
  join public.institutions institution_record
    on institution_record.id = request_record.institution_id
  left join public.institution_programmes programme_record
    on programme_record.id = request_record.programme_id
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
  target_programme_id uuid,
  new_official_name text,
  new_roll_number text,
  new_batch_start_year smallint,
  new_expected_completion_year smallint,
  new_progression_status public.student_progression_status
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
  programme_record public.institution_programmes%rowtype;
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
  if new_batch_start_year is null
     or new_batch_start_year not between 2000 and 2100
     or new_expected_completion_year is null
     or new_expected_completion_year not between new_batch_start_year + 1
       and new_batch_start_year + 12
     or new_progression_status is null then
    raise exception using
      errcode = '22023',
      message = 'A valid batch and progression status are required.';
  end if;

  select programme.*
  into programme_record
  from public.institution_programmes programme
  join public.institutions institution_record
    on institution_record.id = programme.institution_id
  where programme.id = target_programme_id
    and programme.institution_id = target_institution_id
    and programme.is_active
    and institution_record.is_active
  for share of programme, institution_record;

  if programme_record.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Programme is not available for this institution.';
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
    programme_id,
    programme,
    study_year,
    batch_start_year,
    expected_completion_year,
    progression_status
  ) values (
    target_institution_id,
    current_user_id,
    normalized_name,
    normalized_roll,
    programme_record.id,
    programme_record.name,
    null,
    new_batch_start_year,
    new_expected_completion_year,
    new_progression_status
  );

  return public.get_my_student_affiliation_request();
exception
  when unique_violation then
    raise exception using
      errcode = '23505',
      message = 'A matching affiliation request is already pending.';
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
        'programme_id', request_record.programme_id,
        'programme', request_record.programme,
        'duration_months', programme_record.duration_months,
        'user_id', request_record.user_id,
        'email', auth_user.email,
        'official_name', request_record.official_name,
        'roll_number', request_record.roll_number,
        'batch_start_year', request_record.batch_start_year,
        'expected_completion_year', request_record.expected_completion_year,
        'progression_status', request_record.progression_status,
        'verified_current_year', request_record.verified_current_year,
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
  left join public.institution_programmes programme_record
    on programme_record.id = request_record.programme_id
  where request_record.institution_id = target_institution_id
    and request_record.status = 'pending';

  return result;
end;
$$;

create or replace function public.review_student_affiliation_request(
  target_request_id uuid,
  approve_request boolean,
  new_verified_current_year smallint,
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
  programme_record public.institution_programmes%rowtype;
  membership_record public.institution_memberships%rowtype;
  enrollment_record public.student_program_enrollments%rowtype;
  student_role_id uuid;
  maximum_year smallint;
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
    if request_record.programme_id is null
       or request_record.batch_start_year is null
       or request_record.expected_completion_year is null
       or request_record.progression_status is null then
      raise exception using
        errcode = '22023',
        message = 'The student must resubmit programme and batch details.';
    end if;

    select programme.*
    into programme_record
    from public.institution_programmes programme
    where programme.id = request_record.programme_id
      and programme.institution_id = request_record.institution_id
      and programme.is_active
    for share;

    maximum_year := ceil(programme_record.duration_months / 12.0)::smallint;
    if programme_record.id is null
       or new_verified_current_year is null
       or new_verified_current_year not between 1 and maximum_year then
      raise exception using
        errcode = '22023',
        message = 'A valid college-verified current year is required.';
    end if;

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

    insert into public.student_program_enrollments (
      membership_id,
      institution_id,
      user_id,
      programme_id,
      roll_number,
      batch_start_year,
      expected_completion_year,
      current_year,
      progression_status,
      verified_by,
      verified_at
    ) values (
      membership_record.id,
      request_record.institution_id,
      request_record.user_id,
      request_record.programme_id,
      request_record.roll_number,
      request_record.batch_start_year,
      request_record.expected_completion_year,
      new_verified_current_year,
      request_record.progression_status,
      current_user_id,
      now()
    )
    on conflict (membership_id) do update
    set programme_id = excluded.programme_id,
        roll_number = excluded.roll_number,
        batch_start_year = excluded.batch_start_year,
        expected_completion_year = excluded.expected_completion_year,
        current_year = excluded.current_year,
        progression_status = excluded.progression_status,
        verified_by = excluded.verified_by,
        verified_at = excluded.verified_at
    returning * into enrollment_record;

    insert into public.student_progression_events (
      enrollment_id,
      institution_id,
      user_id,
      current_year,
      progression_status,
      recorded_by,
      note
    ) values (
      enrollment_record.id,
      enrollment_record.institution_id,
      enrollment_record.user_id,
      enrollment_record.current_year,
      enrollment_record.progression_status,
      current_user_id,
      normalized_note
    );
  end if;

  update public.student_affiliation_requests request_value
  set status = case
        when approve_request then 'approved'::public.affiliation_request_status
        else 'rejected'::public.affiliation_request_status
      end,
      verified_current_year = case
        when approve_request then new_verified_current_year
        else null
      end,
      reviewed_by = current_user_id,
      reviewed_at = now(),
      decision_note = normalized_note
  where request_value.id = request_record.id;
end;
$$;

revoke all on table
  public.institution_programmes,
  public.student_program_enrollments,
  public.student_progression_events
from public, anon, authenticated, service_role;

grant select on table
  public.institution_programmes,
  public.student_program_enrollments,
  public.student_progression_events
to authenticated;

grant select, insert, update, delete on table
  public.institution_programmes,
  public.student_program_enrollments,
  public.student_progression_events
to service_role;

revoke all on function public.list_active_programmes()
  from public, anon, authenticated, service_role;
revoke all on function public.submit_student_affiliation_request(
  uuid, uuid, text, text, smallint, smallint,
  public.student_progression_status
) from public, anon, authenticated, service_role;
revoke all on function public.review_student_affiliation_request(
  uuid, boolean, smallint, text
) from public, anon, authenticated, service_role;

revoke execute on function public.submit_student_affiliation_request(
  uuid, text, text, text, smallint
) from authenticated;
revoke execute on function public.review_student_affiliation_request(
  uuid, boolean, text
) from authenticated;

grant execute on function public.list_active_programmes()
  to authenticated;
grant execute on function public.submit_student_affiliation_request(
  uuid, uuid, text, text, smallint, smallint,
  public.student_progression_status
) to authenticated;
grant execute on function public.review_student_affiliation_request(
  uuid, boolean, smallint, text
) to authenticated;

commit;
