import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'create_patient_dialog.dart';

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  // Dummy data for the UI demonstration
  final List<Map<String, dynamic>> patients = [
    {
      "name": "Arthur Pendelton",
      "age": 65,
      "gender": "Male",
      "phone": "(555) 123-4567",
      "email": "arthur.p@example.com",
      "status": "Active",
      "date": "Oct 12, 2023",
      "streak": "5 days",
      "imageUrl": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80",
    },
    {
      "name": "Martha Stewart",
      "age": 72,
      "gender": "Female",
      "phone": "(555) 987-6543",
      "email": "martha.s@example.com",
      "status": "Inactive",
      "date": "Sep 28, 2023",
      "streak": "0 days",
      "imageUrl": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80",
    },
    {
      "name": "James Wilson",
      "age": 58,
      "gender": "Male",
      "phone": "(555) 456-7890",
      "email": "j.wilson@example.com",
      "status": "Active",
      "date": "Nov 01, 2023",
      "streak": "12 days",
      "imageUrl": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
    },
    {
      "name": "Eleanor Rigby",
      "age": 61,
      "gender": "Female",
      "phone": "(555) 321-0987",
      "email": "eleanor.r@example.com",
      "status": "Active",
      "date": "Oct 15, 2023",
      "streak": "2 days",
      "imageUrl": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePatientDialog(),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add Patient"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Patients",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage and view patient information and progress.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search patients by name, ID, or email...",
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.filter_list, size: 20, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text("Filter", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 210, // Fixed height for cards to match the design, increased to prevent overflow
                ),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return _buildPatientCard(patients[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final isActive = patient["status"] == "Active";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  patient["imageUrl"],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            patient["name"],
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.successLight : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            patient["status"],
                            style: TextStyle(
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${patient["age"]}, ${patient["gender"]}",
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(patient["phone"], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            patient["email"],
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(patient["date"], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.local_fire_department_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(patient["streak"], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
