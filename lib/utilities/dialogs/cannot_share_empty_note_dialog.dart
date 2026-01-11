import 'package:flutter/material.dart';

import 'generic_dialog.dart';

Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return showGenericDialog(
      context: context,
      title: "Sharing",
      content: "Cannot share empty note",
      optionsBuilder: () => {"OK": null});
}
