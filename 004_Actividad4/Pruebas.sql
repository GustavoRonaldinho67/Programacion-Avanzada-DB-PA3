/*
PA3 · NovaMarket
Actividad 4. Pruebas comparativas y argumentación

En una copia de pruebas de NovaMarket, cargar 00_esquema_y_datos_base.sql
una sola vez. Ejecutar este archivo completo en SQL Server Management Studio.
Cada ejecución confirma una venta de una unidad del producto 1.

Matriz esperada en una base recién cargada
                            Pedidos       Detalles       Stock del producto 1
Venta de 1 unidad           40 -> 41      80 -> 81       20 -> 19
Solicitud de 999999         41 -> 41      81 -> 81       19 -> 19

El primer caso comprueba que el nuevo pedido pertenece al cliente 1, que su
detalle contiene una unidad del producto 1 y que esa unidad sale del stock.
El segundo exige el error 50005 por stock insuficiente y compara las tres
tablas con su estado inmediatamente anterior al intento.

La última cuadrícula contiene la matriz obtenida en la ejecución. En una
venta confirmada, cabecera, detalle y salida de almacén representan la misma
operación. En el rechazo por stock, SQL Server cancela esa operación antes
de insertar la cabecera. Un rechazo por otro motivo invalida la prueba,
aunque los totales coincidan.
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

-- Estado de las tablas antes y después de cada operación
SET NOCOUNT ON;

DECLARE @ClienteID INT = 1;
DECLARE @ProductoID INT = 1;
DECLARE @StockInicial INT;
DECLARE @StockDespuesConfirmacion INT;
DECLARE @StockDespuesCancelacion INT;
DECLARE @PedidosIniciales INT;
DECLARE @PedidosDespuesConfirmacion INT;
DECLARE @PedidosDespuesCancelacion INT;
DECLARE @DetallesIniciales INT;
DECLARE @DetallesDespuesConfirmacion INT;
DECLARE @DetallesDespuesCancelacion INT;
DECLARE @PedidoConfirmado INT;
DECLARE @MensajeError NVARCHAR(4000);
DECLARE @NumeroError INT;
DECLARE @Resultado TABLE
(
    PedidoID INT,
    Mensaje VARCHAR(100),
    StockRestante INT,
    PrecioUnitario DECIMAL(10,2)
);

SELECT @StockInicial = Stock
FROM dbo.Producto
WHERE ProductoID = @ProductoID AND Activo = 1;

IF @@TRANCOUNT <> 0 OR @StockInicial IS NULL OR @StockInicial NOT BETWEEN 1 AND 999999
    THROW 50101, 'Ejecute la prueba en una sesión sin transacciones abiertas y con el stock de prueba cargado.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteID = @ClienteID AND Activo = 1)
    THROW 50102, 'Falta el cliente activo de la prueba.', 1;

SELECT @PedidosIniciales = COUNT(*)
FROM dbo.Pedido;

SELECT @DetallesIniciales = COUNT(*)
FROM dbo.DetallePedido;

SELECT 'ANTES_CONFIRMACION' AS Momento,
       @PedidosIniciales AS TotalPedidos,
       @DetallesIniciales AS TotalDetalles,
       @StockInicial AS StockProducto;

INSERT INTO @Resultado
EXEC dbo.sp_RegistrarPedido
     @ClienteID = @ClienteID,
     @ProductoID = @ProductoID,
     @Cantidad = 1,
     @Canal = 'WEB',
     @FechaPedido = '2026-11-06';

SELECT @PedidoConfirmado = PedidoID FROM @Resultado;

SELECT @StockDespuesConfirmacion = Stock
FROM dbo.Producto
WHERE ProductoID = @ProductoID;

SELECT @PedidosDespuesConfirmacion = COUNT(*)
FROM dbo.Pedido;

SELECT @DetallesDespuesConfirmacion = COUNT(*)
FROM dbo.DetallePedido;

SELECT 'DESPUES_CONFIRMACION' AS Momento,
       @PedidosDespuesConfirmacion AS TotalPedidos,
       @DetallesDespuesConfirmacion AS TotalDetalles,
       @StockDespuesConfirmacion AS StockProducto,
       @PedidoConfirmado AS PedidoID;

BEGIN TRY
    EXEC dbo.sp_RegistrarPedido
         @ClienteID = @ClienteID,
         @ProductoID = @ProductoID,
         @Cantidad = 999999,
         @Canal = 'WEB',
         @FechaPedido = '2026-11-06';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 50005 THROW;
    SET @NumeroError = ERROR_NUMBER();
    SET @MensajeError = ERROR_MESSAGE();
END CATCH;

SELECT @StockDespuesCancelacion = Stock
FROM dbo.Producto
WHERE ProductoID = @ProductoID;

SELECT @PedidosDespuesCancelacion = COUNT(*)
FROM dbo.Pedido;

SELECT @DetallesDespuesCancelacion = COUNT(*)
FROM dbo.DetallePedido;

SELECT 'DESPUES_CANCELACION' AS Momento,
       @PedidosDespuesCancelacion AS TotalPedidos,
       @DetallesDespuesCancelacion AS TotalDetalles,
       @StockDespuesCancelacion AS StockProducto,
       @MensajeError AS MotivoCancelacion;

DECLARE @VentaCorrecta BIT = CASE WHEN
    @StockDespuesConfirmacion = @StockInicial - 1
    AND @PedidosDespuesConfirmacion = @PedidosIniciales + 1
    AND @DetallesDespuesConfirmacion = @DetallesIniciales + 1
    AND EXISTS (
        SELECT 1
        FROM dbo.Pedido AS p
        JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
        WHERE p.PedidoID = @PedidoConfirmado AND p.ClienteID = @ClienteID
          AND p.Estado = 'CONFIRMADO' AND p.Canal = 'WEB'
          AND d.ProductoID = @ProductoID AND d.Cantidad = 1
    ) THEN 1 ELSE 0 END;

DECLARE @RechazoCorrecto BIT = CASE WHEN
    @NumeroError = 50005 AND @@TRANCOUNT = 0
    AND @StockDespuesCancelacion = @StockDespuesConfirmacion
    AND @PedidosDespuesCancelacion = @PedidosDespuesConfirmacion
    AND @DetallesDespuesCancelacion = @DetallesDespuesConfirmacion
    THEN 1 ELSE 0 END;

SELECT Escenario, PedidosAntes, PedidosDespues, DetallesAntes, DetallesDespues,
       StockAntes, StockDespues, NumeroError, Resultado
FROM (VALUES
    (1, 'Venta de 1 unidad', @PedidosIniciales, @PedidosDespuesConfirmacion,
     @DetallesIniciales, @DetallesDespuesConfirmacion, @StockInicial,
     @StockDespuesConfirmacion, 0, IIF(@VentaCorrecta = 1, 'CORRECTA', 'INCORRECTA')),
    (2, 'Stock insuficiente', @PedidosDespuesConfirmacion, @PedidosDespuesCancelacion,
     @DetallesDespuesConfirmacion, @DetallesDespuesCancelacion, @StockDespuesConfirmacion,
     @StockDespuesCancelacion, @NumeroError, IIF(@RechazoCorrecto = 1, 'CORRECTA', 'INCORRECTA'))
) AS m(Orden, Escenario, PedidosAntes, PedidosDespues, DetallesAntes,
       DetallesDespues, StockAntes, StockDespues, NumeroError, Resultado)
ORDER BY Orden;

IF @VentaCorrecta = 0 OR @RechazoCorrecto = 0
    THROW 50104, 'La matriz de pruebas contiene una diferencia.', 1;
GO
