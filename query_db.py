import sqlite3
import os
import glob

# Find the database
paths = glob.glob(os.path.expanduser("~/.local/share/*/Databases/*/ubtms*"))
paths += glob.glob(os.path.expanduser("~/.local/share/*/ubtms*"))
paths += glob.glob(os.path.expanduser("~/.local/share/ubtms/*"))
paths += glob.glob(os.path.expanduser("~/.local/share/*/Databases/*"))
paths += glob.glob(os.path.expanduser("~/.local/share/UBTMS/Databases/*"))

db_path = None
for p in paths:
    if p.endswith('.sqlite') or p.endswith('.db') or 'ubtms' in p:
        db_path = p
        break

if not db_path:
    # Try the default Qt location
    qt_paths = glob.glob(os.path.expanduser("~/.local/share/QML/OfflineStorage/Databases/*.sqlite"))
    if qt_paths:
        db_path = qt_paths[0]

print(f"Using DB: {db_path}")

if db_path:
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    print("--- res_users_app ---")
    cur.execute("SELECT id, odoo_record_id, name, login FROM res_users_app")
    for row in cur.fetchall():
        print(row)
        
    print("\n--- mail_activity_app ---")
    cur.execute("SELECT id, odoo_record_id, summary, user_id FROM mail_activity_app LIMIT 10")
    for row in cur.fetchall():
        print(row)
    conn.close()
