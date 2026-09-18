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
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primary,
              size: 20,
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
        leadingWidth: 46,
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
              icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 20),
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
              label: const Text("Edit Patient", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 34),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text("Delete", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.red,
                backgroundColor: AppTheme.redBg,
                side: const BorderSide(color: AppTheme.redBorder),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 34),
              ),
            ),
          ],
          const SizedBox(width: 12),
        ],
      ),
      body: _viewModel.isLoading && _viewModel.videoHistory.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
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
                            child: const Text("Retry", style: TextStyle(color: AppTheme.amberText)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.emeraldBg : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? AppTheme.emeraldBorder : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.emerald : AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? "Active Member" : "Inactive",
                      style: TextStyle(
                        color: isActive ? AppTheme.emeraldText : AppTheme.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                      color: AppTheme.blueBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.blueBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _viewModel.isAccountInfoCollapsed
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 13,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _viewModel.isAccountInfoCollapsed
                              ? "Expand"
                              : "Collapse",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
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
                              fontSize: 15,
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
                            "${patient.age > 0 ? '${patient.age} yrs' : 'N/A'} • ${patient.gender.isNotEmpty ? patient.gender : 'N/A'}${patient.language.isNotEmpty ? ' • ${patient.language}' : ''}",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
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
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        "ID: ${patient.id.length > 8 ? patient.id.substring(0, 8) : patient.id}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 14),

            _buildInfoRow("AGE", patient.age > 0 ? '${patient.age} yrs' : 'N/A'),
            const SizedBox(height: 10),
            _buildInfoRow("GENDER", patient.gender),
            if (patient.dob.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow("DATE OF BIRTH", _formatDateOnly(patient.dob)),
            ],
            const SizedBox(height: 10),
            _buildInfoRow(
              "LANGUAGE",
              patient.language.isNotEmpty ? patient.language : "N/A",
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
              _buildStatBox(
                label: "Total Assigned",
                value: _viewModel.totalVideos.toString(),
                icon: Icons.play_circle_fill_rounded,
                iconColor: AppTheme.blue,
                iconBgColor: AppTheme.blueBg,
                cardBg: AppTheme.blueCardBg,
                borderColor: AppTheme.blueBorder,
              ),
              const SizedBox(width: 12),
              _buildStatBox(
                label: "Total Completed",
                value: _viewModel.completedVideos.toString(),
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.purple,
                iconBgColor: AppTheme.purpleBg,
                cardBg: AppTheme.purpleCardBg,
                borderColor: AppTheme.purpleBorder,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.emeraldBorder, width: 1.2),
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
              ),
            ],
          ),
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
          if (videoHistory.isEmpty)
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
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                  const Divider(height: 16, color: AppTheme.borderSubtle),
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
    final bool isPostOp = category.toLowerCase().contains('post');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.emeraldBg : AppTheme.blueBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted ? AppTheme.emeraldBorder : AppTheme.blueBorder,
            ),
          ),
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: isCompleted ? AppTheme.emerald : AppTheme.primary,
            size: 18,
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
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    "$subtitle • $duration",
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isPostOp ? AppTheme.purpleBg : AppTheme.blueBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPostOp ? AppTheme.purpleBorder : AppTheme.blueBorder,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isPostOp ? AppTheme.purpleText : AppTheme.blueText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.emeraldBg : AppTheme.blueBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted ? AppTheme.emeraldBorder : AppTheme.blueBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.access_time_rounded,
                size: 12,
                color: isCompleted
                    ? AppTheme.emerald
                    : AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                isCompleted ? "Completed" : "In Progress",
                style: TextStyle(
                  color: isCompleted
                      ? AppTheme.emeraldText
                      : AppTheme.blueText,
                  fontSize: 10.5,
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
