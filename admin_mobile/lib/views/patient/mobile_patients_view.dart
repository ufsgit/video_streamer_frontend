import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../viewmodels/patients_list_viewmodel.dart';
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
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _viewModel.isLoading ? null : _viewModel.fetchPatients,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const MobileCreatePatientView(),
            ),
          );
          if (result == true) {
            _viewModel.fetchPatients();
          }
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
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
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
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
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _viewModel.fetchPatients(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text("Reload"),
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.successLight
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? "Active" : patient.status,
                          style: TextStyle(
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
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
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel patient) {
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
            backgroundColor: AppTheme.secondaryBlue,
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
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
      backgroundColor: AppTheme.secondaryBlue,
      child: Text(
        patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
        style: const TextStyle(
          color: AppTheme.primaryBlue,
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
