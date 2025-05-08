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
    if (v == null || v.isEmpty) return 'Please enter email';
    // Basic regex or use email_validator package
    final pattern = r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(pattern).hasMatch(v) ? null : 'Invalid email';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'Min 6 chars';
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
          .showSnackBar(const SnackBar(content: Text("Registered! Please log in.")));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Email already exists")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwdCtl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              _isRegistering
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: _register, child: const Text('REGISTER')),
            ]),
          ),
        ),
      ),
    );
  }
}
