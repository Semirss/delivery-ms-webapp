import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _clearedNotificationIdsKey =
      'client_cleared_notification_ids';

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _notifications = [];
  Set<String> _clearedNotificationIds = <String>{};
  RealtimeChannel? _channel;
  String? _recipientId;
  String? _recipientPhone;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    _recipientId = user?.id;
    _recipientPhone =
        _cleanRecipient(user?.phone) ?? _cleanRecipient(user?.email);

    await _loadClearedNotificationIds();
    await _fetchNotifications();
    _subscribe();
  }

  Future<void> _loadClearedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    _clearedNotificationIds = Set<String>.from(
      prefs.getStringList(_clearedNotificationIdsKey) ?? const <String>[],
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _supabase
          .from('app_notifications')
          .select()
          .eq('app', 'client')
          .order('created_at', ascending: false)
          .limit(100);

      final notifications = List<Map<String, dynamic>>.from(data)
          .where(_matchesCurrentUser)
          .where((notification) {
            final id = notification['id']?.toString();
            return id == null || !_clearedNotificationIds.contains(id);
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
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
    final channelKey = _recipientPhone ?? _recipientId ?? 'anonymous';
    _channel = _supabase
        .channel('public:app_notifications:client:$channelKey')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'app',
            value: 'client',
          ),
          callback: (_) => _fetchNotifications(),
        )
        .subscribe();
  }

  bool _matchesCurrentUser(Map<String, dynamic> notification) {
    final recipientId = notification['recipient_id']?.toString();
    final recipientPhone = notification['recipient_phone']?.toString();

    if (recipientId == null && recipientPhone == null) return true;
    if (_recipientId != null && recipientId == _recipientId) return true;
    if (_recipientPhone != null && recipientPhone == _recipientPhone) {
      return true;
    }
    return false;
  }

  String? _cleanRecipient(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['read_at'] != null) return;
    final id = notification['id']?.toString();
    if (id == null) return;

    await _supabase
        .from('app_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);

    await _fetchNotifications();
  }

  Future<void> _clearNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final nextIds = {..._clearedNotificationIds, id};
    await prefs.setStringList(_clearedNotificationIdsKey, nextIds.toList());
    if (!mounted) return;
    setState(() {
      _clearedNotificationIds = nextIds;
      _notifications.removeWhere(
        (notification) => notification['id']?.toString() == id,
      );
    });
  }

  Future<void> _clearAllNotifications() async {
    final ids = _notifications
        .map((notification) => notification['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty || _isClearing) return;

    setState(() => _isClearing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final nextIds = {..._clearedNotificationIds, ...ids};
      await prefs.setStringList(_clearedNotificationIdsKey, nextIds.toList());
      if (!mounted) return;
      setState(() {
        _clearedNotificationIds = nextIds;
        _notifications = const [];
      });
      AppToast.show(
        context: context,
        message: 'Notifications cleared.',
        type: AppToastType.success,
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        titleText: 'Notifications',
        actions: [
          IconButton(
            tooltip: 'Clear notifications',
            icon: _isClearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.clear_all_rounded),
            onPressed: _notifications.isEmpty || _isClearing
                ? null
                : _clearAllNotifications,
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

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppText(
            errorMessage,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: context.appBorder,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AppText(
                'No notifications yet',
                variant: AppTextVariant.heading3,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          return _NotificationCard(
            notification: _notifications[index],
            onTap: () => _markAsRead(_notifications[index]),
            onClear: () => _clearNotification(_notifications[index]),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onClear,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['read_at'] == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.22)
                : context.appBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                _iconForType(notification['type']),
                color: AppColors.primary,
              ),
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
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
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
                      IconButton(
                        tooltip: 'Clear',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.appTextSecondary,
                          size: 18,
                        ),
                        onPressed: onClear,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    notification['body']?.toString() ?? '',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    _formatDate(notification['created_at']),
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
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

  String _formatDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(date.toLocal());
  }
}
