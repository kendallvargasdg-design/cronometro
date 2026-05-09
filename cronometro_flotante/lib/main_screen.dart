import 'dart:async';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('cronometro/pip');

  late final StopwatchController _sw;
  Color _bgColor = const Color(0xFF1a1a2e);
  double _opacity = 0.92;
  String _fontFamily = 'poppins';
  String _fontStyle = 'regular';
  Color _textColor = Colors.white;
  bool _showSettings = false;
  bool _inPiP = false;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sw = StopwatchController();
    _sw.addListener(() { if (mounted) setState(() {}); });
    _loadPrefs();
   _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipAction') {
        final action = call.arguments as String;
        if (action == 'play')  { _sw.isRunning ? _sw.pause() : _sw.start(); }
        if (action == 'reset') { _sw.reset(); }
        if (action == 'lap')   { _sw.lap(); }
        if (mounted) setState(() {});
      } else if (call.method == 'pipExited') {
        // Android confirma que salimos del modo flotante
        if (mounted) setState(() => _inPiP = false);
        _dismissNotification();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _inPiP) {
      setState(() => _inPiP = false);
      _dismissNotification();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTimer?.cancel();
    _sw.dispose();
    super.dispose();
  }

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

  void _startNotifTimer() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateNotification());
  }

  Future<void> _updateNotification() async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'time': StopwatchController.format(_sw.elapsed),
        'isRunning': _sw.isRunning,
      });
    } catch (_) {}
  }

  Future<void> _dismissNotification() async {
    _notifTimer?.cancel();
    _notifTimer = null;
    try { await _channel.invokeMethod('dismissNotification'); } catch (_) {}
  }

  Future<void> _enterPiP() async {
    try {
      await _channel.invokeMethod('enterPiP', {
        'time': StopwatchController.format(_sw.elapsed),
        'isRunning': _sw.isRunning,
      });
      if (mounted) setState(() => _inPiP = true);
      _startNotifTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error PiP: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Colores ───────────────────────────────────────────────────
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

  // ── Font helper ──────────────────────────────────────────────
  static TextStyle _buildFontStyle(
      String family, String style, double size, Color color,
      {double? letterSpacing}) {
    final weight = style == 'bold'
        ? FontWeight.w700
        : style == 'extrabold'
            ? FontWeight.w800
            : FontWeight.w400;
    final fStyle = style == 'italic' ? FontStyle.italic : FontStyle.normal;
    switch (family) {
      case 'montserrat':
        return GoogleFonts.montserrat(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing);
      case 'playfair':
        return GoogleFonts.playfairDisplay(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing);
      case 'cormorant':
        return GoogleFonts.cormorantGaramond(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing);
      default:
        return GoogleFonts.poppins(
            fontSize: size, fontWeight: weight, fontStyle: fStyle,
            color: color, letterSpacing: letterSpacing);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Usa SOLO la bandera _inPiP — nunca MediaQuery.width
    // para evitar vibración durante la animación de entrada al PiP.
    if (_inPiP) return _buildPiP();
    return _buildFull();
  }

  // ── Vista PiP (solo lectura, sin botones táctiles) ───────────
  Widget _buildPiP() {
    return Scaffold(
      backgroundColor: _bgColor.withOpacity(_opacity),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              StopwatchController.format(_sw.elapsed),
              style: _buildFontStyle(_fontFamily, _fontStyle, 52, _textColor,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Text(
              _sw.isRunning ? '▶  EN CURSO' : '⏸  PAUSADO',
              style: GoogleFonts.poppins(
                  color: _textColor.withOpacity(0.6),
                  fontSize: 11,
                  letterSpacing: 1.5),
            ),
            if (_sw.laps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'LAP ${_sw.laps.length}',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFfbbc04).withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Vista completa ───────────────────────────────────────────
  Widget _buildFull() {
    final timeStr = StopwatchController.format(_sw.elapsed);
    final timeStyle = _buildFontStyle(_fontFamily, _fontStyle, 58, _textColor,
        letterSpacing: 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1a73e8).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.timer, color: Color(0xFF1a73e8), size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cronómetro',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Flotante',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: const Color(0xFF1a73e8), height: 0.9)),
                ]),
                const Spacer(),
                // Botón ajustes
                IconButton(
                  icon: Icon(
                    _showSettings ? Icons.close : Icons.settings_outlined,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => _showSettings = !_showSettings),
                ),
              ]),
            ),

            // ── Cronómetro principal ────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  const SizedBox(height: 16),

                  // Pantalla del tiempo
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _bgColor.withOpacity(_opacity),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.4), blurRadius: 24)],
                    ),
                    child: Column(children: [
                      Text(timeStr, style: timeStyle),
                      const SizedBox(height: 20),

                      // Botones: INICIAR / LAP / RESET
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _ActionBtn(
                          label: _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR',
                          color: const Color(0xFF1a73e8),
                          onTap: () {
                            _sw.isRunning ? _sw.pause() : _sw.start();
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _ActionBtn(
                          label: 'LAP',
                          color: const Color(0xFFfbbc04),
                          onTap: _sw.isRunning ? () { _sw.lap(); setState(() {}); } : null,
                        ),
                        const SizedBox(width: 10),
                        _ActionBtn(
                          label: '↺  RESET',
                          color: const Color(0xFFea4335),
                          onTap: () { _sw.reset(); setState(() {}); },
                        ),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Botón modo flotante
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_in_picture_alt, size: 18),
                        label: Text('Modo flotante',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6200ea),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _enterPiP,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Panel de ajustes (colapsable) ───────────
                  if (_showSettings) _buildSettingsPanel(),

                  // ── Vueltas ─────────────────────────────────
                  if (_sw.laps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Text('VUELTAS',
                            style: GoogleFonts.poppins(
                                color: Colors.white38, fontSize: 10,
                                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    ..._sw.laps.reversed.map((lap) => _LapTile(lap: lap)),
                  ],
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APARIENCIA',
            style: GoogleFonts.poppins(
                color: Colors.white38, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 14),

        // Color de fondo
        _SettingRow(
          icon: Icons.palette_outlined,
          label: 'Color de fondo',
          trailing: GestureDetector(
            onTap: _pickBgColor,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: _bgColor, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30))),
              const SizedBox(width: 6),
              Text('Cambiar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1a73e8), fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Transparencia
        _SettingRow(
          icon: Icons.opacity,
          label: 'Transparencia',
          trailing: SizedBox(
            width: 120,
            child: Slider(
              value: _opacity, min: 0.3, max: 1.0, divisions: 7,
              activeColor: const Color(0xFF1a73e8),
              inactiveColor: Colors.white12,
              onChanged: (v) { setState(() => _opacity = v); _savePrefs(); },
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text('TIPOGRAFÍA',
            style: GoogleFonts.poppins(
                color: Colors.white38, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),

        // Familia de fuente
        Text('Familia', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildFamilyChip('poppins',    'Poppins'),
          _buildFamilyChip('montserrat', 'Montserrat'),
          _buildFamilyChip('playfair',   'Playfair Display'),
          _buildFamilyChip('cormorant',  'Cormorant'),
        ]),
        const SizedBox(height: 14),

        // Estilo
        Text('Estilo', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildStyleChip('regular',   'Regular'),
          _buildStyleChip('italic',    'Cursiva'),
          _buildStyleChip('bold',      'Bold'),
          _buildStyleChip('extrabold', 'Extra Bold'),
        ]),
        const SizedBox(height: 14),

        // Color de texto
        _SettingRow(
          icon: Icons.format_color_text,
          label: 'Color de texto',
          trailing: GestureDetector(
            onTap: _pickTextColor,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: _textColor, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30))),
              const SizedBox(width: 6),
              Text('Cambiar',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1a73e8), fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Chips ─────────────────────────────────────────────────────
  Widget _buildFamilyChip(String key, String label) {
    final sel = _fontFamily == key;
    final c = sel ? const Color(0xFF1a73e8) : Colors.white60;
    TextStyle ts;
    switch (key) {
      case 'montserrat': ts = GoogleFonts.montserrat(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      case 'playfair':   ts = GoogleFonts.playfairDisplay(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      case 'cormorant':  ts = GoogleFonts.cormorantGaramond(fontSize: 14, color: c, fontWeight: FontWeight.w600); break;
      default:           ts = GoogleFonts.poppins(fontSize: 13, color: c, fontWeight: FontWeight.w600);
    }
    return GestureDetector(
      onTap: () { setState(() => _fontFamily = key); _savePrefs(); },
      child: _Chip(selected: sel, child: Text(label, style: ts)),
    );
  }

  Widget _buildStyleChip(String key, String label) {
    final sel = _fontStyle == key;
    final w = key == 'bold' ? FontWeight.w700 : key == 'extrabold' ? FontWeight.w800 : FontWeight.w400;
    final fi = key == 'italic' ? FontStyle.italic : FontStyle.normal;
    return GestureDetector(
      onTap: () { setState(() => _fontStyle = key); _savePrefs(); },
      child: _Chip(
        selected: sel,
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: sel ? const Color(0xFF1a73e8) : Colors.white60,
                fontWeight: w, fontStyle: fi)),
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: onTap != null ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: onTap != null ? color.withOpacity(0.5) : Colors.white12),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: onTap != null ? color : Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    ),
  );
}

class _LapTile extends StatelessWidget {
  final LapRecord lap;
  const _LapTile({required this.lap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Row(children: [
      Text('LAP ${lap.number}',
          style: GoogleFonts.poppins(
              color: const Color(0xFFfbbc04),
              fontSize: 12, fontWeight: FontWeight.w700)),
      const Spacer(),
      Text(StopwatchController.format(lap.partial),
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      const SizedBox(width: 16),
      Text(StopwatchController.format(lap.cumulative),
          style: GoogleFonts.poppins(
              color: Colors.white38, fontSize: 11)),
    ]),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingRow({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Colors.white38, size: 18),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
    const Spacer(),
    trailing,
  ]);
}

class _Chip extends StatelessWidget {
  final bool selected;
  final Widget child;
  const _Chip({required this.selected, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
