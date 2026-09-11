import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class MobileAssignVideosSheet extends StatefulWidget {
  final List<Map<String, dynamic>> selectedVideos;
  final VoidCallback onAssigned;

  const MobileAssignVideosSheet({
    super.key,
    required this.selectedVideos,
    required this.onAssigned,
  });

  @override
  State<MobileAssignVideosSheet> createState() =>
      _MobileAssignVideosSheetState();
}

class _MobileAssignVideosSheetState extends State<MobileAssignVideosSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = false;
  Timer? _debounce;
  late List<Map<String, dynamic>> _currentVideos;

  @override
  void initState() {
    super.initState();
    _currentVideos = List.from(widget.selectedVideos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.listUsers(search: query.trim());
      if (response.statusCode == 200) {
        final resData = response.data;
        List<dynamic> rawList = [];

        if (resData is Map<String, dynamic>) {
          if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['data'] is Map &&
              resData['data']['users'] is List) {
            rawList = resData['data']['users'];
          } else if (resData['users'] is List) {
            rawList = resData['users'];
          }
        } else if (resData is List) {
          rawList = resData;
        }

        setState(() {
          _searchResults = rawList;
        });
      }
    } catch (e) {
      debugPrint("Error searching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignVideos() async {
    if (_selectedUser == null || _currentVideos.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final targetUserId = _selectedUser!['id'] ?? _selectedUser!['_id'];
      final userFetchResponse = await _apiService.getUserById(targetUserId.toString());
      List<dynamic> existingVideos = [];
      if (userFetchResponse.statusCode == 200) {
        final uData = userFetchResponse.data is Map ? userFetchResponse.data : {};
        final innerUser = uData['data'] ?? uData['user'] ?? uData;
        if (innerUser is Map && innerUser['assigned_videos'] is List) {
          existingVideos = List.from(innerUser['assigned_videos']);
        }
      }

      final List<Map<String, dynamic>> newVideos = _currentVideos.map((v) => {
        'id': v['id'],
        'title': v['title'],
        'duration': v['duration'],
        'imageUrl': v['imageUrl'],
        'category': v['category'],
        'isCompleted': false,
        'assignedAt': DateTime.now().toIso8601String(),
      }).toList();

      final combined = [...existingVideos, ...newVideos];

      await _apiService.editUser(targetUserId.toString(), {
        'assigned_videos': combined,
      });

      if (!mounted) return;
      widget.onAssigned();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Assigned ${_currentVideos.length} videos to ${_selectedUser!['name'] ?? _selectedUser!['username'] ?? 'Patient'}",
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      debugPrint("Error assigning videos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to assign videos. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Assign Videos to Patient",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Step 1: Select Patient
          const Text(
            "Select Patient",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          if (_selectedUser == null) ...[
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search patient by name...",
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: Colors.grey.shade600,
                            onPressed: () {
                              _searchController.clear();
                              _searchResults.clear();
                              setState(() {});
                            },
                          )
                        : null),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, i) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final name = user['name'] ?? user['username'] ?? 'Patient';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.secondaryBlue,
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        "ID: ${user['id'] ?? user['_id'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _searchResults.clear();
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      (_selectedUser!['name'] ?? _selectedUser!['username'] ?? 'P')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUser!['name'] ??
                              _selectedUser!['username'] ??
                              'Selected Patient',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Ready for video assignment",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedUser = null),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          // Step 2: Selected Videos List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Videos (${_currentVideos.length})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: _currentVideos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "No videos selected",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _currentVideos.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 8),
                      itemBuilder: (context, index) {
                        final video = _currentVideos[index];
                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                video['imageUrl'],
                                width: 50,
                                height: 35,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 50,
                                  height: 35,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.video_library, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${video['duration']} • ${video['category']}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() {
                                  _currentVideos.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Button
          ElevatedButton(
            onPressed: _selectedUser == null || _currentVideos.isEmpty || _isLoading
                ? null
                : _assignVideos,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Assign ${_currentVideos.length} Videos",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
