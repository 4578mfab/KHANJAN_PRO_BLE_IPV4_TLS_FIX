import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../theme/app_themes.dart';
import 'dashboard_manager_screen.dart';
import 'device_setup_screen.dart';
import 'settings_device_screen.dart';
import 'settings_mqtt_screen.dart';

/// منوی اصلی تنظیمات — خلوت و کارتی
class SettingsScreen extends StatefulWidget {
  final AppSettings initialSettings;

  const SettingsScreen({super.key, required this.initialSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.fromJson(widget.initialSettings.toJson());
  }

  Future<void> _openMqtt() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsMqttScreen(initialSettings: _settings),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
    }
  }

  Future<void> _openDevice() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsDeviceScreen(initialSettings: _settings),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
    }
  }

  void _done() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات اعمال شد')),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context, _settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.resolve(
      _settings.buttonColorIndex,
      _settings.backgroundColorIndex,
      _settings.cardColorIndex,
      _settings.textColorIndex,
    );

    return Theme(
      data: AppThemes.buildTheme(theme),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('تنظیمات'),
          actions: [
            TextButton(
              onPressed: _done,
              child: Text(
                'تأیید',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _menuCard(
              theme: theme,
              icon: Icons.wifi_rounded,
              title: 'اتصال اینترنت به دستگاه',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceSetupScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _menuCard(
              theme: theme,
              icon: Icons.cloud_rounded,
              title: 'تنظیمات MQTT',
              onTap: _openMqtt,
            ),
            const SizedBox(height: 12),
            _menuCard(
              theme: theme,
              icon: Icons.auto_awesome,
              title: 'شناسه دستگاه و تولید خودکار تاپیک',
              onTap: _openDevice,
            ),
            const SizedBox(height: 12),
            _menuCard(
              theme: theme,
              icon: Icons.dashboard_customize_rounded,
              title: 'مدیریت داشبوردها',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DashboardManagerScreen(currentSettings: _settings),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _done,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('تأیید و بازگشت'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required dynamic theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: theme.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: theme.primary, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(Icons.chevron_left, color: theme.primary),
        onTap: onTap,
      ),
    );
  }
}
