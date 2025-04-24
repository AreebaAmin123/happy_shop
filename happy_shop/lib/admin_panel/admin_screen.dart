import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/categories.dart';
import 'package:happy_shop/admin_panel/orders_screen.dart';
import 'package:happy_shop/admin_panel/product_screen.dart';
import 'package:happy_shop/admin_panel/rating_screen.dart';
import 'package:happy_shop/admin_panel/users_screen.dart';
import 'package:happy_shop/screens/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _userCount = 0;
  int _orderCount = 0;
  int _CompleteOrders = 0;
  int _PendingOrders = 0;
  int _CancelledOrders = 0;
  int _totalProducts = 0;
  double _userPercentage = 0.0;
  double _orderPercentage = 0.0;
  double _CompletedOrdersPercentage = 0.0;
  double _PendingPercentage = 0.0;
  double _CancelledPercentage = 0.0;

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
    await fetchCancelledOrders();
    await fetchTotalProducts();
  }

  Future<void> fetchUserCount() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('*');

    if (response != null) {
      setState(() {
        _userCount = response.length;
        _userPercentage = (_userCount > 0) ? 15.0 : 0.0;
      });
    }
  }

  Future<void> fetchOrderCount() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('*');

    if (response != null) {
      setState(() {
        _orderCount = response.length;
        _orderPercentage = (_orderCount > 0) ? 10.0 : 0.0;
      });
    }
  }

  Future<void> fetchCompletedOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('*')
        .eq('status', 'Completed');

    if (response != null) {
      setState(() {
        _CompleteOrders = response.length;
        _CompletedOrdersPercentage =
        (_orderCount > 0) ? (_CompleteOrders / _orderCount) * 100 : 0.0;
      });
    }
  }

  Future<void> fetchPendingOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('*')
        .eq('status', 'Pending');

    if (response != null) {
      setState(() {
        _PendingOrders = response.length;
        _PendingPercentage =
        (_orderCount > 0) ? (_PendingOrders / _orderCount) * 100 : 0.0;
      });
    }
  }

  Future<void> fetchCancelledOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select('*')
        .eq('status', 'Cancelled');

    if (response != null) {
      setState(() {
        _CancelledOrders = response.length;
        _CancelledPercentage =
        (_orderCount > 0) ? (_CancelledOrders / _orderCount) * 100 : 0.0;
      });
    }
  }

  Future<void> fetchTotalProducts() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('*');

    if (response != null) {
      setState(() {
        _totalProducts = response.length;
      });
    }
  }

  Future<void> _logout() async {
    bool shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you really want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    ) ??
        false;

    if (shouldLogout) {
      try {
        await Supabase.instance.client.auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Auth()),
              (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
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
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildCustomDrawer(context),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                _buildBox('Total Users', Icons.group, _userCount,
                    _userPercentage, Colors.blue[50]),
                _buildBox('Total Orders', Icons.shopping_cart, _orderCount,
                    _orderPercentage, Colors.orange[50]),
                _buildBox('Completed Orders', Icons.check_circle,
                    _CompleteOrders, _CompletedOrdersPercentage, Colors.green[50]),
                _buildBox('Pending Orders', Icons.hourglass_empty,
                    _PendingOrders, _PendingPercentage, Colors.red[50]),
                _buildBox('Cancelled Orders', Icons.cancel, _CancelledOrders,
                    _CancelledPercentage, Colors.red[50]),
                _buildBox('Total Products', Icons.inventory, _totalProducts, 0.0,
                    Colors.purple[50]),
              ],
            ),
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
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('Product'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductsScreen()),
              ),
            ),
            ListTile(
              title: Text('Orders'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrdersScreen()),
              ),
            ),
            ListTile(
              title: Text('Categories'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoriesScreen()),
              ),
            ),
            ListTile(
              title: Text('Users'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersScreen()),
              ),
            ),
            ListTile(
              title: Text('Rating'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RatingScreen()),
              ),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(
      String title, IconData icon, int count, double percentage, Color? color) {
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 12, color: Colors.green),
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
