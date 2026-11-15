-- Supabase Dashboard > SQL Editor me ye poora run karo

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text default '',
  phone text,
  avatar_url text,
  created_at timestamptz default now()
);

create table public.messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (length(content) > 0),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index on public.messages (sender_id, created_at desc);
create index on public.messages (receiver_id, created_at desc);

-- Naya user aate hi profile ban jaye (Google ya phone dono se)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, phone, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    nullif(new.phone, ''),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.messages enable row level security;

create policy "profiles readable by logged-in users"
  on public.profiles for select to authenticated using (true);
create policy "update own profile"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "read own messages"
  on public.messages for select to authenticated
  using (auth.uid() in (sender_id, receiver_id));
create policy "send as self"
  on public.messages for insert to authenticated
  with check (sender_id = auth.uid());
create policy "receiver marks read"
  on public.messages for update to authenticated
  using (receiver_id = auth.uid()) with check (receiver_id = auth.uid());

-- Realtime on
alter publication supabase_realtime add table public.messages;
