import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> orders = [];
  Set<int> deletedOrderIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDeletedOrderIds();
    fetchOrders();
  }

  // Fetch the IDs of deleted orders from SharedPreferences
  Future<void> fetchDeletedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedOrders = prefs.getStringList('deletedOrders') ?? [];
    setState(() {
      deletedOrderIds = Set<int>.from(deletedOrders.map((e) => int.parse(e)));
    });
  }

  // Save the deleted order IDs to SharedPreferences
  Future<void> saveDeletedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedOrders = deletedOrderIds.map((e) => e.toString()).toList();
    await prefs.setStringList('deletedOrders', deletedOrders);
  }

  // Fetch orders from Supabase and exclude deleted orders
  Future<void> fetchOrders() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase
            .from('orders')
            .select('*')
            .eq('user_id', user.id);

        setState(() {
          orders = List<dynamic>.from(data)
              .where((order) => !deletedOrderIds.contains(order['id']))
              .toList();
          isLoading = false;
        });
      } catch (error) {
        print("Error fetching orders: $error");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Delete order from the list and save the deletion
  Future<void> deleteOrderFromUserView(int orderId, int orderIndex) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Order"),
          content: Text("Are you sure you want to delete this order from your view?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        deletedOrderIds.add(orderId); // Add to the deleted set
        orders.removeAt(orderIndex); // Remove from the current view
      });
      await saveDeletedOrderIds(); // Save the deletion to SharedPreferences

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order deleted from your view.')),
      );
    }
  }

  // Cancel an order by updating its status in Supabase
  Future<void> cancelOrder(int orderId, int orderIndex) async {
    bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cancel Order"),
          content: Text("Are you sure you want to cancel this order?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirmCancel == true) {
      final response = await supabase
          .from('orders')
          .update({
        'status': 'Cancelled',
        'payment_status': 'Cancelled',
      })
          .eq('id', orderId);

      if (response.error == null) {
        setState(() {
          orders[orderIndex]['status'] = 'Cancelled';
          orders[orderIndex]['payment_status'] = 'Cancelled';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully.')),
        );
      } else {
        print("Error cancelling order: ${response.error?.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
        child: Text(
          'Your orders screen is Empty',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.red,
          ),
        ),
      )
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, orderIndex) {
          var order = orders[orderIndex];
          return Dismissible(
            key: ValueKey(order['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              color: Colors.red,
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            confirmDismiss: (direction) async {
              await deleteOrderFromUserView(order['id'], orderIndex);
              return false; // Return false to prevent the Dismissible from removing the item
            },
            child: Card(
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${order['name'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text('Phone Number: ${order['phone_number'] ?? 'N/A'}'),
                          SizedBox(height: 5),
                          Text('City: ${order['city']}'),
                          Text('Address: ${order['complete_address']}'),
                          Text('Order Date: ${order['order_date']}'),
                          Text(
                            'Cash on Delivery: ${order['cash_on_delivery'] == null ? 'Yes' : (order['cash_on_delivery'] ? 'Yes' : 'No')}',
                          ),
                          Text(
                            'Status: ${order['status']}',
                            style: TextStyle(
                              color: order['status'] == 'Cancelled'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text('Cart Items:'),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              order['cart_items'].length,
                                  (cartItemIndex) {
                                var item = order['cart_items'][cartItemIndex];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Product: ${item['item_name']} | Quantity: ${item['item_quantity']} '
                                        '| Size: ${item['item_size']} | Color: ${item['item_color']} '
                                        '| Price: ${item['item_price']} ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                          Text('Delivery Charges: 150'),
                          Text(
                            'Total Amount: ${order['total_amount']}',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.center,
                      child: order['status'] != 'Cancelled'
                          ? TextButton(
                        onPressed: () => cancelOrder(order['id'], orderIndex),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                          : Text(
                        'Cancelled',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
  get error => nonNulls;

  Iterable get data => nonNulls;
}
