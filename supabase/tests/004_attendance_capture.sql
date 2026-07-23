begin;

create extension if not exists pgtap with schema extensions;

select plan(56);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

insert into auth.users (id, email) values
  ('71000000-0000-4000-8000-000000000001', 'attendance-student-a@example.invalid'),
  ('71000000-0000-4000-8000-000000000002', 'attendance-student-b@example.invalid'),
  ('71000000-0000-4000-8000-000000000003', 'attendance-faculty@example.invalid'),
  ('71000000-0000-4000-8000-000000000004', 'attendance-unassigned@example.invalid'),
  ('71000000-0000-4000-8000-000000000005', 'attendance-beta-faculty@example.invalid'),
  ('71000000-0000-4000-8000-000000000006', 'attendance-suspended@example.invalid'),
  ('71000000-0000-4000-8000-000000000007', 'attendance-outsider@example.invalid'),
  ('71000000-0000-4000-8000-000000000008', 'attendance-beta-student@example.invalid');

update public.profiles profile_record
set
  display_name = fixture.display_name,
  profile_completed_at = now()
from (
  values
    ('71000000-0000-4000-8000-000000000001'::uuid, 'Attendance Student A'::text),
    ('71000000-0000-4000-8000-000000000002'::uuid, 'Attendance Student B'::text),
    ('71000000-0000-4000-8000-000000000003'::uuid, 'Attendance Faculty'::text),
    ('71000000-0000-4000-8000-000000000004'::uuid, 'Unassigned Faculty'::text),
    ('71000000-0000-4000-8000-000000000005'::uuid, 'Beta Faculty'::text),
    ('71000000-0000-4000-8000-000000000006'::uuid, 'Suspended Faculty'::text),
    ('71000000-0000-4000-8000-000000000007'::uuid, 'Roster Outsider'::text),
    ('71000000-0000-4000-8000-000000000008'::uuid, 'Beta Student'::text)
) fixture(user_id, display_name)
where profile_record.user_id = fixture.user_id;

insert into public.institutions (id, slug, name, is_active, time_zone) values
  (
    '72000000-0000-4000-8000-000000000001',
    'attendance-alpha',
    'Attendance Alpha Campus',
    true,
    'Asia/Kolkata'
  ),
  (
    '72000000-0000-4000-8000-000000000002',
    'attendance-beta',
    'Attendance Beta Campus',
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
    '73000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000001',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000002',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000003',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000003',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000004',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000004',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000005',
    '72000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000005',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000006',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000006',
    'suspended',
    null
  ),
  (
    '73000000-0000-4000-8000-000000000007',
    '72000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000007',
    'active',
    now()
  ),
  (
    '73000000-0000-4000-8000-000000000008',
    '72000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000008',
    'active',
    now()
  );

insert into public.membership_roles (membership_id, role_id)
select fixture.membership_id, role_record.id
from (
  values
    ('73000000-0000-4000-8000-000000000001'::uuid, 'student'::text),
    ('73000000-0000-4000-8000-000000000002'::uuid, 'student'::text),
    ('73000000-0000-4000-8000-000000000003'::uuid, 'faculty'::text),
    ('73000000-0000-4000-8000-000000000004'::uuid, 'faculty'::text),
    ('73000000-0000-4000-8000-000000000005'::uuid, 'faculty'::text),
    ('73000000-0000-4000-8000-000000000006'::uuid, 'faculty'::text),
    ('73000000-0000-4000-8000-000000000007'::uuid, 'student'::text),
    ('73000000-0000-4000-8000-000000000008'::uuid, 'student'::text)
) fixture(membership_id, role_key)
join public.roles role_record on role_record.key = fixture.role_key;

insert into public.departments (id, institution_id, code, name) values
  (
    '74000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    'CSA',
    'Alpha Computer Science'
  ),
  (
    '74000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    'CSB',
    'Beta Computer Science'
  );

