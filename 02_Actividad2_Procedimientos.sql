-- ========================================================================================
-- ARCHIVO: 01_PA3_Actividad2_Procedimientos.sql
-- AUTOR: Gustavo (Diseño) / Mauricio (Implementación)
-- OBJETIVO: Actividad 2 - Implementación del Mantenimiento de Pedidos y Stock.
-- ========================================================================================
USE NovaMarket;
GO

/* ========================================================================================
   PROCEDIMIENTO: Registro de Pedidos y Validación de Stock (usp_RegistrarPedido)
   Basado en el pseudocódigo y reglas de la Actividad 1.
======================================================================================== */
CREATE OR ALTER PROCEDURE usp_RegistrarPedido
    -- PARÁMETROS DE ENTRADA
    @ClienteID INT,
    @ProductoID INT,
    @Cantidad INT,
    @Canal VARCHAR(20),
    @FechaPedido DATE,
    -- PARÁMETROS DE SALIDA
    @NuevoPedidoID INT OUTPUT,
    @StockRestante INT OUTPUT,
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PrecioActual DECIMAL(10,2);
    DECLARE @StockActual INT;

    -- 1. Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE ClienteID = @ClienteID AND Activo = 1)
    BEGIN
        SET @Mensaje = 'Error: Cliente no encontrado o inactivo.';
        RETURN -1; -- Fracaso
    END

    -- 2. Verificar si el producto existe y obtener sus datos
    SELECT @StockActual = Stock, @PrecioActual = PrecioLista 
    FROM Producto 
    WHERE ProductoID = @ProductoID AND Activo = 1;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Mensaje = 'Error: Producto no encontrado o inactivo.';
        RETURN -2; -- Fracaso
    END

    -- 3. Verificar que la cantidad sea válida
    IF @Cantidad <= 0
    BEGIN
        SET @Mensaje = 'Error: La cantidad debe ser mayor a cero.';
        RETURN -3; -- Fracaso
    END

    -- 4. Consultar y verificar el stock
    IF @StockActual < @Cantidad
    BEGIN
        SET @Mensaje = 'Error: Stock insuficiente. Stock actual: ' + CAST(@StockActual AS VARCHAR);
        RETURN -4; -- Fracaso
    END

    -- ==============================================================
    -- LÓGICA DE REGISTRO (MANTENIMIENTO)
    -- ==============================================================

    -- 5. Registrar el Pedido
    INSERT INTO Pedido (ClienteID, FechaPedido, Estado, Canal)
    VALUES (@ClienteID, @FechaPedido, 'CONFIRMADO', @Canal);

    -- Obtener el ID generado
    SET @NuevoPedidoID = @@IDENTITY;

    -- 6. Registrar el Detalle del Pedido
    INSERT INTO DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
    VALUES (@NuevoPedidoID, @ProductoID, @Cantidad, @PrecioActual);

    -- 7. Descontar stock
    UPDATE Producto
    SET Stock = Stock - @Cantidad
    WHERE ProductoID = @ProductoID;

    -- Calcular salidas
    SET @StockRestante = @StockActual - @Cantidad;
    SET @Mensaje = 'Pedido registrado correctamente.';

    RETURN 1; -- Éxito
END;
GO

/* ========================================================================================
   PRUEBAS Y EJECUCIÓN (Requisito de la Rúbrica)
======================================================================================== */

PRINT '-------------------------------------------------------';
PRINT ' PRUEBA 1: Registro Exitoso                            ';
PRINT '-------------------------------------------------------';
DECLARE @Out_PedidoID INT, @Out_Stock INT, @Out_Mensaje VARCHAR(100), @Retorno INT;

EXEC @Retorno = usp_RegistrarPedido 
    @ClienteID = 1, @ProductoID = 1, @Cantidad = 2, @Canal = 'WEB', @FechaPedido = '2026-11-06',
    @NuevoPedidoID = @Out_PedidoID OUTPUT, @StockRestante = @Out_Stock OUTPUT, @Mensaje = @Out_Mensaje OUTPUT;

SELECT @Retorno AS ValorRetorno, @Out_Mensaje AS Mensaje, @Out_PedidoID AS PedidoGenerado, @Out_Stock AS StockSobrante;
GO


PRINT '-------------------------------------------------------';
PRINT ' PRUEBA 2: Error por Stock Insuficiente (Caso Negativo)';
PRINT '-------------------------------------------------------';
DECLARE @Out_PedidoID2 INT, @Out_Stock2 INT, @Out_Mensaje2 VARCHAR(100), @Retorno2 INT;

-- Intentamos comprar 500 unidades (Sobrepasa el stock)
EXEC @Retorno2 = usp_RegistrarPedido 
    @ClienteID = 1, @ProductoID = 1, @Cantidad = 500, @Canal = 'APP', @FechaPedido = '2026-11-06',
    @NuevoPedidoID = @Out_PedidoID2 OUTPUT, @StockRestante = @Out_Stock2 OUTPUT, @Mensaje = @Out_Mensaje2 OUTPUT;

SELECT @Retorno2 AS ValorRetorno, @Out_Mensaje2 AS Mensaje;
GO

PRINT '-------------------------------------------------------';
PRINT ' PRUEBA 3: Error por Cliente Inexistente (Caso Negativo)';
PRINT '-------------------------------------------------------';
DECLARE @Out_PedidoID3 INT, @Out_Stock3 INT, @Out_Mensaje3 VARCHAR(100), @Retorno3 INT;

-- Intentamos comprar con un ClienteID que no existe (999)
EXEC @Retorno3 = usp_RegistrarPedido 
    @ClienteID = 999, @ProductoID = 2, @Cantidad = 1, @Canal = 'TIENDA', @FechaPedido = '2026-11-06',
    @NuevoPedidoID = @Out_PedidoID3 OUTPUT, @StockRestante = @Out_Stock3 OUTPUT, @Mensaje = @Out_Mensaje3 OUTPUT;

SELECT @Retorno3 AS ValorRetorno, @Out_Mensaje3 AS Mensaje;
GO