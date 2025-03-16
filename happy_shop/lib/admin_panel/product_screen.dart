import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final response = await Supabase.instance.client.from('products').select().select('*');

    if (response.error == null) {
      setState(() {
        products = response.data.length as List;
      });
    } else {
      print('Error fetching products: ${response.error?.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text('Price: \$${product['price']}'),
            leading: Image.network(product['image_url'] ?? ''),
          );
        },
      ),
    );
  }
}

extension on PostgrestList {
  Iterable<PostgrestMap> get data => nonNulls;

  get error => nonNulls;
}
