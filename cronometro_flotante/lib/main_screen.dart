import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
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
  final _floating = Floating();
  final _sw = StopwatchController();

  Color _bgColor    = const Color(0xFF1a1a2e);
  double _opacity   = 0.92;
  String _fontFamily = 'poppins';
  String _fontStyle  = 'regular';
  Color _textColor   = Colors.white;
  bool _showLaps     = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _sw.addListener(() { if (mounted) setState(() {}); });
    _loadPrefs();
  }

  @override
  void dispose() {
    _sw.dispose();
    _floating.dispose();
    super.dispose();
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

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bg_color',       _bgColor.value);
    await p.setDouble('opacity',     _opacity);
    await p.setString('font_family', _fontFamily);
    await p.setString('font_style',  _fontStyle);
    await p.setInt('text_color',     _textColor.value);
  }

  Future<void> _enterPiP() async {
    await _floating.enable(
      ImmediatePiP(aspectRatio: const Rational(16, 9)),
    );
  }

  TextStyle _ts(double size, {double? letterSpacing, Color? color}) {
    final c = color ?? _textColor;
    final weight = _fontStyle == 'bold' ? FontWeight.w700
        : _fontStyle == 'extrabold' ? FontWeight.w800
        : FontWeight.w400;
    final fStyle = _fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
    switch (_fontFamily) {
      case 'montserrat': return GoogleFonts.montserrat(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'playfair':   return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      case 'cormorant':  return GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
      default:           return GoogleFonts.poppins(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: c, letterSpacing: letterSpacing, height: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PiPStatus>(
      stream: _floating.pipStatus,
      builder: (context, snap) {
        if (snap.data == PiPStatus.enabled) return _buildPiP();
        return _buildFull();
      },
    );
  }

  // ── Vista PiP (flotante compacta) ─────────────────────────
  Widget _buildPiP() {
    final full = StopwatchController.format(_sw.elapsed);
    final dot  = full.lastIndexOf('.');
    final main = dot >= 0 ? full.substring(0, dot) : full;
    final frac = dot >= 0 ? full.substring(dot) : '';
    return Material(
      color: _bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(main, style: _ts(22, letterSpacing: 1)),
                Text(frac, style: _ts(13, color: _textColor.withOpacity(0.6))),
              ],
            ),
            Row(children: [
              _PiPBtn(
                _sw.isRunning ? Icons.pause : Icons.play_arrow,
                const Color(0xFF1a73e8),
                _sw.startPause,
              ),
              const SizedBox(width: 8),
              _PiPBtn(Icons.refresh, const Color(0xFFea4335),
                  _sw.hasStarted ? _sw.reset : null),
              const SizedBox(width: 8),
              _PiPBtn(Icons.flag_outlined, const Color(0xFFfbbc04),
                  _sw.hasStarted ? _sw.addLap : null),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Vista completa ────────────────────────────────────────
  Widget _buildFull() {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1a73e8).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.timer, color: Color(0xFF1a73e8), size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cronómetro', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Flotante', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1a73e8), height: 0.9)),
                ]),
                const Spacer(),
                IconButton(
                  icon: Icon(_showSettings ? Icons.settings : Icons.settings_outlined, color: Colors.white54),
                  onPressed: () => setState(() => _showSettings = !_showSettings),
                ),
              ]),
              const SizedBox(height: 24),

              // Cronómetro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: _bgColor.withOpacity(_opacity),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24)],
                ),
                child: Column(children: [
                  // Tiempo
                  Builder(builder: (_) {
                    final full = StopwatchController.format(_sw.elapsed);
                    final dot  = full.lastIndexOf('.');
                    final main = dot >= 0 ? full.substring(0, dot) : full;
                    final frac = dot >= 0 ? full.substring(dot) : '';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(main, style: _ts(54, letterSpacing: 2)),
                        Text(frac, style: _ts(28, letterSpacing: 1, color: _textColor.withOpacity(0.6))),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  // Botones
                  Row(children: [
                    Expanded(flex: 5, child: _ActionBtn(label: _sw.isRunning ? '⏸  PAUSAR' : '▶  INICIAR', color: const Color(0xFF1a73e8), onTap: _sw.startPause)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _ActionBtn(label: 'LAP', color: const Color(0xFFfbbc04), onTap: _sw.hasStarted ? _sw.addLap : null)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _ActionBtn(label: '↺ RESET', color: const Color(0xFFea4335), onTap: _sw.hasStarted ? _sw.reset : null)),
                  ]),
                  // Laps toggle
                  if (_sw.laps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showLaps = !_showLaps),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_showLaps ? Icons.expand_less : Icons.expand_more, color: Colors.white38, size: 18),
                        Text('${_sw.laps.length} vueltas', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                      ]),
                    ),
                    if (_showLaps) _buildLapList(),
                  ],
                ]),
              ),
              const SizedBox(height: 16),

              // Configuración (colapsable)
              if (_showSettings) ...[
                _buildSettings(),
                const SizedBox(height: 16),
              ],

              // Botón flotar
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _enterPiP,
                  icon: const Icon(Icons.picture_in_picture_alt, size: 20),
                  label: Text('Modo flotante', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a73e8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Configuración ────────────────────────────────────────
  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Apariencia', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.palette_outlined, title: 'Color de fondo',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle, border: Border.all(color: Colors.white30))),
            const SizedBox(width: 8),
            Text('Cambiar', style: GoogleFonts.poppins(color: const Color(0xFF1a73e8), fontSize: 13)),
          ]),
          onTap: _pickBgColor,
        ),
        const SizedBox(height: 8),
        _SettingTile(
          icon: Icons.opacity, title: 'Transparencia',
          trailing: SizedBox(width: 120, child: Slider(
            value: _opacity, min: 0.3, max: 1.0, divisions: 7,
            activeColor: const Color(0xFF1a73e8), inactiveColor: Colors.white12,
            onChanged: (v) { setState(() => _opacity = v); _savePrefs(); },
          )),
        ),
        const SizedBox(height: 16),
        Text('Tipografía', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text('Familia', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildFamilyChip('poppins', 'Poppins'),
          _buildFamilyChip('montserrat', 'Montserrat'),
          _buildFamilyChip('playfair', 'Playfair'),
          _buildFamilyChip('cormorant', 'Cormorant'),
        ]),
        const SizedBox(height: 12),
        Text('Estilo', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildStyleChip('regular', 'Regular'),
          _buildStyleChip('italic', 'Cursiva'),
          _buildStyleChip('bold', 'Bold'),
          _buildStyleChip('extrabold', 'Extra Bold'),
        ]),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.format_color_text, title: 'Color de texto',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: _textColor, shape: BoxShape.circle, border: Border.all(color: Colors.white30))),
            const SizedBox(width: 8),
            Text('Cambiar', style: GoogleFonts.poppins(color: const Color(0xFF1a73e8), fontSize: 13)),
          ]),
          onTap: _pickTextColor,
        ),
      ]),
    );
  }

  // ── Lap list ─────────────────────────────────────────────
  Widget _buildLapList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
      child: ListView.separated(
        shrinkWrap: true, physics: const BouncingScrollPhysics(),
        itemCount: _sw.laps.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
        itemBuilder: (_, i) {
          final lap = _sw.laps[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Text('LAP ${lap.number}', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(StopwatchController.format(lap.partial), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text(StopwatchController.format(lap.cumulative), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            ]),
          );
        },
      ),
    );
  }

  // ── Color pickers ────────────────────────────────────────
  void _pickBgColor() {
    Color temp = _bgColor;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1e1e2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Color de fondo', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(child: BlockPicker(
        pickerColor: _bgColor, onColorChanged: (c) => temp = c,
        availableColors: const [
          Color(0xFF1a1a2e), Color(0xFF0d1117), Color(0xFF16213e),
          Color(0xFF0f3460), Color(0xFF1b4332), Color(0xFF370617),
          Color(0xFF240046), Color(0xFF212529), Color(0xFF003049),
          Color(0xFF023e8a), Color(0xFF2d6a4f), Color(0xFF6a040f),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a73e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () { setState(() => _bgColor = temp); _savePrefs(); Navigator.pop(context); },
          child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    ));
  }

  void _pickTextColor() {
    Color temp = _textColor;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1e1e2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Color de texto', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(child: ColorPicker(
        pickerColor: _textColor, onColorChanged: (c) => temp = c,
        enableAlpha: false, labelTypes: const [], pickerAreaHeightPercent: 0.7,
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a73e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () { setState(() => _textColor = temp); _savePrefs(); Navigator.pop(context); },
          child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    ));
  }

  // ── Font chips ───────────────────────────────────────────
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
      child: _Chip(selected: sel, child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: sel ? const Color(0xFF1a73e8) : Colors.white60, fontWeight: w, fontStyle: fi))),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PiPBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _PiPBtn(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? color.withOpacity(0.5) : Colors.white12),
        ),
        child: Icon(icon, color: enabled ? color : Colors.white24, size: 16),
      ),
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
        height: 42, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? color.withOpacity(0.55) : Colors.white12),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: enabled ? color : Colors.white24, fontSize: 11, fontWeight: FontWeight.w700)),
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
      color: selected ? const Color(0xFF1a73e8).withOpacity(0.18) : Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: selected ? const Color(0xFF1a73e8) : Colors.white12),
    ),
    child: child,
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingTile({required this.icon, required this.title, required this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Icon(icon, color: Colors.white54, size: 19),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          const Spacer(),
          trailing,
        ]),
      ),
    ),
  );
}
