import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form-only state stays local to the screen.
  late final _titleController =
  TextEditingController(text: widget.product?.title ?? '');
  late final _descriptionController =
  TextEditingController(text: widget.product?.description ?? '');
  late final _priceController =
  TextEditingController(text: widget.product?.price.toString() ?? '');
  late final _categoryController =
  TextEditingController(text: widget.product?.category ?? '');
  late final _brandController =
  TextEditingController(text: widget.product?.brand ?? '');
  late final _imageController =
  TextEditingController(text: widget.product?.thumbnail ?? '');

  bool get _isEditing => widget.product != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.product;
    final imageUrl = _imageController.text.trim();
    final brand = _brandController.text.trim();
    final imageChanged = imageUrl != (existing?.thumbnail ?? '');

    final product = Product(
      id: existing?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _categoryController.text.trim(),
      brand: brand.isEmpty ? null : brand,
      thumbnail: imageUrl,
      images: imageChanged
          ? (imageUrl.isEmpty ? <String>[] : [imageUrl])
          : (existing?.images ?? <String>[]),
      stock: existing?.stock,
      rating: existing?.rating,
      discountPercentage: existing?.discountPercentage,
    );

    final provider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = _isEditing
        ? await provider.updateProduct(product)
        : await provider.createProduct(product);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Product updated (simulated)'
                : 'Product created (simulated)',
          ),
        ),
      );
      context.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.actionError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when saving starts/ends, so the button can be disabled.
    final isSaving = context.watch<ProductProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: 'Title',
                    validator: (value) => Validators.required(value, 'Title'),
                  ),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 4,
                    validator: (value) =>
                        Validators.required(value, 'Description'),
                  ),
                  AppTextField(
                    controller: _priceController,
                    label: 'Price',
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.price,
                  ),
                  AppTextField(
                    controller: _categoryController,
                    label: 'Category',
                    validator: (value) =>
                        Validators.required(value, 'Category'),
                  ),
                  AppTextField(
                    controller: _brandController,
                    label: 'Brand (optional)',
                  ),
                  AppTextField(
                    controller: _imageController,
                    label: 'Image URL (optional)',
                    keyboardType: TextInputType.url,
                    validator: Validators.optionalUrl,
                  ),
                  AppButton(
                    label: _isEditing ? 'Save changes' : 'Create product',
                    isLoading: isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}