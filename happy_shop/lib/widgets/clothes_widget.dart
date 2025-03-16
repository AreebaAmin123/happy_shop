import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/Image_Detail_Screen.dart';
import 'package:happy_shop/screens/favourite.dart';

class ClothesWidget extends StatefulWidget {
  final String categoryName;

  ClothesWidget({required this.categoryName});

  @override
  _ClothesWidgetState createState() => _ClothesWidgetState();
}

class _ClothesWidgetState extends State<ClothesWidget> {
  late Future<List<Map<String, dynamic>>> clothes;

  @override
  void initState() {
    super.initState();
    clothes = fetchClothesData();
  }


  Future<List<Map<String, dynamic>>> fetchClothesData() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('id, name, image_url, description, price, favorite, rating, category')
        .eq('category', 'clothes');

    if (response.error != null) {
      throw Exception('Error fetching data: ${response.error!.message}');
    }

    var data = List<Map<String, dynamic>>.from(response.data);


    for (var item in data) {
      item['name'] = item['name'] ?? 'Clothing Item';
      item['image_url'] = item['image_url'] ?? 'https://via.placeholder.com/150';
      item['description'] = item['description'] ?? 'No description available';
      item['price'] = item['price'] ?? 0.0;
      item['favorite'] = item['favorite'] ?? false;
      item['rating'] = item['rating'] ?? 0.0;
    }

    return data;
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    clothes = fetchClothesData();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: clothes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No clothes available.'));
          } else {
            var data = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Available Clothes in ${widget.categoryName}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 items per row
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: (MediaQuery.of(context).size.width / 2) / 500,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var item = data[index];
                      return GestureDetector(
                        onTap: () => _navigateToImageDetail(item),
                        child: Card(
                          elevation: 5,
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
                                  // Rating stars display
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
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
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

