/* ================================================================
   SportPlusDB — Hệ thống quản lý sân bóng Sport Plus
   STACK: SQL Server 2019+, Collation: Vietnamese_CI_AS

   MỤC LỤC:
   [1]  DROP & CREATE DATABASE
   [2]  LOOKUP TABLES + SEED
   [3]  SYSTEM CONFIG
   [4]  USERS & AUTH
   [5]  FIELDS (Sân bóng)
   [6]  SPECIAL DAYS & PEAK SCHEDULES
   [7]  BOOKINGS & PAYMENTS
   [8]  DEPOSITS
   [9]  BOOKING LOGS
   [10] SERVICES
   [11] PROMOTIONS & VOUCHERS
   [12] INVENTORY
   [13] INCIDENTS
   [14] REVIEWS
   [15] NOTIFICATIONS
   [16] STORED PROCEDURES
   [17] VIEWS
   [18] SEED DATA MẪU
   [19] SQL AGENT JOBS
================================================================ */


/* ================================================================
   [1] DROP & CREATE DATABASE
================================================================ */
--USE master;
--GO

--IF DB_ID('SportPlusDB') IS NOT NULL
--BEGIN
--    ALTER DATABASE SportPlusDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--    DROP DATABASE SportPlusDB;
--END
--GO

--CREATE DATABASE SportPlusDB COLLATE Vietnamese_CI_AS;
--GO
USE SportPlusDB;
GO
--USE db_ac8bb1_klcn
--GO

/* ================================================================
   [2] LOOKUP TABLES + SEED
================================================================ */

CREATE TABLE Roles (
    RoleId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL   -- Admin | Staff | Customer
);
GO

CREATE TABLE UserStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Hoạt động | Bị khóa
);
GO

CREATE TABLE FieldTypes (
    TypeId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL   -- Sân 5 | Sân 7
);
GO

CREATE TABLE FieldStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Hoạt động | Bảo trì
);
GO

CREATE TABLE FieldSlotStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Trống(1) | Đang giữ(2) | Đã đặt(3)
);
GO

CREATE TABLE BookingStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL
    -- Chờ thanh toán(1) | Đã xác nhận(2) | Đã hủy(3) | Đã hoàn thành(4) | Chờ đặt cọc(5)
);
GO

CREATE TABLE PaymentStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL
    -- Chưa thanh toán(1) | Đã thanh toán(2) | Thất bại(3) | Đã hoàn tiền(4)
);
GO

CREATE TABLE IncidentStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Mới(1) | Đang xử lý(2) | Đã xử lý(3)
);
GO

CREATE TABLE PurchaseOrderStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Chờ xác nhận(1) | Đã nhập(2) | Đã hủy(3)
);
GO

CREATE TABLE PaymentMethods (
    MethodId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL  -- Tiền mặt | Chuyển khoản | VNPay | MoMo
);
GO

CREATE TABLE PromotionTypes (
    TypeId INT IDENTITY PRIMARY KEY,
    Name   NVARCHAR(50) UNIQUE NOT NULL   -- Phần trăm | Số tiền cố định
);
GO

-- Trạng thái đặt cọc
CREATE TABLE DepositStatuses (
    StatusId INT IDENTITY PRIMARY KEY,
    Name     NVARCHAR(50) UNIQUE NOT NULL
    -- Chờ nộp(1) | Đã nộp(2) | Đã hoàn(3) | Đã tịch thu(4)
);
GO

INSERT INTO Roles(Name)              VALUES (N'Admin'), (N'Staff'), (N'Customer');
INSERT INTO UserStatuses(Name)       VALUES (N'Hoạt động'), (N'Bị khóa');
INSERT INTO FieldTypes(Name)         VALUES (N'Sân 5'), (N'Sân 7');
INSERT INTO FieldStatuses(Name)      VALUES (N'Hoạt động'), (N'Bảo trì');
INSERT INTO FieldSlotStatuses(Name)  VALUES (N'Trống'), (N'Đang giữ'), (N'Đã đặt');
INSERT INTO BookingStatuses(Name)    VALUES
    (N'Chờ thanh toán'),   -- 1
    (N'Đã xác nhận'),      -- 2
    (N'Đã hủy'),           -- 3
    (N'Đã hoàn thành'),    -- 4
    (N'Chờ đặt cọc');      -- 5
INSERT INTO PaymentStatuses(Name)    VALUES
    (N'Chưa thanh toán'), (N'Đã thanh toán'), (N'Thất bại'), (N'Đã hoàn tiền');
INSERT INTO IncidentStatuses(Name)   VALUES (N'Mới'), (N'Đang xử lý'), (N'Đã xử lý');
INSERT INTO PurchaseOrderStatuses(Name) VALUES
    (N'Chờ xác nhận'), (N'Đã nhập'), (N'Đã hủy');
INSERT INTO PaymentMethods(Name)     VALUES
    (N'Tiền mặt'), (N'Chuyển khoản'), (N'VNPay'), (N'MoMo');
INSERT INTO PromotionTypes(Name)     VALUES (N'Phần trăm'), (N'Số tiền cố định');
INSERT INTO DepositStatuses(Name)    VALUES
    (N'Chờ nộp'), (N'Đã nộp'), (N'Đã hoàn'), (N'Đã tịch thu');
GO


/* ================================================================
   [3] SYSTEM CONFIG
   Bảng cấu hình toàn hệ thống — thay đổi không cần deploy lại code.
   Dùng sp_UpdateSystemConfig để chỉnh sửa.
================================================================ */

CREATE TABLE SystemConfig (
    ConfigKey   NVARCHAR(100) PRIMARY KEY,
    ConfigValue NVARCHAR(500) NOT NULL,
    DataType    NVARCHAR(20)  NOT NULL DEFAULT 'STRING',
    -- STRING | INT | DECIMAL | BOOLEAN
    Description NVARCHAR(500),
    UpdatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedBy   INT NULL   -- UserId
);
GO

INSERT INTO SystemConfig(ConfigKey, ConfigValue, DataType, Description) VALUES

-- Đặt cọc
('DEPOSIT_REQUIRED_PERCENT',    '20',    'DECIMAL',
 N'% đặt cọc bắt buộc khi thanh toán sau/trực tiếp (0 = không bắt buộc)'),
('DEPOSIT_DEADLINE_HOURS',      '2',     'INT',
 N'Khách phải nộp cọc trong vòng N giờ sau khi đặt slot, nếu không sẽ bị tự hủy'),

-- Ràng buộc đặt sân
('MIN_ADVANCE_BOOKING_HOURS',   '1',     'INT',
 N'Phải đặt sân trước ít nhất N giờ so với giờ thi đấu'),
('MAX_ADVANCE_BOOKING_DAYS',    '30',    'INT',
 N'Chỉ cho đặt sân trong vòng N ngày tới'),
('MAX_SLOTS_PER_BOOKING',       '4',     'INT',
 N'Số slot tối đa trong 1 lần đặt'),
('MAX_ACTIVE_BOOKINGS_PER_USER','3',     'INT',
 N'Số booking Đã xác nhận/Chờ đặt cọc tối đa của 1 user tại cùng thời điểm'),

-- Ràng buộc hủy
('MIN_CANCEL_BEFORE_HOURS',     '2',     'INT',
 N'Không được hủy nếu còn dưới N giờ đến giờ thi đấu'),
('CANCEL_REFUND_POLICY_HOURS',  '24',    'INT',
 N'Hủy trước N giờ được hoàn tiền 100%; hủy sau mất cọc'),

-- Đổi lịch
('RESCHEDULE_FEE_PERCENT',      '0',     'DECIMAL',
 N'Phí đổi lịch tính theo % chênh lệch giá (0 = miễn phí)'),
('MIN_RESCHEDULE_BEFORE_HOURS', '4',     'INT',
 N'Không được đổi lịch nếu còn dưới N giờ đến giờ thi đấu'),
('MAX_RESCHEDULE_PER_BOOKING',  '2',     'INT',
 N'Số lần đổi lịch tối đa cho 1 booking'),

-- Giữ slot
('HOLD_DURATION_MINUTES',       '10',    'INT',
 N'Thời gian giữ slot chờ thanh toán (phút)'),

-- Vận hành
('BOOKING_OPEN_TIME',           '06:00', 'STRING',
 N'Giờ mở cửa nhận đặt sân'),
('BOOKING_CLOSE_TIME',          '22:00', 'STRING',
 N'Giờ đóng cửa nhận đặt sân'),
('TAX_PERCENT',                 '0',     'DECIMAL',
 N'Thuế VAT % áp lên tổng hóa đơn (0 = không tính thuế)');
GO


/* ================================================================
   [4] USERS & AUTH
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

-- FK ngược từ SystemConfig về Users (thêm sau khi có bảng Users)
ALTER TABLE SystemConfig
ADD CONSTRAINT FK_SystemConfig_UpdatedBy
    FOREIGN KEY(UpdatedBy) REFERENCES Users(UserId);
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

INSERT INTO Users(Email, Phone, PasswordHash, FullName, RoleId, StatusId)
VALUES (N'admin@sportplus.vn', N'0900000001',
        N'$2a$12$REPLACE_WITH_REAL_BCRYPT_HASH',
        N'Quản trị viên', 1, 1);
INSERT INTO Profiles(UserId) VALUES (1);
GO


/* ================================================================
   [5] FIELDS (Sân bóng)
================================================================ */

