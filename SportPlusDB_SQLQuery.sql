/* ================================================================
   SportPlusDB — Hệ thống quản lý sân bóng Sport Plus
   FINAL VERSION — Sẵn sàng cho API development
   
   STACK: SQL Server 2019+, Collation: Vietnamese_CI_AS
   
   MỤC LỤC:
   [1]  DROP & CREATE DATABASE
   [2]  LOOKUP TABLES + SEED
   [3]  USERS & AUTH
   [4]  FIELDS (Sân bóng) — CORE
   [5]  BOOKINGS & PAYMENTS — CORE
   [6]  SERVICES (Dịch vụ đi kèm)
   [7]  PROMOTIONS & VOUCHERS
   [8]  INVENTORY (Kho)
   [9]  INCIDENTS (Sự cố)
   [10] NOTIFICATIONS
   [11] AUDIT LOG
   [12] STORED PROCEDURES
   [13] VIEWS
   [14] SEED DATA MẪU
   [15] SQL AGENT JOBS (hướng dẫn)
================================================================ */


/* ================================================================
   [1] DROP & CREATE DATABASE
================================================================ */
USE master;
GO

IF DB_ID('SportPlusDB') IS NOT NULL
BEGIN
    ALTER DATABASE SportPlusDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SportPlusDB;
END
GO

CREATE DATABASE SportPlusDB COLLATE Vietnamese_CI_AS;
GO
USE SportPlusDB;
GO


/* ================================================================
   [2] LOOKUP TABLES + SEED
   Toàn bộ danh mục trạng thái, phân loại đặt vào đây.
================================================================ */

-- Vai trò người dùng
CREATE TABLE Roles (
    RoleId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL  -- Admin | Staff | Customer
);
GO

-- Trạng thái tài khoản
CREATE TABLE UserStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Hoạt động | Bị khóa
);
GO

-- Loại sân (5 người / 7 người)
CREATE TABLE FieldTypes (
    TypeId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL
);
GO

-- Trạng thái sân
CREATE TABLE FieldStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Hoạt động | Bảo trì
);
GO

-- Trạng thái ô giờ
CREATE TABLE FieldSlotStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Trống(1) | Đang giữ(2) | Đã đặt(3)
);
GO

-- Trạng thái booking
CREATE TABLE BookingStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL
    -- Chờ thanh toán(1) | Đã xác nhận(2) | Đã hủy(3) | Đã hoàn thành(4)
);
GO

-- Trạng thái thanh toán
CREATE TABLE PaymentStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL
    -- Chưa thanh toán(1) | Đã thanh toán(2) | Thất bại(3) | Đã hoàn tiền(4)
);
GO

-- Trạng thái sự cố
CREATE TABLE IncidentStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Mới(1) | Đang xử lý(2) | Đã xử lý(3)
);
GO

-- Trạng thái đơn nhập kho
CREATE TABLE PurchaseOrderStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Chờ xác nhận(1) | Đã nhập(2) | Đã hủy(3)
);
GO

-- Phương thức thanh toán (tham chiếu cố định, không hardcode string)
CREATE TABLE PaymentMethods (
    MethodId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Tiền mặt | Chuyển khoản | VNPay | MoMo
);
GO

-- Loại voucher
CREATE TABLE PromotionTypes (
    TypeId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL  -- Phần trăm | Số tiền cố định
);
GO

-- ---- SEED ----
INSERT INTO Roles(Name)              VALUES (N'Admin'), (N'Staff'), (N'Customer');
INSERT INTO UserStatuses(Name)       VALUES (N'Hoạt động'), (N'Bị khóa');
INSERT INTO FieldTypes(Name)         VALUES (N'Sân 5'), (N'Sân 7');
INSERT INTO FieldStatuses(Name)      VALUES (N'Hoạt động'), (N'Bảo trì');
INSERT INTO FieldSlotStatuses(Name)  VALUES (N'Trống'), (N'Đang giữ'), (N'Đã đặt');
INSERT INTO BookingStatuses(Name)    VALUES
    (N'Chờ thanh toán'), (N'Đã xác nhận'), (N'Đã hủy'), (N'Đã hoàn thành');
INSERT INTO PaymentStatuses(Name)    VALUES
    (N'Chưa thanh toán'), (N'Đã thanh toán'), (N'Thất bại'), (N'Đã hoàn tiền');
INSERT INTO IncidentStatuses(Name)   VALUES (N'Mới'), (N'Đang xử lý'), (N'Đã xử lý');
INSERT INTO PurchaseOrderStatuses(Name) VALUES
    (N'Chờ xác nhận'), (N'Đã nhập'), (N'Đã hủy');
INSERT INTO PaymentMethods(Name)     VALUES
    (N'Tiền mặt'), (N'Chuyển khoản'), (N'VNPay'), (N'MoMo');
INSERT INTO PromotionTypes(Name)     VALUES (N'Phần trăm'), (N'Số tiền cố định');
GO


/* ================================================================
   [3] USERS & AUTH
================================================================ */

CREATE TABLE Users (
    UserId       INT IDENTITY PRIMARY KEY,
    Email        NVARCHAR(100) NOT NULL,
    Phone        NVARCHAR(20)  NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName     NVARCHAR(100) NOT NULL,
    RoleId       INT NOT NULL,
    StatusId     INT NOT NULL DEFAULT 1,
    CreatedAt    DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt    DATETIME2 DEFAULT SYSDATETIME(),
    IsDeleted    BIT DEFAULT 0,

    CONSTRAINT UQ_Users_Email  UNIQUE(Email),
    CONSTRAINT UQ_Users_Phone  UNIQUE(Phone),
    FOREIGN KEY(RoleId)   REFERENCES Roles(RoleId),
    FOREIGN KEY(StatusId) REFERENCES UserStatuses(StatusId)
);
GO

CREATE TABLE Profiles (
    ProfileId   INT IDENTITY PRIMARY KEY,
    UserId      INT UNIQUE NOT NULL,
    AvatarUrl   NVARCHAR(500),
    DateOfBirth DATE,
    Address     NVARCHAR(255),
    FOREIGN KEY(UserId) REFERENCES Users(UserId)
);
GO

