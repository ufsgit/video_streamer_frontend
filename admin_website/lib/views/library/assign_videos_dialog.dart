import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class AssignVideosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> selectedVideos;
  final VoidCallback onAssigned;

  const AssignVideosDialog({
    super.key,
    required this.selectedVideos,
    required this.onAssigned,
  });

  @override
  State<AssignVideosDialog> createState() => _AssignVideosDialogState();
}

class _AssignVideosDialogState extends State<AssignVideosDialog> {
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
    _debounce = Timer(const Duration(milliseconds: 500), () {
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
          } else if (resData['data'] is Map && resData['data']['users'] is List) {
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
      // Create a list of video objects to assign
      // The API expects assigned_videos or assignedVideos depending on the implementation.
      // Assuming a generic assigned_videos field for the payload:
      final List<Map<String, dynamic>> videosToAssign = _currentVideos.map((v) => {
        'id': v['id'],
        'title': v['title'],
        'duration': v['duration'],
        'category': v['category'],
        'assignedAt': DateTime.now().toIso8601String(),
      }).toList();

      await _apiService.editUser(
        _selectedUser!['id'].toString(),
        {
          'assigned_videos': videosToAssign,
        }
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${_currentVideos.length} videos successfully assigned to ${_selectedUser!['name'] ?? _selectedUser!['username'] ?? 'User'}.",
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error assigning videos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to assign videos."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onAssigned();
        Navigator.of(context).pop();
      }
    }
  }

  void _removeVideo(Map<String, dynamic> video) {
    setState(() {
      _currentVideos.remove(video);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_ind, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assign Videos to User",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Search for a patient or user and confirm educational video assignments.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Step 2: Select User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("Active Clinical Roster", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedUser == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search and select user...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final name = user['name'] ?? user['username'] ?? 'Unknown';
                          final idStr = user['id']?.toString() ?? 'N/A';
                          final id = idStr.length > 5 ? idStr.substring(0, 5) : idStr;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.secondaryBlue,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text("ID: P$id"),
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
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryBlue),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        (_selectedUser!['name'] ?? _selectedUser!['username'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedUser!['name'] ?? _selectedUser!['username'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "User ID: P${(_selectedUser!['id']?.toString() ?? 'N/A').length > 5 ? (_selectedUser!['id']?.toString() ?? 'N/A').substring(0, 5) : (_selectedUser!['id']?.toString() ?? 'N/A')}",
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 14),
                              SizedBox(width: 4),
                              Text("Selected User", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedUser = null;
                        });
                      },
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Step 3: Selected Videos (${_currentVideos.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("Review videos to be assigned or remove items", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _currentVideos.isEmpty
                    ? const Center(child: Text("No videos selected", style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _currentVideos.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final video = _currentVideos[index];
                          return Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  video['imageUrl'],
                                  width: 60,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 40,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text("${video['duration']} \u2022 ", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            video['category'],
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.check, color: AppTheme.primaryBlue, size: 16),
                                  const SizedBox(width: 4),
                                  const Text("Selected", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                    onPressed: () => _removeVideo(video),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedUser == null || _currentVideos.isEmpty || _isLoading ? null : _assignVideos,
                  icon: _isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.video_library, size: 16),
                  label: const Text("Add Videos"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
