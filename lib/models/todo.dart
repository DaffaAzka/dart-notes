class Todo {
  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  Todo.fromRow(Map<String, Object?> map)
      : id = map['id'] as int,
        title = map['title'] as String? ?? '',
        isCompleted = (map['is_completed'] as int) == 1,
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Todo copyWith({int? id, String? title, bool? isCompleted, DateTime? createdAt}) => Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'Todo(id: $id, title: $title, isCompleted: $isCompleted, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Todo other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}
