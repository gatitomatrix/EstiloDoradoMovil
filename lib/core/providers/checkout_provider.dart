// lib/core/providers/checkout_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkout_models.dart';
import '../utils/tarifa_envio.dart';

class CheckoutProvider extends ChangeNotifier {
  static const _k = 'ed_checkout_state';

  DeliveryMode mode = DeliveryMode.none;
  DeliveryAddress? address;
  DeliveryAddress? draft;
  double fee = 0;
  double discount = 0;

  double totalWith(double subtotal) => subtotal + fee - discount;

  bool get canPay => mode == DeliveryMode.storePickup || mode == DeliveryMode.express;

  bool get canCash => mode == DeliveryMode.storePickup;

  String get direccionEntrega {
    if (mode == DeliveryMode.storePickup) return 'Retiro en tienda -';
    return address?.display ?? '';
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
        }),
      );
    } catch (_) {}
  }

  void setStorePickup() {
    mode = DeliveryMode.storePickup;
    address = DeliveryAddress.storePickup();
    fee = 0;
    discount = 0;
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
        TarifaEnvio.estimar(
          departamento: addr.departamento,
          provincia: addr.provincia,
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
      address ??= DeliveryAddress.storePickup();
    } else if (m == DeliveryMode.express) {
      final a = address;
      fee = a == null
          ? 25
          : TarifaEnvio.estimar(
              departamento: a.departamento,
              provincia: a.provincia,
            ).costo;
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
    notifyListeners();
    _persist();
  }
}
