begin;

create extension if not exists pgtap with schema extensions;

select plan(93);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_column(
  'public',
  'institutions',
  'time_zone',
  'institutions define the campus time zone used by academic schedules'
);

select has_table('public', 'departments', 'departments table exists');
select has_table('public', 'programmes', 'programmes table exists');
select has_table('public', 'academic_periods', 'academic periods table exists');
select has_table('public', 'sections', 'sections table exists');
select has_table('public', 'subjects', 'subjects table exists');
select has_table('public', 'course_offerings', 'course offerings table exists');
select has_table('public', 'faculty_assignments', 'faculty assignments table exists');
select has_table('public', 'student_enrolments', 'student enrolments table exists');
select has_table('public', 'timetable_entries', 'timetable entries table exists');
select has_table('public', 'attendance_sessions', 'attendance sessions table exists');
select has_table('public', 'attendance_records', 'attendance records table exists');
select has_column(
  'public',
  'faculty_assignments',
  'is_active',
  'faculty assignments expose an explicit active state'
);
select has_column(
  'public',
  'faculty_assignments',
  'ended_at',
  'faculty assignments retain their revocation timestamp'
);

select has_function(
  'private',
  'validate_institution_time_zone',
  array[]::text[],
  'private institution time-zone validator exists'
);
select has_function(
  'private',
  'has_role',
  array['uuid', 'text'],
  'private role helper exists'
);
select has_function(
  'private',
  'can_access_course_offering',
  array['uuid', 'uuid'],
  'private offering access helper exists'
);
select has_function(
  'private',
  'can_read_course_roster',
  array['uuid', 'uuid'],
  'private roster helper exists'
);
select has_function(
  'private',
  'can_record_course_attendance',
  array['uuid', 'uuid'],
  'private attendance-recording helper exists'
);
select has_function(
  'public',
  'get_my_academic_dashboard',
  array['uuid', 'text', 'date'],
  'academic dashboard RPC exists'
);
select has_function(
  'public',
  'submit_attendance',
  array['uuid', 'uuid', 'uuid', 'date', 'jsonb', 'uuid'],
  'attendance submission RPC exists'
);

select results_eq(
  $$
    select enum_value.enumlabel
    from pg_catalog.pg_enum enum_value
    join pg_catalog.pg_type enum_type
      on enum_type.oid = enum_value.enumtypid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public'
      and enum_type.typname = 'enrolment_status'
    order by enum_value.enumsortorder
  $$,
  array['active'::name, 'dropped'::name, 'completed'::name],
  'enrolment status uses the expected values'
);
select results_eq(
  $$
    select enum_value.enumlabel
    from pg_catalog.pg_enum enum_value
    join pg_catalog.pg_type enum_type
      on enum_type.oid = enum_value.enumtypid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public'
      and enum_type.typname = 'attendance_status'
    order by enum_value.enumsortorder
  $$,
  array['present'::name, 'absent'::name, 'late'::name, 'excused'::name],
  'attendance status uses the expected values'
);
select ok(
  exists (
    select 1
    from pg_catalog.pg_constraint constraint_record
    join pg_catalog.pg_class relation
      on relation.oid = constraint_record.conrelid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = 'attendance_sessions'
      and constraint_record.contype = 'u'
      and position(
        'UNIQUE (institution_id, timetable_entry_id, session_date)'
        in pg_catalog.pg_get_constraintdef(constraint_record.oid)
      ) > 0
  ),
  'attendance sessions enforce one confirmation per timetable entry and date'
);

select is_empty(
  $$
    select relation.relname
    from pg_catalog.pg_class relation
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any (
        array[
          'departments',
          'programmes',
          'academic_periods',
          'sections',
          'subjects',
          'course_offerings',
          'faculty_assignments',
          'student_enrolments',
          'timetable_entries'
        ]
      )
      and not relation.relrowsecurity
  $$,
  'RLS is enabled on every academic table'
);
select is_empty(
  $$
    select relation.relname
    from pg_catalog.pg_class relation
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any (
        array['attendance_sessions', 'attendance_records']
      )
      and not relation.relrowsecurity
  $$,
  'RLS is enabled on every attendance table'
);

