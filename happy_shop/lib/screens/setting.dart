import 'package:flutter/material.dart';
import 'package:happy_shop/screens/auth.dart';
import 'package:happy_shop/screens/cart.dart';
import 'package:happy_shop/screens/favourite.dart';
import 'package:happy_shop/screens/orders_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    setState(() {
      _user = user;
    });
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
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    ) ?? false;

    if (shouldLogout) {
      try {
        await supabase.auth.signOut();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => Auth()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        print('Error logging out: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String firstLetter = _user!.email![0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  firstLetter,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _user!.email!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InfoBox(label: 'Email', value: _user!.email!),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InfoBox(label: 'Country', value: 'Pakistan'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InfoBox(label: 'Language', value: 'English'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InfoBox(label: 'Currency', value: 'PKR'),
              ),

              SizedBox(height: 32),
              _navigationBox(context, 'Favourites', FavouriteScreen()),
              _navigationBox(context, 'Cart', CartScreen()),
              _navigationBox(context, 'Orders', OrdersScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigationBox(BuildContext context, String label, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  final String label;
  final String value;

  InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

