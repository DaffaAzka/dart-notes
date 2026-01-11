import 'package:dstnotes/utilities/generics/get_arguments.dart';
import 'package:flutter/material.dart';

import '../../models/todo.dart';
import '../../services/local_notes_service.dart';

class CreateUpdateTodoView extends StatefulWidget {
  const CreateUpdateTodoView({super.key});

  @override
  State<CreateUpdateTodoView> createState() => _CreateUpdateTodoViewState();
}

class _CreateUpdateTodoViewState extends State<CreateUpdateTodoView> {
  Todo? _todo;
  late final LocalNotesService _notesService;
  late final TextEditingController _titleController;
  bool _isCompleted = false;
  bool _isNewTodo = true;

  @override
  void initState() {
    _notesService = LocalNotesService();
    _titleController = TextEditingController();
    super.initState();
  }

  Future<Todo?> _initializeTodo(BuildContext context) async {
    final widgetTodo = context.getArgument<Todo>();

    if (widgetTodo != null) {
      _todo = widgetTodo;
      _titleController.text = widgetTodo.title;
      _isCompleted = widgetTodo.isCompleted;
      _isNewTodo = false;
      return widgetTodo;
    }

    return null;
  }

  void _saveTodo() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_todo != null) {
      // Update existing todo
      await _notesService.updateTodo(
        id: _todo!.id,
        title: title,
        isCompleted: _isCompleted,
      );
    } else {
      // Create new todo
      await _notesService.createTodo(title: title);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_todo == null && _isNewTodo ? "New Todo" : "Edit Todo"),
        actions: [
          IconButton(
            onPressed: _saveTodo,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initializeTodo(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      autofocus: _isNewTodo,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isNewTodo)
                      Card(
                        child: CheckboxListTile(
                          value: _isCompleted,
                          onChanged: (value) {
                            setState(() {
                              _isCompleted = value ?? false;
                            });
                          },
                          title: const Text('Mark as completed'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _saveTodo,
                      icon: const Icon(Icons.save),
                      label: Text(_isNewTodo ? 'Create Todo' : 'Save Changes'),
                    ),
                  ],
                ),
              );

            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
