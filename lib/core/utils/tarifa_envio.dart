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
      'Envíos solo a Lima (distritos de Lima). Otras ciudades: recojo en tienda.';

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

  static bool cubre({String? departamento, String? provincia}) {
    final d = _norm(departamento);
    final p = _norm(provincia);
    if (d.contains('CALLAO') || d.contains('JUNIN') || d.contains('PASCO')) {
      return false;
    }
    if (p.isNotEmpty && p != 'LIMA') return false;
    return d.contains('LIMA') || p == 'LIMA';
  }

  static List<String> filtrarProvincias(String? departamento, List<String> todas) {
    return todas.where((p) => cubre(departamento: departamento, provincia: p)).toList();
  }

  static TarifaEnvio estimar({String? departamento, String? provincia}) {
    if (cubre(departamento: departamento, provincia: provincia)) {
      return const TarifaEnvio(
        costo: 18,
        zona: 'lima',
        etiqueta: 'Lima · estimado Shalom',
      );
    }
    return const TarifaEnvio(
      costo: 0,
      zona: 'fuera',
      etiqueta: 'Fuera de cobertura',
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
