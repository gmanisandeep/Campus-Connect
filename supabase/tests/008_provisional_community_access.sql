begin;

create extension if not exists pgtap with schema extensions;

select plan(30);

set local request.jwt.claim = '{"amr":[{"method":"password"}]}';

select has_table('public', 'community_feed_posts', 'official feed posts are persisted');
select has_table('public', 'faculty_contact_threads', 'faculty contact threads are persisted');
select has_table('public', 'faculty_contact_messages', 'faculty contact messages are persisted');
select has_function(
  'public',
  'get_my_community_overview',
  array['uuid'],
  'community overview RPC exists'
);
select has_function(
  'public',
  'list_faculty_contact_messages',
  array['uuid'],
  'conversation read RPC exists'
);
select has_function(
  'public',
  'send_faculty_contact_message',
  array['uuid', 'uuid', 'uuid', 'uuid', 'text'],
  'conversation send RPC exists'
);
select has_function(
  'public',
  'publish_community_feed_post',
  array['uuid', 'text', 'text', 'timestamp with time zone'],
  'official publishing RPC exists'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_community_overview(uuid)',
    'execute'
  ),
  'authenticated users can request their server-derived Community scope'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.get_my_community_overview(uuid)',
    'execute'
  ),
  'anonymous users cannot open Community'
);
select ok(
  not has_table_privilege('authenticated', 'public.community_feed_posts', 'select'),
  'clients cannot bypass Feed RPC scope'
);
select ok(
  not has_table_privilege('authenticated', 'public.faculty_contact_messages', 'insert'),
  'clients cannot insert messages directly'
);

insert into public.institutions (id, slug, name) values
  ('a1000000-0000-0000-0000-000000000001', 'community-college', 'Community College'),
  ('a1000000-0000-0000-0000-000000000002', 'other-community-college', 'Other Community College');

insert into public.institution_programmes (
  id, institution_id, name, duration_months
) values (
  'a2000000-0000-0000-0000-000000000001',
  'a1000000-0000-0000-0000-000000000001',
  'B.Sc Community',
  36
);

insert into auth.users (id, email) values
  ('a3000000-0000-0000-0000-000000000001', 'pending-community@example.invalid'),
  ('a3000000-0000-0000-0000-000000000002', 'faculty-community@example.invalid'),
  ('a3000000-0000-0000-0000-000000000003', 'publisher-community@example.invalid'),
  ('a3000000-0000-0000-0000-000000000004', 'other-faculty@example.invalid');

insert into public.profiles (user_id, display_name, profile_completed_at) values
  ('a3000000-0000-0000-0000-000000000002', 'Verified Faculty', now()),
  ('a3000000-0000-0000-0000-000000000003', 'Campus Publisher', now()),
  ('a3000000-0000-0000-0000-000000000004', 'Other Faculty', now())
on conflict (user_id) do update
set display_name = excluded.display_name,
    profile_completed_at = excluded.profile_completed_at;

insert into public.institution_memberships (
  id, institution_id, user_id, status, accepted_at
) values
  (
    'a4000000-0000-0000-0000-000000000002',
    'a1000000-0000-0000-0000-000000000001',
    'a3000000-0000-0000-0000-000000000002',
    'active', now()
  ),
  (
    'a4000000-0000-0000-0000-000000000003',
    'a1000000-0000-0000-0000-000000000001',
    'a3000000-0000-0000-0000-000000000003',
    'active', now()
  ),
  (
    'a4000000-0000-0000-0000-000000000004',
    'a1000000-0000-0000-0000-000000000002',
    'a3000000-0000-0000-0000-000000000004',
    'active', now()
  );

insert into public.membership_roles (membership_id, role_id)
select 'a4000000-0000-0000-0000-000000000002'::uuid, role_record.id
from public.roles role_record where role_record.key = 'faculty';
insert into public.membership_roles (membership_id, role_id)
select 'a4000000-0000-0000-0000-000000000003'::uuid, role_record.id
from public.roles role_record where role_record.key = 'institution_administrator';
insert into public.membership_roles (membership_id, role_id)
select 'a4000000-0000-0000-0000-000000000004'::uuid, role_record.id
from public.roles role_record where role_record.key = 'faculty';

set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000001';
set local role authenticated;

select lives_ok(
  $$select public.submit_student_affiliation_request(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    'a2000000-0000-0000-0000-000000000001'::uuid,
    'Pending Community',
    'COMM-001',
    2026::smallint,
    2029::smallint,
    'regular'::public.student_progression_status
  )$$,
  'a pending affiliation request opens provisional Community scope'
);
select results_eq(
  $$select public.get_my_community_overview(null::uuid) ->> 'access_state'$$,
  array['pending_verification'::text],
  'pending students receive an explicit provisional state'
);
select results_eq(
  $$select public.get_my_community_overview(null::uuid) ->> 'institution_name'$$,
  array['Community College'::text],
  'the pending request derives the only Community institution'
);
select results_eq(
  $$select jsonb_array_length(public.get_my_community_overview(null::uuid) -> 'contacts')$$,
  array[1],
  'pending students can discover only active Faculty in their college'
);
select results_eq(
  $$select public.get_my_community_overview(null::uuid) #>> '{contacts,0,participant_name}'$$,
  array['Verified Faculty'::text],
  'the Faculty directory returns the verified profile name'
);
select throws_ok(
  $$select public.get_my_community_overview(
    'a1000000-0000-0000-0000-000000000002'::uuid
  )$$,
  '42501',
  'Community access is not available for this institution.',
  'a pending student cannot switch to another college Community'
);

