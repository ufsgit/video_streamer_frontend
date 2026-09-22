import 'package:flutter/material.dart';
import 'package:admin_mobile/core/theme.dart';
import 'package:admin_mobile/viewmodels/dashboard_viewmodel.dart';
import 'package:admin_mobile/widgets/app_logo.dart';

class MobileDashboardView extends StatefulWidget {
  const MobileDashboardView({super.key});

  @override
  State<MobileDashboardView> createState() => _MobileDashboardViewState();
}

class _MobileDashboardViewState extends State<MobileDashboardView> {
  final DashboardViewModel _viewModel = DashboardViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _viewModel.totalUsers > 0
        ? _viewModel.totalUsers
        : _viewModel.totalLogins;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            const AppLogo(
              size: 32,
              backgroundColor: Colors.white,
              hasShadow: true,
              isSquircle: true,
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primary),
            onPressed: _viewModel.isLoading ? null : _viewModel.refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _viewModel.refreshData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Row(
                children: [
                  const Text(
                    'Activity & Clinical Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emeraldBorder),
                    ),
                    child: const Text(
                      "Live",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time monitoring of patient engagement and video usage.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Metric Cards Grid with subtle colors
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Total Patients",
                      value: displayedUsers.toString(),
                      icon: Icons.people_alt_rounded,
                      iconBgColor: AppTheme.blueBg,
                      iconColor: AppTheme.blue,
                      borderColor: AppTheme.blueBorder,
                      cardBg: AppTheme.blueCardBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Avg. Videos",
                      value: _viewModel.avgVideosWatched.toStringAsFixed(1),
                      icon: Icons.play_circle_fill_rounded,
                      iconBgColor: AppTheme.purpleBg,
                      iconColor: AppTheme.purple,
                      borderColor: AppTheme.purpleBorder,
                      cardBg: AppTheme.purpleCardBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                title: "Completion Rate",
                value: "${_viewModel.completionRate}%",
                icon: Icons.check_circle_rounded,
                iconBgColor: AppTheme.emeraldBg,
                iconColor: AppTheme.emerald,
                borderColor: AppTheme.emeraldBorder,
                cardBg: AppTheme.emeraldCardBg,
                isFullWidth: true,
              ),
              const SizedBox(height: 20),

              // Activity Logs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Patient Activity",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.blueBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.blueBorder),
                    ),
                    child: Text(
                      "${_viewModel.activityLogs.length} events",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blueText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Activity Logs List
              if (_viewModel.isLoading && _viewModel.activityLogs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36.0),
                    child: AppLogoLoader(
                      size: 48,
                      message: "Loading dashboard activity...",
                    ),
                  ),
                )
              else if (_viewModel.activityLogs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text(
                      "No recent activity logged",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textPrimary.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _viewModel.activityLogs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppTheme.borderSubtle, height: 1),
                    itemBuilder: (context, index) {
                      final log = _viewModel.activityLogs[index];
                      final avatarColor = AppTheme.getAvatarPalette(log.patientName);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: avatarColor['bg'],
                              radius: 18,
                              child: Text(
                                log.patientName.isNotEmpty
                                    ? log.patientName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  color: avatarColor['fg'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          log.patientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: log.progressPercentage == 100
                                              ? AppTheme.emeraldBg
                                              : AppTheme.blueBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${log.progressPercentage}%",
                                          style: TextStyle(
                                            color: log.progressPercentage == 100
                                                ? AppTheme.emeraldText
                                                : AppTheme.blueText,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.ward.isNotEmpty &&
                                            log.ward.toLowerCase() !=
                                                'general ward'
                                        ? "${log.ward} • ${log.lastLogin}"
                                        : log.lastLogin,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (log.progressPercentage / 100)
                                          .clamp(0.0, 1.0),
                                      minHeight: 4,
                                      backgroundColor: AppTheme.border,
                                      color: log.progressPercentage == 100
                                          ? AppTheme.emerald
                                          : AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (log.preWatched.isNotEmpty ||
                                            log.postWatched.isNotEmpty)
                                        ? "Pre: ${log.preWatched} • Post: ${log.postWatched}"
                                        : "${log.videosWatched}/${log.totalVideos} videos watched",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color borderColor,
    required Color cardBg,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: cardBg.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

