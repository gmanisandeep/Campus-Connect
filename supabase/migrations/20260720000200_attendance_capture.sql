begin;

create type public.attendance_status as enum (
  'present',
  'absent',
  'late',
  'excused'
);

create table public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  academic_period_id uuid not null,
  course_offering_id uuid not null,
  timetable_entry_id uuid not null,
  session_date date not null,
  scheduled_starts_at timestamptz not null,
  submitted_by uuid not null,
  request_id uuid not null,
  request_hash text not null
    check (request_hash ~ '^[0-9a-f]{64}$'),
  submitted_at timestamptz not null default now(),
  foreign key (
    timetable_entry_id,
    institution_id,
    academic_period_id,
    course_offering_id
  ) references public.timetable_entries(
    id,
    institution_id,
    academic_period_id,
    course_offering_id
  ) on delete restrict,
  foreign key (
    institution_id,
    academic_period_id,
    course_offering_id,
    submitted_by
  ) references public.faculty_assignments(
    institution_id,
    academic_period_id,
    course_offering_id,
    faculty_user_id
  ) on delete restrict,
  unique (institution_id, request_id),
  unique (institution_id, course_offering_id, scheduled_starts_at),
  unique (institution_id, timetable_entry_id, session_date),
  unique (id, institution_id, academic_period_id, course_offering_id),
  unique (
    id,
    institution_id,
    academic_period_id,
    course_offering_id,
    submitted_by
  )
);

create table public.attendance_records (
  institution_id uuid not null,
  academic_period_id uuid not null,
  course_offering_id uuid not null,
  session_id uuid not null,
  student_enrolment_id uuid not null,
  student_user_id uuid not null,
  status public.attendance_status not null,
  marked_by uuid not null,
  marked_at timestamptz not null default now(),
  primary key (session_id, student_user_id),
  foreign key (
    session_id,
    institution_id,
    academic_period_id,
    course_offering_id,
    marked_by
  ) references public.attendance_sessions(
    id,
    institution_id,
    academic_period_id,
    course_offering_id,
    submitted_by
  ) on delete restrict,
  foreign key (
    student_enrolment_id,
    institution_id,
    academic_period_id,
    course_offering_id,
    student_user_id
  ) references public.student_enrolments(
    id,
    institution_id,
    academic_period_id,
    course_offering_id,
    student_user_id
  ) on delete restrict,
  foreign key (
    institution_id,
    academic_period_id,
    course_offering_id,
    marked_by
  ) references public.faculty_assignments(
    institution_id,
    academic_period_id,
    course_offering_id,
    faculty_user_id
  ) on delete restrict
);

create index attendance_sessions_schedule_idx
  on public.attendance_sessions (
    institution_id,
    session_date,
    course_offering_id,
    scheduled_starts_at
  );
create index attendance_sessions_submitter_idx
  on public.attendance_sessions (
    submitted_by,
    institution_id,
    submitted_at desc
  );
create index attendance_records_student_idx
  on public.attendance_records (
    student_user_id,
    institution_id,
    academic_period_id,
    course_offering_id,
    session_id
  );
create index attendance_records_offering_status_idx
  on public.attendance_records (
    institution_id,
    course_offering_id,
    status,
    session_id
  );

create or replace function private.protect_confirmed_timetable_entry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.attendance_sessions attendance_session
    where attendance_session.timetable_entry_id = old.id
  ) then
    raise exception using
      errcode = '23503',
      message = 'A timetable entry with confirmed attendance is immutable.';
  end if;
  return new;
end;
$$;

revoke all on function private.protect_confirmed_timetable_entry()
  from public, anon, authenticated, service_role;

create trigger timetable_entries_protect_confirmed_schedule
before update of
  institution_id,
  academic_period_id,
  course_offering_id,
  weekday,
  starts_at,
  ends_at,
  room
on public.timetable_entries
for each row execute function private.protect_confirmed_timetable_entry();

alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;

create policy attendance_sessions_read_authorized
on public.attendance_sessions for select to authenticated
using (private.can_access_course_offering(institution_id, course_offering_id));

create policy attendance_records_read_authorized
on public.attendance_records for select to authenticated
using (
  (
    student_user_id = (select auth.uid())
    and private.has_permission(institution_id, 'attendance_read_own')
    and private.can_access_course_offering(institution_id, course_offering_id)
  )
  or private.can_read_course_roster(institution_id, course_offering_id)
);

