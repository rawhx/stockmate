import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/stock_transaction.dart';
import '../providers/stock_transaction_provider.dart';
import '../widgets/transaction_type_badge.dart';

class StockTransactionDetailPage extends StatefulWidget {
  const StockTransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<StockTransactionDetailPage> createState() =>
      _StockTransactionDetailPageState();
}

class _StockTransactionDetailPageState
    extends State<StockTransactionDetailPage> {
  StockTransaction? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<StockTransactionProvider>();
    final tx = await provider.getTransactionById(widget.transactionId);

    if (!mounted) return;
    setState(() {
      _transaction = tx;
      _isLoading = false;
      if (tx == null) {
        _error = 'Transaksi tidak ditemukan';
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  Future<void> _confirmDelete(StockTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus catatan transaksi ${tx.type.label.toLowerCase()} '
            'ini? Stok produk terkait akan disesuaikan kembali.',
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
          content: Text('Transaksi berhasil dihapus dan stok disesuaikan.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/stock-transactions');
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi Stok'),
        actions: [
          if (_transaction != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Transaksi',
              onPressed: () async {
                await context.push(
                  '/stock-transactions/${_transaction!.id}/edit',
                );
                if (mounted) _loadDetails();
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Hapus Transaksi',
              onPressed: () => _confirmDelete(_transaction!),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.go('/stock-transactions'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Kembali ke Riwayat'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                100,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _transaction!.productName,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    TransactionTypeBadge(
                                      type: _transaction!.type,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kode Barang: ${_transaction!.productCode}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Divider(height: 32),
                                _buildDetailRow(
                                  context,
                                  icon: Icons.numbers_rounded,
                                  label: 'Jumlah Barang',
                                  value:
                                      '${_transaction!.type.isOut ? '-' : '+'}${_transaction!.quantity} Unit',
                                  valueColor: _transaction!.type.isOut
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF2E7D32),
                                  valueBold: true,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  context,
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Tanggal Transaksi',
                                  value: _formatDateTime(_transaction!.date),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  context,
                                  icon: Icons.notes_outlined,
                                  label: 'Keterangan / Catatan',
                                  value:
                                      (_transaction!.notes != null &&
                                          _transaction!.notes!.isNotEmpty)
                                      ? _transaction!.notes!
                                      : 'Tidak ada catatan tambahan',
                                  isItalic:
                                      _transaction!.notes == null ||
                                      _transaction!.notes!.isEmpty,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  context,
                                  icon: Icons.history_outlined,
                                  label: 'Waktu Dibuat',
                                  value: _formatDateTime(
                                    _transaction!.createdAt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await context.push(
                                    '/stock-transactions/${_transaction!.id}/edit',
                                  );
                                  if (mounted) _loadDetails();
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Transaksi'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                ),
                                onPressed: () => _confirmDelete(_transaction!),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Hapus Transaksi'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
    bool isItalic = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
