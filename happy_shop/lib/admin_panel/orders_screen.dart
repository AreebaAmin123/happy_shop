import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/order_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];

  // Orders fetch karna
  Future<void> fetchOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('id, user_id, name, total_amount, status')
        .select('*');

    if (response.error != null) {
      print("Error fetching orders: ${response.error!.message}");
    } else {
      setState(() {
        orders = List<Map<String, dynamic>>.from(response.data);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Orders")),
      body: orders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return ListTile(
            title: Text(order['name'] ?? 'No Product'),
            subtitle: Text('Price: \$${order['total_amount']}'),
            trailing: Text('Status: ${order['status']}',style: TextStyle(
              color: Colors.green
            ),),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(orderId: order['id'],),
                ),
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

  Iterable<PostgrestMap> get data => nonNulls;
}




