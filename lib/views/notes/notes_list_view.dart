import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/note.dart';

typedef NoteCallback = void Function(Note note);

class NotesListView extends StatelessWidget {
  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
  });

  final NoteCallback onDeleteNote;
  final List<Note> notes;
  final NoteCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            onTap: () => onTap(note),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              note.text.isEmpty ? 'Empty note' : note.text,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: note.text.isEmpty
                  ? TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    )
                  : null,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatDate(note.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            trailing: IconButton(
              onPressed: () => onDeleteNote(note),
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
