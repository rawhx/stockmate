# Products with Supabase

The default application now uses `ProductRemoteDataSource` for products. The
repository can still accept `ProductMockDataSource` in tests through
`AppProviders(productRepository: ...)`.

## Existing database contract

This integration targets the Supabase schema already configured for this project:

- `products`: UUID `id`, UUID `owner_id` (default `auth.uid()`), `code`, `name`,
  numeric `price`, `unit`, UUID `category_id`, nullable UUID `supplier_id`, and
  integer `minimum_stock`.
- `categories` and `suppliers`: UUID `id`, UUID `owner_id`, and `name`.
- `product_stock_summary`: the product columns above plus integer `current_stock`,
  computed by summing IN quantities and subtracting OUT quantities. The view must
  use `security_invoker=true`.
- RLS on the source tables allows authenticated users to read/write only rows
  whose `owner_id` matches `auth.uid()`. The stock transactions table also needs
  the corresponding per-owner SELECT policy for the view to calculate stock.
- Product references must belong to the same owner. The data source validates
  the selected category and supplier before writing; the database should also
  enforce this with composite owner/ID foreign keys.
- The composite foreign key from `stock_transactions(product_id, owner_id)` to
  `products(id, owner_id)` uses `ON DELETE RESTRICT` to retain transaction history.

`supabase/migrations/20261117000100_restrict_product_delete.sql` records the FK
change already applied through the SQL Editor. It is an incremental migration
for the existing database, not a complete schema bootstrap.

## Product behavior

- List and detail read from the stock summary view; category/supplier names are
  read from the owner's corresponding tables. List requests page through the
  API, and reference lookups use bounded batches.
- The product form selects actual category/supplier UUIDs. At least one category
  must exist for the logged-in account. Category/supplier management screens
  remain separate features and are not migrated by this change.
- Create inserts metadata only, with server-generated product ID and zero stock.
  Current stock is read-only in the form. Opening balances and stock movements
  belong to the stock-transactions integration.
- Update writes metadata only; supplier can be removed. An outdated stock value
  prompts the user to reload rather than pretending to update calculated stock.
- Delete verifies that one owned row was deleted. FK, duplicate-code, and access
  errors receive useful messages.
- Product caches and pending results are invalidated when the account changes.
  The router returns to the product list so another user's detail/form is closed.
- The stock-transactions feature still uses mock data. In the default Supabase
  wiring its mutation callbacks are blocked, so demo transactions cannot report
  a successful synchronization with live products. Injected mock repositories
  retain the existing isolated test/demo behavior.

## Verify

```sh
flutter pub get
flutter analyze
flutter test test/features/products test/app test/widget_test.dart
flutter run -d chrome --dart-define-from-file=.env.dev.json
```

Automated data-source tests use the actual Supabase SDK with intercepted HTTP
requests. They verify request payloads, account filters, null suppliers,
pagination, write failures, and session changes. They do not prove deployed RLS
policies or triggers. A live authenticated smoke test should cover two different
accounts, a product with no supplier, edit/clear supplier, and a restricted delete
against a product with transaction history.

## Existing unrelated test failures

Before this product integration, 17 cases in
`test/features/stock_transactions/presentation/providers/stock_transaction_sync_test.dart`
already failed against the stock feature merged into `develop`. Those failures
remain outside this product-only change. The stock implementation and that
regression test file have been preserved; do not interpret a full-suite failure
there as an authenticated Supabase product test.
