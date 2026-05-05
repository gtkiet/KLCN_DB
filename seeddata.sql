/* ================================================================
   SportPlusDB — SEED DATA MẪU (EXPANDED - ~10+ rows/table)
   ⚠️  PasswordHash là placeholder — thay bằng bcrypt hash thật sau khi có API Auth
================================================================ */

USE SportPlusDB;
-- USE db_ac8bb1_klcn;
GO

/* ================================================================
   [0] DỌN DẸP — xóa đúng thứ tự FK (leaf → parent)
================================================================ */

DELETE FROM Notifications;
DELETE FROM BookingLogs;
DELETE FROM Reviews;
DELETE FROM Incidents;
DELETE FROM Deposits;
DELETE FROM Payments;
DELETE FROM BookingServices;
DELETE FROM BookingDetails;
DELETE FROM Bookings;
DELETE FROM PurchaseOrderDetails;
DELETE FROM PurchaseOrders;
DELETE FROM FieldMaintenanceLogs;
DELETE FROM FieldPriceHistory;
DELETE FROM SpecialDays;
DELETE FROM Promotions;
UPDATE SystemConfig SET UpdatedBy = NULL;
DELETE FROM RefreshTokens;
DELETE FROM Profiles;
DELETE FROM Users    WHERE UserId > 1;   -- giữ admin gốc nếu có trigger
DELETE FROM Users;
GO


/* ================================================================
   [1] USERS — 3 Admin, 3 Staff, 14 Customer = 20 users
================================================================ */

SET IDENTITY_INSERT Users ON;

INSERT INTO Users (UserId, Email, Phone, PasswordHash, FullName, RoleId, StatusId, CreatedAt, UpdatedAt, IsDeleted)
VALUES
    -- Admin
    (1,  N'admin@sportplus.vn',       N'0900000001', N'$2a$12$PLACEHOLDER_HASH', N'Nguyễn Quản Trị',   1, 1, DATEADD(MONTH,-6,SYSDATETIME()), SYSDATETIME(), 0),
    (2,  N'admin2@sportplus.vn',      N'0900000002', N'$2a$12$PLACEHOLDER_HASH', N'Phạm Hoàng Minh',   1, 1, DATEADD(MONTH,-5,SYSDATETIME()), SYSDATETIME(), 0),

    -- Staff
    (3,  N'staff1@sportplus.vn',      N'0900000003', N'$2a$12$PLACEHOLDER_HASH', N'Trần Nhân Viên',    2, 1, DATEADD(MONTH,-4,SYSDATETIME()), SYSDATETIME(), 0),
    (4,  N'staff2@sportplus.vn',      N'0900000004', N'$2a$12$PLACEHOLDER_HASH', N'Lý Thị Hương',      2, 1, DATEADD(MONTH,-3,SYSDATETIME()), SYSDATETIME(), 0),
    (5,  N'staff3@sportplus.vn',      N'0900000005', N'$2a$12$PLACEHOLDER_HASH', N'Vũ Đình Khoa',      2, 1, DATEADD(MONTH,-2,SYSDATETIME()), SYSDATETIME(), 0),

    -- Customer
    (6,  N'lekhanhhang@gmail.com',    N'0901111001', N'$2a$12$PLACEHOLDER_HASH', N'Lê Khánh Hàng',     3, 1, DATEADD(MONTH,-5,SYSDATETIME()), SYSDATETIME(), 0),
    (7,  N'nguyenvana@gmail.com',     N'0901111002', N'$2a$12$PLACEHOLDER_HASH', N'Nguyễn Văn An',     3, 1, DATEADD(MONTH,-4,SYSDATETIME()), SYSDATETIME(), 0),
    (8,  N'tranthib@gmail.com',       N'0901111003', N'$2a$12$PLACEHOLDER_HASH', N'Trần Thị Bích',     3, 1, DATEADD(MONTH,-4,SYSDATETIME()), SYSDATETIME(), 0),
    (9,  N'phamquocc@gmail.com',      N'0901111004', N'$2a$12$PLACEHOLDER_HASH', N'Phạm Quốc Cường',   3, 1, DATEADD(MONTH,-3,SYSDATETIME()), SYSDATETIME(), 0),
    (10, N'hoangminh@gmail.com',      N'0901111005', N'$2a$12$PLACEHOLDER_HASH', N'Hoàng Văn Minh',    3, 1, DATEADD(MONTH,-3,SYSDATETIME()), SYSDATETIME(), 0),
    (11, N'dothithu@gmail.com',       N'0901111006', N'$2a$12$PLACEHOLDER_HASH', N'Đỗ Thị Thu',        3, 1, DATEADD(MONTH,-2,SYSDATETIME()), SYSDATETIME(), 0),
    (12, N'buivanlong@gmail.com',     N'0901111007', N'$2a$12$PLACEHOLDER_HASH', N'Bùi Văn Long',      3, 1, DATEADD(MONTH,-2,SYSDATETIME()), SYSDATETIME(), 0),
    (13, N'ngothanhdat@gmail.com',    N'0901111008', N'$2a$12$PLACEHOLDER_HASH', N'Ngô Thành Đạt',     3, 1, DATEADD(MONTH,-2,SYSDATETIME()), SYSDATETIME(), 0),
    (14, N'vuthimai@gmail.com',       N'0901111009', N'$2a$12$PLACEHOLDER_HASH', N'Vũ Thị Mai',        3, 1, DATEADD(MONTH,-1,SYSDATETIME()), SYSDATETIME(), 0),
    (15, N'dangquochuy@gmail.com',    N'0901111010', N'$2a$12$PLACEHOLDER_HASH', N'Đặng Quốc Huy',     3, 1, DATEADD(MONTH,-1,SYSDATETIME()), SYSDATETIME(), 0),
    (16, N'lythanhphong@gmail.com',   N'0901111011', N'$2a$12$PLACEHOLDER_HASH', N'Lý Thành Phong',    3, 1, DATEADD(MONTH,-1,SYSDATETIME()), SYSDATETIME(), 0),
    (17, N'trinhvankhang@gmail.com',  N'0901111012', N'$2a$12$PLACEHOLDER_HASH', N'Trịnh Văn Khang',   3, 1, DATEADD(WEEK,-3,SYSDATETIME()),  SYSDATETIME(), 0),
    (18, N'maithibaochi@gmail.com',   N'0901111013', N'$2a$12$PLACEHOLDER_HASH', N'Mai Thị Bảo Chi',   3, 1, DATEADD(WEEK,-2,SYSDATETIME()),  SYSDATETIME(), 0),
    (19, N'huynhgiabao@gmail.com',    N'0901111014', N'$2a$12$PLACEHOLDER_HASH', N'Huỳnh Gia Bảo',     3, 1, DATEADD(WEEK,-1,SYSDATETIME()),  SYSDATETIME(), 0),
    (20, N'caovantu@gmail.com',       N'0901111015', N'$2a$12$PLACEHOLDER_HASH', N'Cao Văn Tú',        3, 2, DATEADD(WEEK,-1,SYSDATETIME()),  SYSDATETIME(), 0);
    -- UserId 20: bị khóa (StatusId=2) để test

