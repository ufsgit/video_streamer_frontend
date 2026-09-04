import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'views/auth/login_view.dart';
import 'views/patient_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static int _indexFromRoute(String? routeName) {
    final name = (routeName ?? '').toLowerCase();
    if (name.contains('library')) return 1;
    if (name.contains('patient')) return 2;
    if (name.contains('profile')) return 3;
    return 0;
  }

  static String _getInitialRoute() {
    final fragment = Uri.base.fragment;
    final path = Uri.base.path;
    if (fragment.isNotEmpty) {
      return fragment.startsWith('/') ? fragment : '/$fragment';
    }
    if (path.isNotEmpty && path != '/' && path != '/login') {
      return path;
    }
    return '/login';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarePulse Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: _getInitialRoute(),
      onGenerateRoute: (settings) {
        final name = (settings.name ?? '').toLowerCase();
        if (name == '/' || name == '/login' || name.contains('login')) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginView(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }

        final index = _indexFromRoute(settings.name);
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PatientLayout(initialIndex: index),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}
