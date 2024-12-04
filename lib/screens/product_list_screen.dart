import 'dart:async';

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}
enum SortOption {
  nameAscending,
  nameDescending,
  priceAscending,
  priceDescending,
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';


  SortOption _currentSortOption = SortOption.nameAscending;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_debounceSearch);
    _loadProducts();
  }

  // Debounce timer for search
  Timer? _debounceTimer;

  void _debounceSearch() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        query = query.toLowerCase().trim();
        _filteredProducts = _allProducts.where((product) {
          final nameLower = product.name.toLowerCase();
          final skuLower = product.sku.toLowerCase();
          final price = product.price.toString();

          return nameLower.contains(query) ||
              skuLower.contains(query) ||
              price.contains(query);
        }).toList();
      }
      _sortProducts(_currentSortOption);
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _sortProducts(_currentSortOption);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _sortProducts(SortOption sortOption) {
    setState(() {
      _currentSortOption = sortOption;
      switch (sortOption) {
        case SortOption.nameAscending:
          _filteredProducts.sort((a, b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case SortOption.nameDescending:
          _filteredProducts.sort((a, b) =>
              b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case SortOption.priceAscending:
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceDescending:
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, SKU, or price',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme
                  .of(context)
                  .primaryColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => _debounceSearch(),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty ? Icons.inventory : Icons
                  .search_off,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty
                  ? 'No Products Available'
                  : 'No Products Found',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
                child: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          product.name,
          style: Theme
              .of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku}'),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme
                    .of(context)
                    .primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (product.quantity < 5)
              const Icon(Icons.warning, color: Colors.red),
            Text(
              'Qty: ${product.quantity}',
              style: TextStyle(
                color: product.quantity < 5 ? Colors.red : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToAddEditProduct(product: product),
        onLongPress: () => _showDeleteDialog(product),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAddEditProduct({Product? product}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );

    if (result == true) {
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product == null
                  ? 'Product Added Successfully'
                  : 'Product Updated Successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete this product?'),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('SKU: ${product.sku}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteProduct(product);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _productService.deleteProduct(product.id);
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                await _productService.saveProduct(product);
                await _loadProducts();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme
                          .of(context)
                          .dividerColor,
                    ),
                  ),
                ),
                child: Text(
                  'Sort Products',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Sort by Name (A-Z)'),
                selected: _currentSortOption == SortOption.nameAscending,
                onTap: () {
                  _sortProducts(SortOption.nameAscending);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Sort by Name (Z-A)'),
                selected: _currentSortOption == SortOption.nameDescending,
                onTap: () {
                  _sortProducts(SortOption.nameDescending);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Sort by Price (Low to High)'),
                selected: _currentSortOption == SortOption.priceAscending,
                onTap: () {
                  _sortProducts(SortOption.priceAscending);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Sort by Price (High to Low)'),
                selected: _currentSortOption == SortOption.priceDescending,
                onTap: () {
                  _sortProducts(SortOption.priceDescending);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort Products',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditProduct(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
