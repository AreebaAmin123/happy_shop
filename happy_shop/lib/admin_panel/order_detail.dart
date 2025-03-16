import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  dynamic order;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }


  Future<void> fetchOrderDetails() async {
    try {
      final response = await supabase
          .from('orders')
          .select('*')
          .eq('id', widget.orderId)
          .select('*');
      if (response.error != null) {
        throw response.error!.message;
      }

      if (response.data == null || response.data.isEmpty) {
        throw 'Order not found';
      }

      setState(() {
        order = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text('Error: $errorMessage', style: TextStyle(color: Colors.red)))
          : order == null
          ? Center(child: Text('Order not found'))
          : Card(
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
                'Cash on Delivery: ${order['cash_on_delivery'] == null ? 'Yes' : (order['cash_on_delivery'] ? 'Yes' : 'No')}',
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
              Text('Delivery Charges: 250'),
              Text(
                'Total Amount: ${order['total_amount']}',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;

  get data => nonNulls;
}

