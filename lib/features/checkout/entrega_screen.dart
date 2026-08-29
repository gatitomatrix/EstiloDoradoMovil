// lib/features/checkout/entrega_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/checkout_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/services/ubigeo_service.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/widgets/address_map_preview.dart';
import 'interactive_map_screen.dart';

const _gold = Color(0xFFD4AF37);

class EntregaScreen extends StatefulWidget {
  const EntregaScreen({super.key});

  @override
  State<EntregaScreen> createState() => _EntregaScreenState();
}

class _EntregaScreenState extends State<EntregaScreen> {
  final _ubigeo = UbigeoService();
  final _geo = GeocodingService();

  bool _showAddressSheet = false;
  bool _stepMap = false;
  bool _loadingGeo = false;

  List<String> _deps = [];
  List<String> _provs = [];
  List<String> _dists = [];

  String? _dep;
  String? _prov;
  String? _dist;
  final _viaCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _ubigeo.getDepartamentos().then((d) {
      if (mounted) setState(() => _deps = d);
    });
  }

  @override
  void dispose() {
    _viaCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  void _pickStore(CheckoutProvider checkout) {
    checkout.setStorePickup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retiro en tienda seleccionado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openExpress() {
    setState(() {
      _showAddressSheet = true;
      _stepMap = false;
    });
  }

  Future<void> _onDepChanged(String? v) async {
    setState(() {
      _dep = v;
      _prov = null;
      _dist = null;
      _provs = [];
      _dists = [];
    });
    if (v != null && v.isNotEmpty) {
      final p = await _ubigeo.getProvincias(v);
      if (mounted) setState(() => _provs = p);
    }
  }

  Future<void> _onProvChanged(String? v) async {
    setState(() {
      _prov = v;
      _dist = null;
      _dists = [];
    });
    if (_dep != null && v != null && v.isNotEmpty) {
      final d = await _ubigeo.getDistritos(_dep!, v);
      if (mounted) setState(() => _dists = d);
    }
  }

  Future<void> _openInteractiveMap() async {
    if (_lat == null || _lng == null) return;
    final q = [
      _viaCtrl.text.trim(),
      _numCtrl.text.trim(),
      _dist,
      _prov,
      _dep,
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final result = await Navigator.of(context).push<InteractiveMapResult>(
      MaterialPageRoute(
        builder: (_) => InteractiveMapScreen(
          initialLat: _lat!,
          initialLng: _lng!,
          initialQuery: q,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _lat = result.lat;
      _lng = result.lng;
    });

    // Intentar rellenar vía/número desde reverse
    final rev = await _geo.reverseAddress(result.lat, result.lng);
    if (!mounted) return;
    if (rev != null) {
      setState(() {
        if ((rev['via'] ?? '').isNotEmpty) _viaCtrl.text = rev['via']!;
        if ((rev['numero'] ?? '').isNotEmpty) _numCtrl.text = rev['numero']!;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ubicación actualizada en el mapa'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _continuarDireccion() async {
    if (_dep == null ||
        _prov == null ||
        _dist == null ||
        _viaCtrl.text.trim().isEmpty ||
        _numCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos de dirección')),
      );
      return;
    }
    setState(() => _loadingGeo = true);
    final q = [
      _viaCtrl.text.trim(),
      _numCtrl.text.trim(),
      _dist,
      _prov,
      _dep,
      'Perú',
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final res = await _geo.searchAddress(q);
    // Fallback Huancayo
    _lat = res?.lat ?? -12.06866;
    _lng = res?.lon ?? -75.21027;

    final rev = await _geo.reverseAddress(_lat!, _lng!);
    if (rev != null) {
      if ((rev['via'] ?? '').isNotEmpty) _viaCtrl.text = rev['via']!;
      if ((rev['numero'] ?? '').isNotEmpty) _numCtrl.text = rev['numero']!;
    }

    if (mounted) {
      setState(() {
        _loadingGeo = false;
        _stepMap = true;
      });
    }
  }

  void _confirmarYGuardar(CheckoutProvider checkout) {
    final addr = DeliveryAddress(
      departamento: _dep!,
      provincia: _prov!,
      distrito: _dist!,
      via: _viaCtrl.text.trim(),
      numero: _numCtrl.text.trim().isEmpty ? '0' : _numCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
    );
    checkout.setExpress(addr);
    setState(() => _showAddressSheet = false);
    context.push('/confirmar-entrega');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final subtotal = cart.subtotal;
    final total = checkout.totalWith(subtotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (cart.items.isEmpty) {
              context.go('/home');
            } else {
              context.go('/cart');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Inicio', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu carrito está vacío',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Si acabas de pagar, revisa Mis compras o el detalle del pedido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/mis-compras'),
                      style: ElevatedButton.styleFrom(backgroundColor: _gold),
                      child: const Text('Ir a Mis compras'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Seguir comprando'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Timeline(step: 2),
              const SizedBox(height: 8),
              Text(
                'Elige un tipo de entrega',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _DeliveryOption(
                icon: Icons.storefront_outlined,
                title: 'Retira tu pedido en tienda',
                subtitle:
                    'Haz tu retiro en tienda de forma rápida. Si pagas con Culqi obtienes comprobante electrónico.',
                selected: checkout.mode == DeliveryMode.storePickup,
                onTap: () => _pickStore(checkout),
              ),
              const SizedBox(height: 10),
              _DeliveryOption(
                icon: Icons.local_shipping_outlined,
                title: 'Envío Express',
                subtitle: 'Ingresa tu dirección para conocer disponibilidad',
                selected: checkout.mode == DeliveryMode.express,
                onTap: _openExpress,
              ),
              if (checkout.mode == DeliveryMode.express &&
                  checkout.address != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: _gold),
                    title: const Text('Dirección'),
                    subtitle: Text(checkout.address!.display),
                    trailing: TextButton(
                      onPressed: _openExpress,
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _SummaryCard(
                subtotal: subtotal,
                fee: checkout.fee,
                discount: checkout.discount,
                total: total,
                enabled: checkout.canPay,
                buttonLabel: checkout.mode == DeliveryMode.express
                    ? 'Continuar'
                    : 'Ir a pagar',
                onPressed: () {
                  if (checkout.mode == DeliveryMode.express) {
                    context.push('/confirmar-entrega');
                  } else {
                    context.push('/pago');
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                '¿Necesitas ayuda? +51 904 811 627',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          if (_showAddressSheet) _buildAddressSheet(checkout),
        ],
      ),
    );
  }

  Widget _buildAddressSheet(CheckoutProvider checkout) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _stepMap
                              ? 'Confirma tu dirección'
                              : 'Ingresa tu dirección',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showAddressSheet = false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _stepMap
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_lat != null && _lng != null) ...[
                                AddressMapPreview(lat: _lat!, lng: _lng!),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _openInteractiveMap,
                                    icon: const Icon(Icons.explore),
                                    label: const Text(
                                      'Mover / buscar en el mapa',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(color: _gold, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Ubicación aproximada por geocodificación. '
                                  'Pulsa «Mover / buscar en el mapa» para navegar, hacer zoom '
                                  'y tocar el punto exacto, o busca por texto (calle, avenida…).',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_viaCtrl.text} ${_numCtrl.text}\n$_dist, $_prov, $_dep',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (_lat != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Coords: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _stepMap = false),
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _dropdown(
                                'Departamento',
                                _dep,
                                _deps,
                                _onDepChanged,
                              ),
                              const SizedBox(height: 10),
                              _dropdown(
                                'Provincia',
                                _prov,
                                _provs,
                                _onProvChanged,
                              ),
                              const SizedBox(height: 10),
                              _dropdown(
                                'Distrito',
                                _dist,
                                _dists,
                                (v) => setState(() => _dist = v),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _viaCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Avenida / Calle / Jirón',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _numCtrl,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  // Número de puerta puede ser "123-A"; permite dígitos y guión/letras cortas
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9A-Za-záéíóúÁÉÍÓÚñÑ\-/]'),
                                  ),
                                  LengthLimitingTextInputFormatter(12),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Número',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ej. 123 o 123-A',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loadingGeo
                          ? null
                          : () {
                              if (_stepMap) {
                                _confirmarYGuardar(checkout);
                              } else {
                                _continuarDireccion();
                              }
                            },
                      child: _loadingGeo
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _stepMap
                                  ? 'Confirmar y guardar'
                                  : 'Confirmar dirección',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value != null && items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _gold.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _gold : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _gold.withValues(alpha: 0.15),
                child: Icon(icon, color: _gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: _gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double fee;
  final double discount;
  final double total;
  final bool enabled;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _SummaryCard({
    required this.subtotal,
    required this.fee,
    required this.discount,
    required this.total,
    required this.enabled,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de la compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _row('Productos', 'S/ ${subtotal.toStringAsFixed(2)}'),
            _row('Descuentos', '- S/ ${discount.toStringAsFixed(2)}', green: true),
            _row('Entregas', 'S/ ${fee.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _row('Total', 'S/ ${total.toStringAsFixed(2)}', bold: true),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: enabled ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String r, {bool green = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            r,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: green ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int step;
  const _Timeline({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget chip(int n, String label) {
      final active = n <= step;
      return Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: active ? _gold : Colors.grey.shade300,
            child: Text('$n', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? Colors.black87 : Colors.grey, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip(1, 'Carro'),
          Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.grey.shade300)),
          chip(2, 'Entrega'),
          Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.grey.shade300)),
          chip(3, 'Pago'),
        ],
      ),
    );
  }
}
