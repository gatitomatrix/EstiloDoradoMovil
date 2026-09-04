// lib/core/services/ubigeo_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/tarifa_envio.dart';

class UbigeoService {
  Map<String, Map<String, List<String>>>? _data;
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    _loading ??= _load();
    return _loading!;
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/ubigeo-peru.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _data = decoded.map((dep, provs) {
      final pmap = (provs as Map<String, dynamic>).map((prov, dists) {
        final list = (dists as List).map((e) => e.toString()).toList()..sort();
        return MapEntry(prov, list);
      });
      return MapEntry(dep, pmap);
    });
  }

  Future<List<String>> getDepartamentos({bool soloEnvio = false}) async {
    await ensureLoaded();
    final keys = _data?.keys.toList() ?? [];
    keys.sort();
    if (!soloEnvio) return keys;
    return keys.where((d) => TarifaEnvio.cubre(departamento: d)).toList();
  }

  Future<List<String>> getProvincias(String departamento) async {
    await ensureLoaded();
    final keys = _data?[departamento]?.keys.toList() ?? [];
    keys.sort();
    return keys;
  }

  Future<List<String>> getDistritos(String departamento, String provincia) async {
    await ensureLoaded();
    final list = List<String>.from(_data?[departamento]?[provincia] ?? []);
    list.sort();
    return list;
  }
}
