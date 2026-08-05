begin;

create extension if not exists pgtap with schema extensions;

select plan(41);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_table(
  'public',
  'student_affiliation_requests',
  'student affiliation requests are persisted'
);
select results_eq(
  $$select enumlabel::text collate "C"
    from pg_catalog.pg_enum enum_record
    join pg_catalog.pg_type type_record on type_record.oid = enum_record.enumtypid
    join pg_catalog.pg_namespace namespace on namespace.oid = type_record.typnamespace
    where namespace.nspname = 'public'
      and type_record.typname = 'affiliation_request_status'
    order by enum_record.enumsortorder$$,
  $$values
      ('pending'::text collate "C"),
      ('approved'::text collate "C"),
      ('rejected'::text collate "C"),
      ('cancelled'::text collate "C")$$,
  'affiliation request states are explicit and ordered'
);
select has_function(
  'public',
  'list_active_institutions',
  array[]::text[],
  'active institution discovery RPC exists'
);
select has_function(
  'public',
  'get_my_student_affiliation_request',
  array[]::text[],
  'student request status RPC exists'
);
select has_function(
  'public',
  'submit_student_affiliation_request',
  array['uuid', 'uuid', 'text', 'text', 'smallint', 'smallint', 'student_progression_status'],
  'student submission RPC exists'
);
select has_function(
  'public',
  'cancel_my_student_affiliation_request',
  array['uuid'],
  'student cancellation RPC exists'
);
select has_function(
  'public',
  'list_pending_student_affiliation_requests',
  array['uuid'],
  'institution review queue RPC exists'
);
select has_function(
  'public',
  'review_student_affiliation_request',
  array['uuid', 'boolean', 'smallint', 'text'],
  'institution decision RPC exists'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.list_active_institutions()',
    'execute'
  ),
  'anonymous users cannot discover institutions through the RPC'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.submit_student_affiliation_request(uuid, uuid, text, text, smallint, smallint, student_progression_status)',
    'execute'
  ),
  'authenticated users can submit their own request'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.review_student_affiliation_request(uuid, boolean, smallint, text)',
    'execute'
  ),
  'service role cannot impersonate an institution reviewer through the RPC'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'public.student_affiliation_requests',
    'insert'
  ),
  'authenticated clients cannot insert requests directly'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'public.student_affiliation_requests',
    'update'
  ),
  'authenticated clients cannot update decisions directly'
);

insert into public.institutions (id, slug, name) values
  (
    '22000000-0000-0000-0000-000000000001',
    'affiliation-test-college',
    'Affiliation Test College'
  ),
  (
    '22000000-0000-0000-0000-000000000002',
    'other-affiliation-college',
    'Other Affiliation College'
  );

insert into public.institution_programmes (
  id,
  institution_id,
  name,
  duration_months
) values
  (
    '42000000-0000-0000-0000-000000000001',
    '22000000-0000-0000-0000-000000000001',
    'B.Tech Computer Science',
    48
  ),
  (
    '42000000-0000-0000-0000-000000000002',
    '22000000-0000-0000-0000-000000000002',
    'B.Tech Computer Science',
    48
  );

insert into auth.users (id, email) values
  (
    '12000000-0000-0000-0000-000000000001',
    'affiliation-student@example.invalid'
  ),
  (
    '12000000-0000-0000-0000-000000000002',
    'duplicate-roll@example.invalid'
  ),
  (
    '12000000-0000-0000-0000-000000000003',
    'affiliation-admin@example.invalid'
  ),
  (
    '12000000-0000-0000-0000-000000000004',
    'other-affiliation-admin@example.invalid'
  ),
  (
    '12000000-0000-0000-0000-000000000005',
    'cancel-affiliation@example.invalid'
  );

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status,
  accepted_at
) values
  (
    '32000000-0000-0000-0000-000000000003',
    '22000000-0000-0000-0000-000000000001',
    '12000000-0000-0000-0000-000000000003',
    'active',
    now()
  ),
  (
    '32000000-0000-0000-0000-000000000004',
    '22000000-0000-0000-0000-000000000002',
    '12000000-0000-0000-0000-000000000004',
    'active',
    now()
  );

