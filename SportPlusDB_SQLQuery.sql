/* ================================
RESET DATABASE
================================ */
USE master;
GO
IF DB_ID('SportPlusDB') IS NOT NULL
BEGIN
    ALTER DATABASE SportPlusDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SportPlusDB;
END
GO

CREATE DATABASE SportPlusDB;
GO
USE SportPlusDB;
GO

/* ================================
MASTER TABLES
================================ */
CREATE TABLE UserStatuses(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE BookingStatuses(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE PaymentStatuses(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE FieldStatuses(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE FieldSlotStatuses(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL
);

/* ================================
SEED DATA (TIẾNG VIỆT)
================================ */
INSERT INTO UserStatuses(Name)
VALUES (N'Hoạt động'), (N'Bị khóa');

INSERT INTO BookingStatuses(Name)
VALUES (N'Chờ thanh toán'), (N'Đã xác nhận'), (N'Đã hủy');

INSERT INTO PaymentStatuses(Name)
VALUES (N'Chưa thanh toán'), (N'Đã thanh toán'), (N'Thất bại');

INSERT INTO FieldStatuses(Name)
VALUES (N'Hoạt động'), (N'Bảo trì');

INSERT INTO FieldSlotStatuses(Name)
VALUES (N'Trống'), (N'Đang giữ'), (N'Đã đặt');

/* ================================
USERS
================================ */
CREATE TABLE Users(
    UserId INT IDENTITY PRIMARY KEY,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,

    StatusId INT NOT NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    RowVer ROWVERSION,
    IsDeleted BIT DEFAULT 0,

    CONSTRAINT UQ_Email UNIQUE(Email),
    CONSTRAINT UQ_Phone UNIQUE(Phone),

    FOREIGN KEY(StatusId) REFERENCES UserStatuses(StatusId)
);

/* ================================
FIELDS
================================ */
CREATE TABLE Fields(
    FieldId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100),
    BasePrice DECIMAL(10,2),

    StatusId INT,
    IsDeleted BIT DEFAULT 0,

    FOREIGN KEY(StatusId) REFERENCES FieldStatuses(StatusId)
);

/* ================================
TIME SLOT
================================ */
CREATE TABLE TimeSlots(
    SlotId INT IDENTITY PRIMARY KEY,
    StartTime TIME,
    EndTime TIME,
    CONSTRAINT UQ_Time UNIQUE(StartTime, EndTime)
);

/* ================================
PEAK PRICING
================================ */
CREATE TABLE PeakPricingRules(
    RuleId INT IDENTITY PRIMARY KEY,
    DayOfWeek INT, -- 1=Monday
    StartTime TIME,
    EndTime TIME,
    Multiplier DECIMAL(5,2)
);

/* ================================
FIELD SLOT
================================ */
CREATE TABLE FieldSlots(
    FieldSlotId INT IDENTITY PRIMARY KEY,
    FieldId INT,
    SlotId INT,
    SlotDate DATE,

    Price DECIMAL(10,2),

    StatusId INT DEFAULT 1, -- Trống
    HoldExpireAt DATETIME2 NULL,

    FOREIGN KEY(FieldId) REFERENCES Fields(FieldId),
    FOREIGN KEY(SlotId) REFERENCES TimeSlots(SlotId),
    FOREIGN KEY(StatusId) REFERENCES FieldSlotStatuses(StatusId),

    CONSTRAINT UQ_FieldSlot UNIQUE(FieldId, SlotId, SlotDate)
);

CREATE INDEX IX_FieldSlots_Search
ON FieldSlots(FieldId, SlotDate, StatusId);

/* ================================
BOOKINGS
================================ */
CREATE TABLE Bookings(
    BookingId INT IDENTITY PRIMARY KEY,
    UserId INT,
    StatusId INT,
    TotalAmount DECIMAL(10,2),
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),

    FOREIGN KEY(UserId) REFERENCES Users(UserId),
    FOREIGN KEY(StatusId) REFERENCES BookingStatuses(StatusId)
);

CREATE INDEX IX_Bookings_UserId ON Bookings(UserId);

/* ================================
BOOKING DETAILS
================================ */
CREATE TABLE BookingDetails(
    BookingDetailId INT IDENTITY PRIMARY KEY,
    BookingId INT,
    FieldSlotId INT,
    Price DECIMAL(10,2),

    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(FieldSlotId) REFERENCES FieldSlots(FieldSlotId),

    CONSTRAINT UQ_Slot UNIQUE(FieldSlotId)
);

CREATE INDEX IX_BookingDetails_BookingId ON BookingDetails(BookingId);

/* ================================
PAYMENTS
================================ */
CREATE TABLE Payments(
    PaymentId INT IDENTITY PRIMARY KEY,
    BookingId INT,
    Amount DECIMAL(10,2),
    StatusId INT,
    Method NVARCHAR(50),
    TransactionCode NVARCHAR(100),
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),

    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(StatusId) REFERENCES PaymentStatuses(StatusId)
);
GO

CREATE INDEX IX_Payments_BookingId ON Payments(BookingId);
GO

/* ================================
SEED TIME SLOTS
================================ */
INSERT INTO TimeSlots(StartTime, EndTime)
VALUES 
('06:00','07:00'),('07:00','08:00'),
('08:00','09:00'),('09:00','10:00'),
('17:00','18:00'),('18:00','19:00'),
('19:00','20:00'),('20:00','21:00');
GO

/* ================================
SEED FIELDS
================================ */
INSERT INTO Fields(Name, BasePrice, StatusId)
VALUES 
(N'Sân 1', 200000, 1),
(N'Sân 2', 200000, 1);
GO

/* ================================
GENERATE SLOTS
================================ */
CREATE PROCEDURE sp_GenerateSlots
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET DATEFIRST 1; -- Monday

    DECLARE @Date DATE = @StartDate;

    WHILE @Date <= @EndDate
    BEGIN
        INSERT INTO FieldSlots(FieldId, SlotId, SlotDate, Price)
        SELECT 
            f.FieldId,
            ts.SlotId,
            @Date,
            f.BasePrice * ISNULL(p.Multiplier, 1)
        FROM Fields f
        CROSS JOIN TimeSlots ts
        OUTER APPLY (
            SELECT TOP 1 Multiplier
            FROM PeakPricingRules p
            WHERE p.DayOfWeek = DATEPART(WEEKDAY, @Date)
            AND ts.StartTime BETWEEN p.StartTime AND p.EndTime
        ) p
        WHERE NOT EXISTS (
            SELECT 1 FROM FieldSlots fs
            WHERE fs.FieldId = f.FieldId
            AND fs.SlotId = ts.SlotId
            AND fs.SlotDate = @Date
        );

        SET @Date = DATEADD(DAY, 1, @Date);
    END
END
GO

/* ================================
HOLD SLOT (ANTI RACE CONDITION)
================================ */
CREATE PROCEDURE sp_HoldSlots
    @FieldSlotIds NVARCHAR(MAX)
AS
BEGIN
    SET XACT_ABORT ON;
    BEGIN TRAN;

    ;WITH ids AS (
        SELECT CAST(value AS INT) AS Id
        FROM STRING_SPLIT(@FieldSlotIds, ',')
    )
    UPDATE fs
    SET StatusId = 2,
        HoldExpireAt = DATEADD(MINUTE, 5, SYSDATETIME())
    FROM FieldSlots fs WITH (UPDLOCK, HOLDLOCK)
    JOIN ids i ON fs.FieldSlotId = i.Id
    WHERE fs.StatusId = 1;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK;
        THROW 50001, N'Slot không khả dụng', 1;
    END

    COMMIT;
END
GO

/* ================================
CONFIRM BOOKING
================================ */
CREATE PROCEDURE sp_ConfirmBooking
    @BookingId INT,
    @FieldSlotIds NVARCHAR(MAX)
AS
BEGIN
    SET XACT_ABORT ON;
    BEGIN TRAN;

    DECLARE @BookedStatus INT = (SELECT StatusId FROM FieldSlotStatuses WHERE Name = N'Đã đặt');

    ;WITH ids AS (
        SELECT CAST(value AS INT) AS Id
        FROM STRING_SPLIT(@FieldSlotIds, ',')
    )
    UPDATE fs
    SET StatusId = @BookedStatus,
        HoldExpireAt = NULL
    FROM FieldSlots fs
    JOIN ids i ON fs.FieldSlotId = i.Id
    WHERE fs.StatusId = 2
    AND fs.HoldExpireAt >= SYSDATETIME();

    INSERT INTO BookingDetails(BookingId, FieldSlotId, Price)
    SELECT @BookingId, FieldSlotId, Price
    FROM FieldSlots
    WHERE FieldSlotId IN (SELECT Id FROM ids);

    UPDATE Bookings
    SET TotalAmount = (
        SELECT SUM(Price)
        FROM BookingDetails
        WHERE BookingId = @BookingId
    ),
    StatusId = (SELECT StatusId FROM BookingStatuses WHERE Name = N'Đã xác nhận')
    WHERE BookingId = @BookingId;

    COMMIT;
END
GO

/* ================================
CANCEL BOOKING
================================ */
CREATE PROCEDURE sp_CancelBooking
    @BookingId INT
AS
BEGIN
    SET XACT_ABORT ON;
    BEGIN TRAN;

    DECLARE @EmptyStatus INT = (SELECT StatusId FROM FieldSlotStatuses WHERE Name = N'Trống');

    UPDATE fs
    SET StatusId = @EmptyStatus,
        HoldExpireAt = NULL
    FROM FieldSlots fs
    JOIN BookingDetails bd ON fs.FieldSlotId = bd.FieldSlotId
    WHERE bd.BookingId = @BookingId;

    UPDATE Bookings
    SET StatusId = (SELECT StatusId FROM BookingStatuses WHERE Name = N'Đã hủy')
    WHERE BookingId = @BookingId;

    COMMIT;
END
GO

/* ================================
RELEASE HOLD
================================ */
CREATE PROCEDURE sp_ReleaseExpiredSlots
AS
BEGIN
    DECLARE @EmptyStatus INT = (SELECT StatusId FROM FieldSlotStatuses WHERE Name = N'Trống');

    UPDATE FieldSlots
    SET StatusId = @EmptyStatus,
        HoldExpireAt = NULL
    WHERE StatusId = 2
    AND HoldExpireAt < SYSDATETIME();
END
GO