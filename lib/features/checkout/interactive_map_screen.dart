// lib/features/checkout/interactive_map_screen.dart
// Mapa: pin al centro, al mover se actualiza la calle (como delivery).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/geocoding_service.dart';

const _gold = Color(0xFFD4AF37);

class InteractiveMapResult {
  final double lat;
  final double lng;
  final String? via;
  final String? numero;
  final String? display;

  const InteractiveMapResult({
    required this.lat,
    required this.lng,
    this.via,
    this.numero,
    this.display,
  });
}

class InteractiveMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? initialQuery;

  const InteractiveMapScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialQuery,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final _geo = GeocodingService();
  final _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();
  late LatLng _center;
  bool _searching = false;
  bool _reverseLoading = false;
  bool _ignoreMove = false;
  String? _hint;
  String? _viaRev;
  String? _numRev;
  Timer? _moveDebounce;
  int _revGen = 0;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.initialLat, widget.initialLng);
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _reverse(_center));
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverse(LatLng p) async {
    final gen = ++_revGen;
    setState(() {
      _reverseLoading = true;
      _center = p;
    });
    final rev = await _geo.reverseAddress(p.latitude, p.longitude);
    if (!mounted || gen != _revGen) return;
    setState(() {
      _reverseLoading = false;
      if (rev != null) {
        final via = (rev['via'] ?? '').trim();
        final num = (rev['numero'] ?? '').trim();
        final display = (rev['display'] ?? '').trim();
        if (via.isNotEmpty) _viaRev = via;
        if (num.isNotEmpty) _numRev = num;
        if (display.isNotEmpty) {
          _hint = display;
        } else if ((_viaRev ?? '').isNotEmpty) {
          _hint = '${_viaRev!} ${_numRev ?? ''}'.trim();
        }
      }
    });
  }

  void _onMoveEnd(LatLng c) {
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _ignoreMove) return;
      _reverse(c);
    });
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos 3 caracteres para buscar')),
      );
      return;
    }
    setState(() => _searching = true);
    final query = q.contains('Perú') || q.toLowerCase().contains('peru') ? q : '$q, Perú';
    final res = await _geo.searchAddress(query, lat: _center.latitude, lon: _center.longitude);
    if (!mounted) return;
    setState(() => _searching = false);
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró esa dirección. Prueba con más detalle.')),
      );
      return;
    }
    final p = LatLng(res.lat, res.lon);
    _ignoreMove = true;
    _mapCtrl.move(p, 18);
    await _reverse(p);
    _ignoreMove = false;
  }

  void _confirm() {
    LatLng p = _center;
    try {
      p = _mapCtrl.camera.center;
    } catch (_) {}
    Navigator.of(context).pop(
      InteractiveMapResult(
        lat: p.latitude,
        lng: p.longitude,
        via: _viaRev,
        numero: _numRev,
        display: _hint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubica tu dirección'),
        backgroundColor: _gold,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Buscar calle, avenida, lugar…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Buscar'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Mueve el mapa: la flecha del centro marca el punto y la calle se actualiza sola.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 17,
                    minZoom: 5,
                    maxZoom: 19,
                    onMapEvent: (evt) {
                      if (evt is MapEventMoveEnd) {
                        _onMoveEnd(evt.camera.center);
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.estilodorado.app_movil_estilo_dorado',
                      maxZoom: 19,
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: Icon(Icons.location_on, color: Colors.red, size: 52),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: Column(
                    children: [
                      _zoomBtn(Icons.add, () {
                        _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
                      }),
                      const SizedBox(height: 8),
                      _zoomBtn(Icons.remove, () {
                        _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_reverseLoading)
                      const LinearProgressIndicator(color: _gold, minHeight: 2)
                    else if (_hint != null)
                      Text(
                        _hint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _confirm,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Usar esta ubicación',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}