insert into public.programmes (
  id,
  institution_id,
  department_id,
  code,
  name,
  duration_semesters
) values
  (
    '75000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '74000000-0000-4000-8000-000000000001',
    'BTECHA',
    'Alpha Technology',
    8
  ),
  (
    '75000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '74000000-0000-4000-8000-000000000002',
    'BTECHB',
    'Beta Technology',
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
) values
  (
    '76000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    'AY2026A',
    'Alpha Academic Year 2026',
    (now() at time zone 'Asia/Kolkata')::date - 30,
    (now() at time zone 'Asia/Kolkata')::date + 30,
    true
  ),
  (
    '76000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    'AY2026B',
    'Beta Academic Year 2026',
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
) values
  (
    '77000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '75000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    'A',
    'Alpha Section A',
    7
  ),
  (
    '77000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '75000000-0000-4000-8000-000000000002',
    '76000000-0000-4000-8000-000000000002',
    'B',
    'Beta Section B',
    7
  );

insert into public.subjects (
  id,
  institution_id,
  department_id,
  code,
  name,
  credit_hours
) values
  (
    '78000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '74000000-0000-4000-8000-000000000001',
    'CS701',
    'Distributed Systems',
    4
  ),
  (
    '78000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '74000000-0000-4000-8000-000000000002',
    'CS702',
    'Mobile Systems',
    4
  );

insert into public.course_offerings (
  id,
  institution_id,
  academic_period_id,
  subject_id,
  section_id
) values
  (
    '79000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '78000000-0000-4000-8000-000000000001',
    '77000000-0000-4000-8000-000000000001'
  ),
  (
    '79000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '76000000-0000-4000-8000-000000000002',
    '78000000-0000-4000-8000-000000000002',
    '77000000-0000-4000-8000-000000000002'
  );

insert into public.faculty_assignments (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  faculty_user_id
) values
  (
    '7a000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000003'
  ),
  (
    '7a000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '76000000-0000-4000-8000-000000000002',
    '79000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000005'
  );

insert into public.student_enrolments (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  student_user_id,
  status
) values
  (
    '7b000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000001',
    'active'
  ),
  (
    '7b000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000002',
    'active'
  ),
  (
    '7b000000-0000-4000-8000-000000000003',
    '72000000-0000-4000-8000-000000000002',
    '76000000-0000-4000-8000-000000000002',
    '79000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000008',
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
) values
  (
    '7c000000-0000-4000-8000-000000000001',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    1,
    '09:00',
    '10:00',
    'A-201'
  ),
  (
    '7c000000-0000-4000-8000-000000000002',
    '72000000-0000-4000-8000-000000000002',
    '76000000-0000-4000-8000-000000000002',
    '79000000-0000-4000-8000-000000000002',
    1,
    '11:00',
    '12:00',
    'B-301'
  ),
  (
    '7c000000-0000-4000-8000-000000000003',
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    extract(isodow from now() at time zone 'Asia/Kolkata')::smallint,
    '00:00',
    '00:01',
    'Attendance Capture'
  );

insert into public.attendance_sessions (
  id,
  institution_id,
  academic_period_id,
  course_offering_id,
  timetable_entry_id,
  session_date,
  scheduled_starts_at,
  submitted_by,
  request_id,
  request_hash,
  submitted_at
) values (
  '7d000000-0000-4000-8000-000000000001',
  '72000000-0000-4000-8000-000000000001',
  '76000000-0000-4000-8000-000000000001',
  '79000000-0000-4000-8000-000000000001',
  '7c000000-0000-4000-8000-000000000001',
  '2026-07-13',
  '2026-07-13 03:30:00+00',
  '71000000-0000-4000-8000-000000000003',
  '7e000000-0000-4000-8000-000000000001',
  repeat('a', 64),
  '2026-07-13 04:30:00+00'
);

