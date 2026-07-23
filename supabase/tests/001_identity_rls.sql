begin;

create extension if not exists pgtap with schema extensions;

select plan(81);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_table('public', 'institutions', 'institutions table exists');
select has_table('public', 'institution_memberships', 'memberships table exists');
select has_table('public', 'membership_roles', 'membership roles table exists');
select has_function(
  'private',
  'has_password_authentication',
  array[]::text[],
  'private password-authentication helper exists'
);
select has_function(
  'private',
  'is_active_member',
  array['uuid'],
  'private membership helper exists'
);
select has_function(
  'private',
  'has_permission',
  array['uuid', 'text'],
  'private permission helper exists'
);
select ok(
  to_regprocedure('public.has_password_authentication()') is null,
  'password-authentication helper is not exposed from public'
);
select ok(
  to_regprocedure('public.is_active_member(uuid)') is null,
  'membership helper is not exposed from public'
);
select ok(
  to_regprocedure('public.has_permission(uuid,text)') is null,
  'permission helper is not exposed from public'
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
          'institutions',
          'profiles',
          'institution_memberships',
          'roles',
          'permissions',
          'role_permissions',
          'membership_roles'
        ]
      )
      and not relation.relrowsecurity
  $$,
  'RLS is enabled on every exposed identity table'
);

select policies_are(
  'public',
  'institutions',
  array['institutions_read_active_member'],
  'institutions use the expected policy set'
);
select policies_are(
  'public',
  'profiles',
  array['profiles_read_self', 'profiles_update_self'],
  'profiles use the expected policy set'
);
select policies_are(
  'public',
  'institution_memberships',
  array['memberships_read_self'],
  'memberships use the expected policy set'
);
select policies_are(
  'public',
  'roles',
  array['roles_read_authenticated'],
  'roles use the expected policy set'
);
select policies_are(
  'public',
  'permissions',
  array['permissions_read_authenticated'],
  'permissions use the expected policy set'
);
select policies_are(
  'public',
  'role_permissions',
  array['role_permissions_read_authenticated'],
  'role permissions use the expected policy set'
);
select policies_are(
  'public',
  'membership_roles',
  array['membership_roles_read_own'],
  'membership roles use the expected policy set'
);
select ok(
  not has_schema_privilege('anon', 'private', 'usage'),
  'anonymous requests cannot use the private schema'
);
select ok(
  has_schema_privilege('authenticated', 'private', 'usage'),
  'authenticated policies can use the private schema'
);
select ok(
  not exists (
    select 1
    from unnest(
      array[
        'institutions',
        'profiles',
        'institution_memberships',
        'roles',
        'permissions',
        'role_permissions',
        'membership_roles'
      ]
    ) as identity_table(table_name)
    where has_table_privilege(
      'anon',
      format('public.%I', identity_table.table_name),
      'select,insert,update,delete,truncate,references,trigger'
    )
  ),
  'anonymous requests have no identity-table DML privileges'
);
select ok(
  has_table_privilege('authenticated', 'public.institutions', 'select'),
  'authenticated requests can select institutions subject to RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.institutions', 'insert'),
  'authenticated requests cannot insert institutions'
);
select ok(
  has_table_privilege('service_role', 'public.institutions', 'insert'),
  'the service role has deliberate institution write access'
);
select ok(
  not has_function_privilege(
    'anon',
    'private.has_password_authentication()',
    'execute'
  ),
  'anonymous requests cannot execute the password-authentication helper'
);
select ok(
  not has_function_privilege(
    'anon',
    'private.is_active_member(uuid)',
    'execute'
  ),
  'anonymous requests cannot execute the membership helper'
);
select ok(
  not has_function_privilege(
    'anon',
    'private.has_permission(uuid,text)',
    'execute'
  ),
  'anonymous requests cannot execute the permission helper'
);
select ok(
  has_function_privilege(
    'authenticated',
    'private.has_password_authentication()',
    'execute'
  ),
  'authenticated policies can execute the password-authentication helper'
);
select ok(
  has_function_privilege(
    'authenticated',
    'private.is_active_member(uuid)',
    'execute'
  ),
  'authenticated policies can execute the membership helper'
);
select ok(
  has_function_privilege(
    'authenticated',
    'private.has_permission(uuid,text)',
    'execute'
  ),
  'authenticated policies can execute the permission helper'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.set_updated_at()',
    'execute'
  ),
  'anonymous requests cannot execute the timestamp trigger helper'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.set_updated_at()',
    'execute'
  ),
  'authenticated profile updates can execute the timestamp trigger helper'
);
select ok(
  not has_table_privilege('authenticated', 'public.profiles', 'update'),
  'authenticated requests do not receive table-wide profile updates'
);
select ok(
  has_column_privilege(
    'authenticated',
    'public.profiles',
    'display_name',
    'update'
  ),
  'profile owners may update display names'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'public.profiles',
    'created_at',
    'update'
  ),
  'profile owners cannot rewrite creation timestamps'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'public.profiles',
    'user_id',
    'update'
  ),
  'profile owners cannot rewrite profile ownership'
);

