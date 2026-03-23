import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

enum LoginStep { urlInput, credentials }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController(
    text: 'dev-tascort-dms.tascoauto.com',
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginStep _currentStep = LoginStep.urlInput;
  bool _isLoadingDb = false;
  List<String> _availableDatabases = [];
  String? _selectedDb;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.serverUrl != null &&
          authProvider.serverUrl!.isNotEmpty) {
        setState(() {
          _urlController.text = authProvider.serverUrl!;
        });
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatUrl(String text) {
    var url = text.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url.replaceAll(RegExp(r'/$'), '');
  }

  Future<void> _fetchDatabases() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      _showErrorSnackBar('Please enter a server URL');
      return;
    }

    final formattedUrl = _formatUrl(rawUrl);
    _urlController.text = formattedUrl; // Update UI with formatted url

    setState(() => _isLoadingDb = true);

    try {
      final uri = Uri.parse('$formattedUrl/web/database/list');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {},
          "id": DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'] is List) {
          final dbs = List<String>.from(data['result']);
          setState(() {
            _availableDatabases = dbs;
            if (dbs.length == 1) {
              _selectedDb = dbs.first;
            } else if (dbs.isNotEmpty) {
              _selectedDb = dbs.first; // Default to first if multiple
            }
            _currentStep = LoginStep.credentials;
            _isLoadingDb = false;
          });
          return;
        } else if (data['error'] != null) {
          // Access denied to list DBs or DB list disabled
          setState(() {
            _currentStep = LoginStep.credentials;
            _isLoadingDb = false;
          });
          return;
        }
      }

      // Handle non-200 or unexpected structure
      setState(() {
        _currentStep = LoginStep.credentials;
        _isLoadingDb = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDb = false);
      _showErrorSnackBar(
        'Could not connect to the server. Please check the URL.',
      );
    }
  }

  void _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
      _urlController.text,
      _selectedDb ?? '',
    );

    if (!mounted) return;

    if (!success) {
      _showErrorSnackBar('Login failed. Please check your credentials.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;
    final isAuthenticating = authStatus == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 24.0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutQuint,
                switchOutCurve: Curves.easeInQuint,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _currentStep == LoginStep.urlInput
                    ? _buildUrlInputStep()
                    : _buildCredentialsStep(isAuthenticating),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF5a3d6a),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            height: 220,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=800',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF4A3158),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInputStep() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('urlStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connect to Odoo',
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(
            color: const Color(0xFF1D1B20),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your server URL to get started',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: const Color(0xFF757575)),
        ),
        const SizedBox(height: 48),
        _buildInputLabel('SERVER URL'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _urlController,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _fetchDatabases(),
          decoration: _buildInputDecoration(
            hint: 'e.g. dev-crm.company.com',
            icon: Icons.link_rounded,
          ),
        ),
        const SizedBox(height: 32),
        _buildElevatedButton(
          label: 'Continue',
          isLoading: _isLoadingDb,
          onPressed: _fetchDatabases,
        ),
      ],
    );
  }

  Widget _buildCredentialsStep(bool isAuthenticating) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('credStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () =>
                  setState(() => _currentStep = LoginStep.urlInput),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF5a3d6a),
              ),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const Expanded(
              child: Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance for back button
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _urlController.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),

        // Database Selector (if multiple) or Viewer (if 1 or 0 but manual input allowed)
        if (_availableDatabases.isNotEmpty) ...[
          _buildInputLabel('DATABASE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDb,
            icon: const Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: Color(0xFF5a3d6a),
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1B20),
              fontSize: 16,
            ),
            decoration: _buildInputDecoration(
              hint: 'Select Database',
              icon: Icons.storage_rounded,
            ),
            items: _availableDatabases.map((db) {
              return DropdownMenuItem(value: db, child: Text(db));
            }).toList(),
            onChanged: (val) => setState(() => _selectedDb = val),
          ),
          const SizedBox(height: 24),
        ],

        _buildInputLabel('EMAIL OR USERNAME'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          style: const TextStyle(fontWeight: FontWeight.w600),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _buildInputDecoration(
            hint: 'john.doe@company.com',
            icon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: 24),

        _buildInputLabel('PASSWORD'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: _buildInputDecoration(
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF9E9E9E),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                activeColor: const Color(0xFF5a3d6a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Remember me',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF49454F),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5a3d6a),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildElevatedButton(
          label: 'Login to CRM',
          isLoading: isAuthenticating,
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF757575),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFBDBDBD),
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(icon, size: 22, color: const Color(0xFF9E9E9E)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF5a3d6a), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
    );
  }

  Widget _buildElevatedButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5a3d6a),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