SET IDENTITY_INSERT Users OFF;
GO


/* ================================================================
   [2] PROFILES
================================================================ */

INSERT INTO Profiles (UserId, AvatarUrl, DateOfBirth, Address)
VALUES
    (1,  N'https://ui-avatars.com/api/?name=QT&background=0D8ABC&color=fff', '1985-03-10', N'123 Nguyễn Huệ, Q.1, TP.HCM'),
    (2,  N'https://ui-avatars.com/api/?name=HM&background=0D8ABC&color=fff', '1988-07-22', N'45 Hai Bà Trưng, Q.1, TP.HCM'),
    (3,  N'https://ui-avatars.com/api/?name=NV&background=2ECC71&color=fff', '1995-06-20', N'456 Lê Lợi, Q.1, TP.HCM'),
    (4,  N'https://ui-avatars.com/api/?name=TH&background=2ECC71&color=fff', '1997-11-05', N'88 Đinh Tiên Hoàng, Q.Bình Thạnh, TP.HCM'),
    (5,  N'https://ui-avatars.com/api/?name=VK&background=2ECC71&color=fff', '1999-02-14', N'200 Phan Đăng Lưu, Q.Bình Thạnh, TP.HCM'),
    (6,  N'https://ui-avatars.com/api/?name=KH&background=E74C3C&color=fff', '1992-08-30', N'789 Trần Hưng Đạo, Q.5, TP.HCM'),
    (7,  N'https://ui-avatars.com/api/?name=VA&background=E74C3C&color=fff', '1990-04-15', N'10 Nguyễn Thị Minh Khai, Q.3, TP.HCM'),
    (8,  N'https://ui-avatars.com/api/?name=TB&background=E74C3C&color=fff', '1996-09-28', N'55 Cách Mạng Tháng 8, Q.3, TP.HCM'),
    (9,  N'https://ui-avatars.com/api/?name=QC&background=E74C3C&color=fff', '1993-12-01', N'302 Nguyễn Văn Cừ, Q.5, TP.HCM'),
    (10, N'https://ui-avatars.com/api/?name=VM&background=E74C3C&color=fff', '1991-05-19', N'14 Hoàng Diệu, Q.4, TP.HCM'),
    (11, N'https://ui-avatars.com/api/?name=DT&background=E74C3C&color=fff', '1998-03-22', N'67 Bùi Thị Xuân, Q.Tân Bình, TP.HCM'),
    (12, N'https://ui-avatars.com/api/?name=BL&background=E74C3C&color=fff', '1994-07-07', N'120 Lý Thường Kiệt, Q.10, TP.HCM'),
    (13, N'https://ui-avatars.com/api/?name=TD&background=E74C3C&color=fff', '1997-01-11', N'9 Trường Chinh, Q.Tân Bình, TP.HCM'),
    (14, N'https://ui-avatars.com/api/?name=VM&background=E74C3C&color=fff', '2000-06-06', N'78 Phan Văn Hân, Q.Bình Thạnh, TP.HCM'),
    (15, N'https://ui-avatars.com/api/?name=QH&background=E74C3C&color=fff', '1995-10-25', N'33 Điện Biên Phủ, Q.Bình Thạnh, TP.HCM'),
    (16, N'https://ui-avatars.com/api/?name=TP&background=E74C3C&color=fff', '1993-08-18', N'250 Xô Viết Nghệ Tĩnh, Q.Bình Thạnh, TP.HCM'),
    (17, N'https://ui-avatars.com/api/?name=VK&background=E74C3C&color=fff', '1999-04-03', N'5 Lê Quang Định, Q.Gò Vấp, TP.HCM'),
    (18, N'https://ui-avatars.com/api/?name=BC&background=E74C3C&color=fff', '2001-12-20', N'90 Quang Trung, Q.Gò Vấp, TP.HCM'),
    (19, N'https://ui-avatars.com/api/?name=GB&background=E74C3C&color=fff', '1998-09-14', N'15 Nguyễn Oanh, Q.Gò Vấp, TP.HCM'),
    (20, N'https://ui-avatars.com/api/?name=CT&background=95A5A6&color=fff', '1996-02-28', N'44 Nguyễn Kiệm, Q.Phú Nhuận, TP.HCM');
GO


/* ================================================================
   [3] BOOKINGS — 16 booking trải đều các trạng thái, nhiều user
   StatusId: 1=Chờ TT | 2=Đã xác nhận | 3=Đã hủy | 4=Đã hoàn thành | 5=Chờ cọc
================================================================ */

DECLARE
    @B1  INT, @B2  INT, @B3  INT, @B4  INT, @B5  INT,
    @B6  INT, @B7  INT, @B8  INT, @B9  INT, @B10 INT,
    @B11 INT, @B12 INT, @B13 INT, @B14 INT, @B15 INT, @B16 INT;

-- ── Đã hoàn thành (quá khứ) ──────────────────────────────────────
INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (6, 4, 300000,0,0,300000,0, N'Đặt sân đá giao hữu nội bộ công ty', DATEADD(DAY,-30,SYSDATETIME()), DATEADD(DAY,-28,SYSDATETIME()));
SET @B1 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (7, 4, 550000,50000,0,500000,0, N'Giải phong trào khu phố - vòng bảng', DATEADD(DAY,-25,SYSDATETIME()), DATEADD(DAY,-24,SYSDATETIME()));
SET @B2 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (8, 4, 360000,0,0,360000,0, N'Sinh nhật bạn thân - đặt cả sân A2', DATEADD(DAY,-20,SYSDATETIME()), DATEADD(DAY,-19,SYSDATETIME()));
SET @B3 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (9, 4, 200000,20000,0,180000,0, N'Tập luyện cuối tuần', DATEADD(DAY,-15,SYSDATETIME()), DATEADD(DAY,-14,SYSDATETIME()));
SET @B4 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (10, 4, 1000000,0,0,1000000,0, N'Sân B2 - giải đấu mở rộng 7 người', DATEADD(DAY,-12,SYSDATETIME()), DATEADD(DAY,-11,SYSDATETIME()));
SET @B5 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (11, 4, 480000,0,0,480000,0, N'Đội bóng văn phòng - đá mỗi thứ 5', DATEADD(DAY,-10,SYSDATETIME()), DATEADD(DAY,-9,SYSDATETIME()));
SET @B6 = SCOPE_IDENTITY();

