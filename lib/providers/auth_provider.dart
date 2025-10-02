import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import 'dart:developer';

// Part 1: The Repository
// This class handles all the direct communication with the database and shared preferences.
class AuthRepository {
  final DatabaseHelper _db;
  AuthRepository(this._db);

  static const _emailKey = 'user_email';

  // Tries to find a saved email on app startup.
  Future<String?> attemptAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      return null;
    }
  }

  // Verifies credentials with the database and saves the session.
  Future<String> login(String email, String password) async {
    final isValid = await _db.login(email, password);
    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      log('AUTH_REPO: Login successful for $email. Session saved.');
      return email;
    }
    log('AUTH_REPO: Login failed for $email. Throwing exception.');
    throw 'Invalid email or password.';
  }

  // Creates a new user in the database.
  Future<void> register(String email, String password) async {
    final success = await _db.insertUser(email, password);
    if (!success) {
      throw 'Email already exists.';
    }
  }

  // Clears the user session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    log('AUTH_REPO: Session cleared.');
  }

  // NEW: Method for Password Update
  Future<void> updatePassword(String email, String oldPassword, String newPassword) async {
    return _db.updateUserPassword(email, oldPassword, newPassword);
  }

  // FIX: Added missing user methods to the repository
  Future<User?> getUser(String email) async {
    final userMap = await _db.getUser(email);
    if (userMap != null) {
      return User.fromJson(userMap);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await _db.updateUser(user.toJson());
  }
}

// Provider for the repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DatabaseHelper.instance);
});

// Part 2: The State Notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<String?>> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final email = await _authRepository.attemptAutoLogin();
      state = AsyncValue.data(email);
      log('AUTH_NOTIFIER: Initial state set to data(${email ?? 'null'}).');
    } catch (e, st) {
      state = AsyncValue.error('Failed to initialize session: $e', st);
      log('AUTH_NOTIFIER: Initial state failed: $e.');
    }
  }

  // Login method for the UI to call.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    log('AUTH_NOTIFIER: Login started for $email. State set to loading.');
    try {
      final userEmail = await _authRepository.login(email, password);
      state = AsyncValue.data(userEmail);
      log('AUTH_NOTIFIER: Login successful. State set to data($userEmail).');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      log('AUTH_NOTIFIER: Login failed. State set to error: $e.');
    }
  }

  // NEW: Method for Password Update
  Future<void> updatePassword(String email, String oldPassword, String newPassword) async {
    // This action doesn't change the logged-in state, so we wrap the call.
    return _authRepository.updatePassword(email, oldPassword, newPassword);
  }

  // Register method for the UI to call.
  Future<void> register(String email, String password) async {
    await _authRepository.register(email, password);
  }

  // Logout method for the UI to call.
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AsyncValue.data(null);
    log('AUTH_NOTIFIER: Logout complete. State set to data(null).');
  }
}

// Part 3: The StateNotifierProvider
final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AsyncValue<String?>>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});
