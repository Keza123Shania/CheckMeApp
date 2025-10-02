import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../services/notification_service.dart';

class AddTodoScreen extends ConsumerStatefulWidget {
  const AddTodoScreen({super.key});
  @override
  ConsumerState<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends ConsumerState<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  DateTime? _due;
  Category _category = Category.Personal;
  bool _scheduleNotification = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;


    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userEmail = ref.read(authStateProvider).value!;
      final todo = Todo(
        title: _titleCtl.text,
        description: _descCtl.text,
        dueDate: _due,
        category: _category,
        userEmail: userEmail,
      );
      ref.read(todoListProvider.notifier).addTodo(todo);

      if (_scheduleNotification) {
        ref.read(notificationServiceProvider).scheduleTodoNotification(todo);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add A Todo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(onPressed: _pickDate, child: const Text('Pick Due Date')),
                  const SizedBox(width: 8),
                  Text(_due == null ? 'No date chosen' : _due!.toLocal().toString().split('.')[0]),
                ],
              ),
              if (_due != null)
                SwitchListTile(
                  title: const Text('Set Reminder'),
                  value: _scheduleNotification,
                  onChanged: (bool value) {
                    setState(() {
                      _scheduleNotification = value;
                    });
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Category>(
                value: _category,
                items: Category.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (c) => setState(() => _category = c!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const Spacer(),
              Center(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
            ],
          ),
        ),
      ),
    );
  }
}
