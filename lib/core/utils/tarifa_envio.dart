class TarifaEnvio {
  final double costo;
  final String zona;
  final String etiqueta;

  const TarifaEnvio({
    required this.costo,
    required this.zona,
    required this.etiqueta,
  });

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

  static TarifaEnvio estimar({String? departamento, String? provincia}) {
    final d = _norm(departamento);
    final p = _norm(provincia);
    if (p.contains('HUANCAYO')) {
      return const TarifaEnvio(
        costo: 8,
        zona: 'huancayo',
        etiqueta: 'Huancayo (misma ciudad) · estimado Shalom',
      );
    }
    if (d.contains('JUNIN')) {
      return const TarifaEnvio(
        costo: 12,
        zona: 'junin',
        etiqueta: 'Junín (otras provincias) · estimado Shalom',
      );
    }
    if (d.contains('LIMA') ||
        d.contains('CALLAO') ||
        p.contains('CALLAO') ||
        p.contains('LIMA')) {
      return const TarifaEnvio(
        costo: 18,
        zona: 'lima',
        etiqueta: 'Lima / Callao · estimado Shalom',
      );
    }
    return const TarifaEnvio(
      costo: 25,
      zona: 'resto',
      etiqueta: 'Resto del Perú · estimado Shalom',
    );
  }

  static const recojo = TarifaEnvio(
    costo: 0,
    zona: 'tienda',
    etiqueta: 'Recojo en tienda',
  );
}