insert into auth.users (id, email) values
  (
    '10000000-0000-0000-0000-000000000001',
    'student-a@example.invalid'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'faculty-b@example.invalid'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'faculty-closed@example.invalid'
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    'student-suspended@example.invalid'
  );

insert into public.profiles (user_id, display_name) values
  (
    '10000000-0000-0000-0000-000000000001',
    'Student A'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Faculty B'
  )
on conflict (user_id) do update
set display_name = excluded.display_name;

insert into public.institutions (id, slug, name, is_active) values
  (
    '20000000-0000-0000-0000-000000000001',
    'alpha-campus',
    'Alpha Campus',
    true
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'beta-campus',
    'Beta Campus',
    true
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    'closed-campus',
    'Closed Campus',
    false
  );

insert into public.institution_memberships (
  id,
  institution_id,
  user_id,
  status
) values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'active'
  ),
  (
    '30000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    'active'
  ),
  (
    '30000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000004',
    'suspended'
  );

insert into public.membership_roles (membership_id, role_id)
select mapping.membership_id::uuid, role_record.id
from (
  values
    ('30000000-0000-0000-0000-000000000001', 'student'),
    ('30000000-0000-0000-0000-000000000002', 'faculty'),
    ('30000000-0000-0000-0000-000000000003', 'faculty'),
    ('30000000-0000-0000-0000-000000000004', 'student')
) as mapping(membership_id, role_key)
join public.roles role_record
  on role_record.key = mapping.role_key;

set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000001';
set local role authenticated;

select results_eq(
  $$select slug from public.institutions order by slug$$,
  array['alpha-campus'::text],
  'an active student sees only their active institution'
);
select is_empty(
  $$select id from public.institutions where slug = 'beta-campus'$$,
  'cross-institution reads are denied'
);
select results_eq(
  $$select institution_id from public.institution_memberships order by id$$,
  array['20000000-0000-0000-0000-000000000001'::uuid],
  'a student sees only their own membership'
);
select results_eq(
  $$
    select role_record.key
    from public.membership_roles membership_role
    join public.roles role_record on role_record.id = membership_role.role_id
    order by role_record.key
  $$,
  array['student'::text],
  'a student sees only roles attached to their active membership'
);
select results_eq(
  $$
    select permission_record.key
    from public.role_permissions role_permission
    join public.roles role_record on role_record.id = role_permission.role_id
    join public.permissions permission_record
      on permission_record.id = role_permission.permission_id
    where role_record.key = 'student'
    order by permission_record.key
  $$,
  array['attendance_read_own'::text],
  'the student role has the minimal personal-attendance permission'
);
select results_eq(
  $$
    select permission_record.key
    from public.role_permissions role_permission
    join public.roles role_record on role_record.id = role_permission.role_id
    join public.permissions permission_record
      on permission_record.id = role_permission.permission_id
    where role_record.key = 'faculty'
    order by permission_record.key
  $$,
  array['attendance_record'::text, 'roster_read'::text],
  'the faculty role has the minimal roster and attendance permissions'
);
select ok(
  private.is_active_member(
    '20000000-0000-0000-0000-000000000001'::uuid
  ),
  'an active student passes active membership resolution'
);
select ok(
  not private.is_active_member(
    '20000000-0000-0000-0000-000000000002'::uuid
  ),
  'a student does not pass membership checks for another institution'
);
select ok(
  private.has_permission(
    '20000000-0000-0000-0000-000000000001'::uuid,
    'attendance_read_own'
  ),
  'a student receives their mapped permission'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000001'::uuid,
    'attendance_record'
  ),
  'a student does not receive the faculty attendance permission'
);
select results_eq(
  $$
    with updated_profile as (
      update public.profiles
      set display_name = 'Student A Updated'
      where user_id = '10000000-0000-0000-0000-000000000001'
      returning display_name
    )
    select display_name from updated_profile
  $$,
  array['Student A Updated'::text],
  'a profile owner can update an allowed profile column'
);
select throws_ok(
  $$update public.profiles
    set display_name = '   '
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects an ordinary-space-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = E'\t'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a tab-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = E'\n'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a newline-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\00A0'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a non-breaking-space-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\2003Padded Student\2003'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects Unicode-space padding'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\00AD'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a soft-hyphen-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\200E'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a direction-mark-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\2800'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a braille-blank-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = U&'\3164'
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects a Hangul-filler-only name'
);
select throws_ok(
  $$update public.profiles
    set display_name = ' Padded Student '
    where user_id = '10000000-0000-0000-0000-000000000001'::uuid$$,
  '23514',
  'new row for relation "profiles" violates check constraint "profiles_display_name_normalized"',
  'a direct profile update rejects unnormalized surrounding spaces'
);
select is_empty(
  $$
    with updated_profile as (
      update public.profiles
      set display_name = 'Cross-tenant overwrite'
      where user_id = '10000000-0000-0000-0000-000000000002'
      returning user_id
    )
    select user_id from updated_profile
  $$,
  'a profile owner cannot update another profile'
);

