import 'package:flutter/material.dart';
import 'package:happy_shop/screens/cart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  ImageDetailScreen({required this.item});

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  bool isFavourite = false;
  String? selectedSize;
  String? selectedColor;
  double productRating = 0;
  double avgRating = 0;
  int totalRatings = 0;

  List<String> sizes = ['S', 'M', 'L'];
  List<Map<String, dynamic>> colors = [
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
  ];

  @override
  void initState() {
    super.initState();
    isFavourite = widget.item['favorite'] ?? false;
    selectedSize = sizes.isNotEmpty ? sizes.first : null;
    selectedColor = colors.isNotEmpty ? colors.first['name'] : null;

    _loadUserRating();
    _loadAverageRating();
  }

  Future<void> _loadUserRating() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('product_ratings')
        .select('rating')
        .eq('user_id', user.id)
        .eq('product_id', widget.item['id'])
        .maybeSingle();

    if (response != null && response['rating'] != null) {
      setState(() {
        productRating = response['rating'].toDouble();
      });
    }
  }

  Future<void> _setUserRating(double rating) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final existing = await Supabase.instance.client
        .from('product_ratings')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', widget.item['id'])
        .maybeSingle();

    if (existing != null) {
      await Supabase.instance.client
          .from('product_ratings')
          .update({'rating': rating})
          .eq('id', existing['id']);
    } else {
      await Supabase.instance.client.from('product_ratings').insert({
        'user_id': user.id,
        'product_id': widget.item['id'],
        'rating': rating,
      });
    }

    setState(() {
      productRating = rating;
    });

    _loadAverageRating();
  }

  Future<void> _loadAverageRating() async {
    final response = await Supabase.instance.client
        .from('product_average_ratings')
        .select()
        .eq('product_id', widget.item['id'])
        .maybeSingle();

    if (response != null) {
      setState(() {
        avgRating = (response['average_rating'] ?? 0).toDouble();
        totalRatings = (response['total_ratings'] ?? 0);
      });
    }
  }

  void _toggleFavorite(Map<String, dynamic> item) async {
    setState(() {
      item['favorite'] = !(item['favorite'] ?? false);
      isFavourite = item['favorite'];
    });

    final response = await Supabase.instance.client
        .from('products')
        .update({'favorite': item['favorite']})
        .eq('id', item['id'])
        .select('*');

    if (response.error != null) {
      print('Error updating favorite: ${response.error!.message}');
    }
  }

  void _showQuantitySelector(BuildContext context) {
    int quantity = 1;
    bool isLoading = false;
    String? statusMessage;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets.add(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Quantity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(width: 20),
                      Text('$quantity', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (statusMessage != null) ...[
                    Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMessage!,
                            style: TextStyle(
                              color: isSuccess ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (isSuccess)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CartScreen()),
                          );
                        },
                        icon: Icon(Icons.shopping_cart_checkout, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        label: Text('Go to Cart', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                  if (statusMessage == null)
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                        setState(() {
                          isLoading = true;
                        });

                        final user = Supabase.instance.client.auth.currentUser;

                        if (user == null) {
                          setState(() {
                            statusMessage = 'Please log in to add to cart.';
                            isSuccess = false;
                            isLoading = false;
                          });
                          return;
                        }

                        final cartItem = {
                          'user_id': user.id,
                          'name': widget.item['name'],
                          'image_url': widget.item['image_url'],
                          'price': widget.item['price'],
                          'description': widget.item['description'],
                          'size': selectedSize,
                          'color': selectedColor,
                          'quantity': quantity,
                        };

                        try {
                          final response = await Supabase.instance.client
                              .from('cart')
                              .insert(cartItem)
                              .select();

                          if (response != null && response.isNotEmpty) {
                            setState(() {
                              isSuccess = true;
                              statusMessage = '✅ Added to Cart!';
                            });
                          } else {
                            setState(() {
                              isSuccess = false;
                              statusMessage = '❌ Failed to add to cart.';
                            });
                          }
                        } catch (e) {
                          setState(() {
                            isSuccess = false;
                            statusMessage = '❌ Error: $e';
                          });
                        }

                        setState(() {
                          isLoading = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        isLoading ? 'Adding...' : 'Add $quantity to Cart',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        GestureDetector(
          onTap: () {
            _setUserRating(i.toDouble());
          },
          child: Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: Colors.deepOrange,
            size: 20,
          ),
        ),
      );
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item['name']),
        actions: [
          IconButton(
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () {
              _toggleFavorite(widget.item);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.item['image_url'],
              height: 270,
              width: double.infinity,
              fit: BoxFit.fitHeight,
            ),
            SizedBox(height: 20),
            Text(
              widget.item['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${widget.item['price']}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildRatingStars(avgRating),
                    SizedBox(height: 4),
                    Text(
                      'Your rating: ${productRating.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(widget.item['description'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Center(
              child: Text('Select Size:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),
            Row(
              children: sizes.map((size) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (selected) {
                      setState(() {
                        selectedSize = selected ? size : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Center(
              child: Text('Select Color:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),
            ColorSelector(
              colors: colors,
              selectedColor: selectedColor,
              onColorSelect: (colorName) {
                setState(() {
                  selectedColor = colorName;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _showQuantitySelector(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSelector extends StatelessWidget {
  final List<Map<String, dynamic>> colors;
  final String? selectedColor;
  final Function(String) onColorSelect;

  ColorSelector({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorSelect(color['name']),
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color['color'],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColor == color['name']
                          ? Colors.deepPurple
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Text(color['name'], style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

extension on PostgrestList {
  get error => nonNulls;

}