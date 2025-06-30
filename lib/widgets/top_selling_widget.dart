import 'package:flutter/material.dart';
import 'package:happy_shop/screens/categories.dart';
import 'package:happy_shop/screens/image_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TopSellingWidget extends StatefulWidget {
  const TopSellingWidget({super.key});

  @override
  _TopSellingWidget createState() => _TopSellingWidget();
}

class _TopSellingWidget extends State<TopSellingWidget> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopSellingData();
  }

  Future<void> _fetchTopSellingData() async {
    try {
      final response = await supabase
          .from('products')
          .select('id, category, name, image_url, description, price, favorite');

      final List<Map<String, dynamic>> rawProducts = List<Map<String, dynamic>>.from(response);

      Map<String, Map<String, dynamic>> categoryMap = {};

      for (var product in rawProducts) {
        String category = product['category'];

        final ratingResponse = await supabase
            .from('product_ratings')
            .select('rating')
            .eq('product_id', product['id']);

        final ratings = List<Map<String, dynamic>>.from(ratingResponse);

        // 🔧 FIX: safely cast to double
        final ratingValues = ratings
            .map((r) => ((r['rating'] ?? 0) as num).toDouble())
            .toList();

        final avgRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0.0;

        product['rating'] = avgRating;

        if (!categoryMap.containsKey(category)) {
          categoryMap[category] = product;
        }
      }

      setState(() {
        products = categoryMap.values.toList();
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching products: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleFavorite(Map<String, dynamic> item) async {
    setState(() {
      item['favorite'] = !(item['favorite'] ?? false);
    });

    final response = await Supabase.instance.client
        .from('products')
        .update({'favorite': item['favorite']})
        .eq('id', item['id']);

    if (response.error != null) {
      print('Error updating favorite: ${response.error!.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategoriesScreen()),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: isLoading
              ? CircularProgressIndicator()
              : GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
              childAspectRatio: (MediaQuery.of(context).size.width / 2) / 340,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var item = products[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageDetailScreen(item: item),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                              BorderRadius.vertical(top: Radius.circular(8)),
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
                            item['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'PKR ${item['price']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            _buildRedBorderedStars(
                                (item['rating'] ?? 0.0).toDouble()),
                          ],
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Text(
                            item['description'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
