-- Admin MVP schema for AR historical objects.
-- Run this file in the Supabase SQL editor, then seed the first admin user.

create extension if not exists pgcrypto;

create table if not exists public.admin_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'editor'
    check (role in ('owner', 'admin', 'editor')),
  display_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_archive_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_profiles
    where user_id = auth.uid()
      and is_active = true
      and role in ('owner', 'admin', 'editor')
  );
$$;

create or replace function public.is_archive_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_profiles
    where user_id = auth.uid()
      and is_active = true
      and role = 'owner'
  );
$$;

grant usage on schema public to anon, authenticated;
grant execute on function public.is_archive_admin() to anon, authenticated;
grant execute on function public.is_archive_owner() to anon, authenticated;

create table if not exists public.heritage_objects (
  id text primary key,
  name text not null,
  century text not null default '',
  architecture_type text not null default '',
  address text not null default '',
  years_of_existence text not null default '',
  sources text not null default '',
  short_description text not null default '',
  detailed_description text not null default '',
  cover_image_url text,
  cover_image_asset text,
  latitude double precision not null default 0,
  longitude double precision not null default 0,
  published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.heritage_epochs (
  id uuid primary key default gen_random_uuid(),
  object_id text not null references public.heritage_objects(id) on delete cascade,
  year text not null,
  label text not null default '',
  description text not null default '',
  panorama_url text,
  panorama_asset_path text,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists heritage_epochs_object_year_key
on public.heritage_epochs (object_id, year);

create table if not exists public.heritage_ar_assets (
  id uuid primary key default gen_random_uuid(),
  object_id text not null references public.heritage_objects(id) on delete cascade,
  title text not null default '',
  epoch_year text,
  glb_url text,
  usdz_url text,
  glb_asset_path text,
  usdz_asset_path text,
  scale numeric not null default 1,
  placement text not null default 'plane',
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.heritage_ar_assets
add column if not exists epoch_year text;

create unique index if not exists heritage_ar_assets_object_title_key
on public.heritage_ar_assets (object_id, title);

create index if not exists heritage_ar_assets_object_epoch_year_idx
on public.heritage_ar_assets (object_id, epoch_year);

alter table public.admin_profiles enable row level security;
alter table public.heritage_objects enable row level security;
alter table public.heritage_epochs enable row level security;
alter table public.heritage_ar_assets enable row level security;

grant select on public.admin_profiles to authenticated;
grant insert, update, delete on public.admin_profiles to authenticated;

grant select on public.heritage_objects to anon, authenticated;
grant insert, update, delete on public.heritage_objects to authenticated;

grant select on public.heritage_epochs to anon, authenticated;
grant insert, update, delete on public.heritage_epochs to authenticated;

grant select on public.heritage_ar_assets to anon, authenticated;
grant insert, update, delete on public.heritage_ar_assets to authenticated;

drop policy if exists "admins can read admin profiles" on public.admin_profiles;
create policy "admins can read admin profiles"
on public.admin_profiles for select
using (user_id = auth.uid() or public.is_archive_owner());

drop policy if exists "owners can manage admin profiles" on public.admin_profiles;
create policy "owners can manage admin profiles"
on public.admin_profiles for all
using (public.is_archive_owner())
with check (public.is_archive_owner());

drop policy if exists "published objects are readable" on public.heritage_objects;
create policy "published objects are readable"
on public.heritage_objects for select
using (published = true or public.is_archive_admin());

drop policy if exists "admins can manage objects" on public.heritage_objects;
create policy "admins can manage objects"
on public.heritage_objects for all
using (public.is_archive_admin())
with check (public.is_archive_admin());

drop policy if exists "published epochs are readable" on public.heritage_epochs;
create policy "published epochs are readable"
on public.heritage_epochs for select
using (published = true or public.is_archive_admin());

drop policy if exists "admins can manage epochs" on public.heritage_epochs;
create policy "admins can manage epochs"
on public.heritage_epochs for all
using (public.is_archive_admin())
with check (public.is_archive_admin());

drop policy if exists "published ar assets are readable" on public.heritage_ar_assets;
create policy "published ar assets are readable"
on public.heritage_ar_assets for select
using (published = true or public.is_archive_admin());

drop policy if exists "admins can manage ar assets" on public.heritage_ar_assets;
create policy "admins can manage ar assets"
on public.heritage_ar_assets for all
using (public.is_archive_admin())
with check (public.is_archive_admin());

insert into storage.buckets (id, name, public)
values ('archive-media', 'archive-media', true)
on conflict (id) do nothing;

drop policy if exists "archive media is publicly readable" on storage.objects;
create policy "archive media is publicly readable"
on storage.objects for select
using (bucket_id = 'archive-media');

drop policy if exists "admins can manage archive media" on storage.objects;
create policy "admins can manage archive media"
on storage.objects for all
using (bucket_id = 'archive-media' and public.is_archive_admin())
with check (bucket_id = 'archive-media' and public.is_archive_admin());

-- Seed first admin after the user has registered/logged in at least once:
-- insert into public.admin_profiles (user_id, role, display_name)
-- select id, 'owner', 'Owner'
-- from auth.users
-- where email = 'admin@example.com'
-- on conflict (user_id) do update set role = excluded.role, is_active = true;
