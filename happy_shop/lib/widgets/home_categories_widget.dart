import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/categories.dart';
import 'package:happy_shop/screens/category_detail_screen.dart';


final supabase = Supabase.instance.client;

class HomeCategoriesWidget extends StatefulWidget {
  const HomeCategoriesWidget({super.key});

  @override
  _HomeCategoriesWidget createState() => _HomeCategoriesWidget();
}

class _HomeCategoriesWidget extends State<HomeCategoriesWidget> {
  List<Map<String, dynamic>> categoriesData = [];

  @override
  void initState() {
    super.initState();
    _fetchCategoryImages();
  }

  Future<void> _fetchCategoryImages() async {
    try {

      final response = await supabase
          .from('categories')
          .select('id, name, image_url')
          .select('*');

      if (response.error != null) {
        throw Exception('Error fetching categories: ${response.error!.message}');
      }

      setState(() {
        categoriesData = List<Map<String, dynamic>>.from(response.data);
      });
    } catch (error) {
      print("Error fetching category images: $error");
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
                'Categories',
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoriesData.map((category) {
                String categoryName = category['name'] ?? 'Unknown';
                String imageUrl = category['image_url'] ?? 'https://via.placeholder.com/150';

                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailScreen(
                            category: categoryName,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 120,
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Text(
                              categoryName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}