create or replace function public.get_my_academic_dashboard(
  target_institution_id uuid,
  target_role text,
  target_date date
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  institution_time_zone text;
  dashboard_date date;
  result jsonb;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  if target_institution_id is null then
    raise exception using
      errcode = '22023',
      message = 'Institution is required.';
  end if;

  select institution_record.time_zone
  into institution_time_zone
  from public.institutions institution_record
  where institution_record.id = target_institution_id
    and institution_record.is_active
    and private.is_active_member(institution_record.id);

  if institution_time_zone is null then
    raise exception using
      errcode = '42501',
      message = 'Active institution access is required.';
  end if;

  dashboard_date := coalesce(
    target_date,
    (now() at time zone institution_time_zone)::date
  );

  if target_role = 'student' then
    if not private.has_role(target_institution_id, 'student')
       or not private.has_permission(
         target_institution_id,
         'attendance_read_own'
       ) then
      raise exception using
        errcode = '42501',
        message = 'Student academic access is required.';
    end if;
  elsif target_role = 'faculty' then
    if not private.has_role(target_institution_id, 'faculty')
       or not private.has_permission(target_institution_id, 'roster_read') then
      raise exception using
        errcode = '42501',
        message = 'Faculty academic access is required.';
    end if;
  else
    raise exception using
      errcode = '42501',
      message = 'This role does not have an academic dashboard.';
  end if;

  select jsonb_build_object(
    'institution_id', target_institution_id,
    'role', target_role,
    'date', dashboard_date,
    'time_zone', institution_time_zone,
    'schedule', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'timetable_entry_id', timetable_entry.id,
            'course_offering_id', offering.id,
            'subject_code', subject_record.code,
            'subject_name', subject_record.name,
            'section_name', section_record.name,
            'starts_at', to_char(timetable_entry.starts_at, 'HH24:MI'),
            'ends_at', to_char(timetable_entry.ends_at, 'HH24:MI'),
            'room', timetable_entry.room,
            'attendance_session_id', attendance_session.id,
            'attendance_submitted', attendance_session.id is not null,
            'roster', case
              when target_role = 'faculty' then case
                when attendance_session.id is not null then coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'enrolment_id', confirmed_enrolment.id,
                        'student_user_id', attendance_record.student_user_id,
                        'display_name', coalesce(
                          confirmed_profile.display_name,
                          'Campus student'
                        ),
                        'status', attendance_record.status
                      )
                      order by
                        coalesce(
                          confirmed_profile.display_name,
                          'Campus student'
                        ),
                        attendance_record.student_user_id
                    )
                    from public.attendance_records attendance_record
                    join public.student_enrolments confirmed_enrolment
                      on confirmed_enrolment.id =
                        attendance_record.student_enrolment_id
                      and confirmed_enrolment.institution_id =
                        attendance_record.institution_id
                      and confirmed_enrolment.course_offering_id =
                        attendance_record.course_offering_id
                      and confirmed_enrolment.student_user_id =
                        attendance_record.student_user_id
                    left join public.profiles confirmed_profile
                      on confirmed_profile.user_id =
                        attendance_record.student_user_id
                    where attendance_record.session_id = attendance_session.id
                  ),
                  '[]'::jsonb
                )
                else coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'enrolment_id', enrolment.id,
                        'student_user_id', enrolment.student_user_id,
                        'display_name', coalesce(
                          profile_record.display_name,
                          'Campus student'
                        ),
                        'status', null
                      )
                      order by
                        coalesce(profile_record.display_name, 'Campus student'),
                        enrolment.student_user_id
                    )
                    from public.student_enrolments enrolment
                    left join public.profiles profile_record
                      on profile_record.user_id = enrolment.student_user_id
                    where enrolment.institution_id = target_institution_id
                      and enrolment.course_offering_id = offering.id
                      and enrolment.academic_period_id =
                        offering.academic_period_id
                      and enrolment.status = 'active'
                  ),
                  '[]'::jsonb
                )
              end
              else '[]'::jsonb
            end
          )
          order by timetable_entry.starts_at, subject_record.code
        )
        from public.timetable_entries timetable_entry
        join public.course_offerings offering
          on offering.id = timetable_entry.course_offering_id
          and offering.institution_id = timetable_entry.institution_id
          and offering.academic_period_id = timetable_entry.academic_period_id
          and offering.is_active
        join public.academic_periods academic_period
          on academic_period.id = timetable_entry.academic_period_id
          and academic_period.institution_id = timetable_entry.institution_id
          and dashboard_date between academic_period.starts_on
            and academic_period.ends_on
        join public.subjects subject_record
          on subject_record.id = offering.subject_id
          and subject_record.institution_id = offering.institution_id
        join public.sections section_record
          on section_record.id = offering.section_id
          and section_record.institution_id = offering.institution_id
        left join public.attendance_sessions attendance_session
          on attendance_session.institution_id = timetable_entry.institution_id
          and attendance_session.course_offering_id = offering.id
          and attendance_session.timetable_entry_id = timetable_entry.id
          and attendance_session.session_date = dashboard_date
        where timetable_entry.institution_id = target_institution_id
          and timetable_entry.weekday = extract(isodow from dashboard_date)::int
          and (
            (
              target_role = 'student'
              and exists (
                select 1
                from public.student_enrolments student_schedule_enrolment
                where student_schedule_enrolment.institution_id =
                  target_institution_id
                  and student_schedule_enrolment.course_offering_id = offering.id
                  and student_schedule_enrolment.academic_period_id =
                    offering.academic_period_id
                  and student_schedule_enrolment.student_user_id =
                    current_user_id
                  and student_schedule_enrolment.status = 'active'
              )
            )
            or (
              target_role = 'faculty'
              and exists (
                select 1
                from public.faculty_assignments faculty_schedule_assignment
                where faculty_schedule_assignment.institution_id =
                  target_institution_id
                  and faculty_schedule_assignment.course_offering_id = offering.id
                  and faculty_schedule_assignment.academic_period_id =
                    offering.academic_period_id
                  and faculty_schedule_assignment.faculty_user_id =
                    current_user_id
                  and faculty_schedule_assignment.is_active
              )
            )
          )
      ),
      '[]'::jsonb
    ),
    'attendance_summary', case
      when target_role = 'student' then coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'course_offering_id', offering.id,
              'subject_code', subject_record.code,
              'subject_name', subject_record.name,
              'attended_sessions', attendance_totals.attended_sessions,
              'total_sessions', attendance_totals.total_sessions,
              'excused_sessions', attendance_totals.excused_sessions,
              'percentage', case
                when attendance_totals.total_sessions = 0 then null
                else round(
                  attendance_totals.attended_sessions * 100.0
                  / attendance_totals.total_sessions,
                  2
                )
              end
            )
            order by subject_record.code
          )
          from public.student_enrolments enrolment
          join public.course_offerings offering
            on offering.id = enrolment.course_offering_id
            and offering.institution_id = enrolment.institution_id
            and offering.academic_period_id = enrolment.academic_period_id
            and offering.is_active
          join public.subjects subject_record
            on subject_record.id = offering.subject_id
            and subject_record.institution_id = offering.institution_id
          left join lateral (
            select
              count(attendance_record.session_id)::int as total_sessions,
              count(attendance_record.session_id) filter (
                where attendance_record.status in ('present', 'late')
              )::int as attended_sessions,
              count(attendance_record.session_id) filter (
                where attendance_record.status = 'excused'
              )::int as excused_sessions
            from public.attendance_records attendance_record
            join public.attendance_sessions attendance_session
              on attendance_session.id = attendance_record.session_id
              and attendance_session.institution_id =
                attendance_record.institution_id
              and attendance_session.course_offering_id =
                attendance_record.course_offering_id
            where attendance_record.institution_id = target_institution_id
              and attendance_record.course_offering_id = offering.id
              and attendance_record.student_user_id = current_user_id
              and attendance_session.session_date <= dashboard_date
              and attendance_session.scheduled_starts_at <= now()
          ) attendance_totals on true
          where enrolment.institution_id = target_institution_id
            and enrolment.student_user_id = current_user_id
            and enrolment.status = 'active'
        ),
        '[]'::jsonb
      )
      else '[]'::jsonb
    end
  ) into result;

  return result;
