# Business Supply Management Application

This application provides a graphical user interface (GUI) to interact with the `business_supply` database. It allows you to execute various stored procedures and view query results as defined in the provided SQL scripts.

## 1. Requirements

- **MySQL** installed and running locally.
- **Python 3** installed.
- **Python Packages**:
  - `mysql-connector-python`
    - `pip install mysql-connector-python`
  - `tkinter`

## 2. Setting Up the Database

mysql -u root -p < cs4400_database_schema.sql
mysql -u root -p business_supply < cs4400_phase3_team91.sql

def connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="root",  # Update to your mysql password
        database="business_supply"
    )
## 3. Running Application

python ui.py


## 4. Technologies Used

Below is a brief explanation of the main technologies mentioned in the README and their roles in the project:

- **MySQL**:  
  MySQL is a popular open-source relational database management system. In this project, it stores the application’s data, including tables, sample data, and the stored procedures and views that the application relies on.

- **Python**:  
  Python is a high-level programming language known for its readability and wide range of libraries. In this project, Python is used to implement the graphical user interface and the logic that interacts with the MySQL database.

- **tkinter**:  
  `tkinter` is Python’s standard library for creating GUIs (Graphical User Interfaces). It is used here to build the application’s window, tabs, input fields, buttons, and text areas, making the interaction with the database more user-friendly.

- **mysql-connector-python**:  
  `mysql-connector-python` is a Python library provided by Oracle for connecting to MySQL servers. It allows the Python code to execute SQL queries, call stored procedures, and retrieve results directly from the MySQL database.

These technologies work together to provide a streamlined environment where the user can interact with the `business_supply` database through a Python-based GUI, running SQL procedures and viewing the results in a convenient manner.

## 5. Contribution Table

Sanjit Pingili - Helped code the procedures, views, front end, and boilerplate code. 
Joshua Joseph - Helped code the procedures, views, front end, and boilerplate code. 
Srikar Balusu - Helped code the procedures, views, front end, and boilerplate code. 



