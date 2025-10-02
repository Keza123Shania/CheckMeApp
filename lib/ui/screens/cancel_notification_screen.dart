import 'package:checkme/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../models/todo.dart';
import '/../../services/database_helper.dart';
import '../../providers/auth_provider.dart';

final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
      (ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.asData?.value;
    final notificationService = ref.watch(notificationServiceProvider);
    return TodoListNotifier(ref, userEmail, notificationService);
  },
);

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final Ref _ref;
  final String? _userEmail;
  final NotificationService _notificationService;

  TodoListNotifier(this._ref, this._userEmail, this._notificationService): super([]) {
    if (_userEmail != null) {
      loadTodos();
    }
  }

  Future<void> loadTodos() async {
    final maps = await DatabaseHelper.instance.fetchTodos(_userEmail!);
    state = maps.map((m) => Todo.fromJson(m)).toList();
  }

  Future<void> addTodo(Todo t) async {
    await DatabaseHelper.instance.insertTodo(t.toJson());
    state = [t, ...state];
  }

  Future<void> toggle(String id) async {
    final t = state.firstWhere((t) => t.id == id);
    final updated = Todo(
      id: t.id,
      title: t.title,
      description: t.description,
      isDone: !t.isDone,
      creationDate: t.creationDate,
      dueDate: t.dueDate,
      category: t.category,
      userEmail: t.userEmail,
    );
    await DatabaseHelper.instance.updateTodo(updated.toJson());
    state = state.map((e) => e.id == id ? updated : e).toList();

    if(updated.isDone){
      _notificationService.cancelTodoNotification(id);
    }
  }

  Future<void> update(Todo updated) async {
    await DatabaseHelper.instance.updateTodo(updated.toJson());
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
    // Also re-schedule notification if due date changes.
    // For simplicity, we can just schedule it again. It will overwrite the old one.
    _notificationService.scheduleTodoNotification(updated);
  }

  Future<void> delete(String id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    state = state.where((e) => e.id != id).toList();
    _notificationService.cancelTodoNotification(id);
  }
}
