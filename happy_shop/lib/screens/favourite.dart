import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/Image_Detail_Screen.dart';

class FavouriteScreen extends StatefulWidget {
  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  late Future<List<Map<String, dynamic>>> favoriteProducts;

  @override
  void initState() {
    super.initState();
    favoriteProducts = fetchFavoriteProducts();
  }

  Future<List<Map<String, dynamic>>> fetchFavoriteProducts() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('id, name, image_url, description, price, favorite')
        .eq('favorite', true);

    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

    for (var item in data) {
      final ratingResponse = await Supabase.instance.client
          .from('product_ratings')
          .select('rating')
          .eq('product_id', item['id']);

      final ratings = List<Map<String, dynamic>>.from(ratingResponse);
      final ratingValues = ratings.map((r) => (r['rating'] ?? 0.0) as double).toList();

      final avgRating = ratingValues.isNotEmpty
          ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
          : 0.0;

      item['name'] = item['name'] ?? '';
      item['image_url'] = item['image_url'] ?? 'https://via.placeholder.com/150';
      item['description'] = item['description'] ?? 'No description available';
      item['price'] = item['price'] ?? 0.0;
      item['rating'] = avgRating;
    }

    return data;
  }

  void _navigateToImageDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(item: item),
      ),
    );
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
    } else {
      setState(() {
        favoriteProducts = fetchFavoriteProducts();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favourite Products')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: favoriteProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No favorite products.'));
          } else {
            var data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  childAspectRatio:
                  (MediaQuery.of(context).size.width / 2) / 340,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  var item = data[index];

                  return GestureDetector(
                    onTap: () => _navigateToImageDetail(item),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                  child: Image.network(
                                    item['image_url'],
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PKR ${item['price']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  _buildRedBorderedStars(item['rating']),
                                ],
                              ),
                            Padding(
                              padding: EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                item['description'],
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
            );
          }
        },
      ),
    );
  }
}

