import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'views/auth/login_view.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if token exists
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final bool isLoggedIn = token != null && token.isNotEmpty;

  runApp(CarePulseAdminApp(initialLoggedIn: isLoggedIn));
}

class CarePulseAdminApp extends StatelessWidget {
  final bool initialLoggedIn;

  const CarePulseAdminApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarePulse Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialLoggedIn ? '/main' : '/login',
      routes: {
        '/login': (context) => const MobileLoginView(),
        '/main': (context) => const MainNavigationView(),
        '/dashboard': (context) => const MainNavigationView(initialIndex: 0),
        '/library': (context) => const MainNavigationView(initialIndex: 1),
        '/patients': (context) => const MainNavigationView(initialIndex: 2),
        '/profile': (context) => const MainNavigationView(initialIndex: 3),
      },
    );
  }
}
