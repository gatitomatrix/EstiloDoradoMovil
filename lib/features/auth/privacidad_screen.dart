import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estilo Dorado · Cerro de Pasco, Perú',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 16),
            Text(
              'Esta tienda trata datos personales para crear tu cuenta, atender pedidos y mejorar el servicio.',
            ),
            SizedBox(height: 18),
            Text('Datos que recopilamos', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              '• Nombre, apellido, correo, teléfono y dirección al registrarte o comprar.\n'
              '• Si entras con Google: correo y nombre (no guardamos tu contraseña de Gmail).\n'
              '• Pedidos y forma de pago. Culqi procesa la tarjeta; no guardamos el número completo.\n'
              '• Consultas al asistente Dori.',
            ),
            SizedBox(height: 18),
            Text('Para qué los usamos', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'Crear y recuperar tu cuenta, mostrar Mis compras, coordinar recojo o envío, '
              'y enviar correos de bienvenida o código de recuperación.',
            ),
            SizedBox(height: 18),
            Text('Con quién se comparte', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'No vendemos tus datos. Solo proveedores necesarios: hosting, base de datos, correo, Culqi y Google si eliges ese acceso.',
            ),
            SizedBox(height: 18),
            Text('Local de recojo', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Prolongación Yauli Nro. S/N Pasco - Pasco – Chaupimarca.'),
          ],
        ),
      ),
    );
  }
}

class PrivacidadAviso extends StatelessWidget {
  const PrivacidadAviso({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
        children: [
          const TextSpan(
            text: 'Al crear cuenta (correo o Google) aceptas el tratamiento de datos descrito en la ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => context.push('/privacidad'),
              child: const Text(
                'política de privacidad',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A6D1D),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
