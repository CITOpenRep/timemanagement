.import QtQuick.LocalStorage 2.7 as Sql
.import "database.js" as DBCommon

function initializeDatabase() {
    console.log("🗄️  Initializing database...");
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
            stage INTEGER,\
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
            'stage INTEGER',
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
            priority TEXT,\
            state INTEGER,\
            personal_stage INTEGER,\
            description TEXT,\
            last_modified datetime,\
            user_id INTEGER,\
            status TEXT DEFAULT "",\
            has_draft INTEGER DEFAULT 0,\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'name TEXT', 'account_id INTEGER', 'project_id INTEGER', 'sub_project_id INTEGER', 'parent_id INTEGER',
                                  'start_date date', 'end_date date', 'deadline date', 'initial_planned_hours FLOAT', 'priority TEXT', 'state INTEGER',
                                  'personal_stage INTEGER', 'description TEXT', 'last_modified datetime', 'user_id INTEGER', 'status TEXT DEFAULT ""', 'has_draft INTEGER DEFAULT 0', 'odoo_record_id INTEGER']
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
            timer_type TEXT DEFAULT "manual",\
            has_draft INTEGER DEFAULT 0,\
            odoo_record_id INTEGER,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'account_id INTEGER', 'project_id INTEGER', 'sub_project_id INTEGER', 'task_id INTEGER',
                                  'sub_task_id INTEGER', 'name TEXT', 'unit_amount FLOAT', 'last_modified datetime', 'quadrant_id INTEGER',
                                  'record_date datetime','user_id INTEGER' ,'status TEXT DEFAULT ""', 'timer_type TEXT DEFAULT "manual"', 'has_draft INTEGER DEFAULT 0', 'odoo_record_id INTEGER']
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
            has_draft INTEGER DEFAULT 0,\
            UNIQUE (odoo_record_id, account_id)\
        )',
                                 ['id INTEGER', 'account_id INTEGER', 'activity_type_id INTEGER', 'summary TEXT', 'due_date DATE', 'user_id INTEGER',
                                  'notes TEXT', 'odoo_record_id INTEGER', 'last_modified datetime', 'link_id INTEGER', 'project_id INTEGER',
                                  'task_id INTEGER', 'resId INTEGER', 'resModel TEXT', 'state TEXT', 'status TEXT DEFAULT ""', 'has_draft INTEGER DEFAULT 0']
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

    // Task-Assignee relationship table for multiple assignees per task
    DBCommon.createOrUpdateTable("project_task_assignee_app",
                                 'CREATE TABLE IF NOT EXISTS project_task_assignee_app (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            task_id INTEGER,\
            account_id INTEGER,\
            user_id INTEGER,\
            last_modified datetime,\
            status TEXT DEFAULT "",\
            UNIQUE (task_id, account_id, user_id)\
        )',
                                 [
                                     "id INTEGER",
                                     "task_id INTEGER",
                                     "account_id INTEGER", 
                                     "user_id INTEGER",
                                     "last_modified datetime",
                                     "status TEXT DEFAULT ''"
                                 ]
                                 );


    DBCommon.createOrUpdateTable("project_update_app",
        "CREATE TABLE IF NOT EXISTS project_update_app (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "account_id INTEGER," +
            "name TEXT," +
            "project_status TEXT," +
            "progress INTEGER," +
            "user_id INTEGER," +
            "description TEXT," +
            "date TEXT," +
            "project_id INTEGER," +
            "odoo_record_id INTEGER," +
            "last_modified datetime," +
            "status TEXT DEFAULT ''," +   // local sync status
            "has_draft INTEGER DEFAULT 0," +
            "UNIQUE (odoo_record_id, account_id)" +
        ")",
        [
            "id INTEGER",
            "account_id INTEGER",
            "name TEXT",
            "project_status TEXT",
            "progress INTEGER",
            "user_id INTEGER",
            "description TEXT",
            "date TEXT",
            "project_id INTEGER",
            "odoo_record_id INTEGER",
            "last_modified datetime",
            "status TEXT DEFAULT ''",
            "has_draft INTEGER DEFAULT 0"
        ]
    );

    DBCommon.createOrUpdateTable("project_task_type_app",
      'CREATE TABLE IF NOT EXISTS project_task_type_app (\
          id INTEGER PRIMARY KEY AUTOINCREMENT,\
          account_id INTEGER NOT NULL,\
          odoo_record_id INTEGER NOT NULL,\
          name TEXT NOT NULL,\
          description TEXT,\
          sequence INTEGER DEFAULT 0,\
          fold INTEGER DEFAULT 0,\
          legend_blocked TEXT,\
          legend_done TEXT,\
          legend_normal TEXT,\
          auto_validation_kanban_state INTEGER DEFAULT 0,\
          mail_template_id INTEGER,\
          sms_template_id INTEGER,\
          rating_template_id INTEGER,\
          user_id INTEGER,\
          active INTEGER DEFAULT 1,\
          create_date DATETIME,\
          write_date DATETIME,\
          __last_update DATETIME,\
          -- helper flag: if the stage has no project_ids on Odoo
          is_global INTEGER DEFAULT 1,\
          UNIQUE (odoo_record_id, account_id)\
      )',
      [
        'id INTEGER',
        'account_id INTEGER',
        'odoo_record_id INTEGER',
        'name TEXT',
        'description TEXT',
        'sequence INTEGER',
        'fold INTEGER',
        'legend_blocked TEXT',
        'legend_done TEXT',
        'legend_normal TEXT',
        'auto_validation_kanban_state INTEGER',
        'mail_template_id INTEGER',
        'sms_template_id INTEGER',
        'rating_template_id INTEGER',
        'user_id INTEGER',
        'active INTEGER',
        'create_date DATETIME',
        'write_date DATETIME',
        '__last_update DATETIME',
        'is_global INTEGER'
      ]
    );

    DBCommon.createOrUpdateTable("project_project_stage_app",
      'CREATE TABLE IF NOT EXISTS project_project_stage_app (\
          id INTEGER PRIMARY KEY AUTOINCREMENT,\
          account_id INTEGER NOT NULL,\
          odoo_record_id INTEGER NOT NULL,\
          name TEXT NOT NULL,\
          sequence INTEGER DEFAULT 0,\
          fold INTEGER DEFAULT 0,\
          mail_template_id INTEGER,\
          sms_template_id INTEGER,\
          active INTEGER DEFAULT 1,\
          create_date DATETIME,\
          write_date DATETIME,\
          __last_update DATETIME,\
          UNIQUE (odoo_record_id, account_id)\
      )',
      [
        'id INTEGER',
        'account_id INTEGER',
        'odoo_record_id INTEGER',
        'name TEXT',
        'sequence INTEGER',
        'fold INTEGER',
        'mail_template_id INTEGER',
        'sms_template_id INTEGER',
        'active INTEGER',
        'create_date DATETIME',
        'write_date DATETIME',
        '__last_update DATETIME'
      ]
    );

    DBCommon.createOrUpdateTable("dl_cache_app",
      'CREATE TABLE IF NOT EXISTS dl_cache_app (\
          id INTEGER PRIMARY KEY AUTOINCREMENT,\
          record_id INTEGER NOT NULL,\
          data_base64 TEXT NOT NULL\
      )',
      [
        'id INTEGER',
        'record_id INTEGER',
        'data_base64 TEXT'
      ]
    );

    DBCommon.createOrUpdateTable("attachment_download_app",
        "CREATE TABLE IF NOT EXISTS attachment_download_app (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "account_id INTEGER NOT NULL," +
            "record_id INTEGER NOT NULL," +      // odoo_record_id or unique local id
            "file_name TEXT," +
            "downloaded INTEGER DEFAULT 0," +    // 0 = not downloaded, 1 = downloaded
            "UNIQUE (record_id, account_id)" +
        ")",
        [
            "id INTEGER",
            "account_id INTEGER",
            "record_id INTEGER",
            "file_name TEXT",
            "downloaded INTEGER"
        ]
    );

    // Form drafts table for auto-save functionality
    // Drop and recreate to fix column name mismatch from previous version
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function(tx) {
            // Check if table exists and has wrong column names
            var tableInfo = tx.executeSql("PRAGMA table_info(form_drafts)");
            var hasOldSchema = false;
            
            for (var i = 0; i < tableInfo.rows.length; i++) {
                var colName = tableInfo.rows.item(i).name;
                if (colName === "form_data" || colName === "changed_fields") {
                    hasOldSchema = true;
                    break;
                }
            }
            
            // Drop table if it has old schema
            if (hasOldSchema) {
                console.log("🔄 Dropping form_drafts table with old schema...");
                tx.executeSql("DROP TABLE IF EXISTS form_drafts");
                console.log("✅ Old form_drafts table dropped");
            }
        });
    } catch (e) {
        console.log("ℹ️ form_drafts table doesn't exist yet, will create fresh");
    }
    
    DBCommon.createOrUpdateTable("form_drafts",
        "CREATE TABLE IF NOT EXISTS form_drafts (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "draft_type TEXT NOT NULL," +           // task, timesheet, project, activity, project_update
            "record_id INTEGER," +                  // NULL for new records, ID for editing existing
            "account_id INTEGER NOT NULL," +
            "page_identifier TEXT NOT NULL," +      // Unique identifier for page instance
            "draft_data TEXT NOT NULL," +           // JSON serialized form data (matches draft_manager.js)
            "original_data TEXT," +                 // JSON serialized original data
            "field_changes TEXT," +                 // JSON array of changed field names (matches draft_manager.js)
            "is_new_record INTEGER DEFAULT 0," +    // 1 if new record, 0 if editing existing
            "created_at TEXT NOT NULL," +           // ISO timestamp
            "updated_at TEXT NOT NULL," +           // ISO timestamp
            "UNIQUE (draft_type, account_id, page_identifier, record_id)" +
        ")",
        [
            "id INTEGER",
            "draft_type TEXT",
            "record_id INTEGER",
            "account_id INTEGER",
            "page_identifier TEXT",
            "draft_data TEXT",
            "original_data TEXT",
            "field_changes TEXT",
            "is_new_record INTEGER",
            "created_at TEXT",
            "updated_at TEXT"
        ]
    );
    
    // Create indexes for form_drafts table for better query performance
    try {
        var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
        db.transaction(function(tx) {
            // Index for querying drafts by type and account
            tx.executeSql(
                "CREATE INDEX IF NOT EXISTS idx_form_drafts_type_account " +
                "ON form_drafts (draft_type, account_id)"
            );
            
            // Index for querying drafts by record
            tx.executeSql(
                "CREATE INDEX IF NOT EXISTS idx_form_drafts_record " +
                "ON form_drafts (draft_type, record_id, account_id)"
            );
            
            // Index for cleanup queries (finding old drafts)
            tx.executeSql(
                "CREATE INDEX IF NOT EXISTS idx_form_drafts_timestamp " +
                "ON form_drafts (created_at, updated_at)"
            );
        });
        console.log("✅ Form drafts table and indexes created successfully");
    } catch (e) {
        console.error("❌ Error creating form_drafts indexes:", e);
    }


    purgeCache();
    syncDraftFlags();
    
    console.log("✅ Database initialization complete");
}

