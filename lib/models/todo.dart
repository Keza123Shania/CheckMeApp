import 'package:uuid/uuid.dart';

enum Category { School, Personal, Urgent }

class Todo {
  final String id;
  String title;
  String description;
  bool isDone;
  DateTime creationDate;
  DateTime? dueDate;
  Category category;
  String userEmail;

  Todo({
    String? id,
    required this.title,
    this.description = '',
    this.isDone = false,
    DateTime? creationDate,
    this.dueDate,
    this.category = Category.Personal,
    required this.userEmail,
  }) :
        id = id ?? const Uuid().v4(),
        creationDate = creationDate ?? DateTime.now();

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id:            json['id'] as String,
    title:         json['title'] as String,
    description:   json['description'] as String? ?? '',
    isDone:        (json['isDone'] as int) == 1,
    creationDate:  DateTime.parse(json['creationDate'] as String),
    dueDate:       json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    category:      Category.values.firstWhere((e) => e.toString() == json['category']),
    userEmail:     json['userEmail'] as String,
  );

  Map<String, Object?> toJson() => {
    'id':            id,
    'title':         title,
    'description':   description,
    'isDone':        isDone ? 1 : 0,
    'creationDate':  creationDate.toIso8601String(),
    'dueDate':       dueDate?.toIso8601String(),
    'category':      category.toString(),
    'userEmail':     userEmail,
  };
}