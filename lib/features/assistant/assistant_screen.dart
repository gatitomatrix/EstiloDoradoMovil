// lib/features/assistant/assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/assistant_service.dart';

const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFF8F1E9);

class _ChatMsg {
  final String text;
  final bool fromUser;
  final List<Map<String, dynamic>> products;
  final String? driver;

  _ChatMsg({
    required this.text,
    required this.fromUser,
    this.products = const [],
    this.driver,
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
  bool _sending = false;
  List<String> _suggestions = const [
    '¿Qué productos tienen?',
    'Cerdita tiburón',
    '¿Cómo compro?',
    'Formas de pago',
    '¿Cuántos productos hay?',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(
      _ChatMsg(
        text:
            '¡Hola! Soy el asistente de Estilo Dorado. Pregúntame por productos, precios, stock, cómo comprar o el estado de tu pedido.',
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
      final res = await _svc.send(text);
      if (!mounted) return;
      setState(() {
        _msgs.add(
          _ChatMsg(
            text: res.reply,
            fromUser: false,
            products: res.products,
            driver: res.driver,
          ),
        );
        if (res.suggestions.isNotEmpty) {
          _suggestions = res.suggestions;
        }
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      setState(() {
        _msgs.add(
          _ChatMsg(
            text: msg,
            fromUser: false,
            driver: 'error',
          ),
        );
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Asistente Estilo Dorado'),
        backgroundColor: _gold,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
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
                          Text('Pensando… (Ollama puede tardar unos segundos)'),
                        ],
                      ),
                    ),
                  );
                }
                final m = _msgs[i];
                return _bubble(m);
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _suggestions[i];
                  return ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    onPressed: _sending ? null : () => _send(s),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE7DAC6)),
                  );
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
                        hintText: 'Escribe tu pregunta…',
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

  Widget _bubble(_ChatMsg m) {
    final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = m.fromUser ? _gold : Colors.white;
    final fg = Colors.black87;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
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
              ...m.products.take(4).map((p) {
                final id = p['id'];
                final nombre = p['nombre']?.toString() ?? 'Producto';
                final precio = p['precio'];
                final stock = p['stock'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: _cream,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: id == null ? null : () => context.push('/producto/$id'),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$nombre\nS/ ${precio is num ? precio.toStringAsFixed(2) : precio} · stock $stock',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
