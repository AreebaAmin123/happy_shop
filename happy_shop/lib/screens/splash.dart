import 'package:flutter/material.dart';
import 'package:happy_shop/screens/auth.dart';
import 'package:happy_shop/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();


    Future.delayed(Duration(seconds: 3)).then((value) async {
      bool isAuthenticated = await _checkAuthStatus();
      if (isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Auth()),
        );
      }
    });
  }


  Future<bool> _checkAuthStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 270,
          height: 270,
        ),
      ),
    );
  }
}