select policies_are(
  'public',
  'departments',
  array['departments_read_active_member'],
  'departments use the expected policy set'
);
select policies_are(
  'public',
  'programmes',
  array['programmes_read_active_member'],
  'programmes use the expected policy set'
);
select policies_are(
  'public',
  'academic_periods',
  array['academic_periods_read_active_member'],
  'academic periods use the expected policy set'
);
select policies_are(
  'public',
  'sections',
  array['sections_read_active_member'],
  'sections use the expected policy set'
);
select policies_are(
  'public',
  'subjects',
  array['subjects_read_active_member'],
  'subjects use the expected policy set'
);
select policies_are(
  'public',
  'course_offerings',
  array['course_offerings_read_authorized'],
  'course offerings use the expected policy set'
);
select policies_are(
  'public',
  'faculty_assignments',
  array['faculty_assignments_read_authorized'],
  'faculty assignments use the expected policy set'
);
select policies_are(
  'public',
  'student_enrolments',
  array['student_enrolments_read_authorized'],
  'student enrolments use the expected policy set'
);
select policies_are(
  'public',
  'timetable_entries',
  array['timetable_entries_read_authorized'],
  'timetable entries use the expected policy set'
);
select policies_are(
  'public',
  'attendance_sessions',
  array['attendance_sessions_read_authorized'],
  'attendance sessions use the expected policy set'
);
select policies_are(
  'public',
  'attendance_records',
  array['attendance_records_read_authorized'],
  'attendance records use the expected policy set'
);

select ok(
  not has_function_privilege(
    'anon',
    'private.validate_institution_time_zone()',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.validate_institution_time_zone()',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.validate_institution_time_zone()',
    'execute'
  ),
  'the time-zone trigger function is not directly executable by API roles'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'departments',
        'programmes',
        'academic_periods',
        'sections',
        'subjects',
        'course_offerings',
        'faculty_assignments',
        'student_enrolments',
        'timetable_entries',
        'attendance_sessions',
        'attendance_records'
      ]
    ) academic_table(table_name)
    where has_table_privilege(
      'anon',
      format('public.%I', academic_table.table_name),
      'select,insert,update,delete,truncate,references,trigger'
    )
  ),
  'anonymous requests have no academic or attendance table privileges'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'departments',
        'programmes',
        'academic_periods',
        'sections',
        'subjects',
        'course_offerings',
        'faculty_assignments',
        'student_enrolments',
        'timetable_entries'
      ]
    ) academic_table(table_name)
    where not has_table_privilege(
      'authenticated',
      format('public.%I', academic_table.table_name),
      'select'
    )
  ),
  'authenticated requests receive academic reference reads subject to RLS'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'public.attendance_sessions',
    'select'
  )
  and not has_table_privilege(
    'authenticated',
    'public.attendance_records',
    'select'
  ),
  'authenticated requests receive no table-wide attendance reads'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'id',
        'institution_id',
        'academic_period_id',
        'course_offering_id',
        'timetable_entry_id',
        'session_date',
        'scheduled_starts_at',
        'submitted_at'
      ]
    ) allowed_column(column_name)
    where not has_column_privilege(
      'authenticated',
      'public.attendance_sessions',
      allowed_column.column_name,
      'select'
    )
  ),
  'authenticated requests can select only the app-facing session fields'
);
select ok(
  not exists (
    select 1
    from unnest(array['submitted_by', 'request_id', 'request_hash'])
      sensitive_column(column_name)
    where has_column_privilege(
      'authenticated',
      'public.attendance_sessions',
      sensitive_column.column_name,
      'select'
    )
  ),
  'attendance submission identity and idempotency fields remain private'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'institution_id',
        'academic_period_id',
        'course_offering_id',
        'session_id',
        'student_user_id',
        'status',
        'marked_at'
      ]
    ) allowed_column(column_name)
    where not has_column_privilege(
      'authenticated',
      'public.attendance_records',
      allowed_column.column_name,
      'select'
    )
  ),
  'authenticated requests can select only the app-facing record fields'
);
select ok(
  not exists (
    select 1
    from unnest(array['student_enrolment_id', 'marked_by'])
      sensitive_column(column_name)
    where has_column_privilege(
      'authenticated',
      'public.attendance_records',
      sensitive_column.column_name,
      'select'
    )
  ),
  'attendance enrolment linkage and marking actor remain private'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'departments',
        'programmes',
        'academic_periods',
        'sections',
        'subjects',
        'course_offerings',
        'faculty_assignments',
        'student_enrolments',
        'timetable_entries',
        'attendance_sessions',
        'attendance_records'
      ]
    ) academic_table(table_name)
    where has_table_privilege(
      'authenticated',
      format('public.%I', academic_table.table_name),
      'insert,update,delete,truncate,references,trigger'
    )
  ),
  'authenticated requests receive no direct academic writes'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'departments',
        'programmes',
        'academic_periods',
        'sections',
        'subjects',
        'course_offerings',
        'faculty_assignments',
        'student_enrolments',
        'timetable_entries',
        'attendance_sessions',
        'attendance_records'
      ]
    ) academic_table(table_name)
    cross join unnest(array['select', 'insert', 'update', 'delete']) privilege_name
    where not has_table_privilege(
      'service_role',
      format('public.%I', academic_table.table_name),
      privilege_name
    )
  ),
  'service role receives deliberate academic table DML access'
);

