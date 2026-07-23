begin;

alter table public.profiles
  alter column display_name drop not null,
  add column profile_completed_at timestamptz,
  add constraint profiles_completed_name_required
    check (profile_completed_at is null or display_name is not null);

alter table public.institution_memberships
  add column invitation_expires_at timestamptz,
  add column accepted_at timestamptz,
  add constraint memberships_invitation_expiry_required
    check (status <> 'invited' or invitation_expires_at is not null),
  add constraint memberships_acceptance_state_valid
    check (accepted_at is null or status <> 'invited');

create index institution_memberships_pending_invitation_idx
  on public.institution_memberships (user_id, invitation_expires_at)
  where status = 'invited';

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function private.handle_new_auth_user()
  from public, anon, authenticated, service_role;

create trigger auth_user_profile_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

insert into public.profiles (user_id)
select auth_user.id
from auth.users auth_user
on conflict (user_id) do nothing;

create or replace function public.get_my_identity_context()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  result jsonb;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  select jsonb_build_object(
    'user_id', current_user_id,
    'profile', jsonb_build_object(
      'display_name', profile_record.display_name,
      'profile_completed_at', profile_record.profile_completed_at
    ),
    'memberships', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', membership.id,
            'institution_id', institution_record.id,
            'institution_name', institution_record.name,
            'institution_active', institution_record.is_active,
            'status', membership.status,
            'invitation_expires_at', membership.invitation_expires_at,
            'roles', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'key', role_record.key,
                    'label', role_record.label,
                    'permissions', coalesce(
                      (
                        select jsonb_agg(
                          permission_record.key
                          order by permission_record.key
                        )
                        from public.role_permissions role_permission
                        join public.permissions permission_record
                          on permission_record.id = role_permission.permission_id
                        where role_permission.role_id = role_record.id
                      ),
                      '[]'::jsonb
                    )
                  )
                  order by role_record.key
                )
                from public.membership_roles membership_role
                join public.roles role_record
                  on role_record.id = membership_role.role_id
                where membership_role.membership_id = membership.id
              ),
              '[]'::jsonb
            )
          )
          order by institution_record.name, membership.id
        )
        from public.institution_memberships membership
        join public.institutions institution_record
          on institution_record.id = membership.institution_id
        where membership.user_id = current_user_id
          and membership.status <> 'left'
      ),
      '[]'::jsonb
    )
  )
  into result
  from (values (true)) as identity_context(singleton)
  left join public.profiles profile_record
    on profile_record.user_id = current_user_id;

  return result;
end;
$$;

create or replace function public.accept_my_invitation(
  target_membership_id uuid,
  new_display_name text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_display_name text := btrim(
    new_display_name,
    U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000'
  );
  invitation public.institution_memberships%rowtype;
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  if normalized_display_name is null
     or char_length(normalized_display_name) not between 1 and 120 then
    raise exception using
      errcode = '22023',
      message = 'Display name must contain between 1 and 120 characters.';
  end if;

  select membership.*
  into invitation
  from public.institution_memberships membership
  join public.institutions institution_record
    on institution_record.id = membership.institution_id
  where membership.id = target_membership_id
    and membership.user_id = current_user_id
    and membership.status = 'invited'
    and institution_record.is_active
    and membership.invitation_expires_at > now()
  for update of membership, institution_record;

  if invitation.id is null then
    raise exception using
      errcode = '42501',
      message = 'Invitation cannot be accepted.';
  end if;

  perform 1
  from public.membership_roles membership_role
  where membership_role.membership_id = invitation.id
  for share;

  if not found then
    raise exception using
      errcode = '42501',
      message = 'Invitation cannot be accepted.';
  end if;

  insert into public.profiles (
    user_id,
    display_name,
    profile_completed_at
  ) values (
    current_user_id,
    normalized_display_name,
    now()
  )
  on conflict (user_id) do update
  set display_name = excluded.display_name,
      profile_completed_at = coalesce(
        public.profiles.profile_completed_at,
        excluded.profile_completed_at
      );

  update public.institution_memberships
  set status = 'active',
      accepted_at = now()
  where id = invitation.id;

  return public.get_my_identity_context();
end;
$$;

create or replace function public.complete_my_profile(new_display_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_display_name text := btrim(
    new_display_name,
    U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000'
  );
begin
  if current_user_id is null
     or not private.has_password_authentication() then
    raise exception using
      errcode = '42501',
      message = 'Password authentication is required.';
  end if;

  if normalized_display_name is null
     or char_length(normalized_display_name) not between 1 and 120 then
    raise exception using
      errcode = '22023',
      message = 'Display name must contain between 1 and 120 characters.';
  end if;

  perform 1
  from public.institution_memberships membership
  join public.institutions institution_record
    on institution_record.id = membership.institution_id
  where membership.user_id = current_user_id
    and membership.status = 'active'
    and institution_record.is_active
  limit 1
  for share of membership, institution_record;

  if not found then
    raise exception using
      errcode = '42501',
      message = 'An active institution membership is required.';
  end if;

  insert into public.profiles (
    user_id,
    display_name,
    profile_completed_at
  ) values (
    current_user_id,
    normalized_display_name,
    now()
  )
  on conflict (user_id) do update
  set display_name = excluded.display_name,
      profile_completed_at = coalesce(
        public.profiles.profile_completed_at,
        excluded.profile_completed_at
      );

  return public.get_my_identity_context();
end;
$$;

revoke all on function public.get_my_identity_context()
  from public, anon, authenticated, service_role;
revoke all on function public.accept_my_invitation(uuid, text)
  from public, anon, authenticated, service_role;
revoke all on function public.complete_my_profile(text)
  from public, anon, authenticated, service_role;

grant execute on function public.get_my_identity_context()
  to authenticated;
grant execute on function public.accept_my_invitation(uuid, text)
  to authenticated;
grant execute on function public.complete_my_profile(text)
  to authenticated;

commit;
