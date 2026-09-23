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
  String _selectedOpStage = "Pre-op";

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Delete Patient",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to delete ${_viewModel.patient.name.isNotEmpty ? _viewModel.patient.name : 'this patient'}? This action cannot be undone.",
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.emerald,
              content: Text("Patient deleted successfully"),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.red,
              content: Text("Error deleting patient"),
            ),
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
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Back",
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        leadingWidth: 48,
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
          if (MediaQuery.of(context).size.width < 600) ...[
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primary,
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
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.red,
                size: 20,
              ),
              tooltip: "Delete",
              onPressed: _confirmDelete,
            ),
          ] else ...[
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
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text(
                "Edit Patient",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 34),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text(
                "Delete",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.red,
                backgroundColor: AppTheme.redBg,
                side: const BorderSide(color: AppTheme.redBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 34),
              ),
            ),
          ],
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
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
                        color: AppTheme.amberBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.amberBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.amberText,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _viewModel.fetchPatientDetails,
                            child: const Text(
                              "Retry",
                              style: TextStyle(color: AppTheme.amberText),
                            ),
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
                        _buildStagePerformanceComparisonCard(),
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
                                child: Column(
                                  children: [
                                    _buildEngagementOverviewCard(),
                                    const SizedBox(height: 16),
                                    _buildStagePerformanceComparisonCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildVideoHistoryCard(),
                      ],
                    )
                  else
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
                                child: Column(
                                  children: [
                                    _buildEngagementOverviewCard(),
                                    const SizedBox(height: 16),
                                    _buildStagePerformanceComparisonCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildVideoHistoryCard(),
                      ],
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.blueBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Account Info",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.emeraldBg
                            : AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.emeraldBorder
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.emerald
                                  : AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? "Active Member" : "Inactive",
                            style: TextStyle(
                              color: isActive
                                  ? AppTheme.emeraldText
                                  : AppTheme.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar, Profile Header, and Notification in the same Row
                        Row(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (patient.username.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "@${patient.username}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    "ID: ${patient.id.length > 8 ? patient.id.substring(0, 8) : patient.id}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildNotificationReminderCard(patient),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppTheme.borderSubtle),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          "AGE",
                          patient.age > 0 ? '${patient.age} yrs' : 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow("GENDER", patient.gender),
                        if (patient.dob.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "DATE OF BIRTH",
                            _formatDateOnly(patient.dob),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "LANGUAGE",
                          patient.language.isNotEmpty
                              ? patient.language
                              : "N/A",
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "PHONE NUMBER",
                          patient.phone.isNotEmpty ? patient.phone : "N/A",
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "EMAIL ADDRESS",
                          patient.email.isNotEmpty ? patient.email : "N/A",
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "REGISTRATION DATE",
                          _formatDateTime(patient.date),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "ACTIVITY STREAK",
                          patient.streak.isNotEmpty ? patient.streak : "0 days",
                        ),
                        if (patient.note.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow("CLINICAL NOTE", patient.note),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationReminderCard(UserModel patient) {
    if (_viewModel.isAccountLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: const FlashingWidget(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerBox(width: 24, height: 24, borderRadius: 12),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(width: 75, height: 10),
                  SizedBox(height: 4),
                  ShimmerBox(width: 55, height: 12),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final bool isEnabled = patient.isNotificationActive;
    final String statusText = patient.notificationStatus.isNotEmpty
        ? patient.notificationStatus.toUpperCase()
        : (isEnabled ? "ON" : "OFF");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppTheme.emeraldBg.withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? AppTheme.emeraldBorder : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.emerald.withValues(alpha: 0.12)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              size: 16,
              color: isEnabled ? AppTheme.emeraldText : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Daily Reminder",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? AppTheme.emeraldBg
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isEnabled
                            ? AppTheme.emeraldBorder
                            : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? AppTheme.emeraldText
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnabled && patient.notificationTime.isNotEmpty
                        ? patient.formattedNotificationTime
                        : (isEnabled ? "Time not set" : "Disabled"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  if (isEnabled && patient.notificationTime.isNotEmpty) ...[
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ],
          ),
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
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

    if (!hasImage) {
      return _buildInitialsAvatar(patient);
    }

    final fullUrl = ApiService().getFullImageUrl(photoUrl);

    if (fullUrl.startsWith('data:image')) {
      try {
        final commaIndex = fullUrl.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(fullUrl.substring(commaIndex + 1));
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
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

        if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
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

    final avatarColor = AppTheme.getAvatarPalette(rawName);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: avatarColor['bg'],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: avatarColor['border']!),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: avatarColor['fg'],
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.blueBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Engagement Overview",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // PRE-OP OR POST-OP SELECTION BOX
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderMedium),
                ),
                child: PopupMenuButton<String>(
                  tooltip: "",
                  offset: const Offset(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  onSelected: (String newValue) {
                    setState(() {
                      _selectedOpStage = newValue;
                    });
                    _viewModel.setOpStage(newValue);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "Pre-op",
                      height: 36,
                      child: Text(
                        "Pre-op",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedOpStage == "Pre-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedOpStage == "Pre-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Post-op",
                      height: 36,
                      child: Text(
                        "Post-op",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedOpStage == "Post-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedOpStage == "Post-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "All",
                      height: 36,
                      child: Text(
                        "All",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedOpStage == "All"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedOpStage == "All"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedOpStage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _viewModel.isEngagementLoading
                  ? _buildSkeletonStatBox()
                  : _buildStatBox(
                      label: "Total Assigned",
                      value: _viewModel.totalVideos.toString(),
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: AppTheme.blue,
                      iconBgColor: AppTheme.blueBg,
                      cardBg: AppTheme.blueCardBg,
                      borderColor: AppTheme.blueBorder,
                    ),
              const SizedBox(width: 12),
              _viewModel.isEngagementLoading
                  ? _buildSkeletonStatBox()
                  : _buildStatBox(
                      label: "Total Completed",
                      value: _viewModel.completedVideos.toString(),
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.purple,
                      iconBgColor: AppTheme.purpleBg,
                      cardBg: AppTheme.purpleCardBg,
                      borderColor: AppTheme.purpleBorder,
                    ),
              const SizedBox(width: 12),
              _viewModel.isEngagementLoading
                  ? _buildSkeletonProgressBox()
                  : _buildProgressBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStagePerformanceComparisonCard() {
    final preOp = _viewModel.preOpStats;
    final postOp = _viewModel.postOpStats;
    final delta = _viewModel.stageDeltaRate;

    String deltaLabel;
    Color deltaTextColor;
    Color deltaBg;
    Color deltaBorder;
    IconData deltaIcon;

    if (delta > 0) {
      deltaLabel = "Post-Op +${delta.abs()}%";
      deltaTextColor = AppTheme.emeraldText;
      deltaBg = AppTheme.emeraldBg;
      deltaBorder = AppTheme.emeraldBorder;
      deltaIcon = Icons.trending_up_rounded;
    } else if (delta < 0) {
      deltaLabel = "Pre-Op +${delta.abs()}%";
      deltaTextColor = AppTheme.blueText;
      deltaBg = AppTheme.blueBg;
      deltaBorder = AppTheme.blueBorder;
      deltaIcon = Icons.trending_up_rounded;
    } else {
      deltaLabel = "Equal Completion";
      deltaTextColor = AppTheme.textSecondary;
      deltaBg = AppTheme.borderSubtle;
      deltaBorder = AppTheme.borderMedium;
      deltaIcon = Icons.horizontal_rule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: AppTheme.purple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Pre-Op & Post-Op Comparison",
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
                  color: deltaBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: deltaBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deltaIcon, size: 14, color: deltaTextColor),
                    const SizedBox(width: 4),
                    Text(
                      deltaLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: deltaTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pre-Op and Post-Op visual cards
          Row(
            children: [
              Expanded(
                child: _viewModel.isComparisonLoading
                    ? _buildSkeletonStageBox()
                    : _buildStageDetailBox(
                        stageTitle: "PRE-OP",
                        icon: Icons.assignment_outlined,
                        stats: preOp,
                        accentColor: AppTheme.blue,
                        cardBg: AppTheme.blueCardBg,
                        borderColor: AppTheme.blueBorder,
                        textColor: AppTheme.blueText,
                        badgeBg: AppTheme.blueBg,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _viewModel.isComparisonLoading
                    ? _buildSkeletonStageBox()
                    : _buildStageDetailBox(
                        stageTitle: "POST-OP",
                        icon: Icons.healing_outlined,
                        stats: postOp,
                        accentColor: AppTheme.emerald,
                        cardBg: AppTheme.emeraldCardBg,
                        borderColor: AppTheme.emeraldBorder,
                        textColor: AppTheme.emeraldText,
                        badgeBg: AppTheme.emeraldBg,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageDetailBox({
    required String stageTitle,
    required IconData icon,
    required StagePerformanceStats stats,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stageTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${stats.progressRate}%",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
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
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.blueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Assigned & Watched Video History",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // CATEGORY DROPDOWN: All, Pre-op, Post-op
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderMedium),
                ),
                child: PopupMenuButton<String>(
                  tooltip: "",
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  onSelected: (String newValue) {
                    _viewModel.setHistoryCategory(newValue);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "All",
                      height: 34,
                      child: Text(
                        "All",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _viewModel.selectedHistoryCategory == "All"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _viewModel.selectedHistoryCategory == "All"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Pre-op",
                      height: 34,
                      child: Text(
                        "Pre-op",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _viewModel.selectedHistoryCategory == "Pre-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _viewModel.selectedHistoryCategory == "Pre-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Post-op",
                      height: 34,
                      child: Text(
                        "Post-op",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _viewModel.selectedHistoryCategory == "Post-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _viewModel.selectedHistoryCategory == "Post-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _viewModel.selectedHistoryCategory,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  "${videoHistory.length} ${videoHistory.length == 1 ? 'Video' : 'Videos'}",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_viewModel.isHistoryLoading)
            const FlashingWidget(
              child: Column(
                children: [
                  _SkeletonHistoryItem(),
                  Divider(height: 16, color: AppTheme.borderSubtle),
                  _SkeletonHistoryItem(),
                ],
              ),
            )
          else if (videoHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(
                    Icons.video_library_outlined,
                    size: 38,
                    color: AppTheme.textLight,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No assigned or watched videos found for this patient.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
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
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final video = videoHistory[index];
                return _buildHistoryItem(video, index);
              },
            ),
        ],
      ),
    );
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
    }
    return null;
  }

  String _formatSeconds(int totalSecs) {
    if (totalSecs <= 0) return "0:00";
    final int hours = totalSecs ~/ 3600;
    final int minutes = (totalSecs % 3600) ~/ 60;
    final int seconds = totalSecs % 60;
    final String secStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final String minStr = minutes.toString().padLeft(2, '0');
      return "$hours:$minStr:$secStr";
    } else {
      return "$minutes:$secStr";
    }
  }

  String? _formatDateTimeOrNull(dynamic rawDate) {
    if (rawDate == null) return null;
    final str = rawDate.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null' || str.toLowerCase() == 'n/a') return null;
    final parsed = DateTime.tryParse(str);
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
    return str;
  }

  Widget _buildThumbnail(
    String? thumbnailUrl,
    bool isCompleted,
    bool isPostOp,
    int? totalDuration,
  ) {
    final hasThumbnail = thumbnailUrl != null &&
        thumbnailUrl.trim().isNotEmpty &&
        thumbnailUrl.toLowerCase() != 'null';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.emeraldBg
              : (isPostOp ? AppTheme.purpleBg : AppTheme.blueBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted
                ? AppTheme.emeraldBorder
                : (isPostOp ? AppTheme.purpleBorder : AppTheme.blueBorder),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumbnail)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isCompleted
                        ? AppTheme.emerald
                        : (isPostOp ? AppTheme.purple : AppTheme.primary),
                    size: 26,
                  ),
                ),
              )
            else
              Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  color: isCompleted
                      ? AppTheme.emerald
                      : (isPostOp ? AppTheme.purple : AppTheme.primary),
                  size: 26,
                ),
              ),
            if (totalDuration != null && totalDuration > 0)
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _formatSeconds(totalDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isCompleted,
    int progressPercent,
    int currentSeconds,
    bool hasOpened,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppTheme.emeraldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emeraldBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.emerald),
            SizedBox(width: 4),
            Text(
              "Completed",
              style: TextStyle(
                color: AppTheme.emeraldText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (currentSeconds > 0 || hasOpened) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppTheme.blueBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.blueBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              "In Progress • $progressPercent%",
              style: const TextStyle(
                color: AppTheme.blueText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio_button_unchecked, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text(
              "Not Started",
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimestampBadge(
    IconData icon,
    String label,
    String formattedTime, {
    bool isSuccess = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isSuccess ? AppTheme.emeraldBg : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSuccess ? AppTheme.emeraldBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isSuccess ? AppTheme.emerald : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isSuccess ? AppTheme.emeraldText : AppTheme.textSecondary,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isSuccess ? AppTheme.emeraldText : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> video, int index) {
    final videoId = _parseInt(video['video_id'] ?? video['videoId'] ?? video['id']);
    final title = video['title']?.toString() ??
        video['name']?.toString() ??
        (videoId != null ? 'Video #$videoId' : 'Video #${index + 1}');

    final description = video['description']?.toString().trim();
    final bool hasDescription = description != null &&
        description.isNotEmpty &&
        description.toLowerCase() != 'null';

    final rawCategory = video['category']?.toString() ?? 'Pre-Op';
    final category = rawCategory.trim().isEmpty ? 'Pre-Op' : rawCategory;
    final bool isPostOp = category.toLowerCase().contains('post');

    final thumbnailUrl =
        video['thumbnail_url']?.toString() ?? video['thumbnailUrl']?.toString();

    final rawCompleted = video['is_completed'] ??
        video['isCompleted'] ??
        video['completed'];
    final bool isCompleted = rawCompleted == 1 ||
        rawCompleted == true ||
        rawCompleted == '1' ||
        rawCompleted == 'true' ||
        video['status'] == 'completed';

    final int currentSeconds = _parseInt(
          video['current_timestamp_seconds'] ??
              video['currentTimestampSeconds'] ??
              video['current_timestamp'] ??
              video['progress_seconds'],
        ) ??
        0;

    final int? totalDuration = _parseInt(
      video['total_video_duration'] ??
          video['totalVideoDuration'] ??
          video['duration_seconds'] ??
          video['duration'],
    );

    final firstOpenedAt = _formatDateTimeOrNull(
      video['first_opened_at'] ?? video['firstOpenedAt'],
    );
    final lastWatchedAt = _formatDateTimeOrNull(
      video['last_watched_at'] ?? video['lastWatchedAt'] ?? video['viewedAt'],
    );
    final completedAt = _formatDateTimeOrNull(
      video['completed_at'] ?? video['completedAt'],
    );
    final assignedAt = _formatDateTimeOrNull(
      video['assignedAt'] ?? video['assigned_at'] ?? video['date'],
    );

    int progressPercent;
    if (totalDuration != null && totalDuration > 0) {
      progressPercent =
          ((currentSeconds / totalDuration) * 100).clamp(0, 100).round();
    } else if (isCompleted) {
      progressPercent = 100;
    } else {
      progressPercent = 0;
    }
    if (isCompleted && progressPercent < 100) {
      progressPercent = 100;
    }
    final double progressRatio = (progressPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(thumbnailUrl, isCompleted, isPostOp, totalDuration),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title, Video ID, Category, and Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                            ),
                          ),
                          if (videoId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                "#$videoId",
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isPostOp
                                  ? AppTheme.purpleBg
                                  : AppTheme.blueBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isPostOp
                                    ? AppTheme.purpleBorder
                                    : AppTheme.blueBorder,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isPostOp
                                    ? AppTheme.purpleText
                                    : AppTheme.blueText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(
                      isCompleted,
                      progressPercent,
                      currentSeconds,
                      firstOpenedAt != null,
                    ),
                  ],
                ),

                // Description (if present)
                if (hasDescription) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Watch Progress Section
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              totalDuration != null && totalDuration > 0
                                  ? "Watched: ${_formatSeconds(currentSeconds)} / ${_formatSeconds(totalDuration)}"
                                  : (currentSeconds > 0
                                      ? "Watched: ${_formatSeconds(currentSeconds)}"
                                      : "Not watched yet"),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$progressPercent%",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? AppTheme.emeraldText
                                : (progressPercent > 0
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? AppTheme.emerald : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Timestamps Section: first_opened_at, last_watched_at, completed_at
                if (firstOpenedAt != null ||
                    lastWatchedAt != null ||
                    completedAt != null ||
                    assignedAt != null) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      if (firstOpenedAt != null)
                        _buildTimestampBadge(
                          Icons.login_rounded,
                          "Started",
                          firstOpenedAt,
                        ),
                      if (lastWatchedAt != null)
                        _buildTimestampBadge(
                          Icons.history_rounded,
                          "Last Watched",
                          lastWatchedAt,
                        ),
                      if (completedAt != null)
                        _buildTimestampBadge(
                          Icons.check_circle_outline_rounded,
                          "Completed",
                          completedAt,
                          isSuccess: true,
                        )
                      else if (assignedAt != null &&
                          firstOpenedAt == null &&
                          lastWatchedAt == null)
                        _buildTimestampBadge(
                          Icons.calendar_today_outlined,
                          "Assigned",
                          assignedAt,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBox() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.emeraldCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.emeraldBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Overall Progress",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.emeraldText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.emerald,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${_viewModel.progressRate}%",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.emeraldText,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStatBox() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const FlashingWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 80, height: 13),
                  ShimmerBox(width: 22, height: 22, borderRadius: 6),
                ],
              ),
              SizedBox(height: 12),
              ShimmerBox(width: 45, height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonProgressBox() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const FlashingWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 80, height: 13),
                  ShimmerBox(width: 22, height: 22, borderRadius: 6),
                ],
              ),
              SizedBox(height: 12),
              ShimmerBox(width: 50, height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonStageBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const FlashingWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 55, height: 13),
                ShimmerBox(width: 22, height: 22, borderRadius: 11),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(width: 48, height: 24),
            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SkeletonHistoryItem extends StatelessWidget {
  const _SkeletonHistoryItem();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerBox(width: 36, height: 36, borderRadius: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(width: 160, height: 14),
              SizedBox(height: 6),
              ShimmerBox(width: 110, height: 11),
            ],
          ),
        ),
        const ShimmerBox(width: 75, height: 22, borderRadius: 12),
      ],
    );
  }
}

class FlashingWidget extends StatefulWidget {
  final Widget child;
  final bool isFlashing;

  const FlashingWidget({
    super.key,
    required this.child,
    this.isFlashing = true,
  });

  @override
  State<FlashingWidget> createState() => _FlashingWidgetState();
}

class _FlashingWidgetState extends State<FlashingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFlashing) return widget.child;
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
