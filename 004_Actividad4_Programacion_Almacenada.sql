/*
PA3 - ACTIVIDAD 4
PROGRAMACION ALMACENADA, TRANSACCIONES Y MANEJO DE ERRORES
CASO: NOVAMARKET

Ejecutar despues de 00_esquema_y_datos_base.sql.
*/

USE NovaMarket;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPedido
    @ClienteID INT,
    @ProductoID INT,
    @Cantidad INT,
    @Canal VARCHAR(20),
    @FechaPedido DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PedidoID INT;
    DECLARE @PrecioUnitario DECIMAL(10, 2);

    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 50001, 'La cantidad debe ser mayor que cero.', 1;

        IF NULLIF(LTRIM(RTRIM(@Canal)), '') IS NULL
            THROW 50002, 'El canal del pedido es obligatorio.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteID = @ClienteID AND Activo = 1)
            THROW 50003, 'El cliente no existe o se encuentra inactivo.', 1;

        BEGIN TRANSACTION;

        /* UPDLOCK/HOLDLOCK evita confirmar el mismo stock en dos sesiones. */
        SELECT @PrecioUnitario = COALESCE(PrecioOferta, PrecioLista)
        FROM dbo.Producto WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductoID = @ProductoID AND Activo = 1 AND Stock >= @Cantidad;

        IF @PrecioUnitario IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Producto WHERE ProductoID = @ProductoID AND Activo = 1)
                THROW 50004, 'El producto no existe o se encuentra inactivo.', 1;

            THROW 50005, 'Stock insuficiente para completar el pedido.', 1;
        END;

        INSERT INTO dbo.Pedido (ClienteID, FechaPedido, Estado, Canal)
        VALUES (@ClienteID, COALESCE(@FechaPedido, CONVERT(date, GETDATE())), 'CONFIRMADO', @Canal);

        SET @PedidoID = CONVERT(INT, SCOPE_IDENTITY());

        INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
        VALUES (@PedidoID, @ProductoID, @Cantidad, @PrecioUnitario);

        UPDATE dbo.Producto
        SET Stock = Stock - @Cantidad
        WHERE ProductoID = @ProductoID;

        COMMIT TRANSACTION;

        SELECT
            @PedidoID AS PedidoID,
            'Pedido registrado correctamente.' AS Mensaje,
            Stock AS StockRestante
        FROM dbo.Producto
        WHERE ProductoID = @ProductoID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReporteProductosStockBajo
    @StockMaximo INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @StockMaximo < 0
        THROW 50006, 'El stock maximo no puede ser negativo.', 1;

    DECLARE @ProductoID INT;
    DECLARE @Nombre VARCHAR(80);
    DECLARE @Stock INT;

    DECLARE productos_stock_bajo CURSOR LOCAL FAST_FORWARD FOR
        SELECT ProductoID, Nombre, Stock
        FROM dbo.Producto
        WHERE Activo = 1 AND Stock <= @StockMaximo
        ORDER BY Stock, Nombre;

    CREATE TABLE #StockBajo
    (
        ProductoID INT NOT NULL,
        Nombre VARCHAR(80) NOT NULL,
        Stock INT NOT NULL
    );

    OPEN productos_stock_bajo;
    FETCH NEXT FROM productos_stock_bajo INTO @ProductoID, @Nombre, @Stock;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #StockBajo (ProductoID, Nombre, Stock)
        VALUES (@ProductoID, @Nombre, @Stock);

        FETCH NEXT FROM productos_stock_bajo INTO @ProductoID, @Nombre, @Stock;
    END;

    CLOSE productos_stock_bajo;
    DEALLOCATE productos_stock_bajo;

    SELECT ProductoID, Nombre, Stock
    FROM #StockBajo
    ORDER BY Stock, Nombre;
END;
GO

/* Pruebas sugeridas: */
-- EXEC dbo.sp_RegistrarPedido @ClienteID = 1, @ProductoID = 1, @Cantidad = 1, @Canal = 'WEB';
-- EXEC dbo.sp_ReporteProductosStockBajo @StockMaximo = 10;
-- EXEC dbo.sp_RegistrarPedido @ClienteID = 1, @ProductoID = 1, @Cantidad = 0, @Canal = 'WEB';
