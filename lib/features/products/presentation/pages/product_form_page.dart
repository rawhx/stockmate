import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/presentation/providers/product_provider.dart';
import 'package:stockmate/features/products/presentation/widgets/product_detail_states.dart';
import 'package:stockmate/features/products/presentation/widgets/product_form_fields.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({this.productId, super.key});

  final String? productId;

  bool get isEditing => productId != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _categoryController = TextEditingController();
  final _supplierController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _currentStockController = TextEditingController();

  Product? _originalProduct;
  String? _loadError;
  String? _submitError;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  @override
  void didUpdateWidget(covariant ProductFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId && widget.isEditing) {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _supplierController.dispose();
    _minimumStockController.dispose();
    _currentStockController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final product = await context.read<ProductProvider>().getProductById(
        widget.productId!,
      );
      if (!mounted) return;
      setState(() => _originalProduct = product);
      if (product != null) _fillForm(product);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _originalProduct = null;
        _loadError = 'The product could not be loaded. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillForm(Product product) {
    _codeController.text = product.code;
    _nameController.text = product.name;
    _priceController.text = _numberText(product.price);
    _unitController.text = product.unit;
    _categoryController.text = product.categoryName;
    _supplierController.text = product.supplierName ?? '';
    _minimumStockController.text = '${product.minimumStock}';
    _currentStockController.text = '${product.currentStock}';
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final original = _originalProduct;
    final supplierName = _supplierController.text.trim();
    final categoryName = _categoryController.text.trim();
    final product = Product(
      id:
          original?.id ??
          'product-${DateTime.now().microsecondsSinceEpoch.toString()}',
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      unit: _unitController.text.trim(),
      categoryId: original?.categoryName == categoryName
          ? original!.categoryId
          : _slug(categoryName),
      categoryName: categoryName,
      supplierId: original?.supplierName == supplierName
          ? original?.supplierId
          : null,
      supplierName: supplierName.isEmpty ? null : supplierName,
      minimumStock: int.parse(_minimumStockController.text.trim()),
      currentStock: int.parse(_currentStockController.text.trim()),
    );

    final provider = context.read<ProductProvider>();
    final success = widget.isEditing
        ? await provider.editProduct(product)
        : await provider.addProduct(product);
    if (!mounted) return;

    if (!success) {
      setState(() {
        _isSaving = false;
        _submitError =
            provider.errorMessage ?? 'The product could not be saved.';
      });
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'Add product'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ProductDetailErrorState(
        message: _loadError!,
        onRetry: _loadProduct,
      );
    }

    if (widget.isEditing && _originalProduct == null) {
      return ProductNotFoundState(onRetry: _loadProduct);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Form(
            key: _formKey,
            child: ProductFormFields(
              codeController: _codeController,
              nameController: _nameController,
              priceController: _priceController,
              unitController: _unitController,
              categoryController: _categoryController,
              supplierController: _supplierController,
              minimumStockController: _minimumStockController,
              currentStockController: _currentStockController,
              isEditing: widget.isEditing,
              isSaving: _isSaving,
              errorMessage: _submitError,
              onSubmit: _submit,
            ),
          ),
        ),
      ),
    );
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('(^-+|-+\$)'), '');
  }

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}
