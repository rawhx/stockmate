-- Run after the StockMate migrations, using a disposable database.
begin;

do $$
declare
  account_id uuid := gen_random_uuid();
  category_id uuid := gen_random_uuid();
  product_a uuid := gen_random_uuid();
  product_b uuid := gen_random_uuid();
  receipt_id uuid;
  shipment_id uuid;
  rejection text;
begin
  insert into auth.users (id) values (account_id);
  insert into public.categories (id, owner_id, name)
    values (category_id, account_id, 'Stock guard test');
  insert into public.products (id, owner_id, category_id, code, name, price, unit, minimum_stock)
    values
      (product_a, account_id, category_id, 'TEST-A', 'Product A', 1, 'pcs', 0),
      (product_b, account_id, category_id, 'TEST-B', 'Product B', 1, 'pcs', 0);

  insert into public.stock_transactions (owner_id, product_id, type, quantity)
    values (account_id, product_a, 'IN', 10)
    returning id into receipt_id;
  insert into public.stock_transactions (owner_id, product_id, type, quantity)
    values (account_id, product_a, 'OUT', 8)
    returning id into shipment_id;
  insert into public.stock_transactions (owner_id, product_id, type, quantity)
    values (account_id, product_b, 'IN', 2);

  begin
    update public.stock_transactions set product_id = product_b where id = shipment_id;
    raise exception 'A transfer allowed the destination balance to go negative';
  exception when check_violation then
    get stacked diagnostics rejection = constraint_name;
    if rejection <> 'stock_transactions_nonnegative_balance' then raise; end if;
  end;

  begin
    update public.stock_transactions set product_id = product_b where id = receipt_id;
    raise exception 'A transfer allowed the source balance to go negative';
  exception when check_violation then
    get stacked diagnostics rejection = constraint_name;
    if rejection <> 'stock_transactions_nonnegative_balance' then raise; end if;
  end;

  begin
    delete from public.stock_transactions where id = receipt_id;
    raise exception 'A deletion allowed stock that has been used to disappear';
  exception when check_violation then
    get stacked diagnostics rejection = constraint_name;
    if rejection <> 'stock_transactions_nonnegative_balance' then raise; end if;
  end;

  -- Moving fewer units is valid and leaves zero stock on the destination.
  update public.stock_transactions
    set product_id = product_b, quantity = 2, note = 'Test note'
    where id = shipment_id;
  update public.stock_transactions set note = null where id = shipment_id;
  if not exists (
    select 1 from public.stock_transactions
    where id = shipment_id and product_id = product_b and quantity = 2 and note is null
  ) then
    raise exception 'The valid move or note clear did not persist';
  end if;
end;
$$;

rollback;
