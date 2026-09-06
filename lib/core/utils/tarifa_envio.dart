class TarifaEnvio {
  final double costo;
  final String zona;
  final String etiqueta;

  const TarifaEnvio({
    required this.costo,
    required this.zona,
    required this.etiqueta,
  });

  static const coberturaTexto =
      'Envíos solo a Lima – Callao, Huancayo y Pasco. Otras ciudades: recojo en tienda.';

  static const _huancayoDistritos = ['CHILCA', 'EL TAMBO', 'HUANCAYO'];

  static String _norm(String? s) {
    var t = (s ?? '').toUpperCase().trim();
    const map = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    map.forEach((k, v) => t = t.replaceAll(k, v));
    return t;
  }

  static bool cubre({
    String? departamento,
    String? provincia,
    String? distrito,
  }) {
    final d = _norm(departamento);
    final p = _norm(provincia);
    final di = _norm(distrito);

    final limaMetro = d.contains('LIMA') && !d.contains('CALLAO') && (p.isEmpty || p == 'LIMA');
    final callao = d.contains('CALLAO') && (p.isEmpty || p == 'CALLAO');
    final pasco = d.contains('PASCO') && (p.isEmpty || p == 'PASCO');
    final huancayo = d.contains('JUNIN') && (p.isEmpty || p == 'HUANCAYO');

    if (limaMetro || callao || pasco) return true;
    if (huancayo) {
      if (di.isEmpty) return true;
      return _huancayoDistritos.contains(di);
    }
    return false;
  }

  static List<String> filtrarProvincias(String? departamento, List<String> todas) {
    return todas.where((p) => cubre(departamento: departamento, provincia: p)).toList();
  }

  static List<String> filtrarDistritos(
    String? departamento,
    String? provincia,
    List<String> todas,
  ) {
    return todas
        .where((di) => cubre(departamento: departamento, provincia: provincia, distrito: di))
        .toList();
  }

  static TarifaEnvio estimar({
    String? departamento,
    String? provincia,
    String? distrito,
  }) {
    if (!cubre(departamento: departamento, provincia: provincia, distrito: distrito)) {
      return const TarifaEnvio(
        costo: 0,
        zona: 'fuera',
        etiqueta: 'Fuera de cobertura',
      );
    }
    final d = _norm(departamento);
    final p = _norm(provincia);
    if (d.contains('JUNIN') || p == 'HUANCAYO') {
      return const TarifaEnvio(
        costo: 8,
        zona: 'huancayo',
        etiqueta: 'Huancayo · S/ 8',
      );
    }
    if (d.contains('PASCO') || p == 'PASCO') {
      return const TarifaEnvio(
        costo: 4,
        zona: 'pasco',
        etiqueta: 'Pasco local · S/ 4',
      );
    }
    return const TarifaEnvio(
      costo: 10,
      zona: 'lima',
      etiqueta: 'Lima – Callao · S/ 10',
    );
  }

  static const direccionTienda =
      'Prolongación Yauli Nro. S/N Pasco - Pasco – Chaupimarca.';

  static const textoRecojo = 'Retiro en tienda — $direccionTienda';

  static const recojo = TarifaEnvio(
    costo: 0,
    zona: 'tienda',
    etiqueta: 'Recojo en tienda',
  );
}
