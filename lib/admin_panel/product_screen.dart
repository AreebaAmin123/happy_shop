import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/add_product.dart';
import 'package:happy_shop/admin_panel/edit_product.dart';
import 'package:happy_shop/admin_panel/search_products.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> products = [];


  Future<void> fetchProducts() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('name, price, image_url, category')
        .select('*');

    if (response.error != null) {
      print("Error fetching products: ${response.error!.message}");
    } else {
      setState(() {

        products = List<Map<String, dynamic>>.from(response.data);
      });
    }
  }


  Future<void> deleteProduct(String productId) async {
    final response = await Supabase.instance.client
        .from('products')
        .delete()
        .eq('id', productId);

    if (response.error != null) {
      throw Exception('Error deleting product: ${response.error!.message}');
    }

    setState(() {
      products.removeWhere((product) => product['id'] == productId);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  void _onEditProductClick(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          product: product,
          onProductUpdated: (Map<String, dynamic> updatedProduct) {
            setState(() {
              int index = products.indexWhere((p) => p['id'] == updatedProduct['id']);
              if (index != -1) {
                products[index] = updatedProduct;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Text(
              "Products",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 8),
            Text(
              '(${products.length})',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchProducts(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final name = product['name'] ?? 'No Name';
          final price = product['price'] ?? 0.0;
          final imageUrl = product['image_url'] ?? '';
          final category = product['category'] ?? 'No Category';

          return Dismissible(
            key: Key(product['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              deleteProduct(product['id'].toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Product deleted')),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListTile(
                contentPadding: EdgeInsets.all(8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.image, size: 25)
                      : null,
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: $category'),
                    SizedBox(height: 3),
                    Text('Price: PKR ${price.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    _onEditProductClick(product);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}


