import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class PatientsListViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<UserModel> patients = [];
  bool isLoading = false;
  String? errorMessage;

  PatientsListViewModel() {
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.listUsers();
      final List<dynamic> data = response.data['users'] ?? [];
      patients = data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      errorMessage = "Failed to load patients. Using fallback data.";
      _loadFallbackData();
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadFallbackData() {
    patients = [
      UserModel(id: "1", name: "Arthur Pendelton", age: 65, gender: "Male", phone: "(555) 123-4567", email: "arthur.p@example.com", status: "Active", date: "Oct 12, 2023", streak: "5 days", imageUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80"),
      UserModel(id: "2", name: "Martha Stewart", age: 72, gender: "Female", phone: "(555) 987-6543", email: "martha.s@example.com", status: "Inactive", date: "Sep 28, 2023", streak: "0 days", imageUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80"),
      UserModel(id: "3", name: "James Wilson", age: 58, gender: "Male", phone: "(555) 456-7890", email: "j.wilson@example.com", status: "Active", date: "Nov 01, 2023", streak: "12 days", imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80"),
      UserModel(id: "4", name: "Eleanor Rigby", age: 61, gender: "Female", phone: "(555) 321-0987", email: "eleanor.r@example.com", status: "Active", date: "Oct 15, 2023", streak: "2 days", imageUrl: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"),
    ];
  }
}