CREATE TABLE Fields (
    FieldId     INT IDENTITY PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    BasePrice   DECIMAL(12,2) NOT NULL,
    PeakPrice   DECIMAL(12,2) NOT NULL,
    ImageUrl    NVARCHAR(500),
    TypeId      INT NOT NULL,
    StatusId    INT NOT NULL DEFAULT 1,
    IsDeleted   BIT DEFAULT 0,
    CreatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt   DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Fields_BasePrice   CHECK (BasePrice > 0),
    CONSTRAINT CK_Fields_PeakPrice   CHECK (PeakPrice > 0),
    CONSTRAINT CK_Fields_PeakGtBase  CHECK (PeakPrice >= BasePrice),
    FOREIGN KEY(TypeId)   REFERENCES FieldTypes(TypeId),
    FOREIGN KEY(StatusId) REFERENCES FieldStatuses(StatusId)
);
GO

-- Khi admin thay đổi BasePrice/PeakPrice → ghi log vào đây
CREATE TABLE FieldPriceHistory (
    HistoryId    INT IDENTITY PRIMARY KEY,
    FieldId      INT NOT NULL,
    OldBasePrice DECIMAL(12,2) NOT NULL,
    OldPeakPrice DECIMAL(12,2) NOT NULL,
    NewBasePrice DECIMAL(12,2) NOT NULL,
    NewPeakPrice DECIMAL(12,2) NOT NULL,
    ChangedBy    INT NOT NULL,
    ChangedAt    DATETIME2 DEFAULT SYSDATETIME(),
    Reason       NVARCHAR(255),
    FOREIGN KEY(FieldId)    REFERENCES Fields(FieldId),
    FOREIGN KEY(ChangedBy)  REFERENCES Users(UserId)
);
GO

-- Trigger tự động ghi lịch sử khi giá thay đổi
CREATE OR ALTER TRIGGER trg_Fields_PriceHistory
ON Fields AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO FieldPriceHistory(FieldId, OldBasePrice, OldPeakPrice, NewBasePrice, NewPeakPrice, ChangedBy)
    SELECT
        i.FieldId,
        d.BasePrice, d.PeakPrice,
        i.BasePrice, i.PeakPrice,
        1  -- UserId=1 (Admin); trong thực tế truyền qua SESSION_CONTEXT
    FROM inserted i
    JOIN deleted  d ON i.FieldId = d.FieldId
    WHERE i.BasePrice <> d.BasePrice OR i.PeakPrice <> d.PeakPrice;
END
GO

CREATE TABLE TimeSlots (
    SlotId     INT IDENTITY PRIMARY KEY,
    StartTime  TIME NOT NULL,
    EndTime    TIME NOT NULL,
    IsPeakHour BIT DEFAULT 0,
    CONSTRAINT UQ_TimeSlots        UNIQUE(StartTime, EndTime),
    CONSTRAINT CK_TimeSlots_Order  CHECK (EndTime > StartTime)
);
GO

CREATE TABLE FieldSlots (
    FieldSlotId  INT IDENTITY PRIMARY KEY,
    FieldId      INT NOT NULL,
    SlotId       INT NOT NULL,
    SlotDate     DATE NOT NULL,
    Price        DECIMAL(12,2) NOT NULL,
    StatusId     INT NOT NULL DEFAULT 1,
    HoldExpireAt DATETIME2 NULL,
    UpdatedAt    DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_FieldSlots_Price   CHECK (Price > 0),
    CONSTRAINT UQ_FieldSlot          UNIQUE(FieldId, SlotId, SlotDate),
    FOREIGN KEY(FieldId)  REFERENCES Fields(FieldId),
    FOREIGN KEY(SlotId)   REFERENCES TimeSlots(SlotId),
    FOREIGN KEY(StatusId) REFERENCES FieldSlotStatuses(StatusId)
);
GO

