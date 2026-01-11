import 'package:dstnotes/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog(
          context: context,
          title: "Delete Note",
          content: "Are you sure you want to delete this note?",
          optionsBuilder: () => {"Go Back": false, "Delete": true})
      .then((value) => value ?? false);
}
