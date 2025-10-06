import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart'; // Import main.dart to access babyBlue swatch

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
  bool _isObscurePwd = true;
  bool _isObscureConfirm = true;
  bool _isRegistering = false;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    const pattern = r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(pattern).hasMatch(v) ? null : 'Invalid email format';
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
      await ref.read(authStateProvider.notifier).register(
        _emailCtl.text.trim(),
        _pwdCtl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please log in.')));

        // Safety net: Navigate back to login immediately after registration success
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        // Display specific error message if available
        final errorMessage = e.toString().contains('exists') ? 'Registration failed: Email already in use.' : 'Registration failed.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
    // FIX: Access the entire MaterialColor swatch directly for shading
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          // Top Colored Section with Illustration
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Placeholder
                    Image.asset('assets/login_avatar.png', height: 120, fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.white), // Fallback
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Let\'s create a ',
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        children: [
                          TextSpan(
                            // FIX: Use the babyBlueSwatch to access shade900 for emphasis
                            text: 'space',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade200 : CheckMeApp.babyBlue.shade900,
                              fontWeight: FontWeight.w800,
                              fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                            ),
                          ),
                          TextSpan(
                            text: ' for your workflows.',
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Form Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Form Fields (Email, Password, Confirm) ---
                      TextFormField(
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwdCtl,
                        obscureText: _isObscurePwd,
                        decoration: InputDecoration(
                          labelText: 'Password (min 6 chars)',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscurePwd ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                            onPressed: () => setState(() => _isObscurePwd = !_isObscurePwd),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmCtl,
                        obscureText: _isObscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscureConfirm ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                            onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 24),

                      // Register Button (Primary Action)
                      _isRegistering
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: _register,
                        child: const Text('SIGN UP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 32),

                      // Divider "OR" (Moved to follow the Register button)
                      Row(
                        children: [
                          const Expanded(child: Divider(thickness: 1, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            // Updated text to reflect social login options are next
                            child: Text("OR USE SOCIAL LOGIN", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ),
                          const Expanded(child: Divider(thickness: 1, height: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Login Icons (Moved to follow the Divider)
                      _SocialLoginIcons(primaryColor: primaryColor),
                      const SizedBox(height: 32),

                      // Navigation Footer (Remains at bottom)
                      _NavigationFooter(
                        question: "Already have an account?",
                        actionText: "Login",
                        onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
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
}

// Helper Widget for Social Login Icons (Reused in Login/Register)
class _SocialLoginIcons extends StatelessWidget {
  final Color primaryColor;
  const _SocialLoginIcons({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Icon
        _buildSocialButton(
          Icons.email_rounded, // Using email icon as a stand-in for Google, usually a custom icon
          Colors.red,
              () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Login clicked (TBD)')));
          },
        ),
        const SizedBox(width: 20),
        // Facebook Icon
        _buildSocialButton(
          Icons.facebook_rounded,
          Colors.blue.shade800,
              () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facebook Login clicked (TBD)')));
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color iconColor, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 28, color: iconColor),
      ),
    );
  }
}

// Helper Widget for Navigation Footer (Reused in Login/Register)
class _NavigationFooter extends StatelessWidget {
  final String question;
  final String actionText;
  final VoidCallback onTap;
  final Color primaryColor;
  const _NavigationFooter({
    required this.question,
    required this.actionText,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
