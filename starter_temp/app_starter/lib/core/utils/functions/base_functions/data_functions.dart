import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';

Future<void> outlog(Object data, {String? title = ""}) async {
  // if (kDebugMode) {
  // log("$title $data");
  // print("$title $data");
  // }
}

void toast(
  BuildContext context,
  String title,
  String message, {
  AppToastType type = AppToastType.info,
}) {
  AppToast.show(
    context: context,
    title: title.isEmpty ? null : title,
    message: message,
    type: type,
  );
}

StreamTransformer<Uint8List, List<int>> unit8Transformer =
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(List<int>.from(data));
      },
    );
