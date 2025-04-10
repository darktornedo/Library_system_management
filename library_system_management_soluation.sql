-- create database 
CREATE DATABASE library_database;

-- create table "branch"
CREATE TABLE branch (
branch_id VARCHAR(10) PRIMARY KEY,
manager_id VARCHAR(10),
branch_address VARCHAR(30),
contact_no VARCHAR(15)
);

-- craete table "employee"
CREATE TABLE employees (
emp_id VARCHAR(10) PRIMARY KEY,
emp_name VARCHAR(30),
position VARCHAR(30),
salary DECIMAL(10,2),
branch_id VARCHAR(10),
FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);

-- create table "members"
CREATE TABLE members (
member_id VARCHAR(10) PRIMARY KEY,
member_name VARCHAR(30),
member_address VARCHAR(30),
reg_date DATE
);

-- create table "Books"
CREATE TABLE books (
isbn VARCHAR(50) PRIMARY KEY,
book_title VARCHAR(80),
category VARCHAR(30),
rental_price DECIMAL(10,2),
status VARCHAR(10),
author VARCHAR(30),
publisher VARCHAR(30)
);

-- create table "Issuestatus"
CREATE TABLE issued_status (
issued_id VARCHAR(10) PRIMARY KEY,
issued_member_id VARCHAR(30),
issued_book_name VARCHAR(80),
issued_date DATE,
issued_book_isbn VARCHAR(50),
issued_emp_id VARCHAR(10),
FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);

-- create table "Returnstatus"
CREATE TABLE return_status (
return_id VARCHAR(10) PRIMARY KEY,
issued_id VARCHAR(30),
return_book_name VARCHAR(80),
return_date DATE,
return_book_isbn VARCHAR(50),
FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

/* Import all the csv files using Table Data Import Wizard first select the source of the csv file then select whether 
you want to make a new table or import the data into already exist table then it will automatilcally import your csv file into Mysql*/

-- CRUD Operations 

-- Task 1 Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.
INSERT INTO books 
(isbn, book_title, category, rental_price, status, author, publisher)
VALUES 
("978-1-60129-456-2", 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co');

-- Task 2: Update an Existing Member's Address.
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
SET SQL_SAFE_UPDATES = 0;
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_member_id, COUNT(*) as total_book_issue
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*)>1;

-- CTAS (Create Table As Select)

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt. 
CREATE TABLE book_issue_count AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) as issue_count
FROM books as b 
JOIN issued_status as ist 
ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn, b.book_title
ORDER BY issue_count DESC;

-- Data Analysis and Business key problems & answers 

-- Task 7. Retrieve All Books in a Specific Category. 
SELECT * FROM books 
WHERE category = 'classic';

-- Task 8: Find Total Rental Income by Category.
SELECT category, SUM(rental_price) as total_rental_price, COUNT(ist.issued_book_isbn) issue_count
FROM books as b
JOIN issued_status as ist
ON b.isbn = ist.issued_book_isbn
GROUP BY category
ORDER BY total_rental_price DESC;

-- Task 9: List Members Who Registered in the Last 180 Days. 
SELECT *
FROM members 
WHERE reg_date >= curdate() - INTERVAL 180 DAY ;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details. 
SELECT e.emp_id as emploee_id, e.emp_name as employee_name, b.*, e1.emp_name as manager_nane
FROM branch as b 
JOIN employees as e ON b.branch_id = e.branch_id
JOIN employees as e1 ON b.manager_id = e1.emp_id ;

-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold. 
CREATE TABLE Expensive_books AS 
SELECT * FROM books 
WHERE rental_price >7.00;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT ist.*
FROM issued_status as ist
LEFT JOIN return_status as r ON ist.issued_id = r.issued_id 
WHERE r.issued_id IS NULL;

-- Advanced SQL Operations

/*Task 13: Identify Members with Overdue Books 
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.*/

SELECT m.member_id, m.member_name,b.book_title, ist.issued_date, CURDATE() - ist.issued_date as overdue_days
FROM members as m 
JOIN issued_status as ist on m.member_id = ist.issued_member_id 
JOIN books as b ON ist.issued_book_isbn = b.isbn
LEFT JOIN return_status as r ON ist.issued_id = r.issued_id 
WHERE DATEDIFF(CURDATE(),ist.issued_date) >30  AND r.return_date IS NULL
ORDER BY overdue_days DESC ;

/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/

DELIMITER //
CREATE PROCEDURE add_return_records (p_return_id VARCHAR(10), p_issued_id VARCHAR(30), p_book_quanlity VARCHAR(20))
BEGIN 
DECLARE 
v_isbn VARCHAR(50);
  DECLARE 
  v_book_name VARCHAR(80);
INSERT INTO return_status (return_id, issued_id, return_date, book_quanlity)
  VALUES 
  (p_return_id, p_issued_id,current_date(), p_book_quanlity);
  
  SELECT 
    issued_book_isbn,
    issued_book_name
    INTO 
    v_isbn,
    v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;
    
    UPDATE books
    SET status ='Yes'
    WHERE isbn = v_isbn;
    
END //

DELIMITER ;

-- Testing functions and add records (you can select any isbn)
SELECT * FROM books 
WHERE isbn = '978-0-375-41398-8';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-375-41398-8';