select ok(
  not exists (
    select 1
    from unnest(
      array[
        'private.has_role(uuid,text)',
        'private.can_access_course_offering(uuid,uuid)',
        'private.can_read_course_roster(uuid,uuid)',
        'private.can_record_course_attendance(uuid,uuid)'
      ]
    ) helper(signature)
    where not has_function_privilege('authenticated', helper.signature, 'execute')
  ),
  'authenticated policies can execute every private academic helper'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'private.has_role(uuid,text)',
        'private.can_access_course_offering(uuid,uuid)',
        'private.can_read_course_roster(uuid,uuid)',
        'private.can_record_course_attendance(uuid,uuid)'
      ]
    ) helper(signature)
    where has_function_privilege('anon', helper.signature, 'execute')
  ),
  'anonymous requests cannot execute private academic helpers'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_academic_dashboard(uuid,text,date)',
    'execute'
  ),
  'authenticated requests can execute the academic dashboard RPC'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.submit_attendance(uuid,uuid,uuid,date,jsonb,uuid)',
    'execute'
  ),
  'authenticated requests can execute attendance submission'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.get_my_academic_dashboard(uuid,text,date)',
    'execute'
  ),
  'anonymous requests cannot execute the academic dashboard RPC'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.submit_attendance(uuid,uuid,uuid,date,jsonb,uuid)',
    'execute'
  ),
  'anonymous requests cannot submit attendance'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.get_my_academic_dashboard(uuid,text,date)',
    'execute'
  ),
  'service role cannot impersonate a user through the dashboard RPC'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.submit_attendance(uuid,uuid,uuid,date,jsonb,uuid)',
    'execute'
  ),
  'service role cannot impersonate a user through attendance submission'
);
select results_eq(
  $$
    select count(*) = 2 and bool_and(function_record.prosecdef)
    from pg_catalog.pg_proc function_record
    join pg_catalog.pg_namespace namespace
      on namespace.oid = function_record.pronamespace
    where namespace.nspname = 'public'
      and function_record.proname = any (
        array['get_my_academic_dashboard', 'submit_attendance']
      )
  $$,
  array[true],
  'academic RPCs consistently enforce checks as security definers'
);
select results_eq(
  $$
    select count(*) = 2 and bool_and(function_record.provolatile = 'v')
    from pg_catalog.pg_proc function_record
    join pg_catalog.pg_namespace namespace
      on namespace.oid = function_record.pronamespace
    where namespace.nspname = 'public'
      and function_record.proname = any (
        array['get_my_academic_dashboard', 'submit_attendance']
      )
  $$,
  array[true],
  'academic RPCs return fresh state after attendance mutation'
);

