// lib/features/orders/pagar_pedido_screen.dart
// Completa el pago de un pedido ya creado y pendiente (yape/tarjeta + boleta/factura).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/checkout_models.dart';
import '../../core/services/order_service.dart';
import '../../core/services/ubigeo_service.dart';

const _gold = Color(0xFFD4AF37);

class PagarPedidoScreen extends StatefulWidget {
  final int pedidoId;
  final double total;
  final String? formaPagoSugerida;

  const PagarPedidoScreen({
    super.key,
    required this.pedidoId,
    required this.total,
    this.formaPagoSugerida,
  });

  @override
  State<PagarPedidoScreen> createState() => _PagarPedidoScreenState();
}

class _PagarPedidoScreenState extends State<PagarPedidoScreen> {
  final _order = OrderService();
  final _ubigeo = UbigeoService();
  bool _submitting = false;
  String _method = 'yape';

  final _yapePhone = TextEditingController(text: '+51 9');
  final _yapeCode = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardExp = TextEditingController();
  final _cardCvv = TextEditingController();

  final _bolNombres = TextEditingController();
  final _bolDni = TextEditingController();
  final _bolDir = TextEditingController();
  String? _bolDep, _bolProv, _bolDist;

  final _facRuc = TextEditingController();
  final _facRazon = TextEditingController();
  final _facDir = TextEditingController();
  String? _facDep, _facProv, _facDist;

  String _docTipo = 'BO'; // BO | FA
  List<String> _deps = [];
  List<String> _provs = [];
  List<String> _dists = [];

