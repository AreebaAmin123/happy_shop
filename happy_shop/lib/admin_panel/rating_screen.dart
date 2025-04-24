import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingScreen extends StatefulWidget {
  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  List<Map<String, dynamic>> productsWithRatings = [];

  Future<void> fetchRatings() async {
    final productResponse = await Supabase.instance.client
        .from('products')
        .select('id, name, price, image_url, category');

    final ratingResponse = await Supabase.instance.client
        .from('product_average_ratings')
        .select('product_id, total_ratings, average_rating');

    if (productResponse.error != null || ratingResponse.error != null) {
      print("Error fetching data: ${productResponse.error?.message ?? ''} ${ratingResponse.error?.message ?? ''}");
      return;
    }

    final List<Map<String, dynamic>> productList =
    List<Map<String, dynamic>>.from(productResponse.data);
    final List<Map<String, dynamic>> ratingList =
    List<Map<String, dynamic>>.from(ratingResponse.data);

    for (var product in productList) {
      final rating = ratingList.firstWhere(
            (r) => r['product_id'] == product['id'],
        orElse: () => {'total_ratings': null, 'average_rating': null},
      );
      product['total_ratings'] = rating['total_ratings'];
      product['average_rating'] = rating['average_rating'];
    }

    setState(() {
      productsWithRatings = productList;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Text("Ratings", style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: productsWithRatings.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: productsWithRatings.length,
        itemBuilder: (context, index) {
          final product = productsWithRatings[index];
          final name = product['name'] ?? 'No Name';
          final price = product['price'] ?? 0.0;
          final imageUrl = product['image_url'] ?? '';
          final category = product['category'] ?? 'No Category';
          final totalRating = product['total_ratings'];
          final averageRating = product['average_rating'];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              contentPadding: EdgeInsets.all(8),
              leading: CircleAvatar(
                radius: 45,
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty ? Icon(Icons.image, size: 25) : null,
              ),
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: $category'),
                  SizedBox(height: 3),
                  Text('Price: PKR ${price.toStringAsFixed(2)}'),
                  SizedBox(height: 3),
                  Text(
                    'Total Ratings: ${totalRating ?? 'N/A'}',
                    style: TextStyle(color: Colors.orange[700], fontSize: 15),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Average Rating: ${averageRating != null ? averageRating.toStringAsFixed(1) : 'N/A'}',
                    style: TextStyle(color: Colors.green[700], fontSize: 15),
                  ),
                ],
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
