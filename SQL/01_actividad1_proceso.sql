/*
=
PA3 - ACTIVIDAD 1
IDENTIFICACION DEL PROCESO A AUTOMATIZAR
CASO: NOVAMARKET


PROCESO SELECCIONADO:
Registro de pedidos y validacion de stock.

------------------------------------------------------------


En NovaMarket los clientes realizan pedidos de diferentes
productos. Antes de registrar una venta, es necesario comprobar
que el cliente y el producto existan y que haya suficiente stock.

El proceso que se propone automatizar consiste en recibir los
datos del pedido, validar la informacion y, si todo esta correcto,
registrar el pedido y descontar del stock la cantidad vendida.

La idea es que estas validaciones no tengan que repetirse cada
vez desde una aplicacion diferente, sino que puedan manejarse
desde SQL Server mediante un procedimiento almacenado.

------------------------------------------------------------
ENTRADAS


Para realizar el proceso se necesitan los siguientes datos:

- ClienteID: identifica al cliente que realiza el pedido.
- ProductoID: identifica el producto solicitado.
- Cantidad: indica cuantas unidades desea comprar.
- Canal: indica desde donde se realizo el pedido.
- FechaPedido: fecha en la que se registra la operacion.

------------------------------------------------------------
SALIDAS


Al finalizar el proceso se espera obtener:

- El identificador del pedido generado.
- Un mensaje indicando si el pedido se registro correctamente.
- El stock restante del producto.

En caso de que no se pueda realizar la operacion, se debe
informar el motivo, por ejemplo: cliente inexistente, producto
inexistente o stock insuficiente.

------------------------------------------------------------
REGLAS DEL PROCESO


1. El cliente debe existir en la tabla Cliente.

2. El producto debe existir en la tabla Producto.

3. La cantidad solicitada debe ser mayor a cero.

4. El producto debe contar con stock suficiente.

5. Si las validaciones son correctas, se registra el pedido.

6. El producto solicitado se registra en DetallePedido.

7. Luego de la venta se descuenta del stock la cantidad vendida.

8. Si alguna validacion falla, el pedido no debe continuar.

------------------------------------------------------------
¿POR QUE CONVIENE AUTOMATIZARLO EN EL SERVIDOR?


Este proceso se realiza varias veces y contiene reglas que
siempre deben cumplirse.

Si toda esta logica se coloca en un procedimiento almacenado,
las aplicaciones que utilicen la base de datos pueden llamar al
mismo proceso sin tener que repetir las mismas consultas y
validaciones.

Tambien resulta mas sencillo realizar cambios posteriormente,
porque la logica principal se encuentra centralizada en SQL
Server.

------------------------------------------------------------
RELACION CLIENTE / SERVIDOR

La aplicacion cliente se encarga de enviar la informacion
necesaria para realizar el pedido.

Por ejemplo:

ClienteID
ProductoID
Cantidad
Canal

                |
                v

        APLICACION CLIENTE

                |
                | envia los datos
                v

           SQL SERVER

                |
                | valida al cliente
                | valida el producto
                | consulta el stock
                | registra el pedido
                | registra el detalle
                | actualiza el stock
                v

        RESPUESTA AL CLIENTE

        Pedido registrado correctamente
                    o
        mensaje indicando el problema


------------------------------------------------------------
PSEUDOCODIGO


INICIO

    Recibir ClienteID
    Recibir ProductoID
    Recibir Cantidad
    Recibir Canal
    Recibir FechaPedido

    Verificar si el cliente existe

    SI el cliente no existe
        Mostrar "Cliente no encontrado"
        Finalizar proceso
    FIN SI

    Verificar si el producto existe

    SI el producto no existe
        Mostrar "Producto no encontrado"
        Finalizar proceso
    FIN SI

    Verificar que la cantidad sea mayor a cero

    SI la cantidad no es valida
        Mostrar "Cantidad incorrecta"
        Finalizar proceso
    FIN SI

    Consultar stock del producto

    SI el stock es suficiente

        Registrar pedido

        Registrar detalle del pedido

        Descontar la cantidad vendida del stock

        Mostrar "Pedido registrado correctamente"

    SINO

        Mostrar "Stock insuficiente"

    FIN SI

FIN

============================================================
*/