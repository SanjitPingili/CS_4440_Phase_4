import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector

def connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="your_password", # Change this to your MySQL password
        database="business_supply"
    )

class ProcedureTab:
    def __init__(self, parent, proc_name, param_info):
        self.frame = ttk.Frame(parent, padding="10 10 10 10")
        self.proc_name = proc_name
        self.param_info = param_info
        self.entries = {}

        heading = ttk.Label(self.frame, text=proc_name, font=("Helvetica", 16, "bold"))
        heading.grid(row=0, column=0, columnspan=2, pady=(0, 10), sticky="w")

        row = 1
        for p in self.param_info:
            lbl = ttk.Label(self.frame, text=p[0], font=("Helvetica", 12))
            lbl.grid(row=row, column=0, sticky="w", padx=5, pady=5)
            ent = ttk.Entry(self.frame, width=40)
            ent.grid(row=row, column=1, sticky="ew", padx=5, pady=5)
            self.entries[p[0]] = ent
            row += 1

        exec_btn = ttk.Button(self.frame, text="Execute", command=self.execute_procedure)
        exec_btn.grid(row=row, column=0, columnspan=2, pady=(10, 5))

        self.message = tk.StringVar()
        msg_label = ttk.Label(self.frame, textvariable=self.message, foreground="blue")
        msg_label.grid(row=row+1, column=0, columnspan=2, sticky="w")

        self.frame.columnconfigure(1, weight=1)

    def execute_procedure(self):
        conn = None
        try:
            conn = connect_db()
            cursor = conn.cursor()
            params = []
            for p in self.param_info:
                val = self.entries[p[0]].get().strip()
                if p[1].lower().startswith("int"):
                    val = int(val) if val else None
                params.append(val)

            call_str = "CALL " + self.proc_name + "(" + ",".join(["%s"]*len(params)) + ")"
            cursor.execute(call_str, tuple(params))
            conn.commit()
            self.message.set("Procedure executed successfully (or halted by conditions).")
        except Exception:
            self.message.set("Execution halted. Check constraints or input.")
        finally:
            if conn:
                conn.close()

class ViewTab:
    def __init__(self, parent, view_name):
        self.frame = ttk.Frame(parent, padding="10 10 10 10")
        self.view_name = view_name

        heading = ttk.Label(self.frame, text=view_name, font=("Helvetica", 16, "bold"))
        heading.grid(row=0, column=0, sticky="w")

        self.text = tk.Text(self.frame, wrap="none", width=100, height=20, font=("Courier", 10))
        self.text.grid(row=1, column=0, sticky="nsew")

        btn = ttk.Button(self.frame, text="Load View Data", command=self.load_data)
        btn.grid(row=2, column=0, pady=10, sticky="w")

        # Add scrollbars
        x_scroll = ttk.Scrollbar(self.frame, orient='horizontal', command=self.text.xview)
        x_scroll.grid(row=3, column=0, sticky='ew')
        self.text.configure(xscrollcommand=x_scroll.set)

        y_scroll = ttk.Scrollbar(self.frame, orient='vertical', command=self.text.yview)
        y_scroll.grid(row=1, column=1, sticky='ns')
        self.text.configure(yscrollcommand=y_scroll.set)

        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(1, weight=1)

    def load_data(self):
        self.text.delete("1.0", "end")
        conn = None
        try:
            conn = connect_db()
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM " + self.view_name)
            rows = cursor.fetchall()
            cols = [desc[0] for desc in cursor.description]
            header_line = " | ".join(cols)
            self.text.insert("end", header_line + "\n")
            self.text.insert("end", "-"*len(header_line) + "\n")
            for r in rows:
                line = " | ".join(str(x) for x in r)
                self.text.insert("end", line + "\n")
        except Exception as e:
            self.text.insert("end", "Error loading view data.\n" + str(e))
        finally:
            if conn:
                conn.close()

