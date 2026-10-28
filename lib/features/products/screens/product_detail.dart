import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProductDetails(widget.productId);
      }
    });
  }

  void _edit(Product product) {
    context.pushNamed(
      AppRoutes.productEdit,
      pathParameters: {'id': '${product.id}'},
      extra: product,
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.title}" will be removed from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.deleteProduct(product.id);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Product deleted (simulated)')),
      );
      context.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.actionError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final product = provider.selectedProduct;
        final canAct = product != null && !provider.isSaving;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: canAct ? () => _edit(product) : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: canAct ? () => _confirmDelete(product) : null,
              ),
            ],
          ),
          body: _buildBody(provider, product),
        );
      },
    );
  }

  Widget _buildBody(ProductProvider provider, Product? product) {
    if (provider.detailsError.isNotEmpty) {
      return AppError(
        message: provider.detailsError,
        onRetry: () => context
            .read<ProductProvider>()
            .fetchProductDetails(widget.productId),
      );
    }
    if (provider.isDetailsLoading || product == null) {
      return const AppLoading();
    }
    return _ProductDetails(product: product);
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final images = (product.images.isNotEmpty
        ? product.images
        : [product.thumbnail])
        .where((url) => url.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            child: images.isEmpty
                ? const Center(child: Icon(Icons.image_not_supported, size: 64))
                : PageView(
              children: images
                  .map(
                    (url) => Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                  const Icon(Icons.image_not_supported, size: 64),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(product.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Category', value: product.category),
          if (product.brand != null)
            _InfoRow(label: 'Brand', value: product.brand!),
          if (product.stock != null)
            _InfoRow(label: 'Stock', value: '${product.stock}'),
          if (product.rating != null)
            _InfoRow(label: 'Rating', value: '${product.rating} / 5'),
          const SizedBox(height: 16),
          Text('Description', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(product.description),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}