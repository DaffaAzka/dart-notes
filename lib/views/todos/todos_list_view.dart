import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/todo.dart';

typedef TodoCallback = void Function(Todo todo);

class TodosListView extends StatelessWidget {
  const TodosListView({
    super.key,
    required this.todos,
    required this.onDeleteTodo,
    required this.onTap,
    required this.onToggleComplete,
  });

  final TodoCallback onDeleteTodo;
  final List<Todo> todos;
  final TodoCallback onTap;
  final TodoCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            onTap: () => onTap(todo),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => onToggleComplete(todo),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              todo.title.isEmpty ? 'Empty todo' : todo.title,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: todo.isCompleted
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    )
                  : todo.title.isEmpty
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        )
                      : null,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatDate(todo.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            trailing: IconButton(
              onPressed: () => onDeleteTodo(todo),
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
