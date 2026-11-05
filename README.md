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