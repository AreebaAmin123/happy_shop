import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailScreen extends StatefulWidget {
  final dynamic order;

  OrderDetailScreen({required this.order});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late dynamic _order;
  late TextEditingController _statusController;
  late TextEditingController _paymentStatusController;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _statusController = TextEditingController(text: _order['status']);
    _paymentStatusController = TextEditingController(text: _order['payment_status']);
  }

  Future<void> _updateOrderStatus() async {
    String newStatus = _statusController.text;
    String newPaymentStatus = newStatus == 'Complete' ? 'Complete' : _paymentStatusController.text;

    final response = await _supabase
        .from('orders')
        .update({
      'status': newStatus,
      'payment_status': newPaymentStatus,
    })
        .eq('id', _order['id'])
        .select('*');

    if (response.error == null) {
      setState(() {
        _order['status'] = newStatus;
        _order['payment_status'] = newPaymentStatus;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order updated successfully')));
    } else {
      // Handle error
      print("Error updating order: ${response.error?.message}");
    }
  }

  Future<void> _cancelOrder() async {
    final response = await _supabase
        .from('orders')
        .update({
      'status': 'Cancelled',
      'payment_status': 'Cancelled',
    })
        .eq('id', _order['id'])
        .select('*');

    if (response.error == null) {
      setState(() {
        _order['status'] = 'Cancelled';
        _order['payment_status'] = 'Cancelled';
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order cancelled successfully')));
    } else {
      // Handle error
      print("Error cancelling order: ${response.error?.message}");
    }
  }

  void _showStatusSelection(String type) {
    List<String> options = ['Pending', 'Completed', 'Cancelled'];
    String selectedValue = type == 'status' ? _statusController.text : _paymentStatusController.text;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: options.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(options[index]),
              onTap: () {
                setState(() {
                  if (type == 'status') {
                    _statusController.text = options[index];
                  } else {
                    _paymentStatusController.text = options[index];
                  }
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_order['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Phone: ${_order['phone_number']}'),
            Text('Address: ${_order['complete_address']}'),
            Text('Cart Items: ${_order['cart_items']}'),
            Text('Total Amount: \$${_order['total_amount']}'),
            GestureDetector(
              onTap: () => _showStatusSelection('status'),
              child: AbsorbPointer(
                child: TextField(
                  controller: _statusController,
                  decoration: InputDecoration(labelText: 'Status'),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showStatusSelection('payment_status'),
              child: AbsorbPointer(
                child: TextField(
                  controller: _paymentStatusController,
                  decoration: InputDecoration(labelText: 'Payment Status'),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateOrderStatus,
              child: Text('Update Order'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _cancelOrder,
              child: Text('Cancel Order',
              style: TextStyle(
                color: Colors.white
              ),),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;

  get data => nonNulls;
}

