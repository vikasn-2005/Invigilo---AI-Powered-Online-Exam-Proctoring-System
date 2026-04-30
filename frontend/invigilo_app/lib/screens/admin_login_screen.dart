import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';

const _kBg = Color(0xFF1A0D2E);
const _kSurface = Color(0xFF2D1B4E);
const _kAccent = Color(0xFF844FC1);
const _kMint = Color(0xFF3DDCB0);
const _kTextDim = Color(0xFF7B6B95);
const _kTextSub = Color(0xFFB89FD8);

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _adminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final success = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin', true);
      final adminName = prefs.getString('user_name') ?? 'Admin';

      // Check if institution has been set before
      final savedInstitution =
          prefs.getString('admin_institution') ?? '';

      if (savedInstitution.isEmpty) {
        // First time login — ask for institution
        if (!mounted) return;
        final institution = await _askForInstitution();
        if (institution != null && institution.trim().isNotEmpty) {
          await prefs.setString(
              'admin_institution', institution.trim());
        }
      }

      final institution =
          prefs.getString('admin_institution') ?? 'My Institution';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            institution: institution,
            adminName: adminName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid admin credentials. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<String?> _askForInstitution() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Institution Name',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will be shown on your dashboard.\nYou can change it later from your profile.',
              style: TextStyle(color: _kTextSub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. ABC University',
                hintStyle: const TextStyle(color: _kTextDim),
                prefixIcon: const Icon(Icons.business_rounded,
                    color: _kMint),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'My Institution'),
            child: const Text('Skip',
                style: TextStyle(color: _kTextDim)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              Navigator.pop(
                  context, val.isEmpty ? 'My Institution' : val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        iconTheme: const IconThemeData(color: _kMint),
        elevation: 0,
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
                      fontSize: 15)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _kAccent.withOpacity(0.3),
                      _kSurface,
                    ]),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _kAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: _kMint,
                            size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Administrator Portal',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Restricted access only.',
                              style: TextStyle(
                                  color: _kTextSub,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                _DarkField(
                  controller: _emailController,
                  label: 'Admin Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Admin email is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    labelStyle:
                    const TextStyle(color: _kTextDim),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: _kMint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _kTextDim,
                      ),
                      onPressed: () => setState(() =>
                      _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: _kSurface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _kMint, width: 1)),
                    errorStyle: const TextStyle(
                        color: Colors.redAccent),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty)
                      ? 'Admin password is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Info note
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kMint.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _kMint.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: _kMint, size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your account must have admin role on the server.',
                          style: TextStyle(
                              color: _kTextSub, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _loading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: _kMint))
                      : ElevatedButton(
                    onPressed: _adminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Login as Administrator',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextDim),
        prefixIcon: Icon(icon, color: _kMint),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: _kMint, width: 1)),
        errorStyle:
        const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }
}