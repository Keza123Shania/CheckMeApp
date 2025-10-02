import 'package:checkme/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

final todoListProvider =
StateNotifierProvider<TodoListNotifier, AsyncValue<List<Todo>>>((ref) {
  return TodoListNotifier(ref);
});

class TodoListNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final Ref _ref;
  String? _userEmail;

  TodoListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(authStateProvider, (previous, next) {
      final userEmail = next.asData?.value;
      _userEmail = userEmail;
      if (userEmail != null) {
        loadTodos();
      } else {
        state = const AsyncValue.data([]);
      }
    }, fireImmediately: true);
  }

  Future<void> loadTodos() async {
    if (_userEmail == null) return;
    state = const AsyncValue.loading();
    try {
      final maps = await DatabaseHelper.instance.fetchTodos(_userEmail!);
      final todos = maps.map((m) => Todo.fromJson(m)).toList();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // FIX: Implement clearAll method for the Danger Zone button
  Future<void> clearAll() async {
    if (_userEmail == null) return;
    final currentTodos = state.valueOrNull ?? [];
    try {
      final db = DatabaseHelper.instance;
      for (var todo in currentTodos) {
        await db.deleteTodo(todo.id);
        _ref.read(notificationServiceProvider).cancelTodoNotification(todo.id);
      }
      // Set state directly to empty array
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  Future<void> addTodo(Todo t) async {
    try {
      await DatabaseHelper.instance.insertTodo(t.toJson());
      // Re-fetch to ensure consistency
      await loadTodos();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggle(String id) async {
    final currentTodos = state.valueOrNull ?? [];
    final t = currentTodos.firstWhere((todo) => todo.id == id);
    final updated = t.copyWith(isDone: !t.isDone);

    try {
      await DatabaseHelper.instance.updateTodo(updated.toJson());
      if (updated.isDone) {
        _ref
            .read(notificationServiceProvider)
            .cancelTodoNotification(id);
      }
      await loadTodos();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(Todo updated) async {
    try {
      await DatabaseHelper.instance.updateTodo(updated.toJson());
      _ref
          .read(notificationServiceProvider)
          .scheduleTodoNotification(updated);
      await loadTodos();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      await DatabaseHelper.instance.deleteTodo(id);
      _ref.read(notificationServiceProvider).cancelTodoNotification(id);
      await loadTodos();
    } catch (e) {
      // Handle error
    }
  }
}