insert into public.membership_roles (membership_id, role_id)
select fixture.membership_id, role_record.id
from (
  values
    ('32000000-0000-0000-0000-000000000003'::uuid),
    ('32000000-0000-0000-0000-000000000004'::uuid)
) as fixture(membership_id)
join public.roles role_record
  on role_record.key = 'institution_administrator';

set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000001';
set local role authenticated;

select ok(
  public.list_active_institutions() @> jsonb_build_array(
    jsonb_build_object(
      'id', '22000000-0000-0000-0000-000000000001'::uuid,
      'name', 'Affiliation Test College'
    )
  ),
  'a password-authenticated student can discover an active college'
);
select results_eq(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      '  Test Student  ',
      '  CS-001  ',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a student can submit a pending affiliation request'
);
select results_eq(
  $$select official_name || '|' || roll_number || '|' || programme
    from public.student_affiliation_requests
    where user_id = '12000000-0000-0000-0000-000000000001'::uuid$$,
  array['Test Student|CS-001|B.Tech Computer Science'::text],
  'the submission normalizes the student supplied fields'
);
select throws_ok(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000002'::uuid,
      '42000000-0000-0000-0000-000000000002'::uuid,
      'Test Student',
      'OTHER-001',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    )$$,
  '23505',
  'A matching affiliation request is already pending.',
  'a student can have only one pending request'
);
select throws_ok(
  $$insert into public.student_affiliation_requests (
      institution_id,
      user_id,
      official_name,
      roll_number,
      programme,
      study_year
    ) values (
      '22000000-0000-0000-0000-000000000001'::uuid,
      '12000000-0000-0000-0000-000000000001'::uuid,
      'Direct Student',
      'DIRECT-1',
      'Direct Programme',
      1
    )$$,
  '42501',
  'permission denied for table student_affiliation_requests',
  'students cannot bypass the submission RPC'
);
select throws_ok(
  $$select public.list_pending_student_affiliation_requests(
      '22000000-0000-0000-0000-000000000001'::uuid
    )$$,
  '42501',
  'Institution administrator access is required.',
  'students cannot read the institution review queue'
);
select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      2::smallint,
      null
    )$$,
  '42501',
  'Pending request cannot be reviewed.',
  'students cannot approve their own request'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000002';
set local role authenticated;

select throws_ok(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      'Duplicate Student',
      'cs-001',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    )$$,
  '23505',
  'A matching affiliation request is already pending.',
  'a college cannot receive two pending requests for the same roll number'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000003';
set local role authenticated;

select ok(
  (
    with queue as (
      select public.list_pending_student_affiliation_requests(
        '22000000-0000-0000-0000-000000000001'::uuid
      ) as value
    )
    select jsonb_array_length(value) = 1
      and value #>> '{0,email}' = 'affiliation-student@example.invalid'
      and value #>> '{0,roll_number}' = 'CS-001'
    from queue
  ),
  'the institution administrator sees the scoped request and contact details'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000004';
set local role authenticated;

select throws_ok(
  $$select public.list_pending_student_affiliation_requests(
      '22000000-0000-0000-0000-000000000001'::uuid
    )$$,
  '42501',
  'Institution administrator access is required.',
  'an administrator cannot read another institution queue'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000003';
set local role authenticated;

select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      false,
      null::smallint,
      null
    )$$,
  '22023',
  'A rejection reason between 2 and 500 characters is required.',
  'a rejection requires a useful student-facing reason'
);
select lives_ok(
  $$select public.review_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      false,
      null::smallint,
      'Roll number does not match the college record.'
    )$$,
  'the institution administrator can reject a pending request'
);
select ok(
  (
    select status = 'rejected'
      and reviewed_by = '12000000-0000-0000-0000-000000000003'::uuid
      and reviewed_at is not null
    from public.student_affiliation_requests
    where user_id = '12000000-0000-0000-0000-000000000001'::uuid
  ),
  'rejection records the decision and reviewer audit fields'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000001';
set local role authenticated;

select results_eq(
  $$select public.get_my_student_affiliation_request() ->> 'decision_note'$$,
  array['Roll number does not match the college record.'::text],
  'the student receives the college rejection reason'
);
select results_eq(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      'Test Student',
      'CS-002',
      2023::smallint,
      2027::smallint,
      'repeating'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a rejected student can submit corrected details'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000003';
set local role authenticated;

select lives_ok(
  $$select public.review_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000001'::uuid
          and status = 'pending'
      ),
      true,
      2::smallint,
      'Matched against the official student register.'
    )$$,
  'the institution administrator can approve corrected details'
);

