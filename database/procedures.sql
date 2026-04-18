-- ============================================================
-- FILE: procedures.sql
-- DESC: Stored Procedures và User-Defined Functions
-- RUN AFTER: schema.sql
-- ============================================================

USE [BTL_Restore3]
GO

-- ============================================================
-- USER-DEFINED FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- fn_GetTopNBestSellingProducts
-- Trả về Top N sản phẩm bán chạy nhất (theo tổng số lượng đã bán)
--
-- Cách dùng:
--   SELECT * FROM dbo.fn_GetTopNBestSellingProducts(5)
-- ------------------------------------------------------------
CREATE FUNCTION [dbo].[fn_GetTopNBestSellingProducts]
(
    @TopN INT
)
RETURNS @Result TABLE
(
    RankNo    INT,
    ProductID VARCHAR(20),
    TotalSold INT
)
AS
BEGIN
    -- Validate tham số
    IF @TopN IS NULL OR @TopN <= 0
    BEGIN
        INSERT INTO @Result VALUES (0, NULL, 0);
        RETURN;
    END

    -- Tính tổng số lượng bán theo từng sản phẩm
    DECLARE @Tmp TABLE
    (
        RowNum    INT IDENTITY(1,1),
        ProductID VARCHAR(20),
        TotalSold INT
    );

    INSERT INTO @Tmp (ProductID, TotalSold)
    SELECT ProductID, SUM(Quantity)
    FROM [Contains]
    GROUP BY ProductID
    ORDER BY SUM(Quantity) DESC;

    -- Dùng cursor duyệt và lấy Top N
    DECLARE @pid  VARCHAR(20);
    DECLARE @qty  INT;
    DECLARE @rank INT = 0;

    DECLARE cur CURSOR FOR
        SELECT ProductID, TotalSold
        FROM @Tmp
        ORDER BY TotalSold DESC;

    OPEN cur;
    FETCH NEXT FROM cur INTO @pid, @qty;

    WHILE @@FETCH_STATUS = 0 AND @rank < @TopN
    BEGIN
        SET @rank = @rank + 1;
        INSERT INTO @Result (RankNo, ProductID, TotalSold)
        VALUES (@rank, @pid, @qty);
        FETCH NEXT FROM cur INTO @pid, @qty;
    END

    CLOSE cur;
    DEALLOCATE cur;

    RETURN;
END
GO

-- ------------------------------------------------------------
-- Fn_Revenue_Real_vs_Potential_Month
-- So sánh doanh thu thực tế vs tiềm năng trong một tháng
--
-- Trả về:
--   ActualRevenue    : Doanh thu thực (đơn Completed)
--   PotentialRevenue : Doanh thu thuần nếu không có đơn bị hủy
--   LostRevenue      : Tiền mất do đơn bị hủy
--
-- Cách dùng:
--   SELECT * FROM dbo.Fn_Revenue_Real_vs_Potential_Month(4, 2026)
-- ------------------------------------------------------------
CREATE FUNCTION [dbo].[Fn_Revenue_Real_vs_Potential_Month]
(
    @Month INT,
    @Year  INT
)
RETURNS @Result TABLE
(
    ActualRevenue    DECIMAL(18,2),
    PotentialRevenue DECIMAL(18,2),
    LostRevenue      DECIMAL(18,2)
)
AS
BEGIN
    DECLARE @Actual    DECIMAL(18,2) = 0;
    DECLARE @Potential DECIMAL(18,2) = 0;
    DECLARE @Lost      DECIMAL(18,2) = 0;

    DECLARE @OrderID     VARCHAR(20);
    DECLARE @OrderStatus NVARCHAR(20);
    DECLARE @TotalAmount INT;
    DECLARE @SubtotalSum DECIMAL(18,2);

    -- Validate tham số
    IF @Month NOT BETWEEN 1 AND 12
       OR @Year < 2000
       OR @Year > YEAR(GETDATE()) + 5
    BEGIN
        INSERT INTO @Result VALUES (-1, -1, -1);
        RETURN;
    END

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT OrderID, OrderStatus, ISNULL(TotalAmount, 0)
        FROM [dbo].[Order]
        WHERE MONTH([Date]) = @Month
          AND YEAR([Date])  = @Year;

    OPEN cur;
    FETCH NEXT FROM cur INTO @OrderID, @OrderStatus, @TotalAmount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @SubtotalSum = ISNULL(SUM(Subtotal), 0)
        FROM [Contains]
        WHERE OrderID = @OrderID;

        IF @OrderStatus = N'Completed'
        BEGIN
            SET @Actual    = @Actual    + @TotalAmount;
            SET @Potential = @Potential + @TotalAmount;
        END

        IF @OrderStatus = N'Canceled'
        BEGIN
            SET @Potential = @Potential + @SubtotalSum;
            SET @Lost      = @Lost      + @SubtotalSum;
        END

        FETCH NEXT FROM cur INTO @OrderID, @OrderStatus, @TotalAmount;
    END

    CLOSE cur;
    DEALLOCATE cur;

    INSERT INTO @Result VALUES (@Actual, @Potential, @Lost);
    RETURN;
