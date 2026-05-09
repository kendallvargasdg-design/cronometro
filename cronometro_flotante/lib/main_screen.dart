import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'stopwatch_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _channel = MethodChannel('cronometro/pip');
  late final StopwatchController _sw;

  Color  _bgColor     = const Color(0xFF1a1a2e);
  double _opacity     = 0.92;
  String _fontFamily  = 'poppins';
  String _fontStyle   = 'regular';
  Color  _textColor   = Colors.white;
  bool   _showSettings = false;
  bool   _inPiP        = false;
  int    _lastLapCount = 0;
  bool   _lastRunning  = false;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _sw = StopwatchController();
    _sw.addListener(_onSwChange);
    _channel.setMethodCallHandler(_handleNative);
    _loadPrefs();
  }

  @override
  void dispose() {
    _sw.removeListener(_onSwChange);
    _sw.dispose();
    super.dispose();
  }

  // ── Listener: only setState on meaningful changes ────────────
  void _onSwChange() {
    final lapChanged     = _sw.laps.length != _lastLapCount;
    final runningChanged = _sw.isRunning   != _lastRunning;
    if (lapChanged || runningChanged) {
      _lastLapCount = _sw.laps.length;
      _lastRunning  = _sw.isRunning;
      if (mounted) setState(() {});
      if (_inPiP) _updatePiP();
    }
  }

  // ── Native → Flutter ─────────────────────────────────────────
  Future<dynamic> _handleNative(MethodCall call) async {
    switch (call.method) {
      case 'pipExited':
        if (mounted) setState(() => _inPiP = false);
        break;
      case 'pipAction':
        final action = call.arguments as String?;
        if (action == 'play_pause') {
          _sw.startPause();
        } else if (action == 'reset') {
          _sw.reset();
        } else if (action == 'lap') {
          _sw.addLap();
        }
        break;
    }
  }

  // ── PiP control ───────────────────────────────────────────────
  Future<void> _enterPiP() async {
    try {
      await _channel.invokeMethod('enterPiP', {'isRunning': _sw.isRunning});
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _inPiP = true);
  }

  Future<void> _updatePiP() async {
    try {
      await _channel.invokeMethod('updatePiP', {'isRunning': _sw.isRunning});
    } catch (_) {}
  }

  // ── Prefs ────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bgColor    = Color(p.getInt('bg_color')   ?? 0xFF1a1a2e);
      _opacity    = p.getDouble('opacity')        ?? 0.92;
      _fontFamily = p.getString('font_family')    ?? 'poppins';
      _fontStyle  = p.getString('font_style')     ?? 'regular';
      _textColor  = Color(p.getInt('text_color')  ?? 0xFFFFFFFF);
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bg_color',       _bgColor.value);
    await p.setDouble('opacity',     _opacity);
    await p.setString('font_family', _fontFamily);
    await p.setString('font_style',  _fontStyle);
    await p.setInt('text_color',     _textColor.value);
  }

  // ── Font helper ───────────────────────────────────────────────
  static TextStyle _buildFontStyle(
      String family, String style, double size, Color color,
      {double? letterSpacing}) {
    final weight = style == 'bold'
        ? FontWeight.w700
        : style == 'extrabold'
            ? FontWeight.w800
            : FontWeight.w400;
    final fStyle = style == 'italic' ? FontStyle.italic : FontStyle.normal;
    const deco   = TextDecoration.none; // eliminates yellow underline in PiP
    switch (family) {
      case 'montserrat':
        return GoogleFonts.montserrat(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing, decoration: deco);
      case 'playfair':
        return GoogleFonts.playfairDisplay(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing, decoration: deco);
      case 'cormorant':
        return GoogleFonts.cormorantGaramond(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing, decoration: deco);
      default:
        return GoogleFonts.poppins(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing, decoration: deco);
    }
  }

  // ── Color pickers ─────────────────────────────────────────────
  void _pickBgColor() {
    Color temp = _bgColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Color de fondo',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _bgColor,
            onColorChanged: (c) => temp = c,
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
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _bgColor = temp);
              _savePrefs();
              Navigator.pop(context);
            },
            child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _pickTextColor() {
    Color temp = _textColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Color de texto',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _textColor,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a73e8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() => _textColor = temp);
              _savePrefs();
              Navigator.pop(context);
            },
            child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PiP VIEW — clean, two-size timer + ghost control hints
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPiP() {
    return Material(                          // fixes yellow underline in PiP
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Container(
          color: _bgColor.withOpacity(_opacity),
          child: AnimatedBuilder(
            animation: _sw,
            builder: (_, __) {
              final running = _sw.isRunning;
              return Stack(children: [

                // ── Ghost control icons (top) ─────────────────
                // Hint visual: tells the user controls exist.
                // When they tap the PiP, the system shows the
                // real interactive RemoteAction buttons on top.
                Positioned(
                  top: 7,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _textColor.withOpacity(0.22),
                        size: 14,
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.replay_rounded,
                          color: _textColor.withOpacity(0.22), size: 13),
                      const SizedBox(width: 10),
                      Icon(Icons.flag_rounded,
                          color: _textColor.withOpacity(0.22), size: 12),
                    ],
                  ),
                ),

                // ── Time (MM:SS large + .cs small) ───────────
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
                          Text(
                            StopwatchController.formatMain(_sw.elapsed),
                            style: _buildFontStyle(
                                _fontFamily, _fontStyle, 52, _textColor,
                                letterSpacing: 1),
                          ),
                          Text(
                            StopwatchController.formatCs(_sw.elapsed),
                            style: _buildFontStyle(
                                _fontFamily, _fontStyle, 18,
                                _textColor.withOpacity(0.50)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Status label (bottom) ─────────────────────
                Positioned(
                  bottom: 7,
                  left: 0,
                  right: 0,
                  child: Text(
                    running ? '▶  EN CURSO' : '⏸  PAUSADO',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: running
                          ? const Color(0xFF1a73e8)
                          : Colors.white38,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),

              ]);
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MAIN SCREEN
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_inPiP) return _buildPiP();

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ──────────────────────────────────────
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: const Color(0xFF1a73e8).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.timer,
                      color: Color(0xFF1a73e8), size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cronómetro',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('Flotante',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1a73e8),
                          height: 0.9)),
                ]),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      setState(() => _showSettings = !_showSettings),
                  icon: Icon(
                      _showSettings ? Icons.close : Icons.tune,
                      color: Colors.white54),
                ),
                IconButton(
                  onPressed: _enterPiP,
                  icon: const Icon(Icons.picture_in_picture_alt,
                      color: Color(0xFF1a73e8)),
                  tooltip: 'Modo flotante',
                ),
              ]),
              const SizedBox(height: 24),

              // ── Settings panel (collapsible) ─────────────────
              if (_showSettings) ...[
                _buildSettingsPanel(),
                const SizedBox(height: 20),
              ],

              // ── Timer display ────────────────────────────────
              Center(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _sw,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          StopwatchController.formatMain(_sw.elapsed),
                          style: _buildFontStyle(
                              _fontFamily, _fontStyle, 72, _textColor,
                              letterSpacing: 1),
                        ),
                        Text(
                          StopwatchController.formatCs(_sw.elapsed),
                          style: _buildFontStyle(
                              _fontFamily, _fontStyle, 24,
                              _textColor.withOpacity(0.45)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    label: _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR',
                    color: const Color(0xFF1a73e8),
                    onTap: () => _sw.startPause(),
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    label: 'LAP',
                    color: const Color(0xFFfbbc04),
                    onTap: _sw.isRunning ? () => _sw.addLap() : null,
                  ),
                  const SizedBox(width: 10),
                  _ActionBtn(
                    label: '↺  RESET',
                    color: const Color(0xFFea4335),
                    onTap: () => _sw.reset(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Lap list ─────────────────────────────────────
              if (_sw.laps.isNotEmpty) ...[
                const Divider(color: Colors.white12),
                const SizedBox(height: 4),
                ..._sw.laps.map((lap) => _LapRow(lap: lap, textColor: _textColor)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings panel ────────────────────────────────────────────
  Widget _buildSettingsPanel() {
    return Column(children: [
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APARIENCIA',
            style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _SettingRow(
          label: 'Fondo',
          child: GestureDetector(
            onTap: _pickBgColor,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30))),
              const SizedBox(width: 6),
              Text('Cambiar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1a73e8), fontSize: 12)),
            ]),
          ),
        ),
        _SettingRow(
          label: 'Opacidad',
          child: SizedBox(
            width: 120,
            child: Slider(
              value: _opacity, min: 0.3, max: 1.0, divisions: 7,
              activeColor: const Color(0xFF1a73e8),
              inactiveColor: Colors.white12,
              onChanged: (v) {
                setState(() => _opacity = v);
                _savePrefs();
              },
            ),
          ),
        ),
        _SettingRow(
          label: 'Texto',
          child: GestureDetector(
            onTap: _pickTextColor,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: _textColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30))),
              const SizedBox(width: 6),
              Text('Cambiar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1a73e8), fontSize: 12)),
            ]),
          ),
        ),
      ])),
      const SizedBox(height: 8),
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TIPOGRAFÍA',
            style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildFamilyChip('poppins',    'Poppins'),
          _buildFamilyChip('montserrat', 'Montserrat'),
          _buildFamilyChip('playfair',   'Playfair'),
          _buildFamilyChip('cormorant',  'Cormorant'),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildStyleChip('regular',   'Regular'),
          _buildStyleChip('bold',      'Bold'),
          _buildStyleChip('extrabold', 'Extra Bold'),
          _buildStyleChip('italic',    'Cursiva'),
        ]),
      ])),
    ]);
  }

  Widget _buildFamilyChip(String key, String label) {
    final sel = _fontFamily == key;
    final c   = sel ? const Color(0xFF1a73e8) : Colors.white60;
    TextStyle ts;
    switch (key) {
      case 'montserrat':
        ts = GoogleFonts.montserrat(fontSize: 12, color: c, fontWeight: FontWeight.w600); break;
      case 'playfair':
        ts = GoogleFonts.playfairDisplay(fontSize: 12, color: c, fontWeight: FontWeight.w600); break;
      case 'cormorant':
        ts = GoogleFonts.cormorantGaramond(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      default:
        ts = GoogleFonts.poppins(fontSize: 12, color: c, fontWeight: FontWeight.w600);
    }
    return GestureDetector(
      onTap: () { setState(() => _fontFamily = key); _savePrefs(); },
      child: _Chip(selected: sel, child: Text(label, style: ts)),
    );
  }

  Widget _buildStyleChip(String key, String label) {
    final sel = _fontStyle == key;
    final w   = key == 'bold'
        ? FontWeight.w700
        : key == 'extrabold'
            ? FontWeight.w800
            : FontWeight.w400;
    final fi  = key == 'italic' ? FontStyle.italic : FontStyle.normal;
    return GestureDetector(
      onTap: () { setState(() => _fontStyle = key); _savePrefs(); },
      child: _Chip(
        selected: sel,
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: sel ? const Color(0xFF1a73e8) : Colors.white60,
                fontWeight: w,
                fontStyle: fi)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reusable widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class _LapRow extends StatelessWidget {
  final LapRecord lap;
  final Color textColor;
  const _LapRow({required this.lap, required this.textColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text('LAP ${lap.number}',
          style: GoogleFonts.poppins(
              color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text(StopwatchController.format(lap.partial),
          style: GoogleFonts.poppins(
              color: textColor.withOpacity(0.7), fontSize: 13)),
      const SizedBox(width: 16),
      Text(StopwatchController.format(lap.cumulative),
          style: GoogleFonts.poppins(
              color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: child,
  );
}

class _Chip extends StatelessWidget {
  final bool selected;
  final Widget child;
  const _Chip({required this.selected, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFF1a73e8).withOpacity(0.18)
          : Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: selected ? const Color(0xFF1a73e8) : Colors.white12),
    ),
    child: child,
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingRow({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
      const Spacer(),
      child,
    ]),
  );
}
