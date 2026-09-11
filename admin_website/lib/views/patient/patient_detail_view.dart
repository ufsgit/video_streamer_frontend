import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../viewmodels/patient_detail_viewmodel.dart';
import 'create_patient_dialog.dart';

class PatientDetailView extends StatefulWidget {
  final UserModel patient;

  const PatientDetailView({super.key, required this.patient});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> {
  late final PatientDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PatientDetailViewModel(patient: widget.patient);
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text(
          "Are you sure you want to delete ${_viewModel.patient.name.isNotEmpty ? _viewModel.patient.name : 'this patient'}? This action cannot be undone.",
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
      final success = await _viewModel.deletePatient();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient deleted successfully")),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error deleting patient")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _viewModel.patient;

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
        title: Text(
          patient.name.isNotEmpty ? patient.name : 'Unnamed Patient',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            tooltip: "Refresh Details",
            onPressed: _viewModel.isLoading ? null : _viewModel.fetchPatientDetails,
          ),
          if (MediaQuery.of(context).size.width < 600) ...[
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              tooltip: "Edit",
              onPressed: () async {
                final updated = await showDialog<bool>(
                  context: context,
                  builder: (context) =>
                      CreatePatientDialog(patientToEdit: patient),
                );
                if (updated == true && mounted) {
                  _viewModel.fetchPatientDetails();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: "Delete",
              onPressed: _confirmDelete,
            ),
          ] else ...[
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: () async {
                final updated = await showDialog<bool>(
                  context: context,
                  builder: (context) =>
                      CreatePatientDialog(patientToEdit: patient),
                );
                if (updated == true && mounted) {
                  _viewModel.fetchPatientDetails();
                }
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Edit", style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, size: 16),
              label: const Text("Delete", style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _viewModel.isLoading && _viewModel.videoHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_viewModel.errorMessage != null)
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
                              _viewModel.errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _viewModel.fetchPatientDetails,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  if (MediaQuery.of(context).size.width < 800)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountInfoCard(),
                        const SizedBox(height: 16),
                        _buildEngagementOverviewCard(),
                        const SizedBox(height: 16),
                        _buildVideoHistoryCard(),
                      ],
                    )
                  else if (_viewModel.isAccountInfoCollapsed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 1, child: _buildAccountInfoCard()),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildEngagementOverviewCard(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildVideoHistoryCard(),
                      ],
                    )
                  else
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 1, child: _buildAccountInfoCard()),
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
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountInfoCard() {
    final patient = _viewModel.patient;
    final isActive =
        patient.status.toLowerCase() == "active" || patient.status.isEmpty;
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
              const SizedBox(width: 8),
              Tooltip(
                message: _viewModel.isAccountInfoCollapsed
                    ? "Expand Account Info"
                    : "Collapse vertically",
                child: InkWell(
                  onTap: _viewModel.toggleAccountInfoCollapsed,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _viewModel.isAccountInfoCollapsed
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _viewModel.isAccountInfoCollapsed ? "Expand" : "Collapse",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_viewModel.isAccountInfoCollapsed) ...[
            // Collapsed Compact Profile Header
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Row(
                  children: [
                    _buildPatientAvatar(patient),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            patient.name.isNotEmpty
                                ? patient.name
                                : (patient.username.isNotEmpty
                                      ? patient.username
                                      : 'Unnamed'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient.email.isNotEmpty
                                ? patient.email
                                : (patient.phone.isNotEmpty
                                      ? patient.phone
                                      : "ID: ${patient.id.length > 8 ? patient.id.substring(0, 8) : patient.id}"),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${patient.age > 0 ? '${patient.age} yrs' : 'N/A'} • ${patient.gender.isNotEmpty ? patient.gender : 'N/A'}",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),

            // Avatar and Profile Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildPatientAvatar(patient),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name.isNotEmpty
                              ? patient.name
                              : (patient.username.isNotEmpty
                                    ? patient.username
                                    : 'Unnamed'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (patient.username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "@${patient.username}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          "ID: ${patient.id.length > 8 ? patient.id.substring(0, 8) : patient.id}",
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
              patient.age > 0 ? '${patient.age} yrs' : 'N/A',
            ),
            const SizedBox(height: 10),
            _buildInfoRow("GENDER : ", patient.gender),
            if (patient.dob.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow(
                "DATE OF BIRTH : ",
                _formatDateOnly(patient.dob),
              ),
            ],
            const SizedBox(height: 10),
            _buildInfoRow(
              "PHONE NUMBER : ",
              patient.phone.isNotEmpty ? patient.phone : "N/A",
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              "EMAIL ADDRESS : ",
              patient.email.isNotEmpty ? patient.email : "N/A",
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              "REGISTRATION DATE : ",
              _formatDateTime(patient.date),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              "ACTIVITY STREAK : ",
              patient.streak.isNotEmpty ? patient.streak : "0 days",
            ),
            if (patient.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow("CLINICAL NOTE : ", patient.note),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDateTime(String rawDate) {
    if (rawDate.trim().isEmpty) return "N/A";
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      final local = parsed.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year.toString();
      final hour = local.hour;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final hourStr = displayHour.toString().padLeft(2, '0');
      return "$day/$month/$year, $hourStr:$minute $period";
    }
    return rawDate;
  }

  String _formatDateOnly(String rawDate) {
    if (rawDate.trim().isEmpty) return "N/A";
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      final local = parsed.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year.toString();
      return "$day/$month/$year";
    }
    if (rawDate.length >= 10) {
      return rawDate.substring(0, 10);
    }
    return rawDate;
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPatientAvatar(UserModel patient) {
    final photoUrl = patient.imageUrl.trim();
    final bool hasImage =
        photoUrl.isNotEmpty &&
        photoUrl.toLowerCase() != 'null' &&
        photoUrl.toLowerCase() != 'n/a' &&
        photoUrl.toLowerCase() != 'undefined' &&
        photoUrl.toLowerCase() != 'none';

    // If no image is provided, display initial letters directly
    if (!hasImage) {
      return _buildInitialsAvatar(patient);
    }

    final fullUrl = ApiService().getFullImageUrl(photoUrl);

    // If Base64 string, render directly with initials fallback on error
    if (fullUrl.startsWith('data:image')) {
      try {
        final commaIndex = fullUrl.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(fullUrl.substring(commaIndex + 1));
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitialsAvatar(patient),
            ),
          );
        }
      } catch (_) {
        return _buildInitialsAvatar(patient);
      }
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

        // Try direct Image.network with tunnel headers as secondary
        if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullUrl,
              width: 48,
              height: 48,
              headers: const {
                'bypass-tunnel-reminder': 'true',
                'X-Tunnel-Bypass': 'true',
              },
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
    final rawName = patient.name.trim().isNotEmpty
        ? patient.name.trim()
        : (patient.username.trim().isNotEmpty
              ? patient.username.trim()
              : 'Patient');
    final parts = rawName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    String initials = '';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0][0].toUpperCase();
    } else {
      initials = 'P';
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
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
                _viewModel.totalVideos.toString(),
                Icons.play_circle_outline,
              ),
              const SizedBox(width: 12),
              _buildStatBox(
                "Total Completed",
                _viewModel.completedVideos.toString(),
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
                            "${_viewModel.progressRate}%",
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
    final videoHistory = _viewModel.videoHistory;

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
              SizedBox(width: 6),
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
                "${videoHistory.length} ${videoHistory.length == 1 ? 'Video' : 'Videos'}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (videoHistory.isEmpty)
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
              itemCount: videoHistory.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final video = videoHistory[index];
                final title =
                    video['title']?.toString() ??
                    video['name']?.toString() ??
                    'Video #${index + 1}';
                final duration = video['duration']?.toString() ?? 'N/A';
                final category = video['category']?.toString() ?? 'Pre-Op';
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
