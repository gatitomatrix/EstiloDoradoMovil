// lib/core/providers/checkout_provider.dart
import 'package:flutter/foundation.dart';
import '../models/checkout_models.dart';
import '../utils/tarifa_envio.dart';

class CheckoutProvider extends ChangeNotifier {
  DeliveryMode mode = DeliveryMode.none;
  DeliveryAddress? address;
  double fee = 0;
  double discount = 0;

  double totalWith(double subtotal) => subtotal + fee - discount;

  bool get canPay => mode == DeliveryMode.storePickup || mode == DeliveryMode.express;

  bool get canCash => mode == DeliveryMode.storePickup;

  String get direccionEntrega {
    if (mode == DeliveryMode.storePickup) return 'Retiro en tienda -';
    return address?.display ?? '';
  }

  void setStorePickup() {
    mode = DeliveryMode.storePickup;
    address = DeliveryAddress.storePickup();
    fee = 0;
    discount = 0;
    notifyListeners();
  }

  void setExpress(DeliveryAddress addr, {double? fee, double discount = 0}) {
    mode = DeliveryMode.express;
    address = addr;
    this.fee = fee ??
        TarifaEnvio.estimar(
          departamento: addr.departamento,
          provincia: addr.provincia,
        ).costo;
    this.discount = discount;
    notifyListeners();
  }

  void setCosts({required double fee, required double discount}) {
    this.fee = fee;
    this.discount = discount;
    notifyListeners();
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
  }

  void reset() {
    mode = DeliveryMode.none;
    address = null;
    fee = 0;
    discount = 0;
    notifyListeners();
  }
}
