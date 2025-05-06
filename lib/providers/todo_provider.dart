import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
      (ref) => TodoListNotifier(ref),
);

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final Ref ref;
  TodoListNotifier(this.ref): super([]);

  Future<void> loadTodos() async {
    final email = ref.read(currentUserProvider)!;
    final maps = await DatabaseHelper.instance.fetchTodos(email);
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
  }

  Future<void> update(Todo updated) async {
    await DatabaseHelper.instance.updateTodo(updated.toJson());
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  Future<void> delete(String id) async {
    await DatabaseHelper.instance.deleteTodo(id);
    state = state.where((e) => e.id != id).toList();
  }
}