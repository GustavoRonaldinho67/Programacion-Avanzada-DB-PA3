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

### Actividad 4 - Pruebas comparativas y argumentación

Archivos de la actividad:

- `004_Actividad4_Pruebas_Comparativas.sql`: ejecuta un escenario confirmado y
  otro cancelado. Compara el total de pedidos y el stock antes y después.
- `ACTIVIDAD4.md`: matriz de escenarios, interpretación, justificación y orden
  de ejecución.

El escenario confirmado registra un pedido de una unidad. El escenario cancelado
solicita una cantidad superior al stock disponible. El procedimiento captura el
error y revierte los cambios de la transacción.

Orden de ejecución:

1. `00_esquema_y_datos_base.sql`
2. `004_Actividad4_Programacion_Almacenada.sql`
3. `004_Actividad4_Pruebas_Comparativas.sql`
