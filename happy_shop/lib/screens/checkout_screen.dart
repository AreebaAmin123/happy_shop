import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:happy_shop/screens/order_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CheckoutScreen({required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phoneNumber = '';
  String country = '';
  String city = '';
  String completeAddress = '';
  bool isCashOnDelivery = false;
  bool isLoading = false;
  List<String> countries = ['USA', 'India', 'Canada', 'Pakistan', 'London'];
  List<String> cities = [];
  bool isCountrySelected = false;

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {

      if (country.isEmpty || city.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both country and city')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
      final cartItems = widget.cartItems;

      double totalAmount = 0;
      for (var item in cartItems) {
        totalAmount += item['price'] * item['quantity'];
      }
      var deliveryCharge = cartItems.length * 150;
      totalAmount += deliveryCharge;

      if (user != null) {
        try {
          final formattedCartItems = cartItems.map((item) {
            return {
              'item_name': item['name'],
              'item_price': item['price'],
              'item_quantity': item['quantity'],
              'item_size': item['size'],
              'item_color': item['color'],
            };
          }).toList();

          final response = await Supabase.instance.client.from('orders').insert([
            {
              'user_id': user.id,
              'name': name,
              'phone_number': phoneNumber,
              'country': country,
              'city': city,
              'complete_address': completeAddress,
              'is_cash_on_delivery': isCashOnDelivery,
              'order_date': DateTime.now().toIso8601String(),
              'cart_items': formattedCartItems,
              'status': 'pending',
              'total_amount': totalAmount,
            }
          ]);

          if (response == null) {
            print("Order placed successfully");

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderScreen(),
              ),
            );
          } else {
            print('Error: ${response.error?.message}');
          }
        } catch (e) {
          print('Error: $e');
        }
      } else {
        print('User is not authenticated');
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void placeOrder() async {

    bool orderPlaced = true;

    if (orderPlaced) {

      setState(() {
        var cartItems;
        cartItems.clear();
      });

      var cartItems;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: cartItems,)),
      );
    }
  }

  Future<void> _selectCountry() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: countries.map((countryName) {
            return ListTile(
              title: Text(countryName),
              onTap: () {
                setState(() {
                  country = countryName;
                  isCountrySelected = true;
                  cities = _getCitiesBasedOnCountry(countryName);
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  List<String> _getCitiesBasedOnCountry(String countryName) {
    if (countryName == 'USA') return ['New York', 'Los Angeles', 'Chicago'];
    if (countryName == 'India') return ['Mumbai', 'Delhi', 'Bangalore'];
    if (countryName == 'Canada') return ['Toronto', 'Vancouver', 'Montreal'];
    if (countryName == 'Pakistan') return ['Lahore', 'Karachi', 'Islamabad'];
    if (countryName == 'London') return ['Greenwich', 'Islington', 'Bromley'];
    return [];
  }

  Future<void> _selectCity() async {
    if (!isCountrySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a country first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: cities.map((cityName) {
            return ListTile(
              title: Text(cityName),
              onTap: () {
                setState(() {
                  city = cityName;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Name:'),
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter your name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  name = value;
                },
              ),
              SizedBox(height: 16),
              Text('Phone Number:'),
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter your phone number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 11) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
                onChanged: (value) {
                  phoneNumber = value;
                },
              ),
              SizedBox(height: 16),
              Text('Country:'),
              GestureDetector(
                onTap: _selectCountry,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(country.isEmpty ? 'Select country' : country),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('City:'),
              GestureDetector(
                onTap: _selectCity,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(city.isEmpty ? 'Select city' : city),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Complete Address:'),
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter your complete address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
                onChanged: (value) {
                  completeAddress = value;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isCashOnDelivery,
                    onChanged: (value) {
                      setState(() {
                        isCashOnDelivery = value!;
                      });
                    },
                  ),
                  Text('Cash on Delivery'),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