CREATE TABLE FieldMaintenanceLogs (
    LogId       INT IDENTITY PRIMARY KEY,
    FieldId     INT NOT NULL,
    Reason      NVARCHAR(500) NOT NULL,
    StartDate   DATE NOT NULL,
    EndDate     DATE,
    CreatedBy   INT NOT NULL,
    CreatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT CK_FML_DateOrder CHECK (EndDate IS NULL OR EndDate >= StartDate),
    FOREIGN KEY(FieldId)   REFERENCES Fields(FieldId),
    FOREIGN KEY(CreatedBy) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_Fields_TypeStatus     ON Fields(TypeId, StatusId) WHERE IsDeleted = 0;
CREATE INDEX IX_FieldSlots_Search     ON FieldSlots(FieldId, SlotDate, StatusId);
CREATE INDEX IX_FieldSlots_HoldExpire ON FieldSlots(HoldExpireAt) WHERE StatusId = 2;
GO

-- Seed TimeSlots (06:00 – 22:00, nghỉ trưa 12:00–13:00)
INSERT INTO TimeSlots(StartTime, EndTime, IsPeakHour) VALUES
    ('06:00', '07:00', 0), ('07:00', '08:00', 0), ('08:00', '09:00', 0),
    ('09:00', '10:00', 0), ('10:00', '11:00', 0), ('11:00', '12:00', 0),
    ('13:00', '14:00', 0), ('14:00', '15:00', 0), ('15:00', '16:00', 0),
    ('16:00', '17:00', 0), ('17:00', '18:00', 1), ('18:00', '19:00', 1),
    ('19:00', '20:00', 1), ('20:00', '21:00', 1), ('21:00', '22:00', 1);
GO

INSERT INTO Fields(Name, Description, BasePrice, PeakPrice, TypeId, StatusId) VALUES
    (N'Sân A1', N'Sân cỏ nhân tạo 5 người, có mái che, đèn LED',   200000, 300000, 1, 1),
    (N'Sân A2', N'Sân cỏ nhân tạo 5 người, ngoài trời',            180000, 270000, 1, 1),
    (N'Sân A3', N'Sân cỏ nhân tạo 5 người, có mái che',            200000, 300000, 1, 1),
    (N'Sân B1', N'Sân cỏ nhân tạo 7 người, có đèn chiếu sáng',    350000, 500000, 2, 1),
    (N'Sân B2', N'Sân cỏ nhân tạo 7 người, có mái che, đèn LED',  380000, 550000, 2, 1);
GO


/* ================================================================
   [6] SPECIAL DAYS & PEAK SCHEDULES
   Cho phép cấu hình giá/giờ cao điểm linh hoạt theo từng ngày.
================================================================ */

-- Ngày đặc biệt: lễ, tết, sự kiện — áp dụng hệ số giá riêng
CREATE TABLE SpecialDays (
    SpecialDayId  INT IDENTITY PRIMARY KEY,
    SpecialDate   DATE NOT NULL,
    Name          NVARCHAR(100) NOT NULL,       -- VD: "Lễ 30/4", "Tết Nguyên Đán"
    PriceMultiplier DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    -- Hệ số nhân giá: 1.5 = tăng 50%, 2.0 = gấp đôi
    IsFullDayPeak BIT DEFAULT 0,
    -- 1 = cả ngày tính giờ cao điểm, 0 = theo lịch bình thường
    Note          NVARCHAR(255),
    CreatedBy     INT NOT NULL,
    CreatedAt     DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_SpecialDays_Date UNIQUE(SpecialDate),
    CONSTRAINT CK_SpecialDays_Multiplier CHECK (PriceMultiplier > 0),
    FOREIGN KEY(CreatedBy) REFERENCES Users(UserId)
);
GO

-- Cấu hình giờ cao điểm theo thứ trong tuần
-- DayOfWeek: 1=CN, 2=T2, 3=T3, 4=T4, 5=T5, 6=T6, 7=T7
CREATE TABLE PeakSchedules (
    PeakScheduleId INT IDENTITY PRIMARY KEY,
    DayOfWeek      TINYINT NOT NULL,  -- 1..7
    SlotId         INT NOT NULL,
    IsPeak         BIT DEFAULT 1,
    CONSTRAINT UQ_PeakSchedule       UNIQUE(DayOfWeek, SlotId),
    CONSTRAINT CK_PeakSchedule_Day   CHECK (DayOfWeek BETWEEN 1 AND 7),
    FOREIGN KEY(SlotId) REFERENCES TimeSlots(SlotId)
);
GO

-- T7(7) và CN(1): tất cả các slot đều là cao điểm
INSERT INTO PeakSchedules(DayOfWeek, SlotId, IsPeak)
SELECT dow, SlotId, 1
FROM TimeSlots
CROSS JOIN (VALUES (1),(7)) AS d(dow);
-- T2-T6: chỉ các slot 17:00-22:00 là cao điểm (đã có IsPeakHour=1 trong TimeSlots)
GO


/* ================================================================
   [7] BOOKINGS & PAYMENTS
================================================================ */

CREATE TABLE Bookings (
    BookingId        INT IDENTITY PRIMARY KEY,
    UserId           INT NOT NULL,
    StatusId         INT NOT NULL DEFAULT 1,
    SubTotal         DECIMAL(12,2) NULL,
    DiscountAmount   DECIMAL(12,2) DEFAULT 0,
    TaxAmount        DECIMAL(12,2) DEFAULT 0,
    TotalAmount      DECIMAL(12,2) NULL,
    DepositAmount    DECIMAL(12,2) DEFAULT 0,
    PromotionId      INT NULL,
    Note             NVARCHAR(500),
    CancelReason     NVARCHAR(500),
    RescheduleCount  INT DEFAULT 0,
    CreatedAt        DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt        DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Bookings_SubTotal       CHECK (SubTotal IS NULL OR SubTotal >= 0),
    CONSTRAINT CK_Bookings_DiscountAmount CHECK (DiscountAmount >= 0),
    CONSTRAINT CK_Bookings_TaxAmount      CHECK (TaxAmount >= 0),
    CONSTRAINT CK_Bookings_TotalAmount    CHECK (TotalAmount IS NULL OR TotalAmount >= 0),
    CONSTRAINT CK_Bookings_DepositAmount  CHECK (DepositAmount >= 0),
    FOREIGN KEY(UserId)   REFERENCES Users(UserId),
    FOREIGN KEY(StatusId) REFERENCES BookingStatuses(StatusId)
);
GO

CREATE TABLE BookingDetails (
    BookingDetailId INT IDENTITY PRIMARY KEY,
    BookingId       INT NOT NULL,
    FieldSlotId     INT NOT NULL,
    Price           DECIMAL(12,2) NOT NULL,
    CONSTRAINT CK_BookingDetails_Price  CHECK (Price > 0),
    CONSTRAINT UQ_BookingDetail_Slot    UNIQUE(FieldSlotId),
    FOREIGN KEY(BookingId)   REFERENCES Bookings(BookingId),
    FOREIGN KEY(FieldSlotId) REFERENCES FieldSlots(FieldSlotId)
);
GO

CREATE TABLE Payments (
    PaymentId       INT IDENTITY PRIMARY KEY,
    BookingId       INT NOT NULL,
    Amount          DECIMAL(12,2) NOT NULL,
    StatusId        INT NOT NULL DEFAULT 1,
    MethodId        INT NOT NULL,
    TransactionCode NVARCHAR(100),
    GatewayResponse NVARCHAR(MAX),
    Note            NVARCHAR(255),
    PaidAt          DATETIME2 NULL,
    CreatedAt       DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(StatusId)  REFERENCES PaymentStatuses(StatusId),
    FOREIGN KEY(MethodId)  REFERENCES PaymentMethods(MethodId)
);
GO

CREATE INDEX IX_Bookings_UserId        ON Bookings(UserId);
CREATE INDEX IX_Bookings_StatusCreated ON Bookings(StatusId, CreatedAt);
CREATE INDEX IX_BookingDetails_Booking ON BookingDetails(BookingId);
CREATE INDEX IX_Payments_BookingId     ON Payments(BookingId);
CREATE INDEX IX_Payments_TxCode        ON Payments(TransactionCode) WHERE TransactionCode IS NOT NULL;
GO


/* ================================================================
   [8] DEPOSITS — Đặt cọc
   Tách riêng khỏi Payments để dễ theo dõi trạng thái cọc.
   Khi thanh toán full ngay: DepositAmount = 0, không tạo bản ghi Deposit.
   Khi thanh toán sau: tạo Deposit bắt buộc trước khi xác nhận slot.
================================================================ */

CREATE TABLE Deposits (
    DepositId       INT IDENTITY PRIMARY KEY,
    BookingId       INT NOT NULL UNIQUE,  -- 1 booking 1 dòng deposit
    RequiredAmount  DECIMAL(12,2) NOT NULL,  -- Số tiền cọc yêu cầu
    PaidAmount      DECIMAL(12,2) DEFAULT 0, -- Số tiền cọc đã nộp
    StatusId        INT NOT NULL DEFAULT 1,
    DeadlineAt      DATETIME2 NOT NULL,      -- Hạn phải nộp cọc
    PaidAt          DATETIME2 NULL,
    RefundedAt      DATETIME2 NULL,
    ForfeitedAt     DATETIME2 NULL,          -- Ngày tịch thu (hủy muộn)
    PaymentId       INT NULL,                -- FK tới bản ghi payment của tiền cọc
    Note            NVARCHAR(255),
    CreatedAt       DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Deposits_Required CHECK (RequiredAmount > 0),
    CONSTRAINT CK_Deposits_Paid     CHECK (PaidAmount >= 0),
    FOREIGN KEY(BookingId)  REFERENCES Bookings(BookingId),
    FOREIGN KEY(StatusId)   REFERENCES DepositStatuses(StatusId),
    FOREIGN KEY(PaymentId)  REFERENCES Payments(PaymentId)
);
GO

CREATE INDEX IX_Deposits_Status   ON Deposits(StatusId, DeadlineAt);
CREATE INDEX IX_Deposits_Deadline ON Deposits(DeadlineAt) WHERE StatusId = 1;
GO


/* ================================================================
   [9] BOOKING LOGS — Lịch sử thay đổi trạng thái booking
================================================================ */

CREATE TABLE BookingLogs (
    LogId          INT IDENTITY PRIMARY KEY,
    BookingId      INT NOT NULL,
    OldStatusId    INT NULL,
    NewStatusId    INT NOT NULL,
    ChangedByUserId INT NULL,
    Note           NVARCHAR(500),
    ChangedAt      DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY(BookingId)       REFERENCES Bookings(BookingId),
    FOREIGN KEY(OldStatusId)     REFERENCES BookingStatuses(StatusId),
    FOREIGN KEY(NewStatusId)     REFERENCES BookingStatuses(StatusId),
    FOREIGN KEY(ChangedByUserId) REFERENCES Users(UserId)
);
GO

-- Trigger tự động ghi log khi StatusId thay đổi
CREATE OR ALTER TRIGGER trg_Bookings_StatusLog
ON Bookings AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO BookingLogs(BookingId, OldStatusId, NewStatusId)
    SELECT i.BookingId, d.StatusId, i.StatusId
    FROM inserted i
    JOIN deleted  d ON i.BookingId = d.BookingId
    WHERE i.StatusId <> d.StatusId;
END
GO

CREATE INDEX IX_BookingLogs_Booking ON BookingLogs(BookingId, ChangedAt);
GO


/* ================================================================
   [10] SERVICES (Dịch vụ đi kèm)
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
    CONSTRAINT UQ_BookingService            UNIQUE(BookingId, ServiceId),
    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(ServiceId) REFERENCES Services(ServiceId)
);
GO

CREATE INDEX IX_BookingServices_Booking ON BookingServices(BookingId);
GO

INSERT INTO Services(Name, Description, Price) VALUES
    (N'Thuê bóng',       N'Bóng đá tiêu chuẩn size 5',       30000),
    (N'Thuê áo',         N'Bộ áo thi đấu theo set 10 cái',   150000),
    (N'Nước uống',       N'Thùng 24 chai 500ml',              120000),
    (N'Thuê giày',       N'Giày đá bóng các cỡ',              50000),
    (N'Thuê trọng tài',  N'Trọng tài cho trận giao hữu',     200000);
GO


/* ================================================================
   [11] PROMOTIONS & VOUCHERS
================================================================ */

CREATE TABLE Promotions (
    PromotionId    INT IDENTITY PRIMARY KEY,
    Code           NVARCHAR(50)  NOT NULL,
    Name           NVARCHAR(200) NOT NULL,
    Description    NVARCHAR(500),
    TypeId         INT NOT NULL,
    DiscountValue  DECIMAL(12,2) NOT NULL,
    MaxDiscount    DECIMAL(12,2) NULL,
    MinOrderAmount DECIMAL(12,2) DEFAULT 0,
    UsageLimit     INT DEFAULT 1,
    UsageCount     INT DEFAULT 0,
    StartDate      DATE NOT NULL,
    EndDate        DATE NOT NULL,
    IsActive       BIT DEFAULT 1,
    CreatedBy      INT NOT NULL,
    CreatedAt      DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_Promotions_Code  UNIQUE(Code),
    CONSTRAINT CK_Promotions_Value CHECK (DiscountValue > 0),
    CONSTRAINT CK_Promotions_Date  CHECK (EndDate >= StartDate),
    CONSTRAINT CK_Promotions_Usage CHECK (UsageCount <= UsageLimit),
    FOREIGN KEY(TypeId)    REFERENCES PromotionTypes(TypeId),
    FOREIGN KEY(CreatedBy) REFERENCES Users(UserId)
);
GO

ALTER TABLE Bookings
ADD CONSTRAINT FK_Bookings_Promotion
    FOREIGN KEY(PromotionId) REFERENCES Promotions(PromotionId);
GO

CREATE INDEX IX_Promotions_Code   ON Promotions(Code)     WHERE IsActive = 1;
CREATE INDEX IX_Promotions_Active ON Promotions(IsActive, StartDate, EndDate);
GO


/* ================================================================
   [12] INVENTORY — Kho hàng
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
    MinQty    INT DEFAULT 5,
    IsDeleted BIT DEFAULT 0,
    CONSTRAINT CK_Products_StockQty CHECK (StockQty >= 0),
    CONSTRAINT CK_Products_MinQty   CHECK (MinQty   >= 0)
);
GO

CREATE TABLE PurchaseOrders (
    PurchaseOrderId INT IDENTITY PRIMARY KEY,
    SupplierId      INT NOT NULL,
    CreatedByUserId INT NOT NULL,
    StatusId        INT NOT NULL DEFAULT 1,
    TotalAmount     DECIMAL(12,2) NULL,
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
    CONSTRAINT CK_POD_Qty       CHECK (Quantity  >= 1),
    CONSTRAINT CK_POD_UnitPrice CHECK (UnitPrice > 0),
    CONSTRAINT UQ_POD_Product   UNIQUE(PurchaseOrderId, ProductId),
    FOREIGN KEY(PurchaseOrderId) REFERENCES PurchaseOrders(PurchaseOrderId),
    FOREIGN KEY(ProductId)       REFERENCES Products(ProductId)
);
GO


/* ================================================================
   [13] INCIDENTS — Sự cố sân
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
   [14] REVIEWS — Đánh giá sân
   Chỉ cho phép review sau khi booking Đã hoàn thành (StatusId=4).
================================================================ */

CREATE TABLE Reviews (
    ReviewId    INT IDENTITY PRIMARY KEY,
    BookingId   INT NOT NULL UNIQUE,  -- 1 booking 1 review
    UserId      INT NOT NULL,
    FieldId     INT NOT NULL,
    Rating      TINYINT NOT NULL,     -- 1–5 sao
    Comment     NVARCHAR(1000),
    ImageUrl    NVARCHAR(500),
    IsVisible   BIT DEFAULT 1,        -- Admin có thể ẩn review vi phạm
    CreatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt   DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5),
    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(UserId)    REFERENCES Users(UserId),
    FOREIGN KEY(FieldId)   REFERENCES Fields(FieldId)
);
GO

