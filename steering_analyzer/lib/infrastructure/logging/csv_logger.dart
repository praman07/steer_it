// csv_logger.dart
//
// Buffers sensor samples + measurements in memory and writes them to
// a CSV file on disk in chunks.  We avoid per-sample disk writes
// (which would burn the filesystem at 200 Hz) and instead flush
// every `kLogFlushInterval` or when the buffer is full.
//
// File naming: `steering_<startEpochMs>.csv` in the app's documents
// directory.  The user can hit "Export" to share the file via the
// system share sheet.

import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/sensor_sample.dart';
import '../../domain/algorithms/steering_measurement.dart';

class CsvLogger {
  bool _running = false;
  IOSink? _sink;
  File? _file;
  final List<List<dynamic>> _buffer = <List<dynamic>>[];
  Timer? _flushTimer;
  final Stopwatch _watch = Stopwatch();
  int _rowCount = 0;

  bool get isRunning => _running;
  File? get file => _file;
  int get rowCount => _rowCount;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _buffer.clear();
    _rowCount = 0;
    _watch.start();

    final Directory dir = await getApplicationDocumentsDirectory();
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filename = 'steering_$stamp.csv';
    _file = File('${dir.path}/$filename');
    _sink = _file!.openWrite(mode: FileMode.write);

    // Write the header row.
    _sink!.writeln(_headerRow().join(','));

    _flushTimer = Timer.periodic(kLogFlushInterval, (_) {
      _flush();
    });
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flush();
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _watch.stop();
  }

  void log({
    required SensorSample s,
    required SteeringMeasurement m,
  }) {
    if (!_running) return;
    _buffer.add(<dynamic>[
      m.wallClockMs,
      s.timestampUs.toStringAsFixed(0),
      m.algorithm.name,
      m.angleDeg.toStringAsFixed(3),
      m.rateDps.toStringAsFixed(3),
      m.accumulatedDeg.toStringAsFixed(3),
      m.turns.toStringAsFixed(3),
      m.biasDps.toStringAsFixed(4),
      m.driftDeg.toStringAsFixed(3),
      m.correctionDeg.toStringAsFixed(3),
      m.confidence.toStringAsFixed(3),
      s.gx.toStringAsFixed(4), s.gy.toStringAsFixed(4), s.gz.toStringAsFixed(4),
      s.ax.toStringAsFixed(4), s.ay.toStringAsFixed(4), s.az.toStringAsFixed(4),
      s.uax.toStringAsFixed(4), s.uay.toStringAsFixed(4), s.uaz.toStringAsFixed(4),
      s.mx.toStringAsFixed(4), s.my.toStringAsFixed(4), s.mz.toStringAsFixed(4),
      s.gvx.toStringAsFixed(4), s.gvy.toStringAsFixed(4), s.gvz.toStringAsFixed(4),
      s.azimuthDeg?.toStringAsFixed(3) ?? '',
      s.pitchDeg?.toStringAsFixed(3) ?? '',
      s.rollDeg?.toStringAsFixed(3) ?? '',
      s.headingDeg?.toStringAsFixed(3) ?? '',
      s.rotationAccuracy.toStringAsFixed(3),
    ]);
    _rowCount++;
    if (_buffer.length >= kLogBufferMaxRows) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty || _sink == null) return;
    final String csv = const CsvEncoder().convert(_buffer);
    _sink!.write(csv);
    _buffer.clear();
  }

  List<String> _headerRow() {
    return <String>[
      'wall_clock_ms', 'sensor_timestamp_us', 'algorithm',
      'angle_deg', 'rate_dps', 'accumulated_deg', 'turns',
      'bias_dps', 'drift_deg', 'correction_deg', 'confidence',
      'gx', 'gy', 'gz', 'ax', 'ay', 'az',
      'uax', 'uay', 'uaz', 'mx', 'my', 'mz',
      'gvx', 'gvy', 'gvz',
      'azimuth_deg', 'pitch_deg', 'roll_deg', 'heading_deg',
      'rotation_accuracy',
    ];
  }
}
