-- ============================================================
-- FILE: schema.sql
-- DESC: Tạo database và toàn bộ bảng cho hệ thống Pharma Management
-- ============================================================

USE [master]
GO

-- ============================================================
-- 1. TẠO DATABASE
-- ============================================================
CREATE DATABASE [BTL_Restore3]
  CONTAINMENT = NONE
  ON PRIMARY
  ( NAME = N'BTL',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\BTL_Restore3.mdf',
    SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
  LOG ON
  ( NAME = N'BTL_log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\BTL_Restore3_log.ldf',
    SIZE = 73728KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB )
  WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

ALTER DATABASE [BTL_Restore3] SET COMPATIBILITY_LEVEL = 160
GO

USE [BTL_Restore3]
GO

-- ============================================================
-- 2. TẠO USER
-- ============================================================
CREATE USER [nodeuser] FOR LOGIN [nodeuser] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [nodeuser]
GO

-- ============================================================
-- 3. TẠO BẢNG
-- ============================================================

-- Category (danh mục sản phẩm, hỗ trợ phân cấp cha - con)
CREATE TABLE [dbo].[Category] (
    [CategoryID]       VARCHAR(20)    NOT NULL,
    [Name]             NVARCHAR(255)  NOT NULL,
    [ParentCategoryID] VARCHAR(20)    NULL,
    PRIMARY KEY CLUSTERED ([CategoryID] ASC)
)
GO

ALTER TABLE [dbo].[Category]
    ADD CONSTRAINT [FK_Category_Parent]
    FOREIGN KEY ([ParentCategoryID]) REFERENCES [dbo].[Category] ([CategoryID])
GO

-- Product (sản phẩm gốc)
CREATE TABLE [dbo].[Product] (
    [ProductID]        VARCHAR(20)    NOT NULL,
    [Name]             NVARCHAR(MAX)  NULL,
    [Brand]            NVARCHAR(255)  NULL,
    [Price]            INT            NULL,
    [StockStatus]      INT            NULL,
    [ManufacturerName] NVARCHAR(255)  NULL,
    [OriginCountry]    NVARCHAR(255)  NULL,
    [CategoryID]       VARCHAR(20)    NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    CONSTRAINT [chk_ProductPrice] CHECK ([Price] >= 0),
    CONSTRAINT [chk_ProductStock] CHECK ([StockStatus] >= 0)
)
GO

ALTER TABLE [dbo].[Product]
    ADD FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[Category] ([CategoryID])
GO

-- Medicine (thuốc - kế thừa Product)
CREATE TABLE [dbo].[Medicine] (
    [ProductID]   VARCHAR(20)   NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [Ingredients] NVARCHAR(MAX) NULL,
    [TargetUser]  NVARCHAR(100) NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID])
)
GO

-- Supplement (thực phẩm chức năng - kế thừa Product)
CREATE TABLE [dbo].[Supplement] (
    [ProductID]   VARCHAR(20)   NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [Ingredients] NVARCHAR(MAX) NULL,
    [TargetUser]  NVARCHAR(100) NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID])
)
GO

-- BeautyProduct (mỹ phẩm - kế thừa Product)
CREATE TABLE [dbo].[BeautyProduct] (
    [ProductID]   VARCHAR(20)    NOT NULL,
    [Description] NVARCHAR(MAX)  NULL,
    [TargetUser]  NVARCHAR(100)  NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID])
)
GO

-- MedicalDevice (thiết bị y tế - kế thừa Product)
CREATE TABLE [dbo].[MedicalDevice] (
    [ProductID]   VARCHAR(20)    NOT NULL,
    [Description] NVARCHAR(MAX)  NULL,
    [TargetUser]  NVARCHAR(200)  NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID])
)
GO

-- Pharmacist (dược sĩ / nhân viên)
CREATE TABLE [dbo].[Pharmacist] (
    [StaffID]  VARCHAR(20)   NOT NULL,
    [FullName] NVARCHAR(100) NULL,
    [UserName] VARCHAR(50)   NULL,
    [Password] VARCHAR(50)   NULL,
    [Phone]    VARCHAR(15)   NULL,
    [Email]    VARCHAR(100)  NULL,
    PRIMARY KEY CLUSTERED ([StaffID] ASC)
)
GO

-- Customer (khách hàng)
CREATE TABLE [dbo].[Customer] (
    [CustomerID] INT           IDENTITY(1,1) NOT NULL,
    [FullName]   NVARCHAR(100) NOT NULL,
    [Birthdate]  DATE          NULL,
    [Email]      VARCHAR(100)  NULL,
    [Phone]      VARCHAR(15)   NOT NULL,
    [Gender]     NVARCHAR(10)  NULL,
    PRIMARY KEY CLUSTERED ([CustomerID] ASC),
    UNIQUE NONCLUSTERED ([Phone] ASC)
)
GO

-- CustomerAddress (địa chỉ khách hàng - đa trị)
CREATE TABLE [dbo].[CustomerAddress] (
    [CustomerID] INT            NOT NULL,
    [Address]    NVARCHAR(255)  NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerID] ASC, [Address] ASC),
    FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID])
)
GO

-- Order (đơn hàng)
CREATE TABLE [dbo].[Order] (
    [OrderID]     VARCHAR(20)   NOT NULL,
    [Date]        DATE          NOT NULL,
    [Time]        TIME(7)       NOT NULL,
    [OrderStatus] NVARCHAR(20)  NOT NULL,
    [TotalAmount] INT           NULL DEFAULT(0),
    [CustomerID]  INT           NOT NULL,
    [StaffID]     VARCHAR(20)   NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderID] ASC),
    CONSTRAINT [chk_OrderStatus]  CHECK ([OrderStatus] IN ('Processing','Shipped','Completed','Canceled')),
    CONSTRAINT [chk_TotalAmount]  CHECK ([TotalAmount] >= 0),
    FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer]    ([CustomerID]),
    FOREIGN KEY ([StaffID])    REFERENCES [dbo].[Pharmacist]  ([StaffID])
)
GO

