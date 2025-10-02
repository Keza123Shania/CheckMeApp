import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';

class TodoDetailsScreen extends ConsumerWidget {
  final String todoId;
  const TodoDetailsScreen({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the async provider
    final asyncTodos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todo Details')),
      // Use .when to handle loading/error states
      body: asyncTodos.when(
        data: (todos) {
          // Find the specific todo from the list
          final todo = todos.firstWhere((t) => t.id == todoId, orElse: () {
            // This is a fallback in case the todo is not found (e.g., deleted)
            return Todo(title: 'Not Found', userEmail: '');
          });

          if (todo.title == 'Not Found') {
            return const Center(child: Text('Todo not found. It may have been deleted.'));
          }

          final overdue = todo.dueDate != null && !todo.isDone &&
              todo.dueDate!.isBefore(DateTime.now());

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Category: ${todo.category.name}'),
                const SizedBox(height: 8),
                if (todo.dueDate != null) Text('Due: ${todo.dueDate!.toLocal().toString().split(' ')[0]}'),
                if (overdue) const Text('Overdue', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(todo.description.isNotEmpty ? todo.description : 'No description'),
                const Spacer(),
                Center(child: ElevatedButton(onPressed: () { /* Edit logic would go here */}, child: const Text('Edit'))),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
