import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../providers/auth_provider.dart';

class TodoDetailsScreen extends ConsumerWidget {
  final String todoId;
  const TodoDetailsScreen({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todoListProvider).firstWhere((t) => t.id == todoId);
    final titleCtl = TextEditingController(text: todo.title);
    final descCtl = TextEditingController(text: todo.description);
    DateTime? due = todo.dueDate;
    Category category = todo.category;

    void showEditDialog() {
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('Edit Todo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtl),
                  TextField(controller: descCtl),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(
                              days: 365)),
                          lastDate: DateTime.now().add(const Duration(
                              days: 365)),
                        );
                        if (d != null) due = d;
                      }, child: const Text('Pick Due Date')),
                      const SizedBox(width: 8),
                      Text(due == null ? 'No date chosen' : due!
                          .toLocal()
                          .toString()
                          .split(' ')[0]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Category>(
                    value: category,
                    items: Category.values.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => category = c!,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                TextButton(onPressed: () {
                  final updated = Todo(
                    id: todo.id,
                    title: titleCtl.text,
                    description: descCtl.text,
                    creationDate: todo.creationDate,
                    dueDate: due,
                    category: category,
                    isDone: todo.isDone,
                    userEmail: ref.read(currentUserProvider)!,
                  );
                  ref.read(todoListProvider.notifier).update(updated);
                  Navigator.pop(context);
                }, child: const Text('Save')),
              ],
            ),
      );
    }

    final overdue = todo.dueDate != null && !todo.isDone &&
        todo.dueDate!.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Todo Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title, style: Theme
                .of(context)
                .textTheme
                .titleLarge),
            const SizedBox(height: 8),
            if (todo.dueDate != null) Text(
                'Due: ${todo.dueDate!.toLocal().toString().split(' ')[0]}'),
            if (overdue) const Text(
                'Overdue', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text(todo.description.isNotEmpty
                ? todo.description
                : 'No description'),
            const Spacer(),
            Center(child: ElevatedButton(
                onPressed: showEditDialog, child: const Text('Edit'))),
          ],
        ),
      ),
    );
  }}