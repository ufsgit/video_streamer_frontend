import 'package:flutter/material.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../auth/login_view.dart';

class ProfileView extends StatefulWidget {
  final ProfileViewModel? viewModel;

  const ProfileView({super.key, this.viewModel});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? ProfileViewModel();
    _viewModel.loadProfile();
  }

  void _onLogout() async {
    await _viewModel.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final user = _viewModel.user;
        final name = user?.name.isNotEmpty == true ? user!.name : 'John Doe';
        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar (Profile Title + Settings Icon)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF152C5B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF152C5B),
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // User Header Banner Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top Blue Gradient Banner
                        Container(
                          height: 80,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              colors: [Color(0xFF4A80F0), Color(0xFF7A68EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),

                        // White Card Body with Avatar Overlap
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -32),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF4FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials.isNotEmpty ? initials : 'JD',
                                          style: const TextStyle(
                                            color: Color(0xFF0052CC),
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Transform.translate(
                                offset: const Offset(0, -20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          user?.memberSince.isNotEmpty == true
                                              ? 'Member since ${user!.memberSince}'
                                              : 'Member since Jan 2023',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 12,
                                                color: Color(0xFF027A48),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF027A48),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0F4FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: Color(0xFF0052CC),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user?.platformTime.isNotEmpty == true
                                    ? user!.platformTime
                                    : '12h 45m',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ON PLATFORM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF667085),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: const Color(0xFFF2F4F7),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4F3FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Color(0xFF5B61F6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user != null ? '${user.videosDone}' : '42',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'VIDEOS DONE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF667085),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: const Color(0xFFF2F4F7),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF6ED),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: Color(0xFFFB6514),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user != null ? '${user.streakDays} days' : '5 days',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'STREAK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF667085),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header: YOUR DOCTOR
                  const Text(
                    'YOUR DOCTOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF667085),
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Doctor Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D3B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dr. Sarah Jenkins',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF101828),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Senior physiotherapist',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF98A2B3),
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header: ACCOUNT SETTINGS
                  const Text(
                    'ACCOUNT SETTINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF667085),
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Settings Options Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal information',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFF2F4F7)),
                        _buildSettingsTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notification settings',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFF2F4F7)),
                        _buildSettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & support',
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: Color(0xFFF2F4F7)),
                        _buildSettingsTile(
                          icon: Icons.logout_rounded,
                          title: 'Log out',
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          onTap: _onLogout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF0052CC),
    Color textColor = const Color(0xFF101828),
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF98A2B3),
        size: 22,
      ),
    );
  }
}
