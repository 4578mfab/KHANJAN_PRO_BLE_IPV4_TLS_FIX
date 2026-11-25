import 'app_settings.dart';

class DashboardProfile {
  final String id;
  String name;
  AppSettings settings;

  DashboardProfile({required this.id, required this.name, required this.settings});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'settings': settings.toJson(),
      };

  factory DashboardProfile.fromJson(Map<String, dynamic> json) => DashboardProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'داشبورد',
        settings: AppSettings.fromJson(
          (json['settings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        ),
      );
}
