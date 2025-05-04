import 'package:flutter/material.dart';
import 'package:checkme/models/todo.dart';


class TodoDetailsScreen extends StatefulWidget {
  final Todo todo;
  const TodoDetailsScreen({Key? key, required this.todo}) : super(key: key);

  @override
  _TodoDetailsScreenState createState() => _TodoDetailsScreenState();
}

class _TodoDetailsScreenState extends State<TodoDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.todo.title);
    _descController =
        TextEditingController(text: widget.todo.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  widget.todo.title = _titleController.text;
                  widget.todo.description = _descController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    return Scaffold(
      appBar: AppBar(title: const Text('Todo Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Created: ${todo.creationDate.toLocal()}'),
            const SizedBox(height: 16),
            Text(
                todo.description.isNotEmpty
                    ? todo.description
                    : 'No description'),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _showEditDialog,
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
