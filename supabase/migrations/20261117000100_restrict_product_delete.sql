-- Preserve inventory history when deleting a product.
begin;

alter table public.stock_transactions
drop constraint stock_transactions_product_id_owner_id_fkey;

alter table public.stock_transactions
add constraint stock_transactions_product_id_owner_id_fkey
foreign key (product_id, owner_id)
references public.products (id, owner_id)
on delete restrict;

commit;
