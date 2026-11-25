import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../theme/app_themes.dart';
import '../utils/topic_builder.dart';
import 'settings_topics_screen.dart';

/// شناسه دستگاه + تولید خودکار تاپیک
class SettingsDeviceScreen extends StatefulWidget {
  final AppSettings initialSettings;
  const SettingsDeviceScreen({super.key, required this.initialSettings});

  @override
  State<SettingsDeviceScreen> createState() => _SettingsDeviceScreenState();
}

class _SettingsDeviceScreenState extends State<SettingsDeviceScreen> {
  late AppSettings _settings;
  final _deviceIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.fromJson(widget.initialSettings.toJson());
    final st = _settings.espStatusTopic;
    if (st.endsWith('/status')) {
      _deviceIdCtrl.text = st.substring(0, st.length - '/status'.length);
    }
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  void _applyDeviceId({bool openTopics = true}) {
    final id = _deviceIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شناسه دستگاه را وارد کنید')),
      );
      return;
    }
    setState(() {
      _settings.relays = TopicBuilder.buildRelays(id, count: 6);
      _settings.espStatusTopic = TopicBuilder.statusTopic(id);
      _settings.temperatureTopic = TopicBuilder.temperatureTopic(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تاپیک‌ها برای «$id» ساخته شد')),
    );
    if (openTopics) {
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        final result = await Navigator.push<AppSettings>(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsTopicsScreen(initialSettings: _settings),
          ),
        );
        if (result != null && mounted) {
          setState(() => _settings = result);
        }
      });
    }
  }

  Future<void> _openTopics() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsTopicsScreen(initialSettings: _settings),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
    }
  }

  void _saveAndClose() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ذخیره شد')),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
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
          title: const Text('شناسه دستگاه'),
          actions: [
            TextButton(
              onPressed: _saveAndClose,
              child: Text('ذخیره',
                  style: TextStyle(
                      color: theme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _deviceIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'شناسه دستگاه',
                      border: OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _applyDeviceId(openTopics: true),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('تولید خودکار تاپیک‌ها'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.card,
              child: ListTile(
                leading: Icon(Icons.tune_rounded, color: theme.primary),
                title: Text('دما، وضعیت و کلیدها',
                    style: TextStyle(
                        color: theme.text, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_left, color: theme.primary),
                onTap: _openTopics,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveAndClose,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
