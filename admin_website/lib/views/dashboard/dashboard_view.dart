import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
    final displayedUsersCount = _viewModel.totalUsers > 0
        ? _viewModel.totalUsers
        : _viewModel.totalLogins;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Activity Overview',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.emeraldBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Live",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Real-time monitoring of patient engagement and video usage.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _viewModel.isLoading ? null : _viewModel.refreshData,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: _viewModel.isLoading
                        ? AppTheme.textMuted
                        : AppTheme.primary,
                    size: 20,
                  ),
                  tooltip: 'Refresh Data',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Metrics Section (Cards with soft subtle color palettes)
            if (MediaQuery.of(context).size.width < 700)
              Column(
                children: [
                  _buildMetricCard(
                    title: "Total Users",
                    value: displayedUsersCount.toString(),
                    icon: Icons.people_alt_rounded,
                    iconColor: AppTheme.blue,
                    iconBgColor: AppTheme.blueBg,
                    cardBg: AppTheme.blueCardBg,
                    borderColor: AppTheme.blueBorder,
                    badgeText: "Patients",
                    badgeColor: AppTheme.blueText,
                    badgeBg: AppTheme.blueBorder,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricCard(
                    title: "Avg. Videos Watched",
                    value: _viewModel.avgVideosWatched.toStringAsFixed(1),
                    icon: Icons.play_circle_fill_rounded,
                    iconColor: AppTheme.purple,
                    iconBgColor: AppTheme.purpleBg,
                    cardBg: AppTheme.purpleCardBg,
                    borderColor: AppTheme.purpleBorder,
                    badgeText: "Per User",
                    badgeColor: AppTheme.purpleText,
                    badgeBg: AppTheme.purpleBorder,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricCard(
                    title: "Completion Rate",
                    value: "${_viewModel.completionRate}%",
                    icon: Icons.check_circle_rounded,
                    iconColor: AppTheme.emerald,
                    iconBgColor: AppTheme.emeraldBg,
                    cardBg: AppTheme.emeraldCardBg,
                    borderColor: AppTheme.emeraldBorder,
                    badgeText: "Performance",
                    badgeColor: AppTheme.emeraldText,
                    badgeBg: AppTheme.emeraldBorder,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Total Users",
                      value: displayedUsersCount.toString(),
                      icon: Icons.people_alt_rounded,
                      iconColor: AppTheme.blue,
                      iconBgColor: AppTheme.blueBg,
                      cardBg: AppTheme.blueCardBg,
                      borderColor: AppTheme.blueBorder,
                      badgeText: "Patients",
                      badgeColor: AppTheme.blueText,
                      badgeBg: AppTheme.blueBorder,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Avg. Videos Watched",
                      value: _viewModel.avgVideosWatched.toStringAsFixed(1),
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: AppTheme.purple,
                      iconBgColor: AppTheme.purpleBg,
                      cardBg: AppTheme.purpleCardBg,
                      borderColor: AppTheme.purpleBorder,
                      badgeText: "Per User",
                      badgeColor: AppTheme.purpleText,
                      badgeBg: AppTheme.purpleBorder,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Completion Rate",
                      value: "${_viewModel.completionRate}%",
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.emerald,
                      iconBgColor: AppTheme.emeraldBg,
                      cardBg: AppTheme.emeraldCardBg,
                      borderColor: AppTheme.emeraldBorder,
                      badgeText: "Performance",
                      badgeColor: AppTheme.emeraldText,
                      badgeBg: AppTheme.emeraldBorder,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            // User Activity Logs Table Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "User Activity Logs",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.blueBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.blueBorder),
                            ),
                            child: Text(
                              "${_viewModel.activityLogs.length} Events",
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.blueText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.border),

                    // Table Column Header (for wide screens)
                    if (MediaQuery.of(context).size.width >= 600)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 9.0,
                        ),
                        color: AppTheme.background,
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "PATIENT",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "LAST ACTIVITY",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "PROGRESS",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "PRE-OP",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "POST-OP",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (MediaQuery.of(context).size.width >= 600)
                      const Divider(height: 1, color: AppTheme.border),

                    // Table Body List
                    Expanded(
                      child: _viewModel.activityLogs.isEmpty
                          ? Center(
                              child: Text(
                                _viewModel.isLoading
                                    ? "Loading logs..."
                                    : "No recent activity logged",
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _viewModel.activityLogs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, color: AppTheme.borderSubtle),
                              itemBuilder: (context, index) {
                                final log = _viewModel.activityLogs[index];
                                final isNarrow =
                                    MediaQuery.of(context).size.width < 600;
                                final avatarColor =
                                    AppTheme.getAvatarPalette(log.patientName);

                                if (isNarrow) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14.0,
                                      vertical: 10.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: avatarColor['bg'],
                                          radius: 16,
                                          child: Text(
                                            log.patientName.isNotEmpty
                                                ? log.patientName[0].toUpperCase()
                                                : log.id,
                                            style: TextStyle(
                                              color: avatarColor['fg'],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log.patientName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: AppTheme.textPrimary,
                                                ),
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
                                              Row(
                                                children: [
                                                  _buildProgressBadge(
                                                    log.progressPercentage,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    (log.preWatched.isNotEmpty ||
                                                            log.postWatched
                                                                .isNotEmpty)
                                                        ? "Pre: ${log.preWatched} • Post: ${log.postWatched}"
                                                        : "${log.videosWatched}/${log.totalVideos} videos",
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 10.0,
                                  ),
                                  color: index % 2 == 0
                                      ? Colors.white
                                      : AppTheme.cardHover,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  avatarColor['bg'],
                                              radius: 14,
                                              child: Text(
                                                log.patientName.isNotEmpty
                                                    ? log.patientName[0].toUpperCase()
                                                    : 'P',
                                                style: TextStyle(
                                                  color: avatarColor['fg'],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    log.patientName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (log.ward.isNotEmpty &&
                                                      log.ward.toLowerCase() !=
                                                          'general ward') ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      log.ward,
                                                      style: const TextStyle(
                                                        color: AppTheme.textSecondary,
                                                        fontSize: 11,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              log.lastLoginDate.isNotEmpty
                                                  ? log.lastLoginDate
                                                  : log.lastLogin,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (log.lastLoginTime.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                log.lastLoginTime,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: (log.progressPercentage /
                                                          100)
                                                      .clamp(0.0, 1.0),
                                                  minHeight: 5,
                                                  backgroundColor:
                                                      AppTheme.border,
                                                  color: log.progressPercentage ==
                                                          100
                                                      ? AppTheme.emerald
                                                      : AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${log.progressPercentage}%",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: log.progressPercentage ==
                                                        100
                                                    ? AppTheme.emeraldText
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          log.preWatched.isNotEmpty
                                              ? log.preWatched
                                              : "${log.videosWatched} videos",
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          log.postWatched.isNotEmpty
                                              ? log.postWatched
                                              : "0 videos",
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBadge(int percentage) {
    Color bg;
    Color fg;
    String label;

    if (percentage == 100) {
      bg = AppTheme.emeraldBg;
      fg = AppTheme.emeraldText;
      label = "Completed";
    } else if (percentage > 0) {
      bg = AppTheme.blueBg;
      fg = AppTheme.blueText;
      label = "$percentage%";
    } else {
      bg = AppTheme.borderSubtle;
      fg = AppTheme.textSecondary;
      label = "Not Started";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBg,
    required Color borderColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: cardBg.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
