// File: lib/ui/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_helper.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _isRegistering = false;

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    final pattern = r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$';
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
    final success = await DatabaseHelper.instance.insertUser(
      _emailCtl.text.trim(),
      _pwdCtl.text,
    );
    setState(() => _isRegistering = false);
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registered! Please log in.')));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email already exists')));
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
    final primaryBlue = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwdCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),
                _isRegistering
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _register,
                  child: const Text('REGISTER'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Login',
                        style: TextStyle(color: primaryBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
