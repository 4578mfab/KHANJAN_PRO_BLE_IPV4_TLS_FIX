import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/relay_config.dart';
import '../theme/app_themes.dart';

/// صفحه دما، وضعیت ESP و لیست کلیدها
class SettingsTopicsScreen extends StatefulWidget {
  final AppSettings initialSettings;
  const SettingsTopicsScreen({super.key, required this.initialSettings});

  @override
  State<SettingsTopicsScreen> createState() => _SettingsTopicsScreenState();
}

class _SettingsTopicsScreenState extends State<SettingsTopicsScreen> {
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _tempTopicCtrl = TextEditingController();
  final _espStatusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.fromJson(widget.initialSettings.toJson());
    _tempTopicCtrl.text = _settings.temperatureTopic;
    _espStatusCtrl.text = _settings.espStatusTopic;
  }

  @override
  void dispose() {
    _tempTopicCtrl.dispose();
    _espStatusCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _settings.temperatureTopic = _tempTopicCtrl.text.trim();
    _settings.espStatusTopic = _espStatusCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ذخیره شد')),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context, _settings);
    });
  }

  void _addRelay() {
    setState(() {
      final n = _settings.relays.length + 1;
      _settings.relays.add(RelayConfig(
        id: const Uuid().v4(),
        name: 'کلید $n',
        commandTopic: 'home/relay$n/set',
        stateTopic: 'home/relay$n/state',
      ));
    });
  }

  void _deleteRelay(int index) {
    setState(() => _settings.relays.removeAt(index));
  }

  void _editRelay(int index) {
    final r = _settings.relays[index];
    final nameCtrl = TextEditingController(text: r.name);
    final cmdCtrl = TextEditingController(text: r.commandTopic);
    final stateCtrl = TextEditingController(text: r.stateTopic);
    final onCtrl = TextEditingController(text: r.onPayload);
    final offCtrl = TextEditingController(text: r.offPayload);
    int selectedIcon = r.iconCodePoint;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ویرایش کلید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(builder: (dialogContext, setDialogState) {
                  const icons = <IconData>[
                    Icons.lightbulb_rounded,
                    Icons.air_rounded,
                    Icons.lock_rounded,
                    Icons.power_settings_new_rounded,
                    Icons.ac_unit_rounded,
                    Icons.water_drop_rounded,
                    Icons.tv_rounded,
                    Icons.speaker_rounded,
                    Icons.electrical_services_rounded,
                    Icons.local_fire_department_rounded,
                    Icons.wifi_rounded,
                    Icons.coffee_rounded,
                    Icons.security_rounded,
                    Icons.bolt_rounded,
                  ];
                  final colors = Theme.of(dialogContext).colorScheme;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('آیکون کلید'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons
                            .map((item) => InkWell(
                                  onTap: () => setDialogState(
                                      () => selectedIcon = item.codePoint),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: selectedIcon == item.codePoint
                                          ? colors.primary.withOpacity(.18)
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedIcon == item.codePoint
                                            ? colors.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(item, size: 21),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'نام وسیله'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cmdCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Topic فرمان (Set)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stateCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Topic وضعیت (State)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: onCtrl,
                  decoration:
                      const InputDecoration(labelText: 'پیام روشن (ON)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: offCtrl,
                  decoration:
                      const InputDecoration(labelText: 'پیام خاموش (OFF)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('لغو')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _settings.relays[index] = r.copyWith(
                    name: nameCtrl.text.trim(),
                    commandTopic: cmdCtrl.text.trim(),
                    stateTopic: stateCtrl.text.trim(),
                    onPayload: onCtrl.text.trim(),
                    offPayload: offCtrl.text.trim(),
                    iconCodePoint: selectedIcon,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
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
          title: const Text('دما، وضعیت و کلیدها'),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('ذخیره',
                  style: TextStyle(
                      color: theme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
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
                    TextFormField(
                      controller: _tempTopicCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Topic دما'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _espStatusCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Topic وضعیت ESP32'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('کلیدها',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: theme.text)),
                  const Spacer(),
                  IconButton(
                    onPressed: _addRelay,
                    icon: Icon(Icons.add_circle, color: theme.primary),
                  ),
                ],
              ),
              ...List.generate(_settings.relays.length, (i) {
                final r = _settings.relays[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    title: Text(r.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: theme.text)),
                    subtitle: Text(r.commandTopic,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.text.withOpacity(0.6))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: theme.primary, size: 20),
                          onPressed: () => _editRelay(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteRelay(i),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('ذخیره'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
