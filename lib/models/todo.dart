
class Todo {
  String title;
  String description;
  bool isDone;
  final DateTime creationDate;

  Todo({
    required this.title,
    this.description = '',
    this.isDone = false,
    DateTime? creationDate,
  }) : creationDate = creationDate ?? DateTime.now();
}

