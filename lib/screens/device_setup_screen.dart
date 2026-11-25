import 'dart:async';

import 'package:esp_provisioning_wifi/esp_provisioning_wifi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// راه‌اندازی Wi-Fi دستگاه KHANJAN از طریق BLE
///
/// جریان کار:
/// 1) جست‌وجوی دستگاه
/// 2) صفحه مستقل ورود رمز اختصاصی دستگاه (PoP)
/// 3) صفحه ورود دستی SSID و رمز Wi-Fi
/// 4) ارسال اطلاعات و نمایش خطای تفکیک‌شده
class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  static const String _devicePrefix = 'PROV_';
  static const int _maxScanAttempts = 3;

  final EspProvisioningService _provisioning = EspProvisioningService();

  List<String> _devices = [];
  bool _busy = false;
  String _status =
      'دستگاه را با نگه‌داشتن دکمه BOOT وارد حالت راه‌اندازی کنید.';
  String? _error;

  @override
  void dispose() {
    unawaited(_provisioning.cancelOperations());
    super.dispose();
  }

  bool _isRetryableScanError(String code) {
    return code == 'E_BLE_SCAN' ||
        code == 'E_BLE_SCAN_START' ||
        code == 'E_DEVICE_NOT_FOUND';
  }

  Future<void> _scanDevices() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
      _devices = [];
      _status = 'در حال جست‌وجوی دستگاه‌ها...';
    });

    List<String> foundDevices = [];

    try {
      for (int attempt = 1; attempt <= _maxScanAttempts; attempt++) {
        if (!mounted) return;

        setState(() {
          _status = attempt == 1
              ? 'در حال آماده‌سازی Bluetooth...'
              : 'جست‌وجوی دوباره دستگاه؛ تلاش $attempt از $_maxScanAttempts';
        });

        try {
          await _provisioning.cancelOperations();
        } catch (_) {}

        await Future.delayed(
          Duration(milliseconds: attempt == 1 ? 600 : 1200 * attempt),
        );

        if (!mounted) return;

        try {
          // نتیجه کامل همان نوبت اسکن نگه داشته می‌شود؛ اگر چند برد
          // هم‌زمان در حالت Provisioning باشند، همه در فهرست می‌مانند.
          final scanResults =
              await _provisioning.scanBleDevices(_devicePrefix);
          foundDevices = scanResults.toSet().toList()..sort();

          if (foundDevices.isNotEmpty) break;
        } on PlatformException catch (e) {
          if (!_isRetryableScanError(e.code) ||
              attempt == _maxScanAttempts) {
            rethrow;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _devices = foundDevices;
        _status = foundDevices.isEmpty
            ? 'دستگاهی پیدا نشد. دستگاه را با دکمه BOOT وارد حالت راه‌اندازی کنید.'
            : foundDevices.length == 1
                ? 'یک دستگاه پیدا شد. برای ادامه آن را انتخاب کنید.'
                : '${foundDevices.length} دستگاه هم‌زمان پیدا شد. هر دستگاه را جداگانه انتخاب و تنظیم کنید.';
      });
    } on PlatformException catch (e) {
      _showError(_scanErrorMessage(e));
    } catch (e) {
      _showError('جست‌وجوی دستگاه ناموفق بود. دوباره تلاش کنید.');
      debugPrint('KHANJAN BLE scan error: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _scanErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'E_PERMISSION':
        return 'مجوز Bluetooth صادر نشده است. مجوزهای برنامه را بررسی کنید.';
      case 'E_DEVICE_NOT_FOUND':
        return 'دستگاهی پیدا نشد. دستگاه را با دکمه BOOT وارد حالت راه‌اندازی کنید.';
      case 'E_BLE_SCAN':
      case 'E_BLE_SCAN_START':
        return 'جست‌وجوی Bluetooth ناموفق بود. Bluetooth گوشی را خاموش و روشن کنید.';
      case 'E_CANCELLED':
        return 'جست‌وجو لغو شد. دوباره تلاش کنید.';
      default:
        return 'جست‌وجوی دستگاه ناموفق بود. دوباره تلاش کنید.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _status = message;
    });
  }

  Future<void> _resetSearch() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _devices = [];
      _error = null;
      _status = 'در حال پاک‌سازی وضعیت اتصال...';
    });

    try {
      await _provisioning.cancelOperations();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _busy = false;
      _status =
          'وضعیت پاک شد. دستگاه را با BOOT وارد حالت راه‌اندازی کنید و دوباره جست‌وجو کنید.';
    });
  }

  Future<void> _openDevice(String deviceName) async {
    if (_busy) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DevicePasswordScreen(
          deviceName: deviceName,
          provisioning: _provisioning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('راه‌اندازی دستگاه KHANJAN'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'راهنمای اتصال',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('۱) دکمه BOOT دستگاه را حدود ۳ ثانیه نگه دارید.'),
                  Text('۲) جست‌وجوی دستگاه KHANJAN را انتخاب کنید.'),
                  Text('۳) دستگاه پیدا‌شده را انتخاب کنید.'),
                  SizedBox(height: 6),
                  Text(
                    'در این روش، نام و رمز Wi-Fi را دستی وارد می‌کنید و شبکه‌ها اسکن نمی‌شوند.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _scanDevices,
              icon: const Icon(Icons.bluetooth_searching_rounded),
              label: const Text('جست‌وجوی دستگاه KHANJAN'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _resetSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('شروع مجدد جست‌وجو'),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'دستگاه‌های پیدا‌شده (${_devices.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._devices.map(
              (device) => Card(
                child: ListTile(
                  leading: const Icon(Icons.memory_rounded),
                  title: Text(
                    device,
                    textDirection: TextDirection.ltr,
                  ),
                  subtitle: const Text('تنظیمات این دستگاه جداگانه انجام می‌شود'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _busy ? null : () => _openDevice(device),
                ),
              ),
            ),
          ],
          if (_devices.length > 1) ...[
            const SizedBox(height: 8),
            const Text(
              'می‌توانید دستگاه‌ها را یکی‌یکی تنظیم کنید؛ انتخاب یک دستگاه، فهرست سایر دستگاه‌های پیدا‌شده را پاک نمی‌کند.',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          _StatusPanel(
            message: _status,
            isError: _error != null,
            colorScheme: colors,
          ),
        ],
      ),
    );
  }
}

/// صفحه مستقل ورود رمز اختصاصی دستگاه
class _DevicePasswordScreen extends StatefulWidget {
  const _DevicePasswordScreen({
    required this.deviceName,
    required this.provisioning,
  });

  final String deviceName;
  final EspProvisioningService provisioning;

  @override
  State<_DevicePasswordScreen> createState() =>
      _DevicePasswordScreenState();
}

class _DevicePasswordScreenState extends State<_DevicePasswordScreen> {
  final TextEditingController _proofController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  void _continue() {
    final proof = _proofController.text;

    if (proof.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز اختصاصی دستگاه را وارد کنید.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WifiCredentialsScreen(
          deviceName: widget.deviceName,
          proofOfPossession: proof,
          provisioning: widget.provisioning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('احراز هویت دستگاه')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Icon(
            Icons.bluetooth_connected_rounded,
            size: 54,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          const Text(
            'دستگاه پیدا شد',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('نام دستگاه'),
                  const SizedBox(height: 6),
                  Text(
                    widget.deviceName,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'رمز اختصاصی دستگاه را وارد کنید',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _proofController,
            obscureText: _hidePassword,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'رمز دستگاه',
              hintText: 'رمز روی برچسب یا راهنمای دستگاه',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
                icon: Icon(
                  _hidePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'رمز هنگام برقراری ارتباط امن با دستگاه بررسی می‌شود.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('ادامه و ورود اطلاعات Wi-Fi'),
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحه ورود دستی نام و رمز Wi-Fi و اجرای Provisioning
class _WifiCredentialsScreen extends StatefulWidget {
  const _WifiCredentialsScreen({
    required this.deviceName,
    required this.proofOfPossession,
    required this.provisioning,
  });

  final String deviceName;
  final String proofOfPossession;
  final EspProvisioningService provisioning;

  @override
  State<_WifiCredentialsScreen> createState() =>
      _WifiCredentialsScreenState();
}

class _WifiCredentialsScreenState extends State<_WifiCredentialsScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _wifiPasswordController =
      TextEditingController();

  bool _busy = false;
  bool _completed = false;
  bool _hideWifiPassword = true;
  String _status = 'نام و رمز شبکه Wi-Fi را وارد کنید.';
  String? _error;

  @override
  void dispose() {
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  String _friendlyError(PlatformException e) {
    switch (e.code) {
      case 'E_PERMISSION':
        return 'مجوز Bluetooth صادر نشده است. مجوزهای برنامه را بررسی کنید.';

      case 'E_PROV_SESSION':
        return 'رمز اختصاصی دستگاه اشتباه است.';

      case 'E_PROV_AUTH':
        return 'رمز Wi-Fi اشتباه است. رمز شبکه را بررسی کنید.';

      case 'E_PROV_NETWORK_NOT_FOUND':
        return 'شبکه Wi-Fi پیدا نشد. نام شبکه و فعال بودن Wi-Fi باند ۲٫۴ گیگاهرتز را بررسی کنید.';

      case 'E_PROV_CONFIG':
        return 'ارسال تنظیمات Wi-Fi به دستگاه ناموفق بود. دوباره تلاش کنید.';

      case 'E_PROV_FAILED':
        return 'راه‌اندازی Wi-Fi ناموفق بود. نام شبکه و رمز آن را بررسی کنید.';

      case 'E_DEVICE_NOT_FOUND':
        return 'دستگاه پیدا نشد. آن را دوباره وارد حالت راه‌اندازی کنید.';

      case 'E_CONNECT_TIMEOUT':
        return 'اتصال Bluetooth به دستگاه در زمان مقرر برقرار نشد. گوشی را نزدیک دستگاه نگه دارید.';

      case 'E_CONNECT':
        return 'ارتباط Bluetooth با دستگاه قطع شد. دوباره دستگاه را انتخاب کنید.';

      case 'E_CANCELLED':
        return 'عملیات لغو شد. دوباره تلاش کنید.';

      case 'E_TIMEOUT':
        return 'زمان راه‌اندازی به پایان رسید. دوباره تلاش کنید.';

      case 'E_INVALID_RESPONSE':
        return 'پاسخ دستگاه قابل خواندن نبود. دوباره تلاش کنید.';

      case 'E_DEVICE':
        return 'دستگاه در دسترس نیست. آن را دوباره راه‌اندازی کنید.';

      default:
        debugPrint(
          'KHANJAN provisioning error: '
          '${e.code} | ${e.message} | ${e.details}',
        );
        return 'راه‌اندازی دستگاه ناموفق بود. دوباره تلاش کنید.';
    }
  }

  Future<void> _sendCredentials() async {
    if (_busy) return;

    // SSID را trim نمی‌کنیم؛ فاصله بخشی از نام شبکه می‌تواند باشد.
    final ssid = _ssidController.text;

    if (ssid.isEmpty) {
      _showError('نام شبکه Wi-Fi را وارد کنید.');
      return;
    }

    setState(() {
      _busy = true;
      _completed = false;
      _error = null;
      _status = 'در حال اتصال امن و ارسال اطلاعات Wi-Fi...';
    });

    try {
      final success = await widget.provisioning.provisionWifi(
        widget.deviceName,
        widget.proofOfPossession,
        ssid,
        _wifiPasswordController.text,
        // این زمان مربوط به مرحله برقراری BLE است، نه زمان اتصال مودم.
        connectTimeout: const Duration(seconds: 25),
      );

      if (!mounted) return;

      setState(() {
        _completed = success;
        _error = success ? null : 'راه‌اندازی توسط دستگاه تأیید نشد.';
        _status = success
            ? 'اطلاعات Wi-Fi با موفقیت به دستگاه تحویل شد. آنلاین شدن دستگاه را در داشبورد بررسی کنید.'
            : 'نتیجه راه‌اندازی موفق نبود. نام شبکه و رمز آن را بررسی کنید.';
      });
    } on PlatformException catch (e) {
      _showError(_friendlyError(e));
    } catch (e) {
      debugPrint('KHANJAN provisioning unexpected error: $e');
      _showError('ارسال اطلاعات ناموفق بود. دوباره تلاش کنید.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _completed = false;
      _status = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیم Wi-Fi دستگاه')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory_rounded),
              title: const Text('دستگاه انتخاب‌شده'),
              subtitle: Text(
                widget.deviceName,
                textDirection: TextDirection.ltr,
              ),
              trailing: const Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ورود دستی اطلاعات Wi-Fi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ssidController,
            enabled: !_busy,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'نام شبکه Wi-Fi (SSID)',
              hintText: 'نام دقیق شبکه ۲٫۴ گیگاهرتز',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.wifi_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wifiPasswordController,
            enabled: !_busy,
            obscureText: _hideWifiPassword,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'رمز شبکه Wi-Fi',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _hideWifiPassword = !_hideWifiPassword;
                        });
                      },
                icon: Icon(
                  _hideWifiPassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'شبکه دستگاه باید از باند ۲٫۴ گیگاهرتز پشتیبانی کند. نام شبکه به‌صورت دستی ارسال می‌شود.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _sendCredentials,
              icon: const Icon(Icons.send_rounded),
              label: const Text('ارسال اطلاعات و راه‌اندازی دستگاه'),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 18),
          _StatusPanel(
            message: _status,
            isError: _error != null,
            isSuccess: _completed,
            colorScheme: colors,
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.message,
    required this.isError,
    required this.colorScheme,
    this.isSuccess = false,
  });

  final String message;
  final bool isError;
  final bool isSuccess;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final Color background = isError
        ? colorScheme.errorContainer.withOpacity(0.55)
        : isSuccess
            ? Colors.green.withOpacity(0.12)
            : colorScheme.surfaceContainerHighest;

    final Color foreground = isError
        ? colorScheme.error
        : isSuccess
            ? Colors.green
            : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
