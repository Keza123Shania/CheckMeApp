import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
// Import url_launcher for the "Forgot Password" feature
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();

  // UX: State for password visibility
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // 🚨 CRITICAL FIX: We need to await the login call to ensure the navigation
      // stack is cleared immediately after a successful state transition,
      // preventing the hang we observed.
      final notifier = ref.read(authStateProvider.notifier);
      await notifier.login(_emailCtl.text.trim(), _pwdCtl.text.trim());

      // OPTIONAL: After a brief pause, check the state manually. This ensures
      // that even if the listener lags, the app transitions.
      final userEmail = ref
          .read(authStateProvider)
          .value;
      if (userEmail != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', (route) => false);
      }
    }
  }

  // UX: Forgot Password functionality (Opens an email client)
  void _forgotPassword() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@checkmeapp.com', // Placeholder support email
      query: 'subject=Password Reset Request',
    );
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Could not open email app. Please contact support.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // IMPORTANT: If the state changes to data and we are still here (meaning AuthWrapper didn't catch it),
          // we force navigation. This is the dual safety mechanism.
          data: (userEmail) {
            if (userEmail != null && mounted) {
              // Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Removing this listener trigger and relying on the inline check above for safety
            }
          }
      );
    });

    final authState = ref.watch(authStateProvider);
    final primaryColor = Theme
        .of(context)
        .colorScheme
        .primary;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

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
                      height: 120, // Control the size of the image container
                      width: 120,
                      child: Image.asset(
                        'assets/login_illustration.png', // Placeholder
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person_outline, size: 70, color: Colors
                                .white.withOpacity(0.8)), // Fallback icon
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title Text
                    RichText(

                      text: TextSpan(
                        text: "Let's create a ",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'space',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 28,
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

          // Bottom Login Form Area (White, Rounded Card)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30)),
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

                      const SizedBox(height: 8),
                      // NEW UX: Title alignment and styling
                      Text('Login', style: Theme
                          .of(context)
                          .textTheme
                          .headlineLarge!
                          .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Email Field
                      TextFormField(
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey
                              .shade100,
                        ),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field with Visibility Toggle
                      TextFormField(
                        controller: _pwdCtl,
                        obscureText: !_isPasswordVisible,
                        // Use visibility state
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          // NEW UX: Visibility toggle icon
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons
                                  .visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey
                              .shade100,
                        ),
                        validator: (v) =>
                        (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _forgotPassword,
                            child: Text('Forgot Password?',
                                style: TextStyle(color: primaryColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Login Button
                      authState.isLoading
                          ? Center(
                          child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                        ),
                        onPressed: _login,
                        child: const Text('Login', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),

                      // Social Login Separator
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('or login with',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Social Login Icons (Placeholder)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                              Icons.g_mobiledata_rounded, 'Google',
                              Colors.black, context),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                              Icons.facebook_rounded, 'Apple', Colors.blue,
                              context),
                        ],
                      ),
                      // NEW UX: Sign Up link positioned above the title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(
                                    context, '/register'),
                            child: Text('Sign Up', style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildSocialButton(IconData icon, String label, Color color,
      BuildContext context) {
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
