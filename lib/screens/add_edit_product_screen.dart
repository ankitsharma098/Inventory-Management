import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _sku;
  late double _price;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _sku = widget.product!.sku;
      _price = widget.product!.price;
      _quantity = widget.product!.quantity;
    } else {
      _name = '';
      _sku = '';
      _price = 0.0;
      _quantity = 0;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final product = Product(
        id: widget.product?.id ?? '',
        name: _name,
        sku: _sku,
        price: _price,
        quantity: _quantity,
      );

      await ProductService().saveProduct(product);

      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter product name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _sku,
                decoration: const InputDecoration(labelText: 'SKU'),
                validator: (value) =>
                value!.isEmpty ? 'Enter SKU' : null,
                onSaved: (value) => _sku = value!,
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty || double.tryParse(value) == null
                    ? 'Enter valid price'
                    : null,
                onSaved: (value) => _price = double.parse(value!),
              ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty || int.tryParse(value) == null
                    ? 'Enter valid quantity'
                    : null,
                onSaved: (value) => _quantity = int.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(
                    widget.product == null
                        ? 'Add Product'
                        : 'Update Product'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}