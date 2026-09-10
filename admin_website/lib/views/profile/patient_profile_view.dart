import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../services/api_service.dart';

class PatientProfileView extends StatefulWidget {
  const PatientProfileView({super.key});

  @override
  State<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends State<PatientProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = _viewModel.user;
          final name = user?.name.isNotEmpty == true ? user!.name : 'Admin User';
          final email = user?.email.isNotEmpty == true ? user!.email : 'No email provided';
          final phone = user?.phone.isNotEmpty == true ? user!.phone : 'N/A';
          final dob = user?.dob.isNotEmpty == true ? user!.dob : 'N/A';
          final avatarUrl = user?.imageUrl.isNotEmpty == true
              ? ApiService().getFullImageUrl(user!.imageUrl)
              : "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=60"; // fallback

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Top Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(avatarUrl),
                            onBackgroundImageError: (exception, stackTrace) {},
                            child: user?.imageUrl.isEmpty == true ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Text("(Admin View)", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("ID: #${user?.id ?? 'N/A'}", style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                                const SizedBox(width: 4),
                                Text(user?.status ?? "Active Status", style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.secondaryBlue, borderRadius: BorderRadius.circular(16)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 16, color: AppTheme.textSecondary),
                                SizedBox(width: 4),
                                Text("Administrative Access", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildPersonalDetailsCard(
                      email: email,
                      phone: phone,
                      dob: dob,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalDetailsCard({
    required String email,
    required String phone,
    required String dob,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          _buildDetailRow("Email Address", email, Icons.edit),
          const SizedBox(height: 24),
          _buildDetailRow("Phone Number", phone, Icons.edit),
          const SizedBox(height: 24),
          _buildDetailRow("Date of Birth", dob, Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData trailingIcon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Icon(trailingIcon, color: AppTheme.primaryBlue, size: 20),
      ],
    );
  }
}
