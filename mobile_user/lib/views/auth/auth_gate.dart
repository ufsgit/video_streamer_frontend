import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../navigation/main_navigation_view.dart';
import 'language_selection_dialog.dart';
import 'login_view.dart';

class AuthGate extends StatefulWidget {
  final AuthViewModel? viewModel;

  const AuthGate({super.key, this.viewModel});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? AuthViewModel();
    _viewModel.checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isCheckingSession) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: 80, iconSize: 42),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: Color(0xFF5B67F6),
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          );
        }

        if (_viewModel.isAuthenticated) {
          final box = Hive.box('settings');
          final selectedLanguage = box.get('selected_language');
          
          if (selectedLanguage != null && selectedLanguage.toString().isNotEmpty) {
            return const MainNavigationView();
          } else {
            // Need to select language
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => LanguageSelectionDialog(
                  languages: _viewModel.currentUser?.languages,
                ),
              );
            });
            // Return empty scaffold while dialog is shown
            return const Scaffold(backgroundColor: Color(0xFFF7F9FC));
          }
        }

        return LoginView(viewModel: _viewModel);
      },
    );
  }
}