CREATE INDEX IX_Reviews_Field ON Reviews(FieldId, IsVisible);
GO


/* ================================================================
   [15] NOTIFICATIONS
================================================================ */

CREATE TABLE Notifications (
    NotificationId INT IDENTITY PRIMARY KEY,
    UserId         INT NOT NULL,
    Title          NVARCHAR(200) NOT NULL,
    Body           NVARCHAR(1000),
    Type           NVARCHAR(50),
    -- BOOKING_CONFIRM | BOOKING_CANCEL | PAYMENT | DEPOSIT | INCIDENT | REVIEW | SYSTEM
    RefId          INT NULL,
    IsRead         BIT DEFAULT 0,
    CreatedAt      DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY(UserId) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_Notifications_Unread ON Notifications(UserId, IsRead, CreatedAt DESC);
GO


/* ================================================================
   [16] STORED PROCEDURES
================================================================ */

/* ----------------------------------------------------------------
   Helper: Đọc cấu hình số thực từ SystemConfig
---------------------------------------------------------------- */
CREATE OR ALTER FUNCTION fn_GetConfig(@Key NVARCHAR(100))
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @Val DECIMAL(18,4);
    SELECT @Val = TRY_CAST(ConfigValue AS DECIMAL(18,4))
    FROM SystemConfig WHERE ConfigKey = @Key;
    RETURN ISNULL(@Val, 0);
END
GO

CREATE OR ALTER FUNCTION fn_GetConfigStr(@Key NVARCHAR(100))
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @Val NVARCHAR(500);
    SELECT @Val = ConfigValue FROM SystemConfig WHERE ConfigKey = @Key;
    RETURN @Val;
END
GO


/* ----------------------------------------------------------------
   SP-0: Cập nhật cấu hình hệ thống
   Gọi:  EXEC sp_UpdateSystemConfig 'DEPOSIT_REQUIRED_PERCENT', '30', @UserId=1
         EXEC sp_UpdateSystemConfig 'MIN_CANCEL_BEFORE_HOURS',  '4',  @UserId=1

   Các key thường dùng:
     DEPOSIT_REQUIRED_PERCENT    -- % đặt cọc (0 = không cần cọc)
     DEPOSIT_DEADLINE_HOURS      -- Giờ hạn nộp cọc
     MIN_ADVANCE_BOOKING_HOURS   -- Phải đặt trước bao nhiêu giờ
     MAX_ADVANCE_BOOKING_DAYS    -- Tối đa bao nhiêu ngày trước
     MIN_CANCEL_BEFORE_HOURS     -- Không hủy nếu còn dưới N giờ
     CANCEL_REFUND_POLICY_HOURS  -- Hủy trước N giờ được hoàn tiền
     HOLD_DURATION_MINUTES       -- Thời gian giữ slot
     RESCHEDULE_FEE_PERCENT      -- Phí đổi lịch %
     MIN_RESCHEDULE_BEFORE_HOURS -- Không đổi lịch nếu còn dưới N giờ
     MAX_RESCHEDULE_PER_BOOKING  -- Số lần đổi lịch tối đa
     MAX_SLOTS_PER_BOOKING       -- Slot tối đa / booking
     MAX_ACTIVE_BOOKINGS_PER_USER-- Booking đang mở tối đa / user
     TAX_PERCENT                 -- Thuế VAT %
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_UpdateSystemConfig
    @ConfigKey   NVARCHAR(100),
    @ConfigValue NVARCHAR(500),
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE ConfigKey = @ConfigKey)
        THROW 50100, N'ConfigKey không tồn tại. Kiểm tra lại tên cấu hình.', 1;

    UPDATE SystemConfig
    SET ConfigValue = @ConfigValue,
        UpdatedAt   = SYSDATETIME(),
        UpdatedBy   = @UserId
    WHERE ConfigKey = @ConfigKey;

    PRINT N'✅ Đã cập nhật ' + @ConfigKey + N' = ' + @ConfigValue;
END
GO


/* ----------------------------------------------------------------
   SP-1: Sinh FieldSlots — hỗ trợ SpecialDays & PeakSchedules
   Gọi:  EXEC sp_GenerateSlots '2026-06-01', '2026-06-30'
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_GenerateSlots
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate > @EndDate
        THROW 50010, N'StartDate phải nhỏ hơn hoặc bằng EndDate.', 1;

    DECLARE @Date DATE = @StartDate;
    WHILE @Date <= @EndDate
    BEGIN
        DECLARE @DayOfWeek TINYINT = DATEPART(WEEKDAY, @Date); -- 1=CN..7=T7

        -- Kiểm tra SpecialDay
        DECLARE @Multiplier DECIMAL(5,2) = 1.0;
        DECLARE @IsFullDayPeak BIT = 0;
        SELECT  @Multiplier    = ISNULL(PriceMultiplier, 1.0),
                @IsFullDayPeak = ISNULL(IsFullDayPeak, 0)
        FROM SpecialDays WHERE SpecialDate = @Date;

        INSERT INTO FieldSlots(FieldId, SlotId, SlotDate, Price)
        SELECT
            f.FieldId,
            ts.SlotId,
            @Date,
            -- Giá = BasePrice hoặc PeakPrice × Multiplier
            ROUND(
                CASE
                    WHEN @IsFullDayPeak = 1
                        THEN f.PeakPrice * @Multiplier
                    WHEN EXISTS (
                        SELECT 1 FROM PeakSchedules ps
                        WHERE ps.DayOfWeek = @DayOfWeek
                          AND ps.SlotId   = ts.SlotId
                          AND ps.IsPeak   = 1
                    ) OR ts.IsPeakHour = 1
                        THEN f.PeakPrice * @Multiplier
                    ELSE f.BasePrice * @Multiplier
                END
            , 0)
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
   SP-2: Giữ slot — kiểm tra ràng buộc đặt trước
   Gọi:  EXEC sp_HoldSlots '1,2,3', @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_HoldSlots
    @FieldSlotIds NVARCHAR(MAX),
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    CREATE TABLE #Requested(Id INT);
    INSERT INTO #Requested(Id)
    SELECT CAST(TRIM(value) AS INT)
    FROM STRING_SPLIT(@FieldSlotIds, ',')
    WHERE TRIM(value) != '';

    DECLARE @RequestCount INT = (SELECT COUNT(*) FROM #Requested);

    -- 1. Giới hạn số slot / booking
    DECLARE @MaxSlots INT = CAST(dbo.fn_GetConfig('MAX_SLOTS_PER_BOOKING') AS INT);
    IF @RequestCount > @MaxSlots
        THROW 50011, N'Số lượng slot vượt quá giới hạn cho phép trong một booking.', 1;

    -- 2. Kiểm tra số booking đang mở của user
    IF @UserId IS NOT NULL
    BEGIN
        DECLARE @MaxActive INT = CAST(dbo.fn_GetConfig('MAX_ACTIVE_BOOKINGS_PER_USER') AS INT);
        DECLARE @ActiveCount INT = (
            SELECT COUNT(*) FROM Bookings
            WHERE UserId = @UserId AND StatusId IN (1, 2, 5)
        );
        IF @ActiveCount >= @MaxActive
            THROW 50012, N'Bạn đang có quá nhiều booking đang mở. Vui lòng hoàn thành hoặc hủy bớt.', 1;
    END

    -- 3. Ràng buộc đặt trước (MinAdvanceBookingHours)
    DECLARE @MinAdvanceHours INT = CAST(dbo.fn_GetConfig('MIN_ADVANCE_BOOKING_HOURS') AS INT);
    DECLARE @MaxAdvanceDays  INT = CAST(dbo.fn_GetConfig('MAX_ADVANCE_BOOKING_DAYS')  AS INT);
    DECLARE @Now DATETIME2 = SYSDATETIME();

    IF EXISTS (
        SELECT 1 FROM FieldSlots fs
        JOIN #Requested r ON fs.FieldSlotId = r.Id
        JOIN TimeSlots  ts ON fs.SlotId = ts.SlotId
        WHERE DATEADD(HOUR, -@MinAdvanceHours,
              DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', ts.StartTime), CAST(fs.SlotDate AS DATETIME2))) < @Now
    )
        THROW 50013, N'Phải đặt sân trước ít nhất theo quy định. Vui lòng chọn khung giờ khác.', 1;

    IF EXISTS (
        SELECT 1 FROM FieldSlots fs
        JOIN #Requested r ON fs.FieldSlotId = r.Id
        WHERE fs.SlotDate > DATEADD(DAY, @MaxAdvanceDays, CAST(@Now AS DATE))
    )
        THROW 50014, N'Chỉ được đặt sân trong vòng số ngày tối đa cho phép.', 1;

    -- 4. Giữ slot (UPDLOCK chống double-booking)
    DECLARE @HoldMinutes INT = CAST(dbo.fn_GetConfig('HOLD_DURATION_MINUTES') AS INT);
    IF @HoldMinutes < 1 SET @HoldMinutes = 10;

    UPDATE fs
    SET StatusId     = 2,
        HoldExpireAt = DATEADD(MINUTE, @HoldMinutes, SYSDATETIME()),
        UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs WITH (UPDLOCK, HOLDLOCK)
    JOIN #Requested r ON fs.FieldSlotId = r.Id
    WHERE fs.StatusId = 1;

    IF @@ROWCOUNT < @RequestCount
    BEGIN
        ROLLBACK;
        THROW 50001, N'Một hoặc nhiều slot không còn khả dụng. Vui lòng chọn lại.', 1;
    END

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-3: Xác nhận booking + xử lý đặt cọc
   Gọi:
     -- Thanh toán full ngay (không cần cọc):
     EXEC sp_ConfirmBooking @BookingId=1, @FieldSlotIds='1,2', @IsFullPayment=1
     -- Thanh toán sau (bắt buộc đặt cọc):
     EXEC sp_ConfirmBooking @BookingId=1, @FieldSlotIds='1,2', @IsFullPayment=0
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ConfirmBooking
    @BookingId      INT,
    @FieldSlotIds   NVARCHAR(MAX),
    @IsFullPayment  BIT = 1,     -- 1 = thanh toán đủ, 0 = thanh toán sau/cần cọc
    @UserId         INT = NULL
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

    -- Chuyển slot Đang giữ → Đã đặt
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

    -- Tính SubTotal
    DECLARE @SubTotal DECIMAL(12,2) =
        ISNULL((SELECT SUM(bd.Price)            FROM BookingDetails bd WHERE bd.BookingId = @BookingId), 0)
      + ISNULL((SELECT SUM(bs.Quantity * bs.UnitPrice) FROM BookingServices bs WHERE bs.BookingId = @BookingId), 0);

    -- Tính thuế
    DECLARE @TaxPct DECIMAL(5,2) = dbo.fn_GetConfig('TAX_PERCENT');
    DECLARE @TaxAmount DECIMAL(12,2) = ROUND(@SubTotal * @TaxPct / 100, 0);

    -- Tính TotalAmount (sau giảm giá + thuế)
    DECLARE @DiscountAmt DECIMAL(12,2) = ISNULL((SELECT DiscountAmount FROM Bookings WHERE BookingId = @BookingId), 0);
    DECLARE @TotalAmount DECIMAL(12,2) = @SubTotal - @DiscountAmt + @TaxAmount;
    IF @TotalAmount < 0 SET @TotalAmount = 0;

    -- Tính tiền cọc yêu cầu
    DECLARE @DepositPct    DECIMAL(5,2)  = dbo.fn_GetConfig('DEPOSIT_REQUIRED_PERCENT');
    DECLARE @DepositAmount DECIMAL(12,2) = 0;
    DECLARE @NewBookingStatus INT;

    IF @IsFullPayment = 1 OR @DepositPct = 0
    BEGIN
        -- Không cần cọc → Đã xác nhận
        SET @DepositAmount    = 0;
        SET @NewBookingStatus = 2;  -- Đã xác nhận
    END
    ELSE
    BEGIN
        -- Cần đặt cọc → Chờ đặt cọc
        SET @DepositAmount    = CEILING(@TotalAmount * @DepositPct / 100);
        SET @NewBookingStatus = 5;  -- Chờ đặt cọc

        -- Tạo bản ghi Deposit
        DECLARE @DepositHours INT = CAST(dbo.fn_GetConfig('DEPOSIT_DEADLINE_HOURS') AS INT);
        INSERT INTO Deposits(BookingId, RequiredAmount, StatusId, DeadlineAt)
        VALUES (
            @BookingId,
            @DepositAmount,
            1,  -- Chờ nộp
            DATEADD(HOUR, @DepositHours, SYSDATETIME())
        );
    END

    UPDATE Bookings
    SET SubTotal      = @SubTotal,
        TaxAmount     = @TaxAmount,
        TotalAmount   = @TotalAmount,
        DepositAmount = @DepositAmount,
        StatusId      = @NewBookingStatus,
        UpdatedAt     = SYSDATETIME()
    WHERE BookingId   = @BookingId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-4: Ghi nhận thanh toán đặt cọc
   Gọi:  EXEC sp_RecordDeposit @BookingId=1, @Amount=60000, @MethodId=1,
                                @TransactionCode='TXN123', @UserId=5
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_RecordDeposit
    @BookingId       INT,
    @Amount          DECIMAL(12,2),
    @MethodId        INT,
    @TransactionCode NVARCHAR(100) = NULL,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    -- Kiểm tra booking đang Chờ đặt cọc
    DECLARE @DepositId INT, @RequiredAmount DECIMAL(12,2);
    SELECT @DepositId      = DepositId,
           @RequiredAmount = RequiredAmount
    FROM Deposits
    WHERE BookingId = @BookingId AND StatusId = 1;

    IF @DepositId IS NULL
    BEGIN
        ROLLBACK;
        THROW 50050, N'Booking không yêu cầu đặt cọc hoặc đã được xử lý.', 1;
    END

    IF @Amount < @RequiredAmount
    BEGIN
        ROLLBACK;
        THROW 50051, N'Số tiền cọc chưa đủ theo yêu cầu.', 1;
    END

    -- Ghi payment đặt cọc
    DECLARE @PaymentId INT;
    INSERT INTO Payments(BookingId, Amount, StatusId, MethodId, TransactionCode, Note, PaidAt)
    VALUES (@BookingId, @Amount, 2, @MethodId, @TransactionCode,
            N'Thanh toán đặt cọc', SYSDATETIME());
    SET @PaymentId = SCOPE_IDENTITY();

    -- Cập nhật Deposit
    UPDATE Deposits
    SET PaidAmount = @Amount,
        StatusId   = 2,   -- Đã nộp
        PaidAt     = SYSDATETIME(),
        PaymentId  = @PaymentId,
        UpdatedAt  = SYSDATETIME()
    WHERE DepositId = @DepositId;

    -- Chuyển Booking → Đã xác nhận
    UPDATE Bookings
    SET StatusId  = 2,
        UpdatedAt = SYSDATETIME()
    WHERE BookingId = @BookingId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-5: Thanh toán phần còn lại (sau khi đã cọc)
   Gọi:  EXEC sp_RecordFullPayment @BookingId=1, @MethodId=1,
                                    @TransactionCode='TXN456'
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_RecordFullPayment
    @BookingId       INT,
    @MethodId        INT,
    @TransactionCode NVARCHAR(100) = NULL,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    -- Tổng đã thanh toán
    DECLARE @TotalAmount   DECIMAL(12,2);
    DECLARE @AlreadyPaid   DECIMAL(12,2);
    DECLARE @Remaining     DECIMAL(12,2);

    SELECT @TotalAmount = TotalAmount FROM Bookings WHERE BookingId = @BookingId AND StatusId = 2;
    IF @TotalAmount IS NULL
    BEGIN
        ROLLBACK;
        THROW 50060, N'Booking không hợp lệ hoặc chưa được xác nhận.', 1;
    END

    SELECT @AlreadyPaid = ISNULL(SUM(Amount), 0)
    FROM Payments WHERE BookingId = @BookingId AND StatusId = 2;

    SET @Remaining = @TotalAmount - @AlreadyPaid;

    IF @Remaining <= 0
    BEGIN
        ROLLBACK;
        THROW 50061, N'Booking đã được thanh toán đủ.', 1;
    END

    INSERT INTO Payments(BookingId, Amount, StatusId, MethodId, TransactionCode, Note, PaidAt)
    VALUES (@BookingId, @Remaining, 2, @MethodId, @TransactionCode,
            N'Thanh toán phần còn lại', SYSDATETIME());

    -- Chuyển booking → Đã hoàn thành nếu đã đến ngày
    DECLARE @LastSlotDate DATE;
    SELECT @LastSlotDate = MAX(fs.SlotDate)
    FROM BookingDetails bd
    JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
    WHERE bd.BookingId = @BookingId;

    IF @LastSlotDate <= CAST(SYSDATETIME() AS DATE)
        UPDATE Bookings SET StatusId = 4, UpdatedAt = SYSDATETIME()
        WHERE BookingId = @BookingId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-6: Hủy booking — kiểm tra ràng buộc thời gian
   Gọi:  EXEC sp_CancelBooking @BookingId=1, @UserId=5, @Reason=N'Bận việc'
         -- Admin hủy (bỏ qua giới hạn thời gian):
         EXEC sp_CancelBooking @BookingId=1, @UserId=1, @Reason=N'...', @IsAdminOverride=1
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_CancelBooking
    @BookingId       INT,
    @UserId          INT = NULL,
    @Reason          NVARCHAR(500) = NULL,
    @IsAdminOverride BIT = 0      -- Admin có thể bỏ qua ràng buộc giờ
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    DECLARE @CurrentStatus INT;
    SELECT @CurrentStatus = StatusId FROM Bookings WHERE BookingId = @BookingId;

    IF @CurrentStatus NOT IN (1, 2, 5)
    BEGIN
        ROLLBACK;
        THROW 50003, N'Booking không thể hủy ở trạng thái hiện tại.', 1;
    END

    -- Ràng buộc thời gian hủy (không áp cho Admin override)
    IF @IsAdminOverride = 0
    BEGIN
        DECLARE @MinCancelHours INT = CAST(dbo.fn_GetConfig('MIN_CANCEL_BEFORE_HOURS') AS INT);
        DECLARE @Now DATETIME2 = SYSDATETIME();

        -- Lấy slot sớm nhất trong booking
        DECLARE @EarliestSlotDT DATETIME2;
        SELECT @EarliestSlotDT = MIN(
            DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', ts.StartTime), CAST(fs.SlotDate AS DATETIME2))
        )
        FROM BookingDetails bd
        JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
        JOIN TimeSlots  ts ON fs.SlotId      = ts.SlotId
        WHERE bd.BookingId = @BookingId;

        IF @EarliestSlotDT IS NOT NULL
           AND DATEDIFF(HOUR, @Now, @EarliestSlotDT) < @MinCancelHours
        BEGIN
            ROLLBACK;
            THROW 50004,
                N'Không thể hủy booking khi còn quá ít thời gian trước giờ thi đấu theo chính sách.',
                1;
        END
    END

    -- Trả slot về Trống
    UPDATE fs
    SET StatusId     = 1,
        HoldExpireAt = NULL,
        UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs
    JOIN BookingDetails bd ON fs.FieldSlotId = bd.FieldSlotId
    WHERE bd.BookingId   = @BookingId
      AND fs.StatusId   IN (2, 3);

    -- Xử lý hoàn tiền / tịch thu cọc
    IF @CurrentStatus IN (2, 5)
    BEGIN
        DECLARE @RefundHours INT = CAST(dbo.fn_GetConfig('CANCEL_REFUND_POLICY_HOURS') AS INT);
        DECLARE @MinCancel2  INT = CAST(dbo.fn_GetConfig('MIN_CANCEL_BEFORE_HOURS')    AS INT);
        DECLARE @Now2        DATETIME2 = SYSDATETIME();

        DECLARE @EarliestSlotDT2 DATETIME2;
        SELECT @EarliestSlotDT2 = MIN(
            DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', ts.StartTime), CAST(fs.SlotDate AS DATETIME2))
        )
        FROM BookingDetails bd
        JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
        JOIN TimeSlots  ts ON fs.SlotId      = ts.SlotId
        WHERE bd.BookingId = @BookingId;

        DECLARE @HoursLeft INT = DATEDIFF(HOUR, @Now2, @EarliestSlotDT2);

        DECLARE @DepositStatusId INT = NULL;
        SELECT @DepositStatusId = StatusId FROM Deposits WHERE BookingId = @BookingId;

        IF @HoursLeft >= @RefundHours
        BEGIN
            -- Hoàn tiền đầy đủ
            DECLARE @PaidAmount DECIMAL(12,2), @MethodId INT;
            SELECT TOP 1 @PaidAmount = Amount, @MethodId = MethodId
            FROM Payments
            WHERE BookingId = @BookingId AND StatusId = 2
            ORDER BY CreatedAt DESC;

            IF @PaidAmount IS NOT NULL
                INSERT INTO Payments(BookingId, Amount, StatusId, MethodId, Note, PaidAt)
                VALUES(@BookingId, @PaidAmount, 4, @MethodId,
                       N'Hoàn tiền do hủy booking (đủ điều kiện hoàn 100%)', SYSDATETIME());

            -- Hoàn cọc nếu có
            IF @DepositStatusId = 2
                UPDATE Deposits SET StatusId = 3, RefundedAt = SYSDATETIME(), UpdatedAt = SYSDATETIME()
                WHERE BookingId = @BookingId;
        END
        ELSE
        BEGIN
            -- Hủy muộn → tịch thu cọc, hoàn phần còn lại
            IF @DepositStatusId = 2
                UPDATE Deposits SET StatusId = 4, ForfeitedAt = SYSDATETIME(), UpdatedAt = SYSDATETIME()
                WHERE BookingId = @BookingId;

            -- Hoàn phần tiền đã trả (trừ cọc)
            DECLARE @PaidFull DECIMAL(12,2), @DepositPaid DECIMAL(12,2), @MId2 INT;
            SELECT @PaidFull = ISNULL(SUM(Amount), 0) FROM Payments
            WHERE BookingId = @BookingId AND StatusId = 2;
            SELECT @DepositPaid = ISNULL(PaidAmount, 0) FROM Deposits WHERE BookingId = @BookingId;
            SET @MId2 = (SELECT TOP 1 MethodId FROM Payments
                         WHERE BookingId = @BookingId AND StatusId = 2
                         ORDER BY CreatedAt DESC);

            DECLARE @RefundNet DECIMAL(12,2) = @PaidFull - @DepositPaid;
            IF @RefundNet > 0
                INSERT INTO Payments(BookingId, Amount, StatusId, MethodId, Note, PaidAt)
                VALUES(@BookingId, @RefundNet, 4, @MId2,
                       N'Hoàn tiền do hủy muộn (cọc bị tịch thu)', SYSDATETIME());
        END
    END

    -- Cập nhật Booking
    UPDATE Bookings
    SET StatusId     = 3,
        CancelReason = @Reason,
        UpdatedAt    = SYSDATETIME()
    WHERE BookingId = @BookingId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-7: Giải phóng slot & deposit hết hạn — chạy mỗi 1 phút
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ReleaseExpiredSlots
AS
BEGIN
    SET NOCOUNT ON;

    -- Giải phóng slot hết hạn hold
    UPDATE FieldSlots
    SET StatusId     = 1,
        HoldExpireAt = NULL,
        UpdatedAt    = SYSDATETIME()
    WHERE StatusId    = 2
      AND HoldExpireAt < SYSDATETIME();

    -- Tự động hủy booking Chờ thanh toán > 15 phút không còn slot hold hợp lệ
    UPDATE b
    SET b.StatusId     = 3,
        b.UpdatedAt    = SYSDATETIME(),
        b.CancelReason = N'Hết thời gian giữ chỗ, tự động hủy'
    FROM Bookings b
    WHERE b.StatusId = 1
      AND b.CreatedAt < DATEADD(MINUTE, -15, SYSDATETIME())
      AND NOT EXISTS (
          SELECT 1
          FROM BookingDetails bd
          JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
          WHERE bd.BookingId  = b.BookingId
            AND fs.StatusId   = 2
            AND fs.HoldExpireAt >= SYSDATETIME()
      );

    -- Hủy booking Chờ đặt cọc đã quá deadline nộp cọc
    UPDATE b
    SET b.StatusId     = 3,
        b.UpdatedAt    = SYSDATETIME(),
        b.CancelReason = N'Quá hạn nộp cọc, tự động hủy'
    FROM Bookings b
    JOIN Deposits d ON b.BookingId = d.BookingId
    WHERE b.StatusId = 5
      AND d.StatusId = 1       -- Chờ nộp
      AND d.DeadlineAt < SYSDATETIME();

    -- Trả slot về Trống cho các booking bị hủy do quá hạn cọc
    UPDATE fs
    SET fs.StatusId     = 1,
        fs.HoldExpireAt = NULL,
        fs.UpdatedAt    = SYSDATETIME()
    FROM FieldSlots fs
    JOIN BookingDetails bd ON fs.FieldSlotId = bd.FieldSlotId
    JOIN Bookings b        ON bd.BookingId   = b.BookingId
    WHERE b.StatusId = 3
      AND b.CancelReason = N'Quá hạn nộp cọc, tự động hủy'
      AND fs.StatusId    = 3;

    -- Đánh dấu Deposit đã quá hạn
    UPDATE Deposits
    SET StatusId  = 4,    -- Đã tịch thu (mặc dù không nộp, slot bị thu hồi)
        UpdatedAt = SYSDATETIME()
    WHERE StatusId  = 1
      AND DeadlineAt < SYSDATETIME();

    -- Tự động hoàn thành booking đã qua ngày thi đấu và đã thanh toán đủ
    UPDATE b
    SET b.StatusId  = 4,    -- Đã hoàn thành
        b.UpdatedAt = SYSDATETIME()
    FROM Bookings b
    WHERE b.StatusId = 2
      AND NOT EXISTS (
          SELECT 1
          FROM BookingDetails bd
          JOIN FieldSlots fs ON bd.FieldSlotId = fs.FieldSlotId
          WHERE bd.BookingId = b.BookingId
            AND fs.SlotDate >= CAST(SYSDATETIME() AS DATE)
      );
END
GO


/* ----------------------------------------------------------------
   SP-8: Áp dụng voucher
   Gọi:  EXEC sp_ApplyPromotion @BookingId=1, @Code=N'SUMMER20', @UserId=5
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

    DECLARE @CurrentSubTotal DECIMAL(12,2);
    SELECT @CurrentSubTotal = SubTotal FROM Bookings
    WHERE BookingId = @BookingId AND StatusId IN (1, 5);

    IF @CurrentSubTotal IS NULL
    BEGIN
        ROLLBACK;
        THROW 50020, N'Booking không tồn tại hoặc không thể áp voucher ở trạng thái này.', 1;
    END

    DECLARE @PromotionId INT, @TypeId INT,
            @DiscountValue DECIMAL(12,2), @MaxDiscount DECIMAL(12,2),
            @MinOrder DECIMAL(12,2);

    SELECT @PromotionId   = PromotionId,
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

    DECLARE @DiscountAmount DECIMAL(12,2);
    SET @DiscountAmount = CASE
        WHEN @TypeId = 1 THEN @CurrentSubTotal * @DiscountValue / 100
        ELSE @DiscountValue
    END;
    IF @MaxDiscount IS NOT NULL AND @DiscountAmount > @MaxDiscount
        SET @DiscountAmount = @MaxDiscount;

    DECLARE @TaxAmount DECIMAL(12,2) = ISNULL((SELECT TaxAmount FROM Bookings WHERE BookingId = @BookingId), 0);

    UPDATE Bookings
    SET PromotionId    = @PromotionId,
        DiscountAmount = @DiscountAmount,
        TotalAmount    = SubTotal - @DiscountAmount + @TaxAmount,
        UpdatedAt      = SYSDATETIME()
    WHERE BookingId = @BookingId;

    UPDATE Promotions SET UsageCount = UsageCount + 1 WHERE PromotionId = @PromotionId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-9: Đổi lịch — kiểm tra phí + giới hạn lần đổi
   Gọi:  EXEC sp_RescheduleBooking @BookingDetailId=1, @NewFieldSlotId=50, @UserId=5
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

    DECLARE @BookingId INT, @OldFieldSlotId INT, @OldPrice DECIMAL(12,2), @RescheduleCount INT;

    SELECT @BookingId       = bd.BookingId,
           @OldFieldSlotId  = bd.FieldSlotId,
           @OldPrice        = bd.Price,
           @RescheduleCount = b.RescheduleCount
    FROM BookingDetails bd
    JOIN Bookings b ON bd.BookingId = b.BookingId
    WHERE bd.BookingDetailId = @BookingDetailId
      AND b.StatusId = 2;

    IF @BookingId IS NULL
    BEGIN
        ROLLBACK;
        THROW 50040, N'Booking detail không hợp lệ hoặc booking chưa được xác nhận.', 1;
    END

    -- Giới hạn số lần đổi
    DECLARE @MaxReschedule INT = CAST(dbo.fn_GetConfig('MAX_RESCHEDULE_PER_BOOKING') AS INT);
    IF @RescheduleCount >= @MaxReschedule
    BEGIN
        ROLLBACK;
        THROW 50043, N'Booking đã đạt số lần đổi lịch tối đa cho phép.', 1;
    END

    -- Ràng buộc thời gian đổi lịch
    DECLARE @MinRescheduleHours INT = CAST(dbo.fn_GetConfig('MIN_RESCHEDULE_BEFORE_HOURS') AS INT);
    DECLARE @OldSlotDT DATETIME2;
    SELECT @OldSlotDT = DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', ts.StartTime), CAST(fs.SlotDate AS DATETIME2))
    FROM FieldSlots fs JOIN TimeSlots ts ON fs.SlotId = ts.SlotId
    WHERE fs.FieldSlotId = @OldFieldSlotId;

    IF DATEDIFF(HOUR, SYSDATETIME(), @OldSlotDT) < @MinRescheduleHours
    BEGIN
        ROLLBACK;
        THROW 50044, N'Không thể đổi lịch khi còn quá ít thời gian trước giờ thi đấu.', 1;
    END

    -- Lấy giá slot mới
    DECLARE @NewPrice DECIMAL(12,2);
    SELECT @NewPrice = Price FROM FieldSlots
    WHERE FieldSlotId = @NewFieldSlotId AND StatusId = 1;

    IF @NewPrice IS NULL
    BEGIN
        ROLLBACK;
        THROW 50041, N'Slot mới không tồn tại hoặc không còn trống.', 1;
    END

    -- Tính phí đổi lịch (nếu có)
    DECLARE @RescheduleFee DECIMAL(12,2) = 0;
    DECLARE @RescheduleFeePct DECIMAL(5,2) = dbo.fn_GetConfig('RESCHEDULE_FEE_PERCENT');
    IF @RescheduleFeePct > 0 AND @NewPrice > @OldPrice
        SET @RescheduleFee = CEILING((@NewPrice - @OldPrice) * @RescheduleFeePct / 100);

    -- Trả slot cũ về Trống
    UPDATE FieldSlots SET StatusId = 1, HoldExpireAt = NULL, UpdatedAt = SYSDATETIME()
    WHERE FieldSlotId = @OldFieldSlotId;

    -- Đặt slot mới
    UPDATE FieldSlots SET StatusId = 3, UpdatedAt = SYSDATETIME()
    WHERE FieldSlotId = @NewFieldSlotId AND StatusId = 1;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK;
        THROW 50042, N'Slot mới vừa bị đặt bởi người khác. Vui lòng chọn lại.', 1;
    END

    -- Cập nhật BookingDetail
    UPDATE BookingDetails SET FieldSlotId = @NewFieldSlotId, Price = @NewPrice
    WHERE BookingDetailId = @BookingDetailId;

    -- Tính lại tổng tiền
    DECLARE @PriceDiff DECIMAL(12,2) = @NewPrice - @OldPrice + @RescheduleFee;
    UPDATE Bookings
    SET SubTotal         = SubTotal    + @PriceDiff,
        TotalAmount      = TotalAmount + @PriceDiff,
        RescheduleCount  = RescheduleCount + 1,
        UpdatedAt        = SYSDATETIME()
    WHERE BookingId = @BookingId;

    COMMIT;
END
GO


/* ----------------------------------------------------------------
   SP-10: Xác nhận đơn nhập kho
   Gọi:  EXEC sp_ConfirmPurchaseOrder @PurchaseOrderId=1, @UserId=1
---------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ConfirmPurchaseOrder
    @PurchaseOrderId INT,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;

    IF NOT EXISTS (SELECT 1 FROM PurchaseOrders
                   WHERE PurchaseOrderId = @PurchaseOrderId AND StatusId = 1)
    BEGIN
        ROLLBACK;
        THROW 50030, N'Đơn nhập kho không hợp lệ hoặc đã xử lý.', 1;
    END

    UPDATE p
    SET p.StockQty = p.StockQty + pod.Quantity
    FROM Products p
    JOIN PurchaseOrderDetails pod ON p.ProductId = pod.ProductId
    WHERE pod.PurchaseOrderId = @PurchaseOrderId;

    UPDATE PurchaseOrders
    SET StatusId    = 2,
        TotalAmount = (SELECT SUM(pod.Quantity * pod.UnitPrice)
                       FROM PurchaseOrderDetails pod
                       WHERE pod.PurchaseOrderId = @PurchaseOrderId),
        ConfirmedAt = SYSDATETIME()
    WHERE PurchaseOrderId = @PurchaseOrderId;

    COMMIT;
END
GO


/* ================================================================
   [17] VIEWS
================================================================ */

/* ----------------------------------------------------------------
   VIEW-1: Lịch sân theo ngày
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
    fs.HoldExpireAt,
    -- Còn bao nhiêu giây hold
    CASE WHEN fs.StatusId = 2 AND fs.HoldExpireAt > SYSDATETIME()
         THEN DATEDIFF(SECOND, SYSDATETIME(), fs.HoldExpireAt)
         ELSE NULL END AS HoldRemainingSeconds
FROM FieldSlots fs
JOIN Fields            f   ON fs.FieldId  = f.FieldId
JOIN TimeSlots         ts  ON fs.SlotId   = ts.SlotId
JOIN FieldTypes        ft  ON f.TypeId    = ft.TypeId
JOIN FieldSlotStatuses fss ON fs.StatusId = fss.StatusId
WHERE f.IsDeleted = 0;
GO


/* ----------------------------------------------------------------
   VIEW-2: Lịch sử booking
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
    b.TaxAmount,
    b.TotalAmount,
    b.DepositAmount,
    b.RescheduleCount,
    p.Code           AS PromotionCode,
    b.Note,
    b.CancelReason,
    b.CreatedAt      AS BookingDate,
    b.UpdatedAt,
    bd.BookingDetailId,
    f.FieldId,
    f.Name           AS FieldName,
    ft.Name          AS FieldType,
    ts.StartTime,
    ts.EndTime,
    fs.SlotDate,
    bd.Price         AS SlotPrice,
    pay.Amount       AS PaidAmount,
    pay.PaidAt,
    pm.Name          AS PaymentMethod,
    ps.Name          AS PaymentStatus,
    d.RequiredAmount AS DepositRequired,
    d.PaidAmount     AS DepositPaid,
    ds.Name          AS DepositStatus
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
LEFT JOIN PaymentMethods  pm ON pay.MethodId   = pm.MethodId
LEFT JOIN PaymentStatuses ps ON pay.StatusId   = ps.StatusId
LEFT JOIN Deposits        d  ON b.BookingId    = d.BookingId
LEFT JOIN DepositStatuses ds ON d.StatusId     = ds.StatusId;
GO


/* ----------------------------------------------------------------
   VIEW-3: Booking chờ đặt cọc — Dashboard quản lý
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_PendingDeposits AS
SELECT
    b.BookingId,
    u.FullName    AS CustomerName,
    u.Phone       AS CustomerPhone,
    b.TotalAmount,
    d.RequiredAmount AS DepositRequired,
    d.PaidAmount  AS DepositPaid,
    d.DeadlineAt  AS DepositDeadline,
    DATEDIFF(MINUTE, SYSDATETIME(), d.DeadlineAt) AS MinutesLeft,
    -- Slot sớm nhất trong booking
    MIN(DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', ts.StartTime), CAST(fs.SlotDate AS DATETIME2)))
        AS EarliestSlot,
    b.CreatedAt   AS BookingDate
FROM Bookings b
JOIN Users        u  ON b.UserId      = u.UserId
JOIN Deposits     d  ON b.BookingId   = d.BookingId
JOIN BookingDetails bd ON b.BookingId = bd.BookingId
JOIN FieldSlots   fs ON bd.FieldSlotId = fs.FieldSlotId
JOIN TimeSlots    ts ON fs.SlotId      = ts.SlotId
WHERE b.StatusId  = 5   -- Chờ đặt cọc
  AND d.StatusId  = 1   -- Chưa nộp
GROUP BY b.BookingId, u.FullName, u.Phone, b.TotalAmount,
         d.RequiredAmount, d.PaidAmount, d.DeadlineAt, b.CreatedAt;
GO


/* ----------------------------------------------------------------
   VIEW-4: Doanh thu theo tháng
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
WHERE b.StatusId IN (2, 4)
GROUP BY YEAR(b.CreatedAt), MONTH(b.CreatedAt);
GO


/* ----------------------------------------------------------------
   VIEW-5: Tỷ lệ lấp đầy theo sân và tháng
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_FieldOccupancyByMonth AS
SELECT
    f.FieldId,
    f.Name                        AS FieldName,
    ft.Name                       AS FieldType,
    YEAR(fs.SlotDate)             AS [Year],
    MONTH(fs.SlotDate)            AS [Month],
    COUNT(*)                      AS TotalSlots,
    SUM(CASE WHEN fs.StatusId = 3 THEN 1 ELSE 0 END) AS BookedSlots,
    CAST(
        SUM(CASE WHEN fs.StatusId = 3 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(5,2))              AS OccupancyRate
FROM FieldSlots fs
JOIN Fields     f  ON fs.FieldId = f.FieldId
JOIN FieldTypes ft ON f.TypeId   = ft.TypeId
WHERE f.IsDeleted = 0
GROUP BY f.FieldId, f.Name, ft.Name, YEAR(fs.SlotDate), MONTH(fs.SlotDate);
GO


/* ----------------------------------------------------------------
   VIEW-6: Doanh thu theo dịch vụ
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_RevenueByService AS
SELECT
    s.ServiceId,
    s.Name                           AS ServiceName,
    SUM(bs.Quantity)                 AS TotalQuantitySold,
    SUM(bs.Quantity * bs.UnitPrice)  AS TotalRevenue,
    COUNT(DISTINCT bs.BookingId)     AS TotalBookings
FROM BookingServices bs
JOIN Services  s ON bs.ServiceId = s.ServiceId
JOIN Bookings  b ON bs.BookingId = b.BookingId
WHERE b.StatusId IN (2, 4)
GROUP BY s.ServiceId, s.Name;
GO


/* ----------------------------------------------------------------
   VIEW-7: Sản phẩm sắp hết hàng
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_LowStockProducts AS
SELECT
    p.ProductId, p.Name, p.Unit,
    p.StockQty, p.MinQty,
    p.StockQty - p.MinQty AS StockBuffer
FROM Products p
WHERE p.IsDeleted = 0 AND p.StockQty <= p.MinQty;
GO


/* ----------------------------------------------------------------
   VIEW-8: Rating sân
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_FieldRatings AS
SELECT
    f.FieldId,
    f.Name                          AS FieldName,
    ft.Name                         AS FieldType,
    COUNT(r.ReviewId)               AS TotalReviews,
    CAST(AVG(CAST(r.Rating AS DECIMAL(3,1))) AS DECIMAL(3,1)) AS AvgRating,
    SUM(CASE WHEN r.Rating = 5 THEN 1 ELSE 0 END) AS Stars5,
    SUM(CASE WHEN r.Rating = 4 THEN 1 ELSE 0 END) AS Stars4,
    SUM(CASE WHEN r.Rating = 3 THEN 1 ELSE 0 END) AS Stars3,
    SUM(CASE WHEN r.Rating = 2 THEN 1 ELSE 0 END) AS Stars2,
    SUM(CASE WHEN r.Rating = 1 THEN 1 ELSE 0 END) AS Stars1
FROM Fields f
JOIN FieldTypes ft ON f.TypeId = ft.TypeId
LEFT JOIN Reviews r ON f.FieldId = r.FieldId AND r.IsVisible = 1
WHERE f.IsDeleted = 0
GROUP BY f.FieldId, f.Name, ft.Name;
GO


/* ----------------------------------------------------------------
   VIEW-9: Dashboard tổng quan
---------------------------------------------------------------- */
CREATE OR ALTER VIEW vw_DashboardSummary AS
SELECT
    (SELECT COUNT(*) FROM Bookings WHERE StatusId = 1)
        AS PendingBookings,
    (SELECT COUNT(*) FROM Bookings WHERE StatusId = 5)
        AS PendingDepositBookings,
    (SELECT COUNT(*) FROM Bookings
         WHERE StatusId = 2
           AND CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE))
        AS TodayConfirmed,
    (SELECT COUNT(*) FROM Fields WHERE StatusId = 1 AND IsDeleted = 0)
        AS ActiveFields,
    (SELECT COUNT(*) FROM Fields WHERE StatusId = 2 AND IsDeleted = 0)
        AS MaintenanceFields,
    (SELECT COUNT(*) FROM Incidents WHERE StatusId = 1)
        AS NewIncidents,
    (SELECT ISNULL(SUM(Amount), 0) FROM Payments
         WHERE StatusId = 2
           AND CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE))
        AS TodayRevenue,
    (SELECT COUNT(*) FROM Users WHERE RoleId = 3 AND StatusId = 1)
        AS ActiveCustomers,
    (SELECT COUNT(*) FROM vw_LowStockProducts)
        AS LowStockCount,
    (SELECT COUNT(*) FROM vw_PendingDeposits WHERE MinutesLeft < 30)
        AS UrgentDepositCount;  -- Cọc sắp hết hạn (< 30 phút)
