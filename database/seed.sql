-- ============================================================
-- FILE: seed.sql
-- DESC: Dữ liệu mẫu (sample data) cho hệ thống Pharma Management
-- RUN AFTER: schema.sql, triggers.sql, procedures.sql
-- ============================================================

USE [BTL_Restore3]
GO

-- ============================================================
-- 1. CATEGORY
-- ============================================================
INSERT INTO [dbo].[Category] (CategoryID, Name, ParentCategoryID) VALUES
('CAT001', N'Thuốc',                    NULL),
('CAT002', N'Thực phẩm chức năng',      NULL),
('CAT003', N'Mỹ phẩm',                  NULL),
('CAT004', N'Thiết bị y tế',            NULL),
('CAT011', N'Thuốc kháng sinh',         'CAT001'),
('CAT012', N'Thuốc giảm đau',           'CAT001'),
('CAT013', N'Thuốc tiêu hóa',           'CAT001'),
('CAT021', N'Vitamin & Khoáng chất',    'CAT002'),
('CAT022', N'Bổ sung dinh dưỡng',       'CAT002'),
('CAT031', N'Dưỡng da',                 'CAT003'),
('CAT041', N'Máy đo huyết áp',          'CAT004'),
('CAT042', N'Nhiệt kế',                 'CAT004')
GO

-- ============================================================
-- 2. PHARMACIST (nhân viên / dược sĩ)
-- ============================================================
INSERT INTO [dbo].[Pharmacist] (StaffID, FullName, UserName, Password, Phone, Email) VALUES
('STF001', N'Nguyễn Thị Lan',    'lan.nguyen',  'hashed_pw_001', '0901111111', 'lan.nguyen@pharma.vn'),
('STF002', N'Trần Minh Khoa',    'khoa.tran',   'hashed_pw_002', '0902222222', 'khoa.tran@pharma.vn'),
('STF003', N'Lê Thị Hoa',        'hoa.le',      'hashed_pw_003', '0903333333', 'hoa.le@pharma.vn')
GO

-- ============================================================
-- 3. PRODUCT (sản phẩm gốc)
-- ============================================================
INSERT INTO [dbo].[Product] (ProductID, Name, Brand, Price, StockStatus, ManufacturerName, OriginCountry, CategoryID) VALUES
('PRD001', N'Amoxicillin 500mg',          N'Mekophar',        45000,  200, N'Mekophar',              N'Việt Nam',    'CAT011'),
('PRD002', N'Paracetamol 500mg',          N'DHG Pharma',      15000,  500, N'DHG Pharma',            N'Việt Nam',    'CAT012'),
('PRD003', N'Omeprazole 20mg',            N'Stada',           32000,  150, N'Stada Vietnam',         N'Việt Nam',    'CAT013'),
('PRD004', N'Vitamin C 1000mg',           N'Blackmores',      180000, 300, N'Blackmores Australia',  N'Úc',          'CAT021'),
('PRD005', N'Omega-3 Fish Oil',           N'Nature Made',     250000, 120, N'Nature Made USA',       N'Mỹ',          'CAT022'),
('PRD006', N'Kem dưỡng ẩm Cetaphil',      N'Cetaphil',        320000,  80, N'Galderma',              N'Pháp',        'CAT031'),
('PRD007', N'Máy đo huyết áp Omron',      N'Omron',          1200000,  30, N'Omron Healthcare',      N'Nhật Bản',    'CAT041'),
('PRD008', N'Nhiệt kế điện tử Beurer',    N'Beurer',          350000,  60, N'Beurer GmbH',           N'Đức',         'CAT042')
GO

-- ============================================================
-- 4. PRODUCT SUBTYPES
-- ============================================================
INSERT INTO [dbo].[Medicine] (ProductID, Description, Ingredients, TargetUser) VALUES
('PRD001', N'Kháng sinh phổ rộng, điều trị nhiễm khuẩn', N'Amoxicillin trihydrate 500mg', N'Người lớn và trẻ em trên 12 tuổi'),
('PRD002', N'Giảm đau, hạ sốt hiệu quả',                  N'Paracetamol 500mg',            N'Người lớn và trẻ em trên 6 tuổi'),
('PRD003', N'Điều trị loét dạ dày, trào ngược axit',       N'Omeprazole 20mg',              N'Người lớn')
GO

