import 'package:flutter/material.dart';
import 'package:happy_shop/screens/categories.dart';
import 'package:happy_shop/screens/image_detail_screen.dart'; // Import ImageDetailScreen
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
          .select('id, category, name, image_url, description, price, favorite')
          .select('*');

      if (response.error != null) {
        throw Exception('Error fetching data: ${response.error!.message}');
      }


      Map<String, Map<String, dynamic>> categoryMap = {};


      for (var product in response.data) {
        String category = product['category'];

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
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
                       context, MaterialPageRoute(
                       builder: (context) => CategoriesScreen()));
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: isLoading
              ? CircularProgressIndicator()
              : GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: (MediaQuery.of(context).size.width / 2) / 520,
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
                            Image.network(
                              item['image_url'],
                              height: 350,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            SizedBox(width: 10),
                            _buildRatingStars(item['rating']),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8),
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
        ),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    int emptyStars = 5 - fullStars;

    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.deepOrange, size: 18));
    }
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.deepOrange, size: 18));
    }
    return Row(children: stars);
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}

