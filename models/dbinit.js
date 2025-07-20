.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon

function initializeDatabase() {
    var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

    DBCommon.createOrUpdateTable("sync_report",
                                 'CREATE TABLE IF NOT EXISTS sync_report (' +
                                 'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                                 'status TEXT, ' +
                                 'account_id INTEGER, ' +
                                 'timestamp TEXT, ' +
                                 'message TEXT)',
                                 ['status TEXT',
                                  'account_id INTEGER',
                                  'timestamp TEXT',
                                  'message TEXT']);

    DBCommon.createOrUpdateTable("users",
                                 'CREATE TABLE IF NOT EXISTS users (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            name TEXT NOT NULL,\
            link TEXT NOT NULL,\
            last_modified datetime,\
            database TEXT NOT NULL,\
            connectwith_id INTEGER,\
            api_key TEXT,\
            username TEXT NOT NULL,\
            is_default INTEGER DEFAULT 0\
        )',
                                 ['id INTEGER', 'name TEXT', 'link TEXT', 'last_modified datetime', 'database TEXT', 'connectwith_id INTEGER', 'api_key TEXT', 'username TEXT','is_default INTEGER']
                                 );

    //Notification table
    DBCommon.createOrUpdateTable("notification",
        "CREATE TABLE IF NOT EXISTS notification (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "account_id INTEGER," +
            "timestamp TEXT DEFAULT (datetime('now'))," +
            "message TEXT NOT NULL," +
            "type TEXT CHECK(type IN ('Activity', 'Task', 'Project', 'Timesheet', 'Sync'))," +
            "payload TEXT NOT NULL," +
            "read_status INTEGER DEFAULT 0" +
        ")",
        [
            "id INTEGER",
            "account_id INTEGER",
            "timestamp TEXT",
            "message TEXT",
            "type TEXT",
            "payload TEXT",
            "read_status INTEGER"
        ]
    );


    //Time to create a local account
    DBCommon.ensureDefaultLocalAccountExists()
    //Local account ends

    DBCommon.createOrUpdateTable("project_project_app",
        'CREATE TABLE IF NOT EXISTS project_project_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            name TEXT NOT NULL,\
            account_id INTEGER,\
            parent_id INTEGER,\
            planned_start_date date,\
            planned_end_date date,\
            allocated_hours FLOAT,\
            remaining_hours FLOAT,\
            favorites INTEGER,\
            last_update_status TEXT,\
            description TEXT,\
            last_modified datetime,\
            color_pallet TEXT,\
            status TEXT DEFAULT "",\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
        [
            'id INTEGER',
            'name TEXT',
            'account_id INTEGER',
            'parent_id INTEGER',
            'planned_start_date date',
            'planned_end_date date',
            'allocated_hours FLOAT',
            'remaining_hours FLOAT',
            'favorites INTEGER',
            'last_update_status TEXT',
            'description TEXT',
            'last_modified datetime',
            'color_pallet TEXT',
            'status TEXT DEFAULT ""',
            'odoo_record_id INTEGER'
        ]
    );


    DBCommon.createOrUpdateTable("res_users_app",
                                 "CREATE TABLE IF NOT EXISTS res_users_app (" +
                                 "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                                 "account_id INTEGER, " +
                                 "name TEXT, " +
                                 "login TEXT, " +
                                 "email TEXT, " +
                                 "work_email TEXT, " +
                                 "mobile_phone TEXT, " +
                                 "job_title TEXT, " +
                                 "company_id INTEGER, " +
                                 "share INTEGER, " +
                                 "active INTEGER, " +
                                 "status TEXT DEFAULT '', " +
                                 "odoo_record_id INTEGER, " +
                                 "UNIQUE (odoo_record_id, account_id)" +
                                 ")",
                                 [
                                     "id INTEGER",
                                     "account_id INTEGER",
                                     "name TEXT",
                                     "login TEXT",
                                     "email TEXT",
                                     "work_email TEXT",
                                     "mobile_phone TEXT",
                                     "job_title TEXT",
                                     "company_id INTEGER",
                                     "share INTEGER",
                                     "active INTEGER",
                                     "status TEXT DEFAULT ''",
                                     "odoo_record_id INTEGER"
                                 ]
                                 );


    DBCommon.createOrUpdateTable("project_task_app",
                                 'CREATE TABLE IF NOT EXISTS project_task_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            name TEXT NOT NULL,\
            account_id INTEGER,\
            project_id INTEGER,\
            sub_project_id INTEGER,\
            parent_id INTEGER,\
            start_date date,\
            end_date date,\
            deadline date,\
            initial_planned_hours FLOAT,\
            favorites INTEGER,\
            state TEXT,\
            description TEXT,\
            last_modified datetime,\
            user_id INTEGER,\
            status TEXT DEFAULT "",\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'name TEXT', 'account_id INTEGER', 'project_id INTEGER', 'sub_project_id INTEGER', 'parent_id INTEGER',
                                  'start_date date', 'end_date date', 'deadline date', 'initial_planned_hours FLOAT', 'favorites INTEGER', 'state TEXT',
                                  'description TEXT', 'last_modified datetime', 'user_id INTEGER', 'status TEXT DEFAULT ""', 'odoo_record_id INTEGER']
                                 );

    DBCommon.createOrUpdateTable("account_analytic_line_app",
                                 'CREATE TABLE IF NOT EXISTS account_analytic_line_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            account_id INTEGER,\
            project_id INTEGER,\
            sub_project_id INTEGER,\
            task_id INTEGER,\
            sub_task_id INTEGER,\
            name TEXT,\
            unit_amount FLOAT,\
            last_modified datetime,\
            quadrant_id INTEGER,\
            record_date datetime,\
            user_id INTEGER,\
            status TEXT DEFAULT "",\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'account_id INTEGER', 'project_id INTEGER', 'sub_project_id INTEGER', 'task_id INTEGER',
                                  'sub_task_id INTEGER', 'name TEXT', 'unit_amount FLOAT', 'last_modified datetime', 'quadrant_id INTEGER',
                                  'record_date datetime','user_id INTEGER' ,'status TEXT DEFAULT ""', 'odoo_record_id INTEGER']
                                 );

    DBCommon.createOrUpdateTable("mail_activity_type_app",
                                 'CREATE TABLE IF NOT EXISTS mail_activity_type_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            account_id INTEGER,\
            name TEXT,\
            status TEXT DEFAULT "",\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'account_id INTEGER', 'name TEXT', 'status TEXT DEFAULT ""', 'odoo_record_id INTEGER']
                                 );


    DBCommon.createOrUpdateTable("ir_model_app",
        'CREATE TABLE IF NOT EXISTS ir_model_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            account_id INTEGER,\
            name TEXT,\
            technical_name TEXT,\
            status TEXT DEFAULT "",\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
        ['id INTEGER', 'account_id INTEGER', 'name TEXT', 'technical_name TEXT', 'status TEXT DEFAULT ""', 'odoo_record_id INTEGER']
    );


    DBCommon.createOrUpdateTable("mail_activity_app",
                                 'CREATE TABLE IF NOT EXISTS mail_activity_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            account_id INTEGER,\
            activity_type_id INTEGER,\
            summary TEXT,\
            due_date DATE,\
            user_id INTEGER,\
            notes TEXT,\
            odoo_record_id INTEGER,\
            last_modified datetime,\
            link_id INTEGER,\
            project_id INTEGER,\
            task_id INTEGER,\
            resId INTEGER,\
            resModel TEXT,\
            state TEXT,\
            status TEXT DEFAULT "",\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'account_id INTEGER', 'activity_type_id INTEGER', 'summary TEXT', 'due_date DATE', 'user_id INTEGER',
                                  'notes TEXT', 'odoo_record_id INTEGER', 'last_modified datetime', 'link_id INTEGER', 'project_id INTEGER',
                                  'task_id INTEGER', 'resId INTEGER', 'resModel TEXT', 'state TEXT', 'status TEXT DEFAULT ""']
                                 );
    DBCommon.createOrUpdateTable("ir_attachment_app",
        "CREATE TABLE IF NOT EXISTS ir_attachment_app (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "account_id INTEGER," +
            "name TEXT," +
            "description TEXT," +
            "res_model TEXT," +
            "res_id INTEGER," +
            "store_fname TEXT," +
            "file_path TEXT," +
            "datas TEXT," + // optional if storing on disk only
            "file_size INTEGER," +
            "checksum TEXT," +
            "mimetype TEXT," +
            "access_token TEXT," +
            "url TEXT," +
            "image_width INTEGER," +
            "image_height INTEGER," +
            "local_url TEXT," +
            "odoo_record_id INTEGER," +
            "last_modified datetime," +
            "status TEXT DEFAULT ''," +
            "UNIQUE (odoo_record_id, account_id)" +
        ")",
        [
            "id INTEGER",
            "account_id INTEGER",
            "name TEXT",
            "description TEXT",
            "res_model TEXT",
            "res_id INTEGER",
            "store_fname TEXT",
            "file_path TEXT",
            "datas TEXT",
            "file_size INTEGER",
            "checksum TEXT",
            "mimetype TEXT",
            "access_token TEXT",
            "url TEXT",
            "image_width INTEGER",
            "image_height INTEGER",
            "local_url TEXT",
            "odoo_record_id INTEGER",
            "last_modified datetime",
            "status TEXT DEFAULT ''"
        ]
    );


}
