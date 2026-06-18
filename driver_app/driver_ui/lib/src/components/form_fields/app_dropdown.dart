import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/theme/app_typography.dart';
import '../typography/app_text.dart';
import '../common/app_icon.dart';

/// Enum defining the size variants of AppDropdown
enum AppDropdownSize { small, medium, large }

/// A customizable dropdown component with search and multi-select capabilities.
///
/// AppDropdown provides a consistent dropdown interface with support for
/// different sizes, search functionality, and multi-select mode.
///
/// Example usage:
/// ```dart
/// AppDropdown<String>.medium(
///   label: 'Select Country',
///   items: ['USA', 'Canada', 'Mexico'],
///   onChanged: (value) => print(value),
/// )
/// ```
class AppDropdown<T> extends StatefulWidget {
  /// Optional label displayed above the dropdown
  final String? label;

  /// List of items to display in the dropdown
  final List<T> items;

  /// Currently selected value (for single select)
  final T? value;

  /// Currently selected values (for multi-select)
  final List<T>? values;

  /// Callback invoked when selection changes (single select)
  final void Function(T?)? onChanged;

  /// Callback invoked when selection changes (multi-select)
  final void Function(List<T>)? onMultiChanged;

  /// The size variant of the dropdown
  final AppDropdownSize size;

  /// Whether the dropdown supports search
  final bool searchable;

  /// Whether the dropdown supports multi-select
  final bool multiSelect;

  /// Hint text for the search field
  final String? searchHint;

  /// Optional icon displayed in the dropdown
  final dynamic icon;

  /// Function to convert item to string for display
  final String Function(T)? itemBuilder;

  /// Hint text for the dropdown
  final String? hint;

  /// Whether the dropdown is enabled
  final bool enabled;

  const AppDropdown({
    super.key,
    this.label,
    required this.items,
    this.value,
    this.values,
    this.onChanged,
    this.onMultiChanged,
    this.size = AppDropdownSize.medium,
    this.searchable = false,
    this.multiSelect = false,
    this.searchHint,
    this.icon,
    this.itemBuilder,
    this.hint,
    this.enabled = true,
  });

