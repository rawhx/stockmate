import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/suppliers/domain/entities/supplier.dart';
import 'package:stockmate/features/suppliers/presentation/pages/supplier_form_page.dart';
import 'package:stockmate/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:stockmate/features/suppliers/presentation/widgets/supplier_card.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  static const _staggerDelay = Duration(milliseconds: 80);
  static const _animationDuration = Duration(milliseconds: 420);

  late final SuppliersProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SuppliersProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.fetchSuppliers();
    });
  }

  void _showFailure(String fallback) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_provider.errorMessage ?? fallback)));
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute(builder: (_) => const SupplierFormPage()),
    );
    if (result == null || !mounted) return;
    final saved = await _provider.add(result);
    if (!saved) _showFailure('Gagal menambahkan supplier.');
  }

  Future<void> _openEdit(Supplier supplier) async {
    final result = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: supplier)),
    );
    if (result == null || !mounted) return;
    final saved = await _provider.update(result.copyWith(id: supplier.id));
    if (!saved) _showFailure('Gagal memperbarui supplier.');
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Supplier'),
          content: Text('Yakin ingin menghapus "${supplier.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final deleted = await _provider.delete(supplier.id);
    if (!deleted) _showFailure('Gagal menghapus supplier.');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Suppliers'), centerTitle: false),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: provider.isSaving ? null : _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Supplier'),
          ),
          body: SafeArea(child: _buildBody(context, provider)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SuppliersProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat supplier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(provider.errorMessage ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.fetchSuppliers,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada supplier',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tekan tombol "Tambah Supplier" untuk menambahkan',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.fetchSuppliers,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final supplier = provider.items[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
            child: _StaggeredFadeSlide(
              delay: Duration(
                milliseconds: index * _staggerDelay.inMilliseconds,
              ),
              duration: _animationDuration,
              child: SupplierCard(
                supplier: supplier,
                onEdit: () => _openEdit(supplier),
                onDelete: () => _confirmDelete(supplier),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatefulWidget {
  const _StaggeredFadeSlide({
    required this.child,
    required this.delay,
    required this.duration,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
