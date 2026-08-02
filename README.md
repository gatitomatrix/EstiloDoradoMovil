# Estilo Dorado — App móvil (Flutter)

Cliente móvil de la tienda **Estilo Dorado**, conectado al API Laravel y alineado con el flujo de compra de Angular.

> **Alcance:** esta app es solo **cliente** (catálogo, carrito, checkout, mis compras, cuenta).  
> El **panel de administración** (productos, inventario, proveedores, reportes) se implementa en la **aplicación web** (Angular), según el informe del proyecto.

## Flujo de compra (cliente)

1. **Inicio / catálogo** → detalle de producto → carrito  
2. **Carrito** → Continuar compra (requiere login)  
3. **Entrega** → Retiro en tienda **o** Envío Express (ubigeo + geocoding + mapa)  
4. **Confirmar entrega** (costos: pickup S/0 · express S/20 − S/5 dto)  
5. **Pago** — Efectivo (solo tienda) / Yape / Tarjeta + boleta o factura  
6. **Compra exitosa** → PDF/XML/CDR si aplica  
7. **Mis compras** (lista, detalle, pagar pendiente, cancelar si aplica)

### API

```bash
# Emulador Android (default → http://10.0.2.2:8000/api)
flutter run

# Celular físico / backend remoto
flutter run --dart-define=API_BASE=http://TU_IP:8000/api
```

| Acción | Método | Ruta |
|--------|--------|------|
| Confirmar pedido | POST | `/api/pedidos/confirmar` |
| Mis pedidos | GET | `/api/pedidos` |
| Detalle pedido | GET | `/api/pedidos/{id}` |
| Cancelar pendiente | POST | `/api/pedidos/{id}/cancelar` |
| Pagar pendiente | POST | `/api/pedidos/{id}/pagar` |
| Geo search / reverse | GET | `/api/geo/search`, `/api/geo/reverse` |

### Nota Culqi

En móvil el cobro es **simulado** (`tok_mobile_*` / `ype_mobile_*`) para validar pedido + comprobante (SUNAT beta). Integrar SDK Culqi cuando tengas claves reales.

## Estructura

```
lib/
  core/          # API, providers, modelos, tema
  features/
    auth/        # login, registro, recuperar
    home/        # catálogo
    products/    # detalle
    cart/
    checkout/    # entrega, mapa, pago
    orders/      # mis compras, resumen, éxito
    account/     # mi cuenta
```
