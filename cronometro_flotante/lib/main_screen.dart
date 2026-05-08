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
  Color  _bgColor    = const Color(0xFF1a1a2e);
  double _opacity    = 0.92;
  String _fontFamily = 'poppins';
  String _fontStyle  = 'regular';
  Color  _textColor  = Colors.white;
  bool   _showSettings = false;

  @override
  void initState() {
    super.initState();
    _sw = StopwatchController();
    _sw.addListener(() { if (mounted) setState(() {}); });
    _loadPrefs();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipAction' && mounted) {
        final action = call.arguments as String;
        if (action == 'play_pause') _sw.startPause();
        if (action == 'reset')      _sw.reset();
        if (action == 'lap')        _sw.addLap();
      }
    });
  }

  @override
  void dispose() {
    _sw.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _bgColor    = Color(p.getInt('bg_color')    ?? 0xFF1a1a2e);
      _opacity    = p.getDouble('opacity')         ?? 0.92;
      _fontFamily = p.getString('font_family')     ?? 'poppins';
      _fontStyle  = p.getString('font_style')      ?? 'regular';
      _textColor  = Color(p.getInt('text_color')   ?? 0xFFFFFFFF);
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

  Future<void> _enterPiP() async {
    try {
      await _channel.invokeMethod('enterPiP', {'isRunning': _sw.isRunning});
    } catch (_) {}
  }

  TextStyle _ts(double size, {double? letterSpacing, Color? color}) {
    final c = color ?? _textColor;
    final weight = _fontStyle == 'bold'
        ? FontWeight.w700
        : _fontStyle == 'extrabold' ? FontWeight.w800 : FontWeight.w400;
    final fStyle = _fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
    switch (_fontFamily) {
      case 'montserrat':
        return GoogleFonts.montserrat(fontSize: size, fontWeight: weight,
            fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'playfair':
        return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight,
            fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'cormorant':
        return GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: weight,
            fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      default:
        return GoogleFonts.poppins(fontSize: size, fontWeight: weight,
            fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 300) return _buildPiP();
    return _buildFull();
  }

  // ── PiP compacto ──────────────────────────────────────────────
  Widget _buildPiP() {
    final full = StopwatchController.format(_sw.elapsed);
    final dot  = full.lastIndexOf('.');
    final main = dot >= 0 ? full.substring(0, dot) : full;
    final frac = dot >= 0 ? full.substring(dot) : '';
    return Material(
      color: _bgColor.withOpacity(_opacity),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(main, style: _ts(30, letterSpacing: 2)),
            Text(frac, style: _ts(18, letterSpacing: 1,
                color: _textColor.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  // ── Pantalla completa ─────────────────────────────────────────
  Widget _buildFull() {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTimerCard(),
            const SizedBox(height: 14),
            _buildButtons(),
            if (_sw.laps.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildLapList(),
            ],
            if (_showSettings) ...[
              const SizedBox(height: 14),
              _buildSettings(),
            ],
            const SizedBox(height: 20),
            _buildPiPButton(),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
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
        Text('Cronómetro', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Flotante', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: const Color(0xFF1a73e8), height: 0.9)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() => _showSettings = !_showSettings),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _showSettings
                ? const Color(0xFF1a73e8).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _showSettings
                ? const Color(0xFF1a73e8).withOpacity(0.5)
                : Colors.white12),
          ),
          child: Icon(Icons.tune,
              color: _showSettings ? const Color(0xFF1a73e8) : Colors.white54,
              size: 20),
        ),
      ),
    ]);
  }

  Widget _buildTimerCard() {
    final full = StopwatchController.format(_sw.elapsed);
    final dot  = full.lastIndexOf('.');
    final main = dot >= 0 ? full.substring(0, dot) : full;
    final frac = dot >= 0 ? full.substring(dot) : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(_opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.4), blurRadius: 24)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(main, style: _ts(54, letterSpacing: 2)),
          Text(frac, style: _ts(30, letterSpacing: 1,
              color: _textColor.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(children: [
      Expanded(flex: 5, child: _ActionBtn(
        label: _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR',
        color: const Color(0xFF1a73e8),
        onTap: _sw.startPause,
      )),
      const SizedBox(width: 8),
      Expanded(flex: 3, child: _ActionBtn(
        label: 'LAP',
        color: const Color(0xFFfbbc04),
        onTap: _sw.hasStarted ? _sw.addLap : null,
      )),
      const SizedBox(width: 8),
      Expanded(flex: 3, child: _ActionBtn(
        label: '↺  RESET',
        color: const Color(0xFFea4335),
        onTap: _sw.hasStarted ? _sw.reset : null,
      )),
    ]);
  }

  Widget _buildLapList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sw.laps.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, color: Colors.white.withOpacity(0.06),
            indent: 12, endIndent: 12),
        itemBuilder: (_, i) {
          final lap = _sw.laps[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text('LAP ${lap.number}', style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(StopwatchController.format(lap.partial),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text(StopwatchController.format(lap.cumulative),
                  style: GoogleFonts.poppins(
                      color: Colors.white38, fontSize: 12)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APARIENCIA', style: GoogleFonts.poppins(
            color: Colors.white38, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.opacity, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Text('Transparencia', style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13)),
          const Spacer(),
          SizedBox(width: 120, child: Slider(
            value: _opacity, min: 0.3, max: 1.0, divisions: 7,
            activeColor: const Color(0xFF1a73e8),
            inactiveColor: Colors.white12,
            onChanged: (v) { setState(() => _opacity = v); _savePrefs(); },
          )),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBgColor,
          child: Row(children: [
            const Icon(Icons.palette_outlined, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text('Color de fondo', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13)),
            const Spacer(),
            Container(width: 20, height: 20, decoration: BoxDecoration(
                color: _bgColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white30))),
            const SizedBox(width: 6),
            Text('Cambiar', style: GoogleFonts.poppins(
                color: const Color(0xFF1a73e8), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        Text('TIPOGRAFÍA', style: GoogleFonts.poppins(
            color: Colors.white38, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _familyChip('poppins', 'Poppins'),
          _familyChip('montserrat', 'Montserrat'),
          _familyChip('playfair', 'Playfair'),
          _familyChip('cormorant', 'Cormorant'),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _styleChip('regular', 'Regular'),
          _styleChip('italic', 'Cursiva'),
          _styleChip('bold', 'Bold'),
          _styleChip('extrabold', 'Extra Bold'),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickTextColor,
          child: Row(children: [
            const Icon(Icons.format_color_text, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text('Color de texto', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13)),
            const Spacer(),
            Container(width: 20, height: 20, decoration: BoxDecoration(
                color: _textColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white30))),
            const SizedBox(width: 6),
            Text('Cambiar', style: GoogleFonts.poppins(
                color: const Color(0xFF1a73e8), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPiPButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton.icon(
        onPressed: _enterPiP,
        icon: const Icon(Icons.picture_in_picture_alt, size: 20),
        label: Text('Modo flotante', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1a73e8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
    );
  }

  void _pickBgColor() {
    Color temp = _bgColor;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1e1e2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Color de fondo', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(child: BlockPicker(
        pickerColor: _bgColor,
        onColorChanged: (c) => temp = c,
        availableColors: const [
          Color(0xFF1a1a2e), Color(0xFF0d1117), Color(0xFF16213e),
          Color(0xFF0f3460), Color(0xFF1b4332), Color(0xFF370617),
          Color(0xFF240046), Color(0xFF212529), Color(0xFF003049),
          Color(0xFF023e8a), Color(0xFF2d6a4f), Color(0xFF6a040f),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(
                color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a73e8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () {
            setState(() => _bgColor = temp);
            _savePrefs();
            Navigator.pop(context);
          },
          child: Text('Aplicar', style: GoogleFonts.poppins(
              color: Colors.white)),
        ),
      ],
    ));
  }

  void _pickTextColor() {
    Color temp = _textColor;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1e1e2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Color de texto', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(child: ColorPicker(
        pickerColor: _textColor,
        onColorChanged: (c) => temp = c,
        enableAlpha: false,
        labelTypes: const [],
        pickerAreaHeightPercent: 0.7,
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(
                color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a73e8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () {
            setState(() => _textColor = temp);
            _savePrefs();
            Navigator.pop(context);
          },
          child: Text('Aplicar', style: GoogleFonts.poppins(
              color: Colors.white)),
        ),
      ],
    ));
  }

  Widget _familyChip(String key, String label) {
    final sel = _fontFamily == key;
    final c = sel ? const Color(0xFF1a73e8) : Colors.white60;
    TextStyle ts;
    switch (key) {
      case 'montserrat': ts = GoogleFonts.montserrat(fontSize: 12, color: c, fontWeight: FontWeight.w600); break;
      case 'playfair':   ts = GoogleFonts.playfairDisplay(fontSize: 12, color: c, fontWeight: FontWeight.w600); break;
      case 'cormorant':  ts = GoogleFonts.cormorantGaramond(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      default:           ts = GoogleFonts.poppins(fontSize: 12, color: c, fontWeight: FontWeight.w600);
    }
    return GestureDetector(
      onTap: () { setState(() => _fontFamily = key); _savePrefs(); },
      child: _Chip(selected: sel, child: Text(label, style: ts)),
    );
  }

  Widget _styleChip(String key, String label) {
    final sel = _fontStyle == key;
    final w = key == 'bold' ? FontWeight.w700
        : key == 'extrabold' ? FontWeight.w800 : FontWeight.w400;
    final fi = key == 'italic' ? FontStyle.italic : FontStyle.normal;
    return GestureDetector(
      onTap: () { setState(() => _fontStyle = key); _savePrefs(); },
      child: _Chip(selected: sel, child: Text(label,
          style: GoogleFonts.poppins(fontSize: 12,
              color: sel ? const Color(0xFF1a73e8) : Colors.white60,
              fontWeight: w, fontStyle: fi))),
    );
  }
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
        height: 48, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled ? color.withOpacity(0.55) : Colors.white12),
        ),
        child: Text(label, style: GoogleFonts.poppins(
            color: enabled ? color : Colors.white24,
            fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 0.3)),
      ),
    );
  }
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
