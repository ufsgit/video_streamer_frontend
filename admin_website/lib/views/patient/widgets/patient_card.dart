import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';

class PatientCard extends StatelessWidget {
  final UserModel patient;
  final VoidCallback? onTap;

  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive =
        patient.status.toLowerCase() == "active" || patient.status.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top & Middle body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar, Name & ID, Gender/Age, Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientAvatar(patient, isActive),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      patient.name.isNotEmpty
                                          ? patient.name
                                          : (patient.username.isNotEmpty
                                                ? patient.username
                                                : 'Unnamed'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_formatPatientId(patient.id).isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _formatPatientId(patient.id),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              _buildGenderAndAge(patient),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive
                                    ? "Active"
                                    : (patient.status.isNotEmpty
                                          ? patient.status
                                          : "Inactive"),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Middle Row: Phone Tile (hugs content, not full width)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildInfoTile(
                        icon: Icons.phone_rounded,
                        label: 'PHONE',
                        value: patient.phone.trim(),
                        hasValue:
                            patient.phone.trim().isNotEmpty &&
                            patient.phone.trim().toLowerCase() != 'n/a' &&
                            patient.phone.trim().toLowerCase() != 'none',
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Footer: Registered Date & View Details
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFC),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15)),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Registered: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _formatDate(patient.date),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderAndAge(UserModel patient) {
    final gender = patient.gender.trim().toLowerCase();
    final isMale = gender == 'male' || gender == 'm';
    final isFemale = gender == 'female' || gender == 'f';

    IconData genderIcon = Icons.person_outline_rounded;
    Color genderColor = const Color(0xFF64748B);
    String genderText = patient.gender.trim();
    if (genderText.isEmpty) {
      genderText = 'Not specified';
    } else {
      genderText =
          genderText[0].toUpperCase() + genderText.substring(1).toLowerCase();
    }

    if (isMale) {
      genderIcon = Icons.male_rounded;
      genderColor = const Color(0xFF3B82F6);
    } else if (isFemale) {
      genderIcon = Icons.female_rounded;
      genderColor = const Color(0xFFEC4899);
    }

    final hasAge = patient.age > 0;

    return Row(
      children: [
        Icon(genderIcon, size: 14, color: genderColor),
        const SizedBox(width: 3),
        Text(
          genderText,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '•',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ),
        Text(
          hasAge ? '${patient.age} yrs' : 'Age not specified',
          style: TextStyle(
            color: hasAge ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontWeight: hasAge ? FontWeight.w500 : FontWeight.normal,
            fontStyle: hasAge ? FontStyle.normal : FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool hasValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasValue ? value : 'Not provided',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  color: hasValue
                      ? const Color(0xFF334155)
                      : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar(UserModel patient, bool isActive) {
    final photoUrl = patient.imageUrl.trim();
    final bool hasImage =
        photoUrl.isNotEmpty &&
        photoUrl.toLowerCase() != 'null' &&
        photoUrl.toLowerCase() != 'n/a' &&
        photoUrl.toLowerCase() != 'undefined' &&
        photoUrl.toLowerCase() != 'none';

    Widget avatarContent;

    if (!hasImage) {
      avatarContent = _buildInitialsAvatar(patient);
    } else {
      final fullUrl = ApiService().getFullImageUrl(photoUrl);

      if (fullUrl.startsWith('data:image')) {
        try {
          final commaIndex = fullUrl.indexOf(',');
          if (commaIndex != -1) {
            final bytes = base64Decode(fullUrl.substring(commaIndex + 1));
            avatarContent = ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                bytes,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialsAvatar(patient),
              ),
            );
          } else {
            avatarContent = _buildInitialsAvatar(patient);
          }
        } catch (_) {
          avatarContent = _buildInitialsAvatar(patient);
        }
      } else {
        avatarContent = FutureBuilder<Uint8List?>(
          future: ApiService().fetchImageBytes(photoUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.isNotEmpty) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  snapshot.data!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitialsAvatar(patient),
                ),
              );
            }

            if (fullUrl.startsWith('http://') ||
                fullUrl.startsWith('https://')) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fullUrl,
                  width: 50,
                  height: 50,
                  headers: const {
                    'bypass-tunnel-reminder': 'true',
                    'X-Tunnel-Bypass': 'true',
                  },
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitialsAvatar(patient),
                ),
              );
            }

            return _buildInitialsAvatar(patient);
          },
        );
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarContent,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(UserModel patient) {
    final rawName = patient.name.trim().isNotEmpty
        ? patient.name.trim()
        : (patient.username.trim().isNotEmpty
              ? patient.username.trim()
              : 'Patient');
    final initial = rawName.isNotEmpty ? rawName[0].toUpperCase() : 'P';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF4F46E5),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  String _formatPatientId(String id) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return '';
    final num = int.tryParse(cleanId);
    if (num != null) {
      return '#${num.toString().padLeft(3, '0')}';
    }
    if (cleanId.startsWith('#')) return cleanId;
    return '#$cleanId';
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return "Today";
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
      }
    } catch (_) {}
    if (rawDate.length >= 10) {
      return rawDate.substring(0, 10);
    }
    return rawDate;
  }
}
