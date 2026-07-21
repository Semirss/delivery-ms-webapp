import 'dart:async';
import 'dart:typed_data';

import 'package:client_app/config/router/app_routes.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/core/utils/functions/base_functions/ethiopian_phone.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'package:client_app/features/search/presentation/screens/search_destination_screen.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class _FoodDeliveryPricing {
  const _FoodDeliveryPricing({
    required this.title,
    required this.baseFare,
    required this.perKm,
    required this.icon,
  });

  final String title;
  final int baseFare;
  final int perKm;
  final IconData icon;
}

const Map<String, _FoodDeliveryPricing> _foodDeliveryPricing = {
  'Bike': _FoodDeliveryPricing(
    title: 'Bicycle',
    baseFare: 30,
    perKm: 40,
    icon: Icons.directions_bike_rounded,
  ),
  'Motor': _FoodDeliveryPricing(
    title: 'Motorbike',
    baseFare: 40,
    perKm: 50,
    icon: Icons.motorcycle_rounded,
  ),
};

const double _fallbackFoodPickupLat = 9.0108;
const double _fallbackFoodPickupLng = 38.7612;
const LatLng _fallbackFoodDeliveryCenter = LatLng(8.9806, 38.7578);

enum _FoodDeliveryAddressChoice { gps, neighborhood, pinOnMap }

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
  static const double _bottomNavClearance = 132;

  final SupabaseClient _supabase = Supabase.instance.client;
  final MapRepository _mapRepository = MapRepository();
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
        _phoneController.text = ethiopianPhoneInputText(state.user.phone ?? '');
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

  List<_FoodItem> _itemsForRestaurant(_RestaurantFeature restaurant) {
    return _items.where((item) {
      final matchesId =
          restaurant.id != null && item.restaurantId == restaurant.id;
      final matchesLinkedName = _sameText(item.restaurantName, restaurant.name);
      final matchesSellerName =
          item.restaurantId == null &&
          _sameText(item.sellerName, restaurant.name);
      return matchesId || matchesLinkedName || matchesSellerName;
    }).toList();
  }

  Future<void> _openRestaurant(_RestaurantFeature restaurant) async {
    final restaurantItems = _itemsForRestaurant(restaurant);
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => _RestaurantMenuScreen(
          restaurant: restaurant,
          items: restaurantItems,
          onOrder: _openOrderSheet,
          onRatingTap: _openFoodRatingSheet,
        ),
      ),
    );
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
        'seller_phone': normalizeEthiopianPhone(_phoneController.text),
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
        ? ethiopianPhoneInputText(state.user.phone ?? '')
        : '';

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return _FoodOrderSheetControllerHost(
          initialPhone: initialPhone,
          builder:
              (
                addressController,
                phoneController,
                selectedVehicle,
                onVehicleChanged,
                selectedDestination,
                onDestinationChanged,
              ) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.92,
                  minChildSize: 0.30,
                  maxChildSize: 0.96,
                  snap: true,
                  snapSizes: const [0.52, 0.92],
                  builder: (context, scrollController) {
                    return _buildOrderSheet(
                      sheetContext: sheetContext,
                      scrollController: scrollController,
                      item: item,
                      addressController: addressController,
                      phoneController: phoneController,
                      selectedVehicle: selectedVehicle,
                      onVehicleChanged: onVehicleChanged,
                      selectedDestination: selectedDestination,
                      onDestinationChanged: onDestinationChanged,
                    );
                  },
                );
              },
        );
      },
    );
  }

  Widget _buildOrderSheet({
    required BuildContext sheetContext,
    required ScrollController scrollController,
    required _FoodItem item,
    required TextEditingController addressController,
    required TextEditingController phoneController,
    required String? selectedVehicle,
    required ValueChanged<String> onVehicleChanged,
    required MapPlace? selectedDestination,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) {
    final description = item.description.trim().isEmpty
        ? 'No description added.'
        : item.description.trim();
    final estimate = selectedVehicle == null || selectedDestination == null
        ? null
        : _calculateFoodDeliveryFee(item, selectedDestination, selectedVehicle);
    final estimateDistance =
        selectedVehicle == null || selectedDestination == null
        ? null
        : _foodDeliveryDistanceKm(item, selectedDestination);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Material(
        color: sheetContext.appSurface,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _FoodOrderHero(
                item: item,
                onClose: () => Navigator.of(sheetContext).pop(),
                onRatingTap: () => _openFoodRatingSheet(item),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(sheetContext).viewInsets.bottom +
                      MediaQuery.viewPaddingOf(sheetContext).bottom +
                      AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _FoodDeliveryAddressPicker(
                      address: selectedDestination?.displayName,
                      onTap: () => unawaited(
                        _chooseFoodDeliveryAddress(
                          initialPoint: selectedDestination?.location,
                          addressController: addressController,
                          onDestinationChanged: onDestinationChanged,
                        ),
                      ),
                      onGpsTap: () => unawaited(
                        _useFoodGpsDeliveryAddress(
                          addressController: addressController,
                          onDestinationChanged: onDestinationChanged,
                        ),
                      ),
                      onNeighborhoodTap: () => unawaited(
                        _chooseFoodNeighborhoodAddress(
                          addressController: addressController,
                          onDestinationChanged: onDestinationChanged,
                        ),
                      ),
                      onPinTap: () => unawaited(
                        _pinFoodDeliveryAddress(
                          initialPoint: selectedDestination?.location,
                          addressController: addressController,
                          onDestinationChanged: onDestinationChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FoodVehicleSelector(
                      selectedVehicle: selectedVehicle,
                      onChanged: onVehicleChanged,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FoodDeliveryEstimateCard(
                      vehicleCategory: selectedVehicle,
                      estimate: estimate,
                      distanceKm: estimateDistance,
                      hasExactAddress: selectedDestination != null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SheetField(
                      controller: phoneController,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '$ethiopianDialCode ',
                      validator: validateEthiopianPhone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: 'REQUEST DELIVERY',
                      icon: Icons.delivery_dining_rounded,
                      fullWidth: true,
                      onPressed: () async {
                        final phone = normalizeEthiopianPhone(
                          phoneController.text,
                        );
                        if (selectedDestination == null) {
                          AppToast.show(
                            context: context,
                            message:
                                'Choose where to deliver: use GPS, Neighborhood, or Pin map.',
                            type: AppToastType.error,
                          );
                          return;
                        }
                        if (selectedVehicle == null) {
                          AppToast.show(
                            context: context,
                            message:
                                'Choose delivery vehicle: tap Bicycle or Motorbike.',
                            type: AppToastType.error,
                          );
                          return;
                        }
                        final phoneError = validateEthiopianPhone(phone);
                        if (phoneError != null) {
                          AppToast.show(
                            context: context,
                            message: phoneError,
                            type: AppToastType.error,
                          );
                          return;
                        }
                        final deliveryFee =
                            estimate ??
                            _calculateFoodDeliveryFee(
                              item,
                              selectedDestination,
                              selectedVehicle,
                            );
                        if (deliveryFee == null) {
                          AppToast.show(
                            context: context,
                            message:
                                'Choose a delivery address to calculate the food delivery estimate.',
                            type: AppToastType.error,
                          );
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        await _requestFoodDelivery(
                          item,
                          selectedDestination,
                          selectedVehicle,
                          deliveryFee,
                          phone,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseFoodDeliveryAddress({
    required LatLng? initialPoint,
    required TextEditingController addressController,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) async {
    final choice = await showModalBottomSheet<_FoodDeliveryAddressChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: sheetContext.appSurface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Where should we deliver?',
                  variant: AppTextVariant.heading3,
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  'Choose the easiest way to set your exact delivery point.',
                  variant: AppTextVariant.bodySmall,
                  color: sheetContext.appTextSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                _FoodAddressChoiceTile(
                  icon: Icons.my_location_rounded,
                  title: 'Use current GPS',
                  subtitle: 'Best for door-to-door food delivery.',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FoodDeliveryAddressChoice.gps,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FoodAddressChoiceTile(
                  icon: Icons.travel_explore_rounded,
                  title: 'Choose neighborhood',
                  subtitle: 'Pick an Addis Ababa area manually.',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FoodDeliveryAddressChoice.neighborhood,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FoodAddressChoiceTile(
                  icon: Icons.add_location_alt_rounded,
                  title: 'Pin on map',
                  subtitle: 'Move the map and place the delivery pin.',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FoodDeliveryAddressChoice.pinOnMap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _FoodDeliveryAddressChoice.gps:
        await _useFoodGpsDeliveryAddress(
          addressController: addressController,
          onDestinationChanged: onDestinationChanged,
        );
      case _FoodDeliveryAddressChoice.neighborhood:
        await _chooseFoodNeighborhoodAddress(
          addressController: addressController,
          onDestinationChanged: onDestinationChanged,
        );
      case _FoodDeliveryAddressChoice.pinOnMap:
        await _pinFoodDeliveryAddress(
          initialPoint: initialPoint,
          addressController: addressController,
          onDestinationChanged: onDestinationChanged,
        );
    }
  }

  Future<void> _chooseFoodNeighborhoodAddress({
    required TextEditingController addressController,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) async {
    final destination = await Navigator.of(context, rootNavigator: true)
        .push<MapPlace>(
          MaterialPageRoute(
            builder: (context) => const SearchDestinationScreen(
              title: 'Where should we deliver?',
              subtitle: 'Choose the delivery neighborhood or closest area.',
              emptyTitle: 'No delivery area found',
              emptyMessagePrefix: 'Try another spelling for',
              defaultSectionTitle: 'Major delivery areas',
              defaultSectionSubtitle: 'Tap an area to use it for delivery.',
            ),
          ),
        );
    if (destination == null || !mounted) return;

    addressController.text = destination.displayName;
    onDestinationChanged(destination);
  }

  Future<void> _useFoodGpsDeliveryAddress({
    required TextEditingController addressController,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) async {
    final point = await _currentFoodGpsPoint();
    if (point == null || !mounted) return;
    await _setFoodDeliveryAddressFromPoint(
      point,
      fallbackName: 'Current GPS delivery address',
      addressController: addressController,
      onDestinationChanged: onDestinationChanged,
    );
  }

  Future<void> _pinFoodDeliveryAddress({
    required LatLng? initialPoint,
    required TextEditingController addressController,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) async {
    final point = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => _FoodPinLocationScreen(
          initialCenter: initialPoint ?? _fallbackFoodDeliveryCenter,
        ),
      ),
    );
    if (point == null || !mounted) return;
    await _setFoodDeliveryAddressFromPoint(
      point,
      fallbackName: 'Pinned delivery address',
      addressController: addressController,
      onDestinationChanged: onDestinationChanged,
    );
  }

  Future<void> _setFoodDeliveryAddressFromPoint(
    LatLng point, {
    required String fallbackName,
    required TextEditingController addressController,
    required ValueChanged<MapPlace> onDestinationChanged,
  }) async {
    final destination = await _mapRepository.describeLocation(
      point,
      fallbackName: fallbackName,
    );
    if (!mounted) return;
    addressController.text = destination.displayName;
    onDestinationChanged(destination);
  }

  Future<LatLng?> _currentFoodGpsPoint() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return null;
        await AppModal.info<void>(
          context: context,
          title: 'Turn on location',
          contentText: 'Enable GPS to use your current delivery address.',
          icon: Icons.location_off_outlined,
        );
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        AppToast.show(
          context: context,
          message: 'Location permission is needed for GPS delivery.',
          type: AppToastType.error,
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Food GPS lookup error: $e');
      if (!mounted) return null;
      AppToast.show(
        context: context,
        message: 'Could not read GPS. Choose neighborhood or pin map.',
        type: AppToastType.error,
      );
      return null;
    }
  }

  LatLng _foodPickupPoint(_FoodItem item) {
    if (item.pickupLat != null && item.pickupLng != null) {
      return LatLng(item.pickupLat!, item.pickupLng!);
    }
    return const LatLng(_fallbackFoodPickupLat, _fallbackFoodPickupLng);
  }

  double? _foodDeliveryDistanceKm(_FoodItem item, MapPlace? destination) {
    if (destination == null) {
      return null;
    }

    final distanceKm = _mapRepository.straightLineDistanceKm(
      _foodPickupPoint(item),
      destination.location,
    );
    final cityRoadEstimate = distanceKm * 1.25;
    return cityRoadEstimate < 1 ? 1 : cityRoadEstimate;
  }

  int? _calculateFoodDeliveryFee(
    _FoodItem item,
    MapPlace? destination,
    String vehicleCategory,
  ) {
    final pricing =
        _foodDeliveryPricing[vehicleCategory] ?? _foodDeliveryPricing['Motor']!;
    final distanceKm = _foodDeliveryDistanceKm(item, destination);
    if (distanceKm == null) return null;
    final raw = pricing.baseFare + (distanceKm * pricing.perKm);
    return (raw / 10).round() * 10;
  }

  Future<void> _requestFoodDelivery(
    _FoodItem item,
    MapPlace destination,
    String vehicleCategory,
    int deliveryFee,
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
      final pickupPoint = _foodPickupPoint(item);

      final inserted = await _supabase
          .from('deliveries')
          .insert({
            'customer_name': customerName.isEmpty
                ? state.user.email
                : customerName,
            'customer_phone': phone,
            'client_id': state.user.id,
            'pickup_location': pickupDetails,
            'pickup_lat': pickupPoint.latitude,
            'pickup_lng': pickupPoint.longitude,
            'dropoff_location': destination.displayName,
            'dropoff_lat': destination.location.latitude,
            'dropoff_lng': destination.location.longitude,
            'package_type': 'Food: $packageDetails',
            'service_type': 'food_marketplace',
            'vehicle_category': vehicleCategory,
            'delivery_fee': deliveryFee,
            'status': 'Pending',
          })
          .select('id')
          .single();

      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Food delivery request sent. Opening tracking.',
        type: AppToastType.success,
      );
      final deliveryId = inserted['id']?.toString();
      if (deliveryId != null && deliveryId.isNotEmpty) {
        context.goNamed(
          AppRoutes.tracking.name,
          queryParameters: {'deliveryId': deliveryId},
        );
      }
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
          final foodCount = _itemsForRestaurant(restaurant).length;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openRestaurant(restaurant),
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
                        restaurant.isFeatured
                            ? 'Featured restaurant'
                            : 'Restaurant',
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
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.primary,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  AppText(
                                    foodCount == 1
                                        ? 'Open menu - 1 food'
                                        : 'Open menu - $foodCount foods',
                                    variant: AppTextVariant.labelSmall,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
          childAspectRatio: 0.66,
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
        childAspectRatio: 0.66,
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
              prefixText: '$ethiopianDialCode ',
              validator: validateEthiopianPhone,
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
                  AppText(
                    item.title,
                    variant: AppTextVariant.bodySmall,
                    fontWeight: FontWeight.w900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _FoodRatingBadge(item: item, onTap: onRatingTap),
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

class _RestaurantMenuScreen extends StatefulWidget {
  const _RestaurantMenuScreen({
    required this.restaurant,
    required this.items,
    required this.onOrder,
    required this.onRatingTap,
  });

  final _RestaurantFeature restaurant;
  final List<_FoodItem> items;
  final ValueChanged<_FoodItem> onOrder;
  final ValueChanged<_FoodItem> onRatingTap;

  @override
  State<_RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<_RestaurantMenuScreen> {
  String? _selectedCategoryId;

  List<_FoodCategory> get _menuCategories {
    final seen = <String>{};
    final categories = <_FoodCategory>[];
    for (final item in widget.items) {
      final id =
          (item.categoryId?.trim().isNotEmpty == true
                  ? item.categoryId
                  : item.categoryName)
              ?.trim();
      final name = item.categoryName.trim().isEmpty
          ? 'Food'
          : item.categoryName.trim();
      if (id == null || id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      categories.add(_FoodCategory(id: id, name: name));
    }
    return categories;
  }

  List<_FoodItem> get _visibleItems {
    final selected = _selectedCategoryId;
    if (selected == null) return widget.items;
    return widget.items.where((item) {
      final id = item.categoryId?.trim().isNotEmpty == true
          ? item.categoryId!.trim()
          : item.categoryName.trim();
      return id == selected;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final items = widget.items;
    final visibleItems = _visibleItems;
    final menuCategories = _menuCategories;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 282,
            backgroundColor: context.appSurface,
            foregroundColor: context.appTextPrimary,
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF10243A),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkFoodImage(url: restaurant.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.34),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: AppSpacing.lg,
                    end: AppSpacing.lg,
                    bottom: AppSpacing.xl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const AppText(
                            'Restaurant menu',
                            variant: AppTextVariant.labelSmall,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          restaurant.name,
                          variant: AppTextVariant.heading1,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          restaurant.subtitle.trim().isEmpty
                              ? 'Restaurant'
                              : restaurant.subtitle,
                          variant: AppTextVariant.bodyMedium,
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.w700,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          items.length == 1
                              ? '1 food available'
                              : '${items.length} foods available',
                          variant: AppTextVariant.labelLarge,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty && menuCategories.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Menu categories',
                      variant: AppTextVariant.bodyMedium,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: 'All',
                            selected: _selectedCategoryId == null,
                            onTap: () =>
                                setState(() => _selectedCategoryId = null),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ...menuCategories.map(
                            (category) => Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.sm,
                              ),
                              child: _CategoryChip(
                                label: category.name,
                                selected: _selectedCategoryId == category.id,
                                onTap: () => setState(
                                  () => _selectedCategoryId = category.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: AppText(
                    'No foods are linked to this restaurant yet.',
                    variant: AppTextVariant.heading3,
                    color: context.appTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = visibleItems[index];
                  return _FoodItemCard(
                    item: item,
                    onTap: () => widget.onOrder(item),
                    onRatingTap: () => widget.onRatingTap(item),
                  );
                }, childCount: visibleItems.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  childAspectRatio: 0.66,
                ),
              ),
            ),
        ],
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

class _FoodOrderHero extends StatelessWidget {
  const _FoodOrderHero({
    required this.item,
    required this.onClose,
    required this.onRatingTap,
  });

  final _FoodItem item;
  final VoidCallback onClose;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
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
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const AlignmentDirectional(0.55, -0.65),
                  radius: 1.05,
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 12,
            start: 0,
            end: 0,
            child: Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 28,
            start: AppSpacing.lg,
            child: Material(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: onClose,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF10243A),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FoodHeroPriceBadge(label: '${item.priceLabel} ETB'),
                    _FoodRatingBadge(
                      item: item,
                      large: true,
                      onTap: onRatingTap,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppText(
                  item.title,
                  variant: AppTextVariant.heading1,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _FoodHeroChip(
                      icon: Icons.category_outlined,
                      label: item.categoryName,
                    ),
                    if (item.isFeatured)
                      const _FoodHeroChip(
                        icon: Icons.star_rounded,
                        label: 'Featured',
                        highlighted: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodHeroPriceBadge extends StatelessWidget {
  const _FoodHeroPriceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppText(
        label,
        variant: AppTextVariant.bodyMedium,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FoodHeroChip extends StatelessWidget {
  const _FoodHeroChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primaryLight : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlighted ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          AppText(
            label,
            variant: AppTextVariant.labelSmall,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    String? selectedVehicle,
    ValueChanged<String> onVehicleChanged,
    MapPlace? selectedDestination,
    ValueChanged<MapPlace> onDestinationChanged,
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
  String? _selectedVehicle;
  MapPlace? _selectedDestination;

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
    return widget.builder(
      _addressController,
      _phoneController,
      _selectedVehicle,
      (value) => setState(() => _selectedVehicle = value),
      _selectedDestination,
      (value) => setState(() => _selectedDestination = value),
    );
  }
}

class _FormFieldBox extends StatelessWidget {
  const _FormFieldBox({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.prefixText,
    this.validator,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;
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
        prefixText: prefixText,
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
    this.prefixText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
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

class _FoodDeliveryAddressPicker extends StatelessWidget {
  const _FoodDeliveryAddressPicker({
    required this.address,
    required this.onTap,
    required this.onGpsTap,
    required this.onNeighborhoodTap,
    required this.onPinTap,
  });

  final String? address;
  final VoidCallback onTap;
  final VoidCallback onGpsTap;
  final VoidCallback onNeighborhoodTap;
  final VoidCallback onPinTap;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!.trim().isNotEmpty;
    final borderColor = hasAddress ? AppColors.success : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hasAddress
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (!hasAddress)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.14),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          hasAddress
                              ? 'Delivery address selected'
                              : 'Delivery address',
                          variant: AppTextVariant.labelSmall,
                          color: borderColor,
                          fontWeight: FontWeight.w900,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          hasAddress ? address! : 'Choose where to deliver',
                          variant: hasAddress
                              ? AppTextVariant.bodyMedium
                              : AppTextVariant.heading3,
                          fontWeight: FontWeight.w900,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    hasAddress
                        ? Icons.check_circle_rounded
                        : Icons.expand_more_rounded,
                    color: borderColor,
                    size: hasAddress ? 30 : 32,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _FoodAddressAction(
                    icon: Icons.my_location_rounded,
                    label: 'GPS',
                    onTap: onGpsTap,
                  ),
                  _FoodAddressAction(
                    icon: Icons.travel_explore_rounded,
                    label: 'Neighborhood',
                    onTap: onNeighborhoodTap,
                  ),
                  _FoodAddressAction(
                    icon: Icons.add_location_alt_rounded,
                    label: 'Pin map',
                    onTap: onPinTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodAddressChoiceTile extends StatelessWidget {
  const _FoodAddressChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
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
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      subtitle,
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                    ),
                  ],
                ),
              ),
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

class _FoodAddressAction extends StatelessWidget {
  const _FoodAddressAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      labelStyle: TextStyle(
        color: context.appTextPrimary,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: context.appSurface,
      side: BorderSide(color: context.appBorder),
      onPressed: onTap,
    );
  }
}

class _FoodPinLocationScreen extends StatefulWidget {
  const _FoodPinLocationScreen({required this.initialCenter});

  final LatLng initialCenter;

  @override
  State<_FoodPinLocationScreen> createState() => _FoodPinLocationScreenState();
}

class _FoodPinLocationScreenState extends State<_FoodPinLocationScreen> {
  final MapController _controller = MapController();
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motobikedeliveryservice.client',
                maxNativeZoom: 19,
                keepBuffer: 5,
              ),
            ],
          ),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 52,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: context.appSurface,
                  shape: const CircleBorder(),
                  elevation: 8,
                  child: IconButton(
                    tooltip: 'Back',
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: context.appTextPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Pin delivery address',
                      variant: AppTextVariant.heading3,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.primary(
                      label: 'USE DELIVERY PIN',
                      fullWidth: true,
                      icon: Icons.add_location_alt_rounded,
                      onPressed: () => Navigator.pop(context, _center),
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

class _FoodVehicleSelector extends StatelessWidget {
  const _FoodVehicleSelector({
    required this.selectedVehicle,
    required this.onChanged,
  });

  final String? selectedVehicle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedVehicle != null;
    final borderColor = hasSelection ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.success.withValues(alpha: 0.07)
            : AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          if (!hasSelection)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      hasSelection
                          ? 'Delivery vehicle selected'
                          : 'Choose delivery vehicle',
                      variant: AppTextVariant.bodyMedium,
                      color: borderColor,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      'Tap Bicycle or Motorbike to continue.',
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              if (hasSelection)
                Icon(Icons.check_circle_rounded, color: borderColor, size: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FoodVehicleOption(
                  vehicleCategory: 'Bike',
                  selected: selectedVehicle == 'Bike',
                  onTap: () => onChanged('Bike'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FoodVehicleOption(
                  vehicleCategory: 'Motor',
                  selected: selectedVehicle == 'Motor',
                  onTap: () => onChanged('Motor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodVehicleOption extends StatelessWidget {
  const _FoodVehicleOption({
    required this.vehicleCategory,
    required this.selected,
    required this.onTap,
  });

  final String vehicleCategory;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pricing = _foodDeliveryPricing[vehicleCategory]!;
    final isMotor = vehicleCategory == 'Motor';
    const motorAccent = Color(0xFF2AA7D6);
    const motorCover = Color(0xFFEAF8FF);
    const motorSelectedCover = Color(0xFFDDF4FF);
    const motorBorder = Color(0xFFAFE4FA);
    const motorForeground = Color(0xFF12324A);
    const motorSubtitle = Color(0xFF536C7C);
    final accent = isMotor ? motorAccent : AppColors.secondary;
    final foreground = isMotor
        ? motorForeground
        : selected
        ? Colors.white
        : context.appTextPrimary;
    final subtitleColor = isMotor
        ? motorSubtitle
        : selected
        ? Colors.white.withValues(alpha: 0.82)
        : context.appTextSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? (isMotor ? motorSelectedCover : accent)
              : (isMotor ? motorCover : context.appSurfaceAlt),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? accent
                : (isMotor ? motorBorder : context.appBorder),
            width: isMotor ? 1.4 : 1,
          ),
          boxShadow: [
            if (selected || isMotor)
              BoxShadow(
                color: accent.withValues(alpha: selected ? 0.18 : 0.10),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(pricing.icon, color: foreground, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    pricing.title,
                    variant: AppTextVariant.bodyMedium,
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${pricing.perKm} ETB/km',
                    variant: AppTextVariant.labelSmall,
                    color: subtitleColor,
                    fontWeight: FontWeight.w800,
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

class _FoodDeliveryEstimateCard extends StatelessWidget {
  const _FoodDeliveryEstimateCard({
    required this.vehicleCategory,
    required this.estimate,
    required this.distanceKm,
    required this.hasExactAddress,
  });

  final String? vehicleCategory;
  final int? estimate;
  final double? distanceKm;
  final bool hasExactAddress;

  @override
  Widget build(BuildContext context) {
    final pricing = vehicleCategory == null
        ? null
        : _foodDeliveryPricing[vehicleCategory];
    final resolvedDistanceKm = distanceKm;
    late final String subtitle;
    if (vehicleCategory == null) {
      subtitle = 'Select Bike or Motor to see the delivery estimate.';
    } else if (!hasExactAddress) {
      subtitle = 'Choose address to calculate the real Bike/Motor estimate.';
    } else if (estimate == null || resolvedDistanceKm == null) {
      subtitle = 'Choose address to calculate the food delivery estimate.';
    } else {
      subtitle =
          '${resolvedDistanceKm.toStringAsFixed(1)} km estimate - '
          '${pricing!.baseFare} base + ${pricing.perKm} ETB/km';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Delivery estimate',
                  variant: AppTextVariant.labelSmall,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: 2),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodySmall,
                  color: context.appTextSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppText(
            estimate == null ? '--' : '$estimate ETB',
            variant: AppTextVariant.heading3,
            color: AppColors.primary,
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
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : context.appTextPrimary,
        fontWeight: FontWeight.w900,
      ),
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
      imageUrl:
          map['banner_url']?.toString() ?? map['image_url']?.toString() ?? '',
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
