import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/dashboard_profile.dart';
import '../models/relay_config.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  static const _key = 'khanjan_app_settings'; // Legacy single-dashboard settings
  static const _dashboardsKey = 'khanjan_dashboards_v1';
  static const _activeKey = 'khanjan_active_dashboard_v1';

  Future<List<DashboardProfile>> loadDashboards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dashboardsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => DashboardProfile.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    // One-time migration: keep all existing settings as the first dashboard.
    AppSettings initial = AppSettings();
    final old = prefs.getString(_key);
    if (old != null) {
      try { initial = AppSettings.fromJson(jsonDecode(old) as Map<String, dynamic>); } catch (_) {}
    }
    final first = DashboardProfile(id: 'dashboard_default', name: 'داشبورد اصلی', settings: initial);
    await saveDashboards([first]);
    await prefs.setString(_activeKey, first.id);
    return [first];
  }

  Future<void> saveDashboards(List<DashboardProfile> dashboards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardsKey, jsonEncode(dashboards.map((d) => d.toJson()).toList()));
  }

  Future<String> activeDashboardId() async {
    final prefs = await SharedPreferences.getInstance();
    final dashboards = await loadDashboards();
    final id = prefs.getString(_activeKey);
    if (id != null && dashboards.any((d) => d.id == id)) return id;
    await prefs.setString(_activeKey, dashboards.first.id);
    return dashboards.first.id;
  }

  Future<void> setActiveDashboard(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
  }

  Future<AppSettings> loadForDashboard(String id) async {
    final dashboards = await loadDashboards();
    return dashboards.firstWhere((d) => d.id == id, orElse: () => dashboards.first).settings;
  }

  Future<AppSettings> load() async => loadForDashboard(await activeDashboardId());

  Future<void> saveForDashboard(String id, AppSettings settings) async {
    final dashboards = await loadDashboards();
    final index = dashboards.indexWhere((d) => d.id == id);
    if (index >= 0) {
      dashboards[index].settings = AppSettings.fromJson(settings.toJson());
      await saveDashboards(dashboards);
    }
    // Keep legacy key updated for compatibility with older versions.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> save(AppSettings settings) async => saveForDashboard(await activeDashboardId(), settings);

  Future<String> addDashboard(String name) async {
    final dashboards = await loadDashboards();
    final id = const Uuid().v4();

    // Every new dashboard starts with clean default settings instead of
    // inheriting the broker, topics, relays, or appearance of the current one.
    final freshSettings = AppSettings();

    // MQTT requires a distinct client ID for each simultaneously connected dashboard.
    freshSettings.clientId = 'khanjan_iot_app_${id.substring(0, 8)}';

    dashboards.add(DashboardProfile(
      id: id,
      name: name.trim().isEmpty ? 'داشبورد ${dashboards.length + 1}' : name.trim(),
      settings: freshSettings,
    ));
    await saveDashboards(dashboards);
    return id;
  }

  Future<void> renameDashboard(String id, String name) async {
    final dashboards = await loadDashboards();
    final i = dashboards.indexWhere((d) => d.id == id);
    if (i >= 0 && name.trim().isNotEmpty) {
      dashboards[i].name = name.trim();
      await saveDashboards(dashboards);
    }
  }

  Future<bool> deleteDashboard(String id) async {
    final dashboards = await loadDashboards();
    if (dashboards.length <= 1) return false;
    dashboards.removeWhere((d) => d.id == id);
    await saveDashboards(dashboards);
    final active = await activeDashboardId();
    if (active == id) await setActiveDashboard(dashboards.first.id);
    return true;
  }

  Future<void> updateRelays(List<RelayConfig> relays) async {
    final id = await activeDashboardId();
    final s = await loadForDashboard(id);
    s.relays = relays;
    await saveForDashboard(id, s);
  }
}
