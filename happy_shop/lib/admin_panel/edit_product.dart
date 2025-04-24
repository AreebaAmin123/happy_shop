import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onProductUpdated;

  EditProductScreen({required this.product, required this.onProductUpdated});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController imageController;

  String? selectedCategory;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    priceController = TextEditingController(text: widget.product['price'].toString());
    descriptionController = TextEditingController(text: widget.product['description']);
    imageController = TextEditingController(text: widget.product['image_url']);

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await Supabase.instance.client.from('categories').select('name').select('*');

    if (response.error != null) {
      print('Error fetching categories: ${response.error!.message}');
    } else {
      List<String> fetchedCategories = [];
      for (var category in response.data) {
        fetchedCategories.add(category['name']);
      }
      setState(() {
        categories = fetchedCategories;
        selectedCategory = widget.product['category'];
      });
    }
  }

  Future<void> _updateProduct() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category')));
      return;
    }

    final response = await Supabase.instance.client
        .from('products')
        .update({
      'name': nameController.text,
      'category': selectedCategory,
      'price': double.parse(priceController.text),
      'description': descriptionController.text,
      'image_url': imageController.text,
    })
        .eq('id', widget.product['id']);

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.error!.message}')));
    } else {
      widget.onProductUpdated({
        'id': widget.product['id'],
        'name': nameController.text,
        'category': selectedCategory,
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'image_url': imageController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product updated successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            widget.product['image_url'] != null && widget.product['image_url'].isNotEmpty
                ? Image.network(widget.product['image_url'], height: 180, width: 200)
                : Icon(Icons.image, size: 250, color: Colors.grey),
            SizedBox(height: 10),

            TextField(
              controller: imageController,
              decoration: InputDecoration(
                labelText: 'Image URL',
                hintText: 'Enter a new image URL',
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 10),

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newCategory) {
                setState(() {
                  selectedCategory = newCategory;
                });
              },
              hint: Text('Select a category'),
            ),
            SizedBox(height: 10),

            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Save Changes',
                style: TextStyle(
                    color: Colors.white
                ),),
            ),

          ],
        ),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;

  get data => nonNulls;
}
