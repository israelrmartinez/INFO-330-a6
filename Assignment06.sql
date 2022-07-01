--**********************************************************************************************--
-- Title: Assigment06 
-- Author: IMartinez
-- Desc: This file demonstrates how to design and create; 
--       tables, constraints, views, stored procedures, and permissions
-- Change Log: When,Who,What
-- 2020-05-11,IMartinez,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_IMartinez')
	 Begin 
	  Alter Database [Assignment06DB_IMartinez] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_IMartinez;
	 End
	Create Database Assignment06DB_IMartinez;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_IMartinez;



-- Create Tables (Module 01)-- 
Create Table Courses
(CourseID int IDENTITY(1,1) NOT NULL
,CourseName nvarchar(100) NOT NULL
,CourseStartDate Date
,CourseEndDate Date
,CourseStartTime Time
,CourseEndTime Time
,CourseWeekDays nvarchar(100)
,CourseCurrentPrice Money
);
go

Create -- Drop
Table Students
(StudentID int IDENTITY(1,1) NOT NULL
,StudentNumber nvarchar(100) NOT NULL
,StudentFirstName nvarchar(100) NOT NULL
,StudentLastName nvarchar(100) NOT NULL
,StudentEmail nvarchar(100) NOT NULL
,StudentPhone nvarchar(100)
,StudentAddress1 nvarchar(100) NOT NULL
,StudentAddress2 nvarchar(100)
,StudentCity nvarchar(100) NOT NULL
,StudentStateCode nvarchar(100) NOT NULL
,StudentZipCode nvarchar(100) NOT NULL
);
go

Create Table Enrollments
(EnrollmentID int IDENTITY(1,1) NOT NULL
,StudentID int NOT NULL
,CourseID int NOT NULL
,EnrollmentDateTime Datetime NOT NULL
,EnrollmentPrice Money NOT NULL
);
go



-- Add Constraints (Module 02) --
Alter Table Courses
 Add Constraint pkCourses
  Primary Key (CourseID);
go
Alter Table Courses
 Add Constraint uqCourseName Unique (CourseName)
go
Alter Table Courses
  Add Constraint ckCourseEndDate
    Check (CourseEndDate > CourseStartDate)
go
Alter Table Courses
  Add Constraint ckCourseEndTime
    Check (CourseEndTime > CourseStartTime)
go

Alter Table Students
 Add Constraint pkStudents
  Primary Key (StudentID);
go
Alter Table Students
 Add Constraint uqStudentEmail Unique (StudentEmail)