-- ── Đã hủy ───────────────────────────────────────────────────────
INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CancelReason,CreatedAt,UpdatedAt)
VALUES (12, 3, 200000,0,0,200000,0, N'Sân A3 thứ 6', N'Đội bạn không đủ người', DATEADD(DAY,-8,SYSDATETIME()), DATEADD(DAY,-7,SYSDATETIME()));
SET @B7 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CancelReason,CreatedAt,UpdatedAt)
VALUES (13, 3, 300000,0,0,300000,60000, N'Sân A1 tối thứ 3', N'Trời mưa lớn, không thể đá', DATEADD(DAY,-6,SYSDATETIME()), DATEADD(DAY,-5,SYSDATETIME()));
SET @B8 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CancelReason,CreatedAt,UpdatedAt)
VALUES (14, 3, 550000,0,0,550000,0, N'Sân B1 cuối tuần', N'Nhầm ngày đặt', DATEADD(DAY,-4,SYSDATETIME()), DATEADD(DAY,-3,SYSDATETIME()));
SET @B9 = SCOPE_IDENTITY();

-- ── Đã xác nhận (sắp tới) ────────────────────────────────────────
INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (6, 2, 300000,0,0,300000,0, N'Sân A1 - đá giao lưu với team kế toán', DATEADD(DAY,-2,SYSDATETIME()), SYSDATETIME());
SET @B10 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (15, 2, 500000,50000,0,450000,0, N'Sân B1 - giải nghề nghiệp vòng 2', DATEADD(DAY,-1,SYSDATETIME()), SYSDATETIME());
SET @B11 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (16, 2, 380000,0,0,380000,0, N'Sân A2 - đội bóng trường cũ họp mặt', DATEADD(HOUR,-5,SYSDATETIME()), SYSDATETIME());
SET @B12 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (17, 2, 1100000,0,0,1100000,220000, N'Sân B2 - giải 7 người liên quận', DATEADD(HOUR,-3,SYSDATETIME()), SYSDATETIME());
SET @B13 = SCOPE_IDENTITY();

-- ── Chờ đặt cọc ──────────────────────────────────────────────────
INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (18, 5, 600000,0,0,600000,120000, N'Sân A1+A2 - đặt nhóm 2 sân cùng lúc', DATEADD(MINUTE,-90,SYSDATETIME()), SYSDATETIME());
SET @B14 = SCOPE_IDENTITY();

INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (19, 5, 500000,0,0,500000,100000, N'Sân B1 tối thứ 7', DATEADD(MINUTE,-60,SYSDATETIME()), SYSDATETIME());
SET @B15 = SCOPE_IDENTITY();

-- ── Chờ thanh toán ───────────────────────────────────────────────
INSERT INTO Bookings (UserId,StatusId,SubTotal,DiscountAmount,TaxAmount,TotalAmount,DepositAmount,Note,CreatedAt,UpdatedAt)
VALUES (7, 1, 200000,0,0,200000,0, N'Sân A3 - chờ xác nhận thanh toán', DATEADD(MINUTE,-5,SYSDATETIME()), SYSDATETIME());
SET @B16 = SCOPE_IDENTITY();


/* ================================================================
   [4] PAYMENTS
================================================================ */

-- Booking 1-6: đã hoàn thành, đã thanh toán đủ
INSERT INTO Payments (BookingId,Amount,StatusId,MethodId,TransactionCode,Note,PaidAt,CreatedAt) VALUES
(@B1,  300000, 2, 1, NULL,                  N'Tiền mặt tại quầy',        DATEADD(DAY,-30,SYSDATETIME()), DATEADD(DAY,-30,SYSDATETIME())),
(@B2,  500000, 2, 3, N'VNPAY202603250001',  N'VNPay online',             DATEADD(DAY,-25,SYSDATETIME()), DATEADD(DAY,-25,SYSDATETIME())),
(@B3,  360000, 2, 4, N'MOMO202604010001',   N'MoMo transfer',            DATEADD(DAY,-20,SYSDATETIME()), DATEADD(DAY,-20,SYSDATETIME())),
(@B4,  180000, 2, 2, N'CK2026040510001',    N'Chuyển khoản MB Bank',     DATEADD(DAY,-15,SYSDATETIME()), DATEADD(DAY,-15,SYSDATETIME())),
(@B5, 1000000, 2, 3, N'VNPAY202604100001',  N'VNPay giải đấu',           DATEADD(DAY,-12,SYSDATETIME()), DATEADD(DAY,-12,SYSDATETIME())),
(@B6,  480000, 2, 1, NULL,                  N'Tiền mặt',                 DATEADD(DAY,-10,SYSDATETIME()), DATEADD(DAY,-10,SYSDATETIME())),

-- Booking 7: hủy sớm → hoàn tiền 100%
(@B7,  200000, 2, 1, NULL,                  N'Thanh toán tiền mặt',      DATEADD(DAY,-8,SYSDATETIME()),  DATEADD(DAY,-8,SYSDATETIME())),
(@B7,  200000, 4, 1, NULL,                  N'Hoàn tiền - hủy đủ điều kiện', DATEADD(DAY,-7,SYSDATETIME()), DATEADD(DAY,-7,SYSDATETIME())),

-- Booking 8: hủy muộn → mất cọc 60k, hoàn 240k
(@B8,  300000, 2, 3, N'VNPAY202604200001',  N'Thanh toán VNPay',         DATEADD(DAY,-6,SYSDATETIME()),  DATEADD(DAY,-6,SYSDATETIME())),
(@B8,  240000, 4, 3, N'REFUND202604210001', N'Hoàn tiền (trừ cọc 60k)',  DATEADD(DAY,-5,SYSDATETIME()),  DATEADD(DAY,-5,SYSDATETIME())),

-- Booking 10-13: đã xác nhận, đã thanh toán
(@B10, 300000, 2, 4, N'MOMO202605010001',   N'MoMo app',                 DATEADD(DAY,-2,SYSDATETIME()),  DATEADD(DAY,-2,SYSDATETIME())),
(@B11, 450000, 2, 2, N'CK2026050210001',    N'Chuyển khoản Vietcombank', DATEADD(DAY,-1,SYSDATETIME()),  DATEADD(DAY,-1,SYSDATETIME())),
(@B12, 380000, 2, 3, N'VNPAY202605030001',  N'VNPay checkout',           DATEADD(HOUR,-5,SYSDATETIME()), DATEADD(HOUR,-5,SYSDATETIME())),

-- Booking 13: đặt cọc trước (220k), thanh toán phần còn lại (880k)
(@B13, 220000, 2, 3, N'VNPAY202605030002',  N'Thanh toán đặt cọc',       DATEADD(HOUR,-2,SYSDATETIME()), DATEADD(HOUR,-2,SYSDATETIME()));


/* ================================================================
   [5] DEPOSITS
================================================================ */

-- Booking 8: đã tịch thu (hủy muộn)
INSERT INTO Deposits (BookingId,RequiredAmount,PaidAmount,StatusId,DeadlineAt,PaidAt,ForfeitedAt,CreatedAt,UpdatedAt)
VALUES (@B8, 60000, 60000, 4,
        DATEADD(HOUR,2,DATEADD(DAY,-6,SYSDATETIME())),
        DATEADD(DAY,-6,SYSDATETIME()),
        DATEADD(DAY,-5,SYSDATETIME()),
        DATEADD(DAY,-6,SYSDATETIME()),
        DATEADD(DAY,-5,SYSDATETIME()));

