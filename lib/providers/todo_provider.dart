import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';

final todoListProvider =
StateNotifierProvider<TodoListNotifier, List<Todo>>(
      (ref) => TodoListNotifier(),
);

class TodoListNotifier extends StateNotifier<List<Todo>> {
  TodoListNotifier() : super([]);
  final _uuid = const Uuid();

  void addTodo(
      String title,
      String desc,
      DateTime? dueDate,
      Category category,
      ) {
    final t = Todo(
      id: _uuid.v4(),
      title: title,
      description: desc,
      dueDate: dueDate,
      category: category,
    );
    state = [...state, t];
  }

// lib/providers/todo_provider.dart

  void toggle(String id) {
    state = state.map((t) {
      if (t.id != id) return t;
      // re‑build the Todo, passing in the old creationDate:
      return Todo(
        id: t.id,
        title: t.title,
        description: t.description,
        isDone: !t.isDone,
        creationDate: t.creationDate,  // ← preserve the original
        dueDate: t.dueDate,
        category: t.category,
      );
    }).toList();
  }

  void update(Todo updated) {
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}