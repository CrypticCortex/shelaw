import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelaw/app_colors.dart';
import 'auth_services.dart';
import 'screens/auth_page.dart';
import 'screens/chat_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SheLAWApp());
}

class SheLAWApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SheLAW',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.lightPink,
        hintColor: AppColors.deepPurple,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightPink),
          bodyMedium: TextStyle(color: AppColors.darkPurple),
        ),
      ),
      home: SplashScreen(), // Start with the splash screen
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _checkLoginStatus(context);
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splash.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Future.delayed(Duration(seconds: 2), () {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatListPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    });
  }
}