-- Booking 13: đã nộp cọc
INSERT INTO Deposits (BookingId,RequiredAmount,PaidAmount,StatusId,DeadlineAt,PaidAt,CreatedAt,UpdatedAt)
VALUES (@B13, 220000, 220000, 2,
        DATEADD(HOUR,2,DATEADD(HOUR,-3,SYSDATETIME())),
        DATEADD(HOUR,-2,SYSDATETIME()),
        DATEADD(HOUR,-3,SYSDATETIME()),
        SYSDATETIME());

-- Booking 14: chờ nộp cọc (hạn 90 phút)
INSERT INTO Deposits (BookingId,RequiredAmount,PaidAmount,StatusId,DeadlineAt,CreatedAt,UpdatedAt)
VALUES (@B14, 120000, 0, 1,
        DATEADD(MINUTE,30,SYSDATETIME()),
        DATEADD(MINUTE,-90,SYSDATETIME()),
        SYSDATETIME());

-- Booking 15: chờ nộp cọc (hạn 60 phút)
INSERT INTO Deposits (BookingId,RequiredAmount,PaidAmount,StatusId,DeadlineAt,CreatedAt,UpdatedAt)
VALUES (@B15, 100000, 0, 1,
        DATEADD(HOUR,1,SYSDATETIME()),
        DATEADD(MINUTE,-60,SYSDATETIME()),
        SYSDATETIME());


/* ================================================================
   [6] BOOKING SERVICES — dịch vụ đi kèm
   ServiceId: 1=Thuê bóng | 2=Thuê áo | 3=Nước uống | 4=Thuê giày | 5=Trọng tài
================================================================ */

INSERT INTO BookingServices (BookingId,ServiceId,Quantity,UnitPrice) VALUES
(@B1,  1, 1,  30000),   -- thuê bóng
(@B1,  3, 1, 120000),   -- nước uống
(@B2,  2, 1, 150000),   -- thuê áo x1 set
(@B2,  5, 1, 200000),   -- thuê trọng tài
(@B3,  1, 2,  30000),   -- 2 quả bóng
(@B3,  3, 2, 120000),   -- 2 thùng nước
(@B5,  2, 2, 150000),   -- 2 set áo (2 đội)
(@B5,  5, 1, 200000),   -- trọng tài giải đấu
(@B5,  3, 2, 120000),   -- nước cho 2 đội
(@B6,  1, 1,  30000),   -- thuê bóng
(@B10, 1, 1,  30000),
(@B11, 2, 1, 150000),
(@B11, 5, 1, 200000),
(@B13, 2, 2, 150000),
(@B13, 5, 1, 200000),
(@B13, 3, 3, 120000);


/* ================================================================
   [7] REVIEWS — 1 review / booking đã hoàn thành (B1-B6)
================================================================ */

INSERT INTO Reviews (BookingId,UserId,FieldId,Rating,Comment,IsVisible,CreatedAt,UpdatedAt) VALUES
(@B1, 6,  1, 5,
 N'Sân A1 rất đẹp, cỏ mới, đèn sáng tốt. Nhân viên hỗ trợ nhanh nhiệt. Chắc chắn quay lại!',
 1, DATEADD(DAY,-28,SYSDATETIME()), DATEADD(DAY,-28,SYSDATETIME())),

(@B2, 7,  4, 4,
 N'Sân B1 rộng, mặt sân tốt. Chỉ tiếc là bãi giữ xe hơi chật. Tổng thể hài lòng.',
 1, DATEADD(DAY,-24,SYSDATETIME()), DATEADD(DAY,-24,SYSDATETIME())),

(@B3, 8,  2, 5,
 N'Sân A2 ngoài trời nhưng mặt cỏ rất mượt. Giá hợp lý, đặt online tiện lợi. 5 sao!',
 1, DATEADD(DAY,-19,SYSDATETIME()), DATEADD(DAY,-19,SYSDATETIME())),

(@B4, 9,  3, 3,
 N'Sân ổn nhưng đèn 1 góc hơi mờ vào tối. Mong đội kỹ thuật kiểm tra lại.',
 1, DATEADD(DAY,-14,SYSDATETIME()), DATEADD(DAY,-14,SYSDATETIME())),

(@B5, 10, 5, 5,
 N'Sân B2 rất xịn, phòng thay đồ sạch sẽ, nhân viên chuyên nghiệp. Tổ chức giải đây nha!',
 1, DATEADD(DAY,-11,SYSDATETIME()), DATEADD(DAY,-11,SYSDATETIME())),

(@B6, 11, 1, 4,
 N'Sân sạch, dịch vụ thuê áo chất lượng tốt. Đặt sân qua app nhanh và dễ. Recommend!',
 1, DATEADD(DAY,-9,SYSDATETIME()),  DATEADD(DAY,-9,SYSDATETIME())),

-- Review ẩn (vi phạm nội dung)
(@B7, 12, 3, 1,
 N'[Review vi phạm - đã ẩn bởi admin]',
 0, DATEADD(DAY,-7,SYSDATETIME()),  DATEADD(DAY,-6,SYSDATETIME()));


/* ================================================================
   [8] INCIDENTS — 10 sự cố thực tế
================================================================ */

INSERT INTO Incidents (FieldId,ReportedByUserId,Title,Description,StatusId,CreatedAt) VALUES
(1, 3, N'Đèn LED góc trái sân A1 hỏng',
 N'Đèn LED góc phía Tây-Bắc sân A1 không sáng từ tối qua. Ảnh hưởng tầm nhìn ca 19h-22h.',
 1, SYSDATETIME()),

(2, 6, N'Cỏ nhân tạo sân A2 bị bong mép',
 N'Khu vực gần cầu môn phía Nam, mép cỏ bị bong khoảng 30cm. Nguy cơ vấp ngã cao.',
 2, DATEADD(DAY,-1,SYSDATETIME())),

(3, 4, N'Vòi nước phòng thay đồ sân A3 bị rỉ',
 N'Vòi nước số 3 trong phòng thay đồ nam bị rỉ liên tục, gây ướt sàn trơn.',
 2, DATEADD(DAY,-2,SYSDATETIME())),

(4, 8, N'Lưới bàn thắng sân B1 bị rách',
 N'Lưới bàn thắng phía Đông sân B1 bị rách một lỗ lớn ~40cm, không thể thi đấu chuẩn.',
 1, DATEADD(DAY,-1,SYSDATETIME())),

(5, 5, N'Hệ thống loa thông báo sân B2 không có âm thanh',
 N'Loa phát thanh phía khán đài không phát âm. Ảnh hưởng điều hành giải đấu.',
 2, DATEADD(DAY,-3,SYSDATETIME())),

(1, 9, N'Cổng vào sân A1 bị kẹt',
 N'Chốt khóa cổng phụ bên hông sân A1 bị kẹt, khách vào ra khó khăn vào giờ cao điểm.',
 3, DATEADD(DAY,-5,SYSDATETIME())),

