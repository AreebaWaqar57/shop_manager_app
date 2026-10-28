import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load data when the (protected) screen opens, not before login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProductProvider>();
      provider.fetchProducts();
      provider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Near the bottom of the list -> load the next page.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMore();
    }
  }

  void _onSearch(String text) {
    context.read<ProductProvider>().search(text);
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<ProductProvider>().search('');
  }

  void _onCategoryChanged(String? category) {
    _searchController.clear();
    context.read<ProductProvider>().selectCategory(category);
  }

  void _openDetails(Product product) {
    context.pushNamed(
      AppRoutes.productDetails,
      pathParameters: {'id': '${product.id}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Selector: rebuilds only when the total changes.
        title: Selector<ProductProvider, int>(
          selector: (context, provider) => provider.total,
          builder: (context, total, child) =>
              Text(total > 0 ? 'Products ($total)' : 'Products'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add product',
        onPressed: () => context.pushNamed(AppRoutes.productNew),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onClearSearch,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _CategoryDropdown(onChanged: _onCategoryChanged),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) =>
                  _buildBody(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductProvider provider) {
    if ((provider.isLoading || !provider.hasLoaded) &&
        provider.products.isEmpty) {
      return const AppLoading();
    }
    if (provider.errorMessage.isNotEmpty && provider.products.isEmpty) {
      return AppError(
        message: provider.errorMessage,
        onRetry: () => context.read<ProductProvider>().fetchProducts(),
      );
    }
    if (provider.products.isEmpty) {
      return const EmptyState(message: 'No products found.');
    }

    // Spinner while loading more, or a retry button if loading more failed.
    final showFooter =
        provider.isLoadingMore || provider.errorMessage.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<ProductProvider>().fetchProducts(),
            // Responsive: 1 column on phones, more columns on wide screens.
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                mainAxisExtent: 96,
              ),
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => _openDetails(product),
                );
              },
            ),
          ),
        ),
        if (showFooter)
          Padding(
            padding: const EdgeInsets.all(12),
            child: provider.isLoadingMore
                ? const CircularProgressIndicator()
                : TextButton(
              onPressed: () => context.read<ProductProvider>().loadMore(),
              child: Text('${provider.errorMessage} Tap to retry'),
            ),
          ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.onChanged});

  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    // context.watch(): rebuilds this widget when categories/selection change.
    final provider = context.watch<ProductProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String?>(
        isExpanded: true,
        value: provider.selectedCategory,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All categories'),
          ),
          ...provider.categories.map(
                (category) => DropdownMenuItem<String?>(
              value: category,
              child: Text(_label(category)),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// "mens-shirts" -> "Mens shirts"
String _label(String slug) {
  final text = slug.replaceAll('-', ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}