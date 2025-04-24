import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/edit_product.dart';
import 'package:happy_shop/screens/Image_Detail_Screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SearchProducts extends StatefulWidget {
  @override
  _SearchProductsState createState() => _SearchProductsState();
}

class _SearchProductsState extends State<SearchProducts> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _loading = false;

  List<String> _searchHistory = [];

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final response = await Supabase.instance.client
        .from('products')
        .select('id, name, image_url, description, price, favorite, category')
        .or('category.ilike.%$query%,name.ilike.%$query%')
        .order('name', ascending: false);

    if (response.error == null) {
      final List<Map<String, dynamic>> rawProducts = List.from(response.data);

      for (var product in rawProducts) {
        final ratingRes = await Supabase.instance.client
            .from('product_ratings')
            .select('rating')
            .eq('product_id', product['id']);

        final ratings = List<Map<String, dynamic>>.from(ratingRes);
        final ratingValues = ratings.map((r) => (r['rating'] ?? 0.0) as double).toList();

        final avgRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0.0;

        product['rating'] = avgRating;
      }

      setState(() {
        _products = rawProducts;
        _addToSearchHistory(query);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  void _addToSearchHistory(String query) {
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.add(query);
      });
    }
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _onProductClick(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(item: product),
      ),
    );
  }

  void _onEditProductClick(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          product: product,
          onProductUpdated: (Map<String, dynamic> updatedProduct) {
            setState(() {
              int index = _products.indexWhere((p) => p['id'] == updatedProduct['id']);
              if (index != -1) {
                _products[index] = updatedProduct;
              }
            });
          },
        ),
      ),
    );
  }
  Widget _buildRatingStars(double rating) {
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
      appBar: AppBar(title: Text('Product Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchProducts(_searchController.text);
                  },
                ),
              ),
              onChanged: (text) {
                if (text.isEmpty) {
                  setState(() {
                    _products.clear();
                  });
                }
              },
              onSubmitted: (text) {
                _searchProducts(text);
              },
            ),
            SizedBox(height: 16),
            _searchController.text.isEmpty && _products.isEmpty
                ? _buildSearchHistory()
                : _loading
                ? CircularProgressIndicator()
                : _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      children: [
        if (_searchHistory.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search History', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ..._searchHistory.map((query) {
                return ListTile(
                  title: Text(query),
                  trailing: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchHistory.remove(query);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _searchProducts(query);
                  },
                );
              }).toList(),
            ],
          ),
        SizedBox(height: 16),
        if (_searchHistory.isNotEmpty)
          TextButton(
            onPressed: _clearSearchHistory,
            child: Text('Clear All'),
          ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return Center(child: Text('No products found for your search'));
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
            childAspectRatio: (MediaQuery.of(context).size.width / 2) / 360,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            var product = _products[index];
            double rating = product['rating'];

            return GestureDetector(
              onTap: () => _onProductClick(product),
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
                              product['image_url'] ?? 'https://via.placeholder.com/150',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => {
                              _onEditProductClick(product)
                            },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PKR ${product['price']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                            _buildRatingStars(rating),
                          ],
                        ),
                      Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          product['description'] ?? 'No description available',
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
    );
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}
