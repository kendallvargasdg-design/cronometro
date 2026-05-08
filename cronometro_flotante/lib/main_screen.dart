import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  Color _bgColor = const Color(0xFF1a1a2e);
  double _opacity = 0.92;
  bool _overlayActive = false;
  String _fontFamily = 'poppins';
  String _fontStyle = 'regular';
  Color _textColor = Colors.white;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkOverlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _checkOverlay();
  }

  Future<void> _checkOverlay() async {
    final active = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _overlayActive = active);
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bg_color',       _bgColor.value);
    await p.setDouble('opacity',     _opacity);
    await p.setString('font_family', _fontFamily);
    await p.setString('font_style',  _fontStyle);
    await p.setInt('text_color',     _textColor.value);
  }

  Map<String, dynamic> get _overlayData => {
    'bg_color':    _bgColor.value,
    'opacity':     _opacity,
    'font_family': _fontFamily,
    'font_style':  _fontStyle,
    'text_color':  _textColor.value,
  };

  Future<void> _sendToOverlay() async {
    if (_overlayActive) await FlutterOverlayWindow.shareData(_overlayData);
  }

  Future<void> _toggleOverlay() async {
    setState(() => _errorMsg = null);
    try {
      final hasPerm = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPerm) {
        final granted = await FlutterOverlayWindow.requestPermission();
        if (granted != true) {
          if (mounted) {
            setState(() => _errorMsg =
                'Debes activar "Mostrar sobre otras apps" para esta app en Configuración del sistema.');
          }
          return;
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        if (mounted) setState(() => _overlayActive = false);
      } else {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: 'Cronómetro Flotante',
          overlayContent: 'Cronómetro activo',
          flag: OverlayFlag.focusPointer,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 460,
          width: 320,
          startPosition: const OverlayPosition(0, -80),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        await FlutterOverlayWindow.shareData(_overlayData);
        if (mounted) setState(() => _overlayActive = true);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error al abrir el flotante: $e');
    }
  }

  void _pickBgColor() {
    Color temp = _bgColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Color de fondo', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a73e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { setState(() => _bgColor = temp); _savePrefs(); _sendToOverlay(); Navigator.pop(context); },
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
        title: Text('Color de texto', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a73e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { setState(() => _textColor = temp); _savePrefs(); _sendToOverlay(); Navigator.pop(context); },
            child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  TextStyle _previewTimeStyle() => _buildFontStyle(_fontFamily, _fontStyle, 44, _textColor, letterSpacing: 2);

  static TextStyle _buildFontStyle(String family, String style, double size, Color color, {double? letterSpacing}) {
    final weight = style == 'bold' ? FontWeight.w700 : style == 'extrabold' ? FontWeight.w800 : FontWeight.w400;
    final fStyle = style == 'italic' ? FontStyle.italic : FontStyle.normal;
    switch (family) {
      case 'montserrat': return GoogleFonts.montserrat(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: color, letterSpacing: letterSpacing);
      case 'playfair': return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: color, letterSpacing: letterSpacing);
      case 'cormorant': return GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: color, letterSpacing: letterSpacing);
      default: return GoogleFonts.poppins(fontSize: size, fontWeight: weight, fontStyle: fStyle, color: color, letterSpacing: letterSpacing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1a73e8).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.timer, color: Color(0xFF1a73e8), size: 26),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cronómetro', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Flotante', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1a73e8), height: 0.9)),
                ]),
              ]),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgColor.withOpacity(_opacity),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                  ),
                  child: Column(children: [
                    Text('VISTA PREVIA', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Text('00:00.00', style: _previewTimeStyle()),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _PreviewBtn('▶  INICIAR', const Color(0xFF1a73e8)),
                      const SizedBox(width: 6),
                      _PreviewBtn('LAP', const Color(0xFFfbbc04)),
                      const SizedBox(width: 6),
                      _PreviewBtn('↺  RESET', const Color(0xFFea4335)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel('Apariencia'),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.palette_outlined, title: 'Color de fondo',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle, border: Border.all(color: Colors.white30))),
                  const SizedBox(width: 8),
                  Text('Cambiar', style: GoogleFonts.poppins(color: const Color(0xFF1a73e8), fontSize: 13)),
                ]),
                onTap: _pickBgColor,
              ),
              const SizedBox(height: 8),
              _SettingTile(
                icon: Icons.opacity, title: 'Transparencia',
                trailing: SizedBox(
                  width: 130,
                  child: Slider(
                    value: _opacity, min: 0.3, max: 1.0, divisions: 7,
                    activeColor: const Color(0xFF1a73e8), inactiveColor: Colors.white12,
                    onChanged: (v) { setState(() => _opacity = v); _savePrefs(); _sendToOverlay(); },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Tipografía'),
              const SizedBox(height: 12),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Familia', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _buildFamilyChip('poppins', 'Poppins'),
                  _buildFamilyChip('montserrat', 'Montserrat'),
                  _buildFamilyChip('playfair', 'Playfair Display'),
                  _buildFamilyChip('cormorant', 'Cormorant'),
                ]),
              ])),
              const SizedBox(height: 8),
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Estilo', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _buildStyleChip('regular', 'Regular'),
                  _buildStyleChip('italic', 'Cursiva'),
                  _buildStyleChip('bold', 'Bold'),
                  _buildStyleChip('extrabold', 'Extra Bold'),
                ]),
              ])),
              const SizedBox(height: 8),
              _SettingTile(
                icon: Icons.format_color_text, title: 'Color de texto',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: _textColor, shape: BoxShape.circle, border: Border.all(color: Colors.white30))),
                  const SizedBox(width: 8),
                  Text('Cambiar', style: GoogleFonts.poppins(color: const Color(0xFF1a73e8), fontSize: 13)),
                ]),
                onTap: _pickTextColor,
              ),
              const SizedBox(height: 28),
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMsg!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12))),
                  ]),
                ),
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  onPressed: _toggleOverlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _overlayActive ? const Color(0xFFea4335) : const Color(0xFF1a73e8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    _overlayActive ? '✕  Cerrar cronómetro' : '▶  Mostrar cronómetro flotante',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildFamilyChip(String key, String label) {
    final sel = _fontFamily == key;
    final c = sel ? const Color(0xFF1a73e8) : Colors.white60;
    TextStyle ts;
    switch (key) {
      case 'montserrat': ts = GoogleFonts.montserrat(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      case 'playfair': ts = GoogleFonts.playfairDisplay(fontSize: 13, color: c, fontWeight: FontWeight.w600); break;
      case 'cormorant': ts = GoogleFonts.cormorantGaramond(fontSize: 14, color: c, fontWeight: FontWeight.w600); break;
      default: ts = GoogleFonts.poppins(fontSize: 13, color: c, fontWeight: FontWeight.w600);
    }
    return GestureDetector(
      onTap: () { setState(() => _fontFamily = key); _savePrefs(); _sendToOverlay(); },
      child: _Chip(selected: sel, child: Text(label, style: ts)),
    );
  }

  Widget _buildStyleChip(String key, String label) {
    final sel = _fontStyle == key;
    final w = key == 'bold' ? FontWeight.w700 : key == 'extrabold' ? FontWeight.w800 : FontWeight.w400;
    final fi = key == 'italic' ? FontStyle.italic : FontStyle.normal;
    return GestureDetector(
      onTap: () { setState(() => _fontStyle = key); _savePrefs(); _sendToOverlay(); },
      child: _Chip(
        selected: sel,
        child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: sel ? const Color(0xFF1a73e8) : Colors.white60, fontWeight: w, fontStyle: fi)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF1a73e8).withOpacity(0.18) : Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: selected ? const Color(0xFF1a73e8) : Colors.white12),
    ),
    child: child,
  );
}

class _PreviewBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _PreviewBtn(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.4))),
    child: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
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
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          const Spacer(),
          trailing,
        ]),
      ),
    ),
  );
}
