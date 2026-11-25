import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../theme/app_themes.dart';

class AppearanceScreen extends StatefulWidget {
  final AppSettings initialSettings;
  const AppearanceScreen({super.key, required this.initialSettings});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    settings = AppSettings.fromJson(widget.initialSettings.toJson());
  }

  Future<void> _save() async {
    await SettingsService().save(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره شد')),
      );
      Navigator.pop(context, settings);
    }
  }

  Widget _colorSlider({
    required String title,
    required List<Color> colors,
    required int selected,
    required ValueChanged<int> onChanged,
    required AppThemeData theme,
  }) {
    final max = (colors.length - 1).clamp(0, 99);
    final index = selected.clamp(0, max);
    final c = colors[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(c, Colors.white, 0.25)!,
                      c,
                      Color.lerp(c, Colors.black, 0.15)!,
                    ],
                  ),
                  border: Border.all(
                    color: theme.text.withOpacity(0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.primary,
              inactiveTrackColor: theme.text.withOpacity(0.15),
              thumbColor: theme.primary,
              overlayColor: theme.primary.withOpacity(0.12),
              trackHeight: 4,
            ),
            child: Slider(
              min: 0,
              max: max.toDouble(),
              divisions: max,
              value: index.toDouble(),
              onChanged: (v) => onChanged(v.round().clamp(0, max)),
            ),
          ),
          SizedBox(
            height: 10,
            child: Row(
              children: List.generate(colors.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.horizontal(
                        left: i == 0 ? const Radius.circular(4) : Radius.zero,
                        right: i == colors.length - 1
                            ? const Radius.circular(4)
                            : Radius.zero,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.resolve(
      settings.buttonColorIndex,
      settings.backgroundColorIndex,
      settings.cardColorIndex,
      settings.textColorIndex,
    );

    return Theme(
      data: AppThemes.buildTheme(theme),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('رنگ‌ها'),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(
                'ذخیره',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _colorSlider(
              title: 'رنگ دکمه‌ها و کلیدها',
              colors: AppThemes.buttonColors,
              selected: settings.buttonColorIndex,
              onChanged: (i) =>
                  setState(() => settings.buttonColorIndex = i),
              theme: theme,
            ),
            _colorSlider(
              title: 'رنگ زمینه صفحه',
              colors: AppThemes.backgroundColors,
              selected: settings.backgroundColorIndex,
              onChanged: (i) =>
                  setState(() => settings.backgroundColorIndex = i),
              theme: theme,
            ),
            _colorSlider(
              title: 'رنگ کارت‌ها',
              colors: AppThemes.cardColors,
              selected: settings.cardColorIndex,
              onChanged: (i) => setState(() => settings.cardColorIndex = i),
              theme: theme,
            ),
            _colorSlider(
              title: 'رنگ نوشته‌ها',
              colors: AppThemes.textColors,
              selected: settings.textColorIndex,
              onChanged: (i) => setState(() => settings.textColorIndex = i),
              theme: theme,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
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