(2, 3, N'Điểm mù camera giám sát sân A2',
 N'Camera góc Đông-Nam sân A2 bị lệch góc, không bao quát toàn bộ sân.',
 3, DATEADD(DAY,-7,SYSDATETIME())),

(4, 10, N'Bơm hơi bóng bị hỏng tại sân B1',
 N'Máy bơm hơi bóng đặt tại khu vực nhận đồ sân B1 không hoạt động.',
 3, DATEADD(DAY,-10,SYSDATETIME())),

(3, 11, N'Bảng điểm điện tử sân A3 hiển thị sai',
 N'Bảng điểm điện tử bị lỗi hiển thị giờ (chạy nhanh hơn thực tế x2). Cần reset firmware.',
 1, DATEADD(HOUR,-3,SYSDATETIME())),

(5, 7, N'Ghế ngồi khán giả sân B2 bị gãy chân',
 N'Dãy ghế C hàng 2 có 3 chiếc bị gãy chân, nguy hiểm cho khán giả. Cần thay thế ngay.',
 2, DATEADD(DAY,-2,SYSDATETIME()));

-- Cập nhật các sự cố đã xử lý (StatusId=3)
UPDATE Incidents
SET HandledByUserId=1, HandledAt=DATEADD(DAY,-4,SYSDATETIME()),
    HandledNote=N'Đã siết lại chốt cửa, bôi trơn bản lề. Hoạt động bình thường.'
WHERE Title=N'Cổng vào sân A1 bị kẹt';

UPDATE Incidents
SET HandledByUserId=1, HandledAt=DATEADD(DAY,-6,SYSDATETIME()),
    HandledNote=N'Đã điều chỉnh lại góc camera, kiểm tra và ghi nhận vùng phủ sóng.'
WHERE Title=N'Điểm mù camera giám sát sân A2';

UPDATE Incidents
SET HandledByUserId=3, HandledAt=DATEADD(DAY,-9,SYSDATETIME()),
    HandledNote=N'Đã thay máy bơm mới, nhập từ kho phụ tùng.'
WHERE Title=N'Bơm hơi bóng bị hỏng tại sân B1';
GO


/* ================================================================
   [9] NOTIFICATIONS — đa dạng loại, nhiều user
================================================================ */

INSERT INTO Notifications (UserId,Title,Body,Type,IsRead,CreatedAt) VALUES
(6,  N'Đặt sân thành công!',
     N'Booking #10 đã xác nhận. Sân A1 | 17:00-18:00 | Ngày mai. Hẹn gặp bạn!',
     N'BOOKING_CONFIRM', 1, DATEADD(DAY,-2,SYSDATETIME())),

(7,  N'Booking của bạn đã hoàn thành',
     N'Booking #2 đã hoàn thành. Cảm ơn bạn đã sử dụng Sport Plus. Hãy đánh giá trải nghiệm!',
     N'BOOKING_CONFIRM', 1, DATEADD(DAY,-24,SYSDATETIME())),

(8,  N'Booking đã bị hủy',
     N'Booking #3 đã hủy do: Sinh nhật bạn thân. Tiền hoàn sẽ về trong 1-3 ngày làm việc.',
     N'BOOKING_CANCEL', 1, DATEADD(DAY,-19,SYSDATETIME())),

(18, N'⏰ Nhắc: Nộp cọc còn 30 phút!',
     N'Booking #14 cần nộp cọc 120.000đ trước 30 phút nữa. Quá hạn sẽ tự động hủy.',
     N'DEPOSIT', 0, DATEADD(MINUTE,-60,SYSDATETIME())),

(19, N'⏰ Nhắc: Nộp cọc trong 1 giờ',
     N'Booking #15 cần nộp cọc 100.000đ trước 1 giờ nữa. Vui lòng thanh toán sớm.',
     N'DEPOSIT', 0, DATEADD(MINUTE,-30,SYSDATETIME())),

(15, N'Thanh toán thành công',
     N'Đã ghi nhận 450.000đ qua Chuyển khoản. Booking #11 đã xác nhận.',
     N'PAYMENT', 1, DATEADD(DAY,-1,SYSDATETIME())),

(16, N'Thanh toán thành công',
     N'Đã ghi nhận 380.000đ qua VNPay. Booking #12 đã xác nhận.',
     N'PAYMENT', 1, DATEADD(HOUR,-5,SYSDATETIME())),

(17, N'Đã nhận tiền cọc',
     N'Cọc 220.000đ cho Booking #13 đã xác nhận. Slot giải đấu đã được giữ chắc cho bạn.',
     N'DEPOSIT', 0, DATEADD(HOUR,-2,SYSDATETIME())),

(3,  N'🔧 Sự cố mới: Đèn LED sân A1',
     N'Khách báo cáo đèn LED góc trái sân A1 hỏng. Vui lòng kiểm tra và xử lý ngay.',
     N'INCIDENT', 0, SYSDATETIME()),

(4,  N'🔧 Sự cố mới: Lưới rách sân B1',
     N'Lưới bàn thắng phía Đông sân B1 bị rách lớn. Cần thay trước ca chiều.',
     N'INCIDENT', 0, DATEADD(DAY,-1,SYSDATETIME())),

(6,  N'Ưu đãi dành riêng cho bạn 🎁',
     N'Dùng mã KHAIMEN10 giảm 10% cho lần đặt sân tiếp theo. HSD: cuối tháng.',
     N'SYSTEM', 0, DATEADD(DAY,-3,SYSDATETIME())),

(1,  N'Báo cáo doanh thu tháng 4',
     N'Doanh thu tháng 4/2026: 24.580.000đ (+12% so với tháng 3). Xem chi tiết trong Dashboard.',
     N'SYSTEM', 1, DATEADD(DAY,-5,SYSDATETIME())),

(9,  N'Đặt sân thành công!',
     N'Booking #4 đã xác nhận. Sân A1 | 14:00-15:00. Chúc đội đá vui!',
     N'BOOKING_CONFIRM', 1, DATEADD(DAY,-15,SYSDATETIME())),

(12, N'Booking đã bị hủy',
     N'Booking #7 (Sân A3) đã hủy. Lý do: Đội bạn không đủ người. Không phát sinh phí hủy.',
     N'BOOKING_CANCEL', 1, DATEADD(DAY,-7,SYSDATETIME())),

(1,  N'Sản phẩm sắp hết hàng',
     N'Lưới bàn thắng còn 4 bộ (dưới mức tối thiểu). Vui lòng kiểm tra đơn nhập kho.',
     N'SYSTEM', 0, SYSDATETIME());
GO


/* ================================================================
   [10] SUPPLIERS
================================================================ */

