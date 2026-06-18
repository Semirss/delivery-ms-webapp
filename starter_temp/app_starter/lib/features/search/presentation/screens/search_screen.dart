import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:app_starter/config/router/app_routes.dart';
import 'package:app_starter/config/router/navigation_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<_SearchItem> _items = [
    const _SearchItem(
      title: 'Profile Settings',
      subtitle: 'Update personal details and preferences',
      category: 'Profile',
      icon: Icons.person_outline,
      routeName: AppRoutes.profile,
      keywords: ['profile', 'account', 'settings'],
    ),
    const _SearchItem(
      title: 'Security & PIN',
      subtitle: 'Change PIN and security options',
      category: 'Security',
      icon: Icons.lock_outline_rounded,
      routeName: AppRoutes.changePin,
      keywords: ['pin', 'security', 'password'],
    ),
    const _SearchItem(
      title: 'Notifications',
      subtitle: 'Control push and email alerts',
      category: 'Settings',
      icon: Icons.notifications_none_rounded,
      routeName: AppRoutes.notification,
      keywords: ['alerts', 'push', 'email'],
    ),
    const _SearchItem(
      title: 'Account Settings',
      subtitle: 'Manage account and preferences',
      category: 'Settings',
      icon: Icons.settings_outlined,
      routeName: AppRoutes.setting,
      keywords: ['preferences', 'account'],
    ),
    const _SearchItem(
      title: 'Help Center',
      subtitle: 'FAQs and support resources',
      category: 'Help',
      icon: Icons.help_outline_rounded,
      keywords: ['support', 'faq', 'help'],
    ),
    const _SearchItem(
      title: 'UI Components',
      subtitle: 'Browse the design system showcase',
      category: 'Resources',
      icon: Icons.grid_view_rounded,
      keywords: ['components', 'ui', 'design'],
    ),
    _SearchItem(
      title: 'AppButton',
      subtitle: 'Primary, secondary, outlined, ghost',
      category: 'Components',
      icon: Icons.smart_button_outlined,
      keywords: ['button', 'cta', 'action'],
      preview: AppButton.primary(
        label: 'Primary',
        onPressed: () {},
        fullWidth: true,
      ),
    ),
    _SearchItem(
      title: 'AppIconButton',
      subtitle: 'Icon-only actions',
      category: 'Components',
      icon: Icons.radio_button_checked,
      keywords: ['icon', 'button', 'action'],
      preview: Row(
        children: [
          AppIconButton.primary(icon: Icons.add, onPressed: () {}),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton.ghost(icon: Icons.more_horiz, onPressed: () {}),
        ],
      ),
    ),
    _SearchItem(
      title: 'AppTextField',
      subtitle: 'Input fields with icons and labels',
      category: 'Components',
      icon: Icons.text_fields_rounded,
      keywords: ['input', 'text', 'field', 'form'],
      preview: AppTextField.filled(
        hint: 'Text field',
        prefixIcon: Icons.edit_outlined,
        readOnly: true,
      ),
    ),
    _SearchItem(
      title: 'AppDropdown',
      subtitle: 'Selection inputs',
      category: 'Components',
      icon: Icons.arrow_drop_down_circle_outlined,
      keywords: ['dropdown', 'select', 'menu'],
      preview: AppDropdown<String>.medium(
        label: 'Dropdown',
        items: const ['Option 1', 'Option 2'],
        onChanged: null,
      ),
    ),
    _SearchItem(
      title: 'AppCheckbox & AppRadio',
      subtitle: 'Selection controls',
      category: 'Components',
      icon: Icons.check_box_outlined,
      keywords: ['checkbox', 'radio', 'toggle'],
      preview: Row(
        children: [
          AppCheckbox(value: true, onChanged: (_) {}, label: 'Check'),
          const SizedBox(width: AppSpacing.sm),
          AppRadio<bool>(
            value: true,
            groupValue: true,
            onChanged: (_) {},
            label: 'Radio',
          ),
        ],
      ),
    ),
    const _SearchItem(
      title: 'AppDialog & AppModal',
      subtitle: 'Confirmation and modal surfaces',
      category: 'Components',
      icon: Icons.chat_bubble_outline,
      keywords: ['dialog', 'modal', 'popup'],
    ),
    const _SearchItem(
      title: 'AppToast & AppSnackbar',
      subtitle: 'Feedback and notifications',
      category: 'Components',
      icon: Icons.notifications_active_outlined,
      keywords: ['toast', 'snackbar', 'feedback'],
    ),
    _SearchItem(
      title: 'AppCard',
      subtitle: 'Surface and data cards',
      category: 'Components',
      icon: Icons.credit_card_outlined,
      keywords: ['card', 'surface', 'data'],
      preview: AppCard.outlined(
        child: const AppText('Card', variant: AppTextVariant.bodySmall),
      ),
    ),
  ];

  final List<String> _filters = const [
    'All',
    'Profile',
    'Security',
    'Settings',
    'Help',
    'Resources',
    'Components',
  ];

  String _activeFilter = 'All';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final results = _items.where((item) {
      final matchesFilter =
          _activeFilter == 'All' || item.category == _activeFilter;
      final matchesQuery = _matchesQuery(item, query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: const AppAppBar(titleText: 'Search', centerTitle: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppTextField.filled(
              controller: _controller,
              hint: 'Search for features, settings, or help...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _controller.text.isEmpty ? null : Icons.close_rounded,
              onSuffixPressed: () {
                _controller.clear();
                setState(() {});
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = filter == _activeFilter;
                return ChoiceChip(
                  label: AppText(
                    filter,
                    variant: AppTextVariant.bodySmall,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                  selected: isActive,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceAlt,

                  onSelected: (_) {
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemCount: _filters.length,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: results.isEmpty
                ? _EmptySearchState(query: query)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return AppCard.outlined(
                        onTap: () => _handleResultTap(context, item),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: AppIcon(
                                icon: item.icon,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item.title,
                                    variant: AppTextVariant.labelLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    item.subtitle,
                                    variant: AppTextVariant.bodySmall,
                                    color: AppColors.textSecondary,
                                  ),
                                  if (item.preview != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    item.preview!,
                                  ],
                                ],
                              ),
                            ),
                            const AppIcon(
                              icon: Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemCount: results.length,
                  ),
          ),
        ],
      ),
    );
  }

  void _handleResultTap(BuildContext context, _SearchItem item) {
    if (item.routeName == null) {
      return;
    }

    switch (item.routeName) {
      case AppRoutes.profile:
        context.navigator.pushProfileScreen();
        break;
      case AppRoutes.setting:
        context.navigator.pushSettingScreen();
        break;
      case AppRoutes.changePin:
        context.navigator.pushChangePinScreen();
        break;
      case AppRoutes.notification:
        context.navigator.pushNotificationScreen();
        break;

      default:
        context.navigator.replaceWith(item.routeName!.name);
    }
  }

  bool _matchesQuery(_SearchItem item, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalized = query.toLowerCase();
    if (item.title.toLowerCase().contains(normalized) ||
        item.subtitle.toLowerCase().contains(normalized)) {
      return true;
    }

    for (final keyword in item.keywords) {
      if (keyword.toLowerCase().contains(normalized)) {
        return true;
      }
    }

    return false;
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(
              icon: Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              query.isEmpty ? 'Start typing to search' : 'No results found',
              variant: AppTextVariant.heading3,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              query.isEmpty
                  ? 'Find settings, help, and features in one place.'
                  : 'Try adjusting your keywords or filters.',
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final AppRoutes? routeName;
  final List<String> keywords;
  final Widget? preview;

  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.routeName,
    this.keywords = const [],
    this.preview,
  });
}
