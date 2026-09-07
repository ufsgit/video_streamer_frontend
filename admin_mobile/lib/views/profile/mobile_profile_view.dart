import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../auth/mobile_login_view.dart';

class MobileProfileView extends StatefulWidget {
  const MobileProfileView({super.key});

  @override
  State<MobileProfileView> createState() => _MobileProfileViewState();
}

class _MobileProfileViewState extends State<MobileProfileView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userProfile = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out from the Admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.clearAuthToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MobileLoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Profile Header Card
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: AppTheme.cardBg,
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 54,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userProfile?['username'] ?? _userProfile?['name'] ?? 'Admin User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userProfile?['email'] ?? 'admin@carestream.local',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        (_userProfile?['role'] ?? 'ADMINISTRATOR').toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Settings / Info Section
                    _buildSectionHeader('Account & System'),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Role & Permissions',
                      subtitle: 'Full Administrator Access',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Push Notifications',
                      subtitle: 'Alerts on patient video completion',
                      trailing: Switch(
                        value: true,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) {},
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.cloud_outlined,
                      title: 'Server Sync Status',
                      subtitle: 'Connected (Online)',
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Application Info'),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: 'v1.0.0 (Admin Mobile Suite)',
                    ),
                    _buildSettingsTile(
                      icon: Icons.support_agent_rounded,
                      title: 'CareStream Support',
                      subtitle: 'Documentation & Technical Help',
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                          foregroundColor: AppTheme.error,
                          elevation: 0,
                          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              )
            : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted) : null),
      ),
    );
  }
}
