import sqlite3
import os
import glob

# Try standard click app path for db
db_path = os.path.expanduser("~/.local/share/ubtms/app_settings.db")
if not os.path.exists(db_path):
    # Try Qt OfflineStorage paths
    qt_paths = glob.glob(os.path.expanduser("~/.local/share/*/Databases/*.sqlite"))
    if qt_paths:
        for p in qt_paths:
            if 'ubtms' in p.lower() or 'qml' in p.lower():
                db_path = p
                break

print(f"Using DB: {db_path}")

if db_path and os.path.exists(db_path):
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
        
    print("\n--- project_task_app ---")
    cur.execute("SELECT id, odoo_record_id, name, user_id FROM project_task_app LIMIT 10")
    for row in cur.fetchall():
        print(row)
        
    print("\n--- users ---")
    cur.execute("SELECT id, username FROM users")
    for row in cur.fetchall():
        print(row)
        
    conn.close()
else:
    print("DB not found")
