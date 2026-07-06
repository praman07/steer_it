import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steering_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Theme/Unit Options
  String _selectedTheme = 'Minimal Monochrome';
  String _selectedUnits = 'Degrees';
  String _sensorPreference = 'High Frequency Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF1E1E1E),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<SteeringProvider>(
          builder: (context, p, _) {
            final config = p.config;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildHeader('STEERING ENGINE PARAMETERS'),
                const SizedBox(height: 16),
                _buildCard([
                  _buildSliderTile(
                    title: 'Steering Lock Limit',
                    subtitle: 'Max degree range of absolute wheel travel.',
                    value: config.steeringLock,
                    min: 180.0,
                    max: 1080.0,
                    divisions: 10,
                    displayValue: '${config.steeringLock.toInt()}°',
                    onChanged: (v) {
                      p.updateConfig(config.copyWith(steeringLock: v));
                    },
                  ),
                  _buildDivider(),
                  _buildSliderTile(
                    title: 'Sensitivity Scale',
                    subtitle: 'Multiplier for physical rotation speed.',
                    value: config.sensitivity,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    displayValue: '${config.sensitivity.toStringAsFixed(2)}x',
                    onChanged: (v) {
                      p.updateConfig(config.copyWith(sensitivity: v));
                    },
                  ),
                  _buildDivider(),
                  _buildSliderTile(
                    title: 'Deadzone Boundary',
                    subtitle: 'Filters micro-vibrations around dead center.',
                    value: config.deadzone,
                    min: 0.0,
                    max: 5.0,
                    divisions: 50,
                    displayValue: '${config.deadzone.toStringAsFixed(2)}°/s',
                    onChanged: (v) {
                      p.updateConfig(config.copyWith(deadzone: v));
                    },
                  ),
                ]),
                const SizedBox(height: 32),

                _buildHeader('SIGNAL FILTERS'),
                const SizedBox(height: 16),
                _buildCard([
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text(
                      'LPF Signal Smoothing',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Applies a low-pass filter to output angles.',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                    value: config.useSmoothing,
                    activeThumbColor: const Color(0xFFFFFFFF),
                    activeTrackColor: const Color(0xFF333333),
                    inactiveThumbColor: const Color(0xFF888888),
                    inactiveTrackColor: const Color(0xFF111111),
                    onChanged: (v) {
                      p.updateConfig(config.copyWith(useSmoothing: v));
                    },
                  ),
                  if (config.useSmoothing) ...[
                    _buildDivider(),
                    _buildSliderTile(
                      title: 'Smoothing Filter Coefficient',
                      subtitle: 'Lower values equal more smoothing and latency.',
                      value: config.smoothingAlpha,
                      min: 0.05,
                      max: 0.95,
                      divisions: 18,
                      displayValue: config.smoothingAlpha.toStringAsFixed(2),
                      onChanged: (v) {
                        p.updateConfig(config.copyWith(smoothingAlpha: v));
                      },
                    ),
                  ],
                  _buildDivider(),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text(
                      'Yaw Drift Compensation',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Blends geomagnetic orientation reference.',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                    value: config.useDriftCompensation,
                    activeThumbColor: const Color(0xFFFFFFFF),
                    activeTrackColor: const Color(0xFF333333),
                    inactiveThumbColor: const Color(0xFF888888),
                    inactiveTrackColor: const Color(0xFF111111),
                    onChanged: (v) {
                      p.updateConfig(config.copyWith(useDriftCompensation: v));
                    },
                  ),
                ]),
                const SizedBox(height: 32),

                _buildHeader('SYSTEM PREFERENCES'),
                const SizedBox(height: 16),
                _buildCard([
                  _buildDropdownRow(
                    title: 'Visual Theme',
                    value: _selectedTheme,
                    items: ['Minimal Monochrome', 'Stealth Black'],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTheme = v);
                    },
                  ),
                  _buildDivider(),
                  _buildDropdownRow(
                    title: 'Rotational Units',
                    value: _selectedUnits,
                    items: ['Degrees', 'Radians'],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnits = v);
                    },
                  ),
                  _buildDivider(),
                  _buildDropdownRow(
                    title: 'Sensor Preference',
                    value: _sensorPreference,
                    items: ['High Frequency Auto', 'IMU Raw Only', 'Orientation Fusion'],
                    onChanged: (v) {
                      if (v != null) setState(() => _sensorPreference = v);
                    },
                  ),
                ]),
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () => p.resetAll(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4444),
                    ),
                    child: const Text(
                      'RESET ALL SETTINGS & CALIBRATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF888888),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFF1E1E1E),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                displayValue,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFFFFFF),
              inactiveTrackColor: const Color(0xFF1E1E1E),
              thumbColor: const Color(0xFFFFFFFF),
              overlayColor: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF0A0A0A),
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, fontWeight: FontWeight.bold),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
