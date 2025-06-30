import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> orders = [];
  bool isLoadingOrders = false;


  Future<void> fetchUsers() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('id, email, role')
        .select('*');

    if (response.error != null) {
      print("Error fetching data: ${response.error!.message}");
    } else {
      setState(() {
        users = List<Map<String, dynamic>>.from(response.data);
      });
    }
  }

  Future<void> fetchUserOrders(String userId) async {
    setState(() {
      isLoadingOrders = true;
    });

    final response = await Supabase.instance.client
        .from('orders')
        .select('*')
        .eq('user_id', userId);

    if (response.error != null) {
      print("Error fetching orders: ${response.error!.message}");
    } else {
      setState(() {
        orders = List<Map<String, dynamic>>.from(response.data);
        isLoadingOrders = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Users")),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final email = user['email'] ?? 'No Email';
          final role = user['role'] ?? 'No Role';
          final firstLetter = email.isNotEmpty ? email[0].toUpperCase() : '';

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                firstLetter,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(email),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Role: $role'),
              ],
            ),
            onTap: () async {

              String userId = user['id'];
              await fetchUserOrders(userId);


              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Orders for $email'),
                    content: isLoadingOrders
                        ? Center(child: CircularProgressIndicator())
                        : orders.isEmpty
                        ? Text('No orders found.')
                        : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: orders.map((order) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Name: ${order['name']}'),
                                    Text('Order Date: ${order['order_date']}'),
                                    Text('Status: ${order['status']}'),
                                    Text('Payment Status: ${order['payment_status']}'),
                                    Text('Phone: ${order['phone_number']}'),
                                    Text('Address: ${order['complete_address']}'),
                                    Text('Items: ${order['cart_items']}'),
                                    Text('Delivery Charges: ${order['delivery_charges']}'),
                                    Text('Total Amount: ${order['total_amount']}'),
                                  ],

                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
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
