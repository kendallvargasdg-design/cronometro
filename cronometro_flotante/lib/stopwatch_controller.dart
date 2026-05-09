import 'dart:async';
import 'package:flutter/foundation.dart';

class LapRecord {
  final int number;
  final Duration partial;
  final Duration cumulative;
  const LapRecord({required this.number, required this.partial, required this.cumulative});
}

class StopwatchController extends ChangeNotifier {
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Duration _lapStart = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;
  final List<LapRecord> _laps = [];

  bool get isRunning => _isRunning;
  bool get hasStarted => _elapsed > Duration.zero || _isRunning;
  List<LapRecord> get laps => List.unmodifiable(_laps);

  Duration get elapsed {
    if (_isRunning && _startTime != null) {
      return _elapsed + DateTime.now().difference(_startTime!);
    }
    return _elapsed;
  }

  Duration get currentLap => elapsed - _lapStart;

  void start() {
    if (!_isRunning) startPause();
  }

  void pause() {
    if (_isRunning) startPause();
  }

  void lap() => addLap();

  void startPause() {
    if (_isRunning) {
      _elapsed += DateTime.now().difference(_startTime!);
      _isRunning = false;
      _timer?.cancel();
    } else {
      _isRunning = true;
      _startTime = DateTime.now();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _elapsed = Duration.zero;
    _lapStart = Duration.zero;
    _startTime = null;
    _laps.clear();
    notifyListeners();
  }

  void addLap() {
    if (!hasStarted) return;
    final current = elapsed;
    _laps.insert(0, LapRecord(
      number: _laps.length + 1,
      partial: current - _lapStart,
      cumulative: current,
    ));
    _lapStart = current;
    notifyListeners();
  }
  
  static String format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s.$cs' : '$m:$s.$cs';
  }

  static String formatMain(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String formatCs(Duration d) {
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString().padLeft(2, '0');
    return '.$cs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
