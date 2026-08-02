// lib/core/widgets/address_map_preview.dart
// Vista de mapa con tiles OpenStreetMap (sin API key).
// staticmap.openstreetmap.de suele fallar; los tiles directos son más estables.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _gold = Color(0xFFD4AF37);

class AddressMapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final int zoom;

  const AddressMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 16,
  });

  /// Convierte lat/lng a índice de tile OSM.
  static ({int x, int y}) _tile(double lat, double lon, int z) {
    final n = math.pow(2.0, z).toDouble();
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n)
        .floor();
    return (x: x, y: y);
  }

  /// Fracción dentro del tile (0–1) para posicionar el pin.
  static ({double fx, double fy}) _frac(double lat, double lon, int z) {
    final n = math.pow(2.0, z).toDouble();
    final xf = (lon + 180.0) / 360.0 * n;
    final latRad = lat * math.pi / 180.0;
    final yf = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        n;
    return (fx: xf - xf.floor(), fy: yf - yf.floor());
  }

  static String _tileUrl(int z, int x, int y) {
    // Wikimedia y OSM.org; User-Agent se envía en headers.
    return 'https://tile.openstreetmap.org/$z/$x/$y.png';
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile(lat, lng, zoom);
    final frac = _frac(lat, lng, zoom);
    final url = _tileUrl(zoom, tile.x, tile.y);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo suave
            Container(color: const Color(0xFFE8EEF2)),
            Image.network(
              url,
              fit: BoxFit.cover,
              headers: const {
                // OSM pide un User-Agent identificable
                'User-Agent': 'EstiloDoradoApp/1.0 (checkout; contacto@estilodorado.pe)',
                'Accept': 'image/png,image/*;q=0.8,*/*;q=0.5',
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
                );
              },
              errorBuilder: (_, __, ___) {
                // Fallback visual (no depende de red externa)
                return CustomPaint(
                  painter: _GridMapPainter(lat: lat, lng: lng),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 40, color: Colors.blueGrey),
                        SizedBox(height: 6),
                        Text(
                          'Vista esquemática',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          'Usa Google Maps para el mapa completo',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Pin centrado en la fracción del tile
            LayoutBuilder(
              builder: (context, constraints) {
                final px = frac.fx * constraints.maxWidth;
                final py = frac.fy * constraints.maxHeight;
                return Stack(
                  children: [
                    Positioned(
                      left: px - 18,
                      top: py - 36,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 36,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openGoogleMaps,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, size: 16, color: _gold),
                        SizedBox(width: 6),
                        Text(
                          'Google Maps',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapa esquemático local (sin red) con cruz en el centro.
class _GridMapPainter extends CustomPainter {
  final double lat;
  final double lng;

  _GridMapPainter({required this.lat, required this.lng});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE3EAF0);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFFC5D0DA)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // “calles” diagonales suaves
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.45),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.55, size.height),
      road,
    );

    final pin = Paint()..color = Colors.red;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 7, pin);
    canvas.drawCircle(c, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GridMapPainter oldDelegate) =>
      oldDelegate.lat != lat || oldDelegate.lng != lng;
}
