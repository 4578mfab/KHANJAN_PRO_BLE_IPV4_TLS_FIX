import '../models/relay_config.dart';

/// الگوی تاپیک هم‌خوان با فریمور KHANJAN روی ESP32
///
/// DEVICE_ID = RZA643250BB →
///   RZA643250BB/led/cmd … led6/cmd
///   RZA643250BB/led/state … led6/state
///   RZA643250BB/status
///   RZA643250BB/temperature
class TopicBuilder {
  static String normalizeId(String raw) {
    return raw.trim();
  }

  static String commandTopic(String deviceId, int index) {
    final id = normalizeId(deviceId);
    if (index <= 0) return '$id/led/cmd';
    return '$id/led${index + 1}/cmd';
  }

  static String stateTopic(String deviceId, int index) {
    final id = normalizeId(deviceId);
    if (index <= 0) return '$id/led/state';
    return '$id/led${index + 1}/state';
  }

  static String statusTopic(String deviceId) =>
      '${normalizeId(deviceId)}/status';

  static String temperatureTopic(String deviceId) =>
      '${normalizeId(deviceId)}/temperature';

  /// شش رله با نام و تاپیک استاندارد KHANJAN
  static List<RelayConfig> buildRelays(String deviceId, {int count = 6}) {
    final id = normalizeId(deviceId);
    return List.generate(count, (i) {
      final n = i + 1;
      return RelayConfig(
        id: 'relay_$n',
        name: 'کلید $n',
        commandTopic: commandTopic(id, i),
        stateTopic: stateTopic(id, i),
        onPayload: 'ON',
        offPayload: 'OFF',
      );
    });
  }
}
