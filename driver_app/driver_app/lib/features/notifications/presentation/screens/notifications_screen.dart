import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

enum _NotificationFilter { all, unread }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverProfileRepository _profileRepository = DriverProfileRepository();

  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _driver;
  RealtimeChannel? _channel;
  _NotificationFilter _filter = _NotificationFilter.all;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isMarkingAll = false;

  int get _unreadCount =>
      _notifications.where((notification) => notification['read_at'] == null).length;

  List<Map<String, dynamic>> get _visibleNotifications {
    if (_filter == _NotificationFilter.unread) {
      return _notifications
          .where((notification) => notification['read_at'] == null)
          .toList();
    }
    return _notifications;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    await _resolveDriver();
    await _fetchNotifications();
    _subscribe();
  }

  Future<void> _resolveDriver() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    _driver = await _profileRepository.resolveDriver(user);
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _supabase
          .from('app_notifications')
          .select()
          .eq('app', 'driver')
          .order('created_at', ascending: false)
          .limit(100);

      final driver = _driver;
      final notifications = List<Map<String, dynamic>>.from(data)
          .where(
            (notification) => driver == null
                ? true
                : matchesDriverNotification(notification, driver),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Notifications are not ready yet. Run schema_v4 in Supabase.';
        _isLoading = false;
      });
    }
  }

  void _subscribe() {
    _channel?.unsubscribe();
    final driverId = _driver?['id']?.toString() ?? 'anonymous';

    _channel = _supabase
        .channel('public:app_notifications:driver:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'app',
            value: 'driver',
          ),
          callback: (_) => _fetchNotifications(),
        )
        .subscribe();
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['read_at'] != null) {
      _showNotificationDetails(notification);
      return;
    }

    final id = notification['id']?.toString();
    if (id == null) return;

    await _supabase
        .from('app_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);

    await _fetchNotifications();
    if (mounted) _showNotificationDetails(notification);
  }

  Future<void> _markAllAsRead() async {
    final unreadIds = _notifications
        .where((notification) => notification['read_at'] == null)
        .map((notification) => notification['id']?.toString())
        .whereType<String>()
        .toList();
    if (unreadIds.isEmpty) return;

    setState(() => _isMarkingAll = true);
    try {
      final readAt = DateTime.now().toUtc().toIso8601String();
      await Future.wait(
        unreadIds.map(
          (id) => _supabase
              .from('app_notifications')
              .update({'read_at': readAt}).eq('id', id),
        ),
      );
      await _fetchNotifications();
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'All notifications marked read.',
        type: AppToastType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Could not update notifications.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final createdAt = _formatDate(notification['created_at']);
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: sheetContext.appSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _typeColor(
                        notification['type'],
                      ).withValues(alpha: 0.12),
                      child: Icon(
                        _iconForType(notification['type']),
                        color: _typeColor(notification['type']),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppText(
                        notification['title']?.toString() ?? 'Notification',
                        variant: AppTextVariant.heading3,
                        color: sheetContext.appTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppText(
                  notification['body']?.toString() ?? '',
                  variant: AppTextVariant.bodyMedium,
                  color: sheetContext.appTextSecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                _detailLine(sheetContext, 'Type', _typeLabel(notification['type'])),
                _detailLine(sheetContext, 'Created', createdAt),
                if (notification['delivery_id'] != null)
                  _detailLine(
                    sheetContext,
                    'Delivery ID',
                    notification['delivery_id'].toString(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: context.appTextSecondary,
            ),
          ),
          Flexible(
            child: AppText(
              value,
              variant: AppTextVariant.bodySmall,
              color: context.appTextPrimary,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppAppBar(
        titleText: 'Alerts',
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: context.appTextPrimary),
            onPressed: _fetchNotifications,
          ),
          IconButton(
            tooltip: 'Mark all read',
            icon: _isMarkingAll
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.done_all_rounded,
                    color: _unreadCount == 0
                        ? context.appTextSecondary
                        : AppColors.primary,
                  ),
            onPressed: _unreadCount == 0 || _isMarkingAll
                ? null
                : _markAllAsRead,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.cloud_off_rounded, size: 64, color: context.appBorder),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              _errorMessage!,
              variant: AppTextVariant.bodyMedium,
              color: context.appTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.viewPaddingOf(context).bottom + AppSpacing.xl,
        ),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: AppSpacing.md),
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.md),
          if (_visibleNotifications.isEmpty)
            _buildEmptyState()
          else
            for (final notification in _visibleNotifications)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NotificationCard(
                  notification: notification,
                  onTap: () => _markAsRead(notification),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.primary.withValues(alpha: context.isAppDark ? 0.16 : 0.08),
          context.appSurface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: context.isAppDark ? 0.24 : 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.notifications_active_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Driver alerts',
                  variant: AppTextVariant.heading3,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText(
                  _unreadCount == 0
                      ? 'Everything is read'
                      : '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}',
                  variant: AppTextVariant.bodySmall,
                  color: context.appTextSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          _filterButton('All', _NotificationFilter.all, _notifications.length),
          _filterButton('Unread', _NotificationFilter.unread, _unreadCount),
        ],
      ),
    );
  }

  Widget _filterButton(String label, _NotificationFilter filter, int count) {
    final selected = _filter == filter;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: AppText(
            '$label ($count)',
            variant: AppTextVariant.labelLarge,
            color: selected ? Colors.white : context.appTextSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final unreadOnly = _filter == _NotificationFilter.unread;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Icon(
            unreadOnly
                ? Icons.mark_email_read_rounded
                : Icons.notifications_none_rounded,
            size: 64,
            color: context.appTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            unreadOnly ? 'No unread alerts' : 'No notifications yet',
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            unreadOnly
                ? 'New delivery updates will appear here.'
                : 'Assignments and status changes will appear here.',
            variant: AppTextVariant.bodyMedium,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _iconForType(Object? type) {
    final value = type?.toString() ?? '';
    if (value.contains('assigned')) return Icons.delivery_dining_rounded;
    if (value.contains('status')) return Icons.route_rounded;
    if (value.contains('created')) return Icons.inventory_2_rounded;
    return Icons.notifications_rounded;
  }

  Color _typeColor(Object? type) {
    final value = type?.toString() ?? '';
    if (value.contains('assigned')) return AppColors.primary;
    if (value.contains('status')) return AppColors.info;
    if (value.contains('created')) return AppColors.success;
    return AppColors.warning;
  }

  String _typeLabel(Object? type) {
    final value = type?.toString() ?? 'info';
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatDate(Object? value) {
    final date = asDate(value);
    if (date == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(date);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['read_at'] == null;
    final type = notification['type'];
    final typeColor = _typeColor(type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread
              ? Color.alphaBlend(
                  AppColors.primary.withValues(
                    alpha: context.isAppDark ? 0.16 : 0.07,
                  ),
                  context.appSurface,
                )
              : context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(
                    alpha: context.isAppDark ? 0.32 : 0.20,
                  )
                : context.appBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: typeColor.withValues(alpha: 0.12),
              child: Icon(_iconForType(type), color: typeColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          notification['title']?.toString() ?? 'Notification',
                          variant: AppTextVariant.bodyMedium,
                          color: context.appTextPrimary,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    notification['body']?.toString() ?? '',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: context.appTextSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        _formatDate(notification['created_at']),
                        variant: AppTextVariant.bodySmall,
                        color: context.appTextSecondary,
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
  }

  IconData _iconForType(Object? type) {
    final value = type?.toString() ?? '';
    if (value.contains('assigned')) return Icons.delivery_dining_rounded;
    if (value.contains('status')) return Icons.route_rounded;
    if (value.contains('created')) return Icons.inventory_2_rounded;
    return Icons.notifications_rounded;
  }

  Color _typeColor(Object? type) {
    final value = type?.toString() ?? '';
    if (value.contains('assigned')) return AppColors.primary;
    if (value.contains('status')) return AppColors.info;
    if (value.contains('created')) return AppColors.success;
    return AppColors.warning;
  }

  String _formatDate(Object? value) {
    final date = asDate(value);
    if (date == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(date);
  }
}
