import 'package:dstnotes/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog(
      context: context,
      title: "An error occurred",
      content: text,
      optionsBuilder: () => {"Go Back": null});
}