def main():
    root = tk.Tk()
    root.title("Business Supply Management UI")
    root.geometry("1200x800")

    style = ttk.Style()
    style.theme_use("clam")

    # Add a title frame at the top
    title_frame = ttk.Frame(root, padding="10 10 10 10")
    title_frame.pack(side="top", fill="x")

    title_label = ttk.Label(title_frame, text="Business Supply Management System",
                            font=("Helvetica", 20, "bold"))
    title_label.pack()

    notebook = ttk.Notebook(root)
    notebook.pack(fill="both", expand=True, padx=10, pady=10)

    procedures = [
        ("add_owner", [("ip_username","varchar(40)"), ("ip_first_name","varchar(100)"), ("ip_last_name","varchar(100)"), ("ip_address","varchar(500)"), ("ip_birthdate","date")]),
        ("add_employee", [("ip_username","varchar(40)"), ("ip_first_name","varchar(100)"), ("ip_last_name","varchar(100)"), ("ip_address","varchar(500)"), ("ip_birthdate","date"), ("ip_taxID","varchar(40)"), ("ip_hired","date"), ("ip_employee_experience","int"), ("ip_salary","int")]),
        ("add_driver_role", [("ip_username","varchar(40)"), ("ip_licenseID","varchar(40)"), ("ip_license_type","varchar(40)"), ("ip_driver_experience","int")]),
        ("add_worker_role", [("ip_username","varchar(40)")]),
        ("add_product", [("ip_barcode","varchar(40)"), ("ip_name","varchar(100)"), ("ip_weight","int")]),
        ("add_van", [("ip_id","varchar(40)"), ("ip_tag","int"), ("ip_fuel","int"), ("ip_capacity","int"), ("ip_sales","int"), ("ip_driven_by","varchar(40)")]),
        ("add_business", [("ip_long_name","varchar(40)"), ("ip_rating","int"), ("ip_spent","int"), ("ip_location","varchar(40)")]),
        ("add_service", [("ip_id","varchar(40)"), ("ip_long_name","varchar(100)"), ("ip_home_base","varchar(40)"), ("ip_manager","varchar(40)")]),
        ("add_location", [("ip_label","varchar(40)"), ("ip_x_coord","int"), ("ip_y_coord","int"), ("ip_space","int")]),
        ("start_funding", [("ip_owner","varchar(40)"), ("ip_amount","int"), ("ip_long_name","varchar(40)"), ("ip_fund_date","date")]),
        ("hire_employee", [("ip_username","varchar(40)"), ("ip_id","varchar(40)")]),
        ("fire_employee", [("ip_username","varchar(40)"), ("ip_id","varchar(40)")]),
        ("manage_service", [("ip_username","varchar(40)"), ("ip_id","varchar(40)")]),
        ("takeover_van", [("ip_username","varchar(40)"), ("ip_id","varchar(40)"), ("ip_tag","int")]),
        ("load_van", [("ip_id","varchar(40)"), ("ip_tag","int"), ("ip_barcode","varchar(40)"), ("ip_more_packages","int"), ("ip_price","int")]),
        ("refuel_van", [("ip_id","varchar(40)"), ("ip_tag","int"), ("ip_more_fuel","int")]),
        ("drive_van", [("ip_id","varchar(40)"), ("ip_tag","int"), ("ip_destination","varchar(40)")]),
        ("purchase_product", [("ip_long_name","varchar(40)"), ("ip_id","varchar(40)"), ("ip_tag","int"), ("ip_barcode","varchar(40)"), ("ip_quantity","int")]),
        ("remove_product", [("ip_barcode","varchar(40)")]),
        ("remove_van", [("ip_id","varchar(40)"), ("ip_tag","int")]),
        ("remove_driver_role", [("ip_username","varchar(40)")]),
    ]

    for proc_name, params in procedures:
        tab = ProcedureTab(notebook, proc_name, params)
        notebook.add(tab.frame, text=proc_name)

    views = [
        "display_owner_view",
        "display_employee_view",
        "display_driver_view",
        "display_location_view",
        "display_product_view",
        "display_service_view"
    ]

    for v_name in views:
        vtab = ViewTab(notebook, v_name)
        notebook.add(vtab.frame, text=v_name)

    root.mainloop()

if __name__ == "__main__":
    main()
