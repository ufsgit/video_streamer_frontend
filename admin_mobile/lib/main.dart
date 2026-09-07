import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'views/auth/mobile_login_view.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations & system overlay style
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.cardBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AdminMobileApp());
}

class AdminMobileApp extends StatefulWidget {
  const AdminMobileApp({super.key});

  @override
  State<AdminMobileApp> createState() => _AdminMobileAppState();
}

class _AdminMobileAppState extends State<AdminMobileApp> {
  final ApiService _apiService = ApiService();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _apiService.getAuthToken();
    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareStream Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: _isCheckingAuth
          ? const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
              ),
            )
          : (_isAuthenticated ? const MainNavigationView() : const MobileLoginView()),
      routes: {
        '/login': (context) => const MobileLoginView(),
        '/main': (context) => const MainNavigationView(),
      },
    );
  }
}