select throws_ok(
  $$insert into public.institutions (
      id,
      slug,
      name,
      is_active,
      time_zone
    ) values (
      '92999999-0000-4000-8000-000000000001'::uuid,
      'invalid-time-zone-fixture',
      'Invalid Time Zone Fixture',
      true,
      'Mars/Olympus'
    )$$,
  '23514',
  'Institution time zone is invalid.',
  'institution writes reject an unrecognized IANA time zone'
);

insert into auth.users (id, email) values
  ('91000000-0000-4000-8000-000000000001', 'academic-student@example.invalid'),
  ('91000000-0000-4000-8000-000000000002', 'academic-faculty@example.invalid'),
  ('91000000-0000-4000-8000-000000000003', 'academic-unassigned@example.invalid'),
  ('91000000-0000-4000-8000-000000000004', 'academic-suspended@example.invalid'),
  ('91000000-0000-4000-8000-000000000005', 'academic-beta-faculty@example.invalid');

update public.profiles profile_record
set
  display_name = fixture.display_name,
  profile_completed_at = now()
from (
  values
    ('91000000-0000-4000-8000-000000000001'::uuid, 'Academic Student'::text),
    ('91000000-0000-4000-8000-000000000002'::uuid, 'Assigned Faculty'::text),
    ('91000000-0000-4000-8000-000000000003'::uuid, 'Unassigned Faculty'::text),
    ('91000000-0000-4000-8000-000000000004'::uuid, 'Suspended Student'::text),
    ('91000000-0000-4000-8000-000000000005'::uuid, 'Beta Faculty'::text)
) fixture(user_id, display_name)
where profile_record.user_id = fixture.user_id;

insert into public.institutions (id, slug, name, is_active, time_zone) values
  (
    '92000000-0000-4000-8000-000000000001',
    'academic-alpha',
    'Academic Alpha Campus',
    true,
    'Asia/Kolkata'
  ),
  (
    '92000000-0000-4000-8000-000000000002',
    'academic-beta',
    'Academic Beta Campus',
    true,
    'UTC'
  );

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status,
  accepted_at
) values
  (
    '93000000-0000-4000-8000-000000000001',
    '92000000-0000-4000-8000-000000000001',
    '91000000-0000-4000-8000-000000000001',
    'active',
    now()
  ),
  (
    '93000000-0000-4000-8000-000000000002',
    '92000000-0000-4000-8000-000000000001',
    '91000000-0000-4000-8000-000000000002',
    'active',
    now()
  ),
  (
    '93000000-0000-4000-8000-000000000003',
    '92000000-0000-4000-8000-000000000001',
    '91000000-0000-4000-8000-000000000003',
    'active',
    now()
  ),
  (
    '93000000-0000-4000-8000-000000000004',
    '92000000-0000-4000-8000-000000000001',
    '91000000-0000-4000-8000-000000000004',
    'suspended',
    null
  ),
  (
    '93000000-0000-4000-8000-000000000005',
    '92000000-0000-4000-8000-000000000002',
    '91000000-0000-4000-8000-000000000005',
    'active',
    now()
  );

