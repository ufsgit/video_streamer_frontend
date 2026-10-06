import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../viewmodels/patients_list_viewmodel.dart';
import '../../widgets/skeleton_loader.dart';
import 'create_patient_dialog.dart';
import 'patient_detail_view.dart';
import 'widgets/patient_card.dart';

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const CreatePatientDialog(),
          );
          if (result == true) {
            _viewModel.fetchPatients();
          }
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add Patient"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Patients",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage and view patient information and progress.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) {
                _viewModel.searchPatients(val);
                setState(() {});
              },
              onSubmitted: (val) {
                _viewModel.fetchPatients(search: val, page: 1);
              },
              decoration: InputDecoration(
                hintText: "Search patients by name or phonenumber...",
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
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
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildPatientsContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsContent() {
    if (_viewModel.isLoading) {
      return const PatientsGridSkeleton(itemCount: 6);
    }

    if (_viewModel.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? "No patients registered yet.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _viewModel.fetchPatients(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Refresh List"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3;
              if (constraints.maxWidth < 750) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 1100) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 200,
                ),
                itemCount: _viewModel.patients.length,
                itemBuilder: (context, index) {
                  final patient = _viewModel.patients[index];
                  return PatientCard(
                    patient: patient,
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatientDetailView(patient: patient),
                        ),
                      );
                      if (result == true) {
                        _viewModel.fetchPatients();
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPaginationBar(),
      ],
    );
  }

  Widget _buildPaginationBar() {
    if (_viewModel.patients.isEmpty) return const SizedBox.shrink();

    final startIndex =
        (_viewModel.currentPage - 1) * PatientsListViewModel.pageSize + 1;
    final endIndex =
        (_viewModel.currentPage - 1) * PatientsListViewModel.pageSize +
        _viewModel.patients.length;
    final total =
        _viewModel.totalPatients > 0 ? _viewModel.totalPatients : endIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        final infoWidget = Text(
          "Showing $startIndex–$endIndex of $total patients",
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              label: isMobile ? "Prev" : "Previous",
              onPressed: _viewModel.hasPreviousPage && !_viewModel.isLoading
                  ? () => _viewModel.previousPage()
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.blueBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.blueBorder),
              ),
              child: Text(
                isMobile
                    ? "P. ${_viewModel.currentPage}"
                    : "Page ${_viewModel.currentPage}${_viewModel.totalPages > 1 ? ' of ${_viewModel.totalPages}' : ''}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blueText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildNavButton(
              icon: Icons.chevron_right,
              label: "Next",
              isEndIcon: true,
              onPressed: _viewModel.hasNextPage && !_viewModel.isLoading
                  ? () => _viewModel.nextPage()
                  : null,
            ),
          ],
        );

        return Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 20,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isMobile
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      infoWidget,
                      const SizedBox(height: 8),
                      controls,
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      infoWidget,
                      const SizedBox(width: 20),
                      controls,
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isEndIcon = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        foregroundColor: AppTheme.primaryBlue,
        disabledForegroundColor: Colors.grey.shade400,
        side: BorderSide(
          color:
              onPressed != null ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEndIcon) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
          if (isEndIcon) ...[
            const SizedBox(width: 3),
            Icon(icon, size: 16),
          ],
        ],
      ),
    );
  }
}
