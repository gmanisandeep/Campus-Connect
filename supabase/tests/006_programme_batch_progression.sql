begin;

create extension if not exists pgtap with schema extensions;

select plan(29);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_type(
  'public',
  'student_progression_status',
  'student progression states are explicit'
);
select has_table('public', 'institution_programmes', 'programmes are configured per college');
select has_table('public', 'student_program_enrollments', 'verified enrolments are persisted');
select has_table('public', 'student_progression_events', 'progression history is persisted');
select has_function(
  'public',
  'list_active_programmes',
  array[]::text[],
  'active programme discovery RPC exists'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.submit_student_affiliation_request(uuid, text, text, text, smallint)',
    'execute'
  ),
  'the legacy self-declared study-year submission RPC is disabled'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.review_student_affiliation_request(uuid, boolean, text)',
    'execute'
  ),
  'the legacy approval RPC without a verified year is disabled'
);
select ok(
  not has_function_privilege('anon', 'public.list_active_programmes()', 'execute'),
  'anonymous users cannot discover programmes'
);
select ok(
  not has_table_privilege('authenticated', 'public.institution_programmes', 'insert'),
  'authenticated clients cannot configure programmes directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.student_program_enrollments', 'insert'),
  'authenticated clients cannot create verified enrolments directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.student_progression_events', 'insert'),
  'authenticated clients cannot create progression evidence directly'
);

insert into public.institutions (id, slug, name) values
  (
    '52000000-0000-0000-0000-000000000001',
    'progression-college',
    'Progression College'
  ),
  (
    '52000000-0000-0000-0000-000000000002',
    'other-progression-college',
    'Other Progression College'
  );

insert into public.institution_programmes (
  id,
  institution_id,
  name,
  duration_months
) values
  (
    '62000000-0000-0000-0000-000000000001',
    '52000000-0000-0000-0000-000000000001',
    'B.Sc (MPCs)',
    36
  ),
  (
    '62000000-0000-0000-0000-000000000002',
    '52000000-0000-0000-0000-000000000002',
    'MBBS',
    66
  );

insert into auth.users (id, email) values
  (
    '72000000-0000-0000-0000-000000000001',
    'progression-student@example.invalid'
  ),
  (
    '72000000-0000-0000-0000-000000000002',
    'progression-admin@example.invalid'
  ),
  (
    '72000000-0000-0000-0000-000000000003',
    'progression-outsider@example.invalid'
  );

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status,
  accepted_at
) values (
  '82000000-0000-0000-0000-000000000002',
  '52000000-0000-0000-0000-000000000001',
  '72000000-0000-0000-0000-000000000002',
  'active',
  now()
);

insert into public.membership_roles (membership_id, role_id)
select
  '82000000-0000-0000-0000-000000000002'::uuid,
  role_record.id
from public.roles role_record
where role_record.key = 'institution_administrator';

set local request.jwt.claim.sub = '72000000-0000-0000-0000-000000000001';
set local role authenticated;

