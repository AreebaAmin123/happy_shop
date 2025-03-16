import 'package:flutter/material.dart';
import 'package:happy_shop/screens/Image_Detail_Screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  bool _loading = false;

  List<String> _searchHistory = [];


  Set<String> _favoriteProductIds = Set();


  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final response = await Supabase.instance.client
        .from('products')
        .select('*')
        .or('category.ilike.%$query%,name.ilike.%$query%')
        .select('*')
        .order('name', ascending: false);

    if (response.error == null) {
      setState(() {
        _products = List.from(response.data);
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

  void _navigateToImageDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(item: item),
      ),
    );
  }


  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }


  void _onProductClick(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailScreen(item: product),
      ),
    );
  }


  Future<void> _toggleFavorite(String productId) async {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });

    final response = await Supabase.instance.client
        .from('products')
        .update({'is_favourite': _favoriteProductIds.contains(productId)})
        .eq('id', productId);

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favorite status updated')),
      );
    }
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
      return Center(
        child: Text('No products found for your search'),
      );
    }

    return Expanded(
      child: GridView.builder(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: (MediaQuery.of(context).size.width / 2) / 500,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          var product = _products[index];
          bool isFavorited = _favoriteProductIds.contains(product['id']);
          double rating = product['rating']?.toDouble() ?? 0.0;
          int fullStars = rating.toInt();
          int halfStars = (rating - fullStars) >= 0.5 ? 1 : 0;
          int emptyStars = 5 - fullStars - halfStars;

          return GestureDetector(
            onTap: () => _onProductClick(product),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Image.network(
                          product['image_url'],
                          height: 350,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            icon: Icon(
                              isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              setState(() {
                                isFavorited = !isFavorited;
                                product['favourite'] = isFavorited;
                              });

                              final response = await Supabase.instance.client
                                  .from('products')
                                  .update({'favourite': isFavorited})
                                  .eq('id', product['id']);

                              if (response.error != null) {

                                print('Error updating favourite: ${response.error!.message}');
                              }
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product['price']} PKR',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),

                          Row(
                            children: [
                              for (int i = 0; i < fullStars; i++)
                                Icon(Icons.star, color: Colors.deepOrangeAccent, size: 16),
                              if (halfStars == 1)
                                Icon(Icons.star_half, color: Colors.deepOrangeAccent, size: 16),
                              for (int i = 0; i < emptyStars; i++)
                                Icon(Icons.star_border, color: Colors.deepOrangeAccent, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
    );
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}

