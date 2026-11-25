import 'relay_config.dart';

class AppSettings {
  String broker;
  int port;
  String clientId;
  String username;
  String password;
  String temperatureTopic;
  String espStatusTopic;
  bool useWebSocket;
  String brokerPreset;
  String connectionMode; // tcp, tls, ws, wss
  int themeIndex;
  int buttonColorIndex;
  int backgroundColorIndex;
  int cardColorIndex;
  int textColorIndex;
  List<RelayConfig> relays;

  AppSettings({
    this.broker = 'broker.hivemq.com',
    this.port = 1883,
    this.clientId = 'khanjan_iot_app',
    this.username = '',
    this.password = '',
    this.temperatureTopic = 'home/temperature',
    this.espStatusTopic = 'home/esp32/status',
    this.useWebSocket = false,
    this.brokerPreset = 'hivemq',
    this.connectionMode = 'tcp',
    this.themeIndex = 0,
    this.buttonColorIndex = 0,
    this.backgroundColorIndex = 0,
    this.cardColorIndex = 0,
    this.textColorIndex = 0,
    List<RelayConfig>? relays,
  }) : relays = relays ?? _defaultRelays();

  static List<RelayConfig> _defaultRelays() {
    return List.generate(5, (i) {
      final n = i + 1;
      return RelayConfig(
        id: 'relay_$n',
        name: 'کلید $n',
        commandTopic: 'home/relay$n/set',
        stateTopic: 'home/relay$n/state',
      );
    });
  }

  Map<String, dynamic> toJson() => {
        'broker': broker,
        'port': port,
        'clientId': clientId,
        'username': username,
        'password': password,
        'temperatureTopic': temperatureTopic,
        'espStatusTopic': espStatusTopic,
        'useWebSocket': useWebSocket,
        'brokerPreset': brokerPreset,
        'connectionMode': connectionMode,
        'themeIndex': themeIndex,
        'buttonColorIndex': buttonColorIndex,
        'backgroundColorIndex': backgroundColorIndex,
        'cardColorIndex': cardColorIndex,
        'textColorIndex': textColorIndex,
        'relays': relays.map((r) => r.toJson()).toList(),
      };

  static String _inferBrokerPreset(String broker) {
    switch (broker.trim().toLowerCase()) {
      case 'broker.hivemq.com': return 'hivemq';
      case 'broker.emqx.io': return 'emqx';
      case 'test.mosquitto.org': return 'mosquitto';
      default: return 'custom';
    }
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final list = (json['relays'] as List<dynamic>?)
            ?.map((e) => RelayConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        AppSettings._defaultRelays();
    return AppSettings(
      broker: json['broker'] as String? ?? 'broker.hivemq.com',
      port: json['port'] as int? ?? 1883,
      clientId: json['clientId'] as String? ?? 'khanjan_iot_app',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      temperatureTopic: json['temperatureTopic'] as String? ?? 'home/temperature',
      espStatusTopic: json['espStatusTopic'] as String? ?? 'home/esp32/status',
      useWebSocket: json['useWebSocket'] as bool? ?? false,
      brokerPreset: json['brokerPreset'] as String? ??
          _inferBrokerPreset(json['broker'] as String? ?? 'broker.hivemq.com'),
      connectionMode: json['connectionMode'] as String? ??
          ((json['useWebSocket'] as bool? ?? false) ? 'ws' : 'tcp'),
      themeIndex: json['themeIndex'] as int? ?? 0,
      buttonColorIndex: (json['buttonColorIndex'] as int? ?? 0).clamp(0, 13),
      backgroundColorIndex: (json['backgroundColorIndex'] as int? ?? 0).clamp(0, 13),
      cardColorIndex: (json['cardColorIndex'] as int? ?? 0).clamp(0, 13),
      textColorIndex: (json['textColorIndex'] as int? ?? 0).clamp(0, 13),
      relays: list,
    );
  }
}
