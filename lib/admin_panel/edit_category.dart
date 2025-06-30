import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function(Map<String, dynamic>) onCategoryUpdated;
  EditCategoryScreen({required this.category, required this.onCategoryUpdated});

  @override
  _EditCategoryScreenState createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late TextEditingController nameController;
  late TextEditingController imageController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category['name']);
    imageController = TextEditingController(text: widget.category['image_url']);
  }


  Future<void> _updateCategory() async {
    final response = await Supabase.instance.client
        .from('categories')
        .update({
      'name': nameController.text,
      'image_url': imageController.text,
    })
        .eq('id', widget.category['id']);

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.error!.message}')));
    } else {

      widget.onCategoryUpdated({
        'id': widget.category['id'],
        'name': nameController.text,
        'image_url': imageController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category updated successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [

            widget.category['image_url'] != null && widget.category['image_url'].isNotEmpty
                ? Image.network(widget.category['image_url'], height: 180, width: 200)
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
            // Category Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
            SizedBox(height: 20),
            // Save Changes Button
            ElevatedButton(
              onPressed: _updateCategory,
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
