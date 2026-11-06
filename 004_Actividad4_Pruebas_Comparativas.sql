USE NovaMarket;
GO

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
DECLARE @Resultado TABLE
(
    PedidoID INT,
    Mensaje VARCHAR(100),
    StockRestante INT,
    PrecioUnitario DECIMAL(10,2)
);

SELECT @StockInicial = Stock
FROM dbo.Producto
WHERE ProductoID = @ProductoID;

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

SELECT 'PRUEBA_CONFIRMACION' AS Prueba,
       @StockInicial AS StockAntes,
       @StockDespuesConfirmacion AS StockDespues,
       @PedidosIniciales AS PedidosAntes,
       @PedidosDespuesConfirmacion AS PedidosDespues,
       @DetallesIniciales AS DetallesAntes,
       @DetallesDespuesConfirmacion AS DetallesDespues,
       CASE WHEN @StockDespuesConfirmacion = @StockInicial - 1
                  AND @PedidosDespuesConfirmacion = @PedidosIniciales + 1
                  AND @DetallesDespuesConfirmacion = @DetallesIniciales + 1
            THEN 'CORRECTA' ELSE 'INCORRECTA' END AS Resultado;

SELECT 'PRUEBA_CANCELACION' AS Prueba,
       @StockDespuesConfirmacion AS StockAntes,
       @StockDespuesCancelacion AS StockDespues,
       @PedidosDespuesConfirmacion AS PedidosAntes,
       @PedidosDespuesCancelacion AS PedidosDespues,
       @DetallesDespuesConfirmacion AS DetallesAntes,
       @DetallesDespuesCancelacion AS DetallesDespues,
       CASE WHEN @StockDespuesCancelacion = @StockDespuesConfirmacion
                  AND @PedidosDespuesCancelacion = @PedidosDespuesConfirmacion
                  AND @DetallesDespuesCancelacion = @DetallesDespuesConfirmacion
            THEN 'CORRECTA' ELSE 'INCORRECTA' END AS Resultado;
GO
