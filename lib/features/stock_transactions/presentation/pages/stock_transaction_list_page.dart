import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/stock_transaction.dart';
import '../providers/stock_transaction_provider.dart';
import '../widgets/stock_transaction_card.dart';
import '../widgets/stock_transaction_summary.dart';

class StockTransactionListPage extends StatefulWidget {
  const StockTransactionListPage({super.key});

  @override
  State<StockTransactionListPage> createState() =>
      _StockTransactionListPageState();
}

class _StockTransactionListPageState extends State<StockTransactionListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StockTransactionProvider>().fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(StockTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus catatan transaksi ${tx.type.label.toLowerCase()} '
            'sebanyak ${tx.quantity} untuk "${tx.productName}"?\n\n'
            'Stok produk akan disesuaikan kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<StockTransactionProvider>();
    final success = await provider.removeTransaction(tx.id);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil dihapus dan stok telah disesuaikan.',
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menghapus transaksi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StockTransactionProvider>();
    final transactions = provider.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manajemen Transaksi Stok'),
            Text(
              'Riwayat pencatatan stok barang masuk dan keluar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: provider.fetchTransactions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_transaction_fab'),
        onPressed: () => context.push('/stock-transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat Transaksi'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchTransactions,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StockTransactionSummary(
                            totalCount: provider.transactions.length,
                            totalIn: provider.totalInStockCount,
                            totalOut: provider.totalOutStockCount,
                          ),
                          const SizedBox(height: 12),
                          // Kolom Pencarian
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari barang, kode, atau catatan...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        provider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: provider.setSearchQuery,
                          ),
                          const SizedBox(height: 8),
                          // Filter Chip Masuk / Keluar
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: const Text('Semua'),
                                  selected:
                                      provider.currentFilter ==
                                      TransactionFilter.all,
                                  onSelected: (_) =>
                                      provider.setFilter(TransactionFilter.all),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  avatar: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  label: const Text('Masuk'),
                                  selected:
                                      provider.currentFilter ==
                                      TransactionFilter.inStock,
                                  onSelected: (_) => provider.setFilter(
                                    TransactionFilter.inStock,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  avatar: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: Color(0xFFC62828),
                                  ),
                                  label: const Text('Keluar'),
                                  selected:
                                      provider.currentFilter ==
                                      TransactionFilter.outStock,
                                  onSelected: (_) => provider.setFilter(
                                    TransactionFilter.outStock,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (provider.isLoading && provider.transactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(
                              120,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Riwayat Transaksi',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Tidak ada transaksi yang cocok dengan kata kunci pencarian.'
                                : 'Klik tombol "Catat Transaksi" untuk menambahkan stok masuk atau keluar.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return StockTransactionCard(
                              transaction: tx,
                              onDetail: () =>
                                  context.push('/stock-transactions/${tx.id}'),
                              onEdit: () => context.push(
                                '/stock-transactions/${tx.id}/edit',
                              ),
                              onDelete: () => _confirmDelete(tx),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
