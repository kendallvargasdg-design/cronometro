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
        _bgColor = Color(p.getInt('bg_color') ?? 0xFF1a1a2e);
        _opacity = p.getDouble('opacity') ?? 0.92;
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
    await p.setInt('bg_color', _bgColor.value);
    await p.setDouble('opacity', _opacity);
  }

  Future<void> _toggleOverlay() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      final granted = await FlutterOverlayWindow.requestPermission();
      if (granted != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Debes conceder el permiso para mostrar sobre otras apps'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
    }

    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _overlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Cronómetro',
        overlayContent: 'Toca para abrir',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 480,
        width: 340,
        startPosition: const OverlayPosition(0, -100),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      await FlutterOverlayWindow.shareData({
        'bg_color': _bgColor.value,
        'opacity': _opacity,
      });
      setState(() => _overlayActive = true);
    }
  }

  void _pickColor() {
    Color temp = _bgColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Color de fondo',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a73e8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _bgColor = temp);
              _savePrefs();
              if (_overlayActive) {
                FlutterOverlayWindow.shareData({
                  'bg_color': temp.value,
                  'opacity': _opacity,
                });
              }
              Navigator.pop(context);
            },
            child: Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
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

              // ── Título ──────────────────────────────────────
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
                  Text('Cronómetro', style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                  )),
                  Text('Flotante', style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1a73e8), height: 0.9,
                  )),
                ]),
              ]),

              const SizedBox(height: 36),

              // ── Vista previa ────────────────────────────────
              Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgColor.withOpacity(_opacity),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
                    ],
                  ),
                  child: Column(children: [
                    Text('VISTA PREVIA', style: GoogleFonts.poppins(
                      color: Colors.white38, fontSize: 9, letterSpacing: 2,
                    )),
                    const SizedBox(height: 10),
                    Text('00:00.00', style: GoogleFonts.poppins(
                      fontSize: 44, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 2,
                    )),
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

              const SizedBox(height: 36),

              // ── Personalización ─────────────────────────────
              Text('Personalización', style: GoogleFonts.poppins(
                color: Colors.white38, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5,
              )),
              const SizedBox(height: 12),

              // Color
              _SettingTile(
                icon: Icons.palette_outlined,
                title: 'Color de fondo',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Cambiar', style: GoogleFonts.poppins(
                    color: const Color(0xFF1a73e8), fontSize: 13,
                  )),
                ]),
                onTap: _pickColor,
              ),
              const SizedBox(height: 8),

              // Transparencia
              _SettingTile(
                icon: Icons.opacity,
                title: 'Transparencia',
                trailing: SizedBox(
                  width: 130,
                  child: Slider(
                    value: _opacity, min: 0.3, max: 1.0, divisions: 7,
                    activeColor: const Color(0xFF1a73e8),
                    inactiveColor: Colors.white12,
                    onChanged: (v) {
                      setState(() => _opacity = v);
                      _savePrefs();
                      if (_overlayActive) {
                        FlutterOverlayWindow.shareData({'opacity': v, 'bg_color': _bgColor.value});
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Instrucciones rápidas ───────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cómo usar', style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 10),
                  _Tip('▶', 'Toca "Mostrar cronómetro" para lanzar la ventana flotante'),
                  _Tip('☰', 'En la barra superior del flotante: ajustes y lista de laps'),
                  _Tip('✦', 'Arrastra el cronómetro a donde quieras en la pantalla'),
                  _Tip('✕', 'Ciérralo con la X o desde esta pantalla'),
                ]),
              ),

              const SizedBox(height: 32),

              // ── Botón principal ─────────────────────────────
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  onPressed: _toggleOverlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _overlayActive
                        ? const Color(0xFFea4335)
                        : const Color(0xFF1a73e8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _overlayActive
                        ? '✕  Cerrar cronómetro'
                        : '▶  Mostrar cronómetro flotante',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                    ),
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
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PreviewBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _PreviewBtn(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: GoogleFonts.poppins(
      color: color, fontSize: 10, fontWeight: FontWeight.w700,
    )),
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

class _Tip extends StatelessWidget {
  final String icon;
  final String text;
  const _Tip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 20, child: Text(icon, style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 12))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))),
    ]),
  );
}
