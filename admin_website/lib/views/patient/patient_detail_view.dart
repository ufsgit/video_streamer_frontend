import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';

class PatientDetailView extends StatelessWidget {
  final UserModel patient;

  const PatientDetailView({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56, // More compact appbar
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        leadingWidth: 40,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(patient.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)), // Email instead of Patient ID
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 14),
            label: const Text("Edit", style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete, size: 14),
            label: const Text("Delete", style: TextStyle(fontSize: 12)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccountInfoCard()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildEngagementOverviewCard()),
              ],
            ),
            const SizedBox(height: 16),
            _buildVideoHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    final isActive = patient.status.toLowerCase() == "active" || patient.status.isEmpty;
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
              Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 16),
              SizedBox(width: 6),
              Text("Account Info", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("REGISTRATION DATE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(patient.date, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          const Text("STATUS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isActive ? "Active Member" : "Inactive",
              style: TextStyle(
                color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              Text("Engagement Overview", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox("Total Videos Watched", "24"),
              const SizedBox(width: 12),
              _buildStatBox("Total Completed", "18"),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Overall Progress", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text("75%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Spacer(),
                          Icon(Icons.trending_up, color: Colors.green.shade600, size: 16),
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

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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
          const Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryBlue, size: 16),
              SizedBox(width: 6),
              Text("Detailed Video History", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          _buildHistoryItem("Understanding Hypertension", "Nov 14, 2023 • 09:15 AM", true),
          const SizedBox(height: 15),
          _buildHistoryItem("Dietary Guidelines for Heart Health", "Nov 10, 2023 • 02:30 PM", false),
          const SizedBox(height: 15),
          _buildHistoryItem("Medication Management Daily", "Nov 05, 2023 • 11:45 AM", true),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle, bool isCompleted) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 12)),
              const SizedBox(height: 2),
              Text("Viewed: $subtitle", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
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
              Icon(isCompleted ? Icons.check_circle_outline : Icons.access_time, size: 12, color: isCompleted ? Colors.green.shade700 : AppTheme.primaryBlue),
              const SizedBox(width: 4),
              Text(
                isCompleted ? "Completed" : "Incomplete",
                style: TextStyle(
                  color: isCompleted ? Colors.green.shade700 : AppTheme.primaryBlue,
                  fontSize: 9,
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
