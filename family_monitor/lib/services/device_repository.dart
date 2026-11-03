import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/monitor_state.dart';

abstract interface class DeviceRepository {
  Future<MonitorState> fetchState();
}

class Esp32DeviceRepository implements DeviceRepository {
  Esp32DeviceRepository({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<MonitorState> fetchState() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/status'))
        .timeout(const Duration(seconds: 3));

    if (response.statusCode != 200) {
      throw Exception('ESP32 returned HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final state = json['state'] as String?;
    return MonitorState(
      status: state == 'alarm' ? MonitorStatus.alarm : MonitorStatus.normal,
      deviceOnline: true,
      personName: 'Mum',
      batteryPercent: 82,
      impactG: (json['accelerationG'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.now(),
    );
  }
}
