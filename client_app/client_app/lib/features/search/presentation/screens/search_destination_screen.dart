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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
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
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
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
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _results[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                              ),
                              title: AppText(
                                place.displayName.split(',').first,
                                variant: AppTextVariant.bodyMedium,
                                fontWeight: FontWeight.bold,
                              ),
                              subtitle: AppText(
                                place.displayName,
                                variant: AppTextVariant.bodySmall,
                                color: AppColors.textSecondary,
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
