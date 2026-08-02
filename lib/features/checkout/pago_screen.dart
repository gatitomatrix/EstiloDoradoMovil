// lib/features/checkout/pago_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/checkout_models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/checkout_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/services/order_service.dart';
import '../../core/services/ubigeo_service.dart';
import '../../core/utils/input_formatters.dart';

const _gold = Color(0xFFD4AF37);

class PagoScreen extends StatefulWidget {
  const PagoScreen({super.key});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _order = OrderService();
  final _ubigeo = UbigeoService();
  bool _submitting = false;

  // Yape form (UI; Culqi real requiere SDK nativo)
  final _yapePhone = TextEditingController(text: '+51 9');
  final _yapeCode = TextEditingController();

  // Card form
  final _cardNumber = TextEditingController();
  final _cardExp = TextEditingController();
  final _cardCvv = TextEditingController();

  // Boleta / Factura
  final _bolNombres = TextEditingController();
  final _bolDni = TextEditingController();
  final _bolDir = TextEditingController();
  String? _bolDep, _bolProv, _bolDist;

  final _facRuc = TextEditingController();
  final _facRazon = TextEditingController();
  final _facDir = TextEditingController();
  String? _facDep, _facProv, _facDist;

  List<String> _deps = [];
  List<String> _provs = [];
  List<String> _dists = [];

  String? _method; // yape | tarjeta | efectivo

  @override
  void initState() {
    super.initState();
    final pay = context.read<PaymentProvider>();
    pay.clearAll();
    _ubigeo.getDepartamentos().then((d) {
      if (mounted) setState(() => _deps = d);
    });
  }

  @override
  void dispose() {
    _yapePhone.dispose();
    _yapeCode.dispose();
    _cardNumber.dispose();
    _cardExp.dispose();
    _cardCvv.dispose();
    _bolNombres.dispose();
    _bolDni.dispose();
    _bolDir.dispose();
    _facRuc.dispose();
    _facRazon.dispose();
    _facDir.dispose();
    super.dispose();
  }

  Future<void> _loadProvs(String dep, {required bool forFactura}) async {
    final p = await _ubigeo.getProvincias(dep);
    if (!mounted) return;
    setState(() {
      _provs = p;
      _dists = [];
      if (forFactura) {
        _facProv = null;
        _facDist = null;
      } else {
        _bolProv = null;
        _bolDist = null;
      }
    });
  }

  Future<void> _loadDists(String dep, String prov, {required bool forFactura}) async {
    final d = await _ubigeo.getDistritos(dep, prov);
    if (!mounted) return;
    setState(() {
      _dists = d;
      if (forFactura) {
        _facDist = null;
      } else {
        _bolDist = null;
      }
    });
  }

  List<ConfirmarItem> _itemsFromCart(CartProvider cart) => cart.items
      .map((i) => ConfirmarItem(idProducto: i.id, cantidad: i.cantidad))
      .toList();

