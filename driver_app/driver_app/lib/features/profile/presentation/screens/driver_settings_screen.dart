import 'package:driver_app/core/notifications/local_notification_service.dart';
import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:driver_app/core/preferences/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});
  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  final _api = DriverOperationsApi();
  double _radius = 5;
  bool _notifications = true;
  bool _available = false;
  bool _loading = true;
  bool _saving = false;
  String? _driverId;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.load();
      final driver = data['driver'] as Map;
      if (!mounted) return;
      setState(() {
        _driverId = driver['id']?.toString();
        _radius = double.tryParse('${driver['working_radius_km']}') ?? 5;
        _notifications = driver['notifications_enabled'] != false;
        _available = driver['status'] == 'Online';
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error'.replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.update({
        'action': 'settings',
        'working_radius_km': _radius,
        'notifications_enabled': _notifications,
      });
      if (_notifications) await LocalNotificationService().initialize();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Driver settings saved.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAvailability(bool available) async {
    setState(() => _saving = true);
    try {
      await _api.update({'action': available ? 'online' : 'offline'});
      final driverId = _driverId;
      if (driverId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(
            DriverOperationsApi.availabilityPauseKey(driverId),
            !available,
          );
        } catch (error) {
          debugPrint('Could not save driver availability preference: $error');
        }
      }
      if (mounted) setState(() => _available = available);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Driver settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Appearance'),
            subtitle: Text(
              'Choose a comfortable theme for day and night driving.',
            ),
          ),
          DropdownButtonFormField<ThemeMode>(
            initialValue: preferences.themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            ],
            onChanged: (value) {
              if (value != null) preferences.setThemeMode(value);
            },
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ] else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.online_prediction_rounded),
              title: const Text('Available for deliveries'),
              subtitle: const Text(
                'You start online after sign-in. Turn this off when you need a break.',
              ),
              value: _available,
              onChanged: _saving ? null : _changeAvailability,
            ),
            const SizedBox(height: 16),
            Text(
              'Pickup working radius: ${_radius.toStringAsFixed(0)} km',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Measured from your current GPS position. Dispatch can offer a pickup outside this area; the offer will show a warning.',
            ),
            Slider(
              value: _radius.clamp(1, 50),
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radius.round()} km',
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _radius = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delivery notifications'),
              subtitle: const Text(
                'Sound and alerts for offers and dispatch messages. Device notification permission is also required.',
              ),
              value: _notifications,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _notifications = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save driver settings'),
            ),
          ],
        ],
      ),
    );
  }
}