  /// Creates a small dropdown
  factory AppDropdown.small({
    Key? key,
    String? label,
    required List<T> items,
    T? value,
    void Function(T?)? onChanged,
    String Function(T)? itemBuilder,
    String? hint,
    dynamic icon,
    bool enabled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      size: AppDropdownSize.small,
      itemBuilder: itemBuilder,
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }

  /// Creates a medium dropdown
  factory AppDropdown.medium({
    Key? key,
    String? label,
    required List<T> items,
    T? value,
    void Function(T?)? onChanged,
    String Function(T)? itemBuilder,
    String? hint,
    dynamic icon,
    bool enabled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      size: AppDropdownSize.medium,
      itemBuilder: itemBuilder,
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }

  /// Creates a large dropdown
  factory AppDropdown.large({
    Key? key,
    String? label,
    required List<T> items,
    T? value,
    void Function(T?)? onChanged,
    String Function(T)? itemBuilder,
    String? hint,
    dynamic icon,
    bool enabled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      size: AppDropdownSize.large,
      itemBuilder: itemBuilder,
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }

  /// Creates a searchable dropdown
  factory AppDropdown.searchable({
    Key? key,
    String? label,
    required List<T> items,
    T? value,
    void Function(T?)? onChanged,
    String Function(T)? itemBuilder,
    String? searchHint,
    String? hint,
    dynamic icon,
    bool enabled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      size: AppDropdownSize.medium,
      searchable: true,
      searchHint: searchHint,
      itemBuilder: itemBuilder,
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }

  /// Creates a multi-select dropdown
  factory AppDropdown.multiSelect({
    Key? key,
    String? label,
    required List<T> items,
    List<T>? values,
    void Function(List<T>)? onMultiChanged,
    String Function(T)? itemBuilder,
    String? hint,
    dynamic icon,
    bool enabled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      label: label,
      items: items,
      values: values,
      onMultiChanged: onMultiChanged,
      size: AppDropdownSize.medium,
      multiSelect: true,
      itemBuilder: itemBuilder,
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<T> _selectedItems;
  void Function(void Function())? _overlaySetState;

  @override
  void initState() {
    super.initState();
    _selectedItems = widget.multiSelect
        ? List<T>.from(widget.values ?? [])
        : [];
  }

  @override
  void didUpdateWidget(AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.multiSelect && widget.values != oldWidget.values) {
      _selectedItems = List<T>.from(widget.values ?? []);
    }
  }

  @override
  void dispose() {
    // Remove overlay first without calling setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlaySetState = null;
    _searchController.dispose();
    super.dispose();
  }

  /// Returns the vertical padding based on size
  double get _verticalPadding {
    switch (widget.size) {
      case AppDropdownSize.small:
        return AppSpacing.sm;
      case AppDropdownSize.medium:
        return AppSpacing.md;
      case AppDropdownSize.large:
        return AppSpacing.lg;
    }
  }

  /// Returns the horizontal padding based on size
  double get _horizontalPadding {
    switch (widget.size) {
      case AppDropdownSize.small:
        return AppSpacing.md;
      case AppDropdownSize.medium:
        return AppSpacing.lg;
      case AppDropdownSize.large:
        return AppSpacing.xl;
    }
  }

  /// Returns the text style based on size
  AppTextVariant get _textVariant {
    switch (widget.size) {
      case AppDropdownSize.small:
        return AppTextVariant.bodySmall;
      case AppDropdownSize.medium:
        return AppTextVariant.bodyMedium;
      case AppDropdownSize.large:
        return AppTextVariant.bodyLarge;
    }
  }

  /// Converts an item to string for display
  String _itemToString(T item) {
    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(item);
    }
    return item.toString();
  }

  /// Returns filtered items based on search query
  List<T> get _filteredItems {
    if (!widget.searchable || _searchQuery.isEmpty) {
      return widget.items;
    }

    return widget.items.where((item) {
      final itemString = _itemToString(item).toLowerCase();
      return itemString.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// Toggles the dropdown open/closed state
  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  /// Shows the dropdown overlay
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  /// Removes the dropdown overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlaySetState = null;
    _searchController.clear();
    _searchQuery = '';
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  /// Handles item selection
  void _onItemSelected(T item) {
    if (widget.multiSelect) {
      setState(() {
        if (_selectedItems.contains(item)) {
          _selectedItems.remove(item);
        } else {
          _selectedItems.add(item);
        }
      });
      // Rebuild the overlay to show updated selection state
      _overlaySetState?.call(() {});
      widget.onMultiChanged?.call(_selectedItems);
    } else {
      widget.onChanged?.call(item);
      _removeOverlay();
    }
  }

  /// Creates the overlay entry for the dropdown
  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + AppSpacing.xs),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setOverlayState) {
                        // Store reference to overlay setState for updates (only once)
                        _overlaySetState ??= setOverlayState;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.searchable) ...[
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: widget.searchHint ?? 'Search...',
                                    hintStyle: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    isDense: true,
                                  ),
                                  style: AppTypography.bodySmall,
                                  onChanged: (value) {
                                    // Update search query immediately
                                    _searchQuery = value;
                                    // Rebuild the overlay to show filtered items
                                    setOverlayState(() {});
                                  },
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                            Flexible(
                              child: _filteredItems.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.lg,
                                      ),
                                      child: AppText(
                                        'No items found',
                                        variant: _textVariant,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xs,
                                      ),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final item = _filteredItems[index];
                                        final isSelected = widget.multiSelect
                                            ? _selectedItems.contains(item)
                                            : widget.value == item;

                                        return InkWell(
                                          onTap: () => _onItemSelected(item),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: _horizontalPadding,
                                              vertical: _verticalPadding,
                                            ),
                                            color: isSelected
                                                ? AppColors.primary.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : null,
                                            child: Row(
                                              children: [
                                                if (widget.multiSelect) ...[
                                                  Icon(
                                                    isSelected
                                                        ? Icons.check_box
                                                        : Icons
                                                              .check_box_outline_blank,
                                                    size: 20,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors
                                                              .textSecondary,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                ],
                                                Expanded(
                                                  child: AppText(
                                                    _itemToString(item),
                                                    variant: _textVariant,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (!widget.multiSelect &&
                                                    isSelected)
                                                  const Icon(
                                                    Icons.check,
                                                    size: 20,
                                                    color: AppColors.primary,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the display text for the dropdown button
  String get _displayText {
    if (widget.multiSelect) {
      if (_selectedItems.isEmpty) {
        return widget.hint ?? 'Select items';
      }
      return '${_selectedItems.length} selected';
    } else {
      if (widget.value == null) {
        return widget.hint ?? 'Select an item';
      }
      return _itemToString(widget.value as T);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label ?? 'Dropdown',
      hint: widget.multiSelect
          ? 'Multi-select dropdown, ${_selectedItems.length} items selected'
          : 'Select an item',
      value: _displayText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            AppText(
              widget.label!,
              variant: AppTextVariant.labelMedium,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          CompositedTransformTarget(
            link: _layerLink,
            child: InkWell(
              onTap: _toggleDropdown,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44.0),
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? AppColors.surface
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _isOpen ? AppColors.primary : AppColors.border,
                    width: _isOpen ? 2.0 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 20,
                        color: widget.enabled
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: AppText(
                        _displayText,
                        variant: _textVariant,
                        color: widget.enabled
                            ? (widget.value != null || _selectedItems.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary)
                            : AppColors.textDisabled,
                      ),
                    ),
                    Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: widget.enabled
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
