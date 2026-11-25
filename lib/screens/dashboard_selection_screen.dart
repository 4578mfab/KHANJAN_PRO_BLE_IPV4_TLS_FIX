import 'package:flutter/material.dart';
import '../models/dashboard_profile.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';
import 'home_screen.dart';

class DashboardSelectionScreen extends StatefulWidget {
  const DashboardSelectionScreen({super.key});
  @override
  State<DashboardSelectionScreen> createState() => _DashboardSelectionScreenState();
}

class _DashboardSelectionScreenState extends State<DashboardSelectionScreen> {
  final _service = SettingsService();
  List<DashboardProfile> _dashboards = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await _service.loadDashboards();
    if (mounted) setState(() { _dashboards = list; _loading = false; });
  }

  Future<void> _open(DashboardProfile dashboard) async {
    await _service.setActiveDashboard(dashboard.id);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HomeScreen(dashboardId: dashboard.id, dashboardName: dashboard.name),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.themes[0];
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('انتخاب داشبورد')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('دستگاه موردنظر را انتخاب کنید', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.text)),
          const SizedBox(height: 16),
          ..._dashboards.map((d) => Card(
            color: theme.card,
            child: ListTile(
              leading: CircleAvatar(backgroundColor: theme.primary.withOpacity(.15), child: Icon(Icons.dashboard_rounded, color: theme.primary)),
              title: Text(d.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.text)),
              trailing: Icon(Icons.chevron_left, color: theme.primary),
              onTap: () => _open(d),
            ),
          )),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('به‌روزرسانی فهرست')),
        ],
      ),
    );
  }
}
