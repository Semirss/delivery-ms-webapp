import 'dart:typed_data';

import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

int _clampFoodRating(int value) {
  if (value < 1) return 1;
  if (value > 5) return 5;
  return value;
}

class FoodMarketplaceScreen extends StatefulWidget {
  const FoodMarketplaceScreen({super.key});

  @override
  State<FoodMarketplaceScreen> createState() => _FoodMarketplaceScreenState();
}

class _FoodMarketplaceScreenState extends State<FoodMarketplaceScreen> {
  static const double _bottomNavClearance = 120;

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _restaurantNameController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _sellFormKey = GlobalKey<FormState>();

  List<_FoodCategory> _categories = _sampleCategories;
  List<_FoodItem> _items = _sampleItems;
  List<_RestaurantFeature> _restaurants = _featuredRestaurants;
  String _tab = 'for_you';
  String? _categoryFilterId;
  String? _restaurantFilterId;
  String? _restaurantFilterName;
  String? _sellCategoryId;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _uploadedImageUrl;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFoodMarketplace();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated && mounted) {
        _phoneController.text = state.user.phone ?? '';
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _restaurantNameController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodMarketplace() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final currentUserId = authState is AuthAuthenticated
          ? authState.user.id
          : null;
      final categoriesData = await _supabase
          .from('food_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      final itemsData = await _supabase
          .from('food_marketplace_items')
          .select(
            '*, category:food_categories(name), restaurant:food_restaurants(name)',
          )
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);
      final restaurantsData = await _supabase
          .from('food_restaurants')
          .select()
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      final categories = List<Map<String, dynamic>>.from(
        categoriesData,
      ).map(_FoodCategory.fromMap).toList();
      final items = List<Map<String, dynamic>>.from(
        itemsData,
      ).map(_FoodItem.fromMap).toList();
      final ratedItems = await _attachFoodRatings(items, currentUserId);
      final restaurants = List<Map<String, dynamic>>.from(
        restaurantsData,
      ).map(_RestaurantFeature.fromMap).toList();

      if (!mounted) return;
      setState(() {
        _categories = categories.isEmpty ? _sampleCategories : categories;
        _items = ratedItems.isEmpty ? _sampleItems : ratedItems;
        _restaurants = restaurants.isEmpty ? _featuredRestaurants : restaurants;
        _sellCategoryId ??= _categories.isEmpty ? null : _categories.first.id;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Food marketplace fallback: $e');
      if (!mounted) return;
      setState(() {
        _categories = _sampleCategories;
        _items = _sampleItems;
        _restaurants = _featuredRestaurants;
        _sellCategoryId ??= _sampleCategories.first.id;
        _isLoading = false;
      });
    }
  }

  List<_FoodItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.restaurantDisplayName.toLowerCase().contains(query) ||
          item.sellerName.toLowerCase().contains(query) ||
          item.categoryName.toLowerCase().contains(query);
      final matchesCategory =
          _categoryFilterId == null || item.categoryId == _categoryFilterId;
      final matchesRestaurant =
          _restaurantFilterId == null ||
          item.restaurantId == _restaurantFilterId ||
          (item.restaurantId == null &&
              (_sameText(item.restaurantName, _restaurantFilterName) ||
                  _sameText(item.sellerName, _restaurantFilterName)));
      return matchesQuery && matchesCategory && matchesRestaurant;
    }).toList();
  }

  Future<List<_FoodItem>> _attachFoodRatings(
    List<_FoodItem> items,
    String? currentUserId,
  ) async {
    final ids = items
        .map((item) => item.id)
        .where((id) => id.isNotEmpty && !id.startsWith('sample-'))
        .toList();
    if (ids.isEmpty) return items;

    try {
      final data = await _supabase
          .from('food_item_ratings')
          .select('food_item_id,user_id,rating')
          .filter('food_item_id', 'in', '(${ids.join(',')})');
      final totals = <String, int>{};
      final counts = <String, int>{};
      final userRatings = <String, int>{};

      for (final row in List<Map<String, dynamic>>.from(data)) {
        final itemId = row['food_item_id']?.toString();
        final rating = int.tryParse(row['rating']?.toString() ?? '');
        if (itemId == null || rating == null) continue;

        totals[itemId] = (totals[itemId] ?? 0) + rating;
        counts[itemId] = (counts[itemId] ?? 0) + 1;

        if (currentUserId != null &&
            row['user_id']?.toString() == currentUserId) {
          userRatings[itemId] = rating;
        }
      }

      return items.map((item) {
        final count = counts[item.id] ?? 0;
        if (count == 0) return item;

        return item.copyWith(
          ratingAverage: (totals[item.id] ?? 0) / count,
          ratingCount: count,
          userRating: userRatings[item.id],
        );
      }).toList();
    } catch (e) {
      debugPrint('Food ratings unavailable: $e');
      return items;
    }
  }

  Future<void> _openFoodRatingSheet(_FoodItem item) async {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) {
      AppToast.show(
        context: context,
        message: 'Please sign in before rating food.',
        type: AppToastType.error,
      );
      return;
    }

    final initialRating =
        item.userRating ??
        (item.ratingCount > 0 ? item.ratingAverage.round() : 5);
    final rating = await _showFoodRatingSheet(
      item: item,
      initialRating: _clampFoodRating(initialRating),
    );
    if (rating == null) return;
    if (!mounted) return;

    if (item.id.startsWith('sample-')) {
      _applyLocalFoodRating(item.id, rating);
      AppToast.show(
        context: context,
        message: 'Rating saved.',
        type: AppToastType.success,
      );
      return;
    }

    try {
      await _supabase.from('food_item_ratings').upsert({
        'food_item_id': item.id,
        'user_id': state.user.id,
        'rating': rating,
      }, onConflict: 'food_item_id,user_id');

      if (!mounted) return;
      _applyLocalFoodRating(item.id, rating);
      AppToast.show(
        context: context,
        message: 'Rating saved.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Food rating error: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message:
            'Food ratings are not ready. Run schema_v6_food_marketplace.sql.',
        type: AppToastType.error,
      );
    }
  }

  void _applyLocalFoodRating(String itemId, int rating) {
    if (!mounted) return;
    setState(() {
      _items = _items
          .map((item) => item.id == itemId ? item.withUserRating(rating) : item)
          .toList();
    });
  }

  Future<int?> _showFoodRatingSheet({
    required _FoodItem item,
    required int initialRating,
  }) {
    var selectedRating = _clampFoodRating(initialRating);

    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sheetContext.appBorder,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FoodRatingBadge(item: item, large: true),
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      'Rate ${item.title}',
                      variant: AppTextVariant.heading3,
                      fontWeight: FontWeight.w900,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      'Your rating helps other users choose faster.',
                      variant: AppTextVariant.bodyMedium,
                      color: sheetContext.appTextSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          tooltip: '$value star',
                          onPressed: () =>
                              setSheetState(() => selectedRating = value),
                          icon: Icon(
                            value <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: 'SAVE RATING',
                      fullWidth: true,
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(selectedRating),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: AppText(
                        'Cancel',
                        variant: AppTextVariant.button,
                        color: sheetContext.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectRestaurant(_RestaurantFeature restaurant) {
    setState(() {
      _tab = 'for_you';
      _categoryFilterId = null;
      _restaurantFilterId = restaurant.id;
      _restaurantFilterName = restaurant.name;
    });
  }

  void _clearRestaurantFilter() {
    setState(() {
      _restaurantFilterId = null;
      _restaurantFilterName = null;
    });
  }

  Future<void> _pickListingImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 6 * 1024 * 1024) {
        if (!mounted) return;
        AppToast.show(
          context: context,
          message: 'Choose an image under 6MB.',
          type: AppToastType.error,
        );
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
        _uploadedImageUrl = null;
      });
    } catch (e) {
      debugPrint('Food image picker error: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Could not open image picker.',
        type: AppToastType.error,
      );
    }
  }

  Future<String> _uploadListingImage(String userId) async {
    final bytes = _selectedImageBytes;
    if (_uploadedImageUrl != null && bytes == null) return _uploadedImageUrl!;
    if (bytes == null) {
      throw StateError('Food image is required');
    }

    final extension = _imageExtension(_selectedImageName);
    final filePath =
        'client/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabase.storage
        .from('food_images')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageContentType(extension),
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final publicUrl = _supabase.storage
        .from('food_images')
        .getPublicUrl(filePath);
    _uploadedImageUrl = publicUrl;
    return publicUrl;
  }

  Future<void> _submitListing() async {
    if (!_sellFormKey.currentState!.validate()) return;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) {
      AppToast.show(
        context: context,
        message: 'Please sign in before listing food.',
        type: AppToastType.error,
      );
      return;
    }

    if (_selectedImageBytes == null && _uploadedImageUrl == null) {
      AppToast.show(
        context: context,
        message: 'Upload a food image before publishing.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final price = double.parse(_priceController.text.trim());
      final name = [
        state.user.firstName,
        state.user.lastName,
      ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
      final imageUrl = await _uploadListingImage(state.user.id);
      final restaurantName = _restaurantNameController.text.trim();

      await _supabase.from('food_marketplace_items').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'image_url': imageUrl,
        'restaurant_name': restaurantName.isEmpty ? null : restaurantName,
        'seller_name': name.isEmpty ? state.user.email : name,
        'seller_phone': _phoneController.text.trim(),
        'pickup_location': _pickupController.text.trim(),
        'category_id': _sellCategoryId,
        'source_type': 'client',
        'is_active': true,
        'is_featured': false,
      });

      _titleController.clear();
      _restaurantNameController.clear();
      _priceController.clear();
      _pickupController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
        _uploadedImageUrl = null;
      });
      await _loadFoodMarketplace();

      if (!mounted) return;
      setState(() => _tab = 'for_you');
      AppToast.show(
        context: context,
        message: 'Food listing published.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Food listing error: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message:
            'Food marketplace is not ready. Run schema_v6_food_marketplace.sql.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  static bool _sameText(String value, String? other) {
    if (other == null) return false;
    return value.trim().toLowerCase() == other.trim().toLowerCase();
  }

  static String _imageExtension(String? fileName) {
    final lower = fileName?.toLowerCase() ?? '';
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  static String _imageContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _openOrderSheet(_FoodItem item) async {
    final state = context.read<AuthBloc>().state;
    final initialPhone = state is AuthAuthenticated
        ? state.user.phone ?? ''
        : '';

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _FoodOrderSheetControllerHost(
          initialPhone: initialPhone,
          builder: (addressController, phoneController) {
            return _buildOrderSheet(
              sheetContext: sheetContext,
              item: item,
              addressController: addressController,
              phoneController: phoneController,
            );
          },
        );
      },
    );
  }

  Widget _buildOrderSheet({
    required BuildContext sheetContext,
    required _FoodItem item,
    required TextEditingController addressController,
    required TextEditingController phoneController,
  }) {
    final description = item.description.trim().isEmpty
        ? 'No description added.'
        : item.description.trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.appBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _NetworkFoodImage(url: item.imageUrl),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.04),
                              Colors.black.withValues(alpha: 0.46),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: AppText(
                          '${item.priceLabel} ETB',
                          variant: AppTextVariant.bodyMedium,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodRatingBadge(
                  item: item,
                  large: true,
                  onTap: () => _openFoodRatingSheet(item),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    item.title,
                    variant: AppTextVariant.heading2,
                    fontWeight: FontWeight.w900,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FoodDetailChip(
                  icon: Icons.category_outlined,
                  label: item.categoryName,
                ),
                if (item.isFeatured)
                  const _FoodDetailChip(
                    icon: Icons.star_rounded,
                    label: 'Featured',
                    highlighted: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: sheetContext.appSurfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sheetContext.appBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Food details',
                    variant: AppTextVariant.bodyMedium,
                    fontWeight: FontWeight.w900,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FoodDetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'Restaurant',
                    value: item.restaurantDisplayName,
                  ),
                  _FoodDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Seller',
                    value: item.sellerName.isEmpty
                        ? 'Not specified'
                        : item.sellerName,
                  ),
                  _FoodDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Seller phone',
                    value: item.sellerPhone.isEmpty
                        ? 'Not specified'
                        : item.sellerPhone,
                  ),
                  _FoodDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup',
                    value: item.pickupLocation.isEmpty
                        ? 'Not specified'
                        : item.pickupLocation,
                  ),
                  if (item.pickupCoordinateLabel != null)
                    _FoodDetailRow(
                      icon: Icons.my_location_outlined,
                      label: 'Map point',
                      value: item.pickupCoordinateLabel!,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    description,
                    variant: AppTextVariant.bodySmall,
                    color: sheetContext.appTextSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SheetField(
              controller: addressController,
              label: 'Delivery address',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetField(
              controller: phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'REQUEST DELIVERY',
              icon: Icons.delivery_dining_rounded,
              fullWidth: true,
              onPressed: () async {
                final address = addressController.text.trim();
                final phone = phoneController.text.trim();
                if (address.isEmpty || phone.isEmpty) {
                  AppToast.show(
                    context: context,
                    message: 'Add delivery address and phone.',
                    type: AppToastType.error,
                  );
                  return;
                }
                Navigator.of(sheetContext).pop();
                await _requestFoodDelivery(item, address, phone);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestFoodDelivery(
    _FoodItem item,
    String address,
    String phone,
  ) async {
    if (!mounted) return;
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) {
      AppToast.show(
        context: context,
        message: 'Please sign in before ordering.',
        type: AppToastType.error,
      );
      return;
    }

    try {
      final customerName = [
        state.user.firstName,
        state.user.lastName,
      ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
      final pickupDetails = [
        item.restaurantDisplayName,
        if (item.sellerPhone.trim().isNotEmpty) item.sellerPhone.trim(),
        if (item.pickupLocation.trim().isNotEmpty) item.pickupLocation.trim(),
      ].join(' - ');
      final packageDetails = [
        item.title,
        item.restaurantDisplayName,
        '${item.priceLabel} ETB',
      ].join(' - ');

      await _supabase.from('deliveries').insert({
        'customer_name': customerName.isEmpty ? state.user.email : customerName,
        'customer_phone': phone,
        'client_id': state.user.id,
        'pickup_location': pickupDetails,
        'pickup_lat': item.pickupLat,
        'pickup_lng': item.pickupLng,
        'dropoff_location': address,
        'package_type': 'Food: $packageDetails',
        'service_type': 'food_marketplace',
        'vehicle_category': 'Motor',
        'delivery_fee': null,
        'status': 'Pending',
      });

      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Food delivery request sent.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Food delivery request error: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Could not request food delivery.',
        type: AppToastType.error,
      );
    }
  }

  void _focusMarketplaceSearch() {
    if (_tab != 'for_you') {
      setState(() => _tab = 'for_you');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
      });
      return;
    }

    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFoodMarketplace,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_tab == 'sell')
                SliverToBoxAdapter(child: _buildSellForm())
              else if (_tab == 'categories')
                SliverToBoxAdapter(child: _buildCategoriesView())
              else ...[
                SliverToBoxAdapter(child: _buildFeaturedRestaurants()),
                SliverToBoxAdapter(child: _buildPicksHeader()),
                _buildFoodGrid(_visibleItems),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: _bottomNavClearance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: NavigationService().triggerHomeAction,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  'Marketplace',
                  variant: AppTextVariant.heading1,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _focusMarketplaceSearch,
                icon: Icon(Icons.search_rounded, color: context.appTextPrimary),
              ),
              IconButton(
                onPressed: () => NavigationService().navigateToTab(3),
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _TabChip(
                label: 'Sell',
                selected: _tab == 'sell',
                onTap: () => setState(() => _tab = 'sell'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TabChip(
                label: 'For you',
                selected: _tab == 'for_you',
                onTap: () => setState(() => _tab = 'for_you'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TabChip(
                label: 'Categories',
                selected: _tab == 'categories',
                onTap: () => setState(() => _tab = 'categories'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search foods',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: context.appSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: context.appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: context.appBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRestaurants() {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _selectRestaurant(restaurant),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _NetworkFoodImage(url: restaurant.imageUrl),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.68),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: AppSpacing.md,
                    start: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant.isFeatured
                            ? AppColors.primary
                            : Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: AppText(
                        restaurant.isFeatured ? 'Featured' : 'Restaurant',
                        variant: AppTextVariant.labelSmall,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: AppSpacing.md,
                    end: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          restaurant.name,
                          variant: AppTextVariant.heading3,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          restaurant.subtitle,
                          variant: AppTextVariant.bodySmall,
                          color: Colors.white.withValues(alpha: 0.84),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPicksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              _restaurantFilterName == null
                  ? "Today's picks"
                  : '${_restaurantFilterName!} foods',
              variant: AppTextVariant.heading2,
              fontWeight: FontWeight.w900,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_restaurantFilterName != null)
            TextButton(
              onPressed: _clearRestaurantFilter,
              child: const Text('All'),
            )
          else ...[
            const Icon(Icons.location_on_rounded, color: AppColors.primary),
            const SizedBox(width: 4),
            AppText(
              'Addis Ababa',
              variant: AppTextVariant.bodyMedium,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodGrid(List<_FoodItem> items) {
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: AppText(
            'No food listings found',
            variant: AppTextVariant.heading3,
            color: context.appTextSecondary,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _FoodItemCard(
            item: items[index],
            onTap: () => _openOrderSheet(items[index]),
            onRatingTap: () => _openFoodRatingSheet(items[index]),
          ),
          childCount: items.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _CategoryChip(
                label: 'All',
                selected: _categoryFilterId == null,
                onTap: () => setState(() {
                  _categoryFilterId = null;
                }),
              ),
              ..._categories.map(
                (category) => _CategoryChip(
                  label: category.name,
                  selected: _categoryFilterId == category.id,
                  onTap: () => setState(() {
                    _categoryFilterId = category.id;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInlineGrid(_visibleItems),
        ],
      ),
    );
  }

  Widget _buildInlineGrid(List<_FoodItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => _FoodItemCard(
        item: items[index],
        onTap: () => _openOrderSheet(items[index]),
        onRatingTap: () => _openFoodRatingSheet(items[index]),
      ),
    );
  }

  Widget _buildSellForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Form(
        key: _sellFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Sell food',
              variant: AppTextVariant.heading2,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: AppSpacing.md),
            _FormFieldBox(
              controller: _titleController,
              label: 'Food name',
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _FormFieldBox(
              controller: _restaurantNameController,
              label: 'Restaurant name (optional)',
              icon: Icons.storefront_rounded,
              validator: (_) => null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _FormFieldBox(
                    controller: _priceController,
                    label: 'Price ETB',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) return 'Enter price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sellCategoryId,
                    isExpanded: true,
                    dropdownColor: context.appSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    decoration: _inputDecoration(
                      'Category',
                      Icons.category_outlined,
                    ),
                    selectedItemBuilder: (context) => _categories
                        .map(
                          (category) => Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                        .toList(),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _sellCategoryId = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FormFieldBox(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _FormFieldBox(
              controller: _pickupController,
              label: 'Pickup location',
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _ImageUploadBox(
              imageBytes: _selectedImageBytes,
              fileName: _selectedImageName,
              onPick: _pickListingImage,
              onClear: () {
                setState(() {
                  _selectedImageBytes = null;
                  _selectedImageName = null;
                  _uploadedImageUrl = null;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _FormFieldBox(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.notes_rounded,
              minLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'PUBLISH FOOD',
              fullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _submitListing,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: context.appSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: context.appBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: context.appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({
    required this.item,
    required this.onTap,
    required this.onRatingTap,
  });

  final _FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: context.appSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _NetworkFoodImage(url: item.imageUrl)),
                  if (item.isFeatured)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const AppText(
                          'Featured',
                          variant: AppTextVariant.labelSmall,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _FoodRatingBadge(item: item, onTap: onRatingTap),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AppText(
                          item.title,
                          variant: AppTextVariant.bodySmall,
                          fontWeight: FontWeight.w900,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    '${item.priceLabel} ETB',
                    variant: AppTextVariant.labelSmall,
                    fontWeight: FontWeight.w900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    item.restaurantDisplayName,
                    variant: AppTextVariant.labelSmall,
                    color: context.appTextSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _FoodRatingBadge extends StatelessWidget {
  const _FoodRatingBadge({required this.item, this.onTap, this.large = false});

  final _FoodItem item;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hasRating = item.ratingCount > 0;
    final label = hasRating ? item.ratingAverage.toStringAsFixed(1) : 'Rate';
    final countLabel = hasRating ? ' (${item.ratingCount})' : '';
    final iconSize = large ? 20.0 : 15.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 7,
            vertical: large ? 7 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.36)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: iconSize),
              const SizedBox(width: 3),
              AppText(
                '$label$countLabel',
                variant: large
                    ? AppTextVariant.bodySmall
                    : AppTextVariant.labelSmall,
                color: context.appTextPrimary,
                fontWeight: FontWeight.w900,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkFoodImage extends StatelessWidget {
  const _NetworkFoodImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _imageFallback(context);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(context),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _imageFallback(context);
      },
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      color: context.appSurfaceAlt,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.imageBytes,
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 72,
                height: 72,
                color: context.appSurfaceAlt,
                child: hasImage
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    hasImage ? 'Food image selected' : 'Upload food image',
                    variant: AppTextVariant.bodyMedium,
                    fontWeight: FontWeight.w900,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    hasImage
                        ? fileName ?? 'Ready to upload'
                        : 'Choose from gallery',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasImage)
              IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: context.appTextSecondary,
                ),
              )
            else
              Icon(Icons.upload_rounded, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _FoodOrderSheetControllerHost extends StatefulWidget {
  const _FoodOrderSheetControllerHost({
    required this.initialPhone,
    required this.builder,
  });

  final String initialPhone;
  final Widget Function(
    TextEditingController addressController,
    TextEditingController phoneController,
  )
  builder;

  @override
  State<_FoodOrderSheetControllerHost> createState() =>
      _FoodOrderSheetControllerHostState();
}

class _FoodOrderSheetControllerHostState
    extends State<_FoodOrderSheetControllerHost> {
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_addressController, _phoneController);
  }
}

class _FormFieldBox extends StatelessWidget {
  const _FormFieldBox({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 5,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: context.appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.appSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: context.appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _FoodDetailChip extends StatelessWidget {
  const _FoodDetailChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: highlighted ? AppColors.primary : context.appBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted ? AppColors.primary : context.appTextSecondary,
          ),
          const SizedBox(width: 6),
          AppText(
            label,
            variant: AppTextVariant.labelSmall,
            color: highlighted ? AppColors.primary : context.appTextPrimary,
            fontWeight: FontWeight.w900,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FoodDetailRow extends StatelessWidget {
  const _FoodDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.appTextSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  variant: AppTextVariant.labelSmall,
                  color: context.appTextSecondary,
                  fontWeight: FontWeight.w800,
                ),
                const SizedBox(height: 1),
                AppText(
                  value,
                  variant: AppTextVariant.bodySmall,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          color: selected ? AppColors.primary : context.appTextPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.14),
      backgroundColor: context.appSurface,
      side: BorderSide(color: selected ? AppColors.primary : context.appBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

class _FoodCategory {
  const _FoodCategory({required this.id, required this.name});

  factory _FoodCategory.fromMap(Map<String, dynamic> map) {
    return _FoodCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Food',
    );
  }

  final String id;
  final String name;
}

class _FoodItem {
  const _FoodItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    required this.sellerPhone,
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.categoryId,
    required this.categoryName,
    required this.restaurantId,
    required this.restaurantName,
    required this.isFeatured,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.userRating,
  });

  factory _FoodItem.fromMap(Map<String, dynamic> map) {
    final category = map['category'];
    final restaurant = map['restaurant'];
    final linkedRestaurantName = restaurant is Map
        ? restaurant['name']?.toString()
        : null;
    return _FoodItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Food item',
      description: map['description']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '') ?? 0,
      imageUrl: map['image_url']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? 'Seller',
      sellerPhone: map['seller_phone']?.toString() ?? '',
      pickupLocation: map['pickup_location']?.toString() ?? '',
      pickupLat: _asNullableDouble(map['pickup_lat']),
      pickupLng: _asNullableDouble(map['pickup_lng']),
      categoryId: map['category_id']?.toString(),
      categoryName: category is Map
          ? category['name']?.toString() ?? 'Food'
          : map['category_name']?.toString() ?? 'Food',
      restaurantId: map['restaurant_id']?.toString(),
      restaurantName:
          linkedRestaurantName ?? map['restaurant_name']?.toString() ?? '',
      isFeatured: map['is_featured'] == true,
      ratingAverage: _asNullableDouble(map['rating_average']) ?? 0,
      ratingCount: int.tryParse(map['rating_count']?.toString() ?? '') ?? 0,
    );
  }

  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String sellerName;
  final String sellerPhone;
  final String pickupLocation;
  final double? pickupLat;
  final double? pickupLng;
  final String? categoryId;
  final String categoryName;
  final String? restaurantId;
  final String restaurantName;
  final bool isFeatured;
  final double ratingAverage;
  final int ratingCount;
  final int? userRating;

  String get priceLabel => price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);

  String get restaurantDisplayName {
    final value = restaurantName.trim();
    return value.isEmpty ? sellerName : value;
  }

  String? get pickupCoordinateLabel {
    if (pickupLat == null || pickupLng == null) return null;
    return '${pickupLat!.toStringAsFixed(5)}, ${pickupLng!.toStringAsFixed(5)}';
  }

  _FoodItem copyWith({
    double? ratingAverage,
    int? ratingCount,
    int? userRating,
  }) {
    return _FoodItem(
      id: id,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      pickupLocation: pickupLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      categoryId: categoryId,
      categoryName: categoryName,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      isFeatured: isFeatured,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      userRating: userRating ?? this.userRating,
    );
  }

  _FoodItem withUserRating(int rating) {
    final safeRating = _clampFoodRating(rating);
    final previousRating = userRating;
    final nextCount = previousRating == null ? ratingCount + 1 : ratingCount;
    final previousTotal = ratingAverage * ratingCount;
    final nextTotal = previousRating == null
        ? previousTotal + safeRating
        : previousTotal - previousRating + safeRating;

    return copyWith(
      ratingAverage: nextCount == 0 ? 0 : nextTotal / nextCount,
      ratingCount: nextCount,
      userRating: safeRating,
    );
  }

  static double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class _RestaurantFeature {
  const _RestaurantFeature({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.isFeatured,
    required this.sortOrder,
  });

  factory _RestaurantFeature.fromMap(Map<String, dynamic> map) {
    return _RestaurantFeature(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Restaurant',
      subtitle: map['subtitle']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      isFeatured: map['is_featured'] == true,
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
    );
  }

  final String? id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final bool isFeatured;
  final int sortOrder;
}

const List<_FoodCategory> _sampleCategories = [
  _FoodCategory(id: 'breakfast', name: 'Breakfast'),
  _FoodCategory(id: 'chicken', name: 'Chicken'),
  _FoodCategory(id: 'ethiopian', name: 'Ethiopian'),
  _FoodCategory(id: 'fast_food', name: 'Fast food'),
];

const List<_RestaurantFeature> _featuredRestaurants = [
  _RestaurantFeature(
    id: 'sample-simple-pistro',
    name: 'Simple pistro',
    subtitle: 'Burgers, pasta and cafe plates',
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
    isFeatured: true,
    sortOrder: 1,
  ),
  _RestaurantFeature(
    id: 'sample-amrogn-chiken',
    name: 'Amrogn chiken',
    subtitle: 'Crispy chicken and family meals',
    imageUrl:
        'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80',
    isFeatured: true,
    sortOrder: 2,
  ),
];

const List<_FoodItem> _sampleItems = [
  _FoodItem(
    id: 'sample-burger',
    title: 'Simple burger combo',
    description: 'Burger and fries',
    price: 420,
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
    sellerName: 'Simple pistro',
    sellerPhone: '+251 900 000 001',
    pickupLocation: 'Simple pistro, Addis Ababa',
    pickupLat: 9.0116,
    pickupLng: 38.7850,
    categoryId: 'fast_food',
    categoryName: 'Fast food',
    restaurantId: 'sample-simple-pistro',
    restaurantName: 'Simple pistro',
    isFeatured: true,
    ratingAverage: 4.8,
    ratingCount: 42,
  ),
  _FoodItem(
    id: 'sample-chicken',
    title: 'Amrogn crispy chicken',
    description: 'Crispy chicken plate',
    price: 520,
    imageUrl:
        'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80',
    sellerName: 'Amrogn chiken',
    sellerPhone: '+251 900 000 002',
    pickupLocation: 'Amrogn chiken, Addis Ababa',
    pickupLat: 9.0069,
    pickupLng: 38.7852,
    categoryId: 'chicken',
    categoryName: 'Chicken',
    restaurantId: 'sample-amrogn-chiken',
    restaurantName: 'Amrogn chiken',
    isFeatured: true,
    ratingAverage: 4.6,
    ratingCount: 31,
  ),
  _FoodItem(
    id: 'sample-doro',
    title: 'Doro wat family plate',
    description: 'Spicy chicken stew with injera',
    price: 680,
    imageUrl:
        'https://images.unsplash.com/photo-1548940740-204726a19be3?auto=format&fit=crop&w=900&q=80',
    sellerName: 'Home kitchen',
    sellerPhone: '+251 900 000 003',
    pickupLocation: 'Bole, Addis Ababa',
    pickupLat: 8.9950,
    pickupLng: 38.7894,
    categoryId: 'ethiopian',
    categoryName: 'Ethiopian',
    restaurantId: null,
    restaurantName: '',
    isFeatured: false,
    ratingAverage: 4.9,
    ratingCount: 18,
  ),
  _FoodItem(
    id: 'sample-bowl',
    title: 'Fresh lunch bowl',
    description: 'Rice, vegetables and sauce',
    price: 350,
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
    sellerName: 'Mimi kitchen',
    sellerPhone: '+251 900 000 004',
    pickupLocation: 'Kazanchis, Addis Ababa',
    pickupLat: 9.0133,
    pickupLng: 38.7652,
    categoryId: 'breakfast',
    categoryName: 'Breakfast',
    restaurantId: null,
    restaurantName: '',
    isFeatured: false,
    ratingAverage: 4.5,
    ratingCount: 15,
  ),
];
