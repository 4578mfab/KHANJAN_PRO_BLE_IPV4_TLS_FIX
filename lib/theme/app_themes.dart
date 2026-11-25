import 'package:flutter/material.dart';

class AppThemeData {
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color text;
  final Color accent;

  const AppThemeData({
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.text,
    required this.accent,
  });
}

class AppThemes {
  /// ۱۴ رنگ براق برای دکمه‌ها / تأکید
  static const List<Color> buttonColors = [
    Color(0xFF00E5A8), // emerald
    Color(0xFF00D4FF), // cyan
    Color(0xFF4FC3F7), // sky
    Color(0xFF7C4DFF), // violet
    Color(0xFFFF4081), // pink
    Color(0xFFFF6E40), // coral
    Color(0xFFFFD54F), // amber
    Color(0xFF69F0AE), // mint soft
    Color(0xFF18FFFF), // aqua soft
    Color(0xFFB388FF), // lavender soft
    Color(0xFFFF8A80), // soft red
    Color(0xFFFFAB40), // soft orange
    Color(0xFFFFFFFF), // white
    Color(0xFF37474F), // blue grey
  ];

  /// ۱۴ رنگ زمینه (تیره و روشن)
  static const List<Color> backgroundColors = [
    Color(0xFF0B1220), // deep navy
    Color(0xFF121826), // charcoal
    Color(0xFF0F172A), // slate
    Color(0xFF1A1030), // purple night
    Color(0xFF071A17), // forest night
    Color(0xFF061B2C), // ocean night
    Color(0xFF1B0910), // wine night
    Color(0xFF15171C), // graphite
    Color(0xFFE2E8F0), // cool light (کمی تیره‌تر)
    Color(0xFFE8EEF5), // soft light (کمی تیره‌تر)
    Color(0xFFE3F5EE), // mint light (کمی تیره‌تر)
    Color(0xFFE4EEF9), // ice light (کمی تیره‌تر)
    Color(0xFFF5E9EE), // rose light (کمی تیره‌تر)
    Color(0xFFF2F3F5), // near white (کمی تیره‌تر از سفید خالص)
  ];

  /// ۱۴ رنگ کارت
  static const List<Color> cardColors = [
    Color(0xFF162033), // glass navy
    Color(0xFF1C2740), // elevated dark
    Color(0xFF221A3A), // purple card
    Color(0xFF102B25), // emerald card
    Color(0xFF0C2B42), // ocean card
    Color(0xFF30101D), // ruby card
    Color(0xFFF05A9D), // صورتی مرجانی
    Color(0xFFB05CE2), // ارغوانی
    Color(0xFF8058D6), // بنفش سلطنتی
    Color(0xFF477DE8), // آبی الکتریکی
    Color(0xFF39A9DB), // آبی آسمانی
    Color(0xFF24BDB5), // فیروزه‌ای
    Color(0xFF27AD78), // سبز زمردی
    Color(0xFF82B943), // سبز لیمویی
  ];

  /// ۱۴ رنگ نوشته
  static const List<Color> textColors = [
    Color(0xFFF4F7FF), // near white
    Color(0xFFE8EEF8), // soft white
    Color(0xFFCFD8DC), // blue grey light
    Color(0xFFB0BEC5), // muted
    Color(0xFF90A4AE), // soft grey
    Color(0xFF78909C), // medium grey
    Color(0xFF546E7A), // darker grey
    Color(0xFF37474F), // slate text
    Color(0xFF1A237E), // deep indigo
    Color(0xFF0D47A1), // deep blue
    Color(0xFF1B5E20), // deep green
    Color(0xFF4A148C), // deep purple
    Color(0xFF3E2723), // brown
    Color(0xFF0F172A), // near black
  ];

  // سازگاری با کد قدیمی که themes می‌خواست
  static final List<AppThemeData> themes = List.generate(
    buttonColors.length,
    (i) => resolve(i, 0, 0, 0),
  );

  static int _clamp(int i, int len) {
    if (len <= 0) return 0;
    if (i < 0) return 0;
    return i.clamp(0, len - 1);
  }

  static Color buttonOf(int i) => buttonColors[_clamp(i, buttonColors.length)];
  static Color backgroundOf(int i) =>
      backgroundColors[_clamp(i, backgroundColors.length)];
  static Color cardOf(int i) => cardColors[_clamp(i, cardColors.length)];
  static Color textOf(int i) => textColors[_clamp(i, textColors.length)];

  /// هر چهار رنگ کاملاً مستقل‌اند
  static AppThemeData resolve(
    int buttonIndex,
    int backgroundIndex,
    int cardIndex,
    int textIndex,
  ) {
    final primary = buttonOf(buttonIndex);
    final background = backgroundOf(backgroundIndex);
    final card = cardOf(cardIndex);
    final text = textOf(textIndex);
    return AppThemeData(
      name: 'custom',
      subtitle: '',
      primary: primary,
      secondary: primary,
      background: background,
      card: card,
      text: text,
      accent: primary.withOpacity(
        background.computeLuminance() < 0.35 ? 0.16 : 0.10,
      ),
    );
  }

  static ThemeData buildTheme(AppThemeData t) {
    final dark = t.background.computeLuminance() < 0.35;
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      primaryColor: t.primary,
      scaffoldBackgroundColor: t.background,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: t.primary,
        onPrimary: Colors.white,
        secondary: t.secondary,
        onSecondary: Colors.white,
        surface: t.card,
        onSurface: t.text,
        error: const Color(0xFFFF5252),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: t.text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardTheme(
        color: t.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.card,
        indicatorColor: t.primary.withOpacity(0.18),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: t.text, fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.selected)) return t.primary;
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.selected)) {
            return t.primary.withOpacity(0.45);
          }
          return Colors.grey.withOpacity(0.35);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
