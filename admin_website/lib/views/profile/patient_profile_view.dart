import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PatientProfileView extends StatelessWidget {
  const PatientProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
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
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage("https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=60"),
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
                      const Text("Alex Johnson", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text("(Admin View)", style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Patient ID: #CP-84920", style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text("Active Status", style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.secondaryBlue, borderRadius: BorderRadius.circular(16)),
                        child: const Row(
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
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildPersonalDetailsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
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
          _buildDetailRow("Email Address", "alex.j@example.com", Icons.edit),
          const SizedBox(height: 24),
          _buildDetailRow("Phone Number", "+1 (555) 123-4567", Icons.edit),
          const SizedBox(height: 24),
          _buildDetailRow("Date of Birth", "October 12, 1985", Icons.lock_outline),
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