insert into public.attendance_records (
  institution_id,
  academic_period_id,
  course_offering_id,
  session_id,
  student_enrolment_id,
  student_user_id,
  status,
  marked_by,
  marked_at
) values
  (
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '7d000000-0000-4000-8000-000000000001',
    '7b000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000001',
    'present',
    '71000000-0000-4000-8000-000000000003',
    '2026-07-13 04:30:00+00'
  ),
  (
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '7d000000-0000-4000-8000-000000000001',
    '7b000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000002',
    'absent',
    '71000000-0000-4000-8000-000000000003',
    '2026-07-13 04:30:00+00'
  );

-- This privileged fixture deliberately represents a confirmed future class.
-- Dashboards may display its session state, but it must not count toward a
-- student's attendance summary before its scheduled start.
insert into public.attendance_sessions (
  id,
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
  '7d000000-0000-4000-8000-000000000002',
  '72000000-0000-4000-8000-000000000001',
  '76000000-0000-4000-8000-000000000001',
  '79000000-0000-4000-8000-000000000001',
  '7c000000-0000-4000-8000-000000000001',
  (now() at time zone 'Asia/Kolkata')::date
    + (
      8 - extract(
        isodow from now() at time zone 'Asia/Kolkata'
      )::integer
    ),
  (
    (now() at time zone 'Asia/Kolkata')::date
      + (
        8 - extract(
          isodow from now() at time zone 'Asia/Kolkata'
        )::integer
      )
      + time '09:00'
  ) at time zone 'Asia/Kolkata',
  '71000000-0000-4000-8000-000000000003',
  '7e000000-0000-4000-8000-000000000010',
  repeat('b', 64)
);

insert into public.attendance_records (
  institution_id,
  academic_period_id,
  course_offering_id,
  session_id,
  student_enrolment_id,
  student_user_id,
  status,
  marked_by
) values
  (
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '7d000000-0000-4000-8000-000000000002',
    '7b000000-0000-4000-8000-000000000001',
    '71000000-0000-4000-8000-000000000001',
    'absent',
    '71000000-0000-4000-8000-000000000003'
  ),
  (
    '72000000-0000-4000-8000-000000000001',
    '76000000-0000-4000-8000-000000000001',
    '79000000-0000-4000-8000-000000000001',
    '7d000000-0000-4000-8000-000000000002',
    '7b000000-0000-4000-8000-000000000002',
    '71000000-0000-4000-8000-000000000002',
    'present',
    '71000000-0000-4000-8000-000000000003'
  );

set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local role authenticated;

