import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/version_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_update_dialog.dart';
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
  final VersionService _versionService = VersionService();
  bool _isCheckingVersion = true;
  VersionCheckResult? _versionResult;
  bool _hasPromptedOptionalUpdate = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? AuthViewModel();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Check version before login
    final vResult = await _versionService.checkVersion();
    if (!mounted) return;

    setState(() {
      _versionResult = vResult;
      _isCheckingVersion = false;
    });

    // If forced update, stop here and block app
    if (vResult.updateAvailable && vResult.isForced) {
      return;
    }

    // 2. Check user session
    await _viewModel.checkSession();
    if (!mounted) return;

    // 3. If optional update, show non-blocking prompt
    if (vResult.updateAvailable &&
        !vResult.isForced &&
        !_hasPromptedOptionalUpdate) {
      _hasPromptedOptionalUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppUpdateDialog.show(context, result: vResult);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVersion) {
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

    // Blocking screen for mandatory/forced update
    if (_versionResult != null &&
        _versionResult!.updateAvailable &&
        _versionResult!.isForced) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_security_update_rounded,
                      size: 48,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152C5B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Current Version: v${_versionResult!.currentVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_versionResult!.latestVersion.isNotEmpty &&
                            _versionResult!.latestVersion != 'Latest' &&
                            _versionResult!.latestVersion !=
                                _versionResult!.currentVersion) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Required: v${_versionResult!.latestVersion}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _versionResult!.message ??
                        'A major update is required to continue using Meridian Health. Please update your app to the latest version.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Redirecting to store for update...'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Update App Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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

          if (selectedLanguage != null &&
              selectedLanguage.toString().isNotEmpty) {
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