INSERT INTO Suppliers (Name,ContactName,Phone,Email,Address) VALUES
(N'Công ty TNHH Thể Thao Miền Nam',  N'Nguyễn Văn Phúc', N'0281234567', N'contact@thethaomn.vn',   N'123 Nguyễn Đình Chiểu, Q.3, TP.HCM'),
(N'Đại lý Bóng Đá Pro',              N'Trần Minh Tuấn',  N'0289876543', N'sales@bdpro.vn',          N'456 Đinh Tiên Hoàng, Q.Bình Thạnh, TP.HCM'),
(N'Decathlon Việt Nam',               N'Lê Thị Hoa',      N'0283456789', N'b2b@decathlon.vn',        N'Lầu 1, Crescent Mall, Q.7, TP.HCM'),
(N'Công ty CP Thể Thao Động Lực',    N'Phạm Thanh Sơn',  N'0242345678', N'wholesale@dongluc.vn',    N'15 Đinh Lễ, Hoàn Kiếm, Hà Nội'),
(N'Adidas Việt Nam - B2B',           N'David Nguyễn',    N'0289001122', N'b2b.vn@adidas.com',        N'72 Lê Thánh Tôn, Q.1, TP.HCM');
GO


/* ================================================================
   [11] PRODUCTS
================================================================ */

INSERT INTO Products (Name,Unit,StockQty,MinQty) VALUES
(N'Bóng đá Futsal size 4',           N'Quả',   20,  5),
(N'Bóng đá sân 7 size 5',            N'Quả',   15,  5),
(N'Áo thi đấu (set 10 cái)',         N'Set',    8,  3),
(N'Nước uống Aquafina 500ml',        N'Thùng', 30, 10),
(N'Giày đá bóng size 39-43',         N'Đôi',   12,  5),
(N'Lưới bàn thắng',                  N'Bộ',     4,  2),   -- ⚠ sắp hết
(N'Cột cờ hiệu (set 4 cái)',         N'Set',    6,  2),
(N'Băng đội trưởng',                 N'Cái',   20,  5),
(N'Còi trọng tài',                   N'Cái',   10,  3),
(N'Bơm bóng + kim (bộ)',             N'Bộ',     8,  3),
(N'Bình xịt lạnh sơ cứu',           N'Bình',   5,  3),   -- ⚠ sắp hết
(N'Băng dán cơ (Kinesio tape)',      N'Cuộn',  15,  5),
(N'Hộp sơ cứu thể thao',            N'Hộp',    4,  2),   -- ⚠ sắp hết
(N'Bảng chiến thuật từ tính',        N'Cái',    6,  2),
(N'Đồng hồ bấm giờ thi đấu',        N'Cái',    8,  3);
GO


/* ================================================================
   [12] PURCHASE ORDERS
================================================================ */

DECLARE @PO1 INT,@PO2 INT,@PO3 INT,@PO4 INT,@PO5 INT;
DECLARE @S1 INT,@S2 INT,@S3 INT,@S4 INT;

SELECT @S1=SupplierId FROM Suppliers WHERE Name=N'Công ty TNHH Thể Thao Miền Nam';
SELECT @S2=SupplierId FROM Suppliers WHERE Name=N'Đại lý Bóng Đá Pro';
SELECT @S3=SupplierId FROM Suppliers WHERE Name=N'Decathlon Việt Nam';
SELECT @S4=SupplierId FROM Suppliers WHERE Name=N'Công ty CP Thể Thao Động Lực';

-- PO1: Đã nhập (tháng 3)
INSERT INTO PurchaseOrders (SupplierId,CreatedByUserId,StatusId,TotalAmount,Note,ConfirmedAt,CreatedAt)
VALUES (@S1,1,2,4800000,N'Nhập hàng định kỳ tháng 3/2026',DATEADD(DAY,-45,SYSDATETIME()),DATEADD(DAY,-46,SYSDATETIME()));
SET @PO1=SCOPE_IDENTITY();
INSERT INTO PurchaseOrderDetails (PurchaseOrderId,ProductId,Quantity,UnitPrice)
SELECT @PO1,p.ProductId,v.Qty,v.Price FROM (VALUES
    (N'Bóng đá Futsal size 4',20,120000),(N'Bóng đá sân 7 size 5',10,150000),
    (N'Nước uống Aquafina 500ml',30,55000),(N'Băng đội trưởng',20,25000)
) v(Name,Qty,Price) JOIN Products p ON p.Name=v.Name;

-- PO2: Đã nhập (tháng 4)
INSERT INTO PurchaseOrders (SupplierId,CreatedByUserId,StatusId,TotalAmount,Note,ConfirmedAt,CreatedAt)
VALUES (@S2,3,2,6500000,N'Nhập hàng tháng 4/2026',DATEADD(DAY,-15,SYSDATETIME()),DATEADD(DAY,-16,SYSDATETIME()));
SET @PO2=SCOPE_IDENTITY();
INSERT INTO PurchaseOrderDetails (PurchaseOrderId,ProductId,Quantity,UnitPrice)
SELECT @PO2,p.ProductId,v.Qty,v.Price FROM (VALUES
    (N'Áo thi đấu (set 10 cái)',5,400000),(N'Giày đá bóng size 39-43',8,250000),
    (N'Còi trọng tài',5,40000),(N'Lưới bàn thắng',3,450000)
) v(Name,Qty,Price) JOIN Products p ON p.Name=v.Name;

-- PO3: Đã nhập (tuần trước) - thiết bị y tế
INSERT INTO PurchaseOrders (SupplierId,CreatedByUserId,StatusId,TotalAmount,Note,ConfirmedAt,CreatedAt)
VALUES (@S3,3,2,2350000,N'Bổ sung thiết bị sơ cứu',DATEADD(DAY,-7,SYSDATETIME()),DATEADD(DAY,-8,SYSDATETIME()));
SET @PO3=SCOPE_IDENTITY();
INSERT INTO PurchaseOrderDetails (PurchaseOrderId,ProductId,Quantity,UnitPrice)
SELECT @PO3,p.ProductId,v.Qty,v.Price FROM (VALUES
    (N'Bình xịt lạnh sơ cứu',10,120000),(N'Băng dán cơ (Kinesio tape)',20,45000),
    (N'Hộp sơ cứu thể thao',5,130000)
) v(Name,Qty,Price) JOIN Products p ON p.Name=v.Name;

-- PO4: Chờ xác nhận (đặt hôm nay)
INSERT INTO PurchaseOrders (SupplierId,CreatedByUserId,StatusId,Note,CreatedAt)
VALUES (@S1,3,1,N'Nhập hàng định kỳ tháng 5/2026',SYSDATETIME());
SET @PO4=SCOPE_IDENTITY();
INSERT INTO PurchaseOrderDetails (PurchaseOrderId,ProductId,Quantity,UnitPrice)
SELECT @PO4,p.ProductId,v.Qty,v.Price FROM (VALUES
    (N'Bóng đá Futsal size 4',10,120000),(N'Bóng đá sân 7 size 5',5,150000),
    (N'Nước uống Aquafina 500ml',20,55000),(N'Lưới bàn thắng',5,450000)
) v(Name,Qty,Price) JOIN Products p ON p.Name=v.Name;

