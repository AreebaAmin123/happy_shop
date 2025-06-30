import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/order_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final response = await _supabase.from('orders').select().select('*');

    if (response.error == null) {
      setState(() {
        _orders = List.from(response.data);
        _filteredOrders = _orders;
      });
    } else {
      print("Error fetching orders: ${response.error?.message}");
    }
  }

  void _filterAllOrders() {
    setState(() {
      _selectedStatus = 'All';
      _filteredOrders = _orders;
    });
  }

  void _filterPendingOrders() {
    setState(() {
      _selectedStatus = 'Pending';
      _filteredOrders = _orders.where((order) {
        return order['status'] != null && order['status'].toString().toLowerCase() == 'pending'.toLowerCase();
      }).toList();

      if (_filteredOrders.isEmpty) {
        _showErrorMessage('No Pending orders found.');
      }
    });
  }

  void _filterCompletedOrders() {
    setState(() {
      _selectedStatus = 'Completed';
      _filteredOrders = _orders.where((order) {
        return order['status'] != null && order['status'].toString().toLowerCase() == 'completed'.toLowerCase();
      }).toList();

      if (_filteredOrders.isEmpty) {
        _showErrorMessage('No Completed orders found.');
      }
    });

    _sendEmailNotificationToUser('completed');
  }

  void _filterCanceledOrders() {
    setState(() {
      _selectedStatus = 'Cancelled';
      _filteredOrders = _orders.where((order) {
        return order['status'] != null && order['status'].toString().toLowerCase() == 'cancelled'.toLowerCase();
      }).toList();

      if (_filteredOrders.isEmpty) {
        _showErrorMessage('No Cancelled orders found.');
      }
    });

    _sendEmailNotificationToUser('cancelled');
  }


  Future<void> _sendEmailNotificationToUser(String status) async {

    for (var order in _filteredOrders) {
      final userResponse = await _supabase
          .from('users')
          .select('email')
          .eq('id', order['user_id'])
          .single();

      if (userResponse.error == null) {
        final userEmail = userResponse.data['email'];


        await _sendEmail(userEmail, status, order);
      } else {
        print("Error fetching user email: ${userResponse.error?.message}");
      }
    }
  }

  Future<void> _sendEmail(String userEmail, String status, dynamic order) async {

    final response = await _supabase.rpc('send_order_status_email', params: {
      'email': userEmail,
      'status': status,
      'order_id': order['id'],
    });

    if (response.error != null) {
      print("Error sending email: ${response.error?.message}");
    } else {
      print("Email sent to $userEmail about order status: $status");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Text(
              "Orders",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 8),
            Text(
              '(${_filteredOrders.length})',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryBox('All Orders', _filterAllOrders),
                _buildCategoryBox('Pending', _filterPendingOrders),
                _buildCategoryBox('Completed', _filterCompletedOrders),
                _buildCategoryBox('Canceled', _filterCanceledOrders),
              ],
            ),
          ),
          _filteredOrders.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: ListTile(
                    title: Text(order['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${order['phone_number']}"),
                        Text("Status: ${order['status']}"),
                      ],
                    ),
                    trailing: Text("\$${order['total_amount']}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBox(String category, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: _selectedStatus == category ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            category,
            style: TextStyle(
              color: _selectedStatus == category ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

extension on PostgrestMap {
  get error => null;

  get data => null;
}

extension on PostgrestList {
  get error => null;

  Iterable<PostgrestMap> get data => nonNulls;
}