select ok(
  public.list_active_programmes() @> jsonb_build_array(
    jsonb_build_object(
      'id', '62000000-0000-0000-0000-000000000001'::uuid,
      'institution_id', '52000000-0000-0000-0000-000000000001'::uuid,
      'name', 'B.Sc (MPCs)',
      'duration_months', 36
    )
  ),
  'a password-authenticated student discovers programme duration'
);
select is(
  (select count(*) from public.institution_programmes),
  0::bigint,
  'programme discovery does not bypass membership-scoped table RLS'
);
select throws_ok(
  $$select public.submit_student_affiliation_request(
      '52000000-0000-0000-0000-000000000001'::uuid,
      '62000000-0000-0000-0000-000000000002'::uuid,
      'Progression Student',
      'PR-001',
      2023::smallint,
      2026::smallint,
      'regular'::public.student_progression_status
    )$$,
  'P0002',
  'Programme is not available for this institution.',
  'a programme from another college cannot be submitted'
);
select throws_ok(
  $$select public.submit_student_affiliation_request(
      '52000000-0000-0000-0000-000000000001'::uuid,
      '62000000-0000-0000-0000-000000000001'::uuid,
      'Progression Student',
      'PR-001',
      2026::smallint,
      2023::smallint,
      'regular'::public.student_progression_status
    )$$,
  '22023',
  'A valid batch and progression status are required.',
  'an invalid batch range is rejected'
);
select results_eq(
  $$select public.submit_student_affiliation_request(
      '52000000-0000-0000-0000-000000000001'::uuid,
      '62000000-0000-0000-0000-000000000001'::uuid,
      'Progression Student',
      'PR-001',
      2023::smallint,
      2026::smallint,
      'on_leave'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a student can submit programme, batch, and gap-aware progression'
);
select ok(
  (
    select public.get_my_student_affiliation_request() @>
      '{"programme":"B.Sc (MPCs)","duration_months":36,"batch_start_year":2023,"expected_completion_year":2026,"progression_status":"on_leave"}'::jsonb
  ),
  'the student status payload returns the programme and batch contract'
);

reset role;
set local request.jwt.claim.sub = '72000000-0000-0000-0000-000000000002';
set local role authenticated;

select ok(
  (
    with queue as (
      select public.list_pending_student_affiliation_requests(
        '52000000-0000-0000-0000-000000000001'::uuid
      ) as value
    )
    select value #>> '{0,duration_months}' = '36'
      and value #>> '{0,batch_start_year}' = '2023'
      and value #>> '{0,progression_status}' = 'on_leave'
    from queue
  ),
  'the college review queue includes duration, batch, and progression'
);
select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '72000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      null::smallint,
      null
    )$$,
  '22023',
  'A valid college-verified current year is required.',
  'approval requires a college-verified academic year'
);
select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '72000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      4::smallint,
      null
    )$$,
  '22023',
  'A valid college-verified current year is required.',
  'verified year cannot exceed programme duration'
);
select lives_ok(
  $$select public.review_student_affiliation_request(
      (
        select id from public.student_affiliation_requests
        where user_id = '72000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      3::smallint,
      'Verified against the academic register.'
    )$$,
  'the college can approve the verified academic year'
);

reset role;

select ok(
  (
    select current_year = 3
      and progression_status = 'on_leave'
      and batch_start_year = 2023
      and expected_completion_year = 2026
    from public.student_program_enrollments
    where user_id = '72000000-0000-0000-0000-000000000001'::uuid
  ),
  'approval persists the verified enrolment state'
);
select ok(
  (
    select current_year = 3
      and progression_status = 'on_leave'
      and recorded_by = '72000000-0000-0000-0000-000000000002'::uuid
    from public.student_progression_events
    where user_id = '72000000-0000-0000-0000-000000000001'::uuid
  ),
  'approval records immutable progression evidence'
);

set local request.jwt.claim.sub = '72000000-0000-0000-0000-000000000001';
set local role authenticated;

select is(
  (select count(*) from public.student_program_enrollments),
  1::bigint,
  'a student can read their own verified enrolment'
);
select is(
  (select count(*) from public.student_progression_events),
  1::bigint,
  'a student can read their own progression history'
);

reset role;
set local request.jwt.claim.sub = '72000000-0000-0000-0000-000000000003';
set local role authenticated;

select is(
  (select count(*) from public.student_program_enrollments),
  0::bigint,
  'another student cannot read the verified enrolment'
);
select is(
  (select count(*) from public.student_progression_events),
  0::bigint,
  'another student cannot read progression history'
);

reset role;
set local request.jwt.claim.sub = '72000000-0000-0000-0000-000000000001';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;

select throws_ok(
  $$select public.list_active_programmes()$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot discover programmes'
);
select is(
  (select count(*) from public.student_program_enrollments),
  0::bigint,
  'an OTP recovery token cannot read verified enrolment data'
);

reset role;
select * from finish();
rollback;