insert into public.membership_roles (membership_id, role_id)
select fixture.membership_id, role_record.id
from (
  values
    ('93000000-0000-4000-8000-000000000001'::uuid, 'student'::text),
    ('93000000-0000-4000-8000-000000000002'::uuid, 'faculty'::text),
    ('93000000-0000-4000-8000-000000000003'::uuid, 'faculty'::text),
    ('93000000-0000-4000-8000-000000000004'::uuid, 'student'::text),
    ('93000000-0000-4000-8000-000000000005'::uuid, 'faculty'::text)
) fixture(membership_id, role_key)
join public.roles role_record on role_record.key = fixture.role_key;

insert into public.departments (id, institution_id, code, name) values
  (
    '94000000-0000-4000-8000-000000000001',
    '92000000-0000-4000-8000-000000000001',
    'ALPHA',
    'Alpha Computing'
  ),
  (
    '94000000-0000-4000-8000-000000000002',
    '92000000-0000-4000-8000-000000000002',
    'BETA',
    'Beta Computing'
  );

insert into public.programmes (
  id,
  institution_id,
  department_id,
  code,
  name,
  duration_semesters
) values (
  '95000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '94000000-0000-4000-8000-000000000001',
  'BTECH',
  'Bachelor of Technology',
  8
);

insert into public.academic_periods (
  id,
  institution_id,
  code,
  name,
  starts_on,
  ends_on,
  is_current
) values (
  '96000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  'AY2026',
  'Academic Year 2026',
  '2026-01-01',
  '2026-12-31',
  true
);

insert into public.sections (
  id,
  institution_id,
  programme_id,
  academic_period_id,
  code,
  name,
  semester_number
) values (
  '97000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '95000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  'A',
  'Computer Science A',
  7
);

insert into public.subjects (
  id,
  institution_id,
  department_id,
  code,
  name,
  credit_hours
) values (
  '98000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '94000000-0000-4000-8000-000000000001',
  'CS101',
  'Academic Systems',
  4
);

insert into public.course_offerings (
  id,
  institution_id,
  academic_period_id,
  subject_id,
  section_id
) values (
  '99000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  '98000000-0000-4000-8000-000000000001',
  '97000000-0000-4000-8000-000000000001'
);

insert into public.faculty_assignments (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  faculty_user_id
) values (
  '9a000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  '99000000-0000-4000-8000-000000000001',
  '91000000-0000-4000-8000-000000000002'
);

insert into public.student_enrolments (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  student_user_id,
  status
) values (
  '9b000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  '99000000-0000-4000-8000-000000000001',
  '91000000-0000-4000-8000-000000000001',
  'active'
);

insert into public.timetable_entries (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  weekday,
  starts_at,
  ends_at,
  room
) values (
  '9c000000-0000-4000-8000-000000000001',
  '92000000-0000-4000-8000-000000000001',
  '96000000-0000-4000-8000-000000000001',
  '99000000-0000-4000-8000-000000000001',
  1,
  '09:00',
  '10:00',
  'A-101'
);

set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000001';
set local role authenticated;

