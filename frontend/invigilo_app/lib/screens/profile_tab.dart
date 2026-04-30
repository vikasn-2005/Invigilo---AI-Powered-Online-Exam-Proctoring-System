import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _uploadingImage = false;
  String? _profileImageFilename;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final data = await ApiService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profile = data;
        _profileImageFilename =
            data?['profileImage'] as String? ??
                prefs.getString('user_profile_image');
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Photo',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F5FE),
                child: Icon(Icons.camera_alt, color: Color(0xFF4FC3F7)),
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F5FE),
                child:
                Icon(Icons.photo_library, color: Color(0xFF4FC3F7)),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profileImageFilename != null &&
                _profileImageFilename!.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                ),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context, null),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return; // dismissed

    final picked =
    await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    final filename =
    await ApiService.uploadProfileImage(File(picked.path));

    if (mounted) {
      setState(() {
        _uploadingImage = false;
        if (filename != null) {
          _profileImageFilename = filename;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filename != null
              ? 'Profile photo updated!'
              : 'Upload failed. Try again.'),
          backgroundColor: filename != null
              ? const Color(0xFF66BB6A)
              : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    final name = _profile?['name'] ?? 'Unknown';
    final email = _profile?['email'] ?? '—';
    final initials = name.isNotEmpty
        ? name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join()
        : '?';

    final hasImage = _profileImageFilename != null &&
        _profileImageFilename!.isNotEmpty;
    final imageUrl = hasImage
        ? ApiService.profileImageUrl(_profileImageFilename!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Avatar with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Profile image circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF4FC3F7), width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF4FC3F7).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2),
                  ],
                ),
                child: ClipOval(
                  child: _uploadingImage
                      ? Container(
                    color: const Color(0xFFE1F5FE),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4FC3F7),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                      : hasImage
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFFE1F5FE),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4FC3F7),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        _InitialsAvatar(
                            initials: initials),
                  )
                      : _InitialsAvatar(initials: initials),
                ),
              ),

              // Edit button
              GestureDetector(
                onTap: _uploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7),
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4FC3F7))),
          const SizedBox(height: 4),
          Text(email,
              style:
              const TextStyle(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 8),

          // Tap to change photo hint
          GestureDetector(
            onTap: _uploadingImage ? null : _pickAndUploadImage,
            child: Text(
              _uploadingImage
                  ? 'Uploading...'
                  : hasImage
                  ? 'Tap photo to change'
                  : 'Tap to add profile photo',
              style: TextStyle(
                  color: _uploadingImage
                      ? Colors.black26
                      : const Color(0xFF4FC3F7),
                  fontSize: 12,
                  decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 32),

          // Info rows
          _InfoRow(Icons.person_outline, 'Full Name', name),
          _InfoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 28),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4FC3F7),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3E5FC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4FC3F7), size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}