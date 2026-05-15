create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  github_id text unique not null,
  github_username text not null,
  display_name text not null,
  avatar_url text not null default '',
  email text,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  is_banned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) >= 5),
  description text not null check (char_length(description) >= 20),
  post_type text not null check (post_type in ('found', 'lost', 'stolen')),
  item_type text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'returned', 'closed', 'rejected')),
  city text not null,
  area text not null default '',
  location_text text not null default '',
  latitude double precision,
  longitude double precision,
  event_date date not null,
  contact_phone text,
  contact_email text,
  allow_contact_public boolean not null default false,
  needs_verification boolean not null default true,
  views_count integer not null default 0,
  is_urgent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  image_url text not null,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_one_id uuid not null references public.profiles(id) on delete cascade,
  user_two_id uuid not null references public.profiles(id) on delete cascade,
  last_message text,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (user_one_id <> user_two_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  message text not null default '',
  image_url text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.saved_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete cascade,
  reason text not null,
  description text,
  status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  check (post_id is not null or reported_user_id is not null)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (
    type in (
      'new_message',
      'post_approved',
      'post_rejected',
      'post_returned',
      'similar_item',
      'admin_notice'
    )
  ),
  related_post_id uuid references public.posts(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name_ku text not null unique,
  icon text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index if not exists conversations_unique_pair
on public.conversations (
  post_id,
  least(user_one_id, user_two_id),
  greatest(user_one_id, user_two_id)
);

create index if not exists posts_status_created_idx on public.posts(status, created_at desc);
create index if not exists posts_city_type_idx on public.posts(city, item_type, post_type);
create index if not exists posts_title_trgm_idx on public.posts using gin (title gin_trgm_ops);
create index if not exists posts_description_trgm_idx on public.posts using gin (description gin_trgm_ops);
create index if not exists post_images_post_idx on public.post_images(post_id, sort_order);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id, created_at);
create index if not exists messages_sender_created_idx on public.messages(sender_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index if not exists reports_status_created_idx on public.reports(status, created_at desc);

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists posts_touch_updated_at on public.posts;
create trigger posts_touch_updated_at
before update on public.posts
for each row execute function public.touch_updated_at();

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.profiles where auth_user_id = auth.uid() limit 1
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where auth_user_id = auth.uid() limit 1), 'user')
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_role() in ('admin', 'moderator')
$$;

create or replace function public.is_not_banned()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select not is_banned from public.profiles where auth_user_id = auth.uid() limit 1),
    false
  )
$$;

create or replace function public.can_send_message()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (
    select count(*)
    from public.messages
    where sender_id = public.current_profile_id()
      and created_at >= now() - interval '1 hour'
  ) < 20
$$;

create or replace function public.can_create_post()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (
    select count(*)
    from public.posts
    where user_id = public.current_profile_id()
      and created_at >= date_trunc('day', now())
  ) < 10
$$;

create or replace function public.increment_post_views(post_id_input uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts
  set views_count = views_count + 1
  where id = post_id_input
    and (
      status in ('approved', 'returned')
      or user_id = public.current_profile_id()
      or public.is_admin()
    );
end;
$$;

create or replace function public.prevent_self_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin()
    and old.status <> 'approved'
    and new.status = 'approved' then
    raise exception 'Only admins can approve posts';
  end if;
  return new;
end;
$$;

drop trigger if exists posts_prevent_self_approval on public.posts;
create trigger posts_prevent_self_approval
before update on public.posts
for each row execute function public.prevent_self_approval();

create or replace function public.prevent_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin()
    and (
      new.role <> old.role
      or new.is_banned <> old.is_banned
      or new.auth_user_id <> old.auth_user_id
    ) then
    raise exception 'Only admins can change protected profile fields';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_privilege_escalation on public.profiles;
create trigger profiles_prevent_privilege_escalation
before update on public.profiles
for each row execute function public.prevent_profile_privilege_escalation();

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_images enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.saved_posts enable row level security;
alter table public.reports enable row level security;
alter table public.notifications enable row level security;
alter table public.categories enable row level security;

revoke select on public.profiles from anon, authenticated;
grant select (
  id,
  auth_user_id,
  github_id,
  github_username,
  display_name,
  avatar_url,
  role,
  is_banned,
  created_at,
  updated_at
) on public.profiles to authenticated;

create policy profiles_select_authenticated
on public.profiles for select
to authenticated
using (auth_user_id = auth.uid() or public.is_admin() or not is_banned);

create policy profiles_insert_own
on public.profiles for insert
to authenticated
with check (auth_user_id = auth.uid() and role = 'user' and is_banned = false);

create policy profiles_update_own
on public.profiles for update
to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

create policy profiles_admin_all
on public.profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy posts_public_read_approved
on public.posts for select
to anon, authenticated
using (status in ('approved', 'returned'));

create policy posts_owner_read
on public.posts for select
to authenticated
using (user_id = public.current_profile_id() or public.is_admin());

create policy posts_insert_authenticated
on public.posts for insert
to authenticated
with check (
  user_id = public.current_profile_id()
  and status = 'pending'
  and public.is_not_banned()
  and public.can_create_post()
);

create policy posts_update_owner
on public.posts for update
to authenticated
using (user_id = public.current_profile_id() and public.is_not_banned())
with check (
  user_id = public.current_profile_id()
  and status in ('pending', 'approved', 'returned', 'closed')
);

create policy posts_admin_all
on public.posts for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy posts_delete_owner
on public.posts for delete
to authenticated
using (user_id = public.current_profile_id() or public.is_admin());

create policy post_images_select_visible
on public.post_images for select
to anon, authenticated
using (
  exists (
    select 1 from public.posts p
    where p.id = post_id
      and (
        p.status in ('approved', 'returned')
        or p.user_id = public.current_profile_id()
        or public.is_admin()
      )
  )
);

create policy post_images_insert_owner
on public.post_images for insert
to authenticated
with check (
  public.is_not_banned()
  and exists (
    select 1 from public.posts p
    where p.id = post_id and p.user_id = public.current_profile_id()
  )
);

create policy post_images_delete_owner
on public.post_images for delete
to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.posts p
    where p.id = post_id and p.user_id = public.current_profile_id()
  )
);

