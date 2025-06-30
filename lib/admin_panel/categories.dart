import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/add_category.dart';
import 'package:happy_shop/admin_panel/category_detail.dart';
import 'package:happy_shop/admin_panel/edit_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Map<String, dynamic>>> categories;

  @override
  void initState() {
    super.initState();
    categories = fetchCategories();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await Supabase.instance.client
        .from('categories')
        .select('id, name, image_url')
        .select('*');

    if (response.error != null) {
      throw Exception('Error fetching categories: ${response.error!.message}');
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> deleteCategory(String categoryId) async {
    final response = await Supabase.instance.client
        .from('categories')
        .delete()
        .eq('id', categoryId);

    if (response.error != null) {
      throw Exception('Error deleting category: ${response.error!.message}');
    }

    setState(() {
      categories = fetchCategories();
    });
  }

  void _updateCategoryList(Map<String, dynamic> updatedCategory) {
    setState(() {
      categories = fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Text(
              "Categories",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 8),

            Builder(
              builder: (context) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: categories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }

                    return Text(
                      '(${snapshot.data?.length ?? 0})',
                      style: TextStyle(color: Colors.white),
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCategoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories available.'));
          } else {
            var data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  var category = data[index];
                  return Dismissible(
                    key: Key(category['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {

                      await deleteCategory(category['id'].toString());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category deleted')),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(
                              category: category['name'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          title: Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: category['image_url'] != null
                              ? Image.network(
                            category['image_url'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.category, size: 30),
                          trailing: IconButton(
                            icon: Icon(Icons.edit,color: Colors.blue,),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditCategoryScreen(
                                    category: category,
                                    onCategoryUpdated: _updateCategoryList,
                                  ),
                                ),
                              );
                              print('Edit category: ${category['name']}');
                            },
                          ),
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

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}
