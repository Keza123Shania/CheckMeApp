import 'package:flutter/material.dart';
import 'package:checkme/models/todo.dart';

import 'add_todo_screen.dart';
import 'todo_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum FilterOption { All, Completed, Pending }

class _HomeScreenState extends State<HomeScreen> {
  final List<Todo> _todos = [];
  FilterOption _filter = FilterOption.All;

  List<Todo> get _filteredTodos {
    switch (_filter) {
      case FilterOption.Completed:
        return _todos.where((t) => t.isDone).toList();
      case FilterOption.Pending:
        return _todos.where((t) => !t.isDone).toList();
      case FilterOption.All:
      default:
        return _todos;
    }
  }

  Future<void> _addTodo() async {
    final newTodo = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(builder: (_) => const AddTodoScreen()),
    );
    if (newTodo != null) {
      setState(() => _todos.add(newTodo));

    }
  }

  void _toggleTodoStatus(Todo todo, bool? value) {
    setState(() => todo.isDone = value ?? false);
  }

  void _deleteTodoAt(int index) {
    final todo = _filteredTodos[index];
    setState(() => _todos.remove(todo));
  }

  void _openDetails(Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodoDetailsScreen(todo: todo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Dashboard'),
        actions: [
          PopupMenuButton<FilterOption>(
            onSelected: (f) => setState(() => _filter = f),
            icon: const Icon(Icons.filter_list),
            itemBuilder: (_) => const [
              PopupMenuItem(value: FilterOption.All, child: Text('All')),
              PopupMenuItem(
                  value: FilterOption.Completed, child: Text('Completed')),
              PopupMenuItem(
                  value: FilterOption.Pending, child: Text('Pending')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              child:
              Text(widget.username.isNotEmpty ? widget.username[0] : '?'),
            ),
            title: Text('Welcome, ${widget.username}!'),
          ),
          const Divider(),
          Expanded(
            child: _filteredTodos.isEmpty
                ? const Center(child: Text('No todos yet.'))
                : ListView.builder( // this builder makes you have access to item builder , that is the index of each builder
              itemCount: _filteredTodos.length, // the number of times that needs to be returned by the widget
              itemBuilder: (context, idx) {
                final todo = _filteredTodos[idx];
                return Dismissible(
                  key: Key(todo.creationDate.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTodoAt(idx),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child:
                    const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (val) =>
                          _toggleTodoStatus(todo, val),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.isDone
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    onTap: () => _openDetails(todo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
