import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/todo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../services/notification_service.dart';

class AddTodoScreen extends ConsumerStatefulWidget {
  // Pass the todo object if in edit mode, otherwise null for add mode.
  final Todo? todo;
  const AddTodoScreen({super.key, this.todo});

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

  // Flag to check if we are editing an existing todo
  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    // Initialize fields with existing todo data if in edit mode
    if (isEditing) {
      final todo = widget.todo!;
      _titleCtl.text = todo.title;
      _descCtl.text = todo.description;
      _due = todo.dueDate;
      _category = todo.category;
      // Initialize notification switch based on whether a date is set for edit mode
      _scheduleNotification = todo.dueDate != null;
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? DateTime.now()),
    );
    if (time == null) return;


    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userEmail = ref.read(authStateProvider).value;
      if (userEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
        return;
      }

      // Create the base Todo object
      final newTodo = Todo(
        // If editing, use the existing ID/creation date, otherwise generate new ones.
        id: isEditing ? widget.todo!.id : const Uuid().v4(),
        title: _titleCtl.text.trim(),
        description: _descCtl.text.trim(),
        isDone: isEditing ? widget.todo!.isDone : false,
        creationDate: isEditing ? widget.todo!.creationDate : DateTime.now(),
        dueDate: _due,
        category: _category,
        userEmail: userEmail,
      );

      final todoNotifier = ref.read(todoListProvider.notifier);
      final notificationService = ref.read(notificationServiceProvider);

      if (isEditing) {
        // Handle Edit logic
        todoNotifier.update(newTodo);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated!')));
      } else {
        // Handle Add logic
        todoNotifier.addTodo(newTodo);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New task added!')));
      }

      // Notification Handling
      if (_scheduleNotification && newTodo.dueDate != null) {
        notificationService.scheduleTodoNotification(newTodo);
      } else if (!_scheduleNotification && newTodo.dueDate != null) {
        // If reminder is unchecked for a task with a due date, cancel any existing notification.
        notificationService.cancelTodoNotification(newTodo.id);
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              Text('Title', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtl,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),

              // Due Date Picker (Styled to look like the inspiration image)
              Text('Due Date', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        _due == null
                            ? 'Select Date & Time'
                            : DateFormat('MM/dd/yyyy h:mm a').format(_due!.toLocal()),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: _due == null ? Colors.grey : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category/Priority Dropdown
              Text('Category', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Category>(
                value: _category,
                decoration: InputDecoration(
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: primaryColor, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: Category.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (c) => setState(() => _category = c!),
              ),

              const SizedBox(height: 24),

              // Description Input
              Text('Description (Optional)', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtl,
                decoration: InputDecoration(
                  hintText: 'Add details about the task...',
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Notification Toggle
              if (_due != null)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: primaryColor.withOpacity(0.05),
                  child: SwitchListTile(
                    title: Text('Set Reminder Notification', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                    value: _scheduleNotification,
                    onChanged: (bool value) {
                      setState(() {
                        _scheduleNotification = value;
                      });
                    },
                    activeColor: primaryColor,
                    secondary: Icon(Icons.notifications_active_rounded, color: primaryColor),
                  ),
                ),

              const SizedBox(height: 40),

              // Save Button (Styled to match inspiration)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  onPressed: _save,
                  child: Text(isEditing ? 'SAVE CHANGES' : 'CREATE TASK',
                      style: theme.textTheme.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
