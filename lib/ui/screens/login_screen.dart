import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_services.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  String get _username {
    final e = _emailCtl.text;
    if (!e.contains('@')) return '';
    final n = e.split('@')[0];
    return n.isNotEmpty ? '${n[0].toUpperCase()}${n.substring(1)}' : '';
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your email';
    return EmailValidator.validate(v)
        ? null
        : 'Invalid email address';
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/login_avatar.png'),
                ),
                const SizedBox(height: 24),
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
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _autoValidate = AutovalidateMode.always);
                    if (_formKey.currentState!.validate()) {
                      final ok = await AuthService.login(
                        _emailCtl.text,
                        _pwdCtl.text,
                      );
                      if (ok) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(username: _username),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email or password incorrect'))
                        );
                      }
                    }
                  },
                  child: const Text('LOGIN'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}