begin;

create type public.enrolment_status as enum ('active', 'dropped', 'completed');

create or replace function private.validate_institution_time_zone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from pg_catalog.pg_timezone_names time_zone_record
    where time_zone_record.name = new.time_zone
  ) then
    raise exception using
      errcode = '23514',
      message = 'Institution time zone is invalid.',
      constraint = 'institutions_time_zone_valid';
  end if;
  return new;
end;
$$;

revoke all on function private.validate_institution_time_zone()
  from public, anon, authenticated, service_role;

alter table public.institutions
  add column time_zone text not null default 'UTC'
    check (
      time_zone = btrim(time_zone)
      and char_length(time_zone) between 1 and 64
    );

create trigger institutions_validate_time_zone_insert
before insert on public.institutions
for each row execute function private.validate_institution_time_zone();

create trigger institutions_validate_time_zone_update
before update of time_zone on public.institutions
for each row execute function private.validate_institution_time_zone();

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null
    references public.institutions(id) on delete cascade,
  code text not null
    check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,15}$'),
  name text not null
    check (name = btrim(name) and char_length(name) between 2 and 160),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institution_id, code),
  unique (id, institution_id)
);

create table public.programmes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  department_id uuid not null,
  code text not null
    check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,23}$'),
  name text not null
    check (name = btrim(name) and char_length(name) between 2 and 160),
  duration_semesters smallint not null
    check (duration_semesters between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (department_id, institution_id)
    references public.departments(id, institution_id) on delete restrict,
  unique (institution_id, code),
  unique (id, institution_id)
);

create table public.academic_periods (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null
    references public.institutions(id) on delete cascade,
  code text not null
    check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,23}$'),
  name text not null
    check (name = btrim(name) and char_length(name) between 2 and 120),
  starts_on date not null,
  ends_on date not null,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (starts_on <= ends_on),
  unique (institution_id, code),
  unique (id, institution_id)
);

create unique index academic_periods_one_current_per_institution_idx
  on public.academic_periods (institution_id)
  where is_current;

create table public.sections (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  programme_id uuid not null,
  academic_period_id uuid not null,
  code text not null
    check (code ~ '^[A-Z0-9][A-Z0-9_-]{0,23}$'),
  name text not null
    check (name = btrim(name) and char_length(name) between 1 and 120),
  semester_number smallint not null
    check (semester_number between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (programme_id, institution_id)
    references public.programmes(id, institution_id) on delete restrict,
  foreign key (academic_period_id, institution_id)
    references public.academic_periods(id, institution_id) on delete restrict,
  unique (institution_id, academic_period_id, code),
  unique (id, institution_id, academic_period_id)
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  department_id uuid not null,
  code text not null
    check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,23}$'),
  name text not null
    check (name = btrim(name) and char_length(name) between 2 and 160),
  credit_hours numeric(4, 1) not null default 0
    check (credit_hours between 0 and 40),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (department_id, institution_id)
    references public.departments(id, institution_id) on delete restrict,
  unique (institution_id, code),
  unique (id, institution_id)
);

create table public.course_offerings (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  academic_period_id uuid not null,
  subject_id uuid not null,
  section_id uuid not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (academic_period_id, institution_id)
    references public.academic_periods(id, institution_id) on delete restrict,
  foreign key (subject_id, institution_id)
    references public.subjects(id, institution_id) on delete restrict,
  foreign key (section_id, institution_id, academic_period_id)
    references public.sections(id, institution_id, academic_period_id)
    on delete restrict,
  unique (institution_id, academic_period_id, subject_id, section_id),
  unique (id, institution_id, academic_period_id)
);

create table public.faculty_assignments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  academic_period_id uuid not null,
  course_offering_id uuid not null,
  faculty_user_id uuid not null references auth.users(id) on delete restrict,
  is_active boolean not null default true,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (is_active = (ended_at is null)),
  check (ended_at is null or ended_at >= created_at),
  foreign key (course_offering_id, institution_id, academic_period_id)
    references public.course_offerings(id, institution_id, academic_period_id)
    on delete cascade,
  foreign key (institution_id, faculty_user_id)
    references public.institution_memberships(institution_id, user_id)
    on delete restrict,
  unique (
    institution_id,
    academic_period_id,
    course_offering_id,
    faculty_user_id
  ),
  unique (
    id,
    institution_id,
    academic_period_id,
    course_offering_id,
    faculty_user_id
  )
);

