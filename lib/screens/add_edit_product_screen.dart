import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen>with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  bool _isLoading = false;

  // Animation controllers and animations
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Initialize controllers with existing product data or empty strings
    _nameController = TextEditingController(
        text: widget.product?.name ?? '');
    _skuController = TextEditingController(
        text: widget.product?.sku ?? '');
    _priceController = TextEditingController(
        text: widget.product?.price.toString() ?? '');
    _quantityController = TextEditingController(
        text: widget.product?.quantity.toString() ?? '');

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    // Dispose controllers and animation controller
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final product = Product(
          id: widget.product?.id ?? '',
          name: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
        );

        await _productService.saveProduct(product);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product == null
                    ? 'Product Added Successfully'
                    : 'Product Updated Successfully',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving product: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _animation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: ListView(
                      children: [
                        _buildAnimatedFormField(_buildProductNameField()),
                        const SizedBox(height: 16),
                        _buildAnimatedFormField(_buildSKUField()),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnimatedFormField(_buildPriceField()),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAnimatedFormField(_buildQuantityField()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: Center(
                  child: ScaleTransition(
                    scale: AlwaysStoppedAnimation(1.2),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField(Widget child) {
    return ScaleTransition(
      scale: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: child,
      ),
    );
  }

  Widget _buildProductNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Product Name',
        prefixIcon: const Icon(Icons.shopping_bag_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter product name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildSKUField() {
    return TextFormField(
      controller: _skuController,
      decoration: InputDecoration(
        labelText: 'SKU',
        prefixIcon: const Icon(Icons.qr_code_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter SKU';
        }
        return null;
      },
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Price',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter price';
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Invalid price';
        }
        return null;
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantity',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter quantity';
        }
        final quantity = int.tryParse(value);
        if (quantity == null || quantity < 0) {
          return 'Invalid quantity';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _animation,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveProduct,
        icon: Icon(
          widget.product == null ? Icons.add : Icons.update,
          color: Colors.white,
        ),
        label: Text(
          widget.product == null ? 'Add Product' : 'Update Product',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}