INSERT INTO [dbo].[Supplement] (ProductID, Description, Ingredients, TargetUser) VALUES
('PRD004', N'Tăng cường miễn dịch, chống oxy hóa', N'Ascorbic Acid 1000mg',          N'Người lớn'),
('PRD005', N'Hỗ trợ tim mạch, não bộ',              N'EPA 180mg, DHA 120mg mỗi viên', N'Người lớn từ 18 tuổi')
GO

INSERT INTO [dbo].[BeautyProduct] (ProductID, Description, TargetUser) VALUES
('PRD006', N'Dưỡng ẩm sâu, phù hợp da nhạy cảm', N'Mọi loại da, đặc biệt da khô và nhạy cảm')
GO

INSERT INTO [dbo].[MedicalDevice] (ProductID, Description, TargetUser) VALUES
('PRD007', N'Đo huyết áp tự động tại cổ tay, kết nối Bluetooth', N'Người có bệnh tim mạch, cao huyết áp'),
('PRD008', N'Đo nhiệt độ tai và trán, cho kết quả trong 1 giây',  N'Gia đình, trẻ em')
GO

-- ============================================================
-- 5. CUSTOMER
-- ============================================================
INSERT INTO [dbo].[Customer] (FullName, Birthdate, Email, Phone, Gender) VALUES
(N'Nguyễn Văn An',    '1990-05-15', 'an.nguyen@gmail.com',    '0911111111', N'Nam'),
(N'Trần Thị Bích',    '1985-08-20', 'bich.tran@gmail.com',    '0922222222', N'Nữ'),
(N'Lê Hoàng Cường',   '2000-12-01', 'cuong.le@gmail.com',     '0933333333', N'Nam'),
(N'Phạm Thị Dung',    '1995-03-10', 'dung.pham@gmail.com',    '0944444444', N'Nữ'),
(N'Hoàng Văn Em',     '1978-07-25', NULL,                     '0955555555', N'Nam')
GO

INSERT INTO [dbo].[CustomerAddress] (CustomerID, Address) VALUES
(1, N'123 Lê Lợi, Quận 1, TP.HCM'),
(1, N'456 Nguyễn Huệ, Quận 1, TP.HCM'),
(2, N'789 Trần Hưng Đạo, Quận 5, TP.HCM'),
(3, N'321 Hoàng Diệu, Quận 4, TP.HCM'),
(4, N'654 Cách Mạng Tháng 8, Quận 3, TP.HCM')
GO

-- ============================================================
-- 6. ORDER + CONTAINS + DELIVERY + PAYMENT
-- (Mỗi kịch bản minh hoạ một trạng thái khác nhau)
-- ============================================================

-- ---- Kịch bản 1: Đơn đã hoàn thành (Completed) ----
INSERT INTO [dbo].[Order] (OrderID, Date, Time, OrderStatus, CustomerID, StaffID) VALUES
('ORD001', '2026-04-01', '09:00:00', 'Completed', 1, 'STF001')
GO
INSERT INTO [dbo].[Contains] (ProductID, OrderID, Quantity) VALUES
('PRD002', 'ORD001', 3),   -- Paracetamol x3
('PRD004', 'ORD001', 1)    -- Vitamin C x1
GO
INSERT INTO [dbo].[Delivery] (OrderID, DeliveryID, ReceiverName, ReceiverPhone, DeliveryStatus, DeliveryAddress, ExpectTime) VALUES
('ORD001', 'DEL001', N'Nguyễn Văn An', '0911111111', 'Delivered', N'123 Lê Lợi, Q1, TP.HCM', '2026-04-03')
GO
INSERT INTO [dbo].[Payment] (PayID, PayMethod, PayDate, PayStatus, TotalPay, OrderID, CustomerID) VALUES
('PAY001', 'Cash', '2026-04-03', 'Paid', 225000, 'ORD001', 1)
GO

