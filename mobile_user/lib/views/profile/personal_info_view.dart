import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class PersonalInfoView extends StatelessWidget {
  final UserModel? user;

  const PersonalInfoView({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name.isNotEmpty == true ? user!.name : 'Loading...';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    
    // For now, if age is missing, we calculate a mock age or show standard text.
    final dob = user?.dateOfBirth ?? 'Not provided';
    final ageStr = user?.age != null ? '${user!.age} yrs' : '-';
    final sexStr = user?.sex ?? 'Not provided';
    final email = user?.email ?? 'Not provided';
    final phone = user?.phoneNumber ?? 'Not provided';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF152C5B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF152C5B),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF027A48),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Top Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Gradient Border
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(3), // Border width
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : 'JD',
                            style: const TextStyle(
                              color: Color(0xFF0052CC),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personal Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF027A48).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF027A48),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name Box
                  _buildInfoBox(
                    label: 'Full Name',
                    value: name,
                  ),
                  const SizedBox(height: 12),

                  // DOB and Age Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInfoBox(
                          label: 'Date of Birth',
                          value: dob,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInfoBox(
                          label: 'Age',
                          value: ageStr,
                          icon: Icons.hourglass_bottom_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sex Box
                  _buildInfoBox(
                    label: 'Sex',
                    value: sexStr,
                    icon: Icons.female_rounded, // Using female icon as default per UI, can be logic based later
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.contact_mail_outlined,
                          color: Color(0xFF0052CC),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email Box
                  _buildInfoBoxWithTrailingIcon(
                    label: 'Email',
                    value: email,
                    trailingIcon: Icons.email_rounded,
                    trailingIconColor: const Color(0xFF027A48),
                  ),
                  const SizedBox(height: 12),

                  // Phone Number Box
                  _buildInfoBoxWithTrailingIcon(
                    label: 'Phone Number',
                    value: phone,
                    trailingIcon: Icons.phone_rounded,
                    trailingIconColor: const Color(0xFF027A48),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF667085)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBoxWithTrailingIcon({
    required String label,
    required String value,
    required IconData trailingIcon,
    required Color trailingIconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trailingIconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              trailingIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
