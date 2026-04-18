-- ============================================================
-- FILE: triggers.sql
-- DESC: Toàn bộ trigger của hệ thống Pharma Management
-- RUN AFTER: schema.sql
-- ============================================================

USE [BTL_Restore3]
GO

-- ============================================================
-- BẢNG: Contains
-- ============================================================

-- 1. Tự động lấy giá sản phẩm tại thời điểm đặt hàng
--    (SET PriceAtOrder = Product.Price khi insert vào Contains)
CREATE TRIGGER [dbo].[trg_Contains_SetPrice]
ON [dbo].[Contains]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.PriceAtOrder = p.Price
    FROM [Contains] c
    JOIN inserted i ON c.OrderID = i.OrderID AND c.ProductID = i.ProductID
    JOIN Product  p ON p.ProductID = c.ProductID
    WHERE c.PriceAtOrder IS NULL;
END
GO

EXEC sp_settriggerorder
    @triggername = N'[dbo].[trg_Contains_SetPrice]',
    @order       = N'First',
    @stmttype    = N'INSERT'
GO

-- ============================================================

-- 2. Tự động tính Subtotal = Quantity * PriceAtOrder
CREATE TRIGGER [dbo].[trg_UpdateSubtotal]
ON [dbo].[Contains]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.Subtotal = c.Quantity * c.PriceAtOrder
    FROM [Contains] c
    JOIN inserted i ON c.OrderID = i.OrderID AND c.ProductID = i.ProductID;
END
GO

-- ============================================================

-- 3. Cập nhật TotalAmount của Order mỗi khi Contains thay đổi
CREATE TRIGGER [dbo].[trg_UpdateTotalAmount_Contains]
ON [dbo].[Contains]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE o
    SET o.TotalAmount =
        (SELECT SUM(c.Subtotal) FROM [Contains] c WHERE c.OrderID = o.OrderID)
    FROM [Order] o
    WHERE o.OrderID IN (
        SELECT OrderID FROM inserted
        UNION
        SELECT OrderID FROM deleted
    );
END
GO

-- ============================================================

-- 4. Cập nhật TotalAmount (xử lý thêm trường hợp Canceled → 0)
CREATE TRIGGER [dbo].[trg_UpdateOrderTotalAmount]
ON [dbo].[Contains]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedOrders AS (
        SELECT OrderID FROM inserted
        UNION
        SELECT OrderID FROM deleted
    )
    UPDATE o
    SET o.TotalAmount = CASE
        WHEN o.OrderStatus = 'Canceled' THEN 0
        ELSE (SELECT SUM(Subtotal) FROM [Contains] WHERE OrderID = o.OrderID)
    END
    FROM [Order] o
    INNER JOIN ChangedOrders co ON co.OrderID = o.OrderID;
END
GO

-- ============================================================

-- 5. Giảm tồn kho khi thêm sản phẩm vào đơn hàng
CREATE TRIGGER [dbo].[trg_reduce_stock_after_contains_insert]
ON [dbo].[Contains]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE P
    SET P.StockStatus = P.StockStatus - I.Quantity
    FROM Product P
    INNER JOIN Inserted I ON P.ProductID = I.ProductID;
END
GO

-- ============================================================

-- 6. Hoàn tồn kho khi xóa sản phẩm khỏi đơn hàng
CREATE TRIGGER [dbo].[trg_increase_stock_after_contains_delete]
ON [dbo].[Contains]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE P
    SET P.StockStatus = P.StockStatus + D.Quantity
    FROM Product P
    INNER JOIN Deleted D ON P.ProductID = D.ProductID;
END
GO

-- ============================================================
-- BẢNG: Order
-- ============================================================

-- 7. Đặt TotalAmount = 0 khi đơn hàng bị hủy
CREATE TRIGGER [dbo].[trg_SetTotalAmount_Cancel]
ON [dbo].[Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE o
    SET o.TotalAmount = 0
    FROM [Order] o
    INNER JOIN inserted i ON o.OrderID = i.OrderID
    INNER JOIN deleted  d ON o.OrderID = d.OrderID
    WHERE i.OrderStatus = 'Canceled'
      AND d.OrderStatus <> 'Canceled';
END
GO

-- ============================================================

-- 8. Hoàn tồn kho khi đơn hàng bị hủy (OrderStatus → 'Canceled')
CREATE TRIGGER [dbo].[trg_ReturnStock_WhenCancel]
ON [dbo].[Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(OrderStatus)
        RETURN;

    UPDATE P
    SET P.StockStatus = P.StockStatus + OD.Quantity
    FROM Product P
    INNER JOIN [dbo].[Contains] OD ON P.ProductID = OD.ProductID
    INNER JOIN inserted i ON OD.OrderID = i.OrderID
    INNER JOIN deleted  d ON OD.OrderID = d.OrderID
    WHERE (d.OrderStatus IN (N'Processing') OR d.OrderStatus IS NULL)
      AND i.OrderStatus = N'Canceled';
END
GO

-- ============================================================
-- BẢNG: Delivery
-- ============================================================

-- 9. Tự động cập nhật PayStatus = 'Paid' khi giao hàng thành công (COD)
CREATE TRIGGER [dbo].[trg_UpdatePaymentAfterDelivery]
ON [dbo].[Delivery]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(DeliveryStatus)
        RETURN;

    UPDATE p
    SET p.PayStatus = 'Paid',
        p.PayDate   = CAST(GETDATE() AS DATE)
    FROM Payment p
    INNER JOIN inserted i ON p.OrderID = i.OrderID
    INNER JOIN deleted  d ON i.OrderID = d.OrderID
    WHERE i.DeliveryStatus = 'Delivered'
      AND d.DeliveryStatus <> 'Delivered'
      AND p.PayMethod  = 'Cash'
      AND p.PayStatus NOT IN ('Paid', 'Canceled');
END
GO

-- ============================================================

-- 10. Tự động chuyển đơn hàng sang 'Completed'
--     khi DeliveryStatus = 'Delivered' VÀ PayStatus = 'Paid'
CREATE TRIGGER [dbo].[trg_UpdateOrderAfterPayment]
ON [dbo].[Delivery]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(DeliveryStatus)
        RETURN;

    UPDATE o
    SET o.OrderStatus = 'Completed'
    FROM [Order]   o
    INNER JOIN Delivery d ON o.OrderID = d.OrderID
    INNER JOIN Payment  p ON o.OrderID = p.OrderID
    INNER JOIN inserted i ON o.OrderID = i.OrderID
    WHERE d.DeliveryStatus = 'Delivered'
      AND p.PayStatus       = 'Paid'
      AND o.OrderStatus NOT IN ('Completed', 'Canceled');
END
GO

-- ============================================================
-- BẢNG: Payment
-- ============================================================

-- 11. Tự động tích điểm thành viên sau khi thanh toán thành công
--     Quy tắc: 1.000 VNĐ = 1 điểm  →  Points = FLOOR(TotalPay / 1000)
CREATE TRIGGER [dbo].[auto_add_points_after_payment]
ON [dbo].[Payment]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MembershipPoint (CustomerID, Points, [Date], [Type], OrderID)
    SELECT
        i.CustomerID,
        FLOOR(i.TotalPay / 1000.0),
        CAST(i.PayDate AS DATE),
        'Earned',
        i.OrderID
    FROM inserted i
    LEFT JOIN deleted d ON i.PayID = d.PayID
    WHERE i.PayStatus = 'Paid'
      AND (d.PayStatus IS NULL OR d.PayStatus <> 'Paid')
      AND i.TotalPay > 0;
END
GO
