/* ================================
   RESET DATABASE OBJECTS
================================ */
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
   FUNCTION: AUTO GENERATE CODE
   Format: PREFIX + YYYYMMDD + 4 digits
================================ */
DROP FUNCTION IF EXISTS fn_GenerateCode;
GO

CREATE FUNCTION fn_GenerateCode(@Prefix NVARCHAR(10))
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Code NVARCHAR(50);
    DECLARE @Date NVARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112);
    DECLARE @Rand NVARCHAR(4) = RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR),4);

    SET @Code = @Prefix + '-' + @Date + '-' + @Rand;
    RETURN @Code;
END
GO

/* ================================
   LOOKUP TABLES (TRÁNH HARDCODE)
================================ */
DROP TABLE IF EXISTS Roles;
CREATE TABLE Roles(
    RoleId INT IDENTITY PRIMARY KEY,
    RoleName NVARCHAR(50),
    IsDeleted BIT DEFAULT 0
);
GO

DROP TABLE IF EXISTS BookingStatus;
CREATE TABLE BookingStatus(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

DROP TABLE IF EXISTS PaymentMethod;
CREATE TABLE PaymentMethod(
    MethodId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

DROP TABLE IF EXISTS PaymentStatus;
CREATE TABLE PaymentStatus(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

/* ================================
   USERS
================================ */
DROP TABLE IF EXISTS Users;
CREATE TABLE Users(
    UserId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('USR'),
    FullName NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE,
    Phone NVARCHAR(20),
    PasswordHash NVARCHAR(255),
    RoleId INT,
    Status BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY(RoleId) REFERENCES Roles(RoleId)
);
GO

/* ================================
   FIELDS & TIMESLOTS
================================ */
DROP TABLE IF EXISTS Fields;
CREATE TABLE Fields(
    FieldId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('FLD'),
    FieldName NVARCHAR(100),
    FieldType NVARCHAR(50),
    PricePerHour DECIMAL(10,2),
    Status BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0
);
GO

DROP TABLE IF EXISTS TimeSlots;
CREATE TABLE TimeSlots(
    SlotId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('SLOT'),
    StartTime TIME,
    EndTime TIME,
    IsDeleted BIT DEFAULT 0,

    CONSTRAINT CK_Time CHECK (StartTime < EndTime)
);
GO

/* ================================
   BOOKINGS
================================ */
DROP TABLE IF EXISTS Bookings;
CREATE TABLE Bookings(
    BookingId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('BKG'),
    UserId INT,
    BookingDate DATE,
    TotalAmount DECIMAL(10,2) DEFAULT 0,
    StatusId INT,
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY(UserId) REFERENCES Users(UserId),
    FOREIGN KEY(StatusId) REFERENCES BookingStatus(StatusId)
);
GO

DROP TABLE IF EXISTS BookingDetails;
CREATE TABLE BookingDetails(
    BookingDetailId INT IDENTITY PRIMARY KEY,
    BookingId INT,
    FieldId INT,
    SlotId INT,
    BookingDate DATE,
    Price DECIMAL(10,2),
    IsDeleted BIT DEFAULT 0,

    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(FieldId) REFERENCES Fields(FieldId),
    FOREIGN KEY(SlotId) REFERENCES TimeSlots(SlotId),

    -- TRÁNH TRÙNG LỊCH
    CONSTRAINT UQ_FieldSlot UNIQUE(FieldId, SlotId, BookingDate)
);
GO

/* ================================
   SERVICES
================================ */
DROP TABLE IF EXISTS Services;
CREATE TABLE Services(
    ServiceId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('SER'),
    ServiceName NVARCHAR(100),
    Price DECIMAL(10,2),
    IsDeleted BIT DEFAULT 0
);
GO

DROP TABLE IF EXISTS BookingServices;
CREATE TABLE BookingServices(
    Id INT IDENTITY PRIMARY KEY,
    BookingId INT,
    ServiceId INT,
    Quantity INT,
    Price DECIMAL(10,2),
    IsDeleted BIT DEFAULT 0,

    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(ServiceId) REFERENCES Services(ServiceId)
);
GO

/* ================================
   PAYMENTS
================================ */
DROP TABLE IF EXISTS Payments;
CREATE TABLE Payments(
    PaymentId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(20) DEFAULT dbo.fn_GenerateCode('PAY'),
    BookingId INT,
    Amount DECIMAL(10,2),
    MethodId INT,
    StatusId INT,
    PaidAt DATETIME,
    IsDeleted BIT DEFAULT 0,

    FOREIGN KEY(BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY(MethodId) REFERENCES PaymentMethod(MethodId),
    FOREIGN KEY(StatusId) REFERENCES PaymentStatus(StatusId)
);
GO

/* ================================
   TRIGGER: AUTO UPDATE TOTAL
================================ */
DROP TRIGGER IF EXISTS trg_UpdateBookingTotal;
GO

CREATE TRIGGER trg_UpdateBookingTotal
ON BookingDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE B
    SET TotalAmount = ISNULL((
        SELECT SUM(Price)
        FROM BookingDetails BD
        WHERE BD.BookingId = B.BookingId AND BD.IsDeleted = 0
    ),0)
    FROM Bookings B;
END
GO

/* ================================
   SOFT DELETE TRIGGER
================================ */
DROP TRIGGER IF EXISTS trg_SoftDelete_Users;
GO
CREATE TRIGGER trg_SoftDelete_Users
ON Users
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Users SET IsDeleted = 1
    WHERE UserId IN (SELECT UserId FROM deleted);
END
GO

/* ================================
   VIEW: ACTIVE DATA
================================ */
DROP VIEW IF EXISTS v_Bookings;
GO

CREATE VIEW v_Bookings AS
SELECT *
FROM Bookings
WHERE IsDeleted = 0;
GO

/* ================================
   INDEX (TỐI ƯU)
================================ */
CREATE INDEX IX_Booking_User ON Bookings(UserId);
CREATE INDEX IX_Booking_Date ON Bookings(BookingDate);
GO

/* ================================
   SEED DATA
================================ */
INSERT INTO Roles(RoleName) VALUES
('Admin'),('Staff'),('Customer');

INSERT INTO BookingStatus(Name) VALUES
('Pending'),('Paid'),('Cancelled');

INSERT INTO PaymentMethod(Name) VALUES
('Cash'),('Momo'),('VNPay');

INSERT INTO PaymentStatus(Name) VALUES
('Pending'),('Completed');

INSERT INTO Users(FullName, Email, RoleId)
VALUES
(N'Admin', 'admin@gmail.com',1),
(N'Khách A', 'a@gmail.com',3);

INSERT INTO Fields(FieldName, FieldType, PricePerHour)
VALUES
(N'Sân 1','5 người',200000),
(N'Sân 2','7 người',300000);

INSERT INTO TimeSlots(StartTime, EndTime)
VALUES
('08:00','09:00'),
('09:00','10:00');

INSERT INTO Services(ServiceName, Price)
VALUES
(N'Nước suối',10000),
(N'Thuê bóng',50000);

GO