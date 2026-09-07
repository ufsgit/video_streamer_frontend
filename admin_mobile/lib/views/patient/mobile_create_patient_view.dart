import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class MobileCreatePatientView extends StatefulWidget {
  final UserModel? patientToEdit;

  const MobileCreatePatientView({super.key, this.patientToEdit});

  @override
  State<MobileCreatePatientView> createState() =>
      _MobileCreatePatientViewState();
}

class _MobileCreatePatientViewState extends State<MobileCreatePatientView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedSex = 'Male';
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  String _selectedStatus = 'Active';
  final List<String> _statusOptions = ['Active', 'Inactive'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  bool get isEditing => widget.patientToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      _nameController.text = p.name;
      _usernameController.text = p.username;
      _emailController.text = p.email == "N/A" ? "" : p.email;
      _phoneController.text = p.phone == "N/A" ? "" : p.phone;
      _dobController.text = p.dob;
      _ageController.text = p.age > 0 ? p.age.toString() : '';
      _noteController.text = p.note;
      if (p.gender.isNotEmpty) {
        final match = _sexOptions.firstWhere(
          (s) => s.toLowerCase() == p.gender.toLowerCase(),
          orElse: () => 'Male',
        );
        _selectedSex = match;
      }
      if (p.status.isNotEmpty) {
        final matchStatus = _statusOptions.firstWhere(
          (s) => s.toLowerCase() == p.status.toLowerCase(),
          orElse: () => 'Active',
        );
        _selectedStatus = matchStatus;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        final now = DateTime.now();
        int calculatedAge = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          calculatedAge--;
        }
        _ageController.text = calculatedAge > 0 ? calculatedAge.toString() : '0';
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!isEditing && _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Password is required for new patients.');
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String username = _usernameController.text.trim().isNotEmpty
          ? _usernameController.text.trim()
          : _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

      final Map<String, dynamic> dataMap = {
        'name': _nameController.text.trim(),
        'username': username,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'phone_number': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'sex': _selectedSex,
        'status': _selectedStatus,
        'dob': _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : null,
        'age': int.tryParse(_ageController.text.trim()),
        'note': _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      };

      if (_passwordController.text.isNotEmpty) {
        dataMap['password'] = _passwordController.text;
      }

      dynamic payload;
      if (_selectedImageBytes != null) {
        final formData = FormData.fromMap({
          ...dataMap,
          'photo': MultipartFile.fromBytes(
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'profile.jpg',
          ),
        });
        payload = formData;
      } else {
        payload = dataMap;
      }

      Response response;
      if (isEditing) {
        response = await ApiService().editUser(
          widget.patientToEdit!.id,
          payload,
        );
      } else {
        response = await ApiService().createUser(payload);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? "Patient profile updated successfully"
                  : "Patient registered successfully",
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.data?['message']?.toString() ??
              'Failed to save patient profile.';
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to save patient. Please check input.';
        if (e is DioException) {
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            errorMsg = e.response!.data['message'].toString();
          } else if (e.type == DioExceptionType.connectionError) {
            errorMsg = 'Cannot reach server. Please check backend connection.';
          }
        }
        setState(() => _errorMessage = errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Patient" : "New Patient",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12.5),
                    ),
                  ),

                // Avatar / Photo Picker
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.secondaryBlue,
                        backgroundImage: _selectedImageBytes != null
                            ? MemoryImage(_selectedImageBytes!)
                            : null,
                        child: _selectedImageBytes == null
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.primaryBlue,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: Text(
                      _selectedImageBytes != null
                          ? "Change Photo"
                          : "Upload Photo",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Name
                _buildFieldLabel("Full Legal Name *"),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("e.g. Jane Doe", Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Name is required"
                      : null,
                ),
                const SizedBox(height: 16),

                // Username
                _buildFieldLabel("Username (Optional)"),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration("e.g. janedoe", Icons.alternate_email),
                ),
                const SizedBox(height: 16),

                // Email & Phone
                _buildFieldLabel("Email Address"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration("patient@hospital.org", Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Phone Number"),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("(555) 000-0000", Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                // Sex & Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Gender"),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSex,
                            decoration: _inputDecoration("", null),
                            items: _sexOptions.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedSex = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Status"),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStatus,
                            decoration: _inputDecoration("", null),
                            items: _statusOptions.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedStatus = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // DOB & Age
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Date of Birth"),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: _inputDecoration(
                              "DD-MM-YYYY",
                              Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Age"),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("e.g. 35", null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password fields if creating or resetting
                _buildFieldLabel(isEditing ? "New Password (Leave blank to keep)" : "Password *"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!isEditing || _passwordController.text.isNotEmpty) ...[
                  _buildFieldLabel("Confirm Password"),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: "Confirm password",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                _buildFieldLabel("Clinical Notes"),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: _inputDecoration("Primary diagnosis, allergies, mobility notes...", null),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _savePatient,
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? "Save Patient Changes" : "Create Patient Profile",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}
