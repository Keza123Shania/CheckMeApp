import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart'; // Import main.dart to access babyBlue swatch

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      bool success = false;
      try {
        await ref
            .read(authStateProvider.notifier)
            .login(_emailCtl.text.trim(), _pwdCtl.text.trim());
        success = true;
      } catch (e) {
        // Error handling is done via the listen provider below
      }
      // Safety net: If login was successful, manually navigate to ensure no hang.
      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@checkmeapp.com',
      query: 'subject=Password Reset Request&body=I need help resetting my password.',
    );
    // Use canLaunchUrl and launchUrl with the new url_launcher package
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app. Please contact support manually.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to the auth state to show errors
    ref.listen<AsyncValue<String?>>(authStateProvider, (_, state) {
      state.whenOrNull(
        error: (err, st) {
          final errorMessage = err.toString().contains('Invalid')
              ? 'Login failed: Invalid email or password.'
              : 'Login Error: ${err.toString()}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        },
      );
    });

    final authState = ref.watch(authStateProvider);

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
                    Image.asset('assets/login_avatar.png', height: 150, fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.person_pin_circle_outlined, size: 80, color: Colors.white), // Fallback
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Welcome back to ',
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        children: [
                          TextSpan(
                            text: 'CheckMe',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w900,
                              fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                            ),
                          ),
                          TextSpan(
                            text: '!',
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
                      // --- Form Fields (Moved to Top) ---

                      // Form Fields
                      TextFormField(
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwdCtl,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          // Password Visibility Toggle
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _launchEmail,
                          child: Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w500, color: primaryColor)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login Button (Primary Action)
                      authState.isLoading
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: _login,
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 32),

                      // Divider "OR" (Moved to follow the Login button)
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
                        question: "Don't have an account?",
                        actionText: "Sign Up",
                        onTap: () => Navigator.of(context).pushReplacementNamed('/register'),
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

// Helper Widget for Social Login Icons
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

// Helper Widget for Navigation Footer
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
