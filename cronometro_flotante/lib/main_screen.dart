import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'stopwatch_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
class _MainScreenState extends State<MainScreen> {
  static const _ch = MethodChannel('cronometro/pip');
  late final StopwatchController _sw;

  Color  _bg           = const Color(0xFF1a1a2e);
  double _opacity      = 0.92;
  String _family       = 'poppins';
  String _style        = 'regular';
  Color  _textCol      = Colors.white;
  bool   _inPiP        = false;
  bool   _showSettings = false;
  int    _lapCount     = 0;
  bool   _running      = false;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _sw = StopwatchController();
    _sw.addListener(_onChange);
    _ch.setMethodCallHandler(_onNative);
    _loadPrefs();
  }

  @override
  void dispose() {
    _sw.removeListener(_onChange);
    _sw.dispose();
    super.dispose();
  }

  void _onChange() {
    final lc = _sw.laps.length != _lapCount;
    final rc = _sw.isRunning != _running;
    if (lc || rc) {
      _lapCount = _sw.laps.length;
      _running  = _sw.isRunning;
      if (mounted) setState(() {});
      if (_inPiP) _updatePiP();
    }
  }

  // ── Native ───────────────────────────────────────────────────
  Future<dynamic> _onNative(MethodCall call) async {
    if (call.method == 'pipExited') {
      if (mounted) setState(() => _inPiP = false);
    } else if (call.method == 'pipAction') {
      final a = call.arguments as String?;
      if (a == 'play_pause') _sw.startPause();
      else if (a == 'reset') _sw.reset();
      else if (a == 'lap')   _sw.addLap();
    }
  }

  Future<void> _enterPiP() async {
    try { await _ch.invokeMethod('enterPiP', {'isRunning': _sw.isRunning}); }
    catch (_) {}
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() { _inPiP = true; _showSettings = false; });
  }

  Future<void> _updatePiP() async {
    try { await _ch.invokeMethod('updatePiP', {'isRunning': _sw.isRunning}); }
    catch (_) {}
  }

  // ── Prefs ────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bg      = Color(p.getInt('bg')    ?? 0xFF1a1a2e);
      _opacity = p.getDouble('op')       ?? 0.92;
      _family  = p.getString('fam')      ?? 'poppins';
      _style   = p.getString('sty')      ?? 'regular';
      _textCol = Color(p.getInt('txt')   ?? 0xFFFFFFFF);
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bg',     _bg.value);
    await p.setDouble('op',  _opacity);
    await p.setString('fam', _family);
    await p.setString('sty', _style);
    await p.setInt('txt',    _textCol.value);
  }

  // ── Font helper ──────────────────────────────────────────────
  TextStyle _font(double size, Color color, {double? ls}) {
    final w = _style == 'bold'
        ? FontWeight.w700
        : _style == 'extrabold'
            ? FontWeight.w800
            : FontWeight.w400;
    final fi = _style == 'italic' ? FontStyle.italic : FontStyle.normal;
    const d  = TextDecoration.none;
    switch (_family) {
      case 'montserrat':
        return GoogleFonts.montserrat(
            fontSize: size, fontWeight: w, fontStyle: fi,
            color: color, letterSpacing: ls, decoration: d);
      case 'playfair':
        return GoogleFonts.playfairDisplay(
            fontSize: size, fontWeight: w, fontStyle: fi,
            color: color, letterSpacing: ls, decoration: d);
      case 'cormorant':
        return GoogleFonts.cormorantGaramond(
            fontSize: size, fontWeight: w, fontStyle: fi,
            color: color, letterSpacing: ls, decoration: d);
      default:
        return GoogleFonts.poppins(
            fontSize: size, fontWeight: w, fontStyle: fi,
            color: color, letterSpacing: ls, decoration: d);
    }
  }

  // ── Color pickers ────────────────────────────────────────────
  void _pickBg() {
    Color t = _bg;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Color de fondo',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _bg,
            onColorChanged: (c) => t = c,
            availableColors: const [
              Color(0xFF1a1a2e), Color(0xFF0d1117), Color(0xFF16213e),
              Color(0xFF0f3460), Color(0xFF1b4332), Color(0xFF370617),
              Color(0xFF240046), Color(0xFF212529), Color(0xFF003049),
              Color(0xFF023e8a), Color(0xFF2d6a4f), Color(0xFF6a040f),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _bg = t);
              _save();
              Navigator.pop(context);
            },
            child: Text('Aplicar',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _pickText() {
    Color t = _textCol;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Color de texto',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _textCol,
            onColorChanged: (c) => t = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _textCol = t);
              _save();
              Navigator.pop(context);
            },
            child: Text('Aplicar',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── PiP view ─────────────────────────────────────────────────
  Widget _buildPiP() {
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Container(
          color: _bg.withOpacity(_opacity),
          child: AnimatedBuilder(
            animation: _sw,
            builder: (_, __) {
              final run = _sw.isRunning;
              return Stack(
                children: [
                  // Ghost icons hint
                  Positioned(
                    top: 7, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(run ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: _textCol.withOpacity(0.22), size: 14),
                        const SizedBox(width: 10),
                        Icon(Icons.replay_rounded,
                            color: _textCol.withOpacity(0.22), size: 13),
                        const SizedBox(width: 10),
                        Icon(Icons.flag_rounded,
                            color: _textCol.withOpacity(0.22), size: 12),
                      ],
                    ),
                  ),
                  // Time display
                  Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 26),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(StopwatchController.formatMain(_sw.elapsed),
                                style: _font(52, _textCol, ls: 1)),
                            Text(StopwatchController.formatCs(_sw.elapsed),
                                style: _font(18, _textCol.withOpacity(0.5))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status label
                  Positioned(
                    bottom: 7, left: 0, right: 0,
                    child: Text(
                      run ? '▶  EN CURSO' : '⏸  PAUSADO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: run
                            ? const Color(0xFF1a73e8)
                            : Colors.white38,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Settings panel (inline) ──────────────────────────────────
  Widget _buildSettings() {
    // local helpers live inside the stateful widget → setState() works directly
    Widget settingRow(String label, Widget trailing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            trailing,
          ],
        ),
      );
    }

    Widget chip(String key, String label, {bool isFamily = true}) {
      final sel = isFamily ? _family == key : _style == key;
      final c   = sel ? const Color(0xFF1a73e8) : Colors.white60;
      TextStyle ts;
      if (isFamily) {
        switch (key) {
          case 'montserrat':
            ts = GoogleFonts.montserrat(
                fontSize: 12, color: c, fontWeight: FontWeight.w600);
            break;
          case 'playfair':
            ts = GoogleFonts.playfairDisplay(
                fontSize: 12, color: c, fontWeight: FontWeight.w600);
            break;
          case 'cormorant':
            ts = GoogleFonts.cormorantGaramond(
                fontSize: 13, color: c, fontWeight: FontWeight.w600);
            break;
          default:
            ts = GoogleFonts.poppins(
                fontSize: 12, color: c, fontWeight: FontWeight.w600);
        }
      } else {
        final fw = key == 'bold'
            ? FontWeight.w700
            : key == 'extrabold'
                ? FontWeight.w800
                : FontWeight.w400;
        final fi = key == 'italic' ? FontStyle.italic : FontStyle.normal;
        ts = GoogleFonts.poppins(
            fontSize: 12, color: c, fontWeight: fw, fontStyle: fi);
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isFamily) _family = key;
            else _style = key;
          });
          _save();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel
                ? const Color(0xFF1a73e8).withOpacity(0.18)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel ? const Color(0xFF1a73e8) : Colors.white12),
          ),
          child: Text(label, style: ts),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF13132a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Live preview ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _bg.withOpacity(_opacity),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VISTA PREVIA',
                    style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 8,
                        letterSpacing: 2,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('00:00', style: _font(34, _textCol, ls: 1)),
                    Text('.00', style: _font(13, _textCol.withOpacity(0.45))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Apariencia ────────────────────────────────────
          Text('APARIENCIA',
              style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),

          settingRow(
            'Fondo',
            GestureDetector(
              onTap: _pickBg,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        color: _bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30))),
                const SizedBox(width: 6),
                Text('Cambiar',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1a73e8), fontSize: 12)),
              ]),
            ),
          ),

          settingRow(
            'Opacidad',
            SizedBox(
              width: 130,
              child: Slider(
                value: _opacity,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                activeColor: const Color(0xFF1a73e8),
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  setState(() => _opacity = v);
                  _save();
                },
              ),
            ),
          ),

          settingRow(
            'Color texto',
            GestureDetector(
              onTap: _pickText,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        color: _textCol,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30))),
                const SizedBox(width: 6),
                Text('Cambiar',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1a73e8), fontSize: 12)),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Tipografía ────────────────────────────────────
          Text('TIPOGRAFÍA',
              style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),

          Wrap(spacing: 8, runSpacing: 8, children: [
            chip('poppins',    'Poppins'),
            chip('montserrat', 'Montserrat'),
            chip('playfair',   'Playfair'),
            chip('cormorant',  'Cormorant'),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip('regular',   'Regular',    isFamily: false),
            chip('bold',      'Bold',       isFamily: false),
            chip('extrabold', 'Extra Bold', isFamily: false),
            chip('italic',    'Cursiva',    isFamily: false),
          ]),
        ],
      ),
    );
  }

  // ── Main build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_inPiP) return _buildPiP();

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a73e8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1a73e8).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.timer,
                        color: Color(0xFF1a73e8), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cronómetro',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('Flotante',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1a73e8),
                              height: 0.85)),
                    ],
                  ),
                  const Spacer(),
                  // Settings toggle — icon animates between tune / close
                  IconButton(
                    onPressed: () =>
                        setState(() => _showSettings = !_showSettings),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _showSettings ? Icons.close : Icons.tune,
                        key: ValueKey(_showSettings),
                        color:
                            _showSettings ? Colors.white70 : Colors.white54,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _enterPiP,
                    icon: const Icon(Icons.picture_in_picture_alt,
                        color: Color(0xFF1a73e8)),
                  ),
                ],
              ),
            ),

            // ── Inline settings (animated expand/collapse) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child:
                  _showSettings ? _buildSettings() : const SizedBox.shrink(),
            ),

            // ── Timer + buttons ──────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _sw,
                      builder: (_, __) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                                StopwatchController.formatMain(_sw.elapsed),
                                style: _font(76, _textCol, ls: 1)),
                            Text(
                                StopwatchController.formatCs(_sw.elapsed),
                                style: _font(
                                    26, _textCol.withOpacity(0.45))),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn(
                        _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR',
                        const Color(0xFF1a73e8),
                        () => _sw.startPause(),
                      ),
                      const SizedBox(width: 10),
                      _btn(
                        'LAP',
                        const Color(0xFFfbbc04),
                        _sw.isRunning ? () => _sw.addLap() : null,
                      ),
                      const SizedBox(width: 10),
                      _btn(
                        '↺  RESET',
                        const Color(0xFFea4335),
                        () => _sw.reset(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Laps ────────────────────────────────────────
            if (_sw.laps.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    const Divider(color: Colors.white12),
                    ..._sw.laps.map((lap) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text('LAP ${lap.number}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                  StopwatchController.format(lap.partial),
                                  style: GoogleFonts.poppins(
                                      color: _textCol.withOpacity(0.7),
                                      fontSize: 13)),
                              const SizedBox(width: 16),
                              Text(
                                  StopwatchController
                                      .format(lap.cumulative),
                                  style: GoogleFonts.poppins(
                                      color: _textCol,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Button helper ────────────────────────────────────────────
  Widget _btn(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
