import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:admin_mobile/core/theme.dart';
import 'package:admin_mobile/models/user_model.dart';
import 'package:admin_mobile/services/api_service.dart';
import 'package:admin_mobile/viewmodels/patients_list_viewmodel.dart';
import 'package:admin_mobile/widgets/app_logo.dart';
import 'mobile_create_patient_view.dart';
import 'mobile_patient_detail_view.dart';

class MobilePatientsView extends StatefulWidget {
  const MobilePatientsView({super.key});

  @override
  State<MobilePatientsView> createState() => _MobilePatientsViewState();
}

class _MobilePatientsViewState extends State<MobilePatientsView> {
  final PatientsListViewModel _viewModel = PatientsListViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openCreatePatient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const MobileCreatePatientView(),
      ),
    );
    if (result == true) {
      _viewModel.fetchPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Patients",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
            tooltip: "Add Patient",
            onPressed: _openCreatePatient,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _viewModel.isLoading ? null : _viewModel.fetchPatients,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.red),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Input Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _viewModel.searchPatients(val);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Search patients by name or phone...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _viewModel.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // Patients List
          Expanded(
            child: _viewModel.isLoading && _viewModel.patients.isEmpty
                ? const Center(
                    child: AppLogoLoader(
                      size: 52,
                      message: "Loading patient records...",
                    ),
                  )
                : _viewModel.patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.errorMessage ?? "No patients registered",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openCreatePatient,
                                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                                  label: const Text("Add Patient"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _viewModel.fetchPatients(),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text("Reload"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _viewModel.fetchPatients(),
                        color: AppTheme.primaryBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _viewModel.patients.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final patient = _viewModel.patients[index];
                            return _buildPatientCard(patient);
                          },
                        ),
                      ),
          ),

          // Bottom Pagination Bar
          if (_viewModel.patients.isNotEmpty) _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildPatientCard(UserModel patient) {
    final isActive =
        patient.status.toLowerCase() == "active" || patient.status.isEmpty;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => MobilePatientDetailView(patient: patient),
          ),
        );
        if (result == true) {
          _viewModel.fetchPatients();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(patient),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.emeraldBg
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.emeraldBorder
                                : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          isActive ? "Active" : patient.status,
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.emeraldText
                                : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${patient.age > 0 ? '${patient.age} yrs' : 'Age N/A'} • ${patient.gender}",
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tel: ${patient.phone}",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              onSelected: (action) async {
                if (action == 'view') {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MobilePatientDetailView(patient: patient),
                    ),
                  );
                  if (result == true) {
                    _viewModel.fetchPatients();
                  }
                } else if (action == 'edit') {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MobileCreatePatientView(patientToEdit: patient),
                    ),
                  );
                  if (result == true) {
                    _viewModel.fetchPatients();
                  }
                } else if (action == 'delete') {
                  _confirmDeletePatient(patient);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text('View Profile', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text('Edit Details', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Patient', style: TextStyle(fontSize: 13, color: Colors.red)),
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

  void _confirmDeletePatient(UserModel patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text("Are you sure you want to permanently delete ${patient.name}? This action cannot be undone."),
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
      final success = await ApiService().deleteUser(patient.id);
      if (success.statusCode == 200 || success.statusCode == 204) {
        if (!mounted) return;
        _viewModel.fetchPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Patient deleted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(UserModel patient) {
    final palette = AppTheme.getAvatarPalette(patient.name);
    if (patient.imageUrl.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: ApiService().fetchImageBytes(patient.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return CircleAvatar(
              radius: 22,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return CircleAvatar(
            radius: 22,
            backgroundColor: palette['bg'],
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
              style: TextStyle(
                color: palette['fg'],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: palette['bg'],
      child: Text(
        patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: palette['fg'],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Page ${_viewModel.currentPage}${_viewModel.totalPages > 1 ? ' of ${_viewModel.totalPages}' : ''}",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _viewModel.hasPreviousPage && !_viewModel.isLoading
                      ? () => _viewModel.previousPage()
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Prev", style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _viewModel.hasNextPage && !_viewModel.isLoading
                      ? () => _viewModel.nextPage()
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