create policy conversations_participant_read
on public.conversations for select
to authenticated
using (
  public.is_admin()
  or user_one_id = public.current_profile_id()
  or user_two_id = public.current_profile_id()
);

create policy conversations_participant_insert
on public.conversations for insert
to authenticated
with check (
  public.is_not_banned()
  and (
    user_one_id = public.current_profile_id()
    or user_two_id = public.current_profile_id()
  )
);

create policy conversations_participant_update
on public.conversations for update
to authenticated
using (
  user_one_id = public.current_profile_id()
  or user_two_id = public.current_profile_id()
  or public.is_admin()
)
with check (
  user_one_id = public.current_profile_id()
  or user_two_id = public.current_profile_id()
  or public.is_admin()
);

create policy messages_participant_read
on public.messages for select
to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and (
        c.user_one_id = public.current_profile_id()
        or c.user_two_id = public.current_profile_id()
      )
  )
);

create policy messages_participant_insert
on public.messages for insert
to authenticated
with check (
  sender_id = public.current_profile_id()
  and public.is_not_banned()
  and public.can_send_message()
  and exists (
    select 1 from public.conversations c
    where c.id = conversation_id
      and c.post_id = post_id
      and (
        (c.user_one_id = sender_id and c.user_two_id = receiver_id)
        or (c.user_two_id = sender_id and c.user_one_id = receiver_id)
      )
  )
);

create policy messages_receiver_mark_read
on public.messages for update
to authenticated
using (receiver_id = public.current_profile_id())
with check (receiver_id = public.current_profile_id());

create policy saved_posts_owner_all
on public.saved_posts for all
to authenticated
using (user_id = public.current_profile_id())
with check (user_id = public.current_profile_id());

create policy reports_insert_authenticated
on public.reports for insert
to authenticated
with check (reporter_id = public.current_profile_id() and public.is_not_banned());

create policy reports_owner_or_admin_read
on public.reports for select
to authenticated
using (reporter_id = public.current_profile_id() or public.is_admin());

create policy reports_admin_update
on public.reports for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy notifications_owner_read
on public.notifications for select
to authenticated
using (user_id = public.current_profile_id() or public.is_admin());

create policy notifications_owner_update
on public.notifications for update
to authenticated
using (user_id = public.current_profile_id())
with check (user_id = public.current_profile_id());

create policy notifications_admin_insert
on public.notifications for insert
to authenticated
with check (public.is_admin());

create policy notifications_system_insert_for_participants
on public.notifications for insert
to authenticated
with check (
  user_id = public.current_profile_id()
  or exists (
    select 1 from public.conversations c
    where (c.user_one_id = public.current_profile_id() or c.user_two_id = public.current_profile_id())
      and (c.user_one_id = user_id or c.user_two_id = user_id)
  )
);

create policy categories_public_read
on public.categories for select
to anon, authenticated
using (is_active);

create policy categories_admin_all
on public.categories for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

insert into public.categories (name_ku, icon) values
  ('مۆبایل', 'phone_iphone'),
  ('پارەدان', 'account_balance_wallet'),
  ('ناسنامە', 'badge'),
  ('ئۆتۆمبێل', 'directions_car'),
  ('کلیل', 'key'),
  ('جانتا', 'work'),
  ('کاڵای ئەلیکترۆنی', 'devices'),
  ('بەڵگەنامە', 'description'),
  ('پۆشاک', 'checkroom'),
  ('ئاژەڵ', 'pets'),
  ('شتی تر', 'category')
on conflict (name_ku) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-images',
  'post-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy post_images_storage_public_read
on storage.objects for select
to anon, authenticated
using (bucket_id = 'post-images');

create policy post_images_storage_authenticated_upload
on storage.objects for insert
to authenticated
with check (bucket_id = 'post-images' and public.is_not_banned());

create policy post_images_storage_owner_delete
on storage.objects for delete
to authenticated
using (bucket_id = 'post-images' and (owner = auth.uid() or public.is_admin()));
