import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/permissions_service.dart';

class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({super.key});

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  bool _loading = true;
  bool _permissionDenied = false;
  String? _error;
  List<MediaDeviceInfo> _devices = const <MediaDeviceInfo>[];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });

    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _devices = const <MediaDeviceInfo>[];
        });
        return;
      }

      final allDevices = await navigator.mediaDevices.enumerateDevices();
      final audioDevices = allDevices.where((device) {
        final kind = (device.kind ?? '').toLowerCase();
        return kind == 'audioinput' || kind == 'audiooutput';
      }).toList();

      if (!mounted) return;
      setState(() {
        _loading = false;
        _devices = audioDevices;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Bluetooth cihazlari alinamadi. Lutfen tekrar deneyin.';
      });
    }
  }

  Future<bool> _ensurePermissions() async {
    final bluetoothPermissions = Platform.isIOS
        ? <Permission>[Permission.bluetooth]
        : <Permission>[Permission.bluetoothConnect, Permission.bluetoothScan];

    final results = await <Permission>[
      Permission.microphone,
      ...bluetoothPermissions,
    ].request();

    final micGranted = _isGranted(results[Permission.microphone]);
    final btGranted = Platform.isIOS
        ? _isGranted(results[Permission.bluetooth])
        : _isGranted(results[Permission.bluetoothConnect]) &&
              _isGranted(results[Permission.bluetoothScan]);

    return micGranted && btGranted;
  }

  bool _isGranted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }

  bool _looksLikeBluetooth(MediaDeviceInfo device) {
    final haystack =
      '${device.label} ${device.deviceId} ${device.groupId}'.toLowerCase();
    return haystack.contains('bluetooth') ||
        haystack.contains('a2dp') ||
        haystack.contains('hfp') ||
        haystack.contains('airpods') ||
        haystack.contains('buds') ||
        haystack.contains('headset');
  }

  String _kindLabel(String kind) {
    final value = kind.toLowerCase();
    if (value == 'audioinput') return 'Mikrofon';
    if (value == 'audiooutput') return 'Cikis';
    return kind;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Cihazlari')),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_permissionDenied)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluetooth izni gerekli',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cihazlari listelemek icin mikrofon ve bluetooth izinlerini acin.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: PermissionsService.openSettings,
                        child: const Text('Uygulama Ayarlarini Ac'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              ),
            if (!_loading && !_permissionDenied && _error == null)
              ..._buildDeviceTiles(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDeviceTiles(ThemeData theme) {
    if (_devices.isEmpty) {
      return const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Ses cihazi bulunamadi. Bluetooth baglantinizi kontrol edin.'),
          ),
        ),
      ];
    }

    return _devices.map((device) {
      final rawLabel = device.label;
      final label = rawLabel.isEmpty ? 'Bilinmeyen Cihaz' : rawLabel;
      final isBt = _looksLikeBluetooth(device);

      return Card(
        child: ListTile(
          leading: Icon(
            isBt ? Icons.bluetooth_connected : Icons.hearing,
            color: isBt ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(label),
            subtitle: Text(_kindLabel(device.kind ?? 'unknown')),
          trailing: isBt
              ? const Chip(label: Text('Bluetooth'))
              : const Chip(label: Text('Audio Route')),
        ),
      );
    }).toList();
  }
}