select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select array(
      select dashboard_key
      from jsonb_object_keys(dashboard.value) dashboard_key
      order by dashboard_key
    ) = array[
      'attendance_summary',
      'date',
      'institution_id',
      'role',
      'schedule',
      'time_zone'
    ]
    from dashboard
  ),
  'student dashboard uses the exact top-level JSON contract'
);
select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select value ->> 'institution_id' =
        '72000000-0000-4000-8000-000000000001'
      and value ->> 'role' = 'student'
      and value ->> 'date' =
        ((now() at time zone 'Asia/Kolkata')::date)::text
      and value ->> 'time_zone' = 'Asia/Kolkata'
    from dashboard
  ),
  'student dashboard returns the requested authorized context'
);
select results_eq(
  $$
    select (
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        null
      ) ->> 'date'
    )::date
  $$,
  array[(now() at time zone 'Asia/Kolkata')::date],
  'a null dashboard date derives institution-local today'
);
select results_eq(
  $$
    select count(*)::int
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array[1],
  'student dashboard includes the dedicated institution-local-today class'
);
select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select schedule_item ->> 'subject_code' = 'CS701'
      and schedule_item ->> 'starts_at' = '00:00'
      and schedule_item ->> 'ends_at' = '00:01'
      and schedule_item ->> 'room' = 'Attendance Capture'
    from dashboard
    cross join lateral jsonb_array_elements(
      dashboard.value -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  ),
  'student schedule returns the expected subject, time, and room'
);
select results_eq(
  $$
    select jsonb_array_length(schedule_item -> 'roster')
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array[0],
  'student dashboard never exposes the course roster'
);
select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select schedule_item ->> 'attendance_submitted' = 'false'
      and schedule_item -> 'attendance_session_id' = 'null'::jsonb
    from dashboard
    cross join lateral jsonb_array_elements(
      dashboard.value -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  ),
  'student schedule shows that target-date attendance is not submitted yet'
);
select results_eq(
  $$
    select jsonb_array_length(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'attendance_summary'
    )
  $$,
  array[1],
  'student dashboard includes one own attendance summary'
);
select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select (value #>> '{attendance_summary,0,total_sessions}')::int = 1
      and (value #>> '{attendance_summary,0,attended_sessions}')::int = 1
      and (value #>> '{attendance_summary,0,excused_sessions}')::int = 0
      and (value #>> '{attendance_summary,0,percentage}')::numeric = 100
    from dashboard
  ),
  'student attendance summary derives totals only from their own records'
);
select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        '2026-07-06'::date
      ) as value
    )
    select (value #>> '{attendance_summary,0,total_sessions}')::int = 0
      and value #> '{attendance_summary,0,percentage}' = 'null'::jsonb
    from dashboard
  ),
  'zero-session summaries exclude later sessions and return a null percentage'
);
select results_eq(
  $$
    select (
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
          + (
            8 - extract(
              isodow from now() at time zone 'Asia/Kolkata'
            )::integer
          )
      ) #>> '{attendance_summary,0,total_sessions}'
    )::int
  $$,
  array[1],
  'student summary excludes a privileged future session before it starts'
);
select results_eq(
  $$select count(session_date)::bigint from public.attendance_sessions$$,
  array[2::bigint],
  'student can read sessions only for their enrolled offering'
);
select results_eq(
  $$select status::text from public.attendance_records order by session_id$$,
  array['present'::text, 'absent'::text],
  'student direct record access is restricted to their own attendance'
);
select throws_ok(
  $$select public.get_my_academic_dashboard(
      '72000000-0000-4000-8000-000000000001'::uuid,
      'faculty',
      (now() at time zone 'Asia/Kolkata')::date
    )$$,
  '42501',
  'Faculty academic access is required.',
  'a student cannot request the faculty dashboard branch'
);
select throws_ok(
  $$select public.get_my_academic_dashboard(
      '72000000-0000-4000-8000-000000000002'::uuid,
      'student',
      (now() at time zone 'Asia/Kolkata')::date
    )$$,
  '42501',
  'Active institution access is required.',
  'student dashboard access cannot cross tenant boundaries'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "absent"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000009'::uuid
    )$$,
  '42501',
  'Attendance can only be recorded for an assigned class.',
  'a student cannot submit attendance'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000002';
set local role authenticated;

