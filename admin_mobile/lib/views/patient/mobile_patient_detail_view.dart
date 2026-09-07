import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import 'mobile_create_patient_view.dart';


class MobilePatientDetailView extends StatefulWidget {
  final UserModel patient;

  const MobilePatientDetailView({super.key, required this.patient});

  @override
  State<MobilePatientDetailView> createState() =>
      _MobilePatientDetailViewState();
}

class _MobilePatientDetailViewState extends State<MobilePatientDetailView> {
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

        final List<dynamic> rawVideos = userData['assigned_videos'] ??
            userData['assignedVideos'] ??
            userData['videos'] ??
            userData['history'] ??
            userData['watched_videos'] ??
            [];

        _videoHistory =
            rawVideos.map((v) => Map<String, dynamic>.from(v as Map)).toList();

        _totalVideos = int.tryParse(
              userData['total_videos']?.toString() ??
                  userData['totalVideos']?.toString() ??
                  '',
            ) ??
            _videoHistory.length;

        _completedVideos = int.tryParse(
              userData['total_completed']?.toString() ??
                  userData['completed_videos']?.toString() ??
                  '',
            ) ??
            _videoHistory
                .where((v) =>
                    v['isCompleted'] == true ||
                    v['completed'] == true ||
                    v['status'] == 'completed' ||
                    v['progress'] == 100)
                .length;

        if (_totalVideos > 0) {
          _progressRate = ((_completedVideos / _totalVideos) * 100).round();
        } else {
          _progressRate = 0;
        }
      }
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
      _errorMessage = "Failed to load patient profile.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text(
          "Are you sure you want to permanently delete ${_patient.name}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteUser(_patient.id);
      if (success.statusCode == 200 || success.statusCode == 204) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Patient deleted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        _patient.status.toLowerCase() == "active" || _patient.status.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _isLoading ? null : _fetchPatientDetails,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MobileCreatePatientView(patientToEdit: _patient),
                ),
              );
              if (result == true) {
                _fetchPatientDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading && _videoHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : RefreshIndicator(
              onRefresh: _fetchPatientDetails,
              color: AppTheme.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Patient Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildAvatar(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _patient.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppTheme.successLight
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isActive ? "Active" : _patient.status,
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${_patient.age > 0 ? '${_patient.age} yrs' : 'Age N/A'} • ${_patient.gender}",
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: P${_patient.id.length > 6 ? _patient.id.substring(0, 6) : _patient.id}",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Contact Info List
                          _buildInfoRow(Icons.phone_outlined, "Phone", _patient.phone),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.email_outlined, "Email", _patient.email),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.cake_outlined, "DOB", _patient.dob.isNotEmpty ? _patient.dob : "N/A"),
                          if (_patient.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.notes, "Clinical Notes", _patient.note),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Engagement Stats Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Educational Engagement",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatTile(
                                  "Assigned",
                                  "$_totalVideos",
                                  Icons.video_library_outlined,
                                  AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatTile(
                                  "Completed",
                                  "$_completedVideos",
                                  Icons.check_circle_outline,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatTile(
                                  "Progress",
                                  "$_progressRate%",
                                  Icons.trending_up,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _totalVideos > 0
                                  ? (_completedVideos / _totalVideos).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              color: _progressRate == 100
                                  ? AppTheme.success
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assigned Videos List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Assigned Videos",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "${_videoHistory.length} total",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_videoHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Text(
                            "No videos currently assigned to this patient",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _videoHistory.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final v = _videoHistory[index];
                          final isCompleted = v['isCompleted'] == true ||
                              v['completed'] == true ||
                              v['progress'] == 100;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppTheme.successLight
                                        : AppTheme.secondaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : Icons.play_circle_outline,
                                    color: isCompleted
                                        ? Colors.green.shade700
                                        : AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['title'] ?? 'Educational Video',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${v['duration'] ?? '10:00'} • ${v['category'] ?? 'Rehabilitation'}",
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppTheme.successLight
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCompleted ? "Completed" : "Assigned",
                                    style: TextStyle(
                                      color: isCompleted
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    if (_patient.imageUrl.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _apiService.fetchImageBytes(_patient.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return CircleAvatar(
              radius: 26,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.secondaryBlue,
            child: Text(
              _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
        },
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: AppTheme.secondaryBlue,
      child: Text(
        _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : 'P',
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : "N/A",
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