reset role;

select ok(
  exists (
    select 1
    from public.institution_memberships membership
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.roles role_record
      on role_record.id = membership_role.role_id
    where membership.institution_id =
        '22000000-0000-0000-0000-000000000001'::uuid
      and membership.user_id =
        '12000000-0000-0000-0000-000000000001'::uuid
      and membership.status = 'active'
      and role_record.key = 'student'
  ),
  'approval atomically creates active Student access'
);
select ok(
  (
    select display_name = 'Test Student'
      and profile_completed_at is not null
    from public.profiles
    where user_id = '12000000-0000-0000-0000-000000000001'::uuid
  ),
  'approval completes the verified student profile'
);
select ok(
  (
    select status = 'approved'
      and reviewed_by = '12000000-0000-0000-0000-000000000003'::uuid
      and reviewed_at is not null
    from public.student_affiliation_requests
    where user_id = '12000000-0000-0000-0000-000000000001'::uuid
      and roll_number = 'CS-002'
  ),
  'approval records the immutable reviewer and timestamp evidence'
);

set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000003';
set local role authenticated;

select throws_ok(
  $$select public.review_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000001'::uuid
          and status = 'approved'
      ),
      true,
      2::smallint,
      null
    )$$,
  '42501',
  'Pending request cannot be reviewed.',
  'an approval decision cannot be replayed'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000002';
set local role authenticated;

select throws_ok(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      'Duplicate Student',
      'cs-002',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    )$$,
  '23505',
  'A matching affiliation request is already pending.',
  'an approved roll number remains reserved to its verified student'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000001';
set local role authenticated;

select throws_ok(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000002'::uuid,
      '42000000-0000-0000-0000-000000000002'::uuid,
      'Test Student',
      'OTHER-002',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    )$$,
  '23505',
  'A matching affiliation request is already pending.',
  'an approved student cannot request another active Student membership'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000005';
set local role authenticated;

select results_eq(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      'Cancel Student',
      'CANCEL-001',
      2023::smallint,
      2027::smallint,
      'on_leave'::public.student_progression_status
    ) ->> 'status'$$,
  array['pending'::text],
  'a separate student can create a cancellable request'
);
select lives_ok(
  $$select public.cancel_my_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000005'::uuid
          and status = 'pending'
      )
    )$$,
  'a student can cancel their own pending request'
);
select is(
  public.get_my_student_affiliation_request(),
  null::jsonb,
  'a cancelled request no longer blocks a new student request'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000002';
set local role authenticated;

select throws_ok(
  $$select public.cancel_my_student_affiliation_request(
      (
        select id
        from public.student_affiliation_requests
        where user_id = '12000000-0000-0000-0000-000000000005'::uuid
      )
    )$$,
  '42501',
  'Pending request cannot be cancelled.',
  'a student cannot cancel another student request'
);

reset role;
set local request.jwt.claim.sub = '12000000-0000-0000-0000-000000000002';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;

select throws_ok(
  $$select public.list_active_institutions()$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot discover colleges'
);
select throws_ok(
  $$select public.submit_student_affiliation_request(
      '22000000-0000-0000-0000-000000000001'::uuid,
      '42000000-0000-0000-0000-000000000001'::uuid,
      'OTP Student',
      'OTP-001',
      2023::smallint,
      2027::smallint,
      'regular'::public.student_progression_status
    )$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot submit an affiliation request'
);

reset role;
select * from finish();
rollback;
