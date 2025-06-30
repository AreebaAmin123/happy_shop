import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddCategoryScreen extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;
  Uint8List? _webImageBytes;

  final TextEditingController _nameController = TextEditingController();

  // Pick Image (Mobile and Web)
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  // Compress Image (Only for Mobile)
  Future<Uint8List> _compressImage(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw 'Error decoding image';
    }

    List<int> compressedImage = img.encodeJpg(image, quality: 70);

    // Keep compressing until the image is below the threshold size (100KB)
    while (compressedImage.length > 100 * 1024) {
      compressedImage = img.encodeJpg(image, quality: 60);
    }

    return Uint8List.fromList(compressedImage);
  }

  // Upload Image to Supabase (Works on Mobile & Web)
  Future<void> _uploadImage() async {
    if (kIsWeb && _webImageBytes == null) {
      _showSnackbar('Please pick an image');
      return;
    }

    if (!kIsWeb && _imageFile == null) {
      _showSnackbar('Please pick an image');
      return;
    }

    String fileName = 'category_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // For Web
    if (kIsWeb) {
      final storageResponse = await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(fileName, _webImageBytes!);
      if (storageResponse.error != null) {
        _showSnackbar('Error uploading image: ${storageResponse.error?.message}');
        return;
      }
    } else {
      // For Mobile (Android/iOS)
      final compressedImageBytes = await _compressImage(_imageFile!);
      final storageResponse = await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(fileName, compressedImageBytes);
      if (storageResponse.error != null) {
        _showSnackbar('Error uploading image: ${storageResponse.error?.message}');
        return;
      }
    }

    // Get the URL of the uploaded image
    final imageUrl =
    Supabase.instance.client.storage.from('images').getPublicUrl(fileName);
    setState(() {
      _imageUrl = imageUrl;
    });

    print('Image uploaded successfully, URL: $_imageUrl');

    _saveCategoryData();
  }

  // Save Category Data to Supabase
  Future<void> _saveCategoryData() async {
    if (_imageUrl == null) {
      _showSnackbar('Please upload an image first.');
      return;
    }

    final categoryData = {
      'name': _nameController.text.trim(),
      'image_url': _imageUrl,
    };

    final response = await Supabase.instance.client.from('categories').insert(categoryData).select('*');

    if (response.error != null) {
      _showSnackbar('Error saving category: ${response.error?.message}');
      return;
    }

    _showSnackbar('Category added successfully');
  }

  // Show Snackbar with message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Category'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display the picked image (mobile or web)
              if (_imageFile != null && !kIsWeb)
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_webImageBytes != null && kIsWeb)
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Image.memory(
                    _webImageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 20),

              // Text field for Category Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Category Name'),
              ),
              SizedBox(height: 20),

              // Button to pick an image
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(
                  'Pick Image',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

              // Button to upload image and save category
              ElevatedButton(
                onPressed: _uploadImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(
                  'Upload Image and Save Category',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on List<int> {
  get lengthInBytes => nonNulls;
}

extension on String {
  get error => null;
}

extension on PostgrestList {
  get error => nonNulls;
}
