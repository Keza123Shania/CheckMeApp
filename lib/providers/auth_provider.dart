import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/user.dart';

// Part 1: The Repository
// This class handles all the direct communication with the database and shared preferences.
class AuthRepository {
  final DatabaseHelper _db;
  AuthRepository(this._db);

  static const _emailKey = 'user_email';

  // Tries to find a saved email on app startup.
  Future<String?> attemptAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Verifies credentials with the database and saves the session.
  Future<String> login(String email, String password) async {
    final isValid = await _db.login(email, password);
    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      return email;
    }
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
// This class manages the app's authentication state (loading, data, or error)
// and exposes methods for the UI to call (like login, logout).
class AuthStateNotifier extends StateNotifier<AsyncValue<String?>> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    // Check for a saved session when the app starts.
    _authRepository.attemptAutoLogin().then((email) {
      state = AsyncValue.data(email);
    });
  }

  // Login method for the UI to call.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userEmail = await _authRepository.login(email, password);
      state = AsyncValue.data(userEmail);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Register method for the UI to call.
  Future<void> register(String email, String password) async {
    // Registration doesn't immediately log the user in, so we just pass the call.
    // We re-throw the error so the UI can display it.
    try {
      await _authRepository.register(email, password);
    } catch (e) {
      rethrow;
    }
  }

  // Logout method for the UI to call.
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AsyncValue.data(null);
  }
}

// Part 3: The StateNotifierProvider
// This is the provider that our UI will interact with.
final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AsyncValue<String?>>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

