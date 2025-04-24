import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/image_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;

  const CategoryDetailScreen({required this.category, super.key});

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Future<List<Map<String, dynamic>>> category;

  @override
  void initState() {
    super.initState();
    category = fetchCategoryData(widget.category);
  }

  Future<List<Map<String, dynamic>>> fetchCategoryData(String category) async {
    final productsResponse = await Supabase.instance.client
        .from('products')
        .select('id, name, image_url, description, price, favorite, category')
        .eq('category', category);

    final List<Map<String, dynamic>> data =
    List<Map<String, dynamic>>.from(productsResponse);

    for (var item in data) {
      final ratingResponse = await Supabase.instance.client
          .from('product_ratings')
          .select('rating')
          .eq('product_id', item['id']);

      final ratings = List<Map<String, dynamic>>.from(ratingResponse);
      final ratingValues = ratings.map((r) {
        // Safely handle both int and double types for 'rating'
        var rating = r['rating'];
        return rating is double ? rating : (rating as int).toDouble();
      }).toList();

      final avgRating = ratingValues.isNotEmpty
          ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
          : 0.0;

      item['rating'] = avgRating;
    }

    return data;
  }

  void _toggleFavorite(Map<String, dynamic> item) async {
    setState(() {
      item['favorite'] = !(item['favorite'] ?? false);
    });

    await Supabase.instance.client
        .from('products')
        .update({'favorite': item['favorite']})
        .eq('id', item['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products in ${widget.category}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: category,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No products found.'));

          final products = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(6.0),
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                (MediaQuery.of(context).size.width / 2) / 340,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemBuilder: (context, index) {
                final item = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageDetailScreen(item: item),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Image.network(
                                item['image_url'] ??
                                    'https://via.placeholder.com/150',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(
                                  item['favorite'] == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () => _toggleFavorite(item),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item['name'] ?? 'Product Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PKR ${item['price'] ?? 0}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              // ⭐ Red-filled stars with red border
                              _buildRedBorderedStars(item['rating'] ?? 0.0),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            item['description'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRedBorderedStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.star_border, color: Colors.red, size: 14),
            if (index < rating.floor())
              Icon(Icons.star, color: Colors.red, size: 14),
          ],
        );
      }),
    );
  }
}
