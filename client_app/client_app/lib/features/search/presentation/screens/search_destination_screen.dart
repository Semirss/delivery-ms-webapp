import 'dart:async';

import 'package:client_app/core/map/addis_ababa_base_map.dart';
import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum SearchDestinationAction { currentLocation, pinOnMap }

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
  static const LatLng _addisCenter = LatLng(9.0108, 38.7612);

  final MapRepository _mapRepository = MapRepository();
  final TextEditingController _searchController = TextEditingController();
  List<MapPlace> _results = MapRepository.majorAddisPlaces;
  String _activeQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshCatalog());
  }

  Future<void> _refreshCatalog() async {
    final results = await _mapRepository.refreshAddisCatalog();
    if (!mounted || _activeQuery.isNotEmpty) return;
    setState(() => _results = results);
  }

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
          .timeout(const Duration(seconds: 4), onTimeout: () => localResults);

      if (!mounted || _activeQuery != normalizedQuery) return;
      setState(() {
        _results = results.isEmpty ? localResults : results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEE9),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _addisCenter,
              initialZoom: 13.2,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              ...addisAbabaBaseMapLayers(
                userAgentPackageName: 'com.motobikedeliveryservice.client',
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: _MapBackButton(onPressed: () => Navigator.pop(context)),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.30,
            maxChildSize: 0.76,
            snap: true,
            snapSizes: const [0.34, 0.76],
            builder: (context, scrollController) {
              final bottomPadding =
                  MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md;
              return Container(
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: context.appBorder,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          _SearchHeader(
                            title: widget.title,
                            subtitle: widget.subtitle,
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onUseCurrentLocation: () => Navigator.pop(
                              context,
                              SearchDestinationAction.currentLocation,
                            ),
                            onPinOnMap: () => Navigator.pop(
                              context,
                              SearchDestinationAction.pinOnMap,
                            ),
                            onClear: _searchController.text.isEmpty
                                ? null
                                : () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                          ),
                        ],
                      ),
                    ),
                    if (_results.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoDestinationResults(
                          query: _searchController.text,
                          title: widget.emptyTitle,
                          messagePrefix: widget.emptyMessagePrefix,
                          bottomPadding: bottomPadding,
                          onPinOnMap: () => Navigator.pop(
                            context,
                            SearchDestinationAction.pinOnMap,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          bottomPadding,
                        ),
                        sliver: SliverList.separated(
                          itemCount: _results.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index == _results.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: AppText(
                                  'Location data © OpenStreetMap contributors',
                                  variant: AppTextVariant.bodySmall,
                                  color: context.appTextSecondary,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            final place = _results[index];
                            return _DestinationTile(
                              place: place,
                              index: index,
                              onTap: () => Navigator.pop(context, place),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapBackButton extends StatelessWidget {
  const _MapBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: const CircleBorder(),
      elevation: 8,
      child: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded, color: context.appTextPrimary),
        onPressed: onPressed,
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
    required this.onUseCurrentLocation,
    required this.onPinOnMap,
    required this.onClear,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPinOnMap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.heading3,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 2),
          AppText(
            subtitle,
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
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
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppText(
                'Quick options',
                variant: AppTextVariant.labelSmall,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              _SearchQuickAction(
                icon: Icons.my_location_rounded,
                label: 'Use GPS',
                onTap: onUseCurrentLocation,
              ),
              const SizedBox(width: AppSpacing.xs),
              _SearchQuickAction(
                icon: Icons.add_location_alt_outlined,
                label: 'Pin on map',
                onTap: onPinOnMap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchQuickAction extends StatelessWidget {
  const _SearchQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 5),
              AppText(
                label,
                variant: AppTextVariant.labelSmall,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
        ),
      ),
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
    required this.bottomPadding,
    required this.onPinOnMap,
  });

  final String query;
  final String title;
  final String messagePrefix;
  final double bottomPadding;
  final VoidCallback onPinOnMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        bottomPadding,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.add_location_alt_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              title,
              variant: AppTextVariant.heading3,
              fontWeight: FontWeight.w900,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '$messagePrefix "$query" or choose one of the major '
              'neighborhoods.',
              variant: AppTextVariant.bodyMedium,
              color: context.appTextSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  AppColors.primary.withValues(alpha: 0.08),
                  context.appSurface,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                children: [
                  const AppText(
                    'Cannot find the exact place?',
                    variant: AppTextVariant.labelLarge,
                    fontWeight: FontWeight.w900,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'በካርታ ላይ በትክክል ይመልከቱ',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w800,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.primary(
                    label: 'PIN ON MAP',
                    icon: Icons.add_location_alt_rounded,
                    fullWidth: true,
                    onPressed: onPinOnMap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
