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


  Future<void> fetchDeletedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedOrders = prefs.getStringList('deletedOrders') ?? [];
    setState(() {
      deletedOrderIds = Set<int>.from(deletedOrders.map((e) => int.parse(e)));
    });
  }


  Future<void> saveDeletedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedOrders = deletedOrderIds.map((e) => e.toString()).toList();
    await prefs.setStringList('deletedOrders', deletedOrders);
  }


  Future<void> fetchOrders() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('orders')
          .select('*')
          .eq('user_id', user.id);

      if (response.error == null) {
        setState(() {
          orders = List<dynamic>.from(response.data)
              .where((order) => !deletedOrderIds.contains(order['id']))
              .toList();
          isLoading = false;
        });
      } else {
        print("Error fetching orders: ${response.error?.message}");
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  void removeOrder(int orderIndex) async {
    var orderId = orders[orderIndex]['id'];


    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Order"),
          content: Text("Are you sure you want to delete this order?",),
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

        deletedOrderIds.add(orderId);
        orders.removeAt(orderIndex);
      });
      saveDeletedOrderIds();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order deleted successfully.')),
      );
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
          ? Center(child: Text('Your orders screen is Empty',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 25,
        color: Colors.red
      ),))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, orderIndex) {
          var order = orders[orderIndex];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                'Order ID: ${order['id']}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('City: ${order['city']}'),
                  Text('Address: ${order['complete_address']}'),
                  Text('Order Date: ${order['order_date']}'),
                  Text(
                    'Cash on Delivery: ${order['cash_on_delivery'] == null ?
                    'Yes' : (order['cash_on_delivery'] ? 'Yes' : 'No')}',
                  ),
                  Text(
                    'Status: ${order['status']}',
                    style: TextStyle(color: Colors.green),
                  ),

                  Text('Cart Items:'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      order['cart_items'].length,
                          (cartItemIndex) {
                        var item = order['cart_items'][cartItemIndex];
                        return ListTile(
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
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  removeOrder(orderIndex);
                },
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
