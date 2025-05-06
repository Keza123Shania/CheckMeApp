import 'package:checkme/providers/todo_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';

// Search text
final searchProvider = StateProvider<String>((_) => '');
// Category filter (null = all)
final categoryFilterProvider = StateProvider<Category?>((_) => null);
// Completion filter
final completionFilterProvider =
StateProvider<FilterOption>((_) => FilterOption.All);

enum FilterOption { All, Completed, Pending }

// Computed filtered list
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final search = ref.watch(searchProvider).toLowerCase();
  final cat = ref.watch(categoryFilterProvider);
  final comp = ref.watch(completionFilterProvider);

  return todos.where((t) {
    if (comp == FilterOption.Completed && !t.isDone) return false;
    if (comp == FilterOption.Pending && t.isDone) return false;
    if (cat != null && t.category != cat) return false;
    if (search.isNotEmpty &&
        !t.title.toLowerCase().contains(search) &&
        !t.description.toLowerCase().contains(search)) return false;
    return true;
  }).toList();
});