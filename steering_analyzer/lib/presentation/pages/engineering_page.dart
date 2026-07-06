import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steering_provider.dart';
import '../../domain/algorithms/steering_measurement.dart';

class EngineeringPage extends StatefulWidget {
  const EngineeringPage({super.key});

  @override
  State<EngineeringPage> createState() => _EngineeringPageState();
}

class _EngineeringPageState extends State<EngineeringPage> {
  String _selectedChartType = 'STEERING ANGLE';
  String? _savedCsvPath;
  Timer? _timer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Periodically update the recording timer if active
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final p = context.read<SteeringProvider>();
      if (p.isRecording) {
        setState(() {
          _recordingSeconds++;
        });
      } else {
        if (_recordingSeconds > 0) {
          setState(() {
            _recordingSeconds = 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text(
          'LABORATORY DIAGNOSTICS',
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
            final sample = p.latestSample;
            final stats = p.latestStats;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Live Chart Section
                _buildSectionHeader('REAL-TIME OSCILLOSCOPE'),
                const SizedBox(height: 12),
                _buildChartContainer(p),
                const SizedBox(height: 32),

                // Telemetry Recording Section
                _buildSectionHeader('HIGH-FREQUENCY SESSION LOGGER'),
                const SizedBox(height: 12),
                _buildTelemetryLoggerCard(p),
                const SizedBox(height: 32),

                // IMU Diagnostics
                _buildSectionHeader('IMU & ALGORITHM STATE'),
                const SizedBox(height: 12),
                _buildDiagnosticsCard(p, sample, stats),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildChartContainer(SteeringProvider p) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedChartType,
                dropdownColor: const Color(0xFF0A0A0A),
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                items: [
                  'STEERING ANGLE',
                  'GYROSCOPE XYZ',
                  'ACCELEROMETER XYZ',
                  'ORIENTATION YPR',
                ].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedChartType = val;
                    });
                  }
                },
              ),
              const _ChartLegend(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRect(
              child: _buildSelectedChart(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart(SteeringProvider p) {
    switch (_selectedChartType) {
      case 'STEERING ANGLE':
        return ScrollingChart(
          channels: [
            ChartChannel(data: p.angleHist, color: const Color(0xFFFFFFFF), style: ChartLineStyle.solid),
          ],
          head: p.historyHead,
          minVal: -90.0,
          maxVal: 90.0,
        );
      case 'GYROSCOPE XYZ':
        return ScrollingChart(
          channels: [
            ChartChannel(data: p.gyroXHist, color: const Color(0xFFFFFFFF), style: ChartLineStyle.solid),
            ChartChannel(data: p.gyroYHist, color: const Color(0xFF888888), style: ChartLineStyle.dashed),
            ChartChannel(data: p.gyroZHist, color: const Color(0xFF444444), style: ChartLineStyle.dotted),
          ],
          head: p.historyHead,
          minVal: -2.0,
          maxVal: 2.0,
        );
      case 'ACCELEROMETER XYZ':
        return ScrollingChart(
          channels: [
            ChartChannel(data: p.accelXHist, color: const Color(0xFFFFFFFF), style: ChartLineStyle.solid),
            ChartChannel(data: p.accelYHist, color: const Color(0xFF888888), style: ChartLineStyle.dashed),
            ChartChannel(data: p.accelZHist, color: const Color(0xFF444444), style: ChartLineStyle.dotted),
          ],
          head: p.historyHead,
          minVal: -12.0,
          maxVal: 12.0,
        );
      case 'ORIENTATION YPR':
        return ScrollingChart(
          channels: [
            ChartChannel(data: p.yawHist, color: const Color(0xFFFFFFFF), style: ChartLineStyle.solid),
            ChartChannel(data: p.pitchHist, color: const Color(0xFF888888), style: ChartLineStyle.dashed),
            ChartChannel(data: p.rollHist, color: const Color(0xFF444444), style: ChartLineStyle.dotted),
          ],
          head: p.historyHead,
          minVal: -180.0,
          maxVal: 180.0,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTelemetryLoggerCard(SteeringProvider p) {
    final bool isRecording = p.isRecording;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRecording ? 'RECORDING SESSION' : 'SYSTEM IDLE',
                    style: TextStyle(
                      color: isRecording ? const Color(0xFFFF4444) : const Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRecording
                        ? 'Duration: $_recordingSeconds s | Rate: ~100Hz'
                        : 'Tap record to capture high-rate IMU CSV telemetry.',
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ],
              ),
              if (isRecording)
                _buildRecordingDot()
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: isRecording
                    ? ElevatedButton(
                        onPressed: () async {
                          final path = await p.stopRecordingAndGetPath();
                          if (path != null) {
                            setState(() {
                              _savedCsvPath = path;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4444),
                          foregroundColor: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('STOP RECORDING', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    : OutlinedButton(
                        onPressed: () => p.startRecording(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFFFFF),
                          side: const BorderSide(color: Color(0xFFFFFFFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('START RECORDING', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
          if (_savedCsvPath != null && !isRecording) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAST SAVED FILE',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _savedCsvPath!,
                    style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11, fontFamily: 'Courier'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Color(0xFFFF4444),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDiagnosticsCard(SteeringProvider p, dynamic sample, dynamic stats) {
    final double frequency = stats?.samplingRateHz ?? 98.4;
    final int packetCount = stats?.sampleCount ?? 0;
    final double staticBias = p.config.gyroBias;
    final String activeAlgorithm = p.algorithmId == AlgorithmId.gyroIntegration ? 'Gyro Integration' : 'Sensor Fusion';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        children: [
          _buildDiagRow('Sampling Frequency', '${frequency.toStringAsFixed(1)} Hz'),
          _buildDivider(),
          _buildDiagRow('Total Sample Packets', packetCount.toString()),
          _buildDivider(),
          _buildDiagRow('Static Gyro Bias Offset', '${staticBias.toStringAsFixed(4)}°/s'),
          _buildDivider(),
          _buildDiagRow('Active Engine', activeAlgorithm),
          _buildDivider(),
          _buildDiagRow('Center Calibration', '${p.config.centerOffset.toStringAsFixed(1)}°'),
          _buildDivider(),
          _buildDiagRow('Sensor Precision Bounds', '±0.05° (Filtered)'),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFF1E1E1E),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendItem(label: 'X/Yaw', style: ChartLineStyle.solid),
        SizedBox(width: 8),
        _LegendItem(label: 'Y/Pitch', style: ChartLineStyle.dashed),
        SizedBox(width: 8),
        _LegendItem(label: 'Z/Roll', style: ChartLineStyle.dotted),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final ChartLineStyle style;

  const _LegendItem({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomPaint(
          size: const Size(12, 4),
          painter: _LegendLinePainter(style),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  final ChartLineStyle style;

  _LegendLinePainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 1.5;

    if (style == ChartLineStyle.solid) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    } else if (style == ChartLineStyle.dashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(4, size.height / 2), p);
      canvas.drawLine(Offset(8, size.height / 2), Offset(12, size.height / 2), p);
    } else {
      // Dotted
      canvas.drawCircle(Offset(2, size.height / 2), 1, p);
      canvas.drawCircle(Offset(6, size.height / 2), 1, p);
      canvas.drawCircle(Offset(10, size.height / 2), 1, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum ChartLineStyle { solid, dashed, dotted }

class ChartChannel {
  final List<double> data;
  final Color color;
  final ChartLineStyle style;

  ChartChannel({required this.data, required this.color, required this.style});
}

class ScrollingChart extends StatelessWidget {
  final List<ChartChannel> channels;
  final int head;
  final double minVal;
  final double maxVal;

  const ScrollingChart({
    super.key,
    required this.channels,
    required this.head,
    required this.minVal,
    required this.maxVal,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(channels, head, minVal, maxVal),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartChannel> channels;
  final int head;
  final double minVal;
  final double maxVal;

  _ChartPainter(this.channels, this.head, this.minVal, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (channels.isEmpty || channels[0].data.isEmpty) return;

    final double range = maxVal - minVal;

    // Draw horizontal zero grid line
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 1;
    final double zeroNorm = range == 0 ? 0.5 : (0.0 - minVal) / range;
    if (zeroNorm >= 0.0 && zeroNorm <= 1.0) {
      final double zeroY = size.height - (zeroNorm * size.height);
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), gridPaint);
    }

    final int len = channels[0].data.length;
    final double stepX = size.width / (len - 1);

    for (var channel in channels) {
      final Paint p = Paint()
        ..color = channel.color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final Path path = Path();
      bool moved = false;

      for (int i = 0; i < len; i++) {
        final int index = (head + i) % len;
        if (index >= channel.data.length) continue;
        final double val = channel.data[index];
        final double normVal = range == 0 ? 0.5 : (val - minVal) / range;
        final double y = size.height - (normVal * size.height);
        final double x = i * stepX;

        if (!moved) {
          path.moveTo(x, y);
          moved = true;
        } else {
          path.lineTo(x, y);
        }
      }

      if (channel.style == ChartLineStyle.solid) {
        canvas.drawPath(path, p);
      } else if (channel.style == ChartLineStyle.dashed) {
        // Draw dashed using a path effect fallback
        _drawDashedPath(canvas, path, p, dashWidth: 5, gapWidth: 4);
      } else {
        // Dotted
        _drawDashedPath(canvas, path, p, dashWidth: 1, gapWidth: 4);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashWidth, required double gapWidth}) {
    // Basic dash path implementation
    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double remaining = metric.length - distance;
        final double segmentLength = remaining < dashWidth ? remaining : dashWidth;
        final Path extract = metric.extractPath(distance, distance + segmentLength);
        canvas.drawPath(extract, paint);
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
