import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/dashboard_profile.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';

class DashboardManagerScreen extends StatefulWidget {
  final AppSettings currentSettings;
  const DashboardManagerScreen({super.key, required this.currentSettings});
  @override
  State<DashboardManagerScreen> createState() => _DashboardManagerScreenState();
}

class _DashboardManagerScreenState extends State<DashboardManagerScreen> {
  final _service = SettingsService();
  List<DashboardProfile> _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final items = await _service.loadDashboards();
    if (mounted) setState(() { _items = items; _loading = false; });
  }
  Future<void> _add() async {
    final ctrl = TextEditingController(text: 'داشبورد ${_items.length + 1}');
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('افزودن داشبورد'),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'نام داشبورد', hintText: 'مثلاً خانه باغ')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('ایجاد'))],
    ));
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _service.addDashboard(name);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('داشبورد اضافه شد؛ تنظیمات MQTT آن را جداگانه بررسی کنید.')));
  }
  Future<void> _rename(DashboardProfile d) async {
    final ctrl = TextEditingController(text: d.name);
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تغییر نام داشبورد'), content: TextField(controller: ctrl, autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('ذخیره'))],
    ));
    ctrl.dispose();
    if (name != null && name.trim().isNotEmpty) { await _service.renameDashboard(d.id, name); await _load(); }
  }
  Future<void> _delete(DashboardProfile d) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('حذف داشبورد؟'), content: Text('«${d.name}» حذف شود؟ تنظیمات ذخیره‌شده آن نیز حذف می‌شود.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))],
    ));
    if (ok == true) {
      final deleted = await _service.deleteDashboard(d.id);
      await _load();
      if (!deleted && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک داشبورد باید باقی بماند.')));
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.resolve(widget.currentSettings.buttonColorIndex, widget.currentSettings.backgroundColorIndex, widget.currentSettings.cardColorIndex, widget.currentSettings.textColorIndex);
    return Theme(data: AppThemes.buildTheme(theme), child: Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('مدیریت داشبوردها')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('افزودن داشبورد')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const SizedBox(height: 8),
          ..._items.map((d) => Card(color: theme.card, child: ListTile(
            leading: Icon(Icons.dashboard_customize_rounded, color: theme.primary),
            title: Text(d.name, style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
            trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'rename') _rename(d); if (v == 'delete') _delete(d); }, itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('تغییر نام')), PopupMenuItem(value: 'delete', child: Text('حذف'))]),
          ))),
        ],
      ),
    ));
  }
}
