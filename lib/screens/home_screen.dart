import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/relay_config.dart';
import '../services/mqtt_service.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';
import '../widgets/temperature_card.dart';
import '../widgets/relay_switch.dart';
import 'settings_screen.dart';
import 'appearance_screen.dart';

class HomeScreen extends StatefulWidget {
  final String dashboardId;
  final String dashboardName;
  const HomeScreen({super.key, required this.dashboardId, required this.dashboardName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _settingsService = SettingsService();
  final _mqtt = MqttService();

  AppSettings _settings = AppSettings();
  String _temperature = '';
  bool _connected = false;
  bool _espOnline = false;
  bool _loading = true;
  String? _error;

  StreamSubscription? _connSub;
  StreamSubscription? _tempSub;
  StreamSubscription? _relaySub;
  StreamSubscription? _espSub;
  Timer? _statusWatchdog;
  DateTime? _lastLiveStatusAt;
  DateTime? _lastTemperatureAt;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await _settingsService.loadForDashboard(widget.dashboardId);
    setState(() {
      _settings = s;
      _loading = false;
    });
    _listenMqtt();
    _statusWatchdog?.cancel();
    _statusWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      final last = _lastLiveStatusAt;
      if (last == null || DateTime.now().difference(last) > const Duration(seconds: 95)) {
        if (mounted && _espOnline) setState(() => _espOnline = false);
      }
      final tempAt = _lastTemperatureAt;
      if (tempAt == null || DateTime.now().difference(tempAt) > const Duration(seconds: 60)) {
        if (mounted && _temperature.isNotEmpty) setState(() => _temperature = '');
      }
    });
    await _connectMqtt();
  }

  void _listenMqtt() {
    _connSub = _mqtt.connectionStream.listen((c) {
      if (mounted) setState(() => _connected = c);
    });
    _tempSub = _mqtt.temperatureStream.listen((t) {
      _lastTemperatureAt = DateTime.now();
      if (mounted) setState(() => _temperature = t);
    });
    _relaySub = _mqtt.relayStateStream.listen((map) {
      if (!mounted) return;
      setState(() {
        for (final entry in map.entries) {
          final idx = _settings.relays.indexWhere((r) => r.id == entry.key);
          if (idx >= 0) {
            _settings.relays[idx] =
                _settings.relays[idx].copyWith(isOn: entry.value);
          }
        }
      });
    });
    _espSub = _mqtt.espStatusStream.listen((online) {
      _lastLiveStatusAt = DateTime.now();
      if (mounted) setState(() => _espOnline = online);
    });
  }

  Future<void> _connectMqtt() async {
    setState(() {
      _error = null;
      _espOnline = false;
      _lastLiveStatusAt = null;
      _lastTemperatureAt = null;
      _temperature = '';
    });
    try {
      await _mqtt.connect(_settings);
    } catch (e) {
      if (mounted) {
        // Show the underlying MQTT exception during diagnosis instead of
        // hiding all broker/network/rejection errors behind one generic text.
        setState(() => _error = 'اتصال برقرار نشد. جزئیات خطا: ${e.toString()}');
      }
    }
  }

  Future<void> _onToggle(RelayConfig relay, bool value) async {
    setState(() {
      final idx = _settings.relays.indexWhere((r) => r.id == relay.id);
      if (idx >= 0) {
        _settings.relays[idx] = relay.copyWith(isOn: value);
      }
    });
    await _mqtt.toggleRelay(relay, value);
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(initialSettings: _settings),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
      await _settingsService.saveForDashboard(widget.dashboardId, result);
      await _connectMqtt();
    }
  }

  Future<void> _openAppearance() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(builder: (_) => AppearanceScreen(initialSettings: _settings)),
    );
    if (result != null && mounted) {
      setState(() => _settings = result);
      await _settingsService.saveForDashboard(widget.dashboardId, result);
    } else if (mounted) {
      final latest = await _settingsService.load();
      setState(() => _settings = latest);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _tempSub?.cancel();
    _relaySub?.cancel();
    _espSub?.cancel();
    _statusWatchdog?.cancel();
    _mqtt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.resolve(_settings.buttonColorIndex, _settings.backgroundColorIndex, _settings.cardColorIndex, _settings.textColorIndex);
    final materialTheme = AppThemes.buildTheme(theme);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    return Theme(
      data: materialTheme,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('KHANJAN'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                _connected ? Icons.cloud_done : Icons.cloud_off,
                color: _connected ? theme.primary : Colors.redAccent,
                size: 22,
              ),
            ),
            IconButton(
              tooltip: 'تنظیمات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) _openSettings();
            if (index == 2) _openAppearance();
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'تنظیمات'),
            NavigationDestination(icon: Icon(Icons.palette_rounded), label: 'ظاهر'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _connectMqtt,
          color: theme.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ESP32 Online / Offline status card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _espOnline
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _espOnline ? Colors.green : Colors.redAccent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // آیکون وای‌فای — آفلاین با خط نازک
                    Icon(
                      _espOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: _espOnline ? Colors.green : Colors.redAccent,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    // نام دستگاه — جمع می‌شود تا با آنلاین تداخل نکند
                    Expanded(
                      child: Text(
                        widget.dashboardName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // وضعیت — عرض ثابت نسبی تا نام روی آن نیاید
                    Text(
                      _espOnline ? 'آنلاین' : 'آفلاین',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _espOnline
                            ? Colors.green.shade700
                            : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _espOnline ? Colors.green : Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_espOnline ? Colors.green : Colors.red)
                                .withOpacity(0.45),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              TemperatureCard(temperature: _temperature, theme: theme),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'کلیدهای کنترل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_settings.relays.length} دستگاه',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.text.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._settings.relays.map(
                (r) => RelaySwitchTile(
                  relay: r,
                  theme: theme,
                  buttonColor: AppThemes.buttonColors[_settings.buttonColorIndex.clamp(0, AppThemes.buttonColors.length - 1)],
                  enabled: _connected,
                  onChanged: (v) => _onToggle(r, v),
                ),
              ),
              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}
