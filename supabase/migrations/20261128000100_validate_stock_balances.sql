begin;

create function public.validate_stock_transaction_balance()
returns trigger
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  previous_owner uuid;
  previous_product uuid;
  previous_delta bigint;
  next_owner uuid;
  next_product uuid;
  next_delta bigint;
  affected record;
  balance bigint;
begin
  if tg_op <> 'INSERT' then
    previous_owner := old.owner_id;
    previous_product := old.product_id;
    previous_delta := case old.type when 'IN' then -old.quantity::bigint
                                   else old.quantity::bigint end;
  end if;
  if tg_op <> 'DELETE' then
    next_owner := new.owner_id;
    next_product := new.product_id;
    next_delta := case new.type when 'IN' then new.quantity::bigint
                               else -new.quantity::bigint end;
  end if;

  -- An account deletion cascades through its entire ledger.
  if tg_op = 'DELETE' and not exists (
    select 1 from auth.users where id = previous_owner
  ) then
    return old;
  end if;

  -- The read after waiting for the lock needs a fresh snapshot.
  if current_setting('transaction_isolation') <> 'read committed' then
    raise exception using errcode = '25000',
      message = 'Stock transactions require READ COMMITTED isolation.';
  end if;

  -- Serialize changes per product. NO KEY UPDATE is compatible with the
  -- key-share lock taken by the composite foreign key.
  perform 1
  from public.products p
  where (p.owner_id, p.id) in (
    (previous_owner, previous_product), (next_owner, next_product)
  )
  order by p.owner_id, p.id
  for no key update;

  for affected in
    select changes.owner_id, changes.product_id, sum(changes.delta) as delta
    from (values
      (previous_owner, previous_product, previous_delta),
      (next_owner, next_product, next_delta)
    ) as changes(owner_id, product_id, delta)
    where changes.product_id is not null
    group by changes.owner_id, changes.product_id
    having sum(changes.delta) < 0
  loop
    select coalesce(sum(case when tx.type = 'IN' then tx.quantity::bigint
                            else -tx.quantity::bigint end), 0)
    into balance
    from public.stock_transactions tx
    where tx.owner_id = affected.owner_id
      and tx.product_id = affected.product_id;

    -- A nonnegative delta is allowed so existing deficits can be corrected.
    if balance + affected.delta < 0 then
      raise exception using errcode = '23514',
        constraint = 'stock_transactions_nonnegative_balance',
        message = 'Stok tidak mencukupi untuk menyimpan perubahan transaksi.';
    end if;
  end loop;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

revoke all on function public.validate_stock_transaction_balance()
from public, anon, authenticated;

create trigger validate_stock_transaction_balance
before insert or update or delete on public.stock_transactions
for each row execute function public.validate_stock_transaction_balance();

commit;