create table public.student_enrolments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  academic_period_id uuid not null,
  course_offering_id uuid not null,
  student_user_id uuid not null references auth.users(id) on delete restrict,
  status public.enrolment_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (course_offering_id, institution_id, academic_period_id)
    references public.course_offerings(id, institution_id, academic_period_id)
    on delete cascade,
  foreign key (institution_id, student_user_id)
    references public.institution_memberships(institution_id, user_id)
    on delete restrict,
  unique (
    institution_id,
    academic_period_id,
    course_offering_id,
    student_user_id
  ),
  unique (
    id,
    institution_id,
    academic_period_id,
    course_offering_id,
    student_user_id
  )
);

create table public.timetable_entries (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null,
  academic_period_id uuid not null,
  course_offering_id uuid not null,
  weekday smallint not null check (weekday between 1 and 7),
  starts_at time without time zone not null,
  ends_at time without time zone not null,
  room text not null
    check (room = btrim(room) and char_length(room) between 1 and 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (starts_at < ends_at),
  foreign key (course_offering_id, institution_id, academic_period_id)
    references public.course_offerings(id, institution_id, academic_period_id)
    on delete cascade,
  unique (institution_id, course_offering_id, weekday, starts_at),
  unique (
    id,
    institution_id,
    academic_period_id,
    course_offering_id
  )
);

create index programmes_department_idx
  on public.programmes (institution_id, department_id);
create index sections_programme_period_idx
  on public.sections (institution_id, programme_id, academic_period_id);
create index subjects_department_idx
  on public.subjects (institution_id, department_id);
create index course_offerings_section_idx
  on public.course_offerings (
    institution_id,
    academic_period_id,
    section_id,
    is_active
  );
create index faculty_assignments_user_idx
  on public.faculty_assignments (
    faculty_user_id,
    institution_id,
    is_active,
    academic_period_id,
    course_offering_id
  );
create index faculty_assignments_offering_active_idx
  on public.faculty_assignments (
    institution_id,
    course_offering_id,
    is_active,
    faculty_user_id
  );
create index student_enrolments_user_status_idx
  on public.student_enrolments (
    student_user_id,
    institution_id,
    status,
    academic_period_id,
    course_offering_id
  );
create index student_enrolments_offering_status_idx
  on public.student_enrolments (
    institution_id,
    course_offering_id,
    status,
    student_user_id
  );
create index timetable_entries_day_idx
  on public.timetable_entries (
    institution_id,
    academic_period_id,
    weekday,
    starts_at
  );

create trigger departments_set_updated_at
before update on public.departments
for each row execute function public.set_updated_at();
create trigger programmes_set_updated_at
before update on public.programmes
for each row execute function public.set_updated_at();
create trigger academic_periods_set_updated_at
before update on public.academic_periods
for each row execute function public.set_updated_at();
create trigger sections_set_updated_at
before update on public.sections
for each row execute function public.set_updated_at();
create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function public.set_updated_at();
create trigger course_offerings_set_updated_at
before update on public.course_offerings
for each row execute function public.set_updated_at();
create trigger faculty_assignments_set_updated_at
before update on public.faculty_assignments
for each row execute function public.set_updated_at();
create trigger student_enrolments_set_updated_at
before update on public.student_enrolments
for each row execute function public.set_updated_at();
create trigger timetable_entries_set_updated_at
before update on public.timetable_entries
for each row execute function public.set_updated_at();

create or replace function private.has_role(
  target_institution_id uuid,
  role_key text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.has_password_authentication()
  and exists (
    select 1
    from public.institution_memberships membership
    join public.institutions institution_record
      on institution_record.id = membership.institution_id
      and institution_record.is_active
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record
      on role_record.id = membership_role.role_id
    where membership.institution_id = target_institution_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
      and role_record.key = role_key
  );
$$;

create or replace function private.can_access_course_offering(
  target_institution_id uuid,
  target_course_offering_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_member(target_institution_id)
  and exists (
    select 1
    from public.course_offerings offering
    where offering.id = target_course_offering_id
      and offering.institution_id = target_institution_id
      and offering.is_active
      and (
        private.has_permission(target_institution_id, 'academics_manage')
        or (
          private.has_role(target_institution_id, 'faculty')
          and exists (
            select 1
            from public.faculty_assignments assignment
            where assignment.institution_id = target_institution_id
              and assignment.course_offering_id = target_course_offering_id
              and assignment.faculty_user_id = (select auth.uid())
              and assignment.is_active
          )
        )
        or (
          private.has_role(target_institution_id, 'student')
          and exists (
            select 1
            from public.student_enrolments enrolment
            where enrolment.institution_id = target_institution_id
              and enrolment.course_offering_id = target_course_offering_id
              and enrolment.student_user_id = (select auth.uid())
              and enrolment.status = 'active'
          )
        )
      )
  );
$$;

create or replace function private.can_read_course_roster(
  target_institution_id uuid,
  target_course_offering_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_member(target_institution_id)
  and (
    private.has_permission(target_institution_id, 'academics_manage')
    or (
      private.has_role(target_institution_id, 'faculty')
      and private.has_permission(target_institution_id, 'roster_read')
      and exists (
        select 1
        from public.faculty_assignments assignment
        where assignment.institution_id = target_institution_id
          and assignment.course_offering_id = target_course_offering_id
          and assignment.faculty_user_id = (select auth.uid())
          and assignment.is_active
      )
    )
  );
$$;

create or replace function private.can_record_course_attendance(
  target_institution_id uuid,
  target_course_offering_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_member(target_institution_id)
  and private.has_role(target_institution_id, 'faculty')
  and private.has_permission(target_institution_id, 'attendance_record')
  and exists (
    select 1
    from public.faculty_assignments assignment
    where assignment.institution_id = target_institution_id
      and assignment.course_offering_id = target_course_offering_id
      and assignment.faculty_user_id = (select auth.uid())
      and assignment.is_active
  );
$$;

revoke all on function private.has_role(uuid, text)
  from public, anon, authenticated, service_role;
revoke all on function private.can_access_course_offering(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function private.can_read_course_roster(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function private.can_record_course_attendance(uuid, uuid)
  from public, anon, authenticated, service_role;
grant execute on function private.has_role(uuid, text) to authenticated;
grant execute on function private.can_access_course_offering(uuid, uuid)
  to authenticated;
grant execute on function private.can_read_course_roster(uuid, uuid)
  to authenticated;
grant execute on function private.can_record_course_attendance(uuid, uuid)
  to authenticated;

alter table public.departments enable row level security;
alter table public.programmes enable row level security;
alter table public.academic_periods enable row level security;
alter table public.sections enable row level security;
alter table public.subjects enable row level security;
alter table public.course_offerings enable row level security;
alter table public.faculty_assignments enable row level security;
alter table public.student_enrolments enable row level security;
alter table public.timetable_entries enable row level security;

create policy departments_read_active_member
on public.departments for select to authenticated
using (private.is_active_member(institution_id));

create policy programmes_read_active_member
on public.programmes for select to authenticated
using (private.is_active_member(institution_id));

create policy academic_periods_read_active_member
on public.academic_periods for select to authenticated
using (private.is_active_member(institution_id));

create policy sections_read_active_member
on public.sections for select to authenticated
using (private.is_active_member(institution_id));

create policy subjects_read_active_member
on public.subjects for select to authenticated
using (private.is_active_member(institution_id));

create policy course_offerings_read_authorized
on public.course_offerings for select to authenticated
using (private.can_access_course_offering(institution_id, id));

create policy faculty_assignments_read_authorized
on public.faculty_assignments for select to authenticated
using (
  private.has_permission(institution_id, 'academics_manage')
  or (
    faculty_user_id = (select auth.uid())
    and private.can_access_course_offering(institution_id, course_offering_id)
  )
);

create policy student_enrolments_read_authorized
on public.student_enrolments for select to authenticated
using (
  (
    student_user_id = (select auth.uid())
    and private.can_access_course_offering(institution_id, course_offering_id)
  )
  or private.can_read_course_roster(institution_id, course_offering_id)
);

create policy timetable_entries_read_authorized
on public.timetable_entries for select to authenticated
using (private.can_access_course_offering(institution_id, course_offering_id));

revoke all on table
  public.departments,
  public.programmes,
  public.academic_periods,
  public.sections,
  public.subjects,
  public.course_offerings,
  public.faculty_assignments,
  public.student_enrolments,
  public.timetable_entries
from anon, authenticated, service_role;

grant select on table
  public.departments,
  public.programmes,
  public.academic_periods,
  public.sections,
  public.subjects,
  public.course_offerings,
  public.faculty_assignments,
  public.student_enrolments,
  public.timetable_entries
to authenticated;

grant select, insert, update, delete on table
  public.departments,
  public.programmes,
  public.academic_periods,
  public.sections,
  public.subjects,
  public.course_offerings,
  public.faculty_assignments,
  public.student_enrolments,
  public.timetable_entries
to service_role;

commit;
