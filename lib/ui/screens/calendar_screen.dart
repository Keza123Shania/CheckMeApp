import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import 'todo_details_screen.dart';

// Provider to hold the currently selected date in the Calendar view
final selectedDateProvider = StateProvider<DateTime>((ref) {
  // Normalize to start of day for consistent comparison
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Provider for todos filtered by the selected date
final dailyFilteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider).valueOrNull ?? [];
  final selectedDate = ref.watch(selectedDateProvider);

  // Filter tasks to show only those due on the selected day
  return todos.where((t) {
    if (t.dueDate == null) return false;
    final dueDate = t.dueDate!.toLocal();
    return dueDate.year == selectedDate.year &&
        dueDate.month == selectedDate.month &&
        dueDate.day == selectedDate.day;
  }).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)); // Sort by time
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(dailyFilteredTodosProvider);
    final todoState = ref.watch(todoListProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (todoState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today Task List'),
        automaticallyImplyLeading: false, // Hide back button for main tab
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Action for searching tasks within the calendar view
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Date Picker (Matching Inspiration)
          _buildHorizontalCalendar(ref, primaryColor),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tasks for ${DateFormat('EEEE, MMM d').format(selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Daily Task List
          Expanded(
            child: todos.isEmpty
                ? Center(
              child: Text(
                'No tasks scheduled for this date.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final t = todos[index];
                return _buildTaskTile(context, ref, t, primaryColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar(WidgetRef ref, Color primaryColor) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1)); // Monday
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final selectedDate = ref.watch(selectedDateProvider);

    // Calculate task counts for each day
    final allTodos = ref.watch(todoListProvider).valueOrNull ?? [];
    int getDailyTaskCount(DateTime day) {
      return allTodos.where((t) {
        if (t.dueDate == null) return false;
        final dueDate = t.dueDate!.toLocal();
        return dueDate.year == day.year &&
            dueDate.month == day.month &&
            dueDate.day == day.day;
      }).length;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: days.map((day) {
          final isSelected = day.day == selectedDate.day && day.month == selectedDate.month;
          final taskCount = getDailyTaskCount(day);

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = day;
            },
            child: Container(
              width: 50,
              height: 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : (Theme.of(ref.context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (day.weekday == DateTime.sunday ? Colors.red : primaryColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (Theme.of(ref.context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (taskCount > 0)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, WidgetRef ref, Todo t, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: tileColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          onTap: () => Navigator.pushNamed(context, '/details', arguments: t.id),
          title: Text(
            t.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: t.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.description.isNotEmpty ? t.description : t.category.name),
              const SizedBox(height: 4),
              if (t.dueDate != null)
                Text(
                  DateFormat('h:mm a').format(t.dueDate!.toLocal()),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
          trailing: t.isDone
              ? Icon(Icons.check_circle, color: primaryColor)
              : IconButton(
            icon: Icon(Icons.add_circle_outline, color: primaryColor),
            onPressed: () => ref.read(todoListProvider.notifier).toggle(t.id),
          ),
        ),
      ),
    );
  }
}