reset role;
set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000002';
set local role authenticated;

select results_eq(
  $$select slug from public.institutions order by slug$$,
  array['beta-campus'::text],
  'active faculty see only their own institution'
);
select results_eq(
  $$
    select role_record.key
    from public.membership_roles membership_role
    join public.roles role_record on role_record.id = membership_role.role_id
    order by role_record.key
  $$,
  array['faculty'::text],
  'faculty see only roles attached to their active membership'
);
select ok(
  private.has_permission(
    '20000000-0000-0000-0000-000000000002'::uuid,
    'roster_read'
  ),
  'faculty receive roster access'
);
select ok(
  private.has_permission(
    '20000000-0000-0000-0000-000000000002'::uuid,
    'attendance_record'
  ),
  'faculty receive attendance recording access'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000002'::uuid,
    'attendance_read_own'
  ),
  'faculty do not inherit the student permission'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000001'::uuid,
    'attendance_record'
  ),
  'faculty permissions cannot cross institution boundaries'
);

reset role;
set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000003';
set local role authenticated;

select is_empty(
  $$select id from public.institutions$$,
  'an inactive institution is not readable by its otherwise active member'
);
select ok(
  not private.is_active_member(
    '20000000-0000-0000-0000-000000000003'::uuid
  ),
  'an inactive institution fails active membership resolution'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000003'::uuid,
    'attendance_record'
  ),
  'an inactive institution grants no permissions'
);
select is_empty(
  $$select membership_id from public.membership_roles$$,
  'roles in an inactive institution are hidden'
);

reset role;
set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000004';
set local role authenticated;

select is_empty(
  $$select id from public.institutions$$,
  'a suspended member cannot read their institution'
);
select ok(
  not private.is_active_member(
    '20000000-0000-0000-0000-000000000001'::uuid
  ),
  'a suspended membership fails active membership resolution'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000001'::uuid,
    'attendance_read_own'
  ),
  'a suspended membership grants no permissions'
);
select is_empty(
  $$select membership_id from public.membership_roles$$,
  'roles attached to a suspended membership are hidden'
);

reset role;
set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000001';
set local request.jwt.claim = '{"amr":[{"method":"otp"}]}';
set local role authenticated;

select ok(
  not private.has_password_authentication(),
  'an OTP recovery token fails password-authentication resolution'
);
select is_empty(
  $$select id from public.institutions$$,
  'an OTP recovery token cannot read institutions'
);
select is_empty(
  $$select user_id from public.profiles$$,
  'an OTP recovery token cannot read profiles'
);
select is_empty(
  $$select id from public.institution_memberships$$,
  'an OTP recovery token cannot read memberships'
);
select is_empty(
  $$select id from public.roles$$,
  'an OTP recovery token cannot read roles'
);
select is_empty(
  $$select id from public.permissions$$,
  'an OTP recovery token cannot read permissions'
);
select is_empty(
  $$select role_id from public.role_permissions$$,
  'an OTP recovery token cannot read role permissions'
);
select is_empty(
  $$select membership_id from public.membership_roles$$,
  'an OTP recovery token cannot read membership roles'
);
select ok(
  not private.is_active_member(
    '20000000-0000-0000-0000-000000000001'::uuid
  ),
  'an OTP recovery token fails active membership resolution'
);
select ok(
  not private.has_permission(
    '20000000-0000-0000-0000-000000000001'::uuid,
    'attendance_read_own'
  ),
  'an OTP recovery token receives no permissions'
);

reset role;
select * from finish();
rollback;