select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select (value #>> '{attendance_summary,0,total_sessions}')::int = 1
      and (value #>> '{attendance_summary,0,attended_sessions}')::int = 0
      and (value #>> '{attendance_summary,0,percentage}')::numeric = 0
    from dashboard
  ),
  'another student receives only their own absent history'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000003';
set local role authenticated;

select results_eq(
  $$
    select count(*)::int
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array[1],
  'assigned faculty dashboard includes the dedicated class for campus today'
);
select results_eq(
  $$
    select jsonb_array_length(schedule_item -> 'roster')
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array[2],
  'assigned faculty dashboard includes the complete active roster'
);
select results_eq(
  $$
    select (roster_item ->> 'student_user_id')::uuid
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    cross join lateral jsonb_array_elements(schedule_item -> 'roster') roster_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
    order by (roster_item ->> 'student_user_id')::uuid
  $$,
  array[
    '71000000-0000-4000-8000-000000000001'::uuid,
    '71000000-0000-4000-8000-000000000002'::uuid
  ],
  'faculty roster contains only students enrolled in the assigned offering'
);
select results_eq(
  $$
    select roster_item ->> 'display_name'
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    cross join lateral jsonb_array_elements(schedule_item -> 'roster') roster_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
    order by roster_item ->> 'display_name'
  $$,
  array['Attendance Student A'::text, 'Attendance Student B'::text],
  'faculty roster safely resolves student display names through the RPC'
);
select results_eq(
  $$
    select jsonb_array_length(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'attendance_summary'
    )
  $$,
  array[0],
  'faculty dashboard does not expose a personal student summary'
);
select results_eq(
  $$select count(*)::bigint from public.attendance_records$$,
  array[4::bigint],
  'assigned faculty can directly read records for their roster'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000004';
set local role authenticated;

select results_eq(
  $$
    select jsonb_array_length(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    )
  $$,
  array[0],
  'unassigned faculty receive an empty faculty schedule'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "absent"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000008'::uuid
    )$$,
  '42501',
  'Attendance can only be recorded for an assigned class.',
  'unassigned faculty cannot submit attendance'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000005';
set local role authenticated;

select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "absent"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000007'::uuid
    )$$,
  '42501',
  'Attendance can only be recorded for an assigned class.',
  'a faculty assignment in another tenant grants no submission access'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000006';
set local role authenticated;

select throws_ok(
  $$select public.get_my_academic_dashboard(
      '72000000-0000-4000-8000-000000000001'::uuid,
      'faculty',
      (now() at time zone 'Asia/Kolkata')::date
    )$$,
  '42501',
  'Active institution access is required.',
  'a suspended faculty member cannot load an academic dashboard'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000003';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;

select throws_ok(
  $$select public.get_my_academic_dashboard(
      '72000000-0000-4000-8000-000000000001'::uuid,
      'faculty',
      (now() at time zone 'Asia/Kolkata')::date
    )$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot load the faculty dashboard'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "late"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000002'::uuid
    )$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot submit attendance'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000003';
set local request.jwt.claim = '{"amr":[{"method":"password"}]}';
set local role authenticated;

select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date - 7,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "late"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000012'::uuid
    )$$,
  '22023',
  'Attendance can only be confirmed for today.''s class.',
  'faculty cannot confirm attendance for a past class date'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date + 7,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "late"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000013'::uuid
    )$$,
  '22023',
  'Attendance can only be confirmed for today.''s class.',
  'faculty cannot confirm attendance for a future class date'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000003'::uuid
    )$$,
  '22023',
  'Attendance must contain the complete active roster.',
  'attendance submission rejects an incomplete active roster'
);
select results_eq(
  $$
    select count(*)::bigint
    from public.attendance_sessions
    where session_date = (now() at time zone 'Asia/Kolkata')::date
  $$,
  array[0::bigint],
  'an incomplete roster creates no attendance session'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "absent"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000004'::uuid
    )$$,
  '22023',
  'Attendance contains a duplicate student.',
  'attendance submission rejects duplicate students'
);
select results_eq(
  $$
    select count(*)::bigint
    from public.attendance_sessions
    where session_date = (now() at time zone 'Asia/Kolkata')::date
  $$,
  array[0::bigint],
  'duplicate-student rejection remains atomic'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000007",
          "status": "absent"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000005'::uuid
    )$$,
  '22023',
  'Attendance contains a student outside the active roster.',
  'attendance submission rejects a student outside the assigned roster'
);
select results_eq(
  $$
    select count(*)::bigint
    from public.attendance_sessions
    where session_date = (now() at time zone 'Asia/Kolkata')::date
  $$,
  array[0::bigint],
  'outside-roster rejection creates no partial session'
);
select results_eq(
  $$
    select schedule_item ->> 'attendance_submitted'
    from jsonb_array_elements(
      public.submit_attendance(
        '72000000-0000-4000-8000-000000000001'::uuid,
        '79000000-0000-4000-8000-000000000001'::uuid,
        '7c000000-0000-4000-8000-000000000003'::uuid,
        (now() at time zone 'Asia/Kolkata')::date,
        '[
          {
            "student_user_id": "71000000-0000-4000-8000-000000000001",
            "status": "present"
          },
          {
            "student_user_id": "71000000-0000-4000-8000-000000000002",
            "status": "late"
          }
        ]'::jsonb,
        '7e000000-0000-4000-8000-000000000002'::uuid
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array['true'::text],
  'assigned faculty can atomically submit the exact active roster'
);
select results_eq(
  $$
    select count(*)::bigint
    from public.attendance_sessions
    where session_date = (now() at time zone 'Asia/Kolkata')::date
  $$,
  array[1::bigint],
  'successful submission creates exactly one target-date session'
);
select results_eq(
  $$
    select count(*)::bigint
    from public.attendance_records attendance_record
    join public.attendance_sessions attendance_session
      on attendance_session.id = attendance_record.session_id
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  $$,
  array[2::bigint],
  'successful submission atomically creates the complete record set'
);
select results_eq(
  $$
    select attendance_record.status::text
    from public.attendance_records attendance_record
    join public.attendance_sessions attendance_session
      on attendance_session.id = attendance_record.session_id
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
    order by attendance_record.student_user_id
  $$,
  array['present'::text, 'late'::text],
  'submitted attendance preserves each normalized student status'
);
select results_eq(
  $$
    select roster_item ->> 'status'
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    cross join lateral jsonb_array_elements(schedule_item -> 'roster') roster_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
    order by (roster_item ->> 'student_user_id')::uuid
  $$,
  array['present'::text, 'late'::text],
  'faculty dashboard immediately returns server-confirmed roster statuses'
);
select ok(
  (
    select (schedule_item ->> 'attendance_session_id')::uuid
    from jsonb_array_elements(
      public.submit_attendance(
        '72000000-0000-4000-8000-000000000001'::uuid,
        '79000000-0000-4000-8000-000000000001'::uuid,
        '7c000000-0000-4000-8000-000000000003'::uuid,
        (now() at time zone 'Asia/Kolkata')::date,
        '[
          {
            "student_user_id": "71000000-0000-4000-8000-000000000002",
            "status": "late"
          },
          {
            "student_user_id": "71000000-0000-4000-8000-000000000001",
            "status": "present"
          }
        ]'::jsonb,
        '7e000000-0000-4000-8000-000000000002'::uuid
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  )::uuid = (
    select attendance_session.id
    from public.attendance_sessions attendance_session
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  ),
  'same-key replay with equivalent normalized payload returns the original session'
);
select ok(
  (
    select count(*) = 1
    from public.attendance_sessions attendance_session
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  ) and (
    select count(*) = 2
    from public.attendance_records attendance_record
    join public.attendance_sessions attendance_session
      on attendance_session.id = attendance_record.session_id
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  ),
  'idempotent replay does not duplicate a session or records'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "absent"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "late"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000002'::uuid
    )$$,
  '22023',
  'This attendance request identifier was already used.',
  'same request key cannot be reused with a mismatched payload'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        },
        {
          "student_user_id": "71000000-0000-4000-8000-000000000002",
          "status": "late"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000006'::uuid
    )$$,
  '23505',
  'Attendance is already confirmed for this class.',
  'a different request key cannot create a duplicate class session'
);
select ok(
  (
    select count(*) = 1
    from public.attendance_sessions attendance_session
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  ) and (
    select count(*) = 2
    from public.attendance_records attendance_record
    join public.attendance_sessions attendance_session
      on attendance_session.id = attendance_record.session_id
    where attendance_session.session_date =
      (now() at time zone 'Asia/Kolkata')::date
  ),
  'rejected request reuse and duplicate session leave confirmed data unchanged'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local role authenticated;

select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select (dashboard.value #>> '{attendance_summary,0,total_sessions}')::int = 2
      and (
        dashboard.value #>> '{attendance_summary,0,attended_sessions}'
      )::int = 2
      and (
        dashboard.value #>> '{attendance_summary,0,percentage}'
      )::numeric = 100
      and schedule_item ->> 'attendance_submitted' = 'true'
    from dashboard
    cross join lateral jsonb_array_elements(
      dashboard.value -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  ),
  'student A immediately receives the confirmed two-session attendance summary'
);
select results_eq(
  $$select count(*)::bigint from public.attendance_records$$,
  array[3::bigint],
  'student A still sees only their own attendance records'
);

reset role;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000002';
set local role authenticated;

select ok(
  (
    with dashboard as (
      select public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'student',
        (now() at time zone 'Asia/Kolkata')::date
      ) as value
    )
    select (value #>> '{attendance_summary,0,total_sessions}')::int = 2
      and (value #>> '{attendance_summary,0,attended_sessions}')::int = 1
      and (value #>> '{attendance_summary,0,percentage}')::numeric = 50
    from dashboard
  ),
  'student B summary independently reflects one absence and one late mark'
);
select results_eq(
  $$select count(*)::bigint from public.attendance_records$$,
  array[3::bigint],
  'student B sees only their own records after submission'
);

reset role;
update public.student_enrolments
set status = 'dropped'
where id = '7b000000-0000-4000-8000-000000000002'::uuid;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000003';
set local request.jwt.claim = '{"amr":[{"method":"password"}]}';
set local role authenticated;

select results_eq(
  $$
    select jsonb_array_length(schedule_item -> 'roster')
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    where schedule_item ->> 'timetable_entry_id' =
      '7c000000-0000-4000-8000-000000000003'
  $$,
  array[2],
  'a confirmed roster remains a two-student snapshot after an enrolment drops'
);
select results_eq(
  $$
    select roster_item ->> 'status'
    from jsonb_array_elements(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    ) schedule_item
    cross join lateral jsonb_array_elements(schedule_item -> 'roster') roster_item
    where roster_item ->> 'student_user_id' =
      '71000000-0000-4000-8000-000000000002'
      and schedule_item ->> 'timetable_entry_id' =
        '7c000000-0000-4000-8000-000000000003'
  $$,
  array['late'::text],
  'the confirmed snapshot preserves the dropped student server-confirmed mark'
);

reset role;
update public.faculty_assignments
set
  is_active = false,
  ended_at = now()
where id = '7a000000-0000-4000-8000-000000000001'::uuid;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000003';
set local request.jwt.claim = '{"amr":[{"method":"password"}]}';
set local role authenticated;

select ok(
  not private.can_record_course_attendance(
    '72000000-0000-4000-8000-000000000001'::uuid,
    '79000000-0000-4000-8000-000000000001'::uuid
  ),
  'assignment revocation immediately removes the attendance helper grant'
);
select results_eq(
  $$
    select jsonb_array_length(
      public.get_my_academic_dashboard(
        '72000000-0000-4000-8000-000000000001'::uuid,
        'faculty',
        (now() at time zone 'Asia/Kolkata')::date
      ) -> 'schedule'
    )
  $$,
  array[0],
  'faculty dashboard filters a revoked assignment immediately'
);
select throws_ok(
  $$select public.submit_attendance(
      '72000000-0000-4000-8000-000000000001'::uuid,
      '79000000-0000-4000-8000-000000000001'::uuid,
      '7c000000-0000-4000-8000-000000000003'::uuid,
      (now() at time zone 'Asia/Kolkata')::date,
      '[
        {
          "student_user_id": "71000000-0000-4000-8000-000000000001",
          "status": "present"
        }
      ]'::jsonb,
      '7e000000-0000-4000-8000-000000000014'::uuid
    )$$,
  '42501',
  'Attendance can only be recorded for an assigned class.',
  'revoked faculty cannot replay or create attendance through the RPC'
);

reset role;
select * from finish();
rollback;
