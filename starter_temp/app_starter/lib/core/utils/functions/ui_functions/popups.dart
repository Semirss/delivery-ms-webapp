import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_ui/app_ui.dart';

void showCustomDialog(BuildContext context, Widget child) {
  AppDialog.show<void>(context: context, content: child);
}

void showCustomBottomSheet(BuildContext context, Widget child) {
  AppModal.show<void>(context: context, content: child);
}

void closeDialog(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  }
}