  Future<void> _pagarEfectivo() async {
    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    if (!checkout.canCash) {
      _toast('El pago en efectivo solo está disponible para retiro en tienda.');
      return;
    }
    if (cart.items.isEmpty) {
      _toast('Tu carrito está vacío.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await _order.confirmar(
        formaPago: 'efectivo',
        direccionEntrega: checkout.direccionEntrega,
        items: _itemsFromCart(cart),
      );
      cart.clear();
      checkout.reset();
      if (!mounted) return;
      context.go('/resumen/${res.idPedido}', extra: {'ventaOk': true});
    } catch (e) {
      _toast('No se pudo registrar tu pedido en efectivo.');
      debugPrint('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pagarCulqiLike(String method) async {
    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    final pay = context.read<PaymentProvider>();
    final auth = context.read<AuthProvider>();

    if (cart.items.isEmpty) {
      _toast('Tu carrito está vacío.');
      return;
    }

    // Validar UI del método
    if (method == 'yape') {
      final phoneOk = RegExp(r'^\+51 9\d{8}$').hasMatch(_yapePhone.text.trim());
      final codeOk = RegExp(r'^\d{6}$').hasMatch(_yapeCode.text.trim());
      if (!phoneOk || !codeOk) {
        _toast('Yape: teléfono (+51 9xxxxxxxx) y código de 6 dígitos.');
        return;
      }
    } else if (method == 'tarjeta') {
      final num = _cardNumber.text.replaceAll(' ', '');
      if (num.length != 16 ||
          !RegExp(r'^\d{2}/\d{2}$').hasMatch(_cardExp.text) ||
          !RegExp(r'^\d{3}$').hasMatch(_cardCvv.text)) {
        _toast('Completa los datos de la tarjeta correctamente.');
        return;
      }
    }

    // Comprobante obligatorio para tarjeta/yape
    if (!pay.hasDoc) {
      final tipo = await _pickDocTipo();
      if (tipo == null) return;
      final ok = await _openDocForm(tipo);
      if (!ok) return;
    }

    final tipo = pay.selectedDoc ?? (pay.invoice != null ? 'FA' : 'BO');
    setState(() => _submitting = true);
    try {
      // En móvil, sin Culqi SDK nativo usamos un id de prueba trazable.
      // Cuando integres Culqi nativo, reemplaza por el token/order real.
      final culqiId = method == 'yape'
          ? 'ype_mobile_${DateTime.now().millisecondsSinceEpoch}'
          : 'tok_mobile_${DateTime.now().millisecondsSinceEpoch}';

      final res = await _order.confirmar(
        formaPago: method,
        culqiId: culqiId,
        direccionEntrega: checkout.direccionEntrega,
        items: _itemsFromCart(cart),
        comprobante: tipo,
        factura: tipo == 'FA' ? pay.invoice : null,
        boleta: tipo == 'BO' ? pay.boleta : null,
      );

      cart.clear();
      checkout.reset();
      pay.clearAll();
      if (!mounted) return;
      context.go(
        '/resumen/${res.idPedido}',
        extra: {
          'ventaOk': true,
          'comprobante': res.comprobante,
          'email': auth.user?['email'],
        },
      );
    } catch (e) {
      _toast('No se pudo confirmar el pedido. Revisa datos o conexión al API.');
      debugPrint('confirmar error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String?> _pickDocTipo() async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tipo de comprobante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para pagos con Yape o tarjeta debes emitir boleta o factura.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: _gold),
                title: const Text('Boleta'),
                onTap: () => Navigator.pop(ctx, 'BO'),
              ),
              ListTile(
                leading: const Icon(Icons.business, color: _gold),
                title: const Text('Factura'),
                onTap: () => Navigator.pop(ctx, 'FA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _openDocForm(String tipo) async {
    final pay = context.read<PaymentProvider>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo == 'FA' ? 'Datos de factura' : 'Datos de boleta',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (tipo == 'BO') ...[
                      TextField(
                        controller: _bolNombres,
                        decoration: const InputDecoration(
                          labelText: 'Nombres y apellidos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bolDni,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsMax(8),
                        decoration: const InputDecoration(
                          labelText: 'DNI',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bolDir,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dd('Departamento', _bolDep, _deps, (v) async {
                        setModal(() => _bolDep = v);
                        if (v != null) await _loadProvs(v, forFactura: false);
                        setModal(() {});
                      }),
                      const SizedBox(height: 10),
                      _dd('Provincia', _bolProv, _provs, (v) async {
                        setModal(() => _bolProv = v);
                        if (_bolDep != null && v != null) {
                          await _loadDists(_bolDep!, v, forFactura: false);
                        }
                        setModal(() {});
                      }),
                      const SizedBox(height: 10),
                      _dd('Distrito', _bolDist, _dists, (v) {
                        setModal(() => _bolDist = v);
                      }),
                    ] else ...[
                      TextField(
                        controller: _facRuc,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsMax(11),
                        decoration: const InputDecoration(
                          labelText: 'RUC',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _facRazon,
                        decoration: const InputDecoration(
                          labelText: 'Razón social',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _facDir,
                        decoration: const InputDecoration(
                          labelText: 'Dirección fiscal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dd('Departamento', _facDep, _deps, (v) async {
                        setModal(() => _facDep = v);
                        if (v != null) await _loadProvs(v, forFactura: true);
                        setModal(() {});
                      }),
                      const SizedBox(height: 10),
                      _dd('Provincia', _facProv, _provs, (v) async {
                        setModal(() => _facProv = v);
                        if (_facDep != null && v != null) {
                          await _loadDists(_facDep!, v, forFactura: true);
                        }
                        setModal(() {});
                      }),
                      const SizedBox(height: 10),
                      _dd('Distrito', _facDist, _dists, (v) {
                        setModal(() => _facDist = v);
                      }),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (tipo == 'BO') {
                            if (_bolNombres.text.trim().isEmpty ||
                                !RegExp(r'^\d{8}$').hasMatch(_bolDni.text) ||
                                _bolDir.text.trim().isEmpty ||
                                _bolDep == null ||
                                _bolProv == null ||
                                _bolDist == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Completa la boleta correctamente')),
                              );
                              return;
                            }
                            pay.saveBoleta(BoletaData(
                              nombres: _bolNombres.text.trim(),
                              dni: _bolDni.text.trim(),
                              direccion: _bolDir.text.trim(),
                              departamento: _bolDep!,
                              provincia: _bolProv!,
                              distrito: _bolDist!,
                            ));
                          } else {
                            if (!RegExp(r'^\d{11}$').hasMatch(_facRuc.text) ||
                                _facRazon.text.trim().isEmpty ||
                                _facDir.text.trim().isEmpty ||
                                _facDep == null ||
                                _facProv == null ||
                                _facDist == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Completa la factura correctamente')),
                              );
                              return;
                            }
                            pay.saveInvoice(InvoiceData(
                              ruc: _facRuc.text.trim(),
                              razonSocial: _facRazon.text.trim(),
                              direccion: _facDir.text.trim(),
                              departamento: _facDep!,
                              provincia: _facProv!,
                              distrito: _facDist!,
                            ));
                          }
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result == true;
  }

  Widget _dd(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value != null && items.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final pay = context.watch<PaymentProvider>();
    final subtotal = cart.subtotal;
    final total = checkout.totalWith(subtotal);

    if (!checkout.canPay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/entrega');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                checkout.mode == DeliveryMode.storePickup
                    ? Icons.store
                    : Icons.local_shipping,
                color: _gold,
              ),
              title: Text(
                checkout.mode == DeliveryMode.storePickup
                    ? 'Retiro en tienda'
                    : 'Envío a domicilio',
              ),
              subtitle: Text(checkout.direccionEntrega),
              trailing: TextButton(
                onPressed: () => context.push('/entrega'),
                child: const Text('Cambiar'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info alineada con Angular
          _infoBanner(
            icon: Icons.shield_outlined,
            title: 'Pagos con Culqi',
            body:
                'Contamos con la pasarela Culqi para una experiencia segura. '
                'En la app el cobro se simula (modo prueba) y el pedido se confirma en el servidor. '
                'Tarjetas de prueba abajo en el método Tarjeta.',
          ),
          if (checkout.mode == DeliveryMode.express)
            _infoBanner(
              icon: Icons.local_shipping_outlined,
              title: 'Envío Express',
              body:
                  'Tu pedido llegará en un plazo de 1 a 2 días a tu dirección. '
                  'En envío express el pago es con Yape o tarjeta (Culqi).',
            ),
          if (checkout.canCash)
            _infoBanner(
              icon: Icons.payments_outlined,
              title: '¿Efectivo (retiro en tienda)?',
              body:
                  'Si eliges retiro en tienda puedes pagar en efectivo al recoger. '
                  'No se emiten comprobantes electrónicos (PDF/XML/CDR) en esta modalidad; '
                  'si lo necesitas, solicítalo en tienda.',
            ),
          const SizedBox(height: 8),
          const Text('Método de pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _methodTile(
            id: 'yape',
            title: 'Yape',
            icon: Icons.phone_android,
            child: _method == 'yape'
                ? Column(
                    children: [
                      TextField(
                        controller: _yapePhone,
                        keyboardType: TextInputType.number,
                        inputFormatters: [yapePhoneFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Celular Yape',
                          border: OutlineInputBorder(),
                          hintText: '+51 9xxxxxxxx',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _yapeCode,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsMax(6),
                        decoration: const InputDecoration(
                          labelText: 'Código de aprobación (6 dígitos)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Modo prueba: usa cualquier código de 6 dígitos (ej. 123456).',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                : null,
          ),
          _methodTile(
            id: 'tarjeta',
            title: 'Tarjeta crédito / débito',
            icon: Icons.credit_card,
            child: _method == 'tarjeta'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _cardNumber,
                        keyboardType: TextInputType.number,
                        inputFormatters: [cardNumberFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                          border: OutlineInputBorder(),
                          hintText: '4111 1111 1111 1111',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cardExp,
                              keyboardType: TextInputType.number,
                              inputFormatters: [cardExpiryFormatter],
                              decoration: const InputDecoration(
                                labelText: 'MM/AA',
                                border: OutlineInputBorder(),
                                hintText: '12/28',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cardCvv,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: digitsMax(3),
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(),
                                hintText: '123',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          'Tarjetas de prueba Culqi (sandbox):\n'
                          '• Visa OK: 4111 1111 1111 1111\n'
                          '• Mastercard OK: 5111 1111 1111 1118\n'
                          '• CVV: 123  ·  Exp: cualquier mes/año futuro (ej. 12/28)\n'
                          '• Rechazada: 4000 0000 0000 0002\n'
                          'En esta app el cobro es simulado; no se cobra dinero real.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.35),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (checkout.canCash)
            _methodTile(
              id: 'efectivo',
              title: 'Efectivo (retiro en tienda)',
              icon: Icons.payments_outlined,
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Comprobante', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (pay.boleta != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt, color: _gold),
                      title: Text('Boleta — ${pay.boleta!.nombres}'),
                      subtitle: Text('DNI ${pay.boleta!.dni}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: pay.clearBoleta,
                      ),
                    )
                  else if (pay.invoice != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.business, color: _gold),
                      title: Text('Factura — ${pay.invoice!.razonSocial}'),
                      subtitle: Text('RUC ${pay.invoice!.ruc}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: pay.clearInvoice,
                      ),
                    )
                  else
                    const Text(
                      'Para Yape/tarjeta se pedirá boleta o factura al pagar.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _openDocForm('BO'),
                        child: const Text('Boleta'),
                      ),
                      TextButton(
                        onPressed: () => _openDocForm('FA'),
                        child: const Text('Factura'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _sumRow('Productos', subtotal),
                  _sumRow('Descuentos', -checkout.discount, green: true),
                  _sumRow('Entregas', checkout.fee),
                  const Divider(),
                  _sumRow('Total', total, bold: true),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting || _method == null
                          ? null
                          : () {
                              if (_method == 'efectivo') {
                                _pagarEfectivo();
                              } else if (_method == 'yape' || _method == 'tarjeta') {
                                _pagarCulqiLike(_method!);
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'PAGAR AHORA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String id,
    required String title,
    required IconData icon,
    Widget? child,
  }) {
    final selected = _method == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? _gold : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _method = id),
            leading: Icon(icon, color: selected ? _gold : Colors.grey),
            title: Text(title),
            trailing: selected
                ? const Icon(Icons.check_circle, color: _gold)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          ),
          if (child != null && selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _infoBanner({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF2B2B2B),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _gold, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumRow(String label, double amount, {bool green = false, bool bold = false}) {
    final neg = amount < 0 || green;
    final text = '${neg ? '- ' : ''}S/ ${amount.abs().toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            text,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: green ? Colors.green : (bold ? _gold : null),
              fontSize: bold ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
