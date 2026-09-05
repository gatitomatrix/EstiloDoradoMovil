// lib/features/assistant/assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/assistant_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFF8F1E9);

class _PendingAdd {
  final int id;
  final String nombre;
  final double precio;
  final int stock;
  final int qty;
  final String imagenUrl;

  _PendingAdd({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.qty,
    required this.imagenUrl,
  });
}

class _ChatMsg {
  final String text;
  final bool fromUser;
  final List<Map<String, dynamic>> products;
  final String? driver;
  final _PendingAdd? pendingAdd;
  final String? whatsappUrl;
  final String? whatsappLabel;
  final List<Map<String, dynamic>> pedidos;
  final bool needLogin;

  _ChatMsg({
    required this.text,
    required this.fromUser,
    this.products = const [],
    this.driver,
    this.pendingAdd,
    this.whatsappUrl,
    this.whatsappLabel,
    this.pedidos = const [],
    this.needLogin = false,
  });
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _svc = AssistantService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [];
  /// Últimas opciones mostradas: solo se puede agregar de esta lista.
  List<Map<String, dynamic>> _offered = [];
  String? _awaiting;
  Map<String, dynamic>? _complaint;
  bool _sending = false;
  List<String> _suggestions = const [
    'Regalo de cumpleaños',
    '¿Qué productos tienen?',
    'Cerdita tiburón',
    '¿Cómo compro?',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(
      _ChatMsg(
        text:
            'Hola, soy Dori, tu asistente de Estilo Dorado. Dime qué buscas o para quién es el regalo (cumpleaños, papá, novia…) y te muestro opciones del catálogo.',
        fromUser: false,
        driver: 'welcome',
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<int> get _offeredIds {
    final ids = <int>[];
    for (final p in _offered) {
      final id = int.tryParse(p['id']?.toString() ?? '');
      if (id != null) ids.add(id);
    }
    return ids;
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _msgs.add(_ChatMsg(text: text, fromUser: true));
      _sending = true;
      _ctrl.clear();
    });
    _scrollToEnd();

    try {
      final res = await _svc.send(text, offeredIds: _offeredIds, awaiting: _awaiting, complaint: _complaint);
      if (!mounted) return;

      _PendingAdd? pending;
      String? waUrl;
      String? waLabel;
      if (res.action?.type == 'whatsapp' && (res.action?.url ?? '').isNotEmpty) {
        waUrl = res.action!.url;
        waLabel = res.action!.label ?? 'Escribir por WhatsApp';
      }
      if (res.action?.type == 'confirm_add' && res.action?.id != null) {
        final a = res.action!;
        pending = _PendingAdd(
          id: a.id!,
          nombre: a.nombre ?? 'Producto',
          precio: a.precio ?? 0,
          stock: a.stock ?? 0,
          qty: a.qty < 1 ? 1 : a.qty,
          imagenUrl: a.imagenUrl ?? '',
        );
      }

      setState(() {
        _awaiting = (res.awaiting != null && res.awaiting!.isNotEmpty) ? res.awaiting : null;
        if (res.complaint != null) _complaint = res.complaint;
        if (res.products.isNotEmpty) {
          _offered = res.products;
        }
        _msgs.add(
          _ChatMsg(
            text: res.reply,
            fromUser: false,
            products: res.products,
            driver: res.driver,
            pendingAdd: pending,
            whatsappUrl: waUrl,
            whatsappLabel: waLabel,
            pedidos: res.pedidos,
            needLogin: res.action?.type == 'login',
          ),
        );
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      setState(() {
        _msgs.add(_ChatMsg(text: msg, fromUser: false, driver: 'error'));
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _askConfirm(Map<String, dynamic> p, {int qty = 1}) {
    final id = int.tryParse(p['id']?.toString() ?? '');
    if (id == null) return;
    final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
    final precio = double.tryParse(p['precio']?.toString() ?? '0') ?? 0;
    final nombre = p['nombre']?.toString() ?? 'Producto';
    final q = qty.clamp(1, stock < 1 ? 1 : stock);
    setState(() {
      _msgs.add(
        _ChatMsg(
          text:
              '¿Agrego $nombre × $q (S/ ${precio.toStringAsFixed(2)} c/u) al carrito?',
          fromUser: false,
          driver: 'rules',
          pendingAdd: _PendingAdd(
            id: id,
            nombre: nombre,
            precio: precio,
            stock: stock,
            qty: q,
            imagenUrl: p['imagen_url']?.toString() ?? '',
          ),
        ),
      );
    });
    _scrollToEnd();
  }

  void _confirmAdd(_PendingAdd pending) {
    final cart = context.read<CartProvider>();
    final result = cart.addItem(
      CartItem(
        id: pending.id,
        nombre: pending.nombre,
        precio: pending.precio,
        imagenUrl: pending.imagenUrl,
        stockMax: pending.stock,
        cantidad: pending.qty,
      ),
    );

    final reply = switch (result) {
      CartAddResult.added => '${pending.nombre} × ${pending.qty} se agregó al carrito.',
      CartAddResult.increased => 'Sumé ${pending.qty} más de ${pending.nombre} al carrito.',
      CartAddResult.atLimit =>
        'Llegaste al stock máximo de ${pending.nombre} (${pending.stock}).',
      CartAddResult.outOfStock => '${pending.nombre} está agotado.',
    };


    setState(() {
      _msgs.add(_ChatMsg(text: reply, fromUser: false, driver: 'cart'));
    });
    _scrollToEnd();

    if (result == CartAddResult.added || result == CartAddResult.increased) {
      AppSnackBar.ok(
        context,
        reply,
        actionLabel: 'Ver carrito',
        onAction: () => AppRouter.router.push('/cart'),
      );
    } else {
      AppSnackBar.err(context, reply);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Dori'),
        backgroundColor: _gold,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Carrito',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (_sending && i == _msgs.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
                          ),
                          SizedBox(width: 10),
                          Text('Dori está escribiendo…'),
                        ],
                      ),
                    ),
                  );
                }
                return _bubble(_msgs[i]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ej. regalo de cumpleaños',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE7DAC6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE7DAC6)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : () => _send(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppSnackBar.err(context, 'No se pudo abrir WhatsApp');
    }
  }

  Widget _bubble(_ChatMsg m) {
    final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = m.fromUser ? _gold : Colors.white;
    final fg = Colors.black87;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: m.fromUser ? null : Border.all(color: const Color(0xFFE7DAC6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.text, style: TextStyle(color: fg, height: 1.35)),
            if (!m.fromUser && m.driver != null && m.driver != 'welcome') ...[
              const SizedBox(height: 6),
              Text(
                'via ${m.driver}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
            if (m.products.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...m.products.take(6).map((p) => _productCard(p, infoOnly: m.whatsappUrl != null)),
            ],
            if (m.pedidos.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...m.pedidos.map((o) {
                final id = o['id_pedido'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    onPressed: () => _send('pedido $id'),
                    child: Text('#$id · S/ ${o['total']} · ${o['fecha'] ?? ''}'),
                  ),
                );
              }),
              TextButton(onPressed: () => _send('otro'), child: const Text('Otro / WhatsApp')),
            ],
            if (m.needLogin) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.push('/login'),
                style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black87),
                child: const Text('Iniciar sesión'),
              ),
            ],
            if (m.whatsappUrl != null) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _openWhatsApp(m.whatsappUrl!),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black87,
                ),
                child: Text(m.whatsappLabel ?? 'Escribir por WhatsApp'),
              ),
            ],
            if (m.pendingAdd != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _confirmAdd(m.pendingAdd!),
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Sí, agregar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _msgs.add(
                          _ChatMsg(
                            text: 'Listo, no lo agregué. Puedes elegir otra opción.',
                            fromUser: false,
                            driver: 'cart',
                          ),
                        );
                      });
                      _scrollToEnd();
                    },
                    child: const Text('No'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p, {bool infoOnly = false}) {
    final id = p['id'];
    final nombre = p['nombre']?.toString() ?? 'Producto';
    final precio = p['precio'];
    final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
    final agotado = stock < 1;
    final img = (p['imagen_url'] ?? p['imagenUrl'])?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cream,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (img != null && img.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                      ),
                    ),
                  if (img != null && img.isNotEmpty) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoOnly
                          ? '$nombre\nProducto del pedido (referencia)'
                          : '$nombre\nS/ ${precio is num ? precio.toStringAsFixed(2) : precio} · stock $stock',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (!infoOnly) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton(
                      onPressed: id == null ? null : () => context.push('/producto/$id'),
                      child: const Text('Ver'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.tonal(
                      onPressed: agotado ? null : () => _askConfirm(p),
                      style: FilledButton.styleFrom(
                        backgroundColor: agotado ? Colors.grey.shade300 : _gold,
                        foregroundColor: Colors.black87,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(agotado ? 'Agotado' : 'Agregar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
