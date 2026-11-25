-- Migration: create stock_transactions table with RLS and composite FK
begin;

create table if not exists public.stock_transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id uuid not null,
  type text not null check (type in ('IN', 'OUT')),
  quantity integer not null check (quantity > 0),
  date timestamp with time zone not null default now(),
  notes text,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint stock_transactions_product_id_owner_id_fkey
    foreign key (product_id, owner_id)
    references public.products (id, owner_id)
    on delete restrict
);

-- Enable Row Level Security (RLS)
alter table public.stock_transactions enable row level security;

-- Policies for owner access
create policy "Users can view their own stock transactions"
  on public.stock_transactions for select
  using (auth.uid() = owner_id);

create policy "Users can insert their own stock transactions"
  on public.stock_transactions for insert
  with check (auth.uid() = owner_id);

create policy "Users can update their own stock transactions"
  on public.stock_transactions for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "Users can delete their own stock transactions"
  on public.stock_transactions for delete
  using (auth.uid() = owner_id);

-- Helpful indexes for querying transactions by owner and date
create index if not exists stock_transactions_owner_date_idx
  on public.stock_transactions (owner_id, date desc);

create index if not exists stock_transactions_product_owner_idx
  on public.stock_transactions (product_id, owner_id);

commit;