function purgeCache() {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(
            DBCommon.NAME,
            DBCommon.VERSION,
            DBCommon.DISPLAY_NAME,
            DBCommon.SIZE
        );
        db.transaction(function (tx) {
            tx.executeSql("DELETE FROM dl_cache_app");
        });
        console.log("Cache purged at startup");
    } catch (e) {
        console.error("purgeCache failed:", e);
    }
}

function syncDraftFlags() {
    try {
        // Import draft_manager here to avoid circular dependencies
        var DraftManager = Qt.createQmlObject(
            'import QtQuick 2.7; import "../models/draft_manager.js" as DM; QtObject { function sync() { return DM.syncHasDraftFlags(); } }',
            null,
            "DraftManagerLoader"
        );
        
        if (DraftManager) {
            var result = DraftManager.sync();
            if (result && result.success) {
                console.log("✅ Draft flags synchronized at startup:", result.message);
            }
        }
    } catch (e) {
        // Fallback: Direct implementation if import fails
        try {
            var db = Sql.LocalStorage.openDatabaseSync(
                DBCommon.NAME,
                DBCommon.VERSION,
                DBCommon.DISPLAY_NAME,
                DBCommon.SIZE
            );
            
            var updatedCount = 0;
            
            db.transaction(function(tx) {
                // Get all drafts with record IDs
                var drafts = tx.executeSql(
                    "SELECT DISTINCT draft_type, record_id FROM form_drafts WHERE record_id IS NOT NULL AND record_id > 0"
                );
                
                console.log("🔄 Syncing has_draft flags for " + drafts.rows.length + " records...");
                
                // Set has_draft=1 for all records that have drafts
                for (var i = 0; i < drafts.rows.length; i++) {
                    var draft = drafts.rows.item(i);
                    var recordId = draft.record_id;
                    var draftType = draft.draft_type;
                    
                    var tableName = null;
                    if (draftType === "task") {
                        tableName = "project_task_app";
                    } else if (draftType === "timesheet") {
                        tableName = "account_analytic_line_app";
                    }
                    
                    if (tableName) {
                        tx.executeSql(
                            "UPDATE " + tableName + " SET has_draft = 1 WHERE id = ?",
                            [recordId]
                        );
                        updatedCount++;
                    }
                }
                
                // Clear has_draft=0 for tasks that don't have drafts
                var taskIds = tx.executeSql(
                    "SELECT id FROM project_task_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'task' AND record_id IS NOT NULL)"
                );
                for (var j = 0; j < taskIds.rows.length; j++) {
                    tx.executeSql(
                        "UPDATE project_task_app SET has_draft = 0 WHERE id = ?",
                        [taskIds.rows.item(j).id]
                    );
                    updatedCount++;
                }
                
                // Clear has_draft=0 for timesheets that don't have drafts
                var timesheetIds = tx.executeSql(
                    "SELECT id FROM account_analytic_line_app WHERE has_draft = 1 AND id NOT IN (SELECT record_id FROM form_drafts WHERE draft_type = 'timesheet' AND record_id IS NOT NULL)"
                );
                for (var k = 0; k < timesheetIds.rows.length; k++) {
                    tx.executeSql(
                        "UPDATE account_analytic_line_app SET has_draft = 0 WHERE id = ?",
                        [timesheetIds.rows.item(k).id]
                    );
                    updatedCount++;
                }
            });
            
            console.log("✅ Synchronized " + updatedCount + " has_draft flag(s) at startup");
        } catch (syncError) {
            console.error("❌ Error syncing draft flags:", syncError);
        }
    }
}