  @override
  void initState() {
    super.initState();
    final s = (widget.formaPagoSugerida ?? '').toLowerCase();
    if (s == 'tarjeta' || s == 'yape') _method = s;
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

  Future<void> _onDep(String? v) async {
    setState(() {
      _bolDep = v;
      _facDep = v;
      _bolProv = null;
      _facProv = null;
      _bolDist = null;
      _facDist = null;
      _provs = [];
      _dists = [];
    });
    if (v != null) {
      final p = await _ubigeo.getProvincias(v);
      if (mounted) setState(() => _provs = p);
    }
  }

  Future<void> _onProv(String? v) async {
    setState(() {
      _bolProv = v;
      _facProv = v;
      _bolDist = null;
      _facDist = null;
      _dists = [];
    });
    final dep = _docTipo == 'FA' ? _facDep : _bolDep;
    if (dep != null && v != null) {
      final d = await _ubigeo.getDistritos(dep, v);
      if (mounted) setState(() => _dists = d);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pagar() async {
    if (_method == 'yape') {
      if (!RegExp(r'^\+51 9\d{8}$').hasMatch(_yapePhone.text.trim()) ||
          !RegExp(r'^\d{6}$').hasMatch(_yapeCode.text.trim())) {
        _toast('Yape: teléfono (+51 9xxxxxxxx) y código de 6 dígitos.');
        return;
      }
    } else {
      final num = _cardNumber.text.replaceAll(' ', '');
      if (num.length != 16 ||
          !RegExp(r'^\d{2}/\d{2}$').hasMatch(_cardExp.text) ||
          !RegExp(r'^\d{3}$').hasMatch(_cardCvv.text)) {
        _toast('Completa los datos de la tarjeta correctamente.');
        return;
      }
    }

    BoletaData? boleta;
    InvoiceData? factura;
    if (_docTipo == 'BO') {
      if (_bolNombres.text.trim().isEmpty ||
          !RegExp(r'^\d{8}$').hasMatch(_bolDni.text) ||
          _bolDir.text.trim().isEmpty ||
          _bolDep == null ||
          _bolProv == null ||
          _bolDist == null) {
        _toast('Completa la boleta correctamente.');
        return;
      }
      boleta = BoletaData(
        nombres: _bolNombres.text.trim(),
        dni: _bolDni.text.trim(),
        direccion: _bolDir.text.trim(),
        departamento: _bolDep!,
        provincia: _bolProv!,
        distrito: _bolDist!,
      );
    } else {
      if (!RegExp(r'^\d{11}$').hasMatch(_facRuc.text) ||
          _facRazon.text.trim().isEmpty ||
          _facDir.text.trim().isEmpty ||
          _facDep == null ||
          _facProv == null ||
          _facDist == null) {
        _toast('Completa la factura correctamente.');
        return;
      }
      factura = InvoiceData(
        ruc: _facRuc.text.trim(),
        razonSocial: _facRazon.text.trim(),
        direccion: _facDir.text.trim(),
        departamento: _facDep!,
        provincia: _facProv!,
        distrito: _facDist!,
      );
    }

    setState(() => _submitting = true);
    try {
      final culqiId = _method == 'yape'
          ? 'ype_mobile_${DateTime.now().millisecondsSinceEpoch}'
          : 'tok_mobile_${DateTime.now().millisecondsSinceEpoch}';

      final res = await _order.pagarPendiente(
        id: widget.pedidoId,
        formaPago: _method,
        culqiId: culqiId,
        comprobante: _docTipo,
        boleta: boleta,
        factura: factura,
      );

      if (!mounted) return;
      context.go(
        '/resumen/${res.idPedido}',
        extra: {'ventaOk': true, 'comprobante': res.comprobante},
      );
    } catch (e) {
      _toast('No se pudo pagar: ${OrderService.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagar pedido #${widget.pedidoId}'),
        backgroundColor: _gold,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _gold.withValues(alpha: 0.12),
            child: ListTile(
              leading: const Icon(Icons.payments, color: _gold),
              title: const Text('Total a pagar', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                'S/ ${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _gold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          RadioListTile<String>(
            value: 'yape',
            groupValue: _method,
            activeColor: _gold,
            title: const Text('Yape'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          if (_method == 'yape') ...[
            TextField(
              controller: _yapePhone,
              keyboardType: TextInputType.phone,
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Código de aprobación (6 dígitos)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          RadioListTile<String>(
            value: 'tarjeta',
            groupValue: _method,
            activeColor: _gold,
            title: const Text('Tarjeta'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          if (_method == 'tarjeta') ...[
            TextField(
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de tarjeta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MM/AA',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cardCvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('Comprobante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'BO', label: Text('Boleta')),
              ButtonSegment(value: 'FA', label: Text('Factura')),
            ],
            selected: {_docTipo},
            onSelectionChanged: (s) => setState(() => _docTipo = s.first),
          ),
          const SizedBox(height: 12),
          if (_docTipo == 'BO') ...[
            TextField(
              controller: _bolNombres,
              decoration: const InputDecoration(
                labelText: 'Nombres y apellidos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bolDni,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bolDir,
              decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
            ),
          ] else ...[
            TextField(
              controller: _facRuc,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(labelText: 'RUC', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _facRazon,
              decoration: const InputDecoration(
                labelText: 'Razón social',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _facDir,
              decoration: const InputDecoration(
                labelText: 'Dirección fiscal',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _docTipo == 'FA' ? _facDep : _bolDep,
            decoration: const InputDecoration(
              labelText: 'Departamento',
              border: OutlineInputBorder(),
            ),
            items: _deps.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: _onDep,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _docTipo == 'FA' ? _facProv : _bolProv,
            decoration: const InputDecoration(
              labelText: 'Provincia',
              border: OutlineInputBorder(),
            ),
            items: _provs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: _onProv,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _docTipo == 'FA' ? _facDist : _bolDist,
            decoration: const InputDecoration(
              labelText: 'Distrito',
              border: OutlineInputBorder(),
            ),
            items: _dists.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() {
              if (_docTipo == 'FA') {
                _facDist = v;
              } else {
                _bolDist = v;
              }
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _pagar,
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Volver al pedido'),
          ),
        ],
      ),
    );
  }
}
