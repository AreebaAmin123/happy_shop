import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {

  List<Map<String, dynamic>> users = [];


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
          return ListTile(
            title: Text(user['email'] ?? 'No Email'),
            subtitle: Text('Role: ${user['role']}'),
            trailing: Text('ID: ${user['id']}'),
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