-- Contains (chi tiết đơn hàng)
CREATE TABLE [dbo].[Contains] (
    [ProductID]    VARCHAR(20) NOT NULL,
    [OrderID]      VARCHAR(20) NOT NULL,
    [Quantity]     INT         NULL,
    [PriceAtOrder] INT         NULL,
    [Subtotal]     INT         NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC, [OrderID] ASC),
    CONSTRAINT [chk_ContainsQuantity] CHECK ([Quantity]     >  0),
    CONSTRAINT [chk_ContainsPrice]    CHECK ([PriceAtOrder] >= 0),
    CONSTRAINT [chk_ContainsSubtotal] CHECK ([Subtotal]     >= 0),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID]),
    FOREIGN KEY ([OrderID])   REFERENCES [dbo].[Order]   ([OrderID])
)
GO

-- Delivery (giao hàng)
CREATE TABLE [dbo].[Delivery] (
    [OrderID]         VARCHAR(20)   NOT NULL,
    [DeliveryID]      VARCHAR(20)   NOT NULL,
    [ReceiverName]    NVARCHAR(100) NULL,
    [ReceiverPhone]   VARCHAR(20)   NULL,
    [DeliveryStatus]  VARCHAR(20)   NULL,
    [DeliveryAddress] NVARCHAR(200) NULL,
    [ExpectTime]      DATE          NULL,
    CONSTRAINT [PK_Delivery] PRIMARY KEY CLUSTERED ([OrderID] ASC, [DeliveryID] ASC),
    CONSTRAINT [chk_DeliveryStatus] CHECK ([DeliveryStatus] IN ('Waiting','Shipped','Delivered') OR [DeliveryStatus] IS NULL),
    CONSTRAINT [FK_Delivery_Order]  FOREIGN KEY ([OrderID]) REFERENCES [dbo].[Order] ([OrderID])
)
GO

-- Payment (thanh toán)
CREATE TABLE [dbo].[Payment] (
    [PayID]      VARCHAR(20) NOT NULL,
    [PayMethod]  VARCHAR(20) NULL,
    [PayDate]    DATE        NULL,
    [PayStatus]  VARCHAR(20) NULL,
    [TotalPay]   INT         NULL,
    [OrderID]    VARCHAR(20) NOT NULL,
    [CustomerID] INT         NOT NULL,
    PRIMARY KEY CLUSTERED ([PayID] ASC),
    CONSTRAINT [chk_PayStatus] CHECK ([PayStatus] IN ('Pending','Paid') OR [PayStatus] IS NULL),
    CONSTRAINT [chk_TotalPay]  CHECK ([TotalPay] >= 0),
    FOREIGN KEY ([OrderID])    REFERENCES [dbo].[Order]    ([OrderID]),
    FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID])
)
GO

-- MembershipPoint (tích điểm thành viên)
CREATE TABLE [dbo].[MembershipPoint] (
    [PointID]    INT          IDENTITY(1,1) NOT NULL,
    [CustomerID] INT          NOT NULL,
    [Points]     INT          NOT NULL,
    [Date]       DATE         NOT NULL,
    [Type]       NVARCHAR(20) NOT NULL,   -- 'Earned' | 'Used'
    [OrderID]    VARCHAR(20)  NOT NULL,
    CONSTRAINT [PK_Point] PRIMARY KEY CLUSTERED ([PointID] ASC, [CustomerID] ASC),
    CONSTRAINT [FK_MP_Customer] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID])
)
GO

-- Consulte (tư vấn khách hàng)
CREATE TABLE [dbo].[Consulte] (
    [CustomerID] INT         NOT NULL,
    [StaffID]    VARCHAR(20) NOT NULL,
    [Date]       DATE        NOT NULL,
    [Time]       TIME(7)     NOT NULL,
    CONSTRAINT [PK_Consulte]        PRIMARY KEY CLUSTERED ([CustomerID] ASC, [StaffID] ASC, [Date] ASC, [Time] ASC),
    CONSTRAINT [FK_Consulte_Customer] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer]   ([CustomerID]),
    CONSTRAINT [FK_Consulte_Staff]    FOREIGN KEY ([StaffID])    REFERENCES [dbo].[Pharmacist] ([StaffID])
)
GO

-- Review (đánh giá sản phẩm)
CREATE TABLE [dbo].[Review] (
    [ReviewID]    VARCHAR(20)   NOT NULL,
    [Comment]     NVARCHAR(500) NULL,
    [RatingScore] INT           NOT NULL,
    [Date]        DATE          NOT NULL,
    [Time]        TIME(7)       NOT NULL,
    [CustomerID]  INT           NOT NULL,
    [StaffID]     VARCHAR(20)   NULL,
    [StaffComment] NVARCHAR(500) NULL,
    [ProductID]   VARCHAR(20)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ReviewID] ASC),
    CHECK ([RatingScore] BETWEEN 1 AND 5),
    CONSTRAINT [FK_Review_Customer] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer]   ([CustomerID]),
    CONSTRAINT [FK_Review_Product]  FOREIGN KEY ([ProductID])  REFERENCES [dbo].[Product]    ([ProductID]),
    CONSTRAINT [FK_Review_Staff]    FOREIGN KEY ([StaffID])    REFERENCES [dbo].[Pharmacist] ([StaffID])
)
GO
