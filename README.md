# Estilo Dorado — App móvil (Flutter)

Cliente móvil de la tienda **Estilo Dorado**, conectado al API Laravel y alineado con el flujo de compra de Angular.

## Fase 1 (flujo de compra)

Flujo equivalente a la web:

1. **Carrito** → Continuar compra (requiere login)
2. **Entrega** → Retiro en tienda **o** Envío Express (ubigeo Perú + geocoding)
3. **Confirmar entrega** (costos: pickup S/0 · express S/20 − S/5 dto)
4. **Pago**
   - Efectivo (solo retiro en tienda) → `POST /pedidos/confirmar`
   - Yape / Tarjeta + boleta o factura → `POST /pedidos/confirmar`
5. **Resumen del pedido** (detalle + PDF/XML/CDR si aplica)
6. **Mis compras** (lista + filtros + acceso a resumen)

### API

```bash
# Emulador Android (default)
flutter run

# Celular físico / backend remoto
flutter run --dart-define=API_BASE=http://TU_IP:8000/api
```

Endpoints usados en Fase 1:

| Acción | Método | Ruta |
|--------|--------|------|
| Confirmar pedido | POST | `/api/pedidos/confirmar` |
| Mis pedidos | GET | `/api/pedidos` |
| Detalle pedido | GET | `/api/pedidos/{id}` |
| Geo search | GET | `/api/geo/search` |
| Geo reverse | GET | `/api/geo/reverse` |

### Nota Culqi

En móvil aún no hay SDK nativo de Culqi. Yape/tarjeta envían un `culqi_id` de prueba trazable (`tok_mobile_*` / `ype_mobile_*`) para validar el flujo de pedido + comprobante. Integrar Culqi Flutter/WebView cuando tengas la public key de producción/sandbox real.

## Estructura relevante

```
lib/
  core/
    config/api_config.dart
    models/checkout_models.dart
    providers/checkout_provider.dart
    providers/payment_provider.dart
    providers/cart_provider.dart
    services/order_service.dart
    services/ubigeo_service.dart
    services/geocoding_service.dart
  features/
    checkout/entrega_screen.dart
    checkout/confirmar_entrega_screen.dart
    checkout/pago_screen.dart
    orders/mis_compras_screen.dart
    orders/resumen_pedido_screen.dart
```
