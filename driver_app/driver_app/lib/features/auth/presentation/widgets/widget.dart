import 'package:flutter/material.dart';
import 'package:driver_ui/app_ui.dart';

class TemplateWidget extends StatelessWidget {
  const TemplateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const AppText(
        'Template Widget',
        variant: AppTextVariant.bodyLarge,
      ),
    );
  }
}
