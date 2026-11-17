import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmate/features/products/domain/entities/product.dart';
import 'package:stockmate/features/products/domain/entities/product_form_options.dart';
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
  final _minimumStockController = TextEditingController(text: '0');
  final _currentStockController = TextEditingController(text: '0');
  ProductFormOptions _options = const ProductFormOptions(
    categories: [],
    suppliers: [],
  );
  String? _categoryId;
  String? _supplierId;

  Product? _originalProduct;
  String? _loadError;
  String? _submitError;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadForm();
    });
  }

  @override
  void didUpdateWidget(covariant ProductFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadForm();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _minimumStockController.dispose();
    _currentStockController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final provider = context.read<ProductProvider>();
      final results = await Future.wait<Object?>([
        provider.getFormOptions(),
        if (widget.isEditing) provider.getProductById(widget.productId!),
      ]);
      if (!mounted) return;
      final options = results[0] as ProductFormOptions;
      final product = widget.isEditing ? results[1] as Product? : null;
      if (product != null &&
          (!options.categories.any((item) => item.id == product.categoryId) ||
              (product.supplierId != null &&
                  !options.suppliers.any(
                    (item) => item.id == product.supplierId,
                  )))) {
        throw StateError(
          'Product references are unavailable in this account. Check its category and supplier.',
        );
      }
      setState(() {
        _options = options;
        _originalProduct = product;
      });
      if (product != null) _fillForm(product);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _originalProduct = null;
        _loadError = error is StateError
            ? error.message
            : 'The product form could not be loaded. Please try again.';
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
    _categoryId = product.categoryId;
    _supplierId = product.supplierId;
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
    final category = _options.categories.firstWhere(
      (item) => item.id == _categoryId,
    );
    ProductOption? supplier;
    for (final option in _options.suppliers) {
      if (option.id == _supplierId) supplier = option;
    }
    final product = Product(
      id:
          original?.id ??
          'product-${DateTime.now().microsecondsSinceEpoch.toString()}',
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      unit: _unitController.text.trim(),
      categoryId: category.id,
      categoryName: category.name,
      supplierId: supplier?.id,
      supplierName: supplier?.name,
      minimumStock: int.parse(_minimumStockController.text.trim()),
      currentStock: original?.currentStock ?? 0,
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
      return ProductDetailErrorState(message: _loadError!, onRetry: _loadForm);
    }

    if (widget.isEditing && _originalProduct == null) {
      return ProductNotFoundState(onRetry: _loadForm);
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
              options: _options,
              categoryId: _categoryId,
              supplierId: _supplierId,
              onCategoryChanged: (value) => setState(() => _categoryId = value),
              onSupplierChanged: (value) => setState(() => _supplierId = value),
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

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}
