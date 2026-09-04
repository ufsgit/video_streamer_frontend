import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import 'create_patient_dialog.dart';

class PatientDetailView extends StatefulWidget {
  final UserModel patient;

  const PatientDetailView({super.key, required this.patient});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> {
  final ApiService _apiService = ApiService();
  late UserModel _patient;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _videoHistory = [];
  int _totalVideos = 0;
  int _completedVideos = 0;
  int _progressRate = 0;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _fetchPatientDetails();
  }

  Future<void> _fetchPatientDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getUserById(_patient.id);
      final resData = response.data;

      Map<String, dynamic> userData = {};
      if (resData is Map<String, dynamic>) {
        if (resData['data'] is Map<String, dynamic>) {
          userData = Map<String, dynamic>.from(resData['data']);
        } else if (resData['user'] is Map<String, dynamic>) {
          userData = Map<String, dynamic>.from(resData['user']);
        } else {
          userData = resData;
        }
      }

      if (userData.isNotEmpty) {
        _patient = UserModel.fromJson(userData);

        // Parse assigned or watched videos
        final List<dynamic> rawVideos =
            userData['assigned_videos'] ??
            userData['assignedVideos'] ??
            userData['videos'] ??
            userData['history'] ??
            userData['watched_videos'] ??
            [];

        _videoHistory = rawVideos
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();

        // Calculate / extract statistics
        _totalVideos =
            int.tryParse(
              userData['total_videos']?.toString() ??
                  userData['totalVideos']?.toString() ??
                  userData['total_watched']?.toString() ??
                  '',
            ) ??
            _videoHistory.length;

        _completedVideos =
            int.tryParse(
              userData['total_completed']?.toString() ??
                  userData['completed_videos']?.toString() ??
                  userData['completedCount']?.toString() ??
                  '',
            ) ??
            _videoHistory
                .where(
                  (v) =>
                      v['isCompleted'] == true ||
                      v['completed'] == true ||
                      v['status'] == 'completed' ||
                      v['progress'] == 100,
                )
                .length;

        if (_totalVideos > 0) {
          _progressRate = ((_completedVideos / _totalVideos) * 100).round();
        } else if (userData['progress'] != null) {
          _progressRate =
              int.tryParse(userData['progress'].toString()) ??
              (double.tryParse(userData['progress'].toString())?.round() ?? 0);
        } else {
          _progressRate = 0;
        }
      }
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
      _errorMessage = "Failed to fetch latest details from server.";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text(
          "Are you sure you want to delete ${_patient.name.isNotEmpty ? _patient.name : 'this patient'}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final response = await _apiService.deleteUser(_patient.id);
        if (response.statusCode == 200 || response.statusCode == 204) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Patient deleted successfully")),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting patient: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        leadingWidth: 40,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _patient.name.isNotEmpty ? _patient.name : 'Unnamed Patient',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _patient.email.isNotEmpty ? _patient.email : '',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            tooltip: "Refresh Details",
            onPressed: _isLoading ? null : _fetchPatientDetails,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final updated = await showDialog<bool>(
                context: context,
                builder: (context) =>
                    CreatePatientDialog(patientToEdit: _patient),
              );
              if (updated == true && mounted) {
                _fetchPatientDetails();
              }
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text("Delete", style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading && _videoHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade800,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchPatientDetails,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAccountInfoCard()),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEngagementOverviewCard(),
                            const SizedBox(height: 16),
                            _buildVideoHistoryCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountInfoCard() {
    final isActive =
        _patient.status.toLowerCase() == "active" || _patient.status.isEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                "Account Info",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? "Active Member" : "Inactive",
                  style: TextStyle(
                    color: isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar and Profile Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildPatientAvatar(_patient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _patient.name.isNotEmpty
                            ? _patient.name
                            : (_patient.username.isNotEmpty
                                  ? _patient.username
                                  : 'Unnamed'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_patient.username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          "@${_patient.username}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        "ID: ${_patient.id.length > 8 ? _patient.id.substring(0, 8) : _patient.id}",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          _buildInfoRow(
            "AGE : ",
            _patient.age > 0 ? '${_patient.age} yrs' : 'N/A',
          ),
          const SizedBox(height: 10),
          _buildInfoRow("GENDER : ", _patient.gender),
          if (_patient.dob.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow("DATE OF BIRTH : ", _patient.dob),
          ],
          const SizedBox(height: 10),
          _buildInfoRow(
            "PHONE NUMBER : ",
            _patient.phone.isNotEmpty ? _patient.phone : "N/A",
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            "EMAIL ADDRESS : ",
            _patient.email.isNotEmpty ? _patient.email : "N/A",
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            "REGISTRATION DATE : ",
            _patient.date.isNotEmpty
                ? (_patient.date.length >= 10
                      ? _patient.date.substring(0, 10)
                      : _patient.date)
                : "N/A",
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            "ACTIVITY STREAK : ",
            _patient.streak.isNotEmpty ? _patient.streak : "0 days",
          ),
          if (_patient.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow("CLINICAL NOTE : ", _patient.note),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPatientAvatar(UserModel patient) {
    final photoUrl = patient.imageUrl.trim();
    if (photoUrl.isEmpty) {
      return _buildInitialsAvatar(patient);
    }

    return FutureBuilder<Uint8List?>(
      future: ApiService().fetchImageBytes(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitialsAvatar(patient),
            ),
          );
        }

        return _buildInitialsAvatar(patient);
      },
    );
  }

  Widget _buildInitialsAvatar(UserModel patient) {
    final name = patient.name.trim().isNotEmpty
        ? patient.name.trim()
        : (patient.username.trim().isNotEmpty ? patient.username.trim() : 'P');
    final parts = name.split(' ');
    final initials = parts
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'P',
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryBlue, size: 16),
              SizedBox(width: 6),
              Text(
                "Engagement Overview",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox(
                "Total Assigned",
                _totalVideos.toString(),
                Icons.play_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildStatBox(
                "Total Completed",
                _completedVideos.toString(),
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overall Progress",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "$_progressRate%",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.trending_up,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 14, color: AppTheme.primaryBlue),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.primaryBlue, size: 16),
              const SizedBox(width: 6),
              const Text(
                "Assigned & Watched Video History",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                "${_videoHistory.length} ${_videoHistory.length == 1 ? 'Video' : 'Videos'}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_videoHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 40,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No assigned or watched videos found for this patient.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _videoHistory.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final video = _videoHistory[index];
                final title =
                    video['title']?.toString() ??
                    video['name']?.toString() ??
                    'Video #${index + 1}';
                final duration = video['duration']?.toString() ?? 'N/A';
                final category = video['category']?.toString() ?? 'General';
                final dateStr =
                    video['assignedAt']?.toString() ??
                    video['viewedAt']?.toString() ??
                    video['date']?.toString() ??
                    '';
                final isCompleted =
                    video['isCompleted'] == true ||
                    video['completed'] == true ||
                    video['status'] == 'completed' ||
                    video['progress'] == 100;

                return _buildHistoryItem(
                  title: title,
                  subtitle: dateStr.isNotEmpty
                      ? (dateStr.length >= 10
                            ? dateStr.substring(0, 10)
                            : dateStr)
                      : "Assigned",
                  duration: duration,
                  category: category,
                  isCompleted: isCompleted,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String duration,
    required String category,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    "$subtitle • $duration",
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade100 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_outline : Icons.access_time,
                size: 12,
                color: isCompleted
                    ? Colors.green.shade700
                    : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                isCompleted ? "Completed" : "In Progress",
                style: TextStyle(
                  color: isCompleted
                      ? Colors.green.shade700
                      : AppTheme.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