-- PO5: Đã hủy
INSERT INTO PurchaseOrders (SupplierId,CreatedByUserId,StatusId,Note,CreatedAt)
VALUES (@S4,1,3,N'Đơn hủy - nhà cung cấp báo hết hàng',DATEADD(DAY,-20,SYSDATETIME()));
SET @PO5=SCOPE_IDENTITY();
INSERT INTO PurchaseOrderDetails (PurchaseOrderId,ProductId,Quantity,UnitPrice)
SELECT @PO5,p.ProductId,v.Qty,v.Price FROM (VALUES
    (N'Bảng chiến thuật từ tính',10,180000),(N'Đồng hồ bấm giờ thi đấu',5,220000)
) v(Name,Qty,Price) JOIN Products p ON p.Name=v.Name;
GO


/* ================================================================
   [13] FIELD MAINTENANCE LOGS
================================================================ */

INSERT INTO FieldMaintenanceLogs (FieldId,Reason,StartDate,EndDate,CreatedBy,CreatedAt) VALUES
(1, N'Bảo trì định kỳ quý 1: kiểm tra đèn LED, siết bu-lông khung cầu môn',
 DATEADD(DAY,-60,CAST(GETDATE() AS DATE)), DATEADD(DAY,-59,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-62,SYSDATETIME())),

(2, N'Thay mới toàn bộ mặt cỏ nhân tạo, sơn kẻ lại đường biên',
 DATEADD(DAY,-45,CAST(GETDATE() AS DATE)), DATEADD(DAY,-43,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-46,SYSDATETIME())),

(3, N'Sửa chữa hệ thống thoát nước mặt sân, bổ sung cát lấp đầy',
 DATEADD(DAY,-30,CAST(GETDATE() AS DATE)), DATEADD(DAY,-29,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-32,SYSDATETIME())),

(4, N'Thay bóng đèn LED toàn bộ 16 cột đèn, nâng công suất chiếu sáng',
 DATEADD(DAY,-20,CAST(GETDATE() AS DATE)), DATEADD(DAY,-18,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-22,SYSDATETIME())),

(5, N'Sơn lại đường biên và khu 16m50, thay mới lưới bàn thắng 2 bên',
 DATEADD(DAY,-10,CAST(GETDATE() AS DATE)), DATEADD(DAY,-8,CAST(GETDATE() AS DATE)),  1, DATEADD(DAY,-12,SYSDATETIME())),

(1, N'Khắc phục sự cố cổng phụ: thay khóa chống gỉ loại mới',
 DATEADD(DAY,-4,CAST(GETDATE() AS DATE)),  DATEADD(DAY,-4,CAST(GETDATE() AS DATE)),  3, DATEADD(DAY,-5,SYSDATETIME())),

(2, N'Điều chỉnh và hiệu chỉnh hệ thống camera giám sát 6 góc',
 DATEADD(DAY,-6,CAST(GETDATE() AS DATE)),  DATEADD(DAY,-5,CAST(GETDATE() AS DATE)),  3, DATEADD(DAY,-7,SYSDATETIME())),

(4, N'Thay máy bơm hơi bóng mới, kiểm tra toàn bộ thiết bị phòng nhận đồ',
 DATEADD(DAY,-9,CAST(GETDATE() AS DATE)),  DATEADD(DAY,-9,CAST(GETDATE() AS DATE)),  3, DATEADD(DAY,-10,SYSDATETIME())),

(3, N'Bảo trì định kỳ quý 1: vệ sinh phòng thay đồ, thay vòi nước hỏng',
 DATEADD(DAY,-55,CAST(GETDATE() AS DATE)), DATEADD(DAY,-54,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-57,SYSDATETIME())),

(5, N'Lắp đặt mái che di động góc khán đài, bổ sung ghế ngồi khu VIP',
 DATEADD(DAY,-90,CAST(GETDATE() AS DATE)), DATEADD(DAY,-87,CAST(GETDATE() AS DATE)), 1, DATEADD(DAY,-92,SYSDATETIME()));
GO


/* ================================================================
   [14] FIELD PRICE HISTORY
================================================================ */

INSERT INTO FieldPriceHistory (FieldId,OldBasePrice,OldPeakPrice,NewBasePrice,NewPeakPrice,ChangedBy,ChangedAt,Reason) VALUES
(1, 150000,220000, 180000,270000, 1, DATEADD(MONTH,-6,SYSDATETIME()), N'Điều chỉnh giá đầu năm 2026 theo chỉ số CPI'),
(1, 180000,270000, 200000,300000, 1, DATEADD(MONTH,-2,SYSDATETIME()), N'Nâng cấp hệ thống đèn LED mới, tăng chất lượng sân'),
(2, 150000,220000, 180000,270000, 1, DATEADD(MONTH,-6,SYSDATETIME()), N'Điều chỉnh giá đầu năm 2026'),
(2, 180000,270000, 180000,270000, 1, DATEADD(MONTH,-1,SYSDATETIME()), N'Giữ nguyên sau review nội bộ'),
(3, 160000,240000, 200000,300000, 2, DATEADD(MONTH,-3,SYSDATETIME()), N'Thay cỏ nhân tạo thế hệ mới, bổ sung mái che'),
(4, 280000,400000, 350000,500000, 1, DATEADD(MONTH,-4,SYSDATETIME()), N'Nâng cấp cơ sở vật chất, lắp hệ thống âm thanh'),
(5, 300000,430000, 380000,550000, 1, DATEADD(MONTH,-5,SYSDATETIME()), N'Hoàn thiện khu VIP và phòng thay đồ cao cấp'),
(5, 380000,550000, 380000,550000, 2, DATEADD(MONTH,-1,SYSDATETIME()), N'Giữ nguyên - thị trường ổn định'),
(1, 200000,300000, 200000,300000, 1, DATEADD(WEEK,-2,SYSDATETIME()),  N'Đánh giá định kỳ - không thay đổi'),
(4, 350000,500000, 350000,500000, 1, DATEADD(WEEK,-1,SYSDATETIME()),  N'Đánh giá định kỳ - không thay đổi');
GO


/* ================================================================
   [15] PROMOTIONS
================================================================ */

INSERT INTO Promotions (Code,Name,TypeId,DiscountValue,MaxDiscount,MinOrderAmount,UsageLimit,UsageCount,StartDate,EndDate,CreatedBy) VALUES
(N'KHAIMEN10',    N'Ưu đãi khai trương - Giảm 10%',               1, 10,    50000,  100000, 200, 47,
 DATEADD(MONTH,-2,CAST(GETDATE() AS DATE)), DATEADD(MONTH,1,CAST(GETDATE() AS DATE)), 1),

(N'GIAMMANH50K',  N'Giảm ngay 50.000đ cho đơn từ 200k',           2, 50000, NULL,   200000,  50, 18,
 CAST(GETDATE() AS DATE), DATEADD(MONTH,1,CAST(GETDATE() AS DATE)), 1),

(N'WEEKEND15',    N'Weekend special - Giảm 15% đặt sân cuối tuần',1, 15,    75000,  150000, 100, 23,
 CAST(GETDATE() AS DATE), DATEADD(MONTH,3,CAST(GETDATE() AS DATE)), 1),

