import 'package:flutter/material.dart';
import 'package:happy_shop/admin_panel/admin_screen.dart';
import 'package:happy_shop/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  State<Auth> createState() => AuthState();
}

class AuthState extends State<Auth> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailCon = TextEditingController();
  final TextEditingController passwordCon = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  void _checkUserAuth() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email';
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 6) return 'Password should be at least 6 characters';
    return null;
  }


  final String adminEmail = 'aqsaaminswl123@gmail.com';

  void signup() async {
    if (!formKey.currentState!.validate()) return;

    try {
      SmartDialog.showLoading();
      final response = await Supabase.instance.client.auth.signUp(
        email: emailCon.text.trim(),
        password: passwordCon.text,
      );

      SmartDialog.dismiss();

      if (response.error != null) {
        throw response.error!.message;
      }

      if (response.user == null) {
        throw 'User is null';
      }

      await _saveUserData(response.user!);


      if (response.user!.email == adminEmail) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => AdminPanelScreen()),
              (Route<dynamic> route) => false,
        );
      } else {

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint('Error in sign up => $e');
      SmartDialog.showToast('Error: $e');
    }
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      SmartDialog.showLoading();
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailCon.text.trim(),
        password: passwordCon.text,
      );
      SmartDialog.dismiss();

      if (response.error != null) {
        throw response.error!.message;
      }

      if (response.user == null) {
        throw 'User is null';
      }

      await _saveUserData(response.user!);

      if (response.user!.email == adminEmail) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => AdminPanelScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint('Error in login => $e');
      SmartDialog.showToast('Error: $e');
    }
  }

  Future<void> _saveUserData(User user) async {
    try {
      final response = await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
      }).execute();

      if (response.error != null) {
        throw response.error!.message;
      }
    } catch (e) {
      debugPrint('Error saving user data => $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email Text Field
                TextFormField(
                  controller: emailCon,
                  validator: emailValidator,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: passwordCon,
                  validator: passwordValidator,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: signup,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


extension on AuthResponse {
  get error => null;
}

extension on PostgrestFilterBuilder {
  execute() {}
}


