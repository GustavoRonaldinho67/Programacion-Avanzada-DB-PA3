/*
PA3 - ACTIVIDAD 4
PROGRAMACION ALMACENADA, TRANSACCIONES, CURSORES Y MANEJO DE ERRORES
CASO: NOVAMARKET

Prerequisito: ejecutar 00_esquema_y_datos_base.sql.
Este script es idempotente: puede ejecutarse mas de una vez.
*/
USE NovaMarket;
GO

IF OBJECT_ID('dbo.ErrorProceso', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ErrorProceso
    (
        ErrorProcesoID INT IDENTITY(1,1) PRIMARY KEY,
        FechaError DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        Procedimiento SYSNAME NULL,
        NumeroError INT NULL,
        Severidad INT NULL,
        Estado INT NULL,
        Linea INT NULL,
        Mensaje NVARCHAR(4000) NOT NULL,
        UsuarioBD SYSNAME NOT NULL DEFAULT SUSER_SNAME()
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_PrecioVigente(@ProductoID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Precio DECIMAL(10,2);
    SELECT @Precio = COALESCE(PrecioOferta, PrecioLista)
    FROM dbo.Producto WHERE ProductoID = @ProductoID AND Activo = 1;
    RETURN @Precio;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_DetallePedido(@PedidoID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT d.DetalleID, d.PedidoID, d.ProductoID, p.Nombre AS Producto,
           d.Cantidad, d.PrecioUnitario,
           CONVERT(DECIMAL(12,2), d.Cantidad * d.PrecioUnitario) AS Importe
    FROM dbo.DetallePedido AS d
    INNER JOIN dbo.Producto AS p ON p.ProductoID = d.ProductoID
    WHERE d.PedidoID = @PedidoID
);
GO

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPedido
    @ClienteID INT, @ProductoID INT, @Cantidad INT,
    @Canal VARCHAR(20), @FechaPedido DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @PedidoID INT, @Precio DECIMAL(10,2), @StockRestante INT;
    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 50001, 'La cantidad debe ser mayor que cero.', 1;
        IF NULLIF(LTRIM(RTRIM(@Canal)), '') IS NULL
            THROW 50002, 'El canal del pedido es obligatorio.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteID = @ClienteID AND Activo = 1)
            THROW 50003, 'El cliente no existe o se encuentra inactivo.', 1;

        BEGIN TRANSACTION;
        SELECT @Precio = COALESCE(PrecioOferta, PrecioLista), @StockRestante = Stock
        FROM dbo.Producto WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductoID = @ProductoID AND Activo = 1;
        IF @Precio IS NULL THROW 50004, 'El producto no existe o se encuentra inactivo.', 1;
        IF @StockRestante < @Cantidad THROW 50005, 'Stock insuficiente para completar el pedido.', 1;

        INSERT INTO dbo.Pedido (ClienteID, FechaPedido, Estado, Canal)
        VALUES (@ClienteID, COALESCE(@FechaPedido, CONVERT(date, GETDATE())), 'CONFIRMADO', @Canal);
        SET @PedidoID = CONVERT(INT, SCOPE_IDENTITY());
        INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
        VALUES (@PedidoID, @ProductoID, @Cantidad, @Precio);
        UPDATE dbo.Producto SET Stock = Stock - @Cantidad WHERE ProductoID = @ProductoID;
        SET @StockRestante = @StockRestante - @Cantidad;
        COMMIT TRANSACTION;
        SELECT @PedidoID AS PedidoID, 'Pedido registrado correctamente.' AS Mensaje,
               @StockRestante AS StockRestante, @Precio AS PrecioUnitario;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO dbo.ErrorProceso (Procedimiento, NumeroError, Severidad, Estado, Linea, Mensaje)
        VALUES (ERROR_PROCEDURE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AnularPedido @PedidoID INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Pedido WITH (UPDLOCK, HOLDLOCK) WHERE PedidoID = @PedidoID)
            THROW 50007, 'El pedido no existe.', 1;
        IF EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = @PedidoID AND Estado = 'ANULADO')
            THROW 50008, 'El pedido ya se encuentra anulado.', 1;
        UPDATE p SET p.Stock = p.Stock + d.Cantidad
        FROM dbo.Producto AS p INNER JOIN dbo.DetallePedido AS d ON d.ProductoID = p.ProductoID
        WHERE d.PedidoID = @PedidoID;
        UPDATE dbo.Pedido SET Estado = 'ANULADO' WHERE PedidoID = @PedidoID;
        COMMIT TRANSACTION;
        SELECT @PedidoID AS PedidoID, 'Pedido anulado y stock restituido.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO dbo.ErrorProceso (Procedimiento, NumeroError, Severidad, Estado, Linea, Mensaje)
        VALUES (ERROR_PROCEDURE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ConsultarPedido @PedidoID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = @PedidoID)
        THROW 50009, 'El pedido no existe.', 1;
    SELECT pe.PedidoID, pe.FechaPedido, pe.Estado, pe.Canal,
           c.ClienteID, c.Nombre AS Cliente, c.Documento,
           CONVERT(DECIMAL(12,2), SUM(d.Importe)) AS TotalPedido
    FROM dbo.Pedido AS pe
    INNER JOIN dbo.Cliente AS c ON c.ClienteID = pe.ClienteID
    INNER JOIN dbo.fn_DetallePedido(@PedidoID) AS d ON d.PedidoID = pe.PedidoID
    WHERE pe.PedidoID = @PedidoID
    GROUP BY pe.PedidoID, pe.FechaPedido, pe.Estado, pe.Canal,
             c.ClienteID, c.Nombre, c.Documento;
    SELECT * FROM dbo.fn_DetallePedido(@PedidoID) ORDER BY DetalleID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReponerStock @ProductoID INT, @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 50010, 'La cantidad de reposicion debe ser mayor que cero.', 1;
        BEGIN TRANSACTION;
        UPDATE dbo.Producto WITH (UPDLOCK) SET Stock = Stock + @Cantidad
        WHERE ProductoID = @ProductoID AND Activo = 1;
        IF @@ROWCOUNT = 0 THROW 50011, 'El producto no existe o esta inactivo.', 1;
        COMMIT TRANSACTION;
        SELECT ProductoID, Nombre, Stock FROM dbo.Producto WHERE ProductoID = @ProductoID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO dbo.ErrorProceso (Procedimiento, NumeroError, Severidad, Estado, Linea, Mensaje)
        VALUES (ERROR_PROCEDURE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReporteVentas @Desde DATE = NULL, @Hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Desde IS NOT NULL AND @Hasta IS NOT NULL AND @Desde > @Hasta
        THROW 50012, 'El rango de fechas no es valido.', 1;
    SELECT pe.Canal, pe.Estado, COUNT(DISTINCT pe.PedidoID) AS Pedidos,
           SUM(d.Cantidad) AS Unidades,
           CONVERT(DECIMAL(12,2), SUM(d.Cantidad * d.PrecioUnitario)) AS ImporteTotal
    FROM dbo.Pedido AS pe INNER JOIN dbo.DetallePedido AS d ON d.PedidoID = pe.PedidoID
    WHERE (@Desde IS NULL OR pe.FechaPedido >= @Desde)
      AND (@Hasta IS NULL OR pe.FechaPedido <= @Hasta)
    GROUP BY pe.Canal, pe.Estado ORDER BY pe.Canal, pe.Estado;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReporteProductosStockBajo @StockMaximo INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    IF @StockMaximo < 0 THROW 50013, 'El stock maximo no puede ser negativo.', 1;
    DECLARE @ProductoID INT, @Nombre VARCHAR(80), @Stock INT;
    DECLARE productos_stock_bajo CURSOR LOCAL FAST_FORWARD FOR
        SELECT ProductoID, Nombre, Stock FROM dbo.Producto
        WHERE Activo = 1 AND Stock <= @StockMaximo ORDER BY Stock, Nombre;
    CREATE TABLE #StockBajo (ProductoID INT, Nombre VARCHAR(80), Stock INT);
    OPEN productos_stock_bajo;
    FETCH NEXT FROM productos_stock_bajo INTO @ProductoID, @Nombre, @Stock;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #StockBajo VALUES (@ProductoID, @Nombre, @Stock);
        FETCH NEXT FROM productos_stock_bajo INTO @ProductoID, @Nombre, @Stock;
    END;
    CLOSE productos_stock_bajo; DEALLOCATE productos_stock_bajo;
    SELECT ProductoID, Nombre, Stock FROM #StockBajo ORDER BY Stock, Nombre;
END;
GO

