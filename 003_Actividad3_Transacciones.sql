============================================================================

CREATE OR ALTER PROCEDURE sp_RegistrarPedidoTransaccional
    @ClienteID INT,
    @ProductoID INT,
    @Cantidad INT
AS
BEGIN
    -- Configuración para manejar errores de forma estricta y evitar lecturas sucias
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Inicio de la Transacción Explícita (Unidad Lógica de Trabajo)
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Validación de existencia y estado del Cliente
        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE ClienteID = @ClienteID AND Activo = 1)
        BEGIN
            RAISERROR('El cliente especificado no existe o se encuentra inactivo.', 16, 1);
        END

        -- 2. Validación de existencia y Stock suficiente del Producto
        DECLARE @StockActual INT;
        SELECT @StockActual = Stock 
        FROM Producto 
        WHERE ProductoID = @ProductoID;

        IF @StockActual IS NULL
        BEGIN
            RAISERROR('El producto especificado no existe.', 16, 1);
        END

        IF @StockActual < @Cantidad
        BEGIN
            RAISERROR('Stock insuficiente para completar el pedido.', 16, 1);
        END

        -- 3. Operación A: Registrar la cabecera del Pedido
        INSERT INTO Pedido (ClienteID, Fecha)
        VALUES (@ClienteID, GETDATE());

        DECLARE @NuevoPedidoID INT = SCOPE_IDENTITY();

        -- 4. Operación B: Registrar el detalle del Pedido
        INSERT INTO DetallePedido (PedidoID, ProductoID, Cantidad)
        VALUES (@NuevoPedidoID, @ProductoID, @Cantidad);

        -- 5. Operación C: Actualizar/Descontar el stock del producto
        UPDATE Producto
        SET Stock = Stock - @Cantidad
        WHERE ProductoID = @ProductoID;

        -- Confirmación Explícita: Si todas las operaciones se realizaron con éxito
        COMMIT TRANSACTION;
        PRINT 'Transacción completada con éxito. Pedido registrado y stock actualizado.';

    END TRY
    BEGIN CATCH
        -- Cancelación Explícita: Si ocurre cualquier error, se revierten todos los cambios
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        -- Reporte del mensaje de error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO