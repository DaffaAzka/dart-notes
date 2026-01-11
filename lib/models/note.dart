class Note {
  final int id;
  final String text;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Note.fromRow(Map<String, Object?> map)
      : id = map['id'] as int,
        text = map['text'] as String? ?? '',
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);

  Map<String, Object?> toMap() => {
        'id': id,
        'text': text,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Note copyWith({int? id, String? text, DateTime? createdAt}) => Note(
        id: id ?? this.id,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'Note(id: $id, text: $text, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Note other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}
