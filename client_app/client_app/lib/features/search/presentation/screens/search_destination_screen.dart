import 'package:flutter/material.dart';
import 'package:client_ui/app_ui.dart';
import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'dart:async';

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  State<SearchDestinationScreen> createState() => _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final MapRepository _mapRepository = MapRepository();
  final TextEditingController _searchController = TextEditingController();
  List<MapPlace> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoading = true;
      });

      final results = await _mapRepository.searchAddress(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.appSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.appTextPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.appSurfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon: Icon(Icons.search_rounded, color: context.appTextSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _results.isEmpty && _searchController.text.isNotEmpty
                      ? const Center(child: Text('No results found.'))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: context.appBorder),
                          itemBuilder: (context, index) {
                            final place = _results[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.appSurfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_rounded, color: context.appTextSecondary),
                              ),
                              title: AppText(
                                place.displayName.split(',').first,
                                variant: AppTextVariant.bodyMedium,
                                fontWeight: FontWeight.bold,
                              ),
                              subtitle: AppText(
                                place.displayName,
                                variant: AppTextVariant.bodySmall,
                                color: context.appTextSecondary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.pop(context, place);
                              },
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
