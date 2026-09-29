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

            // Top Watched Videos & Activity Logs
            if (MediaQuery.of(context).size.width >= 1150)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildActivityLogsTable()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTopWatchedVideosCard()),
                ],
              )
            else ...[
              _buildTopWatchedVideosCard(),
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

  Widget _buildTopWatchedVideosCard() {
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
          // Header
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
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Top Watched Videos",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "Most viewed clinical & guidance videos",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 13,
                        color: Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${_viewModel.topWatchedVideos.length} Ranked",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC2410C),
                        ),
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
            child: _viewModel.isLoading
                ? const TopVideosSkeleton(itemCount: 5)
                : _viewModel.topWatchedVideos.isEmpty
                ? Center(
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
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _viewModel.topWatchedVideos.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppTheme.borderSubtle),
                    itemBuilder: (context, index) {
                      final video = _viewModel.topWatchedVideos[index];
                      return _buildTopVideoItem(video, index);
                    },
                  ),
          ),
        ],
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