GO


/* ================================================================
   [18] SEED DATA MẪU
================================================================ */

-- Sinh slot 30 ngày tới
DECLARE @Today   DATE = CAST(GETDATE() AS DATE);
DECLARE @EndDate DATE = DATEADD(DAY, 29, @Today);
EXEC sp_GenerateSlots @StartDate = @Today, @EndDate = @EndDate;
GO

-- Voucher mẫu
INSERT INTO Promotions(Code, Name, TypeId, DiscountValue, MaxDiscount,
                       MinOrderAmount, UsageLimit, StartDate, EndDate, CreatedBy)
VALUES
    (N'KHAIMEN10',   N'Giảm 10% khai trương',     1, 10,    50000, 100000, 100,
     CAST(GETDATE() AS DATE), DATEADD(MONTH, 1, CAST(GETDATE() AS DATE)), 1),
    (N'GIAMMANH50K', N'Giảm 50.000đ đơn từ 200k', 2, 50000, NULL,  200000,  50,
     CAST(GETDATE() AS DATE), DATEADD(MONTH, 1, CAST(GETDATE() AS DATE)), 1);
GO

-- Ngày đặc biệt mẫu
INSERT INTO SpecialDays(SpecialDate, Name, PriceMultiplier, IsFullDayPeak, CreatedBy)
VALUES
    (DATEADD(DAY, 7,  CAST(GETDATE() AS DATE)), N'Cuối tuần sự kiện', 1.2, 0, 1),
    (DATEADD(DAY, 14, CAST(GETDATE() AS DATE)), N'Ngày lễ',           1.5, 1, 1);
