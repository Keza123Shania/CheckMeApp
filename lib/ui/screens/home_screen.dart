import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/filters.dart';
import '../../providers/theme_provider.dart';
import 'todo_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(currentUserProvider)!;
    final todos     = ref.watch(filteredTodosProvider);
    final catFilter = ref.watch(categoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Todos for $userEmail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final current = ref.read(themeModeProvider.notifier).state;
              ref.read(themeModeProvider.notifier).state =
              current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
              ref.read(todoListProvider.notifier).state = [];
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search todos…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(searchProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                DropdownButton<Category?>(
                  value: catFilter,
                  hint: const Text('Category'),
                  items: [null, ...Category.values]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c?.name ?? 'All')))
                      .toList(),
                  onChanged: (c) => ref.read(categoryFilterProvider.notifier).state = c,
                ),
                const SizedBox(width: 16),
                PopupMenuButton<FilterOption>(
                  onSelected: (f) => ref.read(completionFilterProvider.notifier).state = f,
                  icon: const Icon(Icons.filter_list),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: FilterOption.All, child: Text('All')),
                    PopupMenuItem(value: FilterOption.Completed, child: Text('Completed')),
                    PopupMenuItem(value: FilterOption.Pending, child: Text('Pending')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('No todos yet.'))
                : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (ctx, i) {
                final t = todos[i];
                final overdue = t.dueDate != null && !t.isDone && t.dueDate!.isBefore(DateTime.now());

                return Dismissible(
                  key: Key(t.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(todoListProvider.notifier).delete(t.id),
                  child: ListTile(
                    leading: Checkbox(
                      value: t.isDone,
                      onChanged: (_) => ref.read(todoListProvider.notifier).toggle(t.id),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(decoration: t.isDone ? TextDecoration.lineThrough : null),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.dueDate != null) Text('Due: ${t.dueDate!.toLocal().toString().split(' ')[0]}'),
                        if (overdue) const Text('Overdue', style: TextStyle(color: Colors.red)),
                        Text('Category: ${t.category.name}'),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TodoDetailsScreen(todoId: t.id)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}