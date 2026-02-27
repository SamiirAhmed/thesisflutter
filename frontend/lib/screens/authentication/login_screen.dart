import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phoneWithCountryCode) async {
    final digitsOnly = phoneWithCountryCode.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digitsOnly');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showNeedHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NeedHelpSheet(
        onTapPhone: _openWhatsApp,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_userIdCtrl.text.trim().isEmpty || _pinCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your User ID and PIN.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.login(_userIdCtrl.text, _pinCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final apiData = result['data'];
      final innerData = apiData?['data'] as Map?;
      final dashboardMap = innerData?['dashboard'] as Map?;
      final route = dashboardMap?['route']?.toString() ?? '/dashboard';
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4C8C2B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sign In',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Original Circular Logo
                Center(
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => const Icon(
                          Icons.school,
                          size: 70,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Welcome to Jamhuriya University',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 48),

                // User ID Field
                _InputCard(
                  child: TextFormField(
                    controller: _userIdCtrl,
                    enableInteractiveSelection: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.black45,
                      ),
                      hintText: 'User id',
                      hintStyle: TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // PIN Field
                _InputCard(
                  child: TextFormField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType
                        .text, // Text type is more robust for pasting
                    obscureText: _obscurePin,
                    enableInteractiveSelection: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _handleLogin(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.black45,
                      ),
                      hintText: 'PIN',
                      hintStyle: const TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black45,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showNeedHelpSheet,
                    child: const Text(
                      'Need help?',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _NeedHelpSheet extends StatelessWidget {
  final void Function(String phone) onTapPhone;
  final VoidCallback onClose;
  const _NeedHelpSheet({required this.onTapPhone, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Contact Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Medicine and Health Science'),
            onTap: () => onTapPhone('252614178717'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Computer and IT'),
            onTap: () => onTapPhone('252615843794'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ElevatedButton(onPressed: onClose, child: const Text('Close')),
        ],
      ),
    );
  }
}
