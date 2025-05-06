import 'dart:convert';
import 'package:flutter/services.dart';

class AuthService {
  // Lazily load & cache the JSON
  static Future<List<Map<String,String>>> _loadUsers() async {
    final raw = await rootBundle.loadString('assets/users.json');
    final list = json.decode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>()
        .map((m) => {
      'email': m['email'] as String,
      'password': m['password'] as String,
    })
        .toList();
  }

  static Future<bool> login(String email, String password) async {
    final users = await _loadUsers();
    return users.any((u) =>
    u['email'] == email.trim() &&
        u['password'] == password
    );
  }
}