reset role;
set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000003';
set local role authenticated;

select lives_ok(
  $$select public.publish_community_feed_post(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    'Official update',
    'The college office published this update.',
    null
  )$$,
  'an authorized college publisher can create an official post'
);

reset role;
insert into public.community_feed_posts (
  institution_id, author_user_id, title, body, published_at, expires_at
) values (
  'a1000000-0000-0000-0000-000000000001',
  'a3000000-0000-0000-0000-000000000003',
  'Expired update',
  'This should no longer be visible.',
  now() - interval '2 days',
  now() - interval '1 day'
);

set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000001';
set local role authenticated;

select results_eq(
  $$select jsonb_array_length(public.get_my_community_overview(null::uuid) -> 'feed')$$,
  array[1],
  'the Feed includes current posts and excludes expired posts'
);
select results_eq(
  $$select public.get_my_community_overview(null::uuid) #>> '{feed,0,title}'$$,
  array['Official update'::text],
  'the provisional Feed returns authoritative post content'
);
select results_eq(
  $$select public.send_faculty_contact_message(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    null::uuid,
    'a3000000-0000-0000-0000-000000000002'::uuid,
    'a5000000-0000-0000-0000-000000000001'::uuid,
    'Hello Faculty'
  ) #>> '{messages,0,body}'$$,
  array['Hello Faculty'::text],
  'a pending student can message verified Faculty in the selected college'
);
select results_eq(
  $$select jsonb_array_length(
    public.send_faculty_contact_message(
      'a1000000-0000-0000-0000-000000000001'::uuid,
      (public.get_my_community_overview(null::uuid) #>>
        '{contacts,0,thread_id}')::uuid,
      null::uuid,
      'a5000000-0000-0000-0000-000000000001'::uuid,
      'Hello Faculty'
    ) -> 'messages'
  )$$,
  array[1],
  'client message identifiers make exact retries idempotent'
);
select throws_ok(
  $$select public.send_faculty_contact_message(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    null::uuid,
    'a3000000-0000-0000-0000-000000000004'::uuid,
    'a5000000-0000-0000-0000-000000000002'::uuid,
    'Cross-campus message'
  )$$,
  '42501',
  'Choose an active Faculty member.',
  'pending students cannot message Faculty from another college'
);
select throws_ok(
  $$select public.send_faculty_contact_message(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    (public.get_my_community_overview(null::uuid) #>>
      '{contacts,0,thread_id}')::uuid,
    null::uuid,
    'a5000000-0000-0000-0000-000000000003'::uuid,
    '   '
  )$$,
  '22023',
  'Message must contain between 1 and 2000 characters.',
  'blank messages are rejected'
);
reset role;
select ok(
  (select expires_at - sent_at >= interval '179 days'
   from public.faculty_contact_messages limit 1),
  'messages carry the bounded 180-day visibility window'
);

set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000002';
set local role authenticated;

select results_eq(
  $$select jsonb_array_length(
    public.get_my_community_overview(
      'a1000000-0000-0000-0000-000000000001'::uuid
    ) -> 'contacts'
  )$$,
  array[1],
  'Faculty sees only student threads addressed to them'
);
select results_eq(
  $$select public.get_my_community_overview(
      'a1000000-0000-0000-0000-000000000001'::uuid
    ) #>> '{contacts,0,participant_role}'$$,
  array['Student'::text],
  'Faculty contact rows identify the student side of the conversation'
);
select results_eq(
  $$select jsonb_array_length(public.list_faculty_contact_messages(
    (public.get_my_community_overview(
      'a1000000-0000-0000-0000-000000000001'::uuid
    ) #>> '{contacts,0,thread_id}')::uuid
  ))$$,
  array[1],
  'the addressed Faculty member can read the conversation'
);

reset role;
create temporary table community_test_thread as
select id from public.faculty_contact_threads
where faculty_user_id = 'a3000000-0000-0000-0000-000000000002';
grant select on community_test_thread to authenticated;
set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000004';
set local role authenticated;

select throws_ok(
  $$select public.list_faculty_contact_messages(
    (select id from community_test_thread)
  )$$,
  '42501',
  'Conversation access is no longer available.',
  'unrelated Faculty cannot read another conversation'
);

reset role;
set local request.jwt.claim.sub = 'a3000000-0000-0000-0000-000000000001';
set local role authenticated;

select throws_ok(
  $$select public.publish_community_feed_post(
    'a1000000-0000-0000-0000-000000000001'::uuid,
    'Unauthorized',
    'Pending students cannot publish.',
    null
  )$$,
  '42501',
  'Announcement publishing access is required.',
  'provisional students cannot publish official Feed posts'
);

select * from finish();

rollback;
