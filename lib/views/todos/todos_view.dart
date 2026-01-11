import 'package:dstnotes/constants/routes.dart';
import 'package:dstnotes/services/local_notes_service.dart';
import 'package:flutter/material.dart';

import '../../models/todo.dart';
import '../../utilities/dialogs/delete_dialog.dart';
import 'todos_list_view.dart';

class TodosView extends StatefulWidget {
  const TodosView({super.key});

  @override
  State<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends State<TodosView> {
  late final LocalNotesService _notesService;

  @override
  void initState() {
    _notesService = LocalNotesService();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Todos"),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(createOrUpdateTodoRoute);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: _notesService.allTodos,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              if (snapshot.hasData) {
                final allTodos = snapshot.data as List<Todo>;
                if (allTodos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No todos yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first todo',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return TodosListView(
                  todos: allTodos,
                  onDeleteTodo: (Todo todo) async {
                    final shouldDelete = await showDeleteDialog(context);
                    if (shouldDelete) {
                      await _notesService.deleteTodo(id: todo.id);
                    }
                  },
                  onToggleComplete: (Todo todo) async {
                    await _notesService.toggleTodoComplete(id: todo.id);
                  },
                  onTap: (todo) {
                    Navigator.of(context).pushNamed(
                      createOrUpdateTodoRoute,
                      arguments: todo,
                    );
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }

            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
