begin;

create extension if not exists pgtap with schema extensions;

select plan(21);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select results_eq(
  $$select enumlabel::text collate "C"
    from pg_catalog.pg_enum enum_record
    join pg_catalog.pg_type type_record
      on type_record.oid = enum_record.enumtypid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = type_record.typnamespace
    where namespace.nspname = 'public'
      and type_record.typname = 'student_progression_status'
    order by enum_record.enumsortorder$$,
  $$values
      ('regular'::text collate "C"),
      ('on_leave'::text collate "C"),
      ('repeating'::text collate "C"),
      ('lateral_entry'::text collate "C"),
      ('graduated'::text collate "C")$$,
  'graduated is an explicit progression state'
);
select results_eq(
  $$select label from public.roles where key = 'alumni'$$,
  array['Alumni'::text],
  'the Alumni access role exists'
);
select is_empty(
  $$select permission_record.key
    from public.role_permissions role_permission
    join public.roles role_record on role_record.id = role_permission.role_id
    join public.permissions permission_record
      on permission_record.id = role_permission.permission_id
    where role_record.key = 'alumni'$$,
  'Alumni access receives no active Student permissions'
);
select results_eq(
  $$select is_nullable::text collate "C"
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'student_program_enrollments'
      and column_name = 'current_year'$$,
  array['YES'::text collate "C"],
  'a graduated enrolment has no current academic year'
);
select results_eq(
  $$select is_nullable::text collate "C"
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'student_progression_events'
      and column_name = 'current_year'$$,
  array['YES'::text collate "C"],
  'graduation history has no current academic year'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'private.review_student_affiliation_request_v1(uuid, boolean, smallint, text)',
    'execute'
  ),
  'clients cannot bypass the graduate-aware approval wrapper'
);

insert into public.institutions (id, slug, name) values (
  '92000000-0000-0000-0000-000000000001',
  'graduate-test-college',
  'Graduate Test College'
);

insert into public.institution_programmes (
  id,
  institution_id,
  name,
  duration_months
) values (
  '93000000-0000-0000-0000-000000000001',
  '92000000-0000-0000-0000-000000000001',
  'B.Sc (MPCs)',
  36
);

insert into auth.users (id, email) values
  (
    '94000000-0000-0000-0000-000000000001',
    'graduate@example.invalid'
  ),
  (
    '94000000-0000-0000-0000-000000000002',
    'graduate-admin@example.invalid'
  ),
  (
    '94000000-0000-0000-0000-000000000003',
    'future-graduate@example.invalid'
  );

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status,
  accepted_at
) values (
  '95000000-0000-0000-0000-000000000002',
  '92000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-000000000002',
  'active',
  now()
);

insert into public.membership_roles (membership_id, role_id)
select
  '95000000-0000-0000-0000-000000000002'::uuid,
  role_record.id
from public.roles role_record
where role_record.key = 'institution_administrator';

set local request.jwt.claim.sub = '94000000-0000-0000-0000-000000000001';
set local role authenticated;

select results_eq(
  $$select public.submit_student_affiliation_request(
      '92000000-0000-0000-0000-000000000001'::uuid,
      '93000000-0000-0000-0000-000000000001'::uuid,
      'Graduate User',
      'GRAD-001',
      2023::smallint,
      2026::smallint,
      'graduated'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a graduate can submit a completed programme batch'
);
select ok(
  public.get_my_student_affiliation_request() @>
    '{"progression_status":"graduated","batch_start_year":2023,"expected_completion_year":2026,"verified_current_year":null}'::jsonb,
  'the graduate sees a pending request without a current year'
);

reset role;
set local request.jwt.claim.sub = '94000000-0000-0000-0000-000000000002';
set local role authenticated;

select results_eq(
  $$select public.list_pending_student_affiliation_requests(
      '92000000-0000-0000-0000-000000000001'::uuid
    ) #>> '{0,progression_status}'$$,
  array['graduated'::text],
  'the college review queue identifies the graduate request'
);
select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '94000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      3::smallint,
      null
    )$$,
  '22023',
  'Graduated access must not include a current academic year.',
  'a college cannot assign a current year to a graduate'
);
select lives_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '94000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      null::smallint,
      'Completion verified against the college register.'
    )$$,
  'the college can approve a completed batch as Alumni'
);

reset role;

select ok(
  (
    select status = 'approved'
      and progression_status = 'graduated'
      and verified_current_year is null
    from public.student_affiliation_requests
    where user_id = '94000000-0000-0000-0000-000000000001'::uuid
  ),
  'the approved request retains graduated status without a year'
);
select ok(
  (
    select progression_status = 'graduated'
      and current_year is null
      and batch_start_year = 2023
      and expected_completion_year = 2026
    from public.student_program_enrollments
    where user_id = '94000000-0000-0000-0000-000000000001'::uuid
  ),
  'the verified enrolment records programme completion'
);
select ok(
  (
    select progression_status = 'graduated'
      and current_year is null
    from public.student_progression_events
    where user_id = '94000000-0000-0000-0000-000000000001'::uuid
  ),
  'the progression audit event records graduation without a current year'
);
select results_eq(
  $$select role_record.key
    from public.institution_memberships membership
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record on role_record.id = membership_role.role_id
    where membership.user_id = '94000000-0000-0000-0000-000000000001'::uuid
    order by role_record.key$$,
  array['alumni'::text],
  'graduation grants Alumni rather than active Student access'
);

set local request.jwt.claim.sub = '94000000-0000-0000-0000-000000000001';
set local role authenticated;

select is(
  (select count(*) from public.student_program_enrollments),
  1::bigint,
  'the graduate can read their own completed enrolment'
);
select throws_ok(
  $$select public.submit_student_affiliation_request(
      '92000000-0000-0000-0000-000000000001'::uuid,
      '93000000-0000-0000-0000-000000000001'::uuid,
      'Graduate User',
      'GRAD-002',
      2023::smallint,
      2026::smallint,
      'graduated'::public.student_progression_status
    )$$,
  '23505',
  'A matching affiliation request is already pending.',
  'an active Alumni member cannot open another learner request'
);

reset role;
set local request.jwt.claim.sub = '94000000-0000-0000-0000-000000000003';
set local role authenticated;

select results_eq(
  $$select public.submit_student_affiliation_request(
      '92000000-0000-0000-0000-000000000001'::uuid,
      '93000000-0000-0000-0000-000000000001'::uuid,
      'Future Graduate',
      'FUTURE-001',
      2024::smallint,
      2027::smallint,
      'graduated'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a claimed future completion remains pending for college review'
);

reset role;
set local request.jwt.claim.sub = '94000000-0000-0000-0000-000000000002';
set local role authenticated;

select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '94000000-0000-0000-0000-000000000003'::uuid
          and status = 'pending'
      ),
      true,
      null::smallint,
      null
    )$$,
  '22023',
  'A completed programme batch is required for Alumni access.',
  'a future completion year cannot be approved as graduated'
);
select lives_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '94000000-0000-0000-0000-000000000003'::uuid
          and status = 'pending'
      ),
      false,
      null::smallint,
      'Graduation is not yet recorded by the college.'
    )$$,
  'a future graduation claim can be rejected with a correction reason'
);
select results_eq(
  $$select status::text from public.student_affiliation_requests
    where user_id = '94000000-0000-0000-0000-000000000003'::uuid$$,
  array['rejected'::text],
  'the future graduation request is rejected without granting access'
);

reset role;
select * from finish();
rollback;
