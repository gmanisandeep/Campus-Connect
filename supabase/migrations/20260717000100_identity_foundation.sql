begin;

create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to authenticated;

create type public.membership_status as enum ('invited', 'active', 'suspended', 'left');

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name text not null check (char_length(name) between 2 and 160),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null
    constraint profiles_display_name_normalized
    check (
      display_name = btrim(
        display_name,
        U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000'
      )
      and char_length(display_name) between 1 and 120
      and display_name !~ '[[:cntrl:]]'
      and translate(
        display_name,
        U&'\0009\000A\000B\000C\000D\0020\0085\00A0\00AD\034F\061C\115F\1160\1680\17B4\17B5\180E\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\200B\200C\200D\200E\200F\2028\2029\202A\202B\202C\202D\202E\202F\205F\2060\2061\2062\2063\2064\2066\2067\2068\2069\206A\206B\206C\206D\206E\206F\2800\3000\3164\FFA0\FEFF',
        ''
      ) <> ''
    ),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.institution_memberships (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status public.membership_status not null default 'invited',
  invited_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institution_id, user_id)
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (key ~ '^[a-z][a-z0-9_]*$'),
  label text not null,
  is_system boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique check (key ~ '^[a-z][a-z0-9_]*$'),
  description text not null,
  created_at timestamptz not null default now()
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table public.membership_roles (
  membership_id uuid not null references public.institution_memberships(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete restrict,
  assigned_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (membership_id, role_id)
);

create index institution_memberships_user_status_idx
  on public.institution_memberships (user_id, status, institution_id);
create index institution_memberships_invited_by_idx
  on public.institution_memberships (invited_by)
  where invited_by is not null;
create index membership_roles_role_idx
  on public.membership_roles (role_id);
create index membership_roles_assigned_by_idx
  on public.membership_roles (assigned_by)
  where assigned_by is not null;
create index role_permissions_permission_idx
  on public.role_permissions (permission_id, role_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_updated_at()
  from public, anon, authenticated, service_role;
grant execute on function public.set_updated_at()
  to authenticated, service_role;

create trigger institutions_set_updated_at
before update on public.institutions
for each row execute function public.set_updated_at();
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
create trigger memberships_set_updated_at
before update on public.institution_memberships
for each row execute function public.set_updated_at();

create or replace function private.has_password_authentication()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from jsonb_array_elements(
      case
        when jsonb_typeof(auth.jwt() -> 'amr') = 'array'
          then auth.jwt() -> 'amr'
        else '[]'::jsonb
      end
    ) as authentication_method
    where authentication_method ->> 'method' = 'password'
  );
$$;

create or replace function private.is_active_member(target_institution_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.has_password_authentication()
  and exists (
    select 1
    from public.institution_memberships membership
    join public.institutions institution_record
      on institution_record.id = membership.institution_id
      and institution_record.is_active
    where membership.institution_id = target_institution_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
  );
$$;

create or replace function private.has_permission(
  target_institution_id uuid,
  permission_key text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.has_password_authentication()
  and exists (
    select 1
    from public.institution_memberships membership
    join public.institutions institution_record
      on institution_record.id = membership.institution_id
      and institution_record.is_active
    join public.membership_roles membership_role
      on membership_role.membership_id = membership.id
    join public.role_permissions role_permission
      on role_permission.role_id = membership_role.role_id
    join public.permissions permission_record
      on permission_record.id = role_permission.permission_id
    where membership.institution_id = target_institution_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
      and permission_record.key = permission_key
  );
$$;

revoke all on function private.has_password_authentication()
  from public, anon, authenticated, service_role;
revoke all on function private.is_active_member(uuid)
  from public, anon, authenticated, service_role;
revoke all on function private.has_permission(uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function private.has_password_authentication() to authenticated;
grant execute on function private.is_active_member(uuid) to authenticated;
grant execute on function private.has_permission(uuid, text) to authenticated;

alter table public.institutions enable row level security;
alter table public.profiles enable row level security;
alter table public.institution_memberships enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.membership_roles enable row level security;

create policy institutions_read_active_member
on public.institutions for select to authenticated
using (private.is_active_member(id));

create policy profiles_read_self
on public.profiles for select to authenticated
using (
  private.has_password_authentication()
  and user_id = (select auth.uid())
);
create policy profiles_update_self
on public.profiles for update to authenticated
using (
  private.has_password_authentication()
  and user_id = (select auth.uid())
)
with check (
  private.has_password_authentication()
  and user_id = (select auth.uid())
);

create policy memberships_read_self
on public.institution_memberships for select to authenticated
using (
  private.has_password_authentication()
  and user_id = (select auth.uid())
);

create policy roles_read_authenticated
on public.roles for select to authenticated
using (private.has_password_authentication());
create policy permissions_read_authenticated
on public.permissions for select to authenticated
using (private.has_password_authentication());
create policy role_permissions_read_authenticated
on public.role_permissions for select to authenticated
using (private.has_password_authentication());

create policy membership_roles_read_own
on public.membership_roles for select to authenticated
using (
  exists (
    select 1 from public.institution_memberships membership
    where membership.id = membership_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
      and private.is_active_member(membership.institution_id)
  )
);

insert into public.roles (key, label) values
  ('platform_administrator', 'Platform administrator'),
  ('institution_administrator', 'Institution administrator'),
  ('department_administrator', 'Department administrator'),
  ('faculty', 'Faculty'),
  ('mentor', 'Mentor'),
  ('placement_officer', 'Placement officer'),
  ('club_coordinator', 'Club coordinator'),
  ('student', 'Student');

insert into public.permissions (key, description) values
  ('institution_manage', 'Manage institution configuration'),
  ('academics_manage', 'Manage authorized academic structures'),
  ('roster_read', 'Read an authorized course roster'),
  ('attendance_record', 'Record attendance for assigned courses'),
  ('attendance_read_own', 'Read personal attendance'),
  ('announcements_publish', 'Publish to an authorized audience'),
  ('events_manage', 'Manage assigned events'),
  ('mentorship_manage', 'Manage assigned mentees'),
  ('opportunities_manage', 'Manage career opportunities'),
  ('clubs_manage', 'Manage assigned clubs'),
  ('audit_read', 'Read authorized audit events');

insert into public.role_permissions (role_id, permission_id)
select role_record.id, permission_record.id
from (
  values
    ('student', 'attendance_read_own'),
    ('faculty', 'roster_read'),
    ('faculty', 'attendance_record')
) as mapping(role_key, permission_key)
join public.roles role_record
  on role_record.key = mapping.role_key
join public.permissions permission_record
  on permission_record.key = mapping.permission_key;

revoke all on table
  public.institutions,
  public.profiles,
  public.institution_memberships,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.membership_roles
from anon, authenticated, service_role;

grant select on table
  public.institutions,
  public.profiles,
  public.institution_memberships,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.membership_roles
to authenticated;

grant update (display_name, avatar_path)
on public.profiles
to authenticated;

grant select, insert, update, delete on table
  public.institutions,
  public.profiles,
  public.institution_memberships,
  public.roles,
  public.permissions,
  public.role_permissions,
  public.membership_roles
to service_role;

commit;
