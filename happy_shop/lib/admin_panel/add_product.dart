import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;
  Uint8List? _webImageBytes;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
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

  Future<Uint8List> _compressImage(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) {
      throw 'Error decoding image';
    }

    List<int> compressedImage = img.encodeJpg(image, quality: 70);

    while (compressedImage.length > 100 * 1024) {
      compressedImage = img.encodeJpg(image, quality: 60);
    }

    return Uint8List.fromList(compressedImage);
  }

  Future<void> _uploadImage() async {
    print("Upload button pressed ✅");

    if (kIsWeb && _webImageBytes == null) {
      print('❌ Web: No image selected');
      return;
    }

    if (!kIsWeb && _imageFile == null) {
      print('❌ Mobile: No image selected');
      return;
    }

    String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
    print("Image filename: $fileName");

    try {
      if (kIsWeb) {
        final storageResponse = await Supabase.instance.client.storage
            .from('clothes')
            .uploadBinary(fileName, _webImageBytes!);

        if (storageResponse.isEmpty) {
          print('❌ Web: Error uploading image');
          return;
        }
      } else {
        final compressedImageBytes = await _compressImage(_imageFile!);
        final tempDir = Directory.systemTemp;
        final tempFile = await File('${tempDir.path}/temp_image.jpg')
            .writeAsBytes(compressedImageBytes);

        final storageResponse = await Supabase.instance.client.storage
            .from('clothes')
            .upload(fileName, tempFile);

        if (storageResponse.isEmpty) {
          print('❌ Mobile: Error uploading image');
          return;
        }
      }

      final imageUrl =
      Supabase.instance.client.storage.from('clothes').getPublicUrl(fileName);
      setState(() {
        _imageUrl = imageUrl;
      });

      print('✅ Image uploaded successfully, URL: $_imageUrl');
      _saveProductData();
    } catch (e) {
      print('❌ Upload error: $e');
    }
  }

  Future<void> _saveProductData() async {
    if (_imageUrl == null) {
      print('❌ Please upload an image first.');
      return;
    }

    final productData = {
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'description': _descriptionController.text.trim(),
      'image_url': _imageUrl,
    };

    print("📦 Saving product: $productData");

    try {
      final response = await Supabase.instance.client
          .from('products')
          .insert(productData)
          .select();

      if (response.isEmpty) {
        print('❌ Error saving product');
        return;
      }

      print('✅ Product added successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Product uploaded successfully!')),
      );
    } catch (e) {
      print("❌ Product save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_imageFile != null && !kIsWeb)
              Container(
                height: 300,
                width: double.infinity,
                child: Image.file(_imageFile!,
                  ),
              ),
            if (_webImageBytes != null && kIsWeb)
              Container(
                height: 200,
                width: double.infinity,
                child: Image.memory(_webImageBytes!,),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Pick Image', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Upload & Save Product', style: TextStyle(color: Colors.white)),
            ),
          ],
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