-- ---- Kịch bản 2: Đơn đang xử lý (Processing) ----
INSERT INTO [dbo].[Order] (OrderID, Date, Time, OrderStatus, CustomerID, StaffID) VALUES
('ORD002', '2026-04-10', '14:30:00', 'Processing', 2, 'STF002')
GO
INSERT INTO [dbo].[Contains] (ProductID, OrderID, Quantity) VALUES
('PRD007', 'ORD002', 1),   -- Máy đo huyết áp x1
('PRD008', 'ORD002', 1)    -- Nhiệt kế x1
GO
INSERT INTO [dbo].[Delivery] (OrderID, DeliveryID, ReceiverName, ReceiverPhone, DeliveryStatus, DeliveryAddress, ExpectTime) VALUES
('ORD002', 'DEL002', N'Trần Thị Bích', '0922222222', 'Waiting', N'789 Trần Hưng Đạo, Q5, TP.HCM', '2026-04-15')
GO
INSERT INTO [dbo].[Payment] (PayID, PayMethod, PayDate, PayStatus, TotalPay, OrderID, CustomerID) VALUES
('PAY002', 'BankTransfer', NULL, 'Pending', 1550000, 'ORD002', 2)
GO

-- ---- Kịch bản 3: Đơn bị hủy (Canceled) ----
INSERT INTO [dbo].[Order] (OrderID, Date, Time, OrderStatus, CustomerID, StaffID) VALUES
('ORD003', '2026-04-05', '11:15:00', 'Canceled', 3, 'STF001')
GO
INSERT INTO [dbo].[Contains] (ProductID, OrderID, Quantity) VALUES
('PRD001', 'ORD003', 2),   -- Amoxicillin x2
('PRD003', 'ORD003', 1)    -- Omeprazole x1
GO

-- ---- Kịch bản 4: Đơn đang giao (Shipped) ----
INSERT INTO [dbo].[Order] (OrderID, Date, Time, OrderStatus, CustomerID, StaffID) VALUES
('ORD004', '2026-04-12', '16:00:00', 'Shipped', 4, 'STF003')
GO
INSERT INTO [dbo].[Contains] (ProductID, OrderID, Quantity) VALUES
('PRD005', 'ORD004', 2),   -- Omega-3 x2
('PRD006', 'ORD004', 1)    -- Kem dưỡng x1
GO
INSERT INTO [dbo].[Delivery] (OrderID, DeliveryID, ReceiverName, ReceiverPhone, DeliveryStatus, DeliveryAddress, ExpectTime) VALUES
('ORD004', 'DEL004', N'Phạm Thị Dung', '0944444444', 'Shipped', N'654 Cách Mạng Tháng 8, Q3, TP.HCM', '2026-04-16')
GO
INSERT INTO [dbo].[Payment] (PayID, PayMethod, PayDate, PayStatus, TotalPay, OrderID, CustomerID) VALUES
('PAY004', 'Cash', NULL, 'Pending', 820000, 'ORD004', 4)
GO

-- ============================================================
-- 7. REVIEW
-- ============================================================
INSERT INTO [dbo].[Review] (ReviewID, Comment, RatingScore, Date, Time, CustomerID, StaffID, StaffComment, ProductID) VALUES
('REV001', N'Thuốc uống hiệu quả, hạ sốt nhanh',      5, '2026-04-04', '10:00:00', 1, 'STF001', N'Cảm ơn bạn đã tin tưởng!', 'PRD002'),
('REV002', N'Vitamin C chính hãng, dễ uống',           4, '2026-04-04', '11:30:00', 1,  NULL,    NULL,                         'PRD004'),
('REV003', N'Kem dưỡng ẩm tốt nhưng hơi đắt',         4, '2026-04-13', '09:00:00', 4, 'STF003', N'Chúng tôi sẽ cải thiện giá!','PRD006')
GO

-- ============================================================
-- 8. CONSULTE (tư vấn)
-- ============================================================
INSERT INTO [dbo].[Consulte] (CustomerID, StaffID, Date, Time) VALUES
(1, 'STF001', '2026-04-01', '08:45:00'),
(2, 'STF002', '2026-04-10', '14:00:00'),
(5, 'STF001', '2026-04-15', '09:30:00')
GO
