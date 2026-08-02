// lib/core/models/checkout_models.dart

enum DeliveryMode { none, storePickup, express }

class DeliveryAddress {
  final String departamento;
  final String provincia;
  final String distrito;
  final String via;
  final String numero;
  final String? full;
  final double? lat;
  final double? lng;

  const DeliveryAddress({
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.via,
    required this.numero,
    this.full,
    this.lat,
    this.lng,
  });

  String get display {
    if (full != null && full!.isNotEmpty) return full!;
    final left = [via.trim(), numero.trim()].where((s) => s.isNotEmpty).join(' ');
    final right = [distrito, provincia, departamento]
        .where((s) => s.trim().isNotEmpty)
        .join('/');
    return right.isEmpty ? left : '$left – $right';
  }

  Map<String, dynamic> toJson() => {
        'departamento': departamento,
        'provincia': provincia,
        'distrito': distrito,
        'via': via,
        'numero': numero,
        'full': display,
        'lat': lat,
        'lng': lng,
      };

  factory DeliveryAddress.fromJson(Map<String, dynamic> j) => DeliveryAddress(
        departamento: j['departamento']?.toString() ?? '',
        provincia: j['provincia']?.toString() ?? '',
        distrito: j['distrito']?.toString() ?? '',
        via: j['via']?.toString() ?? '',
        numero: j['numero']?.toString() ?? '',
        full: j['full']?.toString(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  factory DeliveryAddress.storePickup() => const DeliveryAddress(
        departamento: '',
        provincia: '',
        distrito: '',
        via: 'Retiro en tienda',
        numero: '-',
        full: 'Retiro en tienda',
      );
}

class InvoiceData {
  final String ruc;
  final String razonSocial;
  final String direccion;
  final String departamento;
  final String provincia;
  final String distrito;

  const InvoiceData({
    required this.ruc,
    required this.razonSocial,
    required this.direccion,
    required this.departamento,
    required this.provincia,
    required this.distrito,
  });

  Map<String, dynamic> toJson() => {
        'ruc': ruc,
        'razonSocial': razonSocial,
        'direccion': direccion,
        'departamento': departamento,
        'provincia': provincia,
        'distrito': distrito,
      };
}

class BoletaData {
  final String nombres;
  final String dni;
  final String direccion;
  final String departamento;
  final String provincia;
  final String distrito;

  const BoletaData({
    required this.nombres,
    required this.dni,
    required this.direccion,
    required this.departamento,
    required this.provincia,
    required this.distrito,
  });

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'dni': dni,
        'direccion': direccion,
        'departamento': departamento,
        'provincia': provincia,
        'distrito': distrito,
      };
}

class ConfirmarItem {
  final int idProducto;
  final int cantidad;

  const ConfirmarItem({required this.idProducto, required this.cantidad});

  Map<String, dynamic> toJson() => {
        'id_producto': idProducto,
        'cantidad': cantidad,
      };
}

class ComprobanteOut {
  final String tipo;
  final String serie;
  final int numero;
  final String? pdf;
  final String? xml;
  final String? cdr;

  const ComprobanteOut({
    required this.tipo,
    required this.serie,
    required this.numero,
    this.pdf,
    this.xml,
    this.cdr,
  });

  factory ComprobanteOut.fromJson(Map<String, dynamic> j) => ComprobanteOut(
        tipo: j['tipo']?.toString() ?? '',
        serie: j['serie']?.toString() ?? '',
        numero: int.tryParse(j['numero']?.toString() ?? '0') ?? 0,
        pdf: j['pdf']?.toString(),
        xml: j['xml']?.toString(),
        cdr: j['cdr']?.toString(),
      );

  String get friendly {
    final num8 = numero.toString().padLeft(8, '0');
    return '$serie-$num8';
  }
}

class ConfirmarRes {
  final int idPedido;
  final String? fechaPedido;
  final String estado;
  final double total;
  final String formaPago;
  final String? direccionEntrega;
  final String? sunatPdf;
  final String? sunatXml;
  final String? sunatCdr;
  final ComprobanteOut? comprobante;
  final List<PedidoDetalle>? detalles;

