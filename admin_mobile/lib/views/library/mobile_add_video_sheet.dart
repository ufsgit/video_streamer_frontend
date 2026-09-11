import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class MobileAddVideoSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onVideoAdded;
  final Map<String, dynamic>? videoToEdit;

  const MobileAddVideoSheet({
    super.key,
    this.onVideoAdded,
    this.videoToEdit,
  });

  @override
  State<MobileAddVideoSheet> createState() => _MobileAddVideoSheetState();
}

class _MobileAddVideoSheetState extends State<MobileAddVideoSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedCategory = 'Post-Op';
  String? _selectedLanguage;
  List<String> _languageOptions = [];
  bool _isLoadingLanguages = true;
  Uint8List? _thumbnailBytes;
  String? _thumbnailName;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _detectedDurationSeconds;
  String? _currentDetectingYtId;

  YoutubePlayerController? _previewYoutubeController;
  YoutubePlayerController? _detectorController;
  bool _isPreviewing = false;
  String? _previewErrorMessage;

  bool get isEditing => widget.videoToEdit != null;

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int? _parseDuration(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return (m * 60) + s;
      } else if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return (h * 3600) + (m * 60) + s;
      }
    }
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.round();
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    final ytId = _extractYtId(url);
    if (ytId != null && ytId.isNotEmpty) {
      _autoDetectDuration(ytId);
      _autoLoadPreview(ytId);
    } else {
      if (_isPreviewing) {
        _clearPreview();
      }
    }
  }

  void _autoDetectDuration(String ytId) {
    if (_currentDetectingYtId == ytId && _detectedDurationSeconds != null) return;
    _currentDetectingYtId = ytId;

    _detectorController?.close();
    final controller = YoutubePlayerController.fromVideoId(
      videoId: ytId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: true,
      ),
    );

    controller.listen((value) async {
      try {
        final dur = await controller.duration;
        if (dur > 0 && mounted) {
          final secs = dur.round();
          if (_detectedDurationSeconds != secs) {
            setState(() {
              _detectedDurationSeconds = secs;
            });
          }
        }
      } catch (_) {}
    });

    if (mounted) {
      setState(() {
        _detectorController = controller;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _fetchLanguages();
    if (widget.videoToEdit != null) {
      final v = widget.videoToEdit!;
      _titleController.text = v['title']?.toString() ?? '';
      _descriptionController.text = v['description']?.toString() ?? '';
      _urlController.text =
          v['youtubeUrl']?.toString() ??
          v['video_url']?.toString() ??
          v['url']?.toString() ??
          '';

      final existingDur =
          v['total_duration_seconds'] ?? v['duration_seconds'] ?? v['duration'];
      if (existingDur != null) {
        if (existingDur is num) {
          _detectedDurationSeconds = existingDur.round();
        } else {
          final str = existingDur.toString().trim();
          final parsed = _parseDuration(str);
          if (parsed != null && parsed > 0) {
            _detectedDurationSeconds = parsed;
          }
        }
      }

      final cat = (v['category']?.toString() ?? '').toLowerCase();
      if (cat.contains('pre')) {
        _selectedCategory = 'Pre-Op';
      } else {
        _selectedCategory = 'Post-Op';
      }

      final lang = (v['language']?.toString() ?? '').trim();
      if (lang.isNotEmpty) {
        _selectedLanguage = lang;
        _languageController.text = lang;
      }

      final url = _urlController.text.trim();
      final ytId = _extractYtId(url);
      if (ytId != null && ytId.isNotEmpty) {
        _autoDetectDuration(ytId);
        _previewYoutubeController = YoutubePlayerController.fromVideoId(
          videoId: ytId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: false,
            mute: false,
          ),
        );
        _isPreviewing = true;
      }
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _previewYoutubeController?.close();
    _detectorController?.close();
    super.dispose();
  }

  Future<void> _fetchLanguages() async {
    try {
      final response = await _apiService.listLanguages();
      if (response.statusCode == 200) {
        final resData = response.data;
        List<dynamic> rawList = [];
        if (resData is Map<String, dynamic>) {
          if (resData['data'] is List) {
            rawList = resData['data'];
          } else if (resData['languages'] is List) {
            rawList = resData['languages'];
          }
        } else if (resData is List) {
          rawList = resData;
        }

        final List<String> parsed = [];
        for (var item in rawList) {
          if (item is String && item.trim().isNotEmpty) {
            final val = item.trim();
            if (!parsed.any((p) => p.toLowerCase() == val.toLowerCase())) {
              parsed.add(val);
            }
          } else if (item is Map) {
            final name = (item['language_name'] ??
                    item['languageName'] ??
                    item['name'] ??
                    item['language'] ??
                    item['title'] ??
                    item['code'] ??
                    '')
                .toString()
                .trim();
            if (name.isNotEmpty &&
                !parsed.any((p) => p.toLowerCase() == name.toLowerCase())) {
              parsed.add(name);
            }
          }
        }

        if (mounted) {
          setState(() {
            _languageOptions = parsed;
            _isLoadingLanguages = false;

            final existingLang =
                (widget.videoToEdit?['language']?.toString() ??
                        _languageController.text)
                    .trim();
            if (existingLang.isNotEmpty) {
              final match = _languageOptions.firstWhere(
                (l) => l.toLowerCase() == existingLang.toLowerCase(),
                orElse: () => '',
              );
              if (match.isNotEmpty) {
                _selectedLanguage = match;
              } else {
                _languageOptions.add(existingLang);
                _selectedLanguage = existingLang;
              }
            } else if (_languageOptions.isNotEmpty &&
                (_selectedLanguage == null ||
                    !_languageOptions.contains(_selectedLanguage))) {
              _selectedLanguage = _languageOptions.first;
            }

            if (_selectedLanguage != null) {
              _languageController.text = _selectedLanguage!;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLanguages = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching languages from API: $e");
      if (mounted) {
        setState(() {
          _isLoadingLanguages = false;
        });
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage = "Thumbnail image must be under 2 MB.";
          });
          return;
        }
        setState(() {
          _thumbnailBytes = bytes;
          _thumbnailName = picked.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Error picking thumbnail image: $e");
    }
  }

  String? _extractYtId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) return match.group(1);
    return null;
  }

  String? _currentPreviewYtId;

  void _autoLoadPreview(String ytId, {bool autoPlay = false}) {
    if (_previewYoutubeController != null &&
        _isPreviewing &&
        _currentPreviewYtId == ytId) {
      return;
    }
    _currentPreviewYtId = ytId;

    final controller = YoutubePlayerController.fromVideoId(
      videoId: ytId,
      autoPlay: autoPlay,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        showVideoAnnotations: false,
        enableCaption: true,
      ),
    );

    controller.listen((value) async {
      try {
        final dur = await controller.duration;
        if (dur > 0 && mounted) {
          final secs = dur.round();
          if (_detectedDurationSeconds != secs) {
            setState(() {
              _detectedDurationSeconds = secs;
            });
          }
        }
      } catch (_) {}
    });

    setState(() {
      _previewErrorMessage = null;
      _previewYoutubeController?.close();
      _previewYoutubeController = controller;
      _isPreviewing = true;
    });
  }

  void _toggleOrLoadPreview() {
    if (_isPreviewing) {
      _clearPreview();
      return;
    }

    final url = _urlController.text.trim();
    final ytId = _extractYtId(url);
    if (ytId == null) {
      setState(() {
        _previewErrorMessage = "Invalid YouTube URL or Video ID";
      });
      return;
    }

    _autoLoadPreview(ytId, autoPlay: true);
  }

  void _clearPreview() {
    setState(() {
      _currentPreviewYtId = null;
      _isPreviewing = false;
      _previewErrorMessage = null;
      _previewYoutubeController?.close();
      _previewYoutubeController = null;
    });
  }

  Future<void> _submitVideo() async {
    final title = _titleController.text.trim();
    final language = _languageController.text.trim().isNotEmpty
        ? _languageController.text.trim()
        : (_selectedLanguage ?? '');
    final url = _urlController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = "Video title is required.";
      });
      return;
    }

    if (language.isEmpty) {
      setState(() {
        _errorMessage = "Language is required.";
      });
      return;
    }

    if (url.isEmpty) {
      setState(() {
        _errorMessage = "Video URL is required (e.g. YouTube link).";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    if (_detectedDurationSeconds == null && _detectorController != null) {
      try {
        final dur = await _detectorController!.duration;
        if (dur > 0) {
          _detectedDurationSeconds = dur.round();
        }
      } catch (_) {}
    }
    if (_detectedDurationSeconds == null && _previewYoutubeController != null) {
      try {
        final dur = await _previewYoutubeController!.duration;
        if (dur > 0) {
          _detectedDurationSeconds = dur.round();
        }
      } catch (_) {}
    }
    final totalDurationSeconds = _detectedDurationSeconds;

    try {
      final response = isEditing
          ? await _apiService.editVideo(
              widget.videoToEdit!['id']?.toString() ??
                  widget.videoToEdit!['_id']?.toString() ??
                  '',
              title: title,
              category: _selectedCategory,
              language: language,
              videoUrl: url,
              description: _descriptionController.text.trim(),
              thumbnailBytes: _thumbnailBytes,
              thumbnailFilename: _thumbnailName,
              totalDurationSeconds: totalDurationSeconds,
            )
          : await _apiService.createVideo(
              title: title,
              category: _selectedCategory,
              language: language,
              videoUrl: url,
              description: _descriptionController.text.trim(),
              thumbnailBytes: _thumbnailBytes,
              thumbnailFilename: _thumbnailName,
              totalDurationSeconds: totalDurationSeconds,
            );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final resData = response.data;
        Map<String, dynamic> videoData = {};
        if (resData is Map<String, dynamic>) {
          if (resData['data'] is Map<String, dynamic>) {
            videoData = Map<String, dynamic>.from(resData['data']);
          } else if (resData['video'] is Map<String, dynamic>) {
            videoData = Map<String, dynamic>.from(resData['video']);
          } else {
            videoData = Map<String, dynamic>.from(resData);
          }
        }

        final ytId = _extractYtId(url);
        final rawApiThumb =
            videoData['thumbnail_url'] ??
            videoData['thumbnail'] ??
            videoData['thumbnailUrl'] ??
            videoData['image_url'] ??
            videoData['imageUrl'] ??
            videoData['image'] ??
            videoData['thumbnail_path'] ??
            (isEditing ? widget.videoToEdit!['imageUrl'] : null);

        String thumbUrl = '';
        if (rawApiThumb != null && rawApiThumb.toString().trim().isNotEmpty) {
          thumbUrl = _apiService.getFullImageUrl(rawApiThumb.toString().trim());
        } else if (ytId != null && ytId.isNotEmpty) {
          thumbUrl = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
        } else {
          thumbUrl =
              'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=500&q=60';
        }

        String formattedDuration = 'Stream';
        if (videoData['duration'] != null &&
            videoData['duration'].toString().trim().isNotEmpty) {
          formattedDuration = videoData['duration'].toString().trim();
        } else if (totalDurationSeconds != null && totalDurationSeconds > 0) {
          formattedDuration = _formatDuration(totalDurationSeconds);
        } else if (widget.videoToEdit?['duration'] != null) {
          formattedDuration = widget.videoToEdit!['duration'].toString();
        }

        final savedVideo = {
          'id':
              videoData['id']?.toString() ??
              videoData['_id']?.toString() ??
              widget.videoToEdit?['id']?.toString() ??
              widget.videoToEdit?['_id']?.toString() ??
              'vid_${DateTime.now().millisecondsSinceEpoch}',
          'videoId': ytId,
          'title': videoData['title'] ?? title,
          'language': videoData['language'] ?? language,
          'description':
              videoData['description'] ?? _descriptionController.text.trim(),
          'category': videoData['category'] ?? _selectedCategory,
          'duration': formattedDuration,
          'total_duration_seconds':
              totalDurationSeconds ?? videoData['total_duration_seconds'],
          'youtubeUrl': url,
          'imageUrl': thumbUrl,
          'thumbnail_url': thumbUrl,
          'thumbnail': thumbUrl,
        };

        widget.onVideoAdded?.call(savedVideo);
        if (mounted) {
          Navigator.of(context).pop(savedVideo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? "Video '$title' updated successfully!"
                    : "Video '$title' added successfully!",
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = "Server returned status code ${response.statusCode}";
        });
      }
    } catch (e) {
      debugPrint("Error saving video: $e");
      String err = isEditing
          ? "Failed to update video."
          : "Failed to create video.";
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          err = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          err = data['error'].toString();
        } else if (e.message != null) {
          err = e.message!;
        }
      }
      setState(() {
        _errorMessage = err;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.video_call,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? "Edit Clinical Video" : "Add Clinical Video",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Video Title
            Row(
              children: const [
                Text(
                  "Video Title ",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text("*", style: TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "e.g., Post-Op ACL Recovery Protocol",
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
            const SizedBox(height: 16),

            // Language and Category Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "Language ",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text("*", style: TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingLanguages)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Loading...",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage != null &&
                                  _languageOptions.contains(_selectedLanguage)
                              ? _selectedLanguage
                              : (_languageOptions.isNotEmpty
                                  ? _languageOptions.first
                                  : null),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
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
                          items: _languageOptions.map((lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(
                                lang,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedLanguage = val;
                                _languageController.text = val;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Category Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "Category ",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text("*", style: TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
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
                        items: ['Post-Op', 'Pre-Op'].map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_detectorController != null)
              Offstage(
                offstage: true,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: YoutubePlayer(controller: _detectorController!),
                ),
              ),

            // Video URL
            Row(
              children: const [
                Text(
                  "Video URL (YouTube) ",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text("*", style: TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "https://youtube.com/watch?v=...",
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _urlController.clear();
                                _clearPreview();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
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
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _urlController.text.trim().isNotEmpty
                      ? _toggleOrLoadPreview
                      : null,
                  icon: Icon(
                    _isPreviewing
                        ? Icons.visibility_off_outlined
                        : Icons.play_circle_fill,
                    size: 16,
                  ),
                  label: Text(
                    _isPreviewing ? "Hide" : "Preview",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPreviewing
                        ? Colors.grey.shade700
                        : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            if (_previewErrorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _previewErrorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (_isPreviewing && _previewYoutubeController != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _previewYoutubeController!,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Thumbnail Upload Section
            const Text(
              "Thumbnail (Optional)",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (_thumbnailBytes != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 60,
                        height: 40,
                        color: Colors.grey.shade200,
                        child: Image.memory(_thumbnailBytes!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _thumbnailName ?? 'custom_thumbnail.jpg',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_thumbnailBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB • Ready for upload',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _pickThumbnail,
                      child: const Text(
                        'Replace',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _thumbnailBytes = null;
                          _thumbnailName = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _pickThumbnail,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Upload Custom Thumbnail (Optional)',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Description
            const Text(
              "Description (Optional)",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Clinical instructions and goals...",
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(12),
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
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitVideo,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isEditing ? Icons.save_outlined : Icons.upload_rounded,
                      size: 18,
                    ),
              label: Text(
                _isSubmitting
                    ? (isEditing ? "Saving..." : "Creating...")
                    : (isEditing ? "Save Video Changes" : "Save & Publish Video"),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
