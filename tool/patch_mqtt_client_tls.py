#!/usr/bin/env python3
# KHANJAN private-broker-only IPv4/DoH TLS transport patch for mqtt_client 10.2.0.

import json
from pathlib import Path
from urllib.parse import unquote, urlparse

PROJECT = Path(__file__).resolve().parents[1]
CONFIG = PROJECT / ".dart_tool" / "package_config.json"
MARKER = "KHANJAN_IPV4_TLS_TRANSPORT"
RELATIVE_SOURCE = Path(
    "lib/src/connectionhandling/server/"
    "mqtt_client_mqtt_server_secure_connection.dart"
)

HELPER = r'''  // KHANJAN_IPV4_TLS_TRANSPORT
  // Apply the special transport ONLY to the private KHANJAN DuckDNS broker.
  // All public/custom TLS brokers retain mqtt_client's original behavior.
  Future<SecureSocket> _connectIpv4Tls(String server, int port) async {
    final normalizedServer =
        server.toLowerCase().replaceFirst(RegExp(r'\.$'), '');

    if (normalizedServer != 'khanjanhome.duckdns.org') {
      return SecureSocket.connect(
        server,
        port,
        onBadCertificate: onBadCertificate,
        context: context,
      );
    }

    final systemAddresses = <InternetAddress>[];
    Object? lastSocketError;

    bool isPublicIpv4(InternetAddress address) {
      if (address.type != InternetAddressType.IPv4) return false;
      final b = address.rawAddress;
      if (b.length != 4) return false;

      final a = b[0];
      final second = b[1];
      final third = b[2];

      // Reject unspecified, private, loopback, link-local, CGNAT,
      // documentation, benchmarking, multicast and reserved ranges.
      if (a == 0 || a == 10 || a == 127 || a >= 224) return false;
      if (a == 100 && second >= 64 && second <= 127) return false;
      if (a == 169 && second == 254) return false;
      if (a == 172 && second >= 16 && second <= 31) return false;
      if (a == 192 && second == 168) return false;
      if (a == 192 && second == 0) return false;
      if (a == 192 && second == 88 && third == 99) return false;
      if (a == 198 && (second == 18 || second == 19)) return false;
      if (a == 198 && second == 51 && third == 100) return false;
      if (a == 203 && second == 0 && third == 113) return false;
      if (a == 255 && second == 255 && third == 255) return false;
      return true;
    }

    try {
      final answers = await InternetAddress.lookup(
        server,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(seconds: 8));
      systemAddresses.addAll(answers.where(isPublicIpv4));
    } catch (error) {
      lastSocketError = error;
    }

    Future<SecureSocket?> tryAddresses(
      List<InternetAddress> addresses,
    ) async {
      for (final address in addresses) {
        Socket rawSocket;
        try {
          rawSocket = await Socket.connect(
            address,
            port,
            timeout: const Duration(seconds: 10),
          );
        } catch (error) {
          lastSocketError = error;
          continue;
        }

        try {
          // Keep the hostname for TLS SNI and normal certificate validation.
          // Never disable onBadCertificate or replace this host with the IP.
          return await SecureSocket.secure(
            rawSocket,
            host: server,
            context: context,
            onBadCertificate: onBadCertificate,
          );
        } catch (_) {
          rawSocket.destroy();
          rethrow;
        }
      }
      return null;
    }

    final systemSocket = await tryAddresses(systemAddresses);
    if (systemSocket != null) return systemSocket;

    // Ignore private/reserved DNS answers such as 10.10.34.36.
    // Resolve the current DuckDNS A record through HTTPS DNS resolvers.
    final dohAddresses = await _resolveIpv4WithDoh(server);
    final additionalAddresses = dohAddresses
        .where(
          (address) =>
              isPublicIpv4(address) &&
              !systemAddresses.any(
                (oldAddress) => oldAddress.address == address.address,
              ),
        )
        .toList();

    final dohSocket = await tryAddresses(additionalAddresses);
    if (dohSocket != null) return dohSocket;

    if (lastSocketError != null) throw lastSocketError!;
    throw SocketException(
      'No reachable public IPv4 address was found for $server. '
      'System DNS private answers were rejected and secure DNS fallback '
      'did not produce a working connection.',
    );
  }

  Future<List<InternetAddress>> _resolveIpv4WithDoh(String domain) async {
    const resolvers = <Map<String, String>>[
      {
        'ip': '1.1.1.1',
        'host': 'cloudflare-dns.com',
        'path': '/dns-query',
      },
      {
        'ip': '1.0.0.1',
        'host': 'cloudflare-dns.com',
        'path': '/dns-query',
      },
      {
        'ip': '8.8.8.8',
        'host': 'dns.google',
        'path': '/resolve',
      },
      {
        'ip': '8.8.4.4',
        'host': 'dns.google',
        'path': '/resolve',
      },
      {
        'ip': '9.9.9.9',
        'host': 'dns.quad9.net',
        'path': '/dns-query',
      },
    ];

    for (final resolver in resolvers) {
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 7)
        ..findProxy = (uri) => 'DIRECT';

      // Connect to resolver IP directly, but keep its hostname for HTTPS TLS.
      httpClient.connectionFactory = (uri, proxyHost, proxyPort) {
        if (proxyHost != null || proxyPort != null) {
          throw SocketException('Unexpected proxy while resolving MQTT host');
        }
        return Socket.startConnect(
          InternetAddress(resolver['ip']!),
          443,
        );
      };

      try {
        final uri = Uri.https(
          resolver['host']!,
          resolver['path']!,
          {'name': domain, 'type': 'A'},
        );
        final request = await httpClient.getUrl(uri).timeout(
          const Duration(seconds: 8),
        );
        request.headers.set(
          HttpHeaders.acceptHeader,
          'application/dns-json',
        );

        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          continue;
        }

        final body = await response.transform(utf8.decoder).join().timeout(
          const Duration(seconds: 7),
        );
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;

        final answers = decoded['Answer'];
        if (answers is! List) continue;

        final result = <InternetAddress>[];
        for (final answer in answers) {
          if (answer is! Map || answer['type'] != 1) continue;
          final value = answer['data'];
          if (value is! String) continue;

          final address = InternetAddress.tryParse(value);
          if (address != null &&
              address.type == InternetAddressType.IPv4) {
            result.add(address);
          }
        }

        if (result.isNotEmpty) return result;
      } catch (_) {
        // Try the next independent HTTPS DNS resolver.
      } finally {
        httpClient.close(force: true);
      }
    }

    return <InternetAddress>[];
  }

'''


