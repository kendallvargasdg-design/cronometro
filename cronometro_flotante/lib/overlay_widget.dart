import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stopwatch_controller.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});
  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  late final StopwatchController _sw;
  Color _bgColor     = const Color(0xFF1a1a2e);
  double _opacity    = 0.92;
  String _fontFamily = 'poppins';
  String _fontStyle  = 'regular';
  Color _textColor   = Colors.white;
  bool _showLaps     = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _sw = StopwatchController();
    _sw.addListener(() { if (mounted) setState(() {}); });
    _loadPrefs();

    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && mounted) {
        setState(() {
          if (data['bg_color']    != null) _bgColor    = Color(data['bg_color'] as int);
          if (data['opacity']     != null) _opacity    = (data['opacity'] as num).toDouble();
          if (data['font_family'] != null) _fontFamily = data['font_family'] as String;
          if (data['font_style']  != null) _fontStyle  = data['font_style']  as String;
          if (data['text_color']  != null) _textColor  = Color(data['text_color'] as int);
        });
      }
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bgColor    = Color(p.getInt('bg_color')   ?? 0xFF1a1a2e);
        _opacity    = p.getDouble('opacity')        ?? 0.92;
        _fontFamily = p.getString('font_family')    ?? 'poppins';
        _fontStyle  = p.getString('font_style')     ?? 'regular';
        _textColor  = Color(p.getInt('text_color')  ?? 0xFFFFFFFF);
      });
    }
  }

  Future<void> _saveOpacity(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('opacity', v);
  }

  @override
  void dispose() {
    _sw.dispose();
    super.dispose();
  }

  TextStyle _ts(double size, {double? letterSpacing, Color? color}) {
    final c = color ?? _textColor;
    final weight = _fontStyle == 'bold'
        ? FontWeight.w700
        : _fontStyle == 'extrabold'
            ? FontWeight.w800
            : FontWeight.w400;
    final fStyle = _fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
    switch (_fontFamily) {
      case 'montserrat':
        return GoogleFonts.montserrat(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'playfair':
        return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'cormorant':
        return GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      default:
        return GoogleFonts.poppins(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor.withOpacity(_opacity),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, spreadRadius: 2)],
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildTimer(),
              _buildButtons(),
              if (_showSettings) _buildOpacityRow(),
              if (_showLaps && _sw.laps.isNotEmpty) _buildLapList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.black.withOpacity(0.25),
      child: Row(children: [
        const Icon(Icons.timer_outlined, color: Colors.white54, size: 13),
        const SizedBox(width: 6),
        Text('CRONÓMETRO', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.8)),
        const Spacer(),
        _HeaderBtn(icon: Icons.tune, active: _showSettings, onTap: () => setState(() => _showSettings = !_showSettings)),
        const SizedBox(width: 14),
        _HeaderBtn(icon: Icons.format_list_bulleted, active: _showLaps, onTap: () => setState(() => _showLaps = !_showLaps)),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => FlutterOverlayWindow.closeOverlay(),
          child: const Icon(Icons.close, color: Colors.white38, size: 17),
        ),
      ]),
    );
  }

  Widget _buildTimer() {
    final full = StopwatchController.format(_sw.elapsed);
    final dot  = full.lastIndexOf('.');
    final main = dot >= 0 ? full.substring(0, dot) : full;
    final frac = dot >= 0 ? full.substring(dot) : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(main, style: _ts(52, letterSpacing: 2)),
          Text(frac, style: _ts(28, letterSpacing: 1, color: _textColor.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: _ActionBtn(
            label: _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR',
            color: const Color(0xFF1a73e8),
            onTap: _sw.startPause,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _ActionBtn(label: 'LAP', color: const Color(0xFFfbbc04), onTap: _sw.hasStarted ? _sw.addLap : null),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _ActionBtn(label: '↺  RESET', color: const Color(0xFFea4335), onTap: _sw.hasStarted ? _sw.reset : null),
        ),
      ]),
    );
  }

  Widget _buildOpacityRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(children: [
        const Icon(Icons.brightness_low, color: Colors.white38, size: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 2,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _opacity, min: 0.3, max: 1.0, divisions: 7,
              activeColor: Colors.white70, inactiveColor: Colors.white24,
              onChanged: (v) { setState(() => _opacity = v); _saveOpacity(v); },
            ),
          ),
        ),
        const Icon(Icons.brightness_high, color: Colors.white70, size: 16),
      ]),
    );
  }

  Widget _buildLapList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 170),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        itemCount: _sw.laps.length,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 12, endIndent: 12),
        itemBuilder: (ctx, i) {
          final lap = _sw.laps[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(children: [
              Text('LAP ${lap.number}', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const Spacer(),
              Text(StopwatchController.format(lap.partial), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 14),
              Text(StopwatchController.format(lap.cumulative), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            ]),
          );
        },
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: active ? Colors.white : Colors.white38, size: 17),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? color.withOpacity(0.55) : Colors.white12, width: 1),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: enabled ? color : Colors.white24, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    );
  }
}
