import 'dart:async';

import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({
    super.key,
    this.title = 'Where should we deliver?',
    this.subtitle =
        'Choose a major Addis Ababa neighborhood or search an exact address.',
    this.emptyTitle = 'No address found',
    this.emptyMessagePrefix = 'Try another spelling for',
    this.defaultSectionTitle = 'Major neighborhoods',
    this.defaultSectionSubtitle =
        'Tap a popular area to fill the delivery destination.',
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessagePrefix;
  final String defaultSectionTitle;
  final String defaultSectionSubtitle;

  @override
  State<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final MapRepository _mapRepository = MapRepository();
  final TextEditingController _searchController = TextEditingController();
  List<MapPlace> _results = MapRepository.majorAddisPlaces;
  String _activeQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalizedQuery = query.trim();
    _activeQuery = normalizedQuery;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (normalizedQuery.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = MapRepository.majorAddisPlaces;
      });
      return;
    }

    final localResults = MapRepository.localAddisMatches(normalizedQuery);
    setState(() {
      _results = localResults.isEmpty
          ? MapRepository.majorAddisPlaces
          : localResults;
    });

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await _mapRepository
          .searchAddress(normalizedQuery)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => localResults,
          );

      if (!mounted || _activeQuery != normalizedQuery) return;
      setState(() {
        _results = results.isEmpty ? localResults : results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              controller: _searchController,
              onChanged: _onSearchChanged,
              onBack: () => Navigator.pop(context),
              onClear: _searchController.text.isEmpty
                  ? null
                  : () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
            ),
            Expanded(
              child: _results.isEmpty
                  ? _NoDestinationResults(
                      query: _searchController.text,
                      title: widget.emptyTitle,
                      messagePrefix: widget.emptyMessagePrefix,
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: _results.length + 1,
                      separatorBuilder: (_, index) => SizedBox(
                        height: index == 0 ? AppSpacing.md : AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _DestinationSectionIntro(
                            hasQuery: hasQuery,
                            count: _results.length,
                            defaultTitle: widget.defaultSectionTitle,
                            defaultSubtitle: widget.defaultSectionSubtitle,
                          );
                        }

                        final place = _results[index - 1];
                        return _DestinationTile(
                          place: place,
                          index: index - 1,
                          onTap: () => Navigator.pop(context, place),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onChanged,
    required this.onBack,
    required this.onClear,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: context.appTextPrimary,
                ),
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  title,
                  variant: AppTextVariant.heading3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            subtitle,
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: context.appSurfaceAlt,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.appBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Bole, CMC, Piassa...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.appTextSecondary,
                ),
                suffixIcon: onClear == null
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.appTextSecondary,
                        ),
                        onPressed: onClear,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationSectionIntro extends StatelessWidget {
  const _DestinationSectionIntro({
    required this.hasQuery,
    required this.count,
    required this.defaultTitle,
    required this.defaultSubtitle,
  });

  final bool hasQuery;
  final int count;
  final String defaultTitle;
  final String defaultSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.travel_explore_rounded,
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
                hasQuery ? 'Search results' : defaultTitle,
                variant: AppTextVariant.labelLarge,
                fontWeight: FontWeight.w900,
              ),
              const SizedBox(height: 2),
              AppText(
                hasQuery
                    ? '$count matching places around Addis Ababa'
                    : defaultSubtitle,
                variant: AppTextVariant.bodySmall,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.place,
    required this.index,
    required this.onTap,
  });

  final MapPlace place;
  final int index;
  final VoidCallback onTap;

  static const _accentColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[index % _accentColors.length];
    final title = place.displayName.split(',').first.trim();

    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.location_on_rounded, color: accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      variant: AppTextVariant.bodyMedium,
                      fontWeight: FontWeight.w900,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    AppText(
                      place.displayName,
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDestinationResults extends StatelessWidget {
  const _NoDestinationResults({
    required this.query,
    required this.title,
    required this.messagePrefix,
  });

  final String query;
  final String title;
  final String messagePrefix;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: context.appTextSecondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              title,
              variant: AppTextVariant.heading3,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '$messagePrefix "$query" or choose one of the major '
              'neighborhoods.',
              variant: AppTextVariant.bodyMedium,
              color: context.appTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
