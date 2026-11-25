#!/usr/bin/env python3
"""Apply KHANJAN's IPv4-first, hostname-verified TLS transport to mqtt_client 10.2.0."""

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
  // Connect TCP to an IPv4 address, then perform TLS using the original
  // hostname. SecureSocket.secure(host: server) preserves SNI and performs
  // normal certificate-chain and hostname validation.
  Future<SecureSocket> _connectIpv4Tls(String server, int port) async {
    final parsedAddress = InternetAddress.tryParse(server);
    final triedAddresses = <InternetAddress>[];
    Object? lastSocketError;

    if (parsedAddress != null) {
      triedAddresses.add(parsedAddress);
    } else {
      try {
        triedAddresses.addAll(
          await InternetAddress.lookup(
            server,
            type: InternetAddressType.IPv4,
          ).timeout(const Duration(seconds: 8)),
        );
      } catch (error) {
        lastSocketError = error;
      }
    }

    Future<SecureSocket?> tryAddresses(List<InternetAddress> addresses) async {
      for (final address in addresses) {
        Socket rawSocket;
        try {
          rawSocket = await Socket.connect(
            address,
            port,
            timeout: const Duration(seconds: 12),
          );
        } catch (error) {
          lastSocketError = error;
          continue;
        }

        try {
          // Do not replace server with the IP here. It is the TLS hostname.
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

    final systemDnsSocket = await tryAddresses(triedAddresses);
    if (systemDnsSocket != null) return systemDnsSocket;

    // If system DNS failed or its address could not be reached, query the
    // current DuckDNS A record over HTTPS using resolver IPs directly. This
    // avoids depending on the phone's DNS just to find the DoH resolver.
    if (parsedAddress == null) {
      final dohAddresses = await _resolveIpv4WithDoh(server);
      final additionalAddresses = dohAddresses
          .where((address) => !triedAddresses.any(
                (oldAddress) => oldAddress.address == address.address,
              ))
          .toList();
      final dohSocket = await tryAddresses(additionalAddresses);
      if (dohSocket != null) return dohSocket;
    }

    if (lastSocketError != null) throw lastSocketError!;
    throw SocketException('Unable to resolve or connect to an IPv4 address for $server');
  }

  Future<List<InternetAddress>> _resolveIpv4WithDoh(String domain) async {
    const resolvers = <Map<String, String>>[
      {
        'ip': '1.1.1.1',
        'host': 'cloudflare-dns.com',
        'path': '/dns-query',
      },
      {
        'ip': '8.8.8.8',
        'host': 'dns.google',
        'path': '/resolve',
      },
    ];

    for (final resolver in resolvers) {
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..findProxy = (uri) => 'DIRECT';

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
              const Duration(seconds: 10),
            );
        request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
        final response = await request.close().timeout(
              const Duration(seconds: 10),
            );
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          continue;
        }

        final body = await response.transform(utf8.decoder).join().timeout(
              const Duration(seconds: 8),
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
          if (address != null && address.type == InternetAddressType.IPv4) {
            result.add(address);
          }
        }
        if (result.isNotEmpty) return result;
      } catch (_) {
        // Try the next independent DNS-over-HTTPS resolver.
      } finally {
        httpClient.close(force: true);
      }
    }
    return <InternetAddress>[];
  }

'''


def package_root() -> Path:
    if not CONFIG.exists():
        raise SystemExit("ERROR: .dart_tool/package_config.json not found; run flutter pub get first.")
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
            "ERROR: expected exactly two standard TLS connect blocks in mqtt_client 10.2.0; "
            f"found {count}. No source changes were made."
        )

    content = content.replace(
        old,
        "      _connectIpv4Tls(server, port).then((socket) {",
    )
    insertion_point = "  /// Sends the message in the stream to the broker."
    if content.count(insertion_point) != 1:
        raise SystemExit("ERROR: could not locate secure connection helper insertion point.")
    content = content.replace(insertion_point, HELPER + insertion_point, 1)
    source.write_text(content, encoding="utf-8")
    print(f"Patched mqtt_client at: {source}")
    print("Both initial TLS connect and automatic reconnect now use IPv4 + verified hostname TLS.")


if __name__ == "__main__":
    main()
