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




