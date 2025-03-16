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
    selectedSize = sizes.first;
    selectedColor = colors.first['name'];
    productRating = widget.item['rating']?.toDouble() ?? 0;
  }

  Future<void> toggleFavourite() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final favorite = {
        'user_id': user.id,
        'id': widget.item['id'],
        'name': widget.item['name'],
        'image_url': widget.item['image_url'],
        'price': widget.item['price'],
        'size': selectedSize,
        'color': selectedColor,
      };

      if (isFavourite) {
        final response = await Supabase.instance.client
            .from('favorites')
            .delete()
            .match({'user_id': user.id, 'id': widget.item['id']});

        if (response.error == null) {
          setState(() {
            isFavourite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from favourites')));
        } else {
          print("Error removing from favourites: ${response.error?.message}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove from favourites')));
        }
      } else {
        final response = await Supabase.instance.client
            .from('favorites')
            .upsert(favorite)
            .eq('user_id', user.id)
            .eq('id', widget.item['id'])
            .select('*');

        if (response.error == null) {
          setState(() {
            isFavourite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to favourites')));
        } else {
          print("Error adding to favourites: ${response.error?.message}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to favourites')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in to add to favourites')));
    }
  }

  Future<void> addToCart(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final cartItem = {
        'user_id': user.id,
        'name': widget.item['name'],
        'image_url': widget.item['image_url'],
        'price': widget.item['price'],
        'description': widget.item['description'],
        'size': selectedSize,
        'color': selectedColor,
      };

      final response = await Supabase.instance.client
          .from('cart')
          .insert(cartItem)
          .select('*');

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Cart!')));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add to cart')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in to add to cart')));
    }
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
            onPressed: toggleFavourite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                widget.item['image_url'],
                height: 360,
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
                  _buildRatingStars(widget.item['rating']),
                ],
              ),
              SizedBox(height: 20),
              Text(
                widget.item['description'],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Select Size:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                child: Text(
                  'Select Color:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                  onPressed: () {
                    addToCart(context);
                  },
                  child: Text(
                      'Add to Cart',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  get error => nonNulls;

}

class ColorSelector extends StatelessWidget {
  final List<Map<String, dynamic>> colors;
  final String? selectedColor;
  final Function(String) onColorSelect;

  ColorSelector({required this.colors, required this.selectedColor, required this.onColorSelect});

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
                      color: selectedColor == color['name'] ? Colors.deepPurple : Colors.transparent,
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
