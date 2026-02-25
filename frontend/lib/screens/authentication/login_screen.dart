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

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  void _showNeedHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _NeedHelpSheet(
        onTapPhone: _openWhatsApp,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showServerSettingsDialog() async {
    final currentUrl = await ApiService.getBaseUrl();
    final urlCtrl = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Base URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'http://192.168.x.x/path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Only change this if the server IP has moved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.setBaseUrl(urlCtrl.text);
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server URL updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4C8C2B); // Jamhuriya Green

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo Section
              Center(
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 70,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Welcome Text
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
                child: TextField(
                  controller: _userIdCtrl,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.black45,
                    ),
                    hintText: 'User id',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PIN Field
              _InputCard(
                child: TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.black45,
                    ),
                    hintText: 'PIN',
                    hintStyle: const TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

              const SizedBox(height: 12),

              // Need Help Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showNeedHelpSheet,
                  style: TextButton.styleFrom(foregroundColor: primaryGreen),
                  child: const Text(
                    'Need help?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    elevation: 2,
                    shadowColor: primaryGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
    );
  }

  // Helper method for login logic to keep build method clean
  Future<void> _handleLogin() async {
    if (_userIdCtrl.text.trim().isEmpty || _pinCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your User ID and PIN.')),
      );
      return;
    }

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    final result = await ApiService.login(_userIdCtrl.text, _pinCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final apiData = result['data'];
      final innerData = apiData?['data'] as Map?;
      final dashboardMap = innerData?['dashboard'] as Map?;
      final route = dashboardMap?['route']?.toString() ?? '/dashboard';
      nav.pushReplacementNamed(route);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: result['isConnectionError'] == true
              ? SnackBarAction(
                  label: 'FIX',
                  textColor: Colors.white,
                  onPressed: _showServerSettingsDialog,
                )
              : null,
        ),
      );
    }
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
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NeedHelpSheet extends StatelessWidget {
  final void Function(String phone) onTapPhone;
  final VoidCallback onClose;

  const _NeedHelpSheet({required this.onTapPhone, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final items = <_SupportItem>[
      const _SupportItem(
        title: 'Medicine and Health Science',
        phone: '252614178717',
      ),
      const _SupportItem(title: 'Computer and IT', phone: '252615843794'),
      const _SupportItem(title: 'Engineering', phone: '252617306148'),
      const _SupportItem(
        title: 'Economics and Business Management',
        phone: '252619896704',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 25,
            offset: Offset(0, 10),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 44,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3E3E3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get help from our support team',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTapPhone(item.phone),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.chat, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.phone,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black45),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportItem {
  final String title;
  final String phone;
  const _SupportItem({required this.title, required this.phone});
}