go
Alter Table Students
  Add Constraint ckStudentPhone
    Check (StudentPhone like '([0-9][0-9][0-9])-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
go
Alter Table Students
  Add Constraint ckStudentZipCode
    Check (StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]' OR
		   StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
go

Alter Table Enrollments
 Add Constraint pkEnrollments
  Primary Key (EnrollmentID);
go
Alter Table Enrollments
  Add Constraint fkStudentID Foreign Key (StudentID)
    References Students(StudentID);
go
Alter Table Enrollments
  Add Constraint fkCourseID Foreign Key (CourseID)
    References Courses(CourseID);
go
Alter Table Enrollments
  Add Constraint dfEnrollmentDateTime Default (GetDate()) For EnrollmentDateTime
go

Create Function dbo.fGetCourseStartDate
(@CourseID int)
Returns datetime
as
 Begin
  Return (Select CourseStartDate
		   From Courses
		    Where Courses.CourseID = @CourseID)
 End
go

Alter Table Enrollments
  Add Constraint ckEnrollmentDateTime
    Check (EnrollmentDateTime < dbo.fGetCourseStartDate(CourseID))
go



-- Add Views (Module 03 and 04) -- 
Create View vCourses
As Select CourseID, CourseName, CourseStartDate, CourseEndDate, CourseStartTime,
		  CourseEndTime, CourseWeekDays, CourseCurrentPrice
From Courses;
go

Create View vStudents
As Select StudentID, StudentNumber, StudentFirstName, StudentLastName, StudentEmail,
		  StudentPhone, StudentAddress1, StudentAddress2, StudentCity, StudentStateCode, 
		  StudentZipCode
From Students;
go

Create View vEnrollments
As Select EnrollmentID, StudentID, CourseID, EnrollmentDateTime, EnrollmentPrice
From Enrollments;
go

Create View vEnrollmentTracker
As
Select Top 100000
 c.CourseName as Course,
 Concat(Convert(varchar, c.CourseStartDate, 101), ' to ', Convert(varchar, c.CourseEndDate, 101)) as Dates, 
 Cast(c.CourseStartTime as time(0)) as [Start],
 Cast(c.CourseEndTime as time(0)) as [End],
 c.CourseWeekDays as [Days],
 c.CourseCurrentPrice as Price,
 s.StudentFirstName + ' ' + s.StudentLastName as Student,
 s.StudentNumber as Number,
 s.StudentEmail as Email,
 s.StudentPhone as Phone,
 Concat(s.StudentAddress1, ' ', s.StudentCity, ', ', s.StudentStateCode, '.,', s.StudentZipCode) as [Address],
 Convert(varchar, e.EnrollmentDateTime, 101) as [Signup Date],
 e.EnrollmentPrice as Paid
From Enrollments as e
 Join Students as s
  on e.StudentID = s.StudentID
 Join Courses as c
  on e.CourseID = c.CourseID
Group By c.CourseName, c.CourseStartDate, c.CourseEndDate, c.CourseStartTime, c.CourseEndTime,
		c.CourseWeekDays, c.CourseCurrentPrice, s.StudentFirstName, s.StudentLastName, s.StudentNumber,
		s.StudentEmail, s.StudentPhone, s.StudentAddress1, s.StudentCity, s.StudentStateCode,  s.StudentZipCode,
		e.EnrollmentDateTime, e.EnrollmentPrice
Order By c.CourseStartDate;
go



-- Add Stored Procedures (Module 04 and 05) --

-- INSERTS --
Create Procedure pInsCourses
(@CourseName nvarchar(100), @CourseStartDate Date, @CourseEndDate Date, @CourseStartTime Time,
 @CourseEndTime Time, @CourseWeekDays nvarchar(100), @CourseCurrentPrice Money)
/* Author: IMartinez
** Desc: Processes Inserts for Courses table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Insert Into Courses (CourseName, CourseStartDate, CourseEndDate, CourseStartTime,
						CourseEndTime, CourseWeekDays, CourseCurrentPrice) 
	Values(@CourseName, @CourseStartDate, @CourseEndDate, @CourseStartTime, @CourseEndTime,
		   @CourseWeekDays, @CourseCurrentPrice);
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pInsStudents
(@StudentNumber nvarchar(100), @StudentFirstName nvarchar(100), @StudentLastName nvarchar(100), 
@StudentEmail nvarchar(100), @StudentPhone nvarchar(100), @StudentAddress1 nvarchar(100), 
@StudentCity nvarchar(100), @StudentStateCode nvarchar(100), @StudentZipCode nvarchar(100))
/* Author: IMartinez
** Desc: Processes Inserts for Students table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Insert Into Students (StudentNumber, StudentFirstName, StudentLastName, StudentEmail,
					    StudentPhone, StudentAddress1, StudentCity, 
						StudentStateCode, StudentZipCode)
	Values (@StudentNumber, @StudentFirstName, @StudentLastName, @StudentEmail, @StudentPhone, 
			@StudentAddress1, @StudentCity, @StudentStateCode, @StudentZipCode);
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pInsEnrollments
(@StudentID int, @CourseID int, @EnrollmentDateTime Datetime, @EnrollmentPrice Money)
/* Author: IMartinez
** Desc: Processes Inserts for Enrollments table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Insert Into Enrollments(StudentID, CourseID, EnrollmentDateTime, EnrollmentPrice)
	Values (@StudentID, @CourseID, @EnrollmentDateTime, @EnrollmentPrice);
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go


-- UPDATES --
Create Procedure pUpdCourses
(@CourseID int, @CourseName nvarchar(100), @CourseStartDate Date, @CourseEndDate Date, 
@CourseStartTime Time, @CourseEndTime Time, @CourseWeekDays nvarchar(100), @CourseCurrentPrice Money)
/* Author: IMartinez
** Desc: Processes updates for Courses table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Update Courses 
	 Set CourseName = @CourseName,
	     CourseStartDate = @CourseStartDate,
		 CourseEndDate = @CourseEndDate,
		 CourseStartTime = @CourseStartTime,
		 CourseEndTime = @CourseEndTime,
		 CourseWeekDays = @CourseWeekDays,
		 CourseCurrentPrice = @CourseCurrentPrice 
	 Where CourseID = @CourseID
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pUpdStudents
(@StudentID int, @StudentNumber nvarchar(100), @StudentFirstName nvarchar(100), @StudentLastName nvarchar(100), 
@StudentEmail nvarchar(100), @StudentPhone nvarchar(100), @StudentAddress1 nvarchar(100),
@StudentCity nvarchar(100), @StudentStateCode nvarchar(100), @StudentZipCode nvarchar(100))
/* Author: IMartinez
** Desc: Processes updates for Students table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Update Students 
	 Set StudentNumber = @StudentNumber, 
	     StudentFirstName = @StudentFirstName, 
		 StudentLastName = @StudentLastName, 
		 StudentEmail = @StudentEmail,
		 StudentPhone = @StudentPhone,
		 StudentAddress1 = @StudentAddress1, 
		 StudentCity = @StudentCity,
		 StudentStateCode = @StudentStateCode,
		 StudentZipCode = @StudentZipCode
	 Where StudentID = @StudentID;
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pUpdEnrollments
(@EnrollmentID int, @StudentID int, @CourseID int, @EnrollmentDateTime Datetime, @EnrollmentPrice Money)
/* Author: IMartinez
** Desc: Processes updates for Enrollments table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Update Enrollments 
	 Set StudentID = @StudentID,
		 CourseID = @CourseID,
		 EnrollmentDateTime = @EnrollmentDateTime,
		 EnrollmentPrice = @EnrollmentPrice
	 Where EnrollmentID = @EnrollmentID;
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go


-- DELETES --
Create Procedure pDelCourses
(@CourseID int)
/* Author: IMartinez
** Desc: Processes Deletes for Courses table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Delete From Courses Where CourseID = @CourseID
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pDelStudents
(@StudentID int)
/* Author: IMartinez
** Desc: Processes Deletes for Students table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Delete From Students 
	Where StudentID = @StudentID
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go

Create Procedure pDelEnrollments
(@EnrollmentID int)
/* Author: IMartinez
** Desc: Processes Deletes for Enrollments table
** Change Log: When,Who,What
** 2020-05-11,IMartinez,Created Sproc.
*/
AS
 Begin -- Body
  Declare @RC int = 0;
  Begin Try
   Begin Transaction; 
    -- Transaction Code --
	Delete From Enrollments 
	Where EnrollmentID = @EnrollmentID
   Commit Transaction;
   Set @RC = +1;
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction;
   Print Error_Message();
   Set @RC = -1
  End Catch
  Return @RC;
 End -- Body
go



-- Set Permissions (Module 06) --
Deny Select, Insert, Update, Delete On Courses To Public;
Deny Select, Insert, Update, Delete On Students To Public;
Deny Select, Insert, Update, Delete On Enrollments To Public;

Grant Select On vCourses To Public;
Grant Select On vStudents To Public;
Grant Select On vEnrollments To Public;

Grant Execute On pInsCourses To Public;
Grant Execute On pInsStudents To Public;
Grant Execute On pInsEnrollments To Public;

Grant Execute On pUpdCourses To Public;
Grant Execute On pUpdStudents To Public;
Grant Execute On pUpdEnrollments To Public;

Grant Execute On pDelCourses To Public;
Grant Execute On pDelStudents To Public;
Grant Execute On pDelEnrollments To Public;



--< Test Views and Sprocs >-- 

-- Courses
Declare @Status int;
Exec @Status = pInsCourses @CourseName = 'SQL1 - Winter 2017',
						  @CourseStartDate = '1/10/2017',
						  @CourseEndDate = '1/24/2017',
						  @CourseStartTime = '6:00:00',
						  @CourseEndTime = '8:50:00',
						  @CourseWeekDays = 'T', 
						  @CourseCurrentPrice = '399';
Print @Status;
go

Declare @Status int;
Exec @Status = pInsCourses @CourseName = 'SQL2 - Winter 2017',
						  @CourseStartDate = '1/31/2017',
						  @CourseEndDate = '2/14/2017',
						  @CourseStartTime = '6:00:00',
						  @CourseEndTime = '8:50:00',
						  @CourseWeekDays = 'T', 
						  @CourseCurrentPrice = '399';
Print @Status;
go


-- Students
Declare @Status int;
Exec @Status = pInsStudents @StudentNumber = 'B-Smith-071',
							@StudentFirstName = 'Bob',
							@StudentLastName = 'Smith',
							@StudentEmail = 'Bsmith@HipMail.com', 
							@StudentPhone = '(206)-111-2222', 
							@StudentAddress1 = '123 Main St.', 
							@StudentCity = 'Seattle', 
							@StudentStateCode = 'WA', 
							@StudentZipCode = '98001';
Print @Status;
go

Declare @Status int;
Exec @Status = pInsStudents @StudentNumber = 'S-Jones-003',
							@StudentFirstName = 'Sue',
							@StudentLastName = 'Jones',
							@StudentEmail = 'SueJones@YaYou.com', 
							@StudentPhone = '(206)-231-4321', 
							@StudentAddress1 = '333 1st Ave.', 
							@StudentCity = 'Seattle', 
							@StudentStateCode = 'WA', 
							@StudentZipCode = '98001';
Print @Status;
go


-- Enrollments
Declare @Status int;
Exec @Status = pInsEnrollments @StudentID = '1',
							   @CourseID = '1', 
							   @EnrollmentDateTime = '1/3/2017', 
							   @EnrollmentPrice = '399';
Print @Status;
go

Declare @Status int;
Exec @Status = pInsEnrollments @StudentID = '2',
							   @CourseID = '1', 
							   @EnrollmentDateTime = '12/14/2016', 
							   @EnrollmentPrice = '349';
Print @Status;
go

Declare @Status int;
Exec @Status = pInsEnrollments @StudentID = '1',
							   @CourseID = '2', 
							   @EnrollmentDateTime = '1/12/2017', 
							   @EnrollmentPrice = '399';
Print @Status;
go

Declare @Status int;
Exec @Status = pInsEnrollments @StudentID = '2',
							   @CourseID = '2', 
							   @EnrollmentDateTime = '12/14/2016', 
							   @EnrollmentPrice = '349';
Print @Status;
go

Select * From vCourses
go
Select * From vStudents
go
Select * From vEnrollments
go

Select * From vEnrollmentTracker
go
--{ IMPORTANT }--
-- To get full credit, your script must run without having to highlight individual statements!!!  
/**************************************************************************************************/