END
GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- ------------------------------------------------------------
-- sp_InsertCustomer
-- Thêm khách hàng mới với đầy đủ validation
--
-- Validation:
--   - Phone là bắt buộc và không được trùng
--   - Ngày sinh không được lớn hơn ngày hiện tại
--   - Khách hàng phải đủ 16 tuổi trở lên
--
-- Cách dùng:
--   DECLARE @id INT
--   EXEC dbo.sp_InsertCustomer
--       @FullName  = N'Nguyễn Văn A',
--       @Birthdate = '2000-01-01',
--       @Phone     = '0901234567',
--       @Email     = 'a@example.com',
--       @Gender    = N'Nam',
--       @CustomerID = @id OUTPUT
--   SELECT @id
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_InsertCustomer]
    @FullName   NVARCHAR(100),
    @Birthdate  DATE,
    @Phone      VARCHAR(15),
    @Email      VARCHAR(100) = NULL,
    @Gender     NVARCHAR(10) = NULL,
    @CustomerID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Phone là bắt buộc
    IF (@Phone IS NULL OR LTRIM(RTRIM(@Phone)) = '')
    BEGIN
        RAISERROR('Lỗi: Khách hàng phải cung cấp Số điện thoại để đăng ký tài khoản.', 16, 1);
        RETURN;
    END

    -- Kiểm tra trùng số điện thoại
    IF EXISTS (SELECT 1 FROM dbo.Customer WHERE Phone = LTRIM(RTRIM(@Phone)))
    BEGIN
        RAISERROR('Lỗi: Số điện thoại đã tồn tại trong hệ thống.', 16, 1);
        RETURN;
    END

    -- Ngày sinh không được vượt ngày hiện tại
    IF (@Birthdate > CAST(GETDATE() AS DATE))
    BEGIN
        RAISERROR(N'Lỗi: Ngày tháng năm sinh không được lớn hơn ngày hiện tại!', 16, 1);
        RETURN;
    END

    -- Phải đủ 16 tuổi
    IF (DATEDIFF(YEAR, @Birthdate, GETDATE()) < 16)
    BEGIN
        RAISERROR(N'Lỗi: Khách hàng phải đủ 16 tuổi trở lên!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        INSERT INTO dbo.Customer (FullName, Birthdate, Email, Phone, Gender)
        VALUES (
            @FullName,
            @Birthdate,
            NULLIF(LTRIM(RTRIM(@Email)), ''),
            LTRIM(RTRIM(@Phone)),
            @Gender
        );

        SET @CustomerID = SCOPE_IDENTITY();
        PRINT 'Thêm khách hàng thành công: CustomerID = ' + CAST(@CustomerID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- ------------------------------------------------------------
-- sp_UpdateCustomer
-- Cập nhật thông tin khách hàng (partial update — NULL = giữ nguyên)
--
-- Lưu ý:
--   - Truyền NULL cho field → giữ nguyên giá trị cũ
--   - Truyền '' cho Email   → xóa email (SET NULL)
--   - Phone KHÔNG được xóa (bắt buộc)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_UpdateCustomer]
    @CustomerID INT,
    @FullName   NVARCHAR(100) = NULL,
    @Birthdate  DATE          = NULL,
    @Email      VARCHAR(100)  = NULL,
    @Phone      VARCHAR(15)   = NULL,
    @Gender     NVARCHAR(10)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR('Lỗi: Không tìm thấy khách hàng với CustomerID = %d.', 16, 1, @CustomerID);
        RETURN;
    END

    -- Lấy giá trị hiện tại
    DECLARE @CurrentEmail VARCHAR(100), @CurrentPhone VARCHAR(15);
    SELECT @CurrentEmail = Email, @CurrentPhone = Phone
    FROM dbo.Customer WHERE CustomerID = @CustomerID;

    -- Xử lý Email: NULL → giữ nguyên, '' → xóa
    DECLARE @NewEmail VARCHAR(100);
    SET @NewEmail = CASE
        WHEN @Email IS NOT NULL THEN NULLIF(LTRIM(RTRIM(@Email)), '')
        ELSE @CurrentEmail
    END;

    -- Xử lý Phone: NULL → giữ nguyên, '' → lỗi (không cho xóa)
    DECLARE @NewPhone VARCHAR(15);
    SET @NewPhone = CASE
        WHEN @Phone IS NOT NULL THEN NULLIF(LTRIM(RTRIM(@Phone)), '')
        ELSE @CurrentPhone
    END;

    -- Phone là bắt buộc
    IF @NewPhone IS NULL
    BEGIN
        RAISERROR('Lỗi: Số điện thoại là thông tin bắt buộc, không được xóa.', 16, 1);
        RETURN;
    END

    -- Kiểm tra trùng Phone với khách hàng khác
    IF EXISTS (
        SELECT 1 FROM dbo.Customer
        WHERE Phone = @NewPhone AND CustomerID <> @CustomerID
    )
    BEGIN
        RAISERROR(N'Số điện thoại này đã tồn tại trong hệ thống.', 16, 1);
        RETURN;
    END

    -- Validation Birthdate
    IF @Birthdate IS NOT NULL
    BEGIN
        IF @Birthdate > CAST(GETDATE() AS DATE)
        BEGIN
            RAISERROR(N'Ngày tháng năm sinh không được lớn hơn ngày hiện tại!', 16, 1);
            RETURN;
        END
        IF DATEADD(YEAR, 16, @Birthdate) > CAST(GETDATE() AS DATE)
        BEGIN
            RAISERROR(N'Khách hàng phải đủ 16 tuổi trở lên!', 16, 1);
            RETURN;
        END
    END

    BEGIN TRY
        UPDATE dbo.Customer
        SET
            FullName  = ISNULL(@FullName, FullName),
            Birthdate = ISNULL(@Birthdate, Birthdate),
            Email     = @NewEmail,
            Phone     = @NewPhone,
            Gender    = ISNULL(@Gender, Gender)
        WHERE CustomerID = @CustomerID;

        PRINT 'Cập nhật khách hàng thành công: CustomerID = ' + CAST(@CustomerID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END
GO

-- ------------------------------------------------------------
-- sp_DeleteCustomer
-- Xóa khách hàng (chỉ được xóa nếu không có đơn hàng liên quan)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_DeleteCustomer]
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR('Lỗi: Không tìm thấy khách hàng với CustomerID = %d.', 16, 1, @CustomerID);
        RETURN;
    END

    -- Kiểm tra ràng buộc ngoại lai với Order
    IF EXISTS (SELECT 1 FROM dbo.[Order] WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR(
            'Không thể xóa khách hàng ID %d vì đang có đơn hàng liên quan. Vui lòng hủy hoặc xóa đơn hàng trước.',
            16, 1, @CustomerID
        );
        RETURN;
    END

    BEGIN TRY
        DELETE FROM dbo.Customer WHERE CustomerID = @CustomerID;
        PRINT 'Xóa khách hàng thành công: CustomerID = ' + CAST(@CustomerID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END
GO

-- ------------------------------------------------------------
-- GetCustomerAndPoints_ByPhone
-- Hiển thị thông tin khách hàng và lịch sử tích điểm theo SĐT
-- Bao gồm cột CurrentPoints (điểm tích lũy hiện tại - running total)
--
-- Cách dùng:
--   EXEC dbo.GetCustomerAndPoints_ByPhone @Phone = '0901234567'
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetCustomerAndPoints_ByPhone]
    @Phone VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.CustomerID,
        C.FullName,
        C.Email,
        C.Phone,
        MP.PointID,
        MP.[Date],
        MP.[Type],      -- 'Earned' hoặc 'Used'
        MP.Points,
        SUM(MP.Points) OVER (
            PARTITION BY C.CustomerID
            ORDER BY MP.[Date], MP.PointID
            ROWS UNBOUNDED PRECEDING
        ) AS [CurrentPoints]
    FROM dbo.Customer C
    LEFT JOIN dbo.MembershipPoint MP ON C.CustomerID = MP.CustomerID
    WHERE C.Phone = @Phone
    ORDER BY MP.[Date] DESC, MP.PointID DESC;
END
GO

-- ------------------------------------------------------------
-- GetLoyalCustomers_ByAmountAndFrequency
-- Tìm khách hàng trung thành dựa trên tổng tiền và tần suất mua
--
-- Cách dùng:
--   EXEC dbo.GetLoyalCustomers_ByAmountAndFrequency
--       @StartDate      = '2026-01-01',
--       @EndDate        = '2026-04-30',
--       @MinTotalAmount = 500000,
--       @MinFrequency   = 3
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetLoyalCustomers_ByAmountAndFrequency]
    @StartDate      DATE,
    @EndDate        DATE,
    @MinTotalAmount INT = 500000,
    @MinFrequency   INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.CustomerID,
        C.FullName,
        C.Phone,
        COUNT(O.OrderID)   AS SoLanMuaHang,
        SUM(O.TotalAmount) AS TongTienDaMua,
        MAX(O.Date)        AS LanMuaGanNhat
    FROM dbo.Customer C
    INNER JOIN dbo.[Order] O ON C.CustomerID = O.CustomerID
    WHERE O.OrderStatus = 'Completed'
      AND O.Date BETWEEN @StartDate AND @EndDate
    GROUP BY C.CustomerID, C.FullName, C.Phone
    HAVING COUNT(O.OrderID)   >= @MinFrequency
       AND SUM(O.TotalAmount) >= @MinTotalAmount
    ORDER BY TongTienDaMua DESC, SoLanMuaHang DESC;
END
GO
