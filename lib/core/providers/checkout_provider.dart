// lib/core/providers/checkout_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkout_models.dart';
import '../utils/tarifa_envio.dart';
import '../utils/celular.dart';

class CheckoutProvider extends ChangeNotifier {
  // Recojo / envío / fee. Misma idea que CheckoutService de la web.
  static const _k = 'ed_checkout_state';

  DeliveryMode mode = DeliveryMode.none;
  DeliveryAddress? address;
  DeliveryAddress? draft;
  double fee = 0;
  double discount = 0;
  bool pendingEditAddress = false;
  String telefono = '';
  int? telefonoUserId;

  double totalWith(double subtotal) => subtotal + fee - discount;

  bool get envioListo {
    final a = address;
    if (a == null || a.via == 'Retiro en tienda') return false;
    if (a.departamento.isEmpty || a.provincia.isEmpty || a.distrito.isEmpty) {
      return false;
    }
    if (a.envioTipo == 'AGENCIA') {
      return (a.agenciaNombre ?? a.agenciaId ?? a.via).trim().isNotEmpty;
    }
    if (a.envioTipo == 'DOMICILIO') {
      return a.via.trim().isNotEmpty;
    }
    return false;
  }

  bool get telefonoOk => Celular.cliente(telefono).length == 9;

  bool get canPay =>
      mode == DeliveryMode.storePickup ||
      (mode == DeliveryMode.express && envioListo && telefonoOk);

  bool get canCash => mode == DeliveryMode.storePickup;

  DeliveryAddress? get savedExpress => envioListo ? address : null;

  String get direccionEntrega {
    if (mode == DeliveryMode.storePickup) return TarifaEnvio.textoRecojo;
    return savedExpress?.display ?? address?.display ?? '';
  }

  CheckoutProvider() {
    hydrate();
  }

  Future<void> hydrate() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final m = j['mode']?.toString();
      mode = m == 'storePickup'
          ? DeliveryMode.storePickup
          : m == 'express'
              ? DeliveryMode.express
              : DeliveryMode.none;
      if (j['address'] is Map) {
        address = DeliveryAddress.fromJson(Map<String, dynamic>.from(j['address'] as Map));
      }
      if (j['draft'] is Map) {
        draft = DeliveryAddress.fromJson(Map<String, dynamic>.from(j['draft'] as Map));
      }
      fee = (j['fee'] as num?)?.toDouble() ?? 0;
      discount = (j['discount'] as num?)?.toDouble() ?? 0;
      telefono = Celular.cliente(j['telefono']?.toString());
      final uid = j['telefonoUserId'];
      telefonoUserId = uid is int ? uid : int.tryParse('${uid ?? ''}');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode({
          'mode': mode.name,
          'address': address?.toJson(),
          'draft': draft?.toJson(),
          'fee': fee,
          'discount': discount,
          'telefono': telefono,
          'telefonoUserId': telefonoUserId,
        }),
      );
    } catch (_) {}
  }

  void requestEditAddress() {
    pendingEditAddress = true;
    notifyListeners();
  }

  bool consumeEditAddress() {
    if (!pendingEditAddress) return false;
    pendingEditAddress = false;
    return true;
  }

  void setStorePickup() {
    mode = DeliveryMode.storePickup;
    address = DeliveryAddress.storePickup();
    fee = 0;
    discount = 0;
    notifyListeners();
    _persist();
  }

  void setTelefono(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('51') && d.length >= 11) d = d.substring(2);
    if (d.length > 9) d = d.substring(0, 9);
    if (d.length == 9 && Celular.cliente(d).isEmpty) d = '';
    telefono = d;
    notifyListeners();
    _persist();
  }

  void bindCliente(int? userId, String? profileTel) {
    final profile = Celular.cliente(profileTel);
    if (userId == null || telefonoUserId != userId) {
      telefono = profile;
      telefonoUserId = userId;
      notifyListeners();
      _persist();
      return;
    }
    final actual = Celular.cliente(telefono);
    telefono = actual.isNotEmpty ? actual : profile;
    notifyListeners();
    _persist();
  }

  void setDraft({
    String? departamento,
    String? provincia,
    String? distrito,
    String? via,
    String? numero,
    double? lat,
    double? lng,
  }) {
    final prev = draft;
    draft = DeliveryAddress(
      departamento: departamento ?? prev?.departamento ?? '',
      provincia: provincia ?? prev?.provincia ?? '',
      distrito: distrito ?? prev?.distrito ?? '',
      via: via ?? prev?.via ?? '',
      numero: numero ?? prev?.numero ?? '',
      lat: lat ?? prev?.lat,
      lng: lng ?? prev?.lng,
    );
    _persist();
  }

  void setExpress(DeliveryAddress addr, {double? fee, double discount = 0}) {
    mode = DeliveryMode.express;
    address = addr;
    draft = addr;
    this.fee = fee ??
        TarifaEnvio.calcular(
          departamento: addr.departamento,
          provincia: addr.provincia,
          distrito: addr.distrito,
          tipo: addr.envioTipo == 'DOMICILIO' ||
                  TarifaEnvio.zonaDe(
                        departamento: addr.departamento,
                        provincia: addr.provincia,
                        distrito: addr.distrito,
                      ) ==
                      'pasco'
              ? 'DOMICILIO'
              : 'AGENCIA',
        ).costo;
    this.discount = discount;
    notifyListeners();
    _persist();
  }

  void setCosts({required double fee, required double discount}) {
    this.fee = fee;
    this.discount = discount;
    notifyListeners();
    _persist();
  }

  void setMode(DeliveryMode m) {
    mode = m;
    if (m == DeliveryMode.storePickup) {
      fee = 0;
      discount = 0;
      address = DeliveryAddress.storePickup();
    } else if (m == DeliveryMode.express) {
      final saved = savedExpress;
      if (saved != null) {
        address = saved;
        draft = saved;
        final tipo = saved.envioTipo == 'DOMICILIO' ? 'DOMICILIO' : 'AGENCIA';
        fee = TarifaEnvio.calcular(
          departamento: saved.departamento,
          provincia: saved.provincia,
          distrito: saved.distrito,
          tipo: tipo,
        ).costo;
      }
      discount = 0;
    }
    notifyListeners();
    _persist();
  }

  void reset() {
    mode = DeliveryMode.none;
    address = null;
    fee = 0;
    discount = 0;
    telefono = '';
    telefonoUserId = null;
    notifyListeners();
    _persist();
  }
}
