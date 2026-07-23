begin;

create extension if not exists pgtap with schema extensions;

select plan(46);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_column(
  'public',
  'profiles',
  'profile_completed_at',
  'profiles track explicit completion'
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
      and relation.relname = 'institution_memberships'
      and constraint_record.conname = 'memberships_invitation_expiry_required'
      and constraint_record.contype = 'c'
  ),
  'invited memberships require an expiry constraint'
);
select has_column(
  'public',
  'institution_memberships',
  'invitation_expires_at',
  'memberships track invitation expiry'
);
select has_column(
  'public',
  'institution_memberships',
  'accepted_at',
  'memberships track acceptance time'
);
select has_function(
  'public',
  'get_my_identity_context',
  array[]::text[],
  'identity context RPC exists'
);
select has_function(
  'public',
  'accept_my_invitation',
  array['uuid', 'text'],
  'invitation acceptance RPC exists'
);
select has_function(
  'public',
  'complete_my_profile',
  array['text'],
  'profile completion RPC exists'
);
select results_eq(
  $$
    select function_record.provolatile::text
    from pg_catalog.pg_proc function_record
    join pg_catalog.pg_namespace namespace
      on namespace.oid = function_record.pronamespace
    where namespace.nspname = 'public'
      and function_record.proname = 'get_my_identity_context'
      and function_record.pronargs = 0
  $$,
  array['v'::text],
  'identity context uses a fresh snapshot after mutating RPCs'
);
select results_eq(
  $$
    select count(*) = 3 and bool_and(function_record.prosecdef)
    from pg_catalog.pg_proc function_record
    join pg_catalog.pg_namespace namespace
      on namespace.oid = function_record.pronamespace
    where namespace.nspname = 'public'
      and function_record.proname = any (
        array[
          'get_my_identity_context',
          'accept_my_invitation',
          'complete_my_profile'
        ]
      )
  $$,
  array[true],
  'identity RPCs consistently enforce their checks as security definers'
);
select ok(
  not has_function_privilege('anon', 'public.get_my_identity_context()', 'execute'),
  'anonymous users cannot execute identity context'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_identity_context()',
    'execute'
  ),
  'authenticated users can execute identity context'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.accept_my_invitation(uuid, text)',
    'execute'
  ),
  'anonymous users cannot accept invitations'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.accept_my_invitation(uuid, text)',
    'execute'
  ),
  'service role does not impersonate a user through invitation acceptance'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.accept_my_invitation(uuid, text)',
    'execute'
  ),
  'authenticated users can accept their own invitations'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.complete_my_profile(text)',
    'execute'
  ),
  'anonymous users cannot complete profiles'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.complete_my_profile(text)',
    'execute'
  ),
  'authenticated users can complete eligible profiles'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.get_my_identity_context()',
    'execute'
  ),
  'service role does not impersonate a user through identity context'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.complete_my_profile(text)',
    'execute'
  ),
  'service role does not impersonate a user through profile completion'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'public.profiles',
    'profile_completed_at',
    'update'
  ),
  'profile completion timestamps remain RPC-owned'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'public.institution_memberships',
    'accepted_at',
    'update'
  ),
  'membership acceptance timestamps remain RPC-owned'
);

insert into auth.users (id, email) values
  ('11000000-0000-0000-0000-000000000001', 'valid-invite@example.invalid'),
  ('11000000-0000-0000-0000-000000000002', 'expired-invite@example.invalid'),
  ('11000000-0000-0000-0000-000000000003', 'other-user@example.invalid'),
  ('11000000-0000-0000-0000-000000000004', 'suspended@example.invalid'),
  ('11000000-0000-0000-0000-000000000005', 'no-role@example.invalid');