(N'MEMBER20',     N'Khách thân thiết - Giảm 20%',                  1, 20,   100000, 300000,  30,  9,
 CAST(GETDATE() AS DATE), DATEADD(MONTH,6,CAST(GETDATE() AS DATE)), 1),

(N'GIAI7NGUOI',   N'Ưu đãi đặt sân 7 người - Giảm 100k',          2, 100000,NULL,  500000,  20,  5,
 CAST(GETDATE() AS DATE), DATEADD(MONTH,2,CAST(GETDATE() AS DATE)), 1),

(N'SUMMER25',     N'Hè 2026 - Giảm 25% tất cả sân',               1, 25,   150000, 200000,  50,  0,
 DATEADD(MONTH,1,CAST(GETDATE() AS DATE)), DATEADD(MONTH,4,CAST(GETDATE() AS DATE)), 1),

(N'FLASHSALE',    N'Flash Sale - Giảm 200k đơn từ 600k',           2, 200000,NULL,  600000,  10,  10,
 DATEADD(MONTH,-1,CAST(GETDATE() AS DATE)), DATEADD(DAY,-1,CAST(GETDATE() AS DATE)), 1),  -- hết hạn hôm qua

(N'NEWUSER30',    N'Chào khách mới - Giảm 30% lần đầu đặt sân',   1, 30,    90000, 100000, 999, 14,
 DATEADD(MONTH,-3,CAST(GETDATE() AS DATE)), DATEADD(MONTH,9,CAST(GETDATE() AS DATE)), 2);
GO


/* ================================================================
   [16] SPECIAL DAYS
================================================================ */

-- Xóa nếu đã có từ script main (tránh dup)
DELETE FROM SpecialDays WHERE CreatedBy IS NOT NULL;

INSERT INTO SpecialDays (SpecialDate,Name,PriceMultiplier,IsFullDayPeak,Note,CreatedBy) VALUES
(DATEADD(DAY,  3,CAST(GETDATE() AS DATE)), N'Cuối tuần event cộng đồng',   1.2, 0, N'Tăng 20% cuối tuần có sự kiện',     1),
(DATEADD(DAY,  7,CAST(GETDATE() AS DATE)), N'Giải bóng đá mở rộng Q.1',    1.3, 1, N'Cả ngày giờ cao điểm',              1),
(DATEADD(DAY, 14,CAST(GETDATE() AS DATE)), N'Ngày Gia đình Việt Nam 28/6',  1.5, 1, N'Nhu cầu cao dịp gia đình',          1),
('2026-04-30',                             N'Lễ 30/4 - Giải phóng Miền Nam',1.5, 1, N'Nghỉ lễ toàn quốc',                1),
('2026-05-01',                             N'Lễ 1/5 - Quốc tế Lao động',    1.5, 1, N'Nghỉ lễ toàn quốc',                1),
('2026-09-01',                             N'Tết Thiếu Nhi bù (01/9)',       1.2, 0, N'Lễ bù, nhu cầu tăng nhẹ',         1),
('2026-09-02',                             N'Lễ Quốc khánh 2/9',            1.5, 1, N'Nghỉ lễ toàn quốc',                1),
('2026-01-01',                             N'Tết Dương lịch 2027',           1.3, 1, N'Ngày đầu năm',                     1),
('2026-10-20',                             N'Ngày Phụ nữ Việt Nam 20/10',   1.2, 0, N'Tăng nhẹ - sự kiện nội bộ cty',   1),
('2026-11-20',                             N'Ngày Nhà giáo Việt Nam 20/11',  1.1, 0, N'Nhu cầu tổ chức giải trường',     1),
('2026-12-25',                             N'Giáng sinh 2026',               1.3, 0, N'Nhu cầu đặt sân tăng dịp Noel',   1),
('2026-12-31',                             N'Tất niên 31/12',                1.5, 1, N'Cuối năm - nhu cầu rất cao',       1);
GO


/* ================================================================
   KIỂM TRA KẾT QUẢ
================================================================ */

PRINT N'';
PRINT N'====== SEED DATA SUMMARY ======';
PRINT N'';

SELECT [Table],[Count] FROM (
SELECT N'Users'                  AS [Table], COUNT(*) AS [Count] FROM Users       WHERE IsDeleted=0 UNION ALL
SELECT N'Profiles',               COUNT(*)                        FROM Profiles                      UNION ALL
SELECT N'Fields (active)',         COUNT(*)                        FROM Fields      WHERE IsDeleted=0 AND StatusId=1 UNION ALL
SELECT N'TimeSlots',               COUNT(*)                        FROM TimeSlots                     UNION ALL
SELECT N'FieldSlots (today+30d)', COUNT(*)                        FROM FieldSlots  WHERE SlotDate>=CAST(GETDATE() AS DATE) UNION ALL
SELECT N'Bookings',                COUNT(*)                        FROM Bookings                      UNION ALL
SELECT N'BookingServices',         COUNT(*)                        FROM BookingServices               UNION ALL
SELECT N'Payments',                COUNT(*)                        FROM Payments                      UNION ALL
SELECT N'Deposits',                COUNT(*)                        FROM Deposits                      UNION ALL
SELECT N'Reviews',                 COUNT(*)                        FROM Reviews                       UNION ALL
SELECT N'Incidents',               COUNT(*)                        FROM Incidents                     UNION ALL
SELECT N'Notifications',           COUNT(*)                        FROM Notifications                 UNION ALL
SELECT N'Suppliers',               COUNT(*)                        FROM Suppliers   WHERE IsDeleted=0 UNION ALL
SELECT N'Products',                COUNT(*)                        FROM Products    WHERE IsDeleted=0 UNION ALL
SELECT N'PurchaseOrders',          COUNT(*)                        FROM PurchaseOrders                UNION ALL
SELECT N'Promotions (active)',      COUNT(*)                        FROM Promotions  WHERE IsActive=1
    AND CAST(GETDATE() AS DATE) BETWEEN StartDate AND EndDate      UNION ALL
SELECT N'SpecialDays',             COUNT(*)                        FROM SpecialDays                   UNION ALL
SELECT N'FieldMaintenanceLogs',    COUNT(*)                        FROM FieldMaintenanceLogs          UNION ALL
SELECT N'FieldPriceHistory',       COUNT(*)                        FROM FieldPriceHistory
) t ORDER BY [Table];

PRINT N'';
PRINT N'====== USERS CREATED ======';
SELECT u.UserId, u.FullName, u.Email, u.Phone, r.Name AS Role, us.Name AS [Status]
FROM Users u
JOIN Roles r ON u.RoleId=r.RoleId
JOIN UserStatuses us ON u.StatusId=us.StatusId
ORDER BY u.RoleId, u.UserId;

PRINT N'';
PRINT N'⚠️  Nhớ thay PasswordHash sau khi có API Auth!';
PRINT N'✅  Seed data expanded hoàn tất.';
GO