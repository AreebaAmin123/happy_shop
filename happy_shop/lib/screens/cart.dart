import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];

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

      if (response.error == null) {
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        print('Error fetching cart items: ${response.error?.message}');
      }
    } else {
      print('No user logged in');
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

    if (orderPlaced) {

      if (user != null) {

        await Supabase.instance.client.from('cart').delete().eq('user_id', user.id);
      }


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: cartItems)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: cartItems.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
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
                        Text(cartItem['name']),
                        Text('x${cartItem['quantity']}'),
                      ],
                    ),
                    subtitle: Text('PKR ${cartItem['price']} + 150 Delivery Charge'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        removeFromCart(cartItem['id']);
                      },
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
                    Text('Subtotal: PKR ${calculateSubtotal()}',
                        style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('Shipping Charges: PKR ${calculateShippingCharges()}',
                        style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    Text('Total: PKR ${calculateTotal()}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        placeOrder();
                      },
                      child: Text('Checkout'),
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