SELECT * FROM return_status 
WHERE issued_id = 'IS134';

-- calling the store procedure 
CALL add_return_records ('RS121', 'IS134','Good');

/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books 
returned, and the total revenue generated from book rentals.*/

WITH branch_reports AS (
SELECT b.branch_id, COUNT(ist.issued_id) as num_of_books_issued,
COUNT(r.return_id) as num_of_books_return, SUM(bb.rental_price) as total_revenue 
FROM issued_status as ist 
JOIN employees as e ON ist.issued_emp_id = e.emp_id 
JOIN branch as b ON e.branch_id = b.branch_id 
JOIN books as bb ON ist.issued_book_isbn = bb.isbn
LEFT JOIN return_status as r ON ist.issued_id = r.issued_id 
GROUP BY b.branch_id 
)
SELECT * FROM branch_reports;


/* Task 16 CTAS: Create a Table of Active Members
Use the create table as (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.*/

CREATE TABLE active_members AS 
SELECT m.*, ist.issued_book_name,ist.issued_date
FROM members as m
JOIN issued_status as ist ON m.member_id = ist.issued_member_id 
WHERE ist.issued_date >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH);


/* Task 17 find the employees with the most books issues processed 
write a query to find the top 3 employees who have processed the most book issues. display the employee_name, number-of_books
processed , and their branch.*/

SELECT e.emp_name as employee_name, COUNT(ist.issued_id) as number_of_books_processed,
e.branch_id
FROM employees as e
JOIN issued_status as ist ON e.emp_id = ist.issued_emp_id 
GROUP BY e.branch_id, employee_name
ORDER BY number_of_books_processed DESC 
LIMIT 3;

/* Task 18 Identify Members Issuing High_Risk Books
write a query to identify members who have issued books atleast once with the status 'damaged' in the books table.
Display the member_name, book_title, and the number of times they've issued damaged books.*/

SELECT m.member_name, b.book_title, COUNT(ist.issued_id) as num_of_books_issued
FROM issued_status as ist 
JOIN members as m ON ist.issued_member_id = m.member_id 
JOIN books as b ON ist.issued_book_isbn = b.isbn
JOIN return_status as r ON ist.issued_id = r.issued_id
WHERE r.book_quanlity = 'Damaged'
GROUP BY m.member_name, b.book_title
HAVING COUNT(ist.issued_id) >0
ORDER BY num_of_books_issued;

/* Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.*/

DELIMITER //
CREATE PROCEDURE issued_book (p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_name VARCHAR(80),
 P_issued_book_isbn VARCHAR(50), p_issued_emp_id VARCHAR(10))
BEGIN 
 DECLARE 
    v_status VARCHAR (10);
  
  -- step 1 check the current status of the book
  SELECT status 
  INTO v_status 
  FROM books 
  WHERE isbn = p_issued_book_isbn;

   -- Step 2: If the book is available (status = 'yes'), issue it
   
   IF V_status = 'Yes' THEN 
   
   INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
   VALUES 
   (p_issued_id, p_issued_member_id, p_issued_book_name, CURRENT_DATE(), p_issued_book_isbn, p_issued_emp_id);
   
   UPDATE books 
   SET status = 'no'
   WHERE isbn = p_issued_book_isbn ;
   
   SELECT 'Book issued successfully !' as message ;
   
    -- step 2: if the book is not available (status = 'no'), Show Error
    
    ELSEIF v_status = 'no' THEN
      
      SELECT 'Sorry to inform you the book you have requested is unavailable !' as message ;
      
   END IF ;

END // 
DELIMITER ;
    
    -- Testing the function 
    
    select * from books where isbn = '978-0-679-77644-3'; -- '978-0-679-77644-3' status is yes 
    SELECT * FROM books WHERE isbn = '978-0-7432-7357-1'; -- '978-0-7432-7357-1' status is no 
    
    SELECT * FROM issued_status WHERE issued_book_isbn = '978-0-679-77644-3';
    SELECT * FROM issued_status WHERE issued_book_isbn = '978-0-7432-7357-1';
    
    SELECT * FROM return_status WHERE issued_id = 'IS127';
    SELECT * FROM return_status WHERE issued_id = 'IS136';
    
    -- Calling the store procedure 
    
    CALL issued_book ('IS155', 'C108', 'Beloved', '978-0-679-77644-3', 'E104');
    CALL issued_book ('IS156', 'C106', '1491: New Revelations of the Americas Before Columbus', '978-0-7432-7357-1', 'E111');


/* Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. 
The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines*/

CREATE TABLE overdue_fines AS 
SELECT ist.issued_member_id , COUNT(*) as overdue_books, 
SUM(
CASE 
  WHEN DATEDIFF(CURDATE(),ist.issued_date) > 30 THEN (DATEDIFF(CURDATE(),ist.issued_date) -30) *0.50 
  ELSE 0
  END) AS Total_fines 
FROM issued_status as ist 
LEFT JOIN return_status as r ON ist.issued_id = r.issued_id 
WHERE r.return_date IS NULL AND 
DATEDIFF(CURDATE(),ist.issued_date)>30 
GROUP BY ist.issued_member_id;

-- End of Project 
