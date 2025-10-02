import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _isRegistering = false;

  // UX: State for password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    const pattern = r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(pattern).hasMatch(v) ? null : 'Invalid email';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pwdCtl.text != _confirmCtl.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }
    setState(() => _isRegistering = true);
    try {
      // 🚨 CRITICAL FIX: Await the registration call
      await ref.read(authStateProvider.notifier).register(
        _emailCtl.text.trim(),
        _pwdCtl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registered! Please log in.')));

        // Navigation back to login is safe and required here
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        // Use a more user-friendly message for common errors
        final errorMessage = e.toString().contains('already exists')
            ? 'Registration failed: Email already in use.'
            : 'Registration failed: $e';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwdCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: primaryColor, // Set background to primary color
      body: Column(
        children: [
          // Top Header Area with Illustration
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Illustration Image Asset
                    Container(
                      height: 150, // Control the size of the image container
                      width: 150,
                      child: Image.asset(
                        'assets/login_illustration.png', // Placeholder
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person_add, size: 70, color: Colors.white.withOpacity(0.8)), // Fallback icon
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title Text
                    RichText(
                      text: TextSpan(
                        text: "Let's create a ",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'space',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              fontSize: 32,
                            ),
                          ),
                          const TextSpan(text: ' for your workflows.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Registration Form Area (White, Rounded Card)
          Expanded(
            flex: 4, // More space for the registration form
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // NEW UX: Login link positioned above the title

                      const SizedBox(height: 8),
                      // NEW UX: Title alignment and styling
                      Text('Sign Up', style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Email Field
                      TextFormField(
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Password Field with Visibility Toggle
                      TextFormField(
                        controller: _pwdCtl,
                        obscureText: !_isPasswordVisible, // Use visibility state
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          // NEW UX: Visibility toggle icon
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field with Visibility Toggle
                      TextFormField(
                        controller: _confirmCtl,
                        obscureText: !_isConfirmPasswordVisible, // Use visibility state
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          // NEW UX: Visibility toggle icon
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _pwdCtl.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      _isRegistering
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                        ),
                        onPressed: _register,
                        child: const Text('REGISTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      // Social Login Separator
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('or SignUp with', style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Social Login Icons (Placeholder)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(Icons.g_mobiledata_rounded, 'Google', Colors.black, context),
                          const SizedBox(width: 16),
                          _buildSocialButton(Icons.facebook_rounded, 'Apple', Colors.blue, context),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            // FIX: Use pushReplacementNamed to /login
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/login'),
                            child: Text('Login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSocialButton(IconData icon, String label, Color color, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

