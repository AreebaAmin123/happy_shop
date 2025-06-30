import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/checkout_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final response = await Supabase.instance.client
          .from('cart')
          .select('*')
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          if (response.error == null) {
            cartItems = List<Map<String, dynamic>>.from(response.data);
          } else {
            print('Error fetching cart items: ${response.error?.message}');
          }
          isLoading = false;
        });
      }
    } else {
      print('No user logged in');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    final response = await Supabase.instance.client
        .from('cart')
        .delete()
        .eq('id', cartItemId)
        .select('*');

    if (response.error == null) {
      setState(() {
        cartItems.removeWhere((item) => item['id'] == cartItemId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from cart')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove from cart')));
    }
  }

  double calculateSubtotal() {
    double subtotal = 0.0;
    for (var item in cartItems) {
      subtotal += item['price'] * item['quantity'];
    }
    return subtotal;
  }

  double calculateShippingCharges() {
    return cartItems.length * 150.0;
  }

  double calculateTotal() {
    return calculateSubtotal() + calculateShippingCharges();
  }

  void placeOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    bool orderPlaced = true;

    if (orderPlaced && user != null) {
      await Supabase.instance.client.from('cart').delete().eq('user_id', user.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: cartItems)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: ListTile(
                    leading: Image.network(cartItem['image_url'], width: 50),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            cartItem['name'],
                            maxLines: 1,
                            style: TextStyle(fontSize: screenWidth * 0.045),
                          ),
                        ),
                        SizedBox(width: 10),
                        AutoSizeText(
                          'x${cartItem['quantity']}',
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                      ],
                    ),
                    subtitle: AutoSizeText(
                      'PKR ${cartItem['price']} + 150 Delivery Charge',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => removeFromCart(cartItem['id']),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      'Subtotal: PKR ${calculateSubtotal().toStringAsFixed(2)}',
                      style: TextStyle(fontSize: screenWidth * 0.045),
                      maxLines: 1,
                    ),
                    SizedBox(height: 8),
                    AutoSizeText(
                      'Shipping Charges: PKR ${calculateShippingCharges().toStringAsFixed(2)}',
                      style: TextStyle(fontSize: screenWidth * 0.045),
                      maxLines: 1,
                    ),
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    AutoSizeText(
                      'Total: PKR ${calculateTotal().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: placeOrder,
                        child: AutoSizeText(
                          'Checkout',
                          style: TextStyle(fontSize: screenWidth * 0.045),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;

  Iterable get data => nonNulls;
}
