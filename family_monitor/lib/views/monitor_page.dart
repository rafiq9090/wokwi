import 'package:flutter/material.dart';

import '../services/device_repository.dart';
import '../viewmodels/monitor_view_model.dart';
import '../widgets/event_tile.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_hero.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  late final MonitorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    const deviceUrl = String.fromEnvironment('ESP32_URL');
    _viewModel = MonitorViewModel(
      repository: deviceUrl.isEmpty
          ? null
          : Esp32DeviceRepository(baseUrl: deviceUrl),
    )
      ..addListener(_refresh)
      ..startPolling();
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _acknowledgeAlert() {
    _viewModel.acknowledgeAlert();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert acknowledged by caregiver')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _viewModel.state;
    final alarm = state.hasAlarm;
    final liveMode = _viewModel.isConnected;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Care Circle', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Family safety monitor', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            StatusHero(
              alarm: alarm,
              online: liveMode && state.deviceOnline,
              personName: state.personName,
              onAcknowledge: alarm ? _acknowledgeAlert : null,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.person_outline,
                    label: 'Person',
                    value: state.personName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    icon: Icons.battery_5_bar,
                    label: 'Battery',
                    value: '${state.batteryPercent}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.speed_rounded,
                    label: 'Impact',
                    value: '${state.impactG.toStringAsFixed(1)} G',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    icon: Icons.update_rounded,
                    label: 'Updated',
                    value: _viewModel.timeAgo(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                TextButton(onPressed: () {}, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 4),
            EventTile(
              icon: alarm ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: alarm ? const Color(0xFFB43B32) : const Color(0xFF0D6B67),
              title: alarm ? 'Fall alert active' : 'Device is operating normally',
              detail: alarm ? 'Immediate attention may be required' : 'No alerts detected',
              time: _viewModel.timeAgo(),
            ),
            EventTile(
              icon: liveMode ? Icons.wifi_rounded : Icons.science_outlined,
              color: liveMode ? const Color(0xFF5B7180) : const Color(0xFFB07B2C),
              title: liveMode ? 'Live device connection' : 'Demo data only',
              detail: liveMode
                  ? 'ESP32 status is polled every 2 seconds'
                  : 'Launch with ESP32_URL to read the sensor',
              time: liveMode ? _viewModel.timeAgo() : 'Not connected',
            ),
            if (!liveMode) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: _viewModel.simulateFall,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Simulate fall alert'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6B67),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFF0D6B67)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              liveMode
                  ? 'Live ESP32 data'
                  : 'Demo mode: run with --dart-define=ESP32_URL=http://127.0.0.1:8180',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66747B),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
