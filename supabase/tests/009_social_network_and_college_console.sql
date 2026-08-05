begin;

create extension if not exists pgtap with schema extensions;
select plan(47);

select has_table('public', 'social_profiles', 'social profiles exist');
select has_table('public', 'social_posts', 'social posts exist');
select has_table('public', 'social_post_media', 'post media exists');
select has_table('public', 'social_post_likes', 'post likes exist');
select has_table('public', 'social_comments', 'comments exist');
select has_table('public', 'social_reposts', 'reposts exist');
select has_table('public', 'social_post_saves', 'private saves exist');
select has_table('public', 'social_follows', 'follows exist');
select has_table('public', 'social_blocks', 'blocks exist');
select has_table('public', 'social_message_requests', 'message requests exist');
select has_table('public', 'social_threads', 'accepted message threads exist');
select has_table('public', 'social_messages', 'social messages exist');
select has_table('public', 'institution_claims', 'college claims exist');
select has_table('public', 'faculty_registrations', 'Faculty registrations exist');
select has_table('public', 'social_reports', 'content reports exist');
select has_table('public', 'social_notifications', 'social notifications exist');

select has_function('public', 'create_social_post', array['text','text','uuid','uuid','boolean','jsonb'], 'post creation RPC exists');
select has_function('public', 'list_social_feed', array['text','timestamp with time zone','integer'], 'feed RPC exists');
select has_function('public', 'toggle_social_like', array['uuid'], 'like RPC exists');
select has_function('public', 'toggle_social_save', array['uuid'], 'save RPC exists');
select has_function('public', 'add_social_comment', array['uuid','text','uuid'], 'comment RPC exists');
select has_function('public', 'toggle_social_repost', array['uuid','text'], 'repost RPC exists');
select has_function('public', 'send_social_message_request', array['uuid','text'], 'message request RPC exists');
select has_function('public', 'respond_social_message_request', array['uuid','boolean'], 'message acceptance RPC exists');
select has_function('public', 'submit_institution_claim', array['uuid','text','text','text','text','text','text','text'], 'college registration RPC exists');
select has_function('public', 'submit_faculty_registration', array['uuid','text','text','text','text'], 'Faculty registration RPC exists');

select ok(has_function_privilege('authenticated', 'public.list_social_feed(text,timestamptz,integer)', 'execute'), 'authenticated users can load the feed');
select ok(not has_function_privilege('anon', 'public.list_social_feed(text,timestamptz,integer)', 'execute'), 'anonymous users cannot load the feed');
select ok(not has_table_privilege('authenticated', 'public.social_posts', 'insert'), 'clients cannot bypass post creation RPC');
select ok(not has_table_privilege('authenticated', 'public.social_messages', 'select'), 'clients cannot bypass message projection RPC');

insert into public.institutions (id, slug, name, registration_status) values
  ('b1000000-0000-0000-0000-000000000001', 'social-test-college', 'Social Test College', 'unclaimed');

insert into auth.users (id, email) values
  ('b2000000-0000-0000-0000-000000000001', 'social-one@example.invalid'),
  ('b2000000-0000-0000-0000-000000000002', 'social-two@example.invalid');
update public.profiles
set display_name = case user_id
    when 'b2000000-0000-0000-0000-000000000001' then 'Social One'
    else 'Social Two'
  end,
  profile_completed_at = now()
where user_id in (
  'b2000000-0000-0000-0000-000000000001',
  'b2000000-0000-0000-0000-000000000002'
);

select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok($$select public.ensure_social_profile()$$, 'authenticated users can create their social profile');

select isnt(
  public.create_social_post('Hello campuses', 'public', 'b3000000-0000-0000-0000-000000000001', null, false, '[]'::jsonb),
  null,
  'a signed-in user can publish a public text post'
);

select is(
  public.toggle_social_like((select id from public.social_posts where client_post_id = 'b3000000-0000-0000-0000-000000000001')),
  true,
  'first like activates the reaction'
);
select is(
  public.toggle_social_like((select id from public.social_posts where client_post_id = 'b3000000-0000-0000-0000-000000000001')),
  false,
  'second like removes the reaction'
);
select is(
  public.toggle_social_save((select id from public.social_posts where client_post_id = 'b3000000-0000-0000-0000-000000000001')),
  true,
  'a post can be saved privately'
);
select isnt(
  public.add_social_comment((select id from public.social_posts where client_post_id = 'b3000000-0000-0000-0000-000000000001'), 'Useful update', null),
  null,
  'visible posts accept comments'
);

select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000002', true);
select lives_ok($$select public.ensure_social_profile()$$, 'message recipients can initialize their profile');
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000001', true);
select isnt(
  public.send_social_message_request('b2000000-0000-0000-0000-000000000002', 'May we connect?'),
  null,
  'a new contact receives one message request'
);
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000002', true);
select isnt(
  public.respond_social_message_request((select id from public.social_message_requests where recipient_user_id = auth.uid()), true),
  null,
  'the recipient can accept and create a conversation'
);
select isnt(
  public.send_social_message((select id from public.social_threads limit 1), 'Accepted conversation', 'b4000000-0000-0000-0000-000000000001', null, null, null),
  null,
  'accepted participants can send messages'
);

select lives_ok($$select public.block_social_user('b2000000-0000-0000-0000-000000000001', true)$$, 'recipients can block an account');
select set_config('request.jwt.claim.sub', 'b2000000-0000-0000-0000-000000000001', true);
select throws_ok(
  $$select public.send_social_message_request('b2000000-0000-0000-0000-000000000002', 'Blocked request')$$,
  'P0001',
  'Account unavailable',
  'blocked accounts cannot send another request'
);

insert into public.student_affiliation_requests (
  institution_id, user_id, official_name, roll_number, programme, study_year
) values (
  'b1000000-0000-0000-0000-000000000001',
  'b2000000-0000-0000-0000-000000000001',
  'Social One', 'SOCIAL-1', 'B.Sc', 1
);
select isnt(
  public.create_social_post('Pending students can reach their college community', 'college', 'b3000000-0000-0000-0000-000000000002', null, false, '[]'::jsonb),
  null,
  'pending students can publish to their resolved college community'
);
select is(
  jsonb_array_length(public.list_social_feed('college', null, 20)),
  1,
  'the college feed returns posts for a pending affiliation'
);

select isnt(
  public.submit_institution_claim(
    'b1000000-0000-0000-0000-000000000001', 'Social One', 'Registrar', 'EMP-1',
    'registrar@college.example', '9999999999', 'b2000000-0000-0000-0000-000000000001/claims/letter.pdf', null
  ),
  null,
  'college authorities can submit a desktop claim without self-approval'
);
select is(
  (select status from public.institution_claims where applicant_user_id = auth.uid()),
  'pending',
  'a submitted college claim remains pending'
);
select throws_ok(
  $$select public.submit_faculty_registration('b1000000-0000-0000-0000-000000000001', 'FAC-1', 'Science', 'Lecturer', 'faculty@college.example')$$,
  'P0001',
  'College must be verified before Faculty can register',
  'Faculty authority cannot be created for an unverified college'
);

select * from finish();
rollback;