  const ConfirmarRes({
    required this.idPedido,
    this.fechaPedido,
    required this.estado,
    required this.total,
    required this.formaPago,
    this.direccionEntrega,
    this.sunatPdf,
    this.sunatXml,
    this.sunatCdr,
    this.comprobante,
    this.detalles,
  });

  factory ConfirmarRes.fromJson(Map<String, dynamic> j) {
    List<PedidoDetalle>? dets;
    if (j['detalles'] is List) {
      dets = (j['detalles'] as List)
          .map((e) => PedidoDetalle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    ComprobanteOut? comp;
    if (j['comprobante'] is Map) {
      comp = ComprobanteOut.fromJson(Map<String, dynamic>.from(j['comprobante'] as Map));
    }
    return ConfirmarRes(
      idPedido: int.tryParse(j['id_pedido']?.toString() ?? '0') ?? 0,
      fechaPedido: j['fecha_pedido']?.toString(),
      estado: j['estado']?.toString() ?? '',
      total: double.tryParse(j['total']?.toString() ?? '0') ?? 0,
      formaPago: j['forma_pago']?.toString() ?? '',
      direccionEntrega: j['direccion_entrega']?.toString(),
      sunatPdf: j['sunat_pdf']?.toString(),
      sunatXml: j['sunat_xml']?.toString(),
      sunatCdr: j['sunat_cdr']?.toString(),
      comprobante: comp,
      detalles: dets,
    );
  }
}

class PedidoDetalle {
  final int idProducto;
  final String? producto;
  final int cantidad;
  final double precioUnitario;
  final double? subtotal;

  const PedidoDetalle({
    required this.idProducto,
    this.producto,
    required this.cantidad,
    required this.precioUnitario,
    this.subtotal,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> j) {
    final cant = int.tryParse(j['cantidad']?.toString() ?? '0') ?? 0;
    final pu = double.tryParse(j['precio_unitario']?.toString() ?? '0') ?? 0;
    String? nombre;
    if (j['producto'] is Map) {
      nombre = (j['producto'] as Map)['nombre']?.toString();
    } else if (j['producto'] is String) {
      nombre = j['producto'] as String;
    }
    return PedidoDetalle(
      idProducto: int.tryParse(j['id_producto']?.toString() ?? '0') ?? 0,
      producto: nombre,
      cantidad: cant,
      precioUnitario: pu,
      subtotal: double.tryParse(j['subtotal']?.toString() ?? '') ?? (cant * pu),
    );
  }
}

class PedidoListItem {
  final int idPedido;
  final String? fechaPedido;
  final String estado;
  final double total;
  final String? formaPago;
  final String? direccionEntrega;
  final String? productoLabel;
  final String? comprobanteTipo;
  final String? comprobanteSerie;
  final int? comprobanteNumero;
  final String? friendly;

  const PedidoListItem({
    required this.idPedido,
    this.fechaPedido,
    required this.estado,
    required this.total,
    this.formaPago,
    this.direccionEntrega,
    this.productoLabel,
    this.comprobanteTipo,
    this.comprobanteSerie,
    this.comprobanteNumero,
    this.friendly,
  });

  factory PedidoListItem.fromJson(Map<String, dynamic> j) => PedidoListItem(
        idPedido: int.tryParse(
              (j['id_pedido'] ?? j['id'] ?? j['q'])?.toString() ?? '0',
            ) ??
            0,
        fechaPedido: (j['fecha_pedido'] ?? j['fecha'])?.toString(),
        estado: j['estado']?.toString() ?? 'pendiente',
        total: double.tryParse(j['total']?.toString() ?? '0') ?? 0,
        formaPago: j['forma_pago']?.toString(),
        direccionEntrega: j['direccion_entrega']?.toString(),
        productoLabel: j['producto_label']?.toString(),
        comprobanteTipo: j['comprobante_tipo']?.toString(),
        comprobanteSerie: j['comprobante_serie']?.toString(),
        comprobanteNumero:
            int.tryParse(j['comprobante_numero']?.toString() ?? ''),
        friendly: j['friendly']?.toString(),
      );
}
