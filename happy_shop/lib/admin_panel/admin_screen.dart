import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/orders_screen.dart';
import 'package:happy_shop/admin_panel/product_screen.dart';
import 'package:happy_shop/admin_panel/reviews_screen.dart';
import 'package:happy_shop/admin_panel/users_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _userCount = 0;
  int _orderCount = 0;
  int _completeOrders = 0;
  int _pendingOrders = 0;
  int _totalProducts = 0;
  double _userPercentage = 0.0;
  double _orderPercentage = 0.0;
  double _completedOrdersPercentage = 0.0;
  double _pendingPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchUserCount();
    await fetchOrderCount();
    await fetchCompletedOrders();
    await fetchPendingOrders();
    await fetchTotalProducts();
  }

  Future<void> fetchUserCount() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('id')
        .select('*');

    if (response.error == null) {
      setState(() {
        _userCount = response.data.length;
        _userPercentage = 10.5;
      });
    } else {
      print('Error fetching user count: ${response.error?.message}');
    }
  }

  Future<void> fetchOrderCount() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('id')
        .select('*');

    if (response.error == null) {
      setState(() {
        _orderCount = response.data.length;
        _orderPercentage = 5.0;
      });
    } else {
      print('Error fetching order count: ${response.error?.message}');
    }
  }

  Future<void> fetchCompletedOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('status', 'completed')
        .select('*');

    if (response.error == null) {
      setState(() {
        _completeOrders = response.data.length;
        _completedOrdersPercentage = 7.5;
      });
    } else {
      print('Error fetching completed orders: ${response.error?.message}');
    }
  }

  Future<void> fetchPendingOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('status', 'pending')
        .select('*');

    if (response.error == null) {
      setState(() {
        _pendingOrders = response.data.length;
        _pendingPercentage = 3.0;
      });
    } else {
      print('Error fetching pending orders: ${response.error?.message}');
    }
  }

  Future<void> fetchTotalProducts() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('id')
        .select('*');

    if (response.error == null) {
      setState(() {
        _totalProducts = response.data.length;
      });
    } else {
      print('Error fetching total products: ${response.error?.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Admin Panel'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildCustomDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [

              _buildBox('Total Users', Icons.group, _userCount, _userPercentage, Colors.blue[50]),
              _buildBox('Total Orders', Icons.shopping_cart, _orderCount, _orderPercentage, Colors.orange[50]),
              _buildBox('Completed Orders', Icons.check_circle, _completeOrders, _completedOrdersPercentage, Colors.green[50]),
              _buildBox('Pending Orders', Icons.hourglass_empty, _pendingOrders, _pendingPercentage, Colors.red[50]),
              _buildBox('Total Products', Icons.inventory, _totalProducts, 0.0, Colors.purple[50]), // New box for products
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCustomDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Product'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductsScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Orders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrdersScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Reviews'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReviewsScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsersScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String title, IconData icon, int count, double percentage, Color? color) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                icon,
                size: 24,
                color: color == Colors.blue[50]
                    ? Colors.blue
                    : color == Colors.orange[50]
                    ? Colors.orange
                    : color == Colors.green[50]
                    ? Colors.green
                    : color == Colors.red[50]
                    ? Colors.red
                    : Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4),
          percentage > 0
              ? Text(
            '$percentage% up from past week',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}


extension on PostgrestList {
  get error => null;

  get data => nonNulls;
}
