// lib/core/utils/agencias_shalom.dart
class AgenciaShalom {
  final String id;
  final String nombre;
  final String direccion;
  final String distrito;
  final String provincia;
  final String departamento;
  const AgenciaShalom({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.distrito,
    required this.provincia,
    required this.departamento,
  });
}

class ResultadoAgencias {
  final List<AgenciaShalom> agencias;
  final bool exacto;
  final String distritoPedido;
  final String? distritoSugerido;
  const ResultadoAgencias({
    required this.agencias,
    required this.exacto,
    required this.distritoPedido,
    this.distritoSugerido,
  });
}

String _n(String? s) {
  var t = (s ?? '').toUpperCase().trim();
  const map = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N'};
  map.forEach((k, v) => t = t.replaceAll(k, v));
  return t;
}

const agenciasShalom = <AgenciaShalom>[
    const AgenciaShalom(id: 'hyo-ica', nombre: 'Shalom Jr. Ica', direccion: 'Jr. Ica 1143', distrito: 'Huancayo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-andes', nombre: 'Shalom Terminal Los Andes', direccion: 'Av. Ferrocarril S/N, Counter 14', distrito: 'Huancayo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-sancarlos', nombre: 'Shalom San Carlos', direccion: 'Pj. San Fernando 209', distrito: 'Huancayo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-chilca', nombre: 'Shalom Chilca', direccion: 'Jr. 28 de Julio 935', distrito: 'Chilca', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-castilla', nombre: 'Shalom Mariscal Castilla', direccion: 'Av. Mariscal Castilla 2769', distrito: 'El Tambo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-piopata', nombre: 'Shalom Pio Pata', direccion: 'Av. Huancavelica 1201', distrito: 'El Tambo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'hyo-circun', nombre: 'Shalom Circunvalación', direccion: 'Av. Circunvalación 480', distrito: 'El Tambo', provincia: 'Huancayo', departamento: 'Junín'),
    const AgenciaShalom(id: 'cal-saenz', nombre: 'Shalom Callao Sáenz Peña', direccion: 'Av. Sáenz Peña 164', distrito: 'Callao', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'cal-bellavista', nombre: 'Shalom Bellavista', direccion: 'Av. Oscar R. Benavides 3860', distrito: 'Bellavista', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'cal-ventanilla', nombre: 'Shalom Ventanilla', direccion: 'Av. Néstor Gambetta km 14.5', distrito: 'Ventanilla', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'cal-perla', nombre: 'Shalom La Perla', direccion: 'Av. Costanera 1450', distrito: 'La Perla', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'cal-faucett', nombre: 'Shalom Carmen de la Legua', direccion: 'Av. Elmer Faucett 2095', distrito: 'Carmen de la Legua Reynoso', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'cal-miperu', nombre: 'Shalom Mi Perú', direccion: 'Av. 200 Millas', distrito: 'Mi Perú', provincia: 'Callao', departamento: 'Callao'),
    const AgenciaShalom(id: 'lim-lima1', nombre: 'Shalom Cercado Tingo María', direccion: 'Av. Tingo María 1252-A', distrito: 'Lima', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-lima2', nombre: 'Shalom Nicolás Dueñas', direccion: 'Av. Nicolás Dueñas 584', distrito: 'Lima', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-ate1', nombre: 'Shalom Ate Esperanza', direccion: 'Av. Esperanza Mz. K Lt. 6', distrito: 'Ate', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-sjl1', nombre: 'Shalom SJL Zárate', direccion: 'Av. Malecón Checa 167', distrito: 'San Juan de Lurigancho', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-smp1', nombre: 'Shalom SMP Bertello', direccion: 'Av. Alejandro Bertello', distrito: 'San Martín de Porres', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-olivos1', nombre: 'Shalom Los Olivos Huandoy', direccion: 'Av. Huandoy con Av. Central', distrito: 'Los Olivos', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-comas1', nombre: 'Shalom Comas Universitaria', direccion: 'Av. Universitaria 7241', distrito: 'Comas', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-carabayllo1', nombre: 'Shalom Carabayllo Túpac Amaru', direccion: 'Av. Túpac Amaru km 19', distrito: 'Carabayllo', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-pp1', nombre: 'Shalom Puente Piedra', direccion: 'Av. Buenos Aires', distrito: 'Puente Piedra', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-indep1', nombre: 'Shalom Independencia', direccion: 'Av. Túpac Amaru 4708', distrito: 'Independencia', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-molina1', nombre: 'Shalom La Molina Fontana', direccion: 'Av. La Fontana 440', distrito: 'La Molina', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-sjm1', nombre: 'Shalom SJM Atocongo', direccion: 'Av. Los Héroes 228', distrito: 'San Juan de Miraflores', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-vmt1', nombre: 'Shalom VMT Lima', direccion: 'Av. Lima 2208, José Gálvez', distrito: 'Villa María del Triunfo', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-ves1', nombre: 'Shalom Villa El Salvador', direccion: 'Av. 1° de Mayo, sector 1', distrito: 'Villa El Salvador', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-chorrillos1', nombre: 'Shalom Chorrillos', direccion: 'Av. Santa Anita 580', distrito: 'Chorrillos', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-surco1', nombre: 'Shalom Surco Higuereta', direccion: 'Calle Barlovento 134', distrito: 'Santiago de Surco', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-victoria1', nombre: 'Shalom La Victoria México', direccion: 'Av. México 1125', distrito: 'La Victoria', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-brena1', nombre: 'Shalom Breña Venezuela', direccion: 'Av. Venezuela 1670', distrito: 'Breña', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-agustino1', nombre: 'Shalom El Agustino', direccion: 'Av. 1° de Mayo 3071', distrito: 'El Agustino', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-jm1', nombre: 'Shalom Jesús María', direccion: 'Av. Mariscal Luzuriaga 584', distrito: 'Jesús María', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-lince1', nombre: 'Shalom Lince José Leal', direccion: 'Av. José Leal 648', distrito: 'Lince', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-pl1', nombre: 'Shalom Pueblo Libre Bolívar', direccion: 'Av. Bolívar 1097', distrito: 'Pueblo Libre', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-rimac1', nombre: 'Shalom Rímac Amancaes', direccion: 'Av. Amancaes 644', distrito: 'Rímac', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-sb1', nombre: 'Shalom San Borja Angamos', direccion: 'Av. Angamos Este 2521', distrito: 'San Borja', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-mira1', nombre: 'Shalom Miraflores', direccion: 'Av. Petit Thouars 4799', distrito: 'Miraflores', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-smiguel1', nombre: 'Shalom San Miguel La Marina', direccion: 'Av. La Marina 2100', distrito: 'San Miguel', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-mag1', nombre: 'Shalom Magdalena del Mar', direccion: 'Jr. Ayacucho 756', distrito: 'Magdalena del Mar', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-surquillo1', nombre: 'Shalom Surquillo Angamos', direccion: 'Av. Angamos Oeste 1100', distrito: 'Surquillo', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-santaanita1', nombre: 'Shalom Santa Anita', direccion: 'Av. Los Eucaliptos', distrito: 'Santa Anita', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-chosica1', nombre: 'Shalom Chosica', direccion: 'El Sol 124, Parque Echenique', distrito: 'Lurigancho', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-lurin1', nombre: 'Shalom Lurín', direccion: 'Antigua Panamericana Sur km 37', distrito: 'Lurín', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-pacha1', nombre: 'Shalom Pachacámac Manchay', direccion: 'Av. Prolongación La Molina', distrito: 'Pachacámac', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-ancon1', nombre: 'Shalom Ancón', direccion: 'Av. Micaela Bastidas', distrito: 'Ancón', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-chacla1', nombre: 'Shalom Chaclacayo', direccion: 'Av. Nicolás Ayllón', distrito: 'Chaclacayo', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-ciene1', nombre: 'Shalom Cieneguilla', direccion: 'Av. Nueva Toledo', distrito: 'Cieneguilla', provincia: 'Lima', departamento: 'Lima'),
    const AgenciaShalom(id: 'lim-srosa1', nombre: 'Shalom Santa Rosa', direccion: 'Av. Santa Rosa', distrito: 'Santa Rosa', provincia: 'Lima', departamento: 'Lima'),
];

const _vecinos = <String, List<String>>{
    'SAN ISIDRO': ['MIRAFLORES', 'SAN BORJA', 'MAGDALENA DEL MAR', 'LINCE', 'SURQUILLO'],
    'BARRANCO': ['CHORRILLOS', 'MIRAFLORES', 'SANTIAGO DE SURCO'],
    'SAN LUIS': ['LA VICTORIA', 'SAN BORJA', 'ATE', 'SANTA ANITA'],
    'LA PUNTA': ['LA PERLA', 'CALLAO', 'BELLAVISTA'],
    'PUNTA HERMOSA': ['LURIN', 'PUNTA NEGRA', 'SAN BARTOLO'],
    'PUNTA NEGRA': ['PUNTA HERMOSA', 'SAN BARTOLO', 'LURIN'],
    'SAN BARTOLO': ['PUNTA NEGRA', 'SANTA MARIA DEL MAR', 'LURIN'],
    'SANTA MARIA DEL MAR': ['SAN BARTOLO', 'PUNTA HERMOSA', 'LURIN'],
    'PUCUSANA': ['SAN BARTOLO', 'LURIN', 'PUNTA HERMOSA'],
    'MI PERU': ['VENTANILLA', 'CALLAO'],
};

bool _sameZona(AgenciaShalom a, String dep, String prov) {
  final d = _n(dep);
  final p = _n(prov);
  final ad = _n(a.departamento);
  final ap = _n(a.provincia);
  if (d.contains('CALLAO') || p == 'CALLAO') {
    return ad.contains('CALLAO') || ap == 'CALLAO';
  }
  if (d.contains('JUNIN') || p == 'HUANCAYO') {
    return ad.contains('JUNIN') || ap == 'HUANCAYO';
  }
  return ad.contains('LIMA') && !ad.contains('CALLAO');
}

ResultadoAgencias buscarAgenciasShalom({
  String? departamento,
  String? provincia,
  String? distrito,
}) {
  final dist = _n(distrito);
  final zona = agenciasShalom.where((a) => _sameZona(a, departamento ?? '', provincia ?? '')).toList();
  final exactas = dist.isEmpty ? <AgenciaShalom>[] : zona.where((a) => _n(a.distrito) == dist).toList();
  if (exactas.isNotEmpty) {
    return ResultadoAgencias(agencias: exactas, exacto: true, distritoPedido: distrito ?? '');
  }
  for (final vecino in _vecinos[dist] ?? const <String>[]) {
    final found = zona.where((a) => _n(a.distrito) == vecino).toList();
    if (found.isNotEmpty) {
      return ResultadoAgencias(
        agencias: found,
        exacto: false,
        distritoPedido: distrito ?? '',
        distritoSugerido: found.first.distrito,
      );
    }
  }
  return ResultadoAgencias(
    agencias: zona.take(6).toList(),
    exacto: false,
    distritoPedido: distrito ?? '',
    distritoSugerido: zona.isEmpty ? null : zona.first.distrito,
  );
}