GO


/* ================================================================
   [19] SQL SERVER AGENT JOBS
================================================================ */

/* ---------------------------------------------------------------
   JOB 1: Giải phóng slot & deposit hết hạn (mỗi 1 phút)
--------------------------------------------------------------- */
-- EXEC msdb.dbo.sp_add_job        @job_name = N'SportPlus - Release Expired Slots';
-- EXEC msdb.dbo.sp_add_jobstep    @job_name = N'SportPlus - Release Expired Slots',
--                                 @step_name = N'Run', @database_name = N'SportPlusDB',
--                                 @command   = N'EXEC sp_ReleaseExpiredSlots';
-- EXEC msdb.dbo.sp_add_schedule   @schedule_name = N'Every1Min',
--                                 @freq_type = 4, @freq_interval = 1,
--                                 @freq_subday_type = 4, @freq_subday_interval = 1;
-- EXEC msdb.dbo.sp_attach_schedule @job_name = N'SportPlus - Release Expired Slots',
--                                  @schedule_name = N'Every1Min';
-- EXEC msdb.dbo.sp_add_jobserver   @job_name = N'SportPlus - Release Expired Slots';

/* ---------------------------------------------------------------
   JOB 2: Sinh slot 30 ngày tới (lúc 00:01 mỗi ngày)
--------------------------------------------------------------- */
-- EXEC msdb.dbo.sp_add_job        @job_name = N'SportPlus - Generate Daily Slots';
-- EXEC msdb.dbo.sp_add_jobstep    @job_name = N'SportPlus - Generate Daily Slots',
--                                 @step_name = N'Run', @database_name = N'SportPlusDB',
--                                 @command   = N'
--                                     DECLARE @S DATE = DATEADD(DAY,29,CAST(GETDATE()AS DATE));
--                                     EXEC sp_GenerateSlots @StartDate=@S, @EndDate=@S;';
-- EXEC msdb.dbo.sp_add_schedule   @schedule_name = N'Daily0001',
--                                 @freq_type = 4, @freq_interval = 1,
--                                 @active_start_time_of_day = 100;
-- EXEC msdb.dbo.sp_attach_schedule @job_name = N'SportPlus - Generate Daily Slots',
--                                  @schedule_name = N'Daily0001';
-- EXEC msdb.dbo.sp_add_jobserver   @job_name = N'SportPlus - Generate Daily Slots';

/* ---------------------------------------------------------------
   Chỉnh cấu hình không cần deploy lại code:

   EXEC sp_UpdateSystemConfig 'DEPOSIT_REQUIRED_PERCENT', '30', @UserId=1;
   EXEC sp_UpdateSystemConfig 'MIN_CANCEL_BEFORE_HOURS',  '4',  @UserId=1;
   EXEC sp_UpdateSystemConfig 'MIN_ADVANCE_BOOKING_HOURS','2',  @UserId=1;
   EXEC sp_UpdateSystemConfig 'DEPOSIT_REQUIRED_PERCENT', '0',  @UserId=1;  -- Tắt bắt buộc cọc
   EXEC sp_UpdateSystemConfig 'TAX_PERCENT',              '10', @UserId=1;  -- Bật VAT 10%
--------------------------------------------------------------- */