# PA3 - Programacion Avanzada de Base de Datos



## Caso: NovaMarket

### Actividad 1 - Identificación del proceso a automatizar

El proceso seleccionado es el registro de pedidos y la validación de stock.

La operación consiste en recibir los datos del pedido, validar que el cliente y el producto existan, comprobar que la cantidad solicitada sea válida y verificar que exista stock suficiente.

Si las validaciones son correctas, el pedido puede continuar con su registro y la actualización del stock correspondiente.

La automatización de este proceso en SQL Server permite centralizar la lógica y evitar repetir las mismas validaciones desde diferentes aplicaciones cliente.

### Entradas del proceso

- ClienteID
- ProductoID
- Cantidad
- Canal
- FechaPedido

### Salidas esperadas

- Identificador del pedido
- Confirmación del registro
- Stock restante
- Mensaje de error si la operación no puede realizarse

### Archivo desarrollado

`01_actividad1_proceso.sql`

### Responsable

Gustavo - Actividad 1

### Actividad 4 - Programación almacenada, transacciones y manejo de errores

El archivo `004_Actividad4_Programacion_Almacenada.sql` contiene la entrega
completa del tema 4 sobre SQL Server:

- Funciones `fn_PrecioVigente` y `fn_DetallePedido` para reutilizar lógica de negocio.
- `sp_RegistrarPedido`, con validación de cliente, producto, cantidad y stock,
  bloqueo `UPDLOCK/HOLDLOCK`, transacción atómica y reversión ante errores.
- `sp_AnularPedido`, que revierte el stock y cambia el estado del pedido dentro
  de una transacción.
- `sp_ConsultarPedido`, que devuelve cabecera, cliente, detalle e importe total.
- `sp_ReponerStock`, con validaciones y control transaccional del inventario.
- `sp_ReporteVentas`, con filtros por fechas y resumen por canal y estado.
- `sp_ReporteProductosStockBajo`, que demuestra un cursor local `FAST_FORWARD`.
- Tabla `ErrorProceso` para registrar número, línea, procedimiento y mensaje de
  los errores capturados.
- Casos de prueba positivos y negativos comentados al final del script.

Orden de ejecución: primero `00_esquema_y_datos_base.sql` y después el archivo
de la actividad 4. Las pruebas se pueden descomentar gradualmente en SQL Server.
