import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../theme/app_themes.dart';

class SettingsMqttScreen extends StatefulWidget {
  final AppSettings initialSettings;
  const SettingsMqttScreen({super.key, required this.initialSettings});

  @override
  State<SettingsMqttScreen> createState() => _SettingsMqttScreenState();
}

class _SettingsMqttScreenState extends State<SettingsMqttScreen> {
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();
  final _brokerCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  static const Map<String, Map<String, dynamic>> _brokerPresets = {
    'hivemq': {
      'label': 'HiveMQ',
      'host': 'broker.hivemq.com',
      'ports': {'tcp': 1883, 'tls': 8883, 'ws': 8000, 'wss': 8884}
    },
    'emqx': {
      'label': 'EMQX',
      'host': 'broker.emqx.io',
      'ports': {'tcp': 1883, 'tls': 8883, 'ws': 8083, 'wss': 8084}
    },
    'mosquitto': {
      'label': 'Mosquitto',
      'host': 'test.mosquitto.org',
      'ports': {'tcp': 1883, 'tls': 8883, 'ws': 8080, 'wss': 8081}
    },
    'custom': {
      'label': 'Custom (بروکر دلخواه)',
      'host': '',
      'ports': {'tcp': 1883, 'tls': 8883, 'ws': 8083, 'wss': 8084}
    },
  };

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.fromJson(widget.initialSettings.toJson());
    _brokerCtrl.text = _settings.broker;
    _portCtrl.text = _settings.port.toString();
    _clientIdCtrl.text = _settings.clientId;
    _userCtrl.text = _settings.username;
    _passCtrl.text = _settings.password;
  }

  @override
  void dispose() {
    _brokerCtrl.dispose();
    _portCtrl.dispose();
    _clientIdCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _selectBrokerPreset(String? value) {
    if (value == null) return;
    setState(() {
      _settings.brokerPreset = value;
      if (value != 'custom') {
        final preset = _brokerPresets[value]!;
        _brokerCtrl.text = preset['host'] as String;
        final ports = preset['ports'] as Map<String, int>;
        _portCtrl.text = ports[_settings.connectionMode]!.toString();
      }
    });
  }

  void _selectConnectionMode(String? value) {
    if (value == null) return;
    setState(() {
      _settings.connectionMode = value;
      _settings.useWebSocket = value == 'ws' || value == 'wss';
      final ports =
          _brokerPresets[_settings.brokerPreset]?['ports'] as Map<String, int>?;
      if (ports != null) _portCtrl.text = ports[value]!.toString();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _settings.broker = _brokerCtrl.text.trim();
    _settings.useWebSocket =
        _settings.connectionMode == 'ws' || _settings.connectionMode == 'wss';
    _settings.port = int.tryParse(_portCtrl.text.trim()) ?? 1883;
    _settings.clientId = _clientIdCtrl.text.trim();
    _settings.username = _userCtrl.text.trim();
    _settings.password = _passCtrl.text;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات MQTT ذخیره شد')),
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
          title: const Text('تنظیمات MQTT'),
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
                    DropdownButtonFormField<String>(
                      value: _brokerPresets.containsKey(_settings.brokerPreset)
                          ? _settings.brokerPreset
                          : 'custom',
                      decoration:
                          const InputDecoration(labelText: 'انتخاب بروکر'),
                      items: _brokerPresets.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value['label'] as String)))
                          .toList(),
                      onChanged: _selectBrokerPreset,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['tcp', 'tls', 'ws', 'wss']
                              .contains(_settings.connectionMode)
                          ? _settings.connectionMode
                          : 'tcp',
                      decoration: const InputDecoration(labelText: 'نوع اتصال'),
                      items: const [
                        DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                        DropdownMenuItem(
                            value: 'tls', child: Text('TLS (TCP امن)')),
                        DropdownMenuItem(
                            value: 'ws', child: Text('WebSocket (WS)')),
                        DropdownMenuItem(
                            value: 'wss', child: Text('WebSocket امن (WSS)')),
                      ],
                      onChanged: _selectConnectionMode,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brokerCtrl,
                      decoration:
                          const InputDecoration(labelText: 'آدرس Broker'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'الزامی' : null,
                      onChanged: (_) {
                        if (_settings.brokerPreset != 'custom') {
                          setState(() => _settings.brokerPreset = 'custom');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'پورت'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return n == null || n < 1 || n > 65535
                            ? 'پورت معتبر وارد کنید'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientIdCtrl,
                      decoration: const InputDecoration(labelText: 'Client ID'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                          labelText: 'نام کاربری (اختیاری)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'رمز عبور (اختیاری)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
