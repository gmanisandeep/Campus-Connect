alter type public.student_progression_status
  add value if not exists 'graduated';

begin;

insert into public.roles (key, label)
values ('alumni', 'Alumni')
on conflict (key) do update set label = excluded.label;

alter table public.student_program_enrollments
  alter column current_year drop not null,
  drop constraint student_program_enrollments_current_year_check,
  add constraint student_program_enrollments_current_year_check check (
    (
      progression_status = 'graduated'
      and current_year is null
    )
    or (
      progression_status <> 'graduated'
      and current_year between 1 and 10
    )
  );

alter table public.student_progression_events
  alter column current_year drop not null,
  drop constraint student_progression_events_current_year_check,
  add constraint student_progression_events_current_year_check check (
    (
      progression_status = 'graduated'
      and current_year is null
    )
    or (
      progression_status <> 'graduated'
      and current_year between 1 and 10
    )
  );

alter function public.review_student_affiliation_request(
  uuid, boolean, smallint, text
) set schema private;

alter function private.review_student_affiliation_request(
  uuid, boolean, smallint, text
) rename to review_student_affiliation_request_v1;

revoke all on function private.review_student_affiliation_request_v1(
  uuid, boolean, smallint, text
) from public, anon, authenticated, service_role;

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
  request_record public.student_affiliation_requests%rowtype;
  programme_record public.institution_programmes%rowtype;
  membership_record public.institution_memberships%rowtype;
  enrollment_record public.student_program_enrollments%rowtype;
  alumni_role_id uuid;
  maximum_year smallint;
  current_calendar_year smallint := extract(year from now())::smallint;
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

  if not approve_request
     or request_record.progression_status <> 'graduated' then
    perform private.review_student_affiliation_request_v1(
      target_request_id,
      approve_request,
      new_verified_current_year,
      new_decision_note
    );
    return;
  end if;

  if new_verified_current_year is not null then
    raise exception using
      errcode = '22023',
      message = 'Graduated access must not include a current academic year.';
  end if;
  if request_record.programme_id is null
     or request_record.batch_start_year is null
     or request_record.expected_completion_year is null
     or request_record.expected_completion_year > current_calendar_year then
    raise exception using
      errcode = '22023',
      message = 'A completed programme batch is required for Alumni access.';
  end if;

  select programme.*
  into programme_record
  from public.institution_programmes programme
  where programme.id = request_record.programme_id
    and programme.institution_id = request_record.institution_id
    and programme.is_active
  for share;

  if programme_record.id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Programme is not available for this institution.';
  end if;

  maximum_year := ceil(programme_record.duration_months / 12.0)::smallint;

  update public.student_affiliation_requests request_value
  set progression_status = 'regular'
  where request_value.id = request_record.id;

  perform private.review_student_affiliation_request_v1(
    target_request_id,
    true,
    maximum_year,
    new_decision_note
  );

  select membership.*
  into membership_record
  from public.institution_memberships membership
  where membership.institution_id = request_record.institution_id
    and membership.user_id = request_record.user_id;

  select enrollment.*
  into enrollment_record
  from public.student_program_enrollments enrollment
  where enrollment.membership_id = membership_record.id
  for update;

  update public.student_program_enrollments enrollment
  set current_year = null,
      progression_status = 'graduated'
  where enrollment.id = enrollment_record.id;

  update public.student_progression_events progression_event
  set current_year = null,
      progression_status = 'graduated'
  where progression_event.id = (
    select event_record.id
    from public.student_progression_events event_record
    where event_record.enrollment_id = enrollment_record.id
    order by event_record.recorded_at desc, event_record.id desc
    limit 1
  );

  delete from public.membership_roles membership_role
  using public.roles role_record
  where membership_role.membership_id = membership_record.id
    and membership_role.role_id = role_record.id
    and role_record.key = 'student'
    and membership_role.assigned_by = current_user_id;

  select role_record.id
  into alumni_role_id
  from public.roles role_record
  where role_record.key = 'alumni';

  if alumni_role_id is null then
    raise exception using
      errcode = 'P0002',
      message = 'Alumni role is not configured.';
  end if;

  insert into public.membership_roles (
    membership_id,
    role_id,
    assigned_by
  ) values (
    membership_record.id,
    alumni_role_id,
    current_user_id
  )
  on conflict (membership_id, role_id) do nothing;

  update public.student_affiliation_requests request_value
  set progression_status = 'graduated',
      verified_current_year = null
  where request_value.id = request_record.id;
end;
$$;

revoke all on function public.review_student_affiliation_request(
  uuid, boolean, smallint, text
) from public, anon, authenticated, service_role;

grant execute on function public.review_student_affiliation_request(
  uuid, boolean, smallint, text
) to authenticated;

create or replace function private.prevent_existing_learner_affiliation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.institution_memberships membership
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record
      on role_record.id = membership_role.role_id
    where membership.user_id = new.user_id
      and membership.status = 'active'
      and role_record.key in ('student', 'alumni')
  ) then
    raise exception using
      errcode = '23505',
      message = 'An active Student or Alumni membership already exists.';
  end if;
  return new;
end;
$$;

create trigger affiliation_request_prevent_existing_learner
before insert on public.student_affiliation_requests
for each row execute function private.prevent_existing_learner_affiliation();

revoke all on function private.prevent_existing_learner_affiliation()
from public, anon, authenticated, service_role;

commit;
