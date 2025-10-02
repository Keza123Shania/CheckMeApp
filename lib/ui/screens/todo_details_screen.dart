import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';

class TodoDetailsScreen extends ConsumerWidget {
  final String todoId;
  const TodoDetailsScreen({super.key, required this.todoId});

  // Helper widget for status tags
  Widget _buildTag(String label, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the async provider
    final asyncTodos = ref.watch(todoListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: asyncTodos.when(
        data: (todos) {
          final todo = todos.firstWhere((t) => t.id == todoId, orElse: () {
            return Todo(title: 'Not Found', userEmail: '');
          });

          if (todo.title == 'Not Found') {
            return const Center(child: Text('Todo not found. It may have been deleted.'));
          }

          final overdue = todo.dueDate != null && !todo.isDone &&
              todo.dueDate!.isBefore(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title and Status
                Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                todo.title,
                                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Icon(
                              todo.isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
                              color: todo.isDone ? Colors.green : primaryColor,
                              size: 30,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Status: ', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                            _buildTag(
                              todo.isDone ? 'COMPLETED' : 'PENDING',
                              todo.isDone ? Colors.green : Colors.orange,
                              context,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Category: ', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                            _buildTag(
                              todo.category.name.toUpperCase(),
                              primaryColor,
                              context,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Due Date & Creation Date Card
                Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Timeline', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
                        const Divider(height: 20, thickness: 1),
                        _buildTimelineItem(
                          context,
                          Icons.schedule_rounded,
                          'Created',
                          DateFormat('MMM d, yyyy h:mm a').format(todo.creationDate.toLocal()),
                          Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        if (todo.dueDate != null)
                          _buildTimelineItem(
                            context,
                            Icons.calendar_month_rounded,
                            'Due Date',
                            DateFormat('MMM d, yyyy h:mm a').format(todo.dueDate!.toLocal()),
                            overdue ? Colors.red : primaryColor,
                          ),
                        if (overdue)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              '⚠️ Task is Overdue!',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description Card
                Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
                        const Divider(height: 20, thickness: 1),
                        Text(
                          todo.description.isNotEmpty ? todo.description : 'No detailed description provided.',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Edit Button at the bottom
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 24),
                    label: const Text('Edit Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/add', arguments: todo);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // Helper for timeline layout
  Widget _buildTimelineItem(BuildContext context, IconData icon, String label, String dateText, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey)),
            Text(
              dateText,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
          ],
        ),
      ],
    );
  }
}
