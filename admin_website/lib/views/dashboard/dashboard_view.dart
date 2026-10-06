import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/skeleton_loader.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardViewModel _viewModel = DashboardViewModel();
  int _selectedTopTab = 0; // 0: Top Watched Videos, 1: Top Active Patients

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
      body: SingleChildScrollView(
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
                    isLoading: _viewModel.isLoading,
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
                    isLoading: _viewModel.isLoading,
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
                    isLoading: _viewModel.isLoading,
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
                      isLoading: _viewModel.isLoading,
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
                      isLoading: _viewModel.isLoading,
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
                      isLoading: _viewModel.isLoading,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            // Top Leaderboard (Switchable Videos/Patients) & Activity Logs
            if (MediaQuery.of(context).size.width >= 1150)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildActivityLogsTable()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTopLeaderboardCard()),
                ],
              )
            else ...[
              _buildTopLeaderboardCard(),
              const SizedBox(height: 18),
              _buildActivityLogsTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogsTable() {
    return Container(
      height: 520,
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
            child: _viewModel.isLoading
                ? const ActivityLogsSkeleton(rowCount: 6)
                : _viewModel.activityLogs.isEmpty
                ? const Center(
                    child: Text(
                      "No recent activity logged",
                      style: TextStyle(
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
                      final isNarrow = MediaQuery.of(context).size.width < 600;
                      final avatarColor = AppTheme.getAvatarPalette(
                        log.patientName,
                      );

                      if (isNarrow) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  log.postWatched.isNotEmpty)
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
                                    backgroundColor: avatarColor['bg'],
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
                                            overflow: TextOverflow.ellipsis,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (log.progressPercentage / 100)
                                            .clamp(0.0, 1.0),
                                        minHeight: 5,
                                        backgroundColor: AppTheme.border,
                                        color: log.progressPercentage == 100
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
                                      color: log.progressPercentage == 100
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
    );
  }

  Widget _buildTopLeaderboardCard() {
    final isVideosTab = _selectedTopTab == 0;

    return Container(
      height: 520,
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
          // Header with Title and Segmented Switcher
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 13.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isVideosTab
                                ? [const Color(0xFFF59E0B), const Color(0xFFEA580C)]
                                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: (isVideosTab
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF6366F1))
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isVideosTab
                              ? Icons.local_fire_department_rounded
                              : Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVideosTab
                                  ? "Top Watched Videos"
                                  : "Top Active Patients",
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isVideosTab
                                  ? "Most viewed guidance videos"
                                  : "Patients with most watch activity",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Switcher Pill Tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(
                        title: "Videos",
                        icon: Icons.play_circle_fill_rounded,
                        isSelected: isVideosTab,
                        activeColor: const Color(0xFFEA580C),
                        onTap: () {
                          if (_selectedTopTab != 0) {
                            setState(() => _selectedTopTab = 0);
                          }
                        },
                      ),
                      _buildTabButton(
                        title: "Patients",
                        icon: Icons.people_alt_rounded,
                        isSelected: !isVideosTab,
                        activeColor: const Color(0xFF4F46E5),
                        onTap: () {
                          if (_selectedTopTab != 1) {
                            setState(() => _selectedTopTab = 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Content List
          Expanded(
            child: isVideosTab
                ? _buildTopVideosBody()
                : _buildTopPatientsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVideosBody() {
    if (_viewModel.isLoading) {
      return const TopVideosSkeleton(itemCount: 5);
    }
    if (_viewModel.topWatchedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 38,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              "No video watch statistics yet",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _viewModel.topWatchedVideos.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppTheme.borderSubtle),
      itemBuilder: (context, index) {
        final video = _viewModel.topWatchedVideos[index];
        return _buildTopVideoItem(video, index);
      },
    );
  }

  Widget _buildTopPatientsBody() {
    if (_viewModel.isLoading) {
      return const TopVideosSkeleton(itemCount: 5);
    }
    if (_viewModel.topPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.people_outline_rounded,
              size: 38,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              "No patient watch records yet",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _viewModel.topPatients.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppTheme.borderSubtle),
      itemBuilder: (context, index) {
        final patient = _viewModel.topPatients[index];
        return _buildTopPatientItem(patient, index);
      },
    );
  }

  Widget _buildTopPatientItem(TopPatient patient, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // Rank Badge
          _buildRankBadge(index),
          const SizedBox(width: 10),

          // Avatar
          _buildPatientAvatar(patient),
          const SizedBox(width: 10),

          // Name & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (patient.ward.isNotEmpty) ...[
                      Text(
                        patient.ward,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "•",
                        style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      patient.completionRate != null
                          ? "${patient.completionRate!.toStringAsFixed(0)}% completion"
                          : "Rank #${index + 1}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Watch Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 13,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 4),
                Text(
                  "${patient.videosWatched} videos",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar(TopPatient patient) {
    final avatarColor = AppTheme.getAvatarPalette(patient.name);
    if (patient.imageUrl.trim().isNotEmpty &&
        patient.imageUrl.trim().toLowerCase() != 'null') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          ApiService().getFullImageUrl(patient.imageUrl),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPatientInitials(patient, avatarColor),
        ),
      );
    }
    return _buildPatientInitials(patient, avatarColor);
  }

  Widget _buildPatientInitials(
      TopPatient patient, Map<String, Color> avatarColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: avatarColor['bg'],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: avatarColor['border']!),
      ),
      alignment: Alignment.center,
      child: Text(
        patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: avatarColor['fg'],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTopVideoItem(TopWatchedVideo video, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // Rank Badge
          _buildRankBadge(index),
          const SizedBox(width: 10),

          // Thumbnail or Icon
          _buildVideoThumbnail(video.thumbnailUrl),
          const SizedBox(width: 10),

          // Title & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _buildCategoryBadge(video.category),
                    if (video.duration.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        video.duration,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Watch Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppTheme.blueBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.blueBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 13,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  "${video.watchCount}",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.blueText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 0) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          "1",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    } else if (rank == 1) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCBD5E1), Color(0xFF64748B)],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          "2",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFF92400E)],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          "3",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        "${rank + 1}",
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String url) {
    if (url.trim().isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.blueBg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(
          Icons.play_circle_filled_rounded,
          color: AppTheme.primary,
          size: 20,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(
        ApiService().getFullImageUrl(url),
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.blueBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.play_circle_filled_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final isPreOp = category.toLowerCase().contains('pre');
    final bg = isPreOp ? const Color(0xFFEFF6FF) : AppTheme.emeraldBg;
    final fg = isPreOp ? AppTheme.blueText : AppTheme.emeraldText;
    final border = isPreOp ? AppTheme.blueBorder : AppTheme.emeraldBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        category.isNotEmpty ? category : 'General',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: fg),
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
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
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
    Color? valueColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(14),
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
      child: Stack(
        children: [
          // Centered value according to container width and height
          Center(
            child: isLoading
                ? const SkeletonPulse(
                    child: SkeletonBox(width: 72, height: 36, borderRadius: 6),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? iconColor,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),

          // Top Header: Icon & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
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

          // Title on the left below icon
          Positioned(
            left: 0,
            top: 40,
            child: SizedBox(
              width: 120,
              child: Text(
                title,
                maxLines: 2,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
