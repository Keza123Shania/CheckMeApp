import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';

class TodoDetailsScreen extends ConsumerWidget {
  final String todoId;
  const TodoDetailsScreen({Key? key, required this.todoId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todoListProvider).firstWhere((t) => t.id == todoId);
    final _titleCtl = TextEditingController(text: todo.title);
    final _descCtl = TextEditingController(text: todo.description);
    DateTime? _due = todo.dueDate;
    Category _category = todo.category;

    void _showEditDialog() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleCtl),
              TextField(controller: _descCtl),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) _due = d;
                    },
                    child: const Text('Pick Due Date'),
                  ),
                  const SizedBox(width: 8),
                  Text(_due == null ? 'No date chosen' : _due!.toLocal().toString().split(' ')[0]),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButton<Category>(
                value: _category,
                items: Category.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (c) => _category = c!,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final updated = Todo(
                  id: todo.id,
                  title: _titleCtl.text,
                  description: _descCtl.text,
                  creationDate: todo.creationDate,
                  dueDate: _due,
                  category: _category,
                  isDone: todo.isDone,
                );
                ref.read(todoListProvider.notifier).update(updated);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    final overdue = todo.dueDate != null && !todo.isDone && todo.dueDate!.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Todo Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (todo.dueDate != null) Text('Due: ${todo.dueDate!.toLocal().toString().split(' ')[0]}'),
            if (overdue) const Text('Overdue', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text(todo.description.isNotEmpty ? todo.description : 'No description'),
            const Spacer(),
            Center(child: ElevatedButton(onPressed: _showEditDialog, child: const Text('Edit'))),
          ],
        ),
      ),
    );
  }
}