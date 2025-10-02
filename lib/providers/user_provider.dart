import 'package:checkme/models/user.dart';
import 'package:checkme/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProvider =
StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Listen to the auth state. When it changes, fetch the user data.
    _ref.listen(authStateProvider, (previous, next) {
      final userEmail = next.asData?.value;
      if (userEmail != null) {
        _fetchUser(userEmail);
      } else {
        state = const AsyncValue.data(null);
      }
    }, fireImmediately: true);
  }

  Future<void> _fetchUser(String email) async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(authRepositoryProvider).getUser(email);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _ref.read(authRepositoryProvider).updateUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

