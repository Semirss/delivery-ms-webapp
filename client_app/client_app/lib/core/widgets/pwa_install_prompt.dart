import 'package:flutter/material.dart';

class PwaInstallPrompt extends StatefulWidget {
  const PwaInstallPrompt({required this.child, super.key});

  final Widget child;

  @override
  State<PwaInstallPrompt> createState() => _PwaInstallPromptState();
}

class _PwaInstallPromptState extends State<PwaInstallPrompt> {
  @override
  Widget build(BuildContext context) => widget.child;
}
