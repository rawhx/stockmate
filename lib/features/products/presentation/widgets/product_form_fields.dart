import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stockmate/features/products/presentation/widgets/product_form_validators.dart';

class ProductFormFields extends StatelessWidget {
  const ProductFormFields({
    required this.codeController,
    required this.nameController,
    required this.priceController,
    required this.unitController,
    required this.categoryController,
    required this.supplierController,
    required this.minimumStockController,
    required this.currentStockController,
    required this.isEditing,
    required this.isSaving,
    required this.onSubmit,
    this.errorMessage,
    super.key,
  });

  final TextEditingController codeController;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController unitController;
  final TextEditingController categoryController;
  final TextEditingController supplierController;
  final TextEditingController minimumStockController;
  final TextEditingController currentStockController;
  final bool isEditing;
  final bool isSaving;
  final String? errorMessage;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditing ? 'Update product details' : 'Create a new product',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete the information below to keep your inventory accurate.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          _FormErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: 20),
        _FormSection(
          title: 'Basic information',
          icon: Icons.inventory_2_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final code = TextFormField(
                key: const Key('product_code'),
                controller: codeController,
                enabled: !isSaving,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product code',
                  hintText: 'PRD-001',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                validator: (value) =>
                    ProductFormValidators.requiredText(value, 'Product code'),
              );
              final name = TextFormField(
                key: const Key('product_name'),
                controller: nameController,
                enabled: !isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  hintText: 'Premium rice',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    ProductFormValidators.requiredText(value, 'Product name'),
              );

              return _ResponsiveFields(
                isHorizontal: constraints.maxWidth >= 620,
                children: [code, name],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FormSection(
          title: 'Classification',
          icon: Icons.category_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _ResponsiveFields(
                isHorizontal: constraints.maxWidth >= 620,
                children: [
                  TextFormField(
                    key: const Key('product_category'),
                    controller: categoryController,
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'Food',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) =>
                        ProductFormValidators.requiredText(value, 'Category'),
                  ),
                  TextFormField(
                    key: const Key('product_unit'),
                    controller: unitController,
                    enabled: !isSaving,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'pcs, bottle, bag',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) =>
                        ProductFormValidators.requiredText(value, 'Unit'),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FormSection(
          title: 'Pricing and stock',
          icon: Icons.warehouse_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _ResponsiveFields(
                isHorizontal: constraints.maxWidth >= 720,
                children: [
                  TextFormField(
                    key: const Key('product_price'),
                    controller: priceController,
                    enabled: !isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Selling price',
                      hintText: '75000',
                      prefixText: 'Rp ',
                    ),
                    validator: ProductFormValidators.positivePrice,
                  ),
                  TextFormField(
                    key: const Key('product_current_stock'),
                    controller: currentStockController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Current stock',
                      prefixIcon: Icon(Icons.inventory_outlined),
                    ),
                    validator: (value) =>
                        ProductFormValidators.nonNegativeStock(
                          value,
                          'Current stock',
                        ),
                  ),
                  TextFormField(
                    key: const Key('product_minimum_stock'),
                    controller: minimumStockController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Minimum stock',
                      prefixIcon: Icon(Icons.notification_important_outlined),
                    ),
                    validator: (value) =>
                        ProductFormValidators.nonNegativeStock(
                          value,
                          'Minimum stock',
                        ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FormSection(
          title: 'Supplier',
          icon: Icons.local_shipping_outlined,
          child: TextFormField(
            key: const Key('product_supplier'),
            controller: supplierController,
            enabled: !isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Supplier name (optional)',
              hintText: 'PT Sumber Pangan',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            onFieldSubmitted: isSaving ? null : (_) => onSubmit(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('product_submit'),
          onPressed: isSaving ? null : onSubmit,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isEditing ? Icons.save_outlined : Icons.add),
          label: Text(isEditing ? 'Save changes' : 'Add product'),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.isHorizontal, required this.children});

  final bool isHorizontal;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isHorizontal) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _FormErrorBanner extends StatelessWidget {
  const _FormErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
