import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class AddVideoDialog extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onVideoAdded;
  final Map<String, dynamic>? videoToEdit;

  const AddVideoDialog({super.key, this.onVideoAdded, this.videoToEdit});

  @override
  State<AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<AddVideoDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
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

  YoutubePlayerController? _previewYoutubeController;
  bool _isPreviewing = false;
  String? _previewErrorMessage;

  bool get isEditing => widget.videoToEdit != null;

  @override
  void initState() {
    super.initState();
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
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _languageController.dispose();
    _previewYoutubeController?.close();
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
            final name =
                (item['language_name'] ??
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVideoTitleField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _selectlanguage()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _buildVideoThumbnailSource(),
                    const SizedBox(height: 24),
                    _buildAlternateExternalUrl(),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
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
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.video_call,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Video Details' : 'Add New Video',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: const TextSpan(
                text: 'Video Title ',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                children: [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "Enter video title...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: const TextSpan(
                text: 'Category ',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                children: [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: ['Post-Op', 'Pre-Op'].map((String category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _selectlanguage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: const TextSpan(
                text: 'Select Video Language ',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                children: [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingLanguages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading languages...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value:
                _selectedLanguage != null &&
                    _languageOptions.contains(_selectedLanguage)
                ? _selectedLanguage
                : (_languageOptions.isNotEmpty ? _languageOptions.first : null),
            isExpanded: true,
            hint: const Text(
              'Select a language',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            borderRadius: BorderRadius.circular(8),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _languageOptions.map((String language) {
              return DropdownMenuItem(
                value: language,
                child: Text(
                  language,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                  _languageController.text = newValue;
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Description (Optional)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              'Patient guidance summary',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter video guidance and notes...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnailSource() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '2. Video Thumbnail (Optional)',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Accepts JPG, PNG, WebP (max 2 MB)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_thumbnailBytes != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _thumbnailName ?? 'custom_thumbnail.jpg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_thumbnailBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB • Ready for upload',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickThumbnail,
                  child: const Text(
                    'Replace',
                    style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 20,
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FAFC),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Upload Custom Thumbnail Image (Optional)',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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

    setState(() {
      _previewErrorMessage = null;
      _previewYoutubeController?.close();
      _previewYoutubeController = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          showVideoAnnotations: false,
          enableCaption: true,
        ),
      );
      _isPreviewing = true;
    });
  }

  void _clearPreview() {
    setState(() {
      _isPreviewing = false;
      _previewErrorMessage = null;
      _previewYoutubeController?.close();
      _previewYoutubeController = null;
    });
  }

  Widget _buildAlternateExternalUrl() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: const [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: AppTheme.primaryBlue,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Video URL (YouTube link)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'YouTube Shorts, Watch, Embed',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      onChanged: (val) {
                        if (_isPreviewing) {
                          _clearPreview();
                        } else {
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. https://www.youtube.com/watch?v=...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        _isPreviewing ? 'Hide Preview' : 'Preview Video',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPreviewing
                            ? Colors.grey.shade700
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        onChanged: (val) {
                          if (_isPreviewing) {
                            _clearPreview();
                          } else {
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. https://www.youtube.com/watch?v=...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                      label: Text(_isPreviewing ? 'Hide' : 'Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPreviewing
                            ? Colors.grey.shade700
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              if (_previewErrorMessage != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _previewErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (_isPreviewing && _previewYoutubeController != null) ...[
                const SizedBox(height: 14),
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
            ],
          ),
        );
      },
    );
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
            )
          : await _apiService.createVideo(
              title: title,
              category: _selectedCategory,
              language: language,
              videoUrl: url,
              description: _descriptionController.text.trim(),
              thumbnailBytes: _thumbnailBytes,
              thumbnailFilename: _thumbnailName,
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
          'duration':
              videoData['duration'] ??
              widget.videoToEdit?['duration'] ??
              'Stream',
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
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
                        isEditing ? Icons.save_outlined : Icons.upload,
                        size: 18,
                      ),
                label: Text(
                  _isSubmitting
                      ? (isEditing ? 'Saving...' : 'Creating...')
                      : (isEditing ? 'Save Changes' : 'Add Video'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