insert into public.institutions (id, slug, name, is_active) values
  ('21000000-0000-0000-0000-000000000001', 'onboarding-campus', 'Onboarding Campus', true),
  ('21000000-0000-0000-0000-000000000002', 'inactive-onboarding-campus', 'Inactive Campus', false);

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status,
  invitation_expires_at
) values
  (
    '31000000-0000-0000-0000-000000000001',
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000001',
    'invited',
    now() + interval '2 days'
  ),
  (
    '31000000-0000-0000-0000-000000000002',
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000002',
    'invited',
    now() - interval '1 minute'
  ),
  (
    '31000000-0000-0000-0000-000000000003',
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000003',
    'active',
    null
  ),
  (
    '31000000-0000-0000-0000-000000000004',
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000004',
    'suspended',
    null
  ),
  (
    '31000000-0000-0000-0000-000000000005',
    '21000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000005',
    'invited',
    now() + interval '2 days'
  ),
  (
    '31000000-0000-0000-0000-000000000006',
    '21000000-0000-0000-0000-000000000002',
    '11000000-0000-0000-0000-000000000005',
    'invited',
    now() + interval '2 days'
  );

insert into public.membership_roles (membership_id, role_id)
select mapping.membership_id::uuid, role_record.id
from (
  values
    ('31000000-0000-0000-0000-000000000001', 'student'),
    ('31000000-0000-0000-0000-000000000002', 'student'),
    ('31000000-0000-0000-0000-000000000003', 'faculty'),
    ('31000000-0000-0000-0000-000000000004', 'student'),
    ('31000000-0000-0000-0000-000000000006', 'student')
) as mapping(membership_id, role_key)
join public.roles role_record on role_record.key = mapping.role_key;

select throws_ok(
  $$insert into public.institution_memberships (
      id,
      institution_id,
      user_id,
      status,
      invitation_expires_at
    ) values (
      '31999999-0000-0000-0000-000000000001'::uuid,
      '21000000-0000-0000-0000-000000000002'::uuid,
      '11000000-0000-0000-0000-000000000003'::uuid,
      'invited',
      null
    )$$,
  '23514',
  'new row for relation "institution_memberships" violates check constraint "memberships_invitation_expiry_required"',
  'an invited membership cannot omit its expiry'
);

select results_eq(
  $$select count(*)::bigint from public.profiles where user_id::text like '11000000-%'$$,
  array[5::bigint],
  'new auth users receive incomplete profiles'
);

set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000001';
set local role authenticated;

