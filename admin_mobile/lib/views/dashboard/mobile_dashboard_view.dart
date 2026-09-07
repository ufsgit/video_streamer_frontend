import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

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
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
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
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _viewModel.isLoading ? null : _viewModel.refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _viewModel.refreshData,
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              const Text(
                'Activity & Clinical Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
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

              // Metric Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      "Total Patients",
                      displayedUsers.toString(),
                      Icons.people_outline_rounded,
                      const Color(0xFFEFF6FF),
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      "Avg. Videos",
                      _viewModel.avgVideosWatched.toStringAsFixed(1),
                      Icons.play_circle_outline,
                      const Color(0xFFFDF4FF),
                      const Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                "Completion Rate",
                "${_viewModel.completionRate}%",
                Icons.check_circle_outline,
                const Color(0xFFF0FDF4),
                const Color(0xFF16A34A),
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
                  Text(
                    "${_viewModel.activityLogs.length} events",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Activity Logs List
              if (_viewModel.isLoading && _viewModel.activityLogs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
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
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _viewModel.activityLogs.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (context, index) {
                      final log = _viewModel.activityLogs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.secondaryBlue,
                              radius: 18,
                              child: Text(
                                log.patientName.isNotEmpty
                                    ? log.patientName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
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
                                              ? AppTheme.successLight
                                              : Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${log.progressPercentage}%",
                                          style: TextStyle(
                                            color: log.progressPercentage == 100
                                                ? Colors.green.shade700
                                                : AppTheme.primaryBlue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${log.ward} • ${log.lastLogin}",
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
                                      backgroundColor: Colors.grey.shade100,
                                      color: log.progressPercentage == 100
                                          ? AppTheme.success
                                          : AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${log.videosWatched}/${log.totalVideos} videos watched",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
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

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
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
