/// Fechas en pantalla: 07 sep 2026 (español). La API sigue en ISO.
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

DateTime? parseFechaPe(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  final hasTz = RegExp(r'[zZ]|[+-]\d{2}:?\d{2}$').hasMatch(s);
  if (RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}').hasMatch(s) && !hasTz) {
    s = '${s.replaceFirst(' ', 'T')}-05:00';
  } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    s = '${s}T12:00:00-05:00';
  }
  return DateTime.tryParse(s);
}

String formatFechaPe(String? raw, {bool conHora = false}) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final d = parseFechaPe(raw);
  if (d == null) return raw;
  final lima = d.toUtc().add(const Duration(hours: -5));
  final dd = lima.day.toString().padLeft(2, '0');
  final mes = _meses[lima.month - 1];
  final base = '$dd $mes ${lima.year}';
  if (!conHora) return base;
  final hh = lima.hour.toString().padLeft(2, '0');
  final mm = lima.minute.toString().padLeft(2, '0');
  return '$base, $hh:$mm';
}

String formatFechaHoraPe(String? raw) => formatFechaPe(raw, conHora: true);
