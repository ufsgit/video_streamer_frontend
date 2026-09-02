import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class PatientsListViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<UserModel> patients = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  int currentPage = 1;
  int totalPatients = 0;
  Timer? _debounceTimer;

  PatientsListViewModel() {
    fetchPatients();
  }

  void searchPatients(String query) {
    searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchPatients(search: query, page: 1);
    });
  }

  void clearSearch() {
    searchQuery = '';
    _debounceTimer?.cancel();
    fetchPatients(search: '', page: 1);
  }

  Future<void> fetchPatients({String? search, int page = 1}) async {
    isLoading = true;
    errorMessage = null;
    currentPage = page;
    if (search != null) {
      searchQuery = search;
    }
    notifyListeners();

    try {
      final response = await _apiService.listUsers(
        search: searchQuery.trim().isNotEmpty ? searchQuery.trim() : null,
        page: currentPage,
        limit: 50,
      );

      final resData = response.data;
      List<dynamic> rawList = [];

      if (resData is Map<String, dynamic>) {
        if (resData['data'] is List) {
          rawList = resData['data'];
        } else if (resData['data'] is Map && resData['data']['users'] is List) {
          rawList = resData['data']['users'];
          totalPatients = resData['data']['total'] ?? rawList.length;
        } else if (resData['users'] is List) {
          rawList = resData['users'];
          totalPatients = resData['total'] ?? rawList.length;
        }
      } else if (resData is List) {
        rawList = resData;
      }

      patients = rawList
          .map((json) => UserModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      errorMessage = "Failed to load patients.";
      debugPrint("fetchPatients error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePatient(String id) async {
    try {
      final response = await _apiService.deleteUser(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        patients.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("deletePatient error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