def package_root() -> Path:
    if not CONFIG.exists():
        raise SystemExit(
            "ERROR: .dart_tool/package_config.json not found; "
            "run flutter pub get first."
        )

    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    for package in config.get("packages", []):
        if package.get("name") == "mqtt_client":
            root_uri = package["rootUri"]
            parsed = urlparse(root_uri)
            if parsed.scheme == "file":
                return Path(unquote(parsed.path))
            return (CONFIG.parent / unquote(root_uri)).resolve()

    raise SystemExit("ERROR: mqtt_client was not found in package_config.json")


def main() -> None:
    root = package_root()
    source = root / RELATIVE_SOURCE
    if not source.exists():
        raise SystemExit(f"ERROR: unsupported mqtt_client source layout: {source}")

    content = source.read_text(encoding="utf-8")
    if MARKER in content:
        print("KHANJAN TLS transport patch already applied.")
        return

    old = (
        "      SecureSocket.connect(server, port,\n"
        "              onBadCertificate: onBadCertificate, context: context)\n"
        "          .then((socket) {"
    )
    count = content.count(old)
    if count != 2:
        raise SystemExit(
            "ERROR: expected exactly two standard TLS connect blocks in "
            f"mqtt_client 10.2.0; found {count}. No source changes were made."
        )

    content = content.replace(
        old,
        "      _connectIpv4Tls(server, port).then((socket) {",
    )

    insertion_point = "  /// Sends the message in the stream to the broker."
    if content.count(insertion_point) != 1:
        raise SystemExit(
            "ERROR: could not locate secure connection helper insertion point."
        )

    content = content.replace(insertion_point, HELPER + insertion_point, 1)
    source.write_text(content, encoding="utf-8")
    print(f"Patched mqtt_client at: {source}")
    print(
        "Private KHANJAN broker: IPv4 + HTTPS DNS fallback + verified TLS. "
        "Public/custom TLS brokers: original connection behavior."
    )


if __name__ == "__main__":
    main()
