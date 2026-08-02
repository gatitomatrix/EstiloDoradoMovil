// lib/core/providers/payment_provider.dart
import 'package:flutter/foundation.dart';
import '../models/checkout_models.dart';

class PaymentProvider extends ChangeNotifier {
  InvoiceData? invoice;
  BoletaData? boleta;
  String? selectedDoc; // FA | BO

  void saveInvoice(InvoiceData data) {
    invoice = data;
    boleta = null;
    selectedDoc = 'FA';
    notifyListeners();
  }

  void saveBoleta(BoletaData data) {
    boleta = data;
    invoice = null;
    selectedDoc = 'BO';
    notifyListeners();
  }

  void clearInvoice() {
    invoice = null;
    if (selectedDoc == 'FA') selectedDoc = null;
    notifyListeners();
  }

  void clearBoleta() {
    boleta = null;
    if (selectedDoc == 'BO') selectedDoc = null;
    notifyListeners();
  }

  void clearAll() {
    invoice = null;
    boleta = null;
    selectedDoc = null;
    notifyListeners();
  }

  bool get hasDoc => invoice != null || boleta != null;
}
