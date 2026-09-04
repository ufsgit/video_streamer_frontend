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
  static const int pageSize = 10;
  int totalPatients = 0;
  int totalPages = 1;
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

  void goToPage(int page) {
    if (page < 1 || (totalPages > 0 && page > totalPages) || page == currentPage || isLoading) {
      return;
    }
    fetchPatients(page: page);
  }

  void nextPage() {
    if (hasNextPage && !isLoading) {
      goToPage(currentPage + 1);
    }
  }

  void previousPage() {
    if (hasPreviousPage && !isLoading) {
      goToPage(currentPage - 1);
    }
  }

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage =>
      currentPage < totalPages ||
      (totalPatients > 0 && currentPage * pageSize < totalPatients) ||
      (totalPatients == 0 && patients.length == pageSize);

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
        limit: pageSize,
      );

      final resData = response.data;
      List<dynamic> rawList = [];

      if (resData is Map<String, dynamic>) {
        // Extract total count from various common backend formats
        totalPatients = resData['total'] ??
            resData['totalCount'] ??
            resData['count'] ??
            (resData['pagination'] is Map ? resData['pagination']['total'] : null) ??
            (resData['meta'] is Map ? resData['meta']['total'] : null) ??
            (resData['data'] is Map
                ? (resData['data']['total'] ??
                    resData['data']['totalCount'] ??
                    resData['data']['count'])
                : null) ??
            0;

        if (resData['data'] is List) {
          rawList = resData['data'];
        } else if (resData['data'] is Map && resData['data']['users'] is List) {
          rawList = resData['data']['users'];
        } else if (resData['users'] is List) {
          rawList = resData['users'];
        } else if (resData['results'] is List) {
          rawList = resData['results'];
        }
      } else if (resData is List) {
        rawList = resData;
        totalPatients = rawList.length;
      }

      patients = rawList
          .map((json) => UserModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      if (totalPatients <= 0) {
        totalPatients = (currentPage - 1) * pageSize + patients.length;
        totalPages = (patients.length == pageSize) ? currentPage + 1 : currentPage;
      } else {
        totalPages = (totalPatients / pageSize).ceil();
        if (totalPages < 1) totalPages = 1;
      }
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
        if (totalPatients > 0) totalPatients--;
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
