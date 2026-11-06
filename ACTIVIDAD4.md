# Actividad 4 - Pruebas comparativas y argumentación

## Procedimiento evaluado

`sp_RegistrarPedido` registra el pedido, registra el detalle y descuenta el stock dentro de una transacción explícita.

## Escenarios

| Escenario | Entrada | Resultado esperado |
|---|---|---|
| Confirmación | Cliente 1, producto 1, cantidad 1 | Se crea un pedido, se crea su detalle y el stock disminuye en 1. |
| Cancelación | Cliente 1, producto 1, cantidad 999999 | Se genera un error; no se crea pedido, no se crea detalle y el stock no cambia. |

## Comparación

El archivo `004_Actividad4_Pruebas_Comparativas.sql` registra el estado de `Pedido` y `Producto` antes y después de cada escenario. Al final devuelve una fila por prueba con el resultado `CORRECTA` o `INCORRECTA`.

En la confirmación, el total de pedidos aumenta en uno y el stock del producto disminuye en una unidad. En la cancelación, los valores permanecen iguales a los obtenidos después de la confirmación.

## Interpretación

La primera prueba demuestra que la transacción se confirma cuando todas las operaciones son válidas. La segunda demuestra que el error detiene el proceso y revierte los cambios parciales. Por eso no queda un pedido sin detalle ni un descuento de stock sin pedido confirmado.

## Justificación

El procedimiento centraliza las reglas del proceso en SQL Server. La aplicación cliente solo envía los datos del pedido y recibe el resultado. `BEGIN TRANSACTION`, `COMMIT TRANSACTION`, `ROLLBACK TRANSACTION` y `TRY...CATCH` mantienen la coherencia entre `Pedido`, `DetallePedido` y `Producto`.

## Ejecución

1. Ejecutar `00_esquema_y_datos_base.sql`.
2. Ejecutar `004_Actividad4_Programacion_Almacenada.sql`.
3. Ejecutar `004_Actividad4_Pruebas_Comparativas.sql`.
4. Guardar las filas de resultados y las capturas de SQL Server como evidencia de la ejecución.
