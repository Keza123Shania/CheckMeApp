import 'package:checkme/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/filters.dart';
import 'add_todo_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TodoListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Todos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);
    final todos = ref.watch(filteredTodosProvider);
    final catFilter = ref.watch(categoryFilterProvider);

    if (userAsyncValue.isLoading || !userAsyncValue.hasValue || userAsyncValue.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = userAsyncValue.value!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.name}\'s Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // This line is now fixed to use the correct provider
              ref.read(authRepositoryProvider).logout();
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
                      .map((c) => DropdownMenuItem(
                      value: c, child: Text(c?.name ?? 'All')))
                      .toList(),
                  onChanged: (c) =>
                  ref.read(categoryFilterProvider.notifier).state = c,
                ),
                const SizedBox(width: 16),
                PopupMenuButton<FilterOption>(
                  onSelected: (f) =>
                  ref.read(completionFilterProvider.notifier).state = f,
                  icon: const Icon(Icons.filter_list),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: FilterOption.All, child: Text('All')),
                    PopupMenuItem(
                        value: FilterOption.Completed,
                        child: Text('Completed')),
                    PopupMenuItem(
                        value: FilterOption.Pending, child: Text('Pending')),
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
                final overdue = t.dueDate != null &&
                    !t.isDone &&
                    t.dueDate!.isBefore(DateTime.now());

                return Dismissible(
                  key: Key(t.id),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete todo?'),
                        content:
                        const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                        false; // treat null as false
                  },
                  onDismissed: (_) async {
                    await ref
                        .read(todoListProvider.notifier)
                        .delete(t.id);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child:
                    const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: t.isDone,
                      onChanged: (_) => ref
                          .read(todoListProvider.notifier)
                          .toggle(t.id),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                          decoration: t.isDone
                              ? TextDecoration.lineThrough
                              : null),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.dueDate != null)
                          Text(
                              'Due: ${t.dueDate!.toLocal().toString().split(' ')[0]}'),
                        if (overdue)
                          const Text('Overdue',
                              style: TextStyle(color: Colors.red)),
                        Text('Category: ${t.category.name}'),
                      ],
                    ),
                    onTap: () {
                      // Navigate to a non-existent route to demonstrate
                      // we'll need a details screen later.
                      // For now, this will do nothing.
                    },
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