select ok(
  (
    with identity_context as (
      select public.get_my_identity_context() as value
    )
    select
      (
        select array_agg(context_key order by context_key)
        from jsonb_object_keys(identity_context.value)
          as context_keys(context_key)
      ) = array['memberships', 'profile', 'user_id']
      and (
        select array_agg(profile_key order by profile_key)
        from jsonb_object_keys(identity_context.value -> 'profile')
          as profile_keys(profile_key)
      ) = array['display_name', 'profile_completed_at']
      and (
        select array_agg(membership_key order by membership_key)
        from jsonb_object_keys(identity_context.value #> '{memberships,0}')
          as membership_keys(membership_key)
      ) = array[
        'id',
        'institution_active',
        'institution_id',
        'institution_name',
        'invitation_expires_at',
        'roles',
        'status'
      ]
      and (
        select array_agg(role_key order by role_key)
        from jsonb_object_keys(identity_context.value #> '{memberships,0,roles,0}')
          as role_keys(role_key)
      ) = array['key', 'label', 'permissions']
    from identity_context
  ),
  'identity context matches the exact app-facing key contract'
);
select ok(
  (
    with identity_context as (
      select public.get_my_identity_context() as value
    )
    select jsonb_typeof(value -> 'user_id') = 'string'
      and jsonb_typeof(value -> 'profile') = 'object'
      and jsonb_typeof(value -> 'memberships') = 'array'
      and jsonb_typeof(value #> '{memberships,0,institution_active}') = 'boolean'
      and jsonb_typeof(value #> '{memberships,0,roles}') = 'array'
      and jsonb_typeof(value #> '{memberships,0,roles,0,permissions}') = 'array'
    from identity_context
  ),
  'identity context returns the expected JSON value types'
);
select results_eq(
  $$select public.get_my_identity_context() ->> 'user_id'$$,
  array['11000000-0000-0000-0000-000000000001'::text],
  'identity context derives the authenticated user'
);
select results_eq(
  $$select jsonb_array_length(public.get_my_identity_context() -> 'memberships')$$,
  array[1],
  'identity context includes only the current user memberships'
);
select results_eq(
  $$select public.get_my_identity_context() #>> '{memberships,0,roles,0,key}'$$,
  array['student'::text],
  'identity context returns assigned roles'
);
select results_eq(
  $$select public.get_my_identity_context() #>> '{memberships,0,roles,0,permissions,0}'$$,
  array['attendance_read_own'::text],
  'identity context returns permissions scoped to the role'
);
select results_eq(
  $$
    select public.accept_my_invitation(
      '31000000-0000-0000-0000-000000000001'::uuid,
      '  Invited Student  '
    ) #>> '{memberships,0,status}'
  $$,
  array['active'::text],
  'acceptance returns a freshly activated identity context'
);
select results_eq(
  $$select status::text from public.institution_memberships
    where id = '31000000-0000-0000-0000-000000000001'::uuid$$,
  array['active'::text],
  'acceptance activates the membership'
);
select results_eq(
  $$select display_name from public.profiles
    where user_id = '11000000-0000-0000-0000-000000000001'::uuid$$,
  array['Invited Student'::text],
  'acceptance normalizes and completes the profile'
);
select ok(
  (
    select accepted_at is not null
    from public.institution_memberships
    where id = '31000000-0000-0000-0000-000000000001'::uuid
  ),
  'acceptance records an audit timestamp'
);
select ok(
  (
    select profile_completed_at is not null
    from public.profiles
    where user_id = '11000000-0000-0000-0000-000000000001'::uuid
  ),
  'acceptance records explicit profile completion'
);
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000001'::uuid,
    'Invited Student'
  )$$,
  '42501',
  'Invitation cannot be accepted.',
  'an accepted invitation cannot be replayed'
);
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000002'::uuid,
    'Wrong user'
  )$$,
  '42501',
  'Invitation cannot be accepted.',
  'a user cannot accept another user invitation'
);
select throws_ok(
  $$select public.complete_my_profile('   ')$$,
  '22023',
  'Display name must contain between 1 and 120 characters.',
  'profile completion rejects a blank display name'
);
select results_eq(
  $$select public.complete_my_profile('Updated Student') #>> '{profile,display_name}'$$,
  array['Updated Student'::text],
  'profile completion returns the freshly updated profile'
);

reset role;
select lives_ok(
  $$
    update public.institution_memberships
    set status = 'suspended'
    where id = '31000000-0000-0000-0000-000000000001'::uuid
      and accepted_at is not null
  $$,
  'later suspension preserves the invitation acceptance audit timestamp'
);
set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000002';
set local role authenticated;
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000002'::uuid,
    'Expired Student'
  )$$,
  '42501',
  'Invitation cannot be accepted.',
  'an expired invitation is rejected'
);

reset role;
set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000005';
set local role authenticated;
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000005'::uuid,
    'No role student'
  )$$,
  '42501',
  'Invitation cannot be accepted.',
  'an invitation without a preassigned role is rejected'
);
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000006'::uuid,
    'Inactive campus student'
  )$$,
  '42501',
  'Invitation cannot be accepted.',
  'an invitation for an inactive institution is rejected'
);

reset role;
set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000004';
set local role authenticated;
select throws_ok(
  $$select public.complete_my_profile('Suspended Student')$$,
  '42501',
  'An active institution membership is required.',
  'a suspended user cannot complete an active profile'
);

reset role;
delete from public.profiles
where user_id = '11000000-0000-0000-0000-000000000003'::uuid;
set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000003';
set local role authenticated;
select ok(
  jsonb_array_length(public.get_my_identity_context() -> 'memberships') = 1
    and public.get_my_identity_context() #> '{profile,display_name}' = 'null'::jsonb,
  'identity context retains memberships if a privileged process removes a profile'
);

reset role;
set local request.jwt.claim.sub = '11000000-0000-0000-0000-000000000001';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;
select throws_ok(
  $$select public.get_my_identity_context()$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot load identity context'
);
select throws_ok(
  $$select public.complete_my_profile('OTP Recovery User')$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot complete a profile'
);
select throws_ok(
  $$select public.accept_my_invitation(
    '31000000-0000-0000-0000-000000000002'::uuid,
    'OTP Recovery User'
  )$$,
  '42501',
  'Password authentication is required.',
  'an OTP recovery token cannot accept an invitation'
);

reset role;
select * from finish();
rollback;