end;
$$;

create or replace function public.submit_attendance(
  target_institution_id uuid,
  target_course_offering_id uuid,
  target_timetable_entry_id uuid,
  target_session_date date,
  attendance_payload jsonb,
  request_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  selected_entry record;
  existing_session public.attendance_sessions%rowtype;
  normalized_payload jsonb;
  request_fingerprint text;
  payload_count integer;
  distinct_student_count integer;
  roster_count integer;
  new_session_id uuid;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  if target_institution_id is null
     or target_course_offering_id is null
     or target_timetable_entry_id is null
     or target_session_date is null
     or request_id is null then
    raise exception using
      errcode = '22023',
      message = 'A complete attendance request is required.';
  end if;

  if not private.can_record_course_attendance(
    target_institution_id,
    target_course_offering_id
  ) then
    raise exception using
      errcode = '42501',
      message = 'Attendance can only be recorded for an assigned class.';
  end if;

  if attendance_payload is null
     or jsonb_typeof(attendance_payload) <> 'array'
     or jsonb_array_length(attendance_payload) = 0 then
    raise exception using
      errcode = '22023',
      message = 'Attendance must contain the complete active roster.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(attendance_payload) payload_item
    where jsonb_typeof(payload_item) <> 'object'
      or coalesce(payload_item ->> 'student_user_id', '') !~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      or coalesce(payload_item ->> 'status', '') not in (
        'present',
        'absent',
        'late',
        'excused'
      )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Attendance contains an invalid student or status.';
  end if;

  select
    count(*)::int,
    count(distinct lower(payload_item ->> 'student_user_id'))::int,
    jsonb_agg(
      jsonb_build_object(
        'student_user_id', lower(payload_item ->> 'student_user_id'),
        'status', payload_item ->> 'status'
      )
      order by lower(payload_item ->> 'student_user_id')
    )
  into payload_count, distinct_student_count, normalized_payload
  from jsonb_array_elements(attendance_payload) payload_item;

  if payload_count <> distinct_student_count then
    raise exception using
      errcode = '22023',
      message = 'Attendance contains a duplicate student.';
  end if;

  request_fingerprint := encode(
    extensions.digest(normalized_payload::text, 'sha256'),
    'hex'
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(request_id::text, 0)
  );

  select attendance_session.*
  into existing_session
  from public.attendance_sessions attendance_session
  where attendance_session.institution_id = target_institution_id
    and attendance_session.request_id = submit_attendance.request_id
  for update;

  if existing_session.id is not null then
    if existing_session.course_offering_id <> target_course_offering_id
       or existing_session.timetable_entry_id <> target_timetable_entry_id
       or existing_session.session_date <> target_session_date
       or existing_session.request_hash <> request_fingerprint then
      raise exception using
        errcode = '22023',
        message = 'This attendance request identifier was already used.';
    end if;

    return public.get_my_academic_dashboard(
      target_institution_id,
      'faculty',
      target_session_date
    );
  end if;

  select
    timetable_entry.institution_id,
    timetable_entry.academic_period_id,
    timetable_entry.course_offering_id,
    timetable_entry.weekday,
    timetable_entry.starts_at,
    institution_record.time_zone,
    (now() at time zone institution_record.time_zone)::date as campus_today,
    (
      target_session_date + timetable_entry.starts_at
    ) at time zone institution_record.time_zone as scheduled_starts_at
  into selected_entry
  from public.timetable_entries timetable_entry
  join public.course_offerings offering
    on offering.id = timetable_entry.course_offering_id
    and offering.institution_id = timetable_entry.institution_id
    and offering.academic_period_id = timetable_entry.academic_period_id
    and offering.is_active
  join public.academic_periods academic_period
    on academic_period.id = timetable_entry.academic_period_id
    and academic_period.institution_id = timetable_entry.institution_id
    and target_session_date between academic_period.starts_on
      and academic_period.ends_on
  join public.institutions institution_record
    on institution_record.id = timetable_entry.institution_id
    and institution_record.is_active
  where timetable_entry.id = target_timetable_entry_id
    and timetable_entry.institution_id = target_institution_id
    and timetable_entry.course_offering_id = target_course_offering_id
    and timetable_entry.weekday =
      extract(isodow from target_session_date)::int
  for update of offering
  for share of timetable_entry, academic_period, institution_record;

  if selected_entry.institution_id is null then
    raise exception using
      errcode = '22023',
      message = 'The selected class does not occur on this date.';
  end if;

  if target_session_date <> selected_entry.campus_today then
    raise exception using
      errcode = '22023',
      message = 'Attendance can only be confirmed for today.''s class.';
  end if;

  if selected_entry.scheduled_starts_at > now() then
    raise exception using
      errcode = '22023',
      message = 'Attendance cannot be confirmed before the class starts.';
  end if;

  perform 1
  from public.institution_memberships membership
  join public.membership_roles faculty_membership_role
    on faculty_membership_role.membership_id = membership.id
  join public.roles faculty_role
    on faculty_role.id = faculty_membership_role.role_id
    and faculty_role.key = 'faculty'
  join public.membership_roles permission_membership_role
    on permission_membership_role.membership_id = membership.id
  join public.role_permissions role_permission
    on role_permission.role_id = permission_membership_role.role_id
  join public.permissions permission_record
    on permission_record.id = role_permission.permission_id
    and permission_record.key = 'attendance_record'
  join public.faculty_assignments assignment
    on assignment.institution_id = membership.institution_id
    and assignment.faculty_user_id = membership.user_id
    and assignment.course_offering_id = target_course_offering_id
    and assignment.academic_period_id = selected_entry.academic_period_id
    and assignment.is_active
  where membership.institution_id = target_institution_id
    and membership.user_id = current_user_id
    and membership.status = 'active'
  for share of
    membership,
    faculty_membership_role,
    faculty_role,
    permission_membership_role,
    role_permission,
    permission_record,
    assignment;

  if not found then
    raise exception using
      errcode = '42501',
      message = 'Attendance can only be recorded for an assigned class.';
  end if;

  if exists (
    select 1
    from public.attendance_sessions attendance_session
    where attendance_session.institution_id = target_institution_id
      and (
        (
          attendance_session.course_offering_id = target_course_offering_id
          and attendance_session.scheduled_starts_at =
            selected_entry.scheduled_starts_at
        )
        or (
          attendance_session.timetable_entry_id = target_timetable_entry_id
          and attendance_session.session_date = target_session_date
        )
      )
  ) then
    raise exception using
      errcode = '23505',
      message = 'Attendance is already confirmed for this class.';
  end if;

  perform 1
  from public.student_enrolments enrolment
  where enrolment.institution_id = target_institution_id
    and enrolment.course_offering_id = target_course_offering_id
    and enrolment.academic_period_id = selected_entry.academic_period_id
  for share;

  select count(*)::int
  into roster_count
  from public.student_enrolments enrolment
  where enrolment.institution_id = target_institution_id
    and enrolment.course_offering_id = target_course_offering_id
    and enrolment.academic_period_id = selected_entry.academic_period_id
    and enrolment.status = 'active';

  if roster_count = 0 or payload_count <> roster_count then
    raise exception using
      errcode = '22023',
      message = 'Attendance must contain the complete active roster.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(normalized_payload) payload_item
    where not exists (
      select 1
      from public.student_enrolments enrolment
      where enrolment.institution_id = target_institution_id
        and enrolment.course_offering_id = target_course_offering_id
        and enrolment.academic_period_id = selected_entry.academic_period_id
        and enrolment.student_user_id =
          (payload_item ->> 'student_user_id')::uuid
        and enrolment.status = 'active'
    )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Attendance contains a student outside the active roster.';
  end if;

  insert into public.attendance_sessions (
    institution_id,
    academic_period_id,
    course_offering_id,
    timetable_entry_id,
    session_date,
    scheduled_starts_at,
    submitted_by,
    request_id,
    request_hash
  ) values (
    target_institution_id,
    selected_entry.academic_period_id,
    target_course_offering_id,
    target_timetable_entry_id,
    target_session_date,
    selected_entry.scheduled_starts_at,
    current_user_id,
    request_id,
    request_fingerprint
  )
  returning id into new_session_id;

  insert into public.attendance_records (
    institution_id,
    academic_period_id,
    course_offering_id,
    session_id,
    student_enrolment_id,
    student_user_id,
    status,
    marked_by
  )
  select
    target_institution_id,
    selected_entry.academic_period_id,
    target_course_offering_id,
    new_session_id,
    enrolment.id,
    enrolment.student_user_id,
    (payload_item ->> 'status')::public.attendance_status,
    current_user_id
  from jsonb_array_elements(normalized_payload) payload_item
  join public.student_enrolments enrolment
    on enrolment.institution_id = target_institution_id
    and enrolment.course_offering_id = target_course_offering_id
    and enrolment.academic_period_id = selected_entry.academic_period_id
    and enrolment.student_user_id =
      (payload_item ->> 'student_user_id')::uuid
    and enrolment.status = 'active';

  return public.get_my_academic_dashboard(
    target_institution_id,
    'faculty',
    target_session_date
  );
end;
$$;

revoke all on function public.get_my_academic_dashboard(uuid, text, date)
  from public, anon, authenticated, service_role;
revoke all on function public.submit_attendance(
  uuid,
  uuid,
  uuid,
  date,
  jsonb,
  uuid
) from public, anon, authenticated, service_role;
grant execute on function public.get_my_academic_dashboard(uuid, text, date)
  to authenticated;
grant execute on function public.submit_attendance(
  uuid,
  uuid,
  uuid,
  date,
  jsonb,
  uuid
) to authenticated;

revoke all on table
  public.attendance_sessions,
  public.attendance_records
from anon, authenticated, service_role;

grant select (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  timetable_entry_id,
  session_date,
  scheduled_starts_at,
  submitted_at
) on public.attendance_sessions to authenticated;

grant select (
  institution_id,
  academic_period_id,
  course_offering_id,
  session_id,
  student_user_id,
  status,
  marked_at
) on public.attendance_records to authenticated;

grant select, insert, update, delete on table
  public.attendance_sessions,
  public.attendance_records
to service_role;

commit;
