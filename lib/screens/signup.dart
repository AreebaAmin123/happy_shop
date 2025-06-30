import 'package:flutter/material.dart';
import 'package:happy_shop/screens/home_screen.dart';
import 'package:happy_shop/screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailCon = TextEditingController();
  final TextEditingController passwordCon = TextEditingController();
  bool _obscureText = true;

  void signup() async {
    if (!formKey.currentState!.validate()) return;
    try {
      SmartDialog.showLoading();
      final response = await Supabase.instance.client.auth.signUp(
        email: emailCon.text.trim(),
        password: passwordCon.text,
      );
      SmartDialog.dismiss();
      if (response.user == null) throw 'User is null';

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint('Error in sign up => $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sign In Text
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 80),

                // Email Text Field
                TextFormField(
                  controller: emailCon,
                  validator: (txt) {
                    if (txt == null || txt.isEmpty) return 'Email is required';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Password Text Field
                TextFormField(
                  controller: passwordCon,
                  validator: (txt) {
                    if (txt == null || txt.isEmpty) return 'Password is required';
                    return null;
                  },
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                ElevatedButton(
                  onPressed: signup,
                  child: const Text(
                    'Signup',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB03FE8),
                    minimumSize: Size(double.infinity, 55),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Forget Password ?  ',
                      style: TextStyle(
                          fontSize: 16
                      ),),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

