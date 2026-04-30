import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'create_exam_screen.dart';
import 'admin_results_tab.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF1A0D2E);
const _kSurface = Color(0xFF2D1B4E);
const _kSurface2 = Color(0xFF3D2560);
const _kAccent = Color(0xFF844FC1);
const _kMint = Color(0xFF3DDCB0);
const _kText = Colors.white;
const _kTextSub = Color(0xFFB89FD8);
const _kTextDim = Color(0xFF7B6B95);

class AdminDashboardScreen extends StatefulWidget {
  final String institution;
  final String adminName;

  const AdminDashboardScreen({
    super.key,
    required this.institution,
    this.adminName = 'Admin',
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int _examListKey = 0;
  List<dynamic> _violations = [];
  List<String> _clearedViolationIds = [];
  bool _notifLoading = false;
  String? _profileImageFilename;

  List<dynamic> get _unreadViolations => _violations
      .where((v) =>
  !_clearedViolationIds.contains(v['_id']?.toString()))
      .toList();

  int get _unreadCount => _unreadViolations.length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageFilename =
          prefs.getString('user_profile_image') ?? '';
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _notifLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final cleared =
        prefs.getStringList('admin_cleared_violations') ?? [];
    final data = await ApiService.getAllViolations();
    if (mounted) {
      setState(() {
        _violations = data;
        _clearedViolationIds = cleared;
        _notifLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    final allIds =
    _violations.map((v) => v['_id']?.toString() ?? '').toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('admin_cleared_violations', allIds);
    setState(() => _clearedViolationIds = allIds);
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminNotificationPanel(
        violations: _unreadViolations,
        loading: _notifLoading,
        onRefresh: _loadNotifications,
        onClearAll: () {
          _clearAllNotifications();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openProfileMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AdminProfileSheet(
        adminName: widget.adminName,
        institution: widget.institution,
        profileImageFilename: _profileImageFilename,
        onLogout: _logout,
        onImageUpdated: (filename) {
          setState(() => _profileImageFilename = filename);
        },
        onInstitutionUpdated: (newInstitution) {
          // Rebuild dashboard with new institution name
          setState(() {});
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(
                institution: newInstitution,
                adminName: widget.adminName,
              ),
            ),
          );
        },
      ),
    );
    _loadProfileImage();
  }

  void _logout() async {
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

  Future<void> _openCreateExam() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateExamScreen()),
    );
    if (result == true) {
      setState(() {
        _examListKey++;
        _selectedIndex = 2;
      });
    }
  }

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _TabItem(icon: Icons.people_rounded, label: 'Students'),
    _TabItem(icon: Icons.assignment_rounded, label: 'Exams'),
    _TabItem(icon: Icons.bar_chart_rounded, label: 'Results'),
    _TabItem(icon: Icons.warning_amber_rounded, label: 'Violations'),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _OverviewTab(
            institution: widget.institution,
            adminName: widget.adminName);
      case 1:
        return const _StudentsTab();
      case 2:
        return _AdminExamsTab(key: ValueKey(_examListKey));
      case 3:
        return const AdminResultsTab();
      case 4:
        return const _AdminViolationsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExamsTab = _selectedIndex == 2;
    final isOverviewTab = _selectedIndex == 0;

    // Profile avatar widget for appbar
    final hasImage = _profileImageFilename != null &&
        _profileImageFilename!.isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kAccent, Color(0xFF5B2D9E)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Invigilo',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(width: 10),
            Text(_tabs[_selectedIndex].label,
                style: const TextStyle(
                    color: _kTextSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: _kTextSub, size: 22),
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text('$_unreadCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),

          // New Exam button — only on Exams tab
          if (isExamsTab)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _openCreateExam,
                icon: const Icon(Icons.add_circle_outline,
                    color: _kMint, size: 18),
                label: const Text('New Exam',
                    style: TextStyle(
                        color: _kMint,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                style: TextButton.styleFrom(
                  backgroundColor: _kMint.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                ),
              ),
            ),

          // Profile avatar — only on Overview tab
          if (isOverviewTab)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: _openProfileMenu,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kMint, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _kMint.withOpacity(0.2),
                          blurRadius: 6),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.network(
                      ApiService.profileImageUrl(
                          _profileImageFilename!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AdminInitialsAvatar(
                              name: widget.adminName),
                    )
                        : _AdminInitialsAvatar(
                        name: widget.adminName),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          border: Border(
              top: BorderSide(
                  color: _kAccent.withOpacity(0.3), width: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: _kSurface,
          selectedItemColor: _kMint,
          unselectedItemColor: _kTextDim,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon, size: 22),
            label: t.label,
          ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _AdminInitialsAvatar extends StatelessWidget {
  final String name;
  const _AdminInitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join()
        : 'A';
    return Container(
      color: _kAccent.withOpacity(0.3),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: _kMint,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}

// ── Admin Profile Sheet ───────────────────────────────────────────────────────

class _AdminProfileSheet extends StatefulWidget {
  final String adminName;
  final String institution;
  final String? profileImageFilename;
  final VoidCallback onLogout;
  final ValueChanged<String?> onImageUpdated;
  final ValueChanged<String> onInstitutionUpdated;

  const _AdminProfileSheet({
    required this.adminName,
    required this.institution,
    required this.profileImageFilename,
    required this.onLogout,
    required this.onImageUpdated,
    required this.onInstitutionUpdated,
  });

  @override
  State<_AdminProfileSheet> createState() =>
      _AdminProfileSheetState();
}

class _AdminProfileSheetState extends State<_AdminProfileSheet> {
  late String? _filename;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _filename = widget.profileImageFilename;
  }

  bool get _hasImage =>
      _filename != null && _filename!.isNotEmpty;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kTextDim,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Photo',
                style: TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _kAccent.withOpacity(0.2),
                child: const Icon(Icons.camera_alt, color: _kMint),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(color: _kText)),
              onTap: () =>
                  Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _kAccent.withOpacity(0.2),
                child:
                const Icon(Icons.photo_library, color: _kMint),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: _kText)),
              onTap: () =>
                  Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked =
    await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploading = true);
    final filename =
    await ApiService.uploadProfileImage(File(picked.path));
    if (mounted) {
      setState(() {
        _uploading = false;
        if (filename != null) _filename = filename;
      });
      widget.onImageUpdated(filename);
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

  Future<void> _editInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('admin_institution') ?? '';
    final ctrl = TextEditingController(text: current);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Institution Name',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. ABC University',
            hintStyle: const TextStyle(color: _kTextDim),
            prefixIcon:
            const Icon(Icons.business_rounded, color: _kMint),
            filled: true,
            fillColor: const Color(0xFF1A0D2E),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: _kMint, width: 1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextDim)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await prefs.setString('admin_institution', result);
      widget.onInstitutionUpdated(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Institution name updated!'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.adminName.isNotEmpty
        ? widget.adminName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join()
        : 'A';

    final imageUrl =
    _hasImage ? ApiService.profileImageUrl(_filename!) : null;

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _kTextDim,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // Avatar with edit overlay
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kMint, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: _kMint.withOpacity(0.2),
                        blurRadius: 12),
                  ],
                ),
                child: ClipOval(
                  child: _uploading
                      ? Container(
                    color: _kSurface2,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: _kMint, strokeWidth: 2),
                    ),
                  )
                      : _hasImage
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(
                            initials: initials),
                  )
                      : _AvatarFallback(initials: initials),
                ),
              ),
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kSurface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tap hint
          GestureDetector(
            onTap: _uploading ? null : _pickAndUpload,
            child: Text(
              _uploading
                  ? 'Uploading...'
                  : _hasImage
                  ? 'Tap to change photo'
                  : 'Tap to add photo',
              style: TextStyle(
                  color: _uploading ? _kTextDim : _kMint,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  decorationColor: _kMint),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(widget.adminName,
              style: const TextStyle(
                  color: _kText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),

          // Institution
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_outlined,
                  color: _kMint, size: 14),
              const SizedBox(width: 4),
              Text(widget.institution,
                  style:
                  const TextStyle(color: _kMint, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kAccent.withOpacity(0.4), width: 0.8),
            ),
            child: const Text('Administrator',
                style: TextStyle(
                    color: _kTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 28),

          Divider(color: _kTextDim.withOpacity(0.3), height: 1),
          const SizedBox(height: 20),

          // Edit institution button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _editInstitution,
              icon: const Icon(Icons.business_rounded,
                  color: _kMint),
              label: const Text('Edit Institution Name',
                  style: TextStyle(
                      color: _kMint,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kMint, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent),
              label: const Text('Logout',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Colors.redAccent, width: 1),
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

class _AvatarFallback extends StatelessWidget {
  final String initials;
  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kAccent.withOpacity(0.25),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: _kMint,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Notification Panel ────────────────────────────────────────────────────────

class _AdminNotificationPanel extends StatelessWidget {
  final List<dynamic> violations;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onClearAll;

  const _AdminNotificationPanel({
    required this.violations,
    required this.loading,
    required this.onRefresh,
    required this.onClearAll,
  });

  String _formatType(String type) {
    switch (type) {
      case 'app_switch':
        return 'App Switch / Minimized';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kTextDim,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: _kMint, size: 20),
                  const SizedBox(width: 8),
                  const Text('Violation Alerts',
                      style: TextStyle(
                          color: _kText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (violations.isNotEmpty)
                    TextButton(
                      onPressed: onClearAll,
                      child: const Text('Clear all',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: _kMint),
                    onPressed: onRefresh,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _kAccent.withOpacity(0.2)),
            Expanded(
              child: loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _kMint))
                  : violations.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 56,
                        color: _kMint.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('No new alerts',
                        style: TextStyle(
                            color: _kTextDim,
                            fontSize: 14)),
                  ],
                ),
              )
                  : ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                itemCount: violations.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: _kAccent.withOpacity(0.15)),
                itemBuilder: (_, i) {
                  final v = violations[i];
                  final ts = v['timestamp'] != null
                      ? DateTime.tryParse(v['timestamp'])
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.redAccent
                              .withOpacity(0.15),
                          child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['studentName'] ??
                                    'Unknown',
                                style: const TextStyle(
                                    color: _kText,
                                    fontWeight:
                                    FontWeight.w600,
                                    fontSize: 14),
                              ),
                              Text(v['examTitle'] ?? '',
                                  style: const TextStyle(
                                      color: _kMint,
                                      fontSize: 12)),
                              Text(
                                  _formatType(
                                      v['type'] ?? ''),
                                  style: const TextStyle(
                                      color:
                                      Colors.redAccent,
                                      fontSize: 12)),
                              if (ts != null)
                                Text(
                                  '${ts.day}/${ts.month}/${ts.year}  '
                                      '${ts.hour.toString().padLeft(2, '0')}:'
                                      '${ts.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: _kTextDim,
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final String institution;
  final String adminName;
  const _OverviewTab(
      {required this.institution, required this.adminName});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  int _studentCount = 0;
  int _activeExamCount = 0;
  int _violationCount = 0;
  int _completedExamCount = 0;
  List<dynamic> _violations = [];
  bool _loading = true;
  bool _showViolations = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _parseExamDateTime(dynamic exam) {
    try {
      final dateParts = (exam['date'] as String).split('/');
      final timeStr = exam['time'] as String;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final timeParts = timeStr.split(' ');
      final hm = timeParts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPm = timeParts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getStudents(),
      ApiService.getExams(),
      ApiService.getAllViolations(),
    ]);
    final students = results[0];
    final exams = results[1];
    final violations = results[2];
    final now = DateTime.now();

    final active = exams.where((e) {
      final t = _parseExamDateTime(e);
      if (t == null) return false;
      return now.isAfter(t) &&
          now.isBefore(t.add(const Duration(minutes: 10)));
    }).length;

    final completed = exams.where((e) {
      final t = _parseExamDateTime(e);
      if (t == null) return false;
      return now.isAfter(t.add(const Duration(minutes: 10)));
    }).length;

    if (mounted) {
      setState(() {
        _studentCount = students.length;
        _activeExamCount = active;
        _violationCount = violations.length;
        _completedExamCount = completed;
        _violations = violations;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: _kMint,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B2D9E), Color(0xFF844FC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: _kAccent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kMint.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kMint.withOpacity(0.4)),
                    ),
                    child: const Text('Admin Dashboard',
                        style: TextStyle(
                            color: _kMint,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Welcome, to Admin Dashboard.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: _kMint, size: 15),
                      const SizedBox(width: 5),
                      Text(widget.adminName,
                          style: const TextStyle(
                              color: _kMint,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          color: Colors.white54, size: 13),
                      const SizedBox(width: 5),
                      Text(widget.institution,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: _kMint,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('Quick Stats',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),

            _loading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child:
                CircularProgressIndicator(color: _kMint),
              ),
            )
                : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _StatCard(
                    label: 'Total Students',
                    value: '$_studentCount',
                    icon: Icons.people_rounded,
                    color: _kMint),
                _StatCard(
                    label: 'Active Exams',
                    value: '$_activeExamCount',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF6DD5FA)),
                _StatCard(
                    label: 'Total Violations',
                    value: '$_violationCount',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    onTap: () => setState(() =>
                    _showViolations = !_showViolations),
                    tapHint: 'Tap to view'),
                _StatCard(
                    label: 'Exams Completed',
                    value: '$_completedExamCount',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFFFCA28)),
              ],
            ),

            if (_showViolations) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Violations',
                      style: TextStyle(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: _kTextDim, size: 18),
                    onPressed: () =>
                        setState(() => _showViolations = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_violations.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No violations recorded.',
                        style: TextStyle(color: _kTextDim)),
                  ),
                )
              else
                ..._violations.map((v) {
                  final ts = v['timestamp'] != null
                      ? DateTime.tryParse(v['timestamp'])
                      : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                          Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.redAccent
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(v['studentName'] ?? 'Unknown',
                                  style: const TextStyle(
                                      color: _kText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(v['examTitle'] ?? '',
                                  style: const TextStyle(
                                      color: _kMint, fontSize: 12)),
                              Text(
                                (v['type'] ?? '')
                                    .toString()
                                    .replaceAll('_', ' '),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (ts != null)
                          Text(
                            '${ts.day}/${ts.month}\n'
                                '${ts.hour.toString().padLeft(2, '0')}:'
                                '${ts.minute.toString().padLeft(2, '0')}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: _kTextDim, fontSize: 10),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tapHint;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.tapHint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.25), width: 0.8),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: color.withOpacity(0.5), size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
                Text(label,
                    style: const TextStyle(
                        color: _kTextSub, fontSize: 11)),
                if (tapHint != null)
                  Text(tapHint!,
                      style: TextStyle(
                          color: color.withOpacity(0.6),
                          fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Students Tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatefulWidget {
  const _StudentsTab();

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  List<dynamic> _allStudents = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getStudents();
    if (mounted) {
      setState(() {
        _allStudents = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allStudents
          : _allStudents.where((s) {
        final name =
        (s['name'] ?? '').toString().toLowerCase();
        final email =
        (s['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: _kText),
            decoration: InputDecoration(
              hintText: 'Search students...',
              hintStyle: const TextStyle(color: _kTextDim),
              prefixIcon:
              const Icon(Icons.search_rounded, color: _kMint),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear,
                    color: _kTextDim, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _filter();
                },
              )
                  : null,
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _kMint, width: 1)),
            ),
          ),
        ),
        if (_loading)
          const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: _kMint)),
          )
        else if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 56,
                      color: _kTextDim.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    _searchCtrl.text.isEmpty
                        ? 'No students registered yet'
                        : 'No students found',
                    style: const TextStyle(
                        color: _kTextDim, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: _kMint,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _StudentTile(student: _filtered[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  final dynamic student;
  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final profileImage = student['profileImage'] as String?;
    final hasImage =
        profileImage != null && profileImage.isNotEmpty;
    final initials = name.isNotEmpty
        ? name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join()
        : '?';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                StudentProfilePage(student: student)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAccent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kMint, width: 1.5),
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                  ApiService.profileImageUrl(profileImage),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _StudentInitials(initials: initials),
                )
                    : _StudentInitials(initials: initials),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(email,
                      style: const TextStyle(
                          color: _kTextDim, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kTextDim, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StudentInitials extends StatelessWidget {
  final String initials;
  const _StudentInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kAccent.withOpacity(0.25),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: _kMint,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}

// ── Student Profile Page ──────────────────────────────────────────────────────

class StudentProfilePage extends StatefulWidget {
  final dynamic student;
  const StudentProfilePage(
      {super.key, required this.student});

  @override
  State<StudentProfilePage> createState() =>
      _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  List<dynamic> _results = [];
  List<dynamic> _violations = [];
  bool _loading = true;

  String get _studentId =>
      widget.student['_id']?.toString() ?? '';
  String get _studentName =>
      widget.student['name'] ?? 'Unknown';
  String get _studentEmail =>
      widget.student['email'] ?? '';
  String? get _profileImage =>
      widget.student['profileImage'] as String?;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await Future.wait([
      ApiService.getAllResults(studentId: _studentId),
      ApiService.getAllViolations(studentId: _studentId),
    ]);
    if (mounted) {
      setState(() {
        _results = data[0];
        _violations = data[1];
        _loading = false;
      });
    }
  }

  int get _attended => _results.length;
  int get _passed =>
      _results.where((r) => r['passed'] == true).length;
  int get _failed => _attended - _passed;

  @override
  Widget build(BuildContext context) {
    final initials = _studentName.isNotEmpty
        ? _studentName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join()
        : '?';
    final hasImage =
        _profileImage != null && _profileImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        iconTheme: const IconThemeData(color: _kMint),
        elevation: 0,
        title: const Text('Student Profile',
            style: TextStyle(
                color: _kText, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: _kMint))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _kAccent.withOpacity(0.4),
                  _kSurface2
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _kAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kMint, width: 2),
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? Image.network(
                        ApiService.profileImageUrl(
                            _profileImage!),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                            _AvatarFallback2(
                                initials:
                                initials),
                      )
                          : _AvatarFallback2(
                          initials: initials),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(_studentName,
                            style: const TextStyle(
                                color: _kText,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_studentEmail,
                            style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3),
                          decoration: BoxDecoration(
                            color: _kMint.withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Text('Student',
                              style: TextStyle(
                                  color: _kMint,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _MiniStat(
                    label: 'Attended',
                    value: '$_attended',
                    icon: Icons.assignment_turned_in_rounded,
                    color: _kMint),
                _MiniStat(
                    label: 'Passed',
                    value: '$_passed',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF66BB6A)),
                _MiniStat(
                    label: 'Failed',
                    value: '$_failed',
                    icon: Icons.cancel_rounded,
                    color: Colors.redAccent),
                _MiniStat(
                    label: 'Violations',
                    value: '${_violations.length}',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            if (_results.isNotEmpty) ...[
              _SectionHeader(
                  label: 'Exam Results', color: _kMint),
              const SizedBox(height: 10),
              ..._results.map((r) {
                final passed = r['passed'] ?? false;
                final score = r['score'] ?? 0;
                final total = r['totalMarks'] ?? 0;
                final pct = total > 0
                    ? (score / total * 100).round()
                    : 0;
                final color = passed
                    ? const Color(0xFF66BB6A)
                    : Colors.redAccent;
                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                        color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Text('$pct%',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(r['examTitle'] ?? '',
                                style: const TextStyle(
                                    color: _kText,
                                    fontWeight:
                                    FontWeight.w600,
                                    fontSize: 13)),
                            Text('$score / $total marks',
                                style: const TextStyle(
                                    color: _kTextSub,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Text(
                            passed ? 'PASS' : 'FAIL',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            if (_violations.isNotEmpty) ...[
              _SectionHeader(
                  label: 'Violations',
                  color: Colors.redAccent),
              const SizedBox(height: 10),
              ..._violations.map((v) {
                final ts = v['timestamp'] != null
                    ? DateTime.tryParse(v['timestamp'])
                    : null;
                return Container(
                  margin:
                  const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent
                            .withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.redAccent
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(v['examTitle'] ?? '',
                                style: const TextStyle(
                                    color: _kMint,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w500)),
                            Text(
                                (v['type'] ?? '')
                                    .toString()
                                    .replaceAll('_', ' '),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12)),
                            if (ts != null)
                              Text(
                                '${ts.day}/${ts.month}/${ts.year}  '
                                    '${ts.hour.toString().padLeft(2, '0')}:'
                                    '${ts.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: _kTextDim,
                                    fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (_results.isEmpty && _violations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 56,
                          color:
                          _kTextDim.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'This student has not attended any exams yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _kTextDim,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback2 extends StatelessWidget {
  final String initials;
  const _AvatarFallback2({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kAccent.withOpacity(0.25),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: _kMint,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: _kText,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: _kTextSub, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Admin Exams Tab ───────────────────────────────────────────────────────────

class _AdminExamsTab extends StatefulWidget {
  const _AdminExamsTab({super.key});

  @override
  State<_AdminExamsTab> createState() => _AdminExamsTabState();
}

class _AdminExamsTabState extends State<_AdminExamsTab> {
  List<dynamic> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exams = await ApiService.getExams();
    if (mounted)
      setState(() {
        _exams = exams;
        _loading = false;
      });
  }

  Future<void> _deleteExam(dynamic exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text('Delete Exam',
            style: TextStyle(color: _kText)),
        content: Text(
            'Delete "${exam['title']}"? This cannot be undone.',
            style: const TextStyle(color: _kTextSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: _kTextDim))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteExam(exam['_id'].toString());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kMint));
    }
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: _kTextDim.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No exams yet',
                style:
                TextStyle(color: _kTextDim, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Use "New Exam" button above to create one',
                style: TextStyle(
                    color: _kTextDim, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kMint,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final exam = _exams[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _kAccent.withOpacity(0.2), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kMint.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.assignment_rounded,
                          color: _kMint,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(exam['title'] ?? '',
                              style: const TextStyle(
                                  color: _kText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(exam['subject'] ?? '',
                              style: const TextStyle(
                                  color: _kMint, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteExam(exam),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _Chip(
                        icon: Icons.calendar_today_outlined,
                        label: exam['date'] ?? ''),
                    _Chip(
                        icon: Icons.access_time_outlined,
                        label: exam['time'] ?? ''),
                    _Chip(
                        icon: Icons.timer_outlined,
                        label: '${exam['duration']} mins'),
                    _Chip(
                        icon: Icons.star_outline,
                        label: '${exam['totalMarks']} marks'),
                    _Chip(
                        icon: Icons.check_circle_outline,
                        label: 'Pass: ${exam['passingMarks']}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(6),
        border:
        Border.all(color: _kAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _kTextDim),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: _kTextSub, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Admin Violations Tab ──────────────────────────────────────────────────────

class _AdminViolationsTab extends StatefulWidget {
  const _AdminViolationsTab();

  @override
  State<_AdminViolationsTab> createState() =>
      _AdminViolationsTabState();
}

class _AdminViolationsTabState
    extends State<_AdminViolationsTab> {
  List<dynamic> _violations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAllViolations();
    if (mounted)
      setState(() {
        _violations = data;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kMint));
    }
    if (_violations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined,
                size: 64, color: _kMint.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No violations recorded',
                style: TextStyle(
                    color: _kMint,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kMint,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _violations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final v = _violations[i];
          final ts = v['timestamp'] != null
              ? DateTime.tryParse(v['timestamp'])
              : null;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.2),
                  width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(v['studentName'] ?? 'Unknown',
                          style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(v['examTitle'] ?? '',
                          style: const TextStyle(
                              color: _kMint, fontSize: 12)),
                      Text(
                          (v['type'] ?? '')
                              .toString()
                              .replaceAll('_', ' '),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12)),
                      if (ts != null)
                        Text(
                          '${ts.day}/${ts.month}/${ts.year}  '
                              '${ts.hour.toString().padLeft(2, '0')}:'
                              '${ts.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: _kTextDim, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}