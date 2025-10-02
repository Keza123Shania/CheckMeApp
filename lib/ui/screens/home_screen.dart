import 'package:checkme/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/filters.dart';
import 'add_todo_screen.dart';
import 'profile_screen.dart';
import 'todo_details_screen.dart';
import 'calendar_screen.dart'; // NEW: Import the Calendar Screen

// Widget to display Home Page Stats - Polished Card Layout (FIXED OVERFLOW)
class TodoStatsCard extends ConsumerWidget {
  const TodoStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the full, unfiltered list of todos (once available)
    final allTodos = ref.watch(todoListProvider).valueOrNull ?? [];
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.grey.shade50; // Light background for contrast

    final total = allTodos.length;
    final completed = allTodos.where((t) => t.isDone).length;
    final pending = total - completed;
    final overdue = allTodos.where((t) =>
    !t.isDone && t.dueDate != null && t.dueDate!.isBefore(DateTime.now())
    ).length;

    // Use a GridView or Row of cards for presentation
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 2.1, // FIX 1: Slightly increased ratio to give more vertical space (was 2.5)
        ),
        children: [
          _buildStatTile(context, 'Total Tasks', total.toString(), primaryColor, cardColor),
          _buildStatTile(context, 'Completed', completed.toString(), Colors.green, cardColor),
          _buildStatTile(context, 'Pending', pending.toString(), Colors.orange, cardColor),
          _buildStatTile(context, 'Overdue', overdue.toString(), overdue > 0 ? Colors.red : Colors.grey, cardColor),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String value, Color color, Color cardBgColor) {
    return Card(
      color: cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // FIX 3: Reduced padding from 12.0 to 10.0
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)), // Reduced font size to 11
            const SizedBox(height: 2), // Reduced spacing
            Text(
                value,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 22, // FIX 2: Explicitly set size to avoid overflow on smaller devices
                )
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // UPDATED: Added CalendarScreen to the list of screens
  final List<Widget> _screens = [
    const TodoListScreen(),
    const CalendarScreen(), // NEW: Calendar screen at index 1
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Modern bottom navigation bar styling
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          elevation: 0,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          // UPDATED: Added Calendar item
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), // NEW: Calendar Icon
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);
    final todos = ref.watch(filteredTodosProvider);
    final catFilter = ref.watch(categoryFilterProvider);
    final todoState = ref.watch(todoListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;

    // Show loading states
    if (userAsyncValue.isLoading || todoState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userAsyncValue.hasError) {
      return Center(child: Text('User Error: ${userAsyncValue.error}'));
    }
    if (todoState.hasError) {
      return Center(child: Text('Todo Error: ${todoState.error}'));
    }

    final user = userAsyncValue.value;
    if (user == null) {
      return const Center(child: Text('User session invalid. Please re-login.'));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, ${user.name.split(' ').first}!',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Here\'s your quick look at the day.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
            // Use floating and snap for modern scroll effect
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 90,
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // Date and Time (Matching inspiration)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  DateFormat('EEEE, d MMM, yyyy - hh:mm a').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards (Dashboard section)
              const TodoStatsCard(),

              const SizedBox(height: 16),

              // Filters and Search section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search tasks by title or description...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200.withOpacity(0.5),
                      ),
                      onChanged: (v) => ref.read(searchProvider.notifier).state = v,
                    ),
                    const SizedBox(height: 12),

                    // Filters Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Category?>(
                            value: catFilter,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [null, ...Category.values]
                                .map((c) => DropdownMenuItem(
                                value: c, child: Text(c?.name ?? 'All Categories')))
                                .toList(),
                            onChanged: (c) =>
                            ref.read(categoryFilterProvider.notifier).state = c,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade400),
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                          ),
                          child: PopupMenuButton<FilterOption>(
                            onSelected: (f) =>
                            ref.read(completionFilterProvider.notifier).state = f,
                            icon: Icon(Icons.filter_list_rounded, color: primaryColor),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: FilterOption.All, child: Text('All Tasks')),
                              PopupMenuItem(
                                  value: FilterOption.Completed,
                                  child: Text('Completed')),
                              PopupMenuItem(
                                  value: FilterOption.Pending, child: Text('Pending')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Active Tasks', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Task List (Replaced Expanded with SliverList to fit CustomScrollView)
              if (todos.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'No tasks found matching filters.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...todos.map((t) {
                  final overdue = t.dueDate != null &&
                      !t.isDone &&
                      t.dueDate!.isBefore(DateTime.now());

                  // Modern List Tile with Card wrap
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Dismissible(
                      key: Key(t.id),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content:
                            const Text('This task will be deleted permanently.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child:
                        const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        color: cardColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: Checkbox(
                            value: t.isDone,
                            onChanged: (_) => ref
                                .read(todoListProvider.notifier)
                                .toggle(t.id),
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          title: Text(
                            t.title,
                            style: TextStyle(
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 16
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (t.dueDate != null)
                                Text(
                                    'Due: ${DateFormat('MMM d, h:mm a').format(t.dueDate!.toLocal())}',
                                    style: TextStyle(fontSize: 12, color: overdue ? Colors.red : Colors.grey.shade600)
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.category.name,
                                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                          onTap: () {
                            // Navigate to TodoDetailsScreen with todo ID
                            Navigator.pushNamed(context, '/details', arguments: t.id);
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
      ),
    );
  }
}