select ok(
  private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'student'
  ),
  'an active student resolves their institution role'
);
select ok(
  not private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'faculty'
  ),
  'a student does not resolve the faculty role'
);
select ok(
  private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'an active enrolment grants offering access'
);
select ok(
  not private.can_read_course_roster(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'a student cannot read the course roster'
);
select ok(
  not private.can_record_course_attendance(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'a student cannot record course attendance'
);
select results_eq(
  $$select code from public.departments order by code$$,
  array['ALPHA'::text],
  'an active student sees only reference data in their tenant'
);
select results_eq(
  $$select id from public.course_offerings order by id$$,
  array['99000000-0000-4000-8000-000000000001'::uuid],
  'an active student sees their enrolled offering'
);
select results_eq(
  $$select student_user_id from public.student_enrolments order by id$$,
  array['91000000-0000-4000-8000-000000000001'::uuid],
  'an active student sees only their own enrolment'
);
select is_empty(
  $$select faculty_user_id from public.faculty_assignments$$,
  'a student cannot read faculty assignment rows'
);
select throws_ok(
  $$insert into public.departments (institution_id, code, name)
    values (
      '92000000-0000-4000-8000-000000000001'::uuid,
      'WRITE',
      'Unauthorized write'
    )$$,
  '42501',
  'permission denied for table departments',
  'authenticated clients cannot write academic tables directly'
);

reset role;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000002';
set local role authenticated;

select ok(
  private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'faculty'
  ),
  'an active faculty member resolves their institution role'
);
select ok(
  private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'an assigned faculty member can access their offering'
);
select ok(
  private.can_read_course_roster(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'an assigned faculty member can read their roster'
);
select ok(
  private.can_record_course_attendance(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'an assigned faculty member can record attendance'
);
select results_eq(
  $$select faculty_user_id from public.faculty_assignments order by id$$,
  array['91000000-0000-4000-8000-000000000002'::uuid],
  'assigned faculty can read their own assignment'
);
select results_eq(
  $$select student_user_id from public.student_enrolments order by id$$,
  array['91000000-0000-4000-8000-000000000001'::uuid],
  'assigned faculty with roster permission can read active enrolments'
);

reset role;
update public.faculty_assignments
set
  is_active = false,
  ended_at = now()
where id = '9a000000-0000-4000-8000-000000000001'::uuid;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000002';
set local role authenticated;

select ok(
  not private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'revoking a faculty assignment removes offering access immediately'
);
select ok(
  not private.can_read_course_roster(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'revoking a faculty assignment removes roster access immediately'
);
select ok(
  not private.can_record_course_attendance(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'revoking a faculty assignment removes attendance recording immediately'
);
select is_empty(
  $$select id from public.course_offerings$$,
  'revoked faculty can no longer read the former offering'
);
select is_empty(
  $$select id from public.faculty_assignments$$,
  'revoked faculty assignment rows are not exposed through RLS'
);

reset role;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000003';
set local role authenticated;

select ok(
  private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'faculty'
  ),
  'an unassigned faculty member still resolves their institution role'
);
select ok(
  not private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'faculty role alone does not grant offering access'
);
select ok(
  not private.can_read_course_roster(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'unassigned faculty cannot read a roster'
);
select ok(
  not private.can_record_course_attendance(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'unassigned faculty cannot record attendance'
);
select is_empty(
  $$select id from public.course_offerings$$,
  'unassigned faculty cannot read the offering'
);
select is_empty(
  $$select student_user_id from public.student_enrolments$$,
  'unassigned faculty cannot read the roster directly'
);

reset role;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000004';
set local role authenticated;

select ok(
  not private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'student'
  ),
  'a suspended member has no active student role'
);
select ok(
  not private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'a suspended member cannot access an offering'
);
select is_empty(
  $$select id from public.departments$$,
  'a suspended member cannot read tenant academic reference data'
);

reset role;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000005';
set local role authenticated;

select ok(
  not private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'a faculty member in another tenant cannot access the offering'
);
select results_eq(
  $$select code from public.departments order by code$$,
  array['BETA'::text],
  'cross-tenant reference data remains isolated'
);

reset role;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000002';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;

select ok(
  not private.has_role(
    '92000000-0000-4000-8000-000000000001'::uuid,
    'faculty'
  ),
  'an OTP recovery token does not resolve an academic role'
);
select ok(
  not private.can_access_course_offering(
    '92000000-0000-4000-8000-000000000001'::uuid,
    '99000000-0000-4000-8000-000000000001'::uuid
  ),
  'an OTP recovery token cannot resolve offering access'
);
select is_empty(
  $$
    select id from public.departments
    union all
    select id from public.course_offerings
    union all
    select id from public.faculty_assignments
    union all
    select id from public.student_enrolments
    union all
    select id from public.timetable_entries
  $$,
  'an OTP recovery token cannot directly read academic data'
);

reset role;
select * from finish();
rollback;
