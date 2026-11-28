import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';

import '../../domain/entities/stock_transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/stock_transaction_provider.dart';

class StockTransactionFormPage extends StatefulWidget {
  const StockTransactionFormPage({this.transactionId, super.key});

  final String? transactionId;

  bool get isEditing => transactionId != null;

  @override
  State<StockTransactionFormPage> createState() =>
      _StockTransactionFormPageState();
}

class _StockTransactionFormPageState extends State<StockTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  Product? _selectedProduct;
  TransactionType _selectedType = TransactionType.inStock;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isInit = true;
  bool _isLoading = true;
  String? _loadError;
  StockTransaction? _existingTransaction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      _initializeFormData();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeFormData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _existingTransaction = null;
    });
    final productProvider = context.read<ProductProvider>();
    final txProvider = context.read<StockTransactionProvider>();

    if (productProvider.products.isEmpty) {
      await productProvider.fetchProducts();
    }
    if (!mounted) return;

    if (widget.isEditing) {
      final tx = await txProvider.getTransactionById(widget.transactionId!);
      if (!mounted) return;
      if (tx == null) {
        setState(() {
          _loadError = txProvider.errorMessage ?? 'Transaksi tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }
      _existingTransaction = tx;

      _selectedType = tx.type;
      _quantityController.text = tx.quantity.toString();
      _notesController.text = tx.notes ?? '';
      _selectedDate = tx.date;
      _selectedProduct = productProvider.products
          .where((product) => product.id == tx.productId)
          .firstOrNull;
      setState(() => _isLoading = false);
    } else {
      final products = productProvider.products;
      setState(() {
        _selectedProduct ??= products.firstOrNull;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      final time = TimeOfDay.fromDateTime(_selectedDate);
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }

  int get _enteredQuantity {
    final text = _quantityController.text.trim();
    return int.tryParse(text) ?? 0;
  }

  int? get _simulatedNewStock {
    final selected = _selectedProduct;
    if (selected == null) return null;
    final previous = _existingTransaction;
    final previousQuantity = previous?.productId == selected.id
        ? previous!.signedQuantity
        : 0;
    final nextQuantity = _selectedType.isIn ? _enteredQuantity : -_enteredQuantity;
    return selected.currentStock - previousQuantity + nextQuantity;
  }

  bool get _isStockExceeded {
    final simulated = _simulatedNewStock;
    return simulated != null && simulated < 0;
  }

  Future<void> _handleSubmit() async {
    if (_isLoading || _formKey.currentState?.validate() != true) return;
    final existing = _existingTransaction;
    if (widget.isEditing && existing == null) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih barang terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<StockTransactionProvider>();
    final notes = _notesController.text.trim();
    final quantity = _enteredQuantity;

    bool success;
    if (widget.isEditing) {
      final updated = existing!.copyWith(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        productCode: _selectedProduct!.code,
        type: _selectedType,
        quantity: quantity,
        date: _selectedDate,
        notes: notes.isEmpty ? null : notes,
        clearNotes: notes.isEmpty,
      );
      success = await provider.editTransaction(updated);
    } else {
      final newTx = StockTransaction(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        productCode: _selectedProduct!.code,
        type: _selectedType,
        quantity: quantity,
        date: _selectedDate,
        notes: notes.isEmpty ? null : notes,
        createdAt: DateTime.now(),
      );
      success = await provider.addTransaction(newTx);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Transaksi berhasil diperbarui dan stok telah disesuaikan!'
                : 'Transaksi berhasil dicatat dan stok telah disesuaikan!',
          ),
          backgroundColor: const Color(0xFF2E7D32),
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
          content: Text(provider.errorMessage ?? 'Gagal menyimpan transaksi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Transaksi Stok' : 'Catat Transaksi Stok',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _initializeFormData,
                        child: const Text('Coba lagi'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/stock-transactions'),
                        child: const Text('Kembali'),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withAlpha(100),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Transaksi',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  // Dropdown Pilihan Barang
                                  Text(
                                    'Pilih Barang',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<Product>(
                                    initialValue:
                                        _selectedProduct != null &&
                                            products.any(
                                              (p) =>
                                                  p.id == _selectedProduct!.id,
                                            )
                                        ? products.firstWhere(
                                            (p) => p.id == _selectedProduct!.id,
                                          )
                                        : null,
                                    decoration: InputDecoration(
                                      hintText: 'Pilih barang inventaris',
                                      prefixIcon: const Icon(
                                        Icons.inventory_2_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: products.map((product) {
                                      return DropdownMenuItem<Product>(
                                        value: product,
                                        child: Text(
                                          '${product.name} (${product.code}) - Stok: ${product.currentStock} ${product.unit}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (product) {
                                      setState(() {
                                        _selectedProduct = product;
                                      });
                                    },
                                    validator: (val) {
                                      if (val == null) {
                                        return 'Barang wajib dipilih';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Pilihan Jenis Transaksi
                                  Text(
                                    'Jenis Transaksi',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<TransactionType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: TransactionType.inStock,
                                        label: Text('Stok Masuk (+)'),
                                        icon: Icon(
                                          Icons.arrow_downward_rounded,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: TransactionType.outStock,
                                        label: Text('Stok Keluar (-)'),
                                        icon: Icon(
                                          Icons.arrow_upward_rounded,
                                          color: Color(0xFFC62828),
                                        ),
                                      ),
                                    ],
                                    selected: {_selectedType},
                                    onSelectionChanged: (set) {
                                      setState(() {
                                        _selectedType = set.first;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Jumlah Barang
                                  Text(
                                    'Jumlah Barang',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan kuantitas',
                                      prefixIcon: const Icon(
                                        Icons.numbers_outlined,
                                      ),
                                      suffixText:
                                          _selectedProduct?.unit ?? 'unit',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Jumlah barang wajib diisi';
                                      }
                                      final number = int.tryParse(val.trim());
                                      if (number == null || number <= 0) {
                                        return 'Jumlah harus berupa angka lebih dari 0';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Live Stock Preview & Validation Indicator
                                  if (_selectedProduct != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _isStockExceeded
                                            ? const Color(0xFFFFEBEE)
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withAlpha(120),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isStockExceeded
                                              ? const Color(0xFFE57373)
                                              : theme.colorScheme.outlineVariant
                                                    .withAlpha(100),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Stok Tersedia Saat Ini:',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              Text(
                                                '${_selectedProduct!.currentStock} ${_selectedProduct!.unit}',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Prediksi Setelah Transaksi:',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              Text(
                                                '${_simulatedNewStock ?? _selectedProduct!.currentStock} ${_selectedProduct!.unit}',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _isStockExceeded
                                                          ? const Color(
                                                              0xFFC62828,
                                                            )
                                                          : const Color(
                                                              0xFF2E7D32,
                                                            ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (_isStockExceeded) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 16,
                                                  color: Color(0xFFC62828),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Peringatan: Jumlah keluar melebihi stok yang tersedia!',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: const Color(
                                                            0xFFC62828,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  // Tanggal Transaksi
                                  Text(
                                    'Tanggal Transaksi',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _pickDate,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.arrow_drop_down,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(_formatDate(_selectedDate)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Keterangan / Catatan
                                  Text(
                                    'Keterangan / Catatan (Opsional)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Contoh: Pengadaan batch 1, Retur barang, Penjualan grosir...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('submit_transaction_button'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleSubmit,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              widget.isEditing
                                  ? 'Simpan Perubahan'
                                  : 'Simpan Transaksi',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