-- Refresh token cho JWT auth
CREATE TABLE RefreshTokens (
    TokenId   INT IDENTITY PRIMARY KEY,
    UserId    INT NOT NULL,
    Token     NVARCHAR(500) NOT NULL,
    ExpiresAt DATETIME2 NOT NULL,
    IsRevoked BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY(UserId) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_Users_RoleId        ON Users(RoleId);
CREATE INDEX IX_Users_StatusId      ON Users(StatusId);
CREATE INDEX IX_RefreshTokens_Token ON RefreshTokens(Token);
CREATE INDEX IX_RefreshTokens_User  ON RefreshTokens(UserId, IsRevoked);
GO

-- Seed admin mặc định (thay hash thực khi deploy)
INSERT INTO Users(Email, Phone, PasswordHash, FullName, RoleId, StatusId)
VALUES (N'admin@sportplus.vn', N'0900000001',
        N'$2a$12$REPLACE_WITH_REAL_BCRYPT_HASH',
        N'Quản trị viên', 1, 1);
INSERT INTO Profiles(UserId) VALUES (1);
GO


/* ================================================================
   [4] FIELDS (Sân bóng) — CORE
   Đây là phần trọng tâm của hệ thống.
================================================================ */

CREATE TABLE Fields (
    FieldId     INT IDENTITY PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    BasePrice   DECIMAL(12,2) NOT NULL,  -- Giá giờ thường
    PeakPrice   DECIMAL(12,2) NOT NULL,  -- Giá giờ cao điểm (tách riêng thay vì * 1.5 hardcode)
    ImageUrl    NVARCHAR(500),
    TypeId      INT NOT NULL,
    StatusId    INT NOT NULL DEFAULT 1,
    IsDeleted   BIT DEFAULT 0,
    CreatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt   DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Fields_BasePrice CHECK (BasePrice > 0),
    CONSTRAINT CK_Fields_PeakPrice CHECK (PeakPrice > 0),
    FOREIGN KEY(TypeId)   REFERENCES FieldTypes(TypeId),
    FOREIGN KEY(StatusId) REFERENCES FieldStatuses(StatusId)
);
GO

-- Khung giờ (dùng chung cho tất cả sân)
CREATE TABLE TimeSlots (
    SlotId     INT IDENTITY PRIMARY KEY,
    StartTime  TIME NOT NULL,
    EndTime    TIME NOT NULL,
    IsPeakHour BIT DEFAULT 0,
    CONSTRAINT UQ_TimeSlots UNIQUE(StartTime, EndTime)
);
GO

-- Ô giờ cụ thể theo ngày (FieldId x SlotId x Date)
CREATE TABLE FieldSlots (
    FieldSlotId  INT IDENTITY PRIMARY KEY,
    FieldId      INT NOT NULL,
    SlotId       INT NOT NULL,
    SlotDate     DATE NOT NULL,
    Price        DECIMAL(12,2) NOT NULL,
    StatusId     INT NOT NULL DEFAULT 1,
    HoldExpireAt DATETIME2 NULL,           -- NULL khi Trống hoặc Đã đặt
    UpdatedAt    DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_FieldSlots_Price CHECK (Price > 0),
    FOREIGN KEY(FieldId)  REFERENCES Fields(FieldId),
    FOREIGN KEY(SlotId)   REFERENCES TimeSlots(SlotId),
    FOREIGN KEY(StatusId) REFERENCES FieldSlotStatuses(StatusId),
    CONSTRAINT UQ_FieldSlot UNIQUE(FieldId, SlotId, SlotDate)
);
GO

-- Lịch bảo trì sân (track lý do tại sao sân bị StatusId=2)
CREATE TABLE FieldMaintenanceLogs (
    LogId       INT IDENTITY PRIMARY KEY,
    FieldId     INT NOT NULL,
    Reason      NVARCHAR(500) NOT NULL,
    StartDate   DATE NOT NULL,
    EndDate     DATE,
    CreatedBy   INT NOT NULL,
    CreatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY(FieldId)   REFERENCES Fields(FieldId),
    FOREIGN KEY(CreatedBy) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_Fields_TypeStatus      ON Fields(TypeId, StatusId) WHERE IsDeleted = 0;
CREATE INDEX IX_FieldSlots_Search      ON FieldSlots(FieldId, SlotDate, StatusId);
CREATE INDEX IX_FieldSlots_HoldExpire  ON FieldSlots(HoldExpireAt) WHERE StatusId = 2;
GO

-- Seed TimeSlots (khung giờ hoạt động)
INSERT INTO TimeSlots(StartTime, EndTime, IsPeakHour) VALUES
    ('06:00', '07:00', 0),
    ('07:00', '08:00', 0),
    ('08:00', '09:00', 0),
    ('09:00', '10:00', 0),
    ('10:00', '11:00', 0),
    ('11:00', '12:00', 0),
    ('13:00', '14:00', 0),
    ('14:00', '15:00', 0),
    ('15:00', '16:00', 0),
    ('16:00', '17:00', 0),
    ('17:00', '18:00', 1),
    ('18:00', '19:00', 1),
    ('19:00', '20:00', 1),
    ('20:00', '21:00', 1),
    ('21:00', '22:00', 1);
GO

-- Seed sân mẫu
INSERT INTO Fields(Name, Description, BasePrice, PeakPrice, TypeId, StatusId) VALUES
    (N'Sân A1', N'Sân cỏ nhân tạo 5 người, có mái che, đèn LED',    200000, 300000, 1, 1),
    (N'Sân A2', N'Sân cỏ nhân tạo 5 người, ngoài trời',             180000, 270000, 1, 1),
    (N'Sân A3', N'Sân cỏ nhân tạo 5 người, có mái che',             200000, 300000, 1, 1),
    (N'Sân B1', N'Sân cỏ nhân tạo 7 người, có đèn chiếu sáng',     350000, 500000, 2, 1),
    (N'Sân B2', N'Sân cỏ nhân tạo 7 người, có mái che, đèn LED',   380000, 550000, 2, 1);
GO


/* ================================================================
   [5] BOOKINGS & PAYMENTS — CORE
================================================================ */

CREATE TABLE Bookings (
    BookingId      INT IDENTITY PRIMARY KEY,
    UserId         INT NOT NULL,
    StatusId       INT NOT NULL DEFAULT 1,
    SubTotal       DECIMAL(12,2) NULL,           -- Tổng trước giảm giá
    DiscountAmount DECIMAL(12,2) DEFAULT 0,      -- Số tiền được giảm
    TotalAmount    DECIMAL(12,2) NULL,           -- SubTotal - DiscountAmount
    PromotionId    INT NULL,                     -- Voucher áp dụng (nếu có)
    Note           NVARCHAR(500),
    CancelReason   NVARCHAR(500),                -- Lý do hủy
    CreatedAt      DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt      DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Bookings_SubTotal       CHECK (SubTotal IS NULL OR SubTotal >= 0),
    CONSTRAINT CK_Bookings_DiscountAmount CHECK (DiscountAmount >= 0),
    CONSTRAINT CK_Bookings_TotalAmount    CHECK (TotalAmount IS NULL OR TotalAmount >= 0),
    FOREIGN KEY(UserId)      REFERENCES Users(UserId),
    FOREIGN KEY(StatusId)    REFERENCES BookingStatuses(StatusId)
    -- FK PromotionId thêm sau khi tạo bảng Promotions
);
GO

CREATE TABLE BookingDetails (
    BookingDetailId INT IDENTITY PRIMARY KEY,
    BookingId       INT NOT NULL,
    FieldSlotId     INT NOT NULL,
    Price           DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_BookingDetails_Price CHECK (Price > 0),
    FOREIGN KEY(BookingId)   REFERENCES Bookings(BookingId),
    FOREIGN KEY(FieldSlotId) REFERENCES FieldSlots(FieldSlotId),
    CONSTRAINT UQ_BookingDetail_Slot UNIQUE(FieldSlotId)  -- 1 slot chỉ thuộc 1 booking
);
GO

CREATE TABLE Payments (
    PaymentId       INT IDENTITY PRIMARY KEY,
    BookingId       INT NOT NULL,
    Amount          DECIMAL(12,2) NOT NULL,
    StatusId        INT NOT NULL DEFAULT 1,
    MethodId        INT NOT NULL,                 -- FK → PaymentMethods
    TransactionCode NVARCHAR(100),               -- Mã GD từ cổng thanh toán
    GatewayResponse NVARCHAR(MAX),               -- Raw response từ VNPay/MoMo
    Note            NVARCHAR(255),
    PaidAt          DATETIME2 NULL,              -- Thời điểm thanh toán thành công
    CreatedAt       DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(StatusId)  REFERENCES PaymentStatuses(StatusId),
    FOREIGN KEY(MethodId)  REFERENCES PaymentMethods(MethodId)
);
GO

CREATE INDEX IX_Bookings_UserId         ON Bookings(UserId);
CREATE INDEX IX_Bookings_StatusCreated  ON Bookings(StatusId, CreatedAt);
CREATE INDEX IX_BookingDetails_Booking  ON BookingDetails(BookingId);
CREATE INDEX IX_Payments_BookingId      ON Payments(BookingId);
CREATE INDEX IX_Payments_TxCode         ON Payments(TransactionCode) WHERE TransactionCode IS NOT NULL;
GO


/* ================================================================
   [6] SERVICES (Dịch vụ đi kèm: nước, áo, bóng...)
================================================================ */

CREATE TABLE Services (
    ServiceId   INT IDENTITY PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Price       DECIMAL(12,2) NOT NULL,
    ImageUrl    NVARCHAR(500),
    IsAvailable BIT DEFAULT 1,
    IsDeleted   BIT DEFAULT 0,
    UpdatedAt   DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Services_Price CHECK (Price > 0)
);
GO

CREATE TABLE BookingServices (
    BookingServiceId INT IDENTITY PRIMARY KEY,
    BookingId        INT NOT NULL,
    ServiceId        INT NOT NULL,
    Quantity         INT           NOT NULL DEFAULT 1,
    UnitPrice        DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_BookingServices_Qty       CHECK (Quantity >= 1),
    CONSTRAINT CK_BookingServices_UnitPrice CHECK (UnitPrice > 0),
    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(ServiceId) REFERENCES Services(ServiceId),
    CONSTRAINT UQ_BookingService UNIQUE(BookingId, ServiceId)
);
GO

CREATE INDEX IX_BookingServices_Booking ON BookingServices(BookingId);
GO

-- Seed dịch vụ mẫu
INSERT INTO Services(Name, Description, Price) VALUES
    (N'Thuê bóng',      N'Bóng đá tiêu chuẩn size 5',       30000),
    (N'Thuê áo',        N'Bộ áo thi đấu theo set 10 cái',   150000),
    (N'Nước uống',      N'Thùng 24 chai 500ml',              120000),
    (N'Thuê giày',      N'Giày đá bóng các cỡ',             50000),
    (N'Bảo vệ trọng tài', N'Trọng tài cho trận giao hữu',  200000);
GO


/* ================================================================
   [7] PROMOTIONS & VOUCHERS
   Bổ sung mới — hội đồng thường hỏi phần này.
================================================================ */

CREATE TABLE Promotions (
    PromotionId     INT IDENTITY PRIMARY KEY,
    Code            NVARCHAR(50) NOT NULL,        -- Mã voucher khách nhập
    Name            NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(500),
    TypeId          INT NOT NULL,                 -- Phần trăm(1) | Số tiền cố định(2)
    DiscountValue   DECIMAL(12,2) NOT NULL,       -- % hoặc số tiền
    MaxDiscount     DECIMAL(12,2) NULL,           -- Giảm tối đa (cho loại %)
    MinOrderAmount  DECIMAL(12,2) DEFAULT 0,      -- Đơn hàng tối thiểu để áp dụng
    UsageLimit      INT DEFAULT 1,                -- Tổng số lượt dùng tối đa
    UsageCount      INT DEFAULT 0,                -- Đã dùng bao nhiêu lượt
    StartDate       DATE NOT NULL,
    EndDate         DATE NOT NULL,
    IsActive        BIT DEFAULT 1,
    CreatedBy       INT NOT NULL,
    CreatedAt       DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_Promotions_Code    UNIQUE(Code),
    CONSTRAINT CK_Promotions_Value   CHECK (DiscountValue > 0),
    CONSTRAINT CK_Promotions_Date    CHECK (EndDate >= StartDate),
    CONSTRAINT CK_Promotions_Usage   CHECK (UsageCount <= UsageLimit),
    FOREIGN KEY(TypeId)    REFERENCES PromotionTypes(TypeId),
    FOREIGN KEY(CreatedBy) REFERENCES Users(UserId)
);
GO

-- Thêm FK PromotionId vào Bookings (đã tạo bảng Promotions rồi)
ALTER TABLE Bookings
ADD CONSTRAINT FK_Bookings_Promotion
    FOREIGN KEY(PromotionId) REFERENCES Promotions(PromotionId);
GO

CREATE INDEX IX_Promotions_Code   ON Promotions(Code) WHERE IsActive = 1;
CREATE INDEX IX_Promotions_Active ON Promotions(IsActive, StartDate, EndDate);
GO


/* ================================================================
   [8] INVENTORY — Kho hàng
================================================================ */

CREATE TABLE Suppliers (
    SupplierId  INT IDENTITY PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    Phone       NVARCHAR(20),
    Email       NVARCHAR(100),
    Address     NVARCHAR(255),
    IsDeleted   BIT DEFAULT 0
);
GO

CREATE TABLE Products (
    ProductId INT IDENTITY PRIMARY KEY,
    Name      NVARCHAR(100) NOT NULL,
    Unit      NVARCHAR(50),
    StockQty  INT DEFAULT 0,
    MinQty    INT DEFAULT 5,             -- Ngưỡng cảnh báo tồn kho thấp
    IsDeleted BIT DEFAULT 0,

    CONSTRAINT CK_Products_StockQty CHECK (StockQty >= 0),
    CONSTRAINT CK_Products_MinQty   CHECK (MinQty >= 0)
);
GO

CREATE TABLE PurchaseOrders (
    PurchaseOrderId INT IDENTITY PRIMARY KEY,
    SupplierId      INT NOT NULL,
    CreatedByUserId INT NOT NULL,
    StatusId        INT NOT NULL DEFAULT 1,
    TotalAmount     DECIMAL(12,2) NULL,  -- Tính tự động khi confirm
    Note            NVARCHAR(500),
    ConfirmedAt     DATETIME2 NULL,
    CreatedAt       DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_PO_TotalAmount CHECK (TotalAmount IS NULL OR TotalAmount > 0),
    FOREIGN KEY(SupplierId)      REFERENCES Suppliers(SupplierId),
    FOREIGN KEY(CreatedByUserId) REFERENCES Users(UserId),
    FOREIGN KEY(StatusId)        REFERENCES PurchaseOrderStatuses(StatusId)
);
GO

CREATE TABLE PurchaseOrderDetails (
    PurchaseOrderDetailId INT IDENTITY PRIMARY KEY,
    PurchaseOrderId       INT NOT NULL,
    ProductId             INT NOT NULL,
    Quantity              INT           NOT NULL,
    UnitPrice             DECIMAL(12,2) NOT NULL,

    CONSTRAINT CK_POD_Qty      CHECK (Quantity >= 1),
    CONSTRAINT CK_POD_UnitPrice CHECK (UnitPrice > 0),
    FOREIGN KEY(PurchaseOrderId) REFERENCES PurchaseOrders(PurchaseOrderId),
    FOREIGN KEY(ProductId)       REFERENCES Products(ProductId),
    CONSTRAINT UQ_POD_Product UNIQUE(PurchaseOrderId, ProductId)
);
GO


/* ================================================================
   [9] INCIDENTS — Sự cố sân
================================================================ */

CREATE TABLE Incidents (
    IncidentId       INT IDENTITY PRIMARY KEY,
    FieldId          INT NOT NULL,
    ReportedByUserId INT NOT NULL,
    Title            NVARCHAR(200) NOT NULL,
    Description      NVARCHAR(1000),
    ImageUrl         NVARCHAR(500),
    StatusId         INT NOT NULL DEFAULT 1,
    HandledByUserId  INT NULL,
    HandledAt        DATETIME2 NULL,
    HandledNote      NVARCHAR(500),
    CreatedAt        DATETIME2 DEFAULT SYSDATETIME(),

    FOREIGN KEY(FieldId)          REFERENCES Fields(FieldId),
    FOREIGN KEY(ReportedByUserId) REFERENCES Users(UserId),
    FOREIGN KEY(HandledByUserId)  REFERENCES Users(UserId),
    FOREIGN KEY(StatusId)         REFERENCES IncidentStatuses(StatusId)
);
GO

CREATE INDEX IX_Incidents_Field  ON Incidents(FieldId, StatusId);
CREATE INDEX IX_Incidents_Status ON Incidents(StatusId, CreatedAt);
GO


/* ================================================================
   [10] NOTIFICATIONS
================================================================ */

CREATE TABLE Notifications (
    NotificationId INT IDENTITY PRIMARY KEY,
    UserId         INT NOT NULL,
    Title          NVARCHAR(200) NOT NULL,
    Body           NVARCHAR(1000),
    Type           NVARCHAR(50),       -- BOOKING_CONFIRM | BOOKING_CANCEL | PAYMENT | ...
    RefId          INT NULL,           -- BookingId hoặc IncidentId liên quan
    IsRead         BIT DEFAULT 0,
    CreatedAt      DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY(UserId) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_Notifications_Unread ON Notifications(UserId, IsRead, CreatedAt DESC);
GO


/* ================================================================
   [11] AUDIT LOG
   Ghi lại mọi thay đổi quan trọng — bắt buộc cho khóa luận.
================================================================ */

CREATE TABLE AuditLogs (
    AuditLogId BIGINT IDENTITY PRIMARY KEY,
    UserId     INT NULL,                  -- NULL = hệ thống tự động
    Action     NVARCHAR(100) NOT NULL,    -- BOOKING_CANCEL | SLOT_HOLD | ...
    TableName  NVARCHAR(100) NOT NULL,
    RecordId   INT NOT NULL,
    OldValue   NVARCHAR(MAX) NULL,        -- JSON snapshot trước
    NewValue   NVARCHAR(MAX) NULL,        -- JSON snapshot sau
    IpAddress  NVARCHAR(50) NULL,
    CreatedAt  DATETIME2 DEFAULT SYSDATETIME()
);
GO

CREATE INDEX IX_AuditLogs_Record ON AuditLogs(TableName, RecordId);
CREATE INDEX IX_AuditLogs_User   ON AuditLogs(UserId, CreatedAt);
GO


/* ================================================================
   [12] STORED PROCEDURES
================================================================ */

/* ----------------------------------------------------------------
   SP-1: Sinh ô giờ (FieldSlots) cho tất cả sân đang hoạt động
   Gọi: EXEC sp_GenerateSlots '2026-06-01', '2026-06-30'
   Logic: Giá lấy từ Fields.PeakPrice / BasePrice theo IsPeakHour
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_GenerateSlots
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate > @EndDate
    BEGIN
        THROW 50010, N'StartDate phải nhỏ hơn hoặc bằng EndDate.', 1;
        RETURN;
    END

    DECLARE @Date DATE = @StartDate;
    WHILE @Date <= @EndDate
    BEGIN
        INSERT INTO FieldSlots(FieldId, SlotId, SlotDate, Price)
        SELECT
            f.FieldId,
            ts.SlotId,
            @Date,
            CASE WHEN ts.IsPeakHour = 1 THEN f.PeakPrice ELSE f.BasePrice END
        FROM Fields f
        CROSS JOIN TimeSlots ts
        WHERE f.IsDeleted = 0
          AND f.StatusId  = 1
          AND NOT EXISTS (
              SELECT 1 FROM FieldSlots fs
              WHERE fs.FieldId  = f.FieldId
                AND fs.SlotId   = ts.SlotId
                AND fs.SlotDate = @Date
          );

        SET @Date = DATEADD(DAY, 1, @Date);
    END
END
GO

/* ----------------------------------------------------------------
   SP-2: Giữ slot (Hold 10 phút, dùng lock để chống double-booking)
   Gọi: EXEC sp_HoldSlots '1,2,3', @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_HoldSlots
    @FieldSlotIds NVARCHAR(MAX),
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    -- Parse danh sách ID
    CREATE TABLE #Requested(Id INT);
    INSERT INTO #Requested(Id)
    SELECT CAST(TRIM(value) AS INT)
    FROM STRING_SPLIT(@FieldSlotIds, ',')
    WHERE TRIM(value) != '';

    DECLARE @RequestCount INT = (SELECT COUNT(*) FROM #Requested);

    -- Lock + cập nhật các slot còn Trống
    UPDATE fs
    SET StatusId     = 2,
        HoldExpireAt = DATEADD(MINUTE, 10, SYSDATETIME()),
        UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs WITH (UPDLOCK, HOLDLOCK)
    JOIN #Requested r ON fs.FieldSlotId = r.Id
    WHERE fs.StatusId = 1;

    IF @@ROWCOUNT < @RequestCount
    BEGIN
        ROLLBACK;
        THROW 50001, N'Một hoặc nhiều slot không còn khả dụng. Vui lòng chọn lại.', 1;
    END

    -- Audit log
    IF @UserId IS NOT NULL
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        SELECT @UserId, N'SLOT_HOLD', N'FieldSlots', Id,
               N'{"StatusId":2,"holdMinutes":10}'
        FROM #Requested;

    COMMIT;
END
GO

/* ----------------------------------------------------------------
   SP-3: Xác nhận booking sau thanh toán thành công
   Gọi: EXEC sp_ConfirmBooking @BookingId=1, @FieldSlotIds='1,2', @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ConfirmBooking
    @BookingId    INT,
    @FieldSlotIds NVARCHAR(MAX),
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    CREATE TABLE #SlotIds(Id INT);
    INSERT INTO #SlotIds(Id)
    SELECT CAST(TRIM(value) AS INT)
    FROM STRING_SPLIT(@FieldSlotIds, ',')
    WHERE TRIM(value) != '';

    DECLARE @Count INT = (SELECT COUNT(*) FROM #SlotIds);

    -- Chuyển slot từ Đang giữ → Đã đặt (chỉ khi hold chưa hết hạn)
    UPDATE fs
    SET StatusId     = 3,
        HoldExpireAt = NULL,
        UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs
    JOIN #SlotIds t ON fs.FieldSlotId = t.Id
    WHERE fs.StatusId    = 2
      AND fs.HoldExpireAt >= SYSDATETIME();

    IF @@ROWCOUNT < @Count
    BEGIN
        ROLLBACK;
        THROW 50002, N'Phiên giữ chỗ đã hết hạn. Vui lòng đặt lại.', 1;
    END

    -- Ghi BookingDetails
    INSERT INTO BookingDetails(BookingId, FieldSlotId, Price)
    SELECT @BookingId, fs.FieldSlotId, fs.Price
    FROM FieldSlots fs
    JOIN #SlotIds t ON fs.FieldSlotId = t.Id;

    -- Tính SubTotal, TotalAmount (sau khi trừ discount đã được set vào Bookings)
    UPDATE Bookings
    SET SubTotal    = (
            SELECT ISNULL(SUM(bd.Price),0)
            FROM BookingDetails bd WHERE bd.BookingId = @BookingId
        ) + (
            SELECT ISNULL(SUM(bs.Quantity * bs.UnitPrice),0)
            FROM BookingServices bs WHERE bs.BookingId = @BookingId
        ),
        TotalAmount = SubTotal - ISNULL(DiscountAmount, 0),
        StatusId    = 2,
        UpdatedAt   = SYSDATETIME()
    WHERE BookingId = @BookingId;

    -- Audit
    IF @UserId IS NOT NULL
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        VALUES(@UserId, N'BOOKING_CONFIRM', N'Bookings', @BookingId, N'{"StatusId":2}');

    COMMIT;
END
GO

/* ----------------------------------------------------------------
   SP-4: Hủy booking
   Xử lý hoàn tiền nếu booking đã được xác nhận (StatusId=2).
   Gọi: EXEC sp_CancelBooking @BookingId=1, @UserId=5, @Reason=N'Bận việc'
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_CancelBooking
    @BookingId INT,
    @UserId    INT = NULL,
    @Reason    NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    DECLARE @CurrentStatus INT;
    SELECT @CurrentStatus = StatusId FROM Bookings WHERE BookingId = @BookingId;

    IF @CurrentStatus NOT IN (1, 2)  -- Chỉ hủy khi Chờ TT hoặc Đã xác nhận
    BEGIN
        ROLLBACK;
        THROW 50003, N'Booking không thể hủy ở trạng thái hiện tại.', 1;
    END

    -- Trả slot về Trống (cả slot đang giữ lẫn đã đặt)
    UPDATE fs
    SET StatusId     = 1,
        HoldExpireAt = NULL,
        UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs
    JOIN BookingDetails bd ON fs.FieldSlotId = bd.FieldSlotId
    WHERE bd.BookingId   = @BookingId
      AND fs.StatusId   IN (2, 3);

    -- Cập nhật Booking
    UPDATE Bookings
    SET StatusId     = 3,
        CancelReason = @Reason,
        UpdatedAt    = SYSDATETIME()
    WHERE BookingId = @BookingId;

    -- Nếu đã thanh toán (StatusId=2) → tạo payment hoàn tiền
    IF @CurrentStatus = 2
    BEGIN
        DECLARE @PaidAmount DECIMAL(12,2);
        SELECT TOP 1 @PaidAmount = Amount
        FROM Payments
        WHERE BookingId = @BookingId AND StatusId = 2
        ORDER BY CreatedAt DESC;

        IF @PaidAmount IS NOT NULL
        BEGIN
            -- Lấy MethodId của payment gốc
            DECLARE @MethodId INT;
            SELECT TOP 1 @MethodId = MethodId
            FROM Payments
            WHERE BookingId = @BookingId AND StatusId = 2
            ORDER BY CreatedAt DESC;

            INSERT INTO Payments(BookingId, Amount, StatusId, MethodId, Note, PaidAt)
            VALUES(@BookingId, @PaidAmount, 4, @MethodId,
                   N'Hoàn tiền do hủy booking', SYSDATETIME());
        END
    END

    -- Audit
    IF @UserId IS NOT NULL
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        VALUES(@UserId, N'BOOKING_CANCEL', N'Bookings', @BookingId,
               CONCAT(N'{"StatusId":3,"reason":"', ISNULL(@Reason,''), N'"}'));

    COMMIT;
END
GO

/* ----------------------------------------------------------------
   SP-5: Giải phóng slot hết hạn hold (chạy mỗi 1 phút qua Agent Job)
   Dùng OUTPUT để capture chính xác slot/booking bị ảnh hưởng.
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ReleaseExpiredSlots
AS
BEGIN
    SET NOCOUNT ON;

    -- Bước 1: Giải phóng slot hết hạn, dùng OUTPUT để ghi audit chính xác
    CREATE TABLE #ReleasedSlots(FieldSlotId INT);

    UPDATE FieldSlots
    SET StatusId     = 1,
        HoldExpireAt = NULL,
        UpdatedAt    = SYSDATETIME()
    OUTPUT inserted.FieldSlotId INTO #ReleasedSlots
    WHERE StatusId    = 2
      AND HoldExpireAt < SYSDATETIME();

    IF EXISTS(SELECT 1 FROM #ReleasedSlots)
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        SELECT NULL, N'SLOT_RELEASE_AUTO', N'FieldSlots', FieldSlotId,
               N'{"StatusId":1,"reason":"hold_expired"}'
        FROM #ReleasedSlots;

    -- Bước 2: Hủy booking Chờ thanh toán > 15 phút không còn slot giữ nào
    CREATE TABLE #CancelledBookings(BookingId INT);

    UPDATE b
    SET b.StatusId  = 3,
        b.UpdatedAt = SYSDATETIME(),
        b.CancelReason = N'Hết thời gian giữ chỗ, tự động hủy'
    OUTPUT inserted.BookingId INTO #CancelledBookings
    FROM Bookings b
    WHERE b.StatusId = 1
      AND b.CreatedAt < DATEADD(MINUTE, -15, SYSDATETIME())
      AND NOT EXISTS (
          SELECT 1
          FROM BookingDetails bd
          JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
          WHERE bd.BookingId = b.BookingId
            AND fs.StatusId  = 2
            AND fs.HoldExpireAt >= SYSDATETIME()
      );

    IF EXISTS(SELECT 1 FROM #CancelledBookings)
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        SELECT NULL, N'BOOKING_CANCEL_AUTO', N'Bookings', BookingId,
               N'{"StatusId":3,"reason":"payment_timeout"}'
        FROM #CancelledBookings;
END
GO

/* ----------------------------------------------------------------
   SP-6: Áp dụng voucher vào booking
   Gọi: EXEC sp_ApplyPromotion @BookingId=1, @Code=N'SUMMER20', @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ApplyPromotion
    @BookingId INT,
    @Code      NVARCHAR(50),
    @UserId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    -- Kiểm tra booking hợp lệ
    DECLARE @CurrentSubTotal DECIMAL(12,2);
    SELECT @CurrentSubTotal = SubTotal
    FROM Bookings
    WHERE BookingId = @BookingId AND StatusId = 1;

    IF @CurrentSubTotal IS NULL
    BEGIN
        ROLLBACK;
        THROW 50020, N'Booking không tồn tại hoặc không thể áp voucher.', 1;
    END

    -- Kiểm tra voucher
    DECLARE @PromotionId    INT;
    DECLARE @TypeId         INT;
    DECLARE @DiscountValue  DECIMAL(12,2);
    DECLARE @MaxDiscount    DECIMAL(12,2);
    DECLARE @MinOrder       DECIMAL(12,2);

    SELECT
        @PromotionId   = PromotionId,
        @TypeId        = TypeId,
        @DiscountValue = DiscountValue,
        @MaxDiscount   = MaxDiscount,
        @MinOrder      = MinOrderAmount
    FROM Promotions
    WHERE Code     = @Code
      AND IsActive = 1
      AND CAST(SYSDATETIME() AS DATE) BETWEEN StartDate AND EndDate
      AND UsageCount < UsageLimit;

    IF @PromotionId IS NULL
    BEGIN
        ROLLBACK;
        THROW 50021, N'Mã voucher không hợp lệ, đã hết hạn hoặc đã dùng hết.', 1;
    END

    IF @CurrentSubTotal < @MinOrder
    BEGIN
        ROLLBACK;
        THROW 50022, N'Giá trị đơn hàng chưa đạt mức tối thiểu để dùng voucher.', 1;
    END

    -- Tính giảm giá
    DECLARE @DiscountAmount DECIMAL(12,2);
    IF @TypeId = 1  -- Phần trăm
        SET @DiscountAmount = @CurrentSubTotal * @DiscountValue / 100;
    ELSE            -- Số tiền cố định
        SET @DiscountAmount = @DiscountValue;

    -- Áp MaxDiscount nếu có
    IF @MaxDiscount IS NOT NULL AND @DiscountAmount > @MaxDiscount
        SET @DiscountAmount = @MaxDiscount;

    -- Cập nhật Booking
    UPDATE Bookings
    SET PromotionId    = @PromotionId,
        DiscountAmount = @DiscountAmount,
        TotalAmount    = SubTotal - @DiscountAmount,
        UpdatedAt      = SYSDATETIME()
    WHERE BookingId = @BookingId;

    -- Tăng UsageCount
    UPDATE Promotions SET UsageCount = UsageCount + 1
    WHERE PromotionId = @PromotionId;

    COMMIT;
END
GO

/* ----------------------------------------------------------------
   SP-7: Xác nhận đơn nhập kho → cộng tồn kho
   Gọi: EXEC sp_ConfirmPurchaseOrder @PurchaseOrderId=1, @UserId=1
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ConfirmPurchaseOrder
    @PurchaseOrderId INT,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    IF NOT EXISTS (
        SELECT 1 FROM PurchaseOrders
        WHERE PurchaseOrderId = @PurchaseOrderId AND StatusId = 1
    )
    BEGIN
        ROLLBACK;
        THROW 50030, N'Đơn nhập kho không hợp lệ hoặc đã xử lý.', 1;
    END

    -- Cộng tồn kho
    UPDATE p
    SET p.StockQty = p.StockQty + pod.Quantity
    FROM Products p
    JOIN PurchaseOrderDetails pod ON p.ProductId = pod.ProductId
    WHERE pod.PurchaseOrderId = @PurchaseOrderId;

    -- Tính TotalAmount và cập nhật trạng thái
    UPDATE PurchaseOrders
    SET StatusId    = 2,
        TotalAmount = (
            SELECT SUM(pod.Quantity * pod.UnitPrice)
            FROM PurchaseOrderDetails pod
            WHERE pod.PurchaseOrderId = @PurchaseOrderId
        ),
        ConfirmedAt = SYSDATETIME()
    WHERE PurchaseOrderId = @PurchaseOrderId;

    IF @UserId IS NOT NULL
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        VALUES(@UserId, N'PURCHASE_CONFIRM', N'PurchaseOrders',
               @PurchaseOrderId, N'{"StatusId":2}');

    COMMIT;
END
GO

/* ----------------------------------------------------------------
   SP-8: Đổi lịch (reschedule) — đổi 1 slot sang slot khác
   Gọi: EXEC sp_RescheduleBooking
            @BookingDetailId=1, @NewFieldSlotId=50, @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_RescheduleBooking
    @BookingDetailId INT,
    @NewFieldSlotId  INT,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    -- Lấy thông tin slot cũ
    DECLARE @BookingId      INT;
    DECLARE @OldFieldSlotId INT;
    DECLARE @OldPrice       DECIMAL(12,2);

    SELECT @BookingId = bd.BookingId,
           @OldFieldSlotId = bd.FieldSlotId,
           @OldPrice = bd.Price
    FROM BookingDetails bd
    JOIN Bookings b ON bd.BookingId = b.BookingId
    WHERE bd.BookingDetailId = @BookingDetailId
      AND b.StatusId = 2;  -- Chỉ đổi booking đã xác nhận

    IF @BookingId IS NULL
    BEGIN
        ROLLBACK;
        THROW 50040, N'Booking detail không hợp lệ hoặc booking chưa được xác nhận.', 1;
    END

    -- Kiểm tra slot mới còn trống
    DECLARE @NewPrice DECIMAL(12,2);
    SELECT @NewPrice = Price
    FROM FieldSlots
    WHERE FieldSlotId = @NewFieldSlotId AND StatusId = 1;

    IF @NewPrice IS NULL
    BEGIN
        ROLLBACK;
        THROW 50041, N'Slot mới không tồn tại hoặc không còn trống.', 1;
    END

    -- Trả slot cũ về Trống
    UPDATE FieldSlots
    SET StatusId = 1, HoldExpireAt = NULL, UpdatedAt = SYSDATETIME()
    WHERE FieldSlotId = @OldFieldSlotId;

    -- Đặt slot mới thành Đã đặt
    UPDATE FieldSlots
    SET StatusId = 3, UpdatedAt = SYSDATETIME()
    WHERE FieldSlotId = @NewFieldSlotId AND StatusId = 1;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK;
        THROW 50042, N'Slot mới vừa bị đặt bởi người khác. Vui lòng chọn lại.', 1;
    END

    -- Cập nhật BookingDetail
    UPDATE BookingDetails
    SET FieldSlotId = @NewFieldSlotId,
        Price       = @NewPrice
    WHERE BookingDetailId = @BookingDetailId;

    -- Tính lại TotalAmount
    DECLARE @PriceDiff DECIMAL(12,2) = @NewPrice - @OldPrice;
    UPDATE Bookings
    SET SubTotal    = SubTotal + @PriceDiff,
        TotalAmount = TotalAmount + @PriceDiff,
        UpdatedAt   = SYSDATETIME()
    WHERE BookingId = @BookingId;

    -- Audit
    IF @UserId IS NOT NULL
        INSERT INTO AuditLogs(UserId, Action, TableName, RecordId, NewValue)
        VALUES(@UserId, N'BOOKING_RESCHEDULE', N'BookingDetails', @BookingDetailId,
               CONCAT(N'{"oldSlot":', @OldFieldSlotId,
                      N',"newSlot":', @NewFieldSlotId, N'}'));

    COMMIT;
END
GO


/* ================================================================
   [13] VIEWS
================================================================ */

/* ----------------------------------------------------------------
   VIEW-1: Lịch sân theo ngày — dùng cho trang đặt sân
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_FieldSchedule AS
SELECT
    fs.FieldSlotId,
    f.FieldId,
    f.Name          AS FieldName,
    f.ImageUrl      AS FieldImageUrl,
    ft.Name         AS FieldType,
    ts.SlotId,
    ts.StartTime,
    ts.EndTime,
    ts.IsPeakHour,
    fs.SlotDate,
    fs.Price,
    fss.Name        AS SlotStatus,
    fs.StatusId     AS SlotStatusId,
    fs.HoldExpireAt
FROM FieldSlots fs
JOIN Fields            f   ON fs.FieldId  = f.FieldId
JOIN TimeSlots         ts  ON fs.SlotId   = ts.SlotId
JOIN FieldTypes        ft  ON f.TypeId    = ft.TypeId
JOIN FieldSlotStatuses fss ON fs.StatusId = fss.StatusId
WHERE f.IsDeleted = 0;
GO

/* ----------------------------------------------------------------
   VIEW-2: Lịch sử đặt sân — dùng cho trang quản lý booking
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_BookingHistory AS
SELECT
    b.BookingId,
    b.UserId,
    u.FullName       AS CustomerName,
    u.Phone          AS CustomerPhone,
    u.Email          AS CustomerEmail,
    bs.Name          AS BookingStatus,
    b.StatusId       AS BookingStatusId,
    b.SubTotal,
    b.DiscountAmount,
    b.TotalAmount,
    p.Code           AS PromotionCode,
    b.Note,
    b.CancelReason,
    b.CreatedAt      AS BookingDate,
    b.UpdatedAt,
    -- Chi tiết slot
    bd.BookingDetailId,
    f.FieldId,
    f.Name           AS FieldName,
    ft.Name          AS FieldType,
    ts.StartTime,
    ts.EndTime,
    fs.SlotDate,
    bd.Price         AS SlotPrice,
    -- Thanh toán
    pay.Amount       AS PaidAmount,
    pay.PaidAt,
    pm.Name          AS PaymentMethod,
    ps.Name          AS PaymentStatus
FROM Bookings b
JOIN Users              u   ON b.UserId       = u.UserId
JOIN BookingStatuses    bs  ON b.StatusId      = bs.StatusId
JOIN BookingDetails     bd  ON b.BookingId     = bd.BookingId
JOIN FieldSlots         fs  ON bd.FieldSlotId  = fs.FieldSlotId
JOIN Fields             f   ON fs.FieldId      = f.FieldId
JOIN FieldTypes         ft  ON f.TypeId        = ft.TypeId
JOIN TimeSlots          ts  ON fs.SlotId       = ts.SlotId
LEFT JOIN Promotions    p   ON b.PromotionId   = p.PromotionId
LEFT JOIN (
    SELECT BookingId, Amount, PaidAt, MethodId, StatusId,
           ROW_NUMBER() OVER (PARTITION BY BookingId ORDER BY CreatedAt DESC) AS rn
    FROM Payments WHERE StatusId = 2
) pay ON b.BookingId = pay.BookingId AND pay.rn = 1
LEFT JOIN PaymentMethods  pm ON pay.MethodId  = pm.MethodId
LEFT JOIN PaymentStatuses ps ON pay.StatusId  = ps.StatusId;
GO

/* ----------------------------------------------------------------
   VIEW-3: Doanh thu theo tháng
   Lấy payment thành công mới nhất để tránh đếm trùng.
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_RevenueByMonth AS
SELECT
    YEAR(b.CreatedAt)           AS [Year],
    MONTH(b.CreatedAt)          AS [Month],
    COUNT(DISTINCT b.BookingId) AS TotalBookings,
    SUM(pay.Amount)             AS TotalRevenue,
    AVG(pay.Amount)             AS AvgBookingValue
FROM Bookings b
JOIN (
    SELECT BookingId, Amount,
           ROW_NUMBER() OVER (PARTITION BY BookingId ORDER BY CreatedAt DESC) AS rn
    FROM Payments WHERE StatusId = 2
) pay ON b.BookingId = pay.BookingId AND pay.rn = 1
WHERE b.StatusId = 2
GROUP BY YEAR(b.CreatedAt), MONTH(b.CreatedAt);
GO

/* ----------------------------------------------------------------
   VIEW-4: Tỷ lệ lấp đầy theo sân và tháng
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_FieldOccupancyByMonth AS
SELECT
    f.FieldId,
    f.Name                       AS FieldName,
    ft.Name                      AS FieldType,
    YEAR(fs.SlotDate)            AS [Year],
    MONTH(fs.SlotDate)           AS [Month],
    COUNT(*)                     AS TotalSlots,
    SUM(CASE WHEN fs.StatusId = 3 THEN 1 ELSE 0 END) AS BookedSlots,
    CAST(
        SUM(CASE WHEN fs.StatusId = 3 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(5,2))             AS OccupancyRate
FROM FieldSlots fs
JOIN Fields     f  ON fs.FieldId = f.FieldId
JOIN FieldTypes ft ON f.TypeId   = ft.TypeId
WHERE f.IsDeleted = 0
GROUP BY f.FieldId, f.Name, ft.Name, YEAR(fs.SlotDate), MONTH(fs.SlotDate);
GO

/* ----------------------------------------------------------------
   VIEW-5: Doanh thu theo dịch vụ — dùng cho báo cáo admin
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_RevenueByService AS
SELECT
    s.ServiceId,
    s.Name                              AS ServiceName,
    SUM(bs.Quantity)                    AS TotalQuantitySold,
    SUM(bs.Quantity * bs.UnitPrice)     AS TotalRevenue,
    COUNT(DISTINCT bs.BookingId)        AS TotalBookings
FROM BookingServices bs
JOIN Services  s ON bs.ServiceId = s.ServiceId
JOIN Bookings  b ON bs.BookingId = b.BookingId
WHERE b.StatusId = 2  -- Chỉ tính booking đã xác nhận
GROUP BY s.ServiceId, s.Name;
GO

/* ----------------------------------------------------------------
   VIEW-6: Sản phẩm sắp hết hàng
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_LowStockProducts AS
SELECT
    p.ProductId,
    p.Name,
    p.Unit,
    p.StockQty,
    p.MinQty,
    p.StockQty - p.MinQty AS StockBuffer
FROM Products p
WHERE p.IsDeleted = 0
  AND p.StockQty <= p.MinQty;
GO

/* ----------------------------------------------------------------
   VIEW-7: Dashboard tổng quan — 1 query cho trang chủ admin
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_DashboardSummary AS
SELECT
    (SELECT COUNT(*) FROM Bookings WHERE StatusId = 1)                AS PendingBookings,
    (SELECT COUNT(*) FROM Bookings WHERE StatusId = 2
         AND CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE))       AS TodayConfirmed,
    (SELECT COUNT(*) FROM Fields WHERE StatusId = 1 AND IsDeleted = 0) AS ActiveFields,
    (SELECT COUNT(*) FROM Fields WHERE StatusId = 2 AND IsDeleted = 0) AS MaintenanceFields,
    (SELECT COUNT(*) FROM Incidents WHERE StatusId = 1)               AS NewIncidents,
    (SELECT ISNULL(SUM(Amount),0) FROM Payments
         WHERE StatusId = 2
           AND CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE))     AS TodayRevenue,
    (SELECT COUNT(*) FROM Users WHERE RoleId = 3 AND StatusId = 1)    AS ActiveCustomers,
    (SELECT COUNT(*) FROM vw_LowStockProducts)                        AS LowStockCount;
GO


/* ================================================================
   [14] SEED DATA MẪU
   Sinh slot cho 30 ngày tới
================================================================ */
DECLARE @Today   DATE = CAST(GETDATE() AS DATE);
DECLARE @EndDate DATE = DATEADD(DAY, 29, @Today);
EXEC sp_GenerateSlots @StartDate = @Today, @EndDate = @EndDate;
GO

-- Seed voucher mẫu
INSERT INTO Promotions(Code, Name, TypeId, DiscountValue, MaxDiscount,
                       MinOrderAmount, UsageLimit, StartDate, EndDate, CreatedBy)
VALUES
    (N'KHAIMEN10',  N'Giảm 10% khai trương',    1, 10,  50000, 100000, 100,
     CAST(GETDATE() AS DATE), DATEADD(MONTH, 1, CAST(GETDATE() AS DATE)), 1),
    (N'GIAMMANH50K', N'Giảm 50.000đ đơn từ 200k', 2, 50000, NULL, 200000, 50,
     CAST(GETDATE() AS DATE), DATEADD(MONTH, 1, CAST(GETDATE() AS DATE)), 1);
GO


/* ================================================================
   [15] SQL SERVER AGENT JOBS

   Copy từng block dưới đây vào SSMS và chạy:

   -- JOB 1: Giải phóng slot hết hạn (mỗi 1 phút)
   EXEC msdb.dbo.sp_add_job        @job_name = N'SportPlus - Release Expired Slots';
   EXEC msdb.dbo.sp_add_jobstep    @job_name = N'SportPlus - Release Expired Slots',
                                   @step_name = N'Run', @database_name = N'SportPlusDB',
                                   @command   = N'EXEC sp_ReleaseExpiredSlots';
   EXEC msdb.dbo.sp_add_schedule   @schedule_name = N'Every1Min',
                                   @freq_type = 4, @freq_interval = 1,
                                   @freq_subday_type = 4, @freq_subday_interval = 1;
   EXEC msdb.dbo.sp_attach_schedule @job_name = N'SportPlus - Release Expired Slots',
                                    @schedule_name = N'Every1Min';
   EXEC msdb.dbo.sp_add_jobserver   @job_name = N'SportPlus - Release Expired Slots';

   -- JOB 2: Sinh slot 30 ngày tới (chạy lúc 00:01 mỗi ngày)
   EXEC msdb.dbo.sp_add_job        @job_name = N'SportPlus - Generate Daily Slots';
   EXEC msdb.dbo.sp_add_jobstep    @job_name = N'SportPlus - Generate Daily Slots',
                                   @step_name = N'Run', @database_name = N'SportPlusDB',
                                   @command   = N'
                                       DECLARE @S DATE = DATEADD(DAY,29,CAST(GETDATE()AS DATE));
                                       EXEC sp_GenerateSlots @StartDate=@S, @EndDate=@S;';
   EXEC msdb.dbo.sp_add_schedule   @schedule_name = N'Daily0001',
                                   @freq_type = 4, @freq_interval = 1,
                                   @active_start_time_of_day = 1;
   EXEC msdb.dbo.sp_attach_schedule @job_name = N'SportPlus - Generate Daily Slots',
                                    @schedule_name = N'Daily0001';
   EXEC msdb.dbo.sp_add_jobserver   @job_name = N'SportPlus - Generate Daily Slots';
================================================================ */