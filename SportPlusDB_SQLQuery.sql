/* ================================
   RESET DB
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
   LOOKUP TABLES
================================ */
CREATE TABLE Roles(
    RoleId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('ROLE-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
    RoleName NVARCHAR(50),
    IsDeleted BIT DEFAULT 0
);
GO

CREATE TABLE BookingStatus(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

CREATE TABLE PaymentMethod(
    MethodId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

CREATE TABLE PaymentStatus(
    StatusId INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

/* ================================
   USERS
================================ */
CREATE TABLE Users(
    UserId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('USR-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
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
   FIELDS
================================ */
CREATE TABLE Fields(
    FieldId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('FLD-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
    FieldName NVARCHAR(100),
    FieldType NVARCHAR(50),
    PricePerHour DECIMAL(10,2),
    Status BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0
);
GO

/* ================================
   TIMESLOTS
================================ */
CREATE TABLE TimeSlots(
    SlotId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('SLOT-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
    StartTime TIME,
    EndTime TIME,
    IsDeleted BIT DEFAULT 0,

    CONSTRAINT CK_Time CHECK (StartTime < EndTime)
);
GO

/* ================================
   BOOKINGS
================================ */
CREATE TABLE Bookings(
    BookingId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('BKG-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
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

/* ================================
   BOOKING DETAILS
================================ */
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

    CONSTRAINT UQ_FieldSlot UNIQUE(FieldId, SlotId, BookingDate)
);
GO

/* ================================
   SERVICES
================================ */
CREATE TABLE Services(
    ServiceId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('SER-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
    ServiceName NVARCHAR(100),
    Price DECIMAL(10,2),
    IsDeleted BIT DEFAULT 0
);
GO

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
CREATE TABLE Payments(
    PaymentId INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(50) DEFAULT ('PAY-' + LEFT(CONVERT(VARCHAR(36), NEWID()),8)),
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
   TRIGGER: AUTO TOTAL
================================ */
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
   SOFT DELETE USERS
================================ */
CREATE TRIGGER trg_SoftDelete_Users
ON Users
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Users
    SET IsDeleted = 1
    WHERE UserId IN (SELECT UserId FROM deleted);
END
GO

/* ================================
   VIEW
================================ */
CREATE VIEW v_Bookings AS
SELECT * FROM Bookings WHERE IsDeleted = 0;
GO

/* ================================
   INDEX
================================ */
CREATE INDEX IX_Booking_User ON Bookings(UserId);
CREATE INDEX IX_Booking_Date ON Bookings(BookingDate);
GO

/* ================================
   SEED DATA
================================ */
INSERT INTO Roles(RoleName) VALUES ('Admin'),('Staff'),('Customer');

INSERT INTO BookingStatus(Name) VALUES ('Pending'),('Paid'),('Cancelled');

INSERT INTO PaymentMethod(Name) VALUES ('Cash'),('Momo'),('VNPay');

INSERT INTO PaymentStatus(Name) VALUES ('Pending'),('Completed');

INSERT INTO Users(FullName, Email, RoleId)
VALUES (N'Admin','admin@gmail.com',1);

INSERT INTO Fields(FieldName, FieldType, PricePerHour)
VALUES (N'Sân 1','5 người',200000);

INSERT INTO TimeSlots(StartTime, EndTime)
VALUES ('08:00','09:00');
GO