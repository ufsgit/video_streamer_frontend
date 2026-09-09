import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../navigation/main_navigation_view.dart';

class LanguageSelectionDialog extends StatefulWidget {
  final List<String>? languages;
  const LanguageSelectionDialog({super.key, this.languages});

  @override
  State<LanguageSelectionDialog> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  List<Map<String, dynamic>> _languagesData = [];
  List<String> _languages = [];
  bool _isLoading = true;
  String? _selectedLanguage;
  int? _selectedLanguageId;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    try {
      final response = await DioClient().dio.get(ApiConstants.userLanguagesPath);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'];
        if (mounted) {
          setState(() {
            _languagesData = List<Map<String, dynamic>>.from(dataList);
            final uniqueNames = <String>{};
            _languagesData.retainWhere((item) => uniqueNames.add(item['language_name'].toString()));
            _languages = uniqueNames.toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveAndContinue() async {
    if (_selectedLanguage == null) return;

    var box = Hive.box('settings');
    await box.put('selected_language', _selectedLanguage);
    if (_selectedLanguageId != null) {
      await box.put('selected_language_id', _selectedLanguageId);
    }
    
    // For debugging as requested
    print('DEBUG: Hive stored language -> ${box.get('selected_language')} (ID: ${box.get('selected_language_id')})');

    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152C5B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select your preferred language to continue.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF0052CC)),
                ),
              )
            else if (_languages.isEmpty)
              const Text(
                'No languages available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEDF2F7)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Choose a language'),
                    ),
                    isExpanded: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.arrow_drop_down),
                    ),
                    items: _languages.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(lang),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedLanguage = value;
                        if (value != null) {
                          final selectedObj = _languagesData.firstWhere(
                            (item) => item['language_name'].toString() == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selectedObj.isNotEmpty && selectedObj['id'] != null) {
                            _selectedLanguageId = int.tryParse(selectedObj['id'].toString());
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedLanguage == null || _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
