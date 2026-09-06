.import "logger.js" as Logger
.import QtQuick.LocalStorage 2.7 as Sql
    .import "database.js" as DBCommon
        .import "utils.js" as Utils
            .import "accounts.js" as Accounts
                .import "draft_manager.js" as DraftManager


/**
 * Retrieves all non-deleted timesheet entries from the local SQLite database.
 *
 * Joins related data from `project_project_app`, `users`, `res_users_app`, and `project_task_app`
 * to enrich the timesheet list with human-readable project, task, instance, and user names.
 *
 * @returns {Array<Object>} - A list of enriched timesheet entries.
 */
function fetchTimesheetsByStatus(status, accountId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            // Build map of odoo_record_id and local id -> color_pallet
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT id, odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                if (projectRow.odoo_record_id) {
                    projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
                }
                if (projectRow.id) {
                    projectColorMap[projectRow.id] = projectRow.color_pallet;
                }
            }

            var query = "";
            var params = [];


            if (!status || status.toLowerCase() === "all") {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [accountId];
            } else if (status === "draft") {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND (status = 'draft' OR status = 'saved') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [accountId];
            } else {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [accountId, status];
            }

            Logger.debug("Timesheet", "Executing fetchTimesheetsByStatus query:", query, "with params:", params)
            var result = tx.executeSql(query, params);
            Logger.debug("Timesheet", "Found", result.rows.length, "timesheets for account:", accountId)

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                // Resolve project name and parent name
                var projectName = "Unknown Project";
                var inheritedColor = 0;

                if (row.project_id) {
                    var rs_project = tx.executeSql(
                        "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.project_id, row.project_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            // Subproject case
                            var rs_parent = tx.executeSql(
                                "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                                [project_row.parent_id, project_row.parent_id]
                            );
                            if (rs_parent.rows.length > 0) {
                                projectName = rs_parent.rows.item(0).name + " / " + project_row.name;
                            } else {
                                projectName = project_row.name;
                            }

                            // Inherit color from subproject
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                // Resolve task name
                var taskName = "Unknown Task";
                if (row.task_id) {
                    var rs_task = tx.executeSql(
                        "SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.task_id, row.task_id]
                    );
                    if (rs_task.rows.length > 0) {
                        taskName = rs_task.rows.item(0).name;
                    }
                }

                // Resolve instance and user names
                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }

                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in fetchTimesheetsByStatus:", e.message)
        DBCommon.logException("fetchTimesheetsByStatus", e);
    }

    return timesheetList;
}
function fetchTimesheetsForAllAccounts(status) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT id, odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                if (projectRow.odoo_record_id) {
                    projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
                }
                if (projectRow.id) {
                    projectColorMap[projectRow.id] = projectRow.color_pallet;
                }
            }
            var query = "";
            var params = [];

            if (!status || status.toLowerCase() === "all") {
                query = "SELECT * FROM account_analytic_line_app WHERE status IS NULL OR status != 'deleted' ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [];
            } else if (status === "draft") {
                query = "SELECT * FROM account_analytic_line_app WHERE (status = 'draft' OR status = 'saved') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [];
            } else {
                query = "SELECT * FROM account_analytic_line_app WHERE status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                params = [status];
            }

            // console.log("Executing fetchTimesheetsForAllAccounts query:", query, "with params:", params);
            var result = tx.executeSql(query, params);
            // console.log("Found", result.rows.length, "timesheets for all accounts");

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                // Resolve project name and parent name
                var projectName = "Unknown Project";
                var inheritedColor = 0;

                if (row.project_id) {
                    var rs_project = tx.executeSql(
                        "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.project_id, row.project_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            var rs_parent = tx.executeSql(
                                "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                                [project_row.parent_id, project_row.parent_id]
                            );
                            if (rs_parent.rows.length > 0) {
                                projectName = rs_parent.rows.item(0).name + " / " + project_row.name;
                            } else {
                                projectName = project_row.name;
                            }
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                // Resolve task name
                var taskName = "Unknown Task";
                if (row.task_id) {
                    var rs_task = tx.executeSql(
                        "SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.task_id, row.task_id]
                    );
                    if (rs_task.rows.length > 0) {
                        taskName = rs_task.rows.item(0).name;
                    }
                }

                // Resolve instance and user names
                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }

                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in fetchTimesheetsForAllAccounts:", e.message)
        DBCommon.logException("fetchTimesheetsForAllAccounts", e);
    }

    return timesheetList;
}

/**
 * Paginated version of fetchTimesheetsByStatus for infinite scroll.
 * 
 * @param {string} status - Status filter: 'all', 'active', 'draft', etc.
 * @param {number} accountId - Account ID to filter by.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} - A list of enriched timesheet entries.
 */
function fetchTimesheetsByStatusPaginated(status, accountId, limit, offset) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];
    limit = limit || 10;
    offset = offset || 0;

    try {
        db.transaction(function (tx) {
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT id, odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                if (projectRow.odoo_record_id) {
                    projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
                }
                if (projectRow.id) {
                    projectColorMap[projectRow.id] = projectRow.color_pallet;
                }
            }

            var query = "";
            var params = [];

            if (!status || status.toLowerCase() === "all") {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND (status IS NULL OR status != 'deleted') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [accountId, limit, offset];
            } else if (status === "draft") {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND (status = 'draft' OR status = 'saved') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [accountId, limit, offset];
            } else {
                query = "SELECT * FROM account_analytic_line_app WHERE account_id = ? AND status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [accountId, status, limit, offset];
            }

            var result = tx.executeSql(query, params);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var quadrantMap = { 0: "Unknown", 1: "Do", 2: "Plan", 3: "Delegate", 4: "Delete" };

                var projectName = "Unknown Project";
                var inheritedColor = 0;
                if (row.project_id) {
                    var projectAccountId = (row.account_id !== undefined && row.account_id !== null) ? row.account_id : null;
                    var rs_project = (projectAccountId !== null) ?
                        tx.executeSql(
                            "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) AND account_id = ? LIMIT 1",
                            [row.project_id, row.project_id, projectAccountId]
                        ) :
                        tx.executeSql(
                            "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                            [row.project_id, row.project_id]
                        );
                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            var rs_parent = (projectAccountId !== null) ?
                                tx.executeSql(
                                    "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) AND account_id = ? LIMIT 1",
                                    [project_row.parent_id, project_row.parent_id, projectAccountId]
                                ) :
                                tx.executeSql(
                                    "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                                    [project_row.parent_id, project_row.parent_id]
                                );
                            projectName = rs_parent.rows.length > 0 ? rs_parent.rows.item(0).name + " / " + project_row.name : project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                var taskName = "";
                if (row.task_id) {
                    var rs_task = tx.executeSql("SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.task_id, row.task_id]);
                    if (rs_task.rows.length > 0) taskName = rs_task.rows.item(0).name;
                }

                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }
                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    account_id: (row.account_id !== undefined && row.account_id !== null) ? row.account_id : 0,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in fetchTimesheetsByStatusPaginated:", e.message)
        DBCommon.logException("fetchTimesheetsByStatusPaginated", e);
    }

    return timesheetList;
}

/**
 * Paginated version of fetchTimesheetsForAllAccounts for infinite scroll.
 * 
 * @param {string} status - Status filter: 'all', 'active', 'draft', etc.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} - A list of enriched timesheet entries.
 */
function fetchTimesheetsForAllAccountsPaginated(status, limit, offset) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        db.transaction(function (tx) {
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT id, odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                if (projectRow.odoo_record_id) {
                    projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
                }
                if (projectRow.id) {
                    projectColorMap[projectRow.id] = projectRow.color_pallet;
                }
            }

            var query = "";
            var params = [];

            if (!status || status.toLowerCase() === "all") {
                query = "SELECT * FROM account_analytic_line_app WHERE status IS NULL OR status != 'deleted' ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [limit, offset];
            } else if (status === "draft") {
                query = "SELECT * FROM account_analytic_line_app WHERE (status = 'draft' OR status = 'saved') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [limit, offset];
            } else {
                query = "SELECT * FROM account_analytic_line_app WHERE status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                params = [status, limit, offset];
            }

            var result = tx.executeSql(query, params);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);
                var quadrantMap = { 0: "Unknown", 1: "Do", 2: "Plan", 3: "Delegate", 4: "Delete" };

                var projectName = "Unknown Project";
                var inheritedColor = 0;
                if (row.project_id) {
                    var rs_project = tx.executeSql("SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.project_id, row.project_id]);
                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            var rs_parent = tx.executeSql("SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [project_row.parent_id, project_row.parent_id]);
                            projectName = rs_parent.rows.length > 0 ? rs_parent.rows.item(0).name + " / " + project_row.name : project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                var taskName = "";
                if (row.task_id) {
                    var rs_task = tx.executeSql("SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.task_id, row.task_id]);
                    if (rs_task.rows.length > 0) taskName = rs_task.rows.item(0).name;
                }

                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }
                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    account_id: (row.account_id !== undefined && row.account_id !== null) ? row.account_id : 0,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in fetchTimesheetsForAllAccountsPaginated:", e.message)
        DBCommon.logException("fetchTimesheetsForAllAccountsPaginated", e);
    }

    return timesheetList;
}

/**
 * Retrieves all non-deleted timesheet entries for a specific task from the local SQLite database.
 *
 * @param {number} taskOdooRecordId - The Odoo record ID of the task.
 * @param {number} accountId - The account ID (optional, if provided will filter by account).
 * @param {string} status - The status filter: 'all', 'active', 'draft', etc.
 * @returns {Array<Object>} - A list of enriched timesheet entries for the task.
 */
function getTimesheetsForTask(taskOdooRecordId, accountId, status, startDate, endDate) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];

    try {
        db.transaction(function (tx) {
            // Build map of odoo_record_id -> color_pallet
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                projectColorMap[projectRow.odoo_record_id] = projectRow.color_pallet;
            }

            var query = "";
            var params = [];

            // Build query based on status and accountId
            var baseQuery = "SELECT * FROM account_analytic_line_app WHERE task_id = ?";
            var dateCondition = "";
            
            if (startDate) {
                dateCondition += " AND DATE(record_date) >= DATE(?)";
            }
            if (endDate) {
                dateCondition += " AND DATE(record_date) <= DATE(?)";
            }
            
            if (!status || status.toLowerCase() === "all") {
                if (accountId && accountId > 0) {
                    query = baseQuery + " AND account_id = ? AND (status IS NULL OR status != 'deleted')" + dateCondition + " ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                    params = [taskOdooRecordId, accountId];
                } else {
                    query = baseQuery + " AND (status IS NULL OR status != 'deleted')" + dateCondition + " ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                    params = [taskOdooRecordId];
                }
            } else {
                if (accountId && accountId > 0) {
                    query = baseQuery + " AND account_id = ? AND status = ?" + dateCondition + " ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                    params = [taskOdooRecordId, accountId, status];
                } else {
                    query = baseQuery + " AND status = ?" + dateCondition + " ORDER BY COALESCE(last_modified, record_date) DESC, id DESC";
                    params = [taskOdooRecordId, status];
                }
            }
            
            if (startDate) params.push(startDate);
            if (endDate) params.push(endDate);

            Logger.debug("Timesheet", "Executing getTimesheetsForTask query:", query, "with params:", params)
            var result = tx.executeSql(query, params);
            Logger.debug("Timesheet", "Found", result.rows.length, "timesheets for task:", taskOdooRecordId)

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                // Resolve project name and parent name
                var projectName = "Unknown Project";
                var inheritedColor = 0;

                if (row.project_id) {
                    var rs_project = tx.executeSql(
                        "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.project_id, row.project_id]
                    );

                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            // Subproject case
                            var rs_parent = tx.executeSql(
                                "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                                [project_row.parent_id, project_row.parent_id]
                            );
                            if (rs_parent.rows.length > 0) {
                                projectName = rs_parent.rows.item(0).name + " / " + project_row.name;
                            } else {
                                projectName = project_row.name;
                            }

                            // Inherit color from subproject
                            inheritedColor = projectColorMap[row.project_id] || projectColorMap[project_row.parent_id] || 0;
                        } else {
                            projectName = project_row.name;
                            inheritedColor = projectColorMap[row.project_id] || 0;
                        }
                    }
                }

                // Resolve task name
                var taskName = "Unknown Task";
                if (row.task_id) {
                    var rs_task = tx.executeSql(
                        "SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.task_id, row.task_id]
                    );
                    if (rs_task.rows.length > 0) {
                        taskName = rs_task.rows.item(0).name;
                    }
                }

                // Resolve instance and user names
                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }

                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in getTimesheetsForTask:", e.message)
        DBCommon.logException("getTimesheetsForTask", e);
    }

    return timesheetList;
}

/**
 * Paginated version of getTimesheetsForTask for infinite scroll.
 *
 * @param {number} taskOdooRecordId - The Odoo record ID of the task.
 * @param {number} accountId - The account ID (optional, if provided will filter by account).
 * @param {string} status - The status filter: 'all', 'active', 'draft', etc.
 * @param {number} limit - Maximum number of items to return.
 * @param {number} offset - Number of items to skip.
 * @returns {Array<Object>} - A list of enriched timesheet entries for the task.
 */
function getTimesheetsForTaskPaginated(taskOdooRecordId, accountId, status, limit, offset) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheetList = [];
    limit = limit || 30;
    offset = offset || 0;

    try {
        db.transaction(function (tx) {
            // Build map of odoo_record_id -> color_pallet
            var projectColorMap = {};
            var projectResult = tx.executeSql("SELECT odoo_record_id, color_pallet, account_id FROM project_project_app");
            for (var j = 0; j < projectResult.rows.length; j++) {
                var projectRow = projectResult.rows.item(j);
                var colorKey = projectRow.account_id + ":" + projectRow.odoo_record_id;
                projectColorMap[colorKey] = projectRow.color_pallet;
            }

            var query = "";
            var params = [];

            // Build query based on status and accountId with LIMIT/OFFSET
            if (!status || status.toLowerCase() === "all") {
                if (accountId && accountId > 0) {
                    query = "SELECT * FROM account_analytic_line_app WHERE task_id = ? AND account_id = ? AND (status IS NULL OR status != 'deleted') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                    params = [taskOdooRecordId, accountId, limit, offset];
                } else {
                    query = "SELECT * FROM account_analytic_line_app WHERE task_id = ? AND (status IS NULL OR status != 'deleted') ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                    params = [taskOdooRecordId, limit, offset];
                }
            } else {
                if (accountId && accountId > 0) {
                    query = "SELECT * FROM account_analytic_line_app WHERE task_id = ? AND account_id = ? AND status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                    params = [taskOdooRecordId, accountId, status, limit, offset];
                } else {
                    query = "SELECT * FROM account_analytic_line_app WHERE task_id = ? AND status = ? ORDER BY COALESCE(last_modified, record_date) DESC, id DESC LIMIT ? OFFSET ?";
                    params = [taskOdooRecordId, status, limit, offset];
                }
            }

            var result = tx.executeSql(query, params);

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var quadrantMap = {
                    0: "Unknown",
                    1: "Do",
                    2: "Plan",
                    3: "Delegate",
                    4: "Delete"
                };

                // Resolve project name and parent name
                var projectName = "Unknown Project";
                var inheritedColor = 0;

                if (row.project_id) {
                    var accountId = (row.account_id !== undefined && row.account_id !== null) ? row.account_id : null;
                    var rs_project = (accountId !== null) ?
                        tx.executeSql(
                            "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) AND account_id = ? LIMIT 1",
                            [row.project_id, row.project_id, accountId]
                        ) :
                        tx.executeSql(
                            "SELECT name, parent_id FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                            [row.project_id, row.project_id]
                        );

                    if (rs_project.rows.length > 0) {
                        var project_row = rs_project.rows.item(0);
                        if (project_row.parent_id && project_row.parent_id > 0) {
                            var rs_parent = (accountId !== null) ?
                                tx.executeSql(
                                    "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) AND account_id = ? LIMIT 1",
                                    [project_row.parent_id, project_row.parent_id, accountId]
                                ) :
                                tx.executeSql(
                                    "SELECT name FROM project_project_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                                    [project_row.parent_id, project_row.parent_id]
                                );
                            if (rs_parent.rows.length > 0) {
                                projectName = rs_parent.rows.item(0).name + " / " + project_row.name;
                            } else {
                                projectName = project_row.name;
                            }
                            var projectColorKey = accountId + ":" + row.project_id;
                            var parentColorKey = accountId + ":" + project_row.parent_id;
                            inheritedColor = projectColorMap[projectColorKey] || projectColorMap[parentColorKey] || 0;
                        } else {
                            projectName = project_row.name;
                            var directColorKey = accountId + ":" + row.project_id;
                            inheritedColor = projectColorMap[directColorKey] || 0;
                        }
                    }
                }

                // Resolve task name
                var taskName = "Unknown Task";
                if (row.task_id) {
                    var rs_task = tx.executeSql(
                        "SELECT name FROM project_task_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1",
                        [row.task_id, row.task_id]
                    );
                    if (rs_task.rows.length > 0) {
                        taskName = rs_task.rows.item(0).name;
                    }
                }

                // Resolve instance and user names
                var instanceName = "", userName = "";
                if (row.account_id !== undefined && row.account_id !== null) {
                    var rs_instance = tx.executeSql("SELECT name FROM users WHERE id = ? LIMIT 1", [row.account_id]);
                    if (rs_instance.rows.length > 0) instanceName = rs_instance.rows.item(0).name;
                }

                if (row.user_id !== undefined && row.user_id !== null) {
                    var rs_user = tx.executeSql("SELECT name FROM res_users_app WHERE (odoo_record_id = ? OR id = ?) LIMIT 1", [row.user_id, row.user_id]);
                    if (rs_user.rows.length > 0) userName = rs_user.rows.item(0).name;
                }

                timesheetList.push({
                    id: row.id,
                    instance: instanceName,
                    name: row.name || '',
                    spentHours: Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    project: projectName,
                    quadrant: quadrantMap[row.quadrant_id] || "Unknown",
                    date: row.record_date,
                    status: row.status,
                    task: taskName,
                    user: userName,
                    timer_type: row.timer_type || 'manual',
                    color_pallet: parseInt(inheritedColor) || 0,
                    has_draft: row.has_draft || 0
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in getTimesheetsForTaskPaginated:", e.message)
        DBCommon.logException("getTimesheetsForTaskPaginated", e);
    }

    return timesheetList;
}


function getAttachmentsForTimesheet(odooRecordId) {
    var attachmentList = [];

    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            var query = `
                SELECT name, mimetype, datas
                FROM ir_attachment_app
                WHERE res_model = 'hr_timesheet.sheet' AND res_id = ?
                ORDER BY name COLLATE NOCASE ASC
            `;

            var result = tx.executeSql(query, [odooRecordId]);

            for (var i = 0; i < result.rows.length; i++) {
                attachmentList.push({
                    name: result.rows.item(i).name,
                    mimetype: result.rows.item(i).mimetype,
                    datas: result.rows.item(i).datas
                });
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "getAttachmentsForTask failed:", e)
    }

    return attachmentList;
}


function getTimesheetDisplayName(timesheetId) {
    if (!timesheetId || timesheetId <= 0) return "";
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var displayName = "";
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT t.name AS ts_name, p.name AS project_name, tk.name AS task_name " +
                "FROM account_analytic_line_app t " +
                "LEFT JOIN project_project_app p ON (t.project_id = p.odoo_record_id OR t.project_id = p.id) " +
                "LEFT JOIN project_task_app tk ON (t.task_id = tk.odoo_record_id OR t.task_id = tk.id) " +
                "WHERE t.id = ? LIMIT 1",
                [timesheetId]
            );
            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                if (row.ts_name && row.ts_name.trim() !== "") {
                    displayName = row.ts_name.trim();
                } else if (row.project_name && row.project_name.trim() !== "") {
                    displayName = row.project_name.trim() + (row.task_name ? " - " + row.task_name.trim() : "");
                } else if (row.task_name && row.task_name.trim() !== "") {
                    displayName = row.task_name.trim();
                }
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetDisplayName", e);
    }
    return displayName;
}

function getTimesheetNameById(timesheetId) {
    var displayName = getTimesheetDisplayName(timesheetId);
    if (displayName && displayName.trim() !== "") {
        return displayName;
    }

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var name = "";
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT name FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0 && rs.rows.item(0).name) {
                name = rs.rows.item(0).name;
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetNameById", e);
    }
    return name;
}

/**
 * Checks if a timesheet is ready to be synced to Odoo.
 * Both project (or sub-project) and task (or sub-task) must be assigned to prevent sync errors.
 *
 * @param {number} timesheetId - The ID of the timesheet to check
 * @returns {boolean} - True if the timesheet has both project and task assigned, false otherwise
 */
function isTimesheetReadyToRecord(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var ready = false;

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT project_id, sub_project_id, task_id, sub_task_id FROM account_analytic_line_app WHERE id = ? LIMIT 1",
                [timesheetId]
            );

            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);
                //  console.log("Project id " +row.project_id)
                //  console.log("SubProject id " + row.sub_project_id)
                //  console.log("Task id " +row.task_id  )
                //  console.log("SubTask id " +row.sub_task_id)

                var hasProjectOrSubproject = (row.project_id && row.project_id > 0) ||
                    (row.sub_project_id && row.sub_project_id > 0);

                var hasTaskOrSubtask = (row.task_id && row.task_id > 0) ||
                    (row.sub_task_id && row.sub_task_id > 0);

                // Both project and task are mandatory for sync to prevent sync errors
                ready = hasProjectOrSubproject && hasTaskOrSubtask;
            } else {
                Logger.debug("Timesheet", "Timesheet ID " + timesheetId + " not found in DB.")
            }
        });
    } catch (e) {
        Logger.debug("Timesheet", "isTimesheetReadyToRecord failed:", e)
    }

    return ready;
}

/**
 * Checks if a timesheet is ready to start timer tracking.
 * Only requires a project (or sub-project) to be assigned, allowing draft timesheets to be tracked.
 *
 * @param {number} timesheetId - The ID of the timesheet to check
 * @returns {boolean} - True if the timesheet has a project assigned, false otherwise
 */
function isTimesheetReadyToStartTimer(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var ready = false;

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT project_id, sub_project_id FROM account_analytic_line_app WHERE id = ? LIMIT 1",
                [timesheetId]
            );

            if (rs.rows.length > 0) {
                var row = rs.rows.item(0);

                var hasProjectOrSubproject = (row.project_id && row.project_id > 0) ||
                    (row.sub_project_id && row.sub_project_id > 0);

                // Only project is required for timer start - task can be selected later
                ready = hasProjectOrSubproject;
            } else {
                Logger.debug("Timesheet", "Timesheet ID " + timesheetId + " not found in DB.")
            }
        });
    } catch (e) {
        Logger.debug("Timesheet", "isTimesheetReadyToStartTimer failed:", e)
    }

    return ready;
}


/**
/**
 * Marks a timesheet entry as deleted in the local SQLite database by setting its `status` to `'deleted'`.
 *
 * This is a soft delete and does not remove the record from the database.
 *
 * @param {number} taskId - The ID of the timesheet entry to be marked as deleted.
 * @returns {Object} - An object with `success` (boolean) and `message` (string) indicating the result.
 */
function markTimesheetAsDeleted(taskId) {
    try {
        var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);

        db.transaction(function (tx) {
            tx.executeSql(
                "UPDATE account_analytic_line_app SET status = 'deleted' WHERE id = ?",
                [taskId]
            );
        });

        DBCommon.log("Timesheet marked as deleted (id: " + taskId + ")");

        // Clean up any drafts for this deleted timesheet
        try {
            DraftManager.cleanupDraftsForDeletedRecords("timesheet", [taskId]);
        } catch (draftError) {
            Logger.warn("Timesheet", "Failed to cleanup timesheet draft:", draftError)
            // Don't fail the deletion if draft cleanup fails
        }

        return { success: true, message: "Timesheet marked as deleted." };

    } catch (e) {
        DBCommon.logException("markTimesheetAsDeleted", e);
        return { success: false, message: "Failed to mark as deleted: " + e.message };
    }
}

/**
 * Retrieves details of a specific timesheet entry by its local database ID.
 *
 * The returned object includes project/task associations, recorded hours,
 * quadrant classification, and a formatted record date.
 *
 * @param {number} record_id - The local database ID of the timesheet entry.
 * @returns {Object} - A timesheet detail object, or an empty object if not found.
 */
function getTimeSheetDetails(record_id, accountId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheet_detail = {};

    try {
        db.transaction(function (tx) {
            var query = 'SELECT * FROM account_analytic_line_app WHERE id = ?';
            var params = [record_id];


            if (accountId !== undefined && accountId !== null && accountId !== -1) {
                query += ' AND account_id = ?';
                params.push(accountId);
                Logger.debug("Timesheet", "Applying security filter - accountId:", accountId)
            } else {
                Logger.debug("Timesheet", "WARNING: No account filter applied - this may be a security risk")
            }

            Logger.debug("Timesheet", "Executing query:", query, "with params:", params)

            var timesheet = tx.executeSql(query, params);

            if (timesheet.rows.length) {
                var row = timesheet.rows.item(0);
                Logger.debug("Timesheet", "Found record with account_id:", row.account_id)
                Logger.debug("Timesheet", "getTimeSheetDetails: Raw user_id from DB:", row.user_id)

                timesheet_detail = {
                    'id': row.id,
                    'instance_id': row.account_id,
                    'account_id': row.account_id,
                    'status': row.status || 'draft',
                    'project_id': row.project_id,
                    'sub_project_id': row.sub_project_id,
                    'task_id': row.task_id,
                    'sub_task_id': row.sub_task_id,
                    'name': row.name,
                    'spentHours': Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    'quadrant_id': row.quadrant_id,
                    'record_date': Utils.formatDate(new Date(row.record_date)),
                    'timer_type': row.timer_type || 'manual',
                    'user_id': row.user_id,
                    'has_draft': row.has_draft || 0,
                    'odoo_record_id': row.odoo_record_id
                };

                Logger.debug("Timesheet", "getTimeSheetDetails: Returning timesheet_detail:", JSON.stringify(timesheet_detail))
            } else {
                Logger.debug("Timesheet", "No matching record found for id:", record_id, "accountId:", accountId)


                var debugCheck = tx.executeSql('SELECT account_id FROM account_analytic_line_app WHERE id = ?', [record_id]);
                if (debugCheck.rows.length) {
                    Logger.debug("Timesheet", "Record exists but has account_id:", debugCheck.rows.item(0).account_id,
                        "Expected:", accountId);
                } else {
                    Logger.debug("Timesheet", "Record with id", record_id, "does not exist in database")
                }
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in getTimeSheetDetails:", e.message)
        DBCommon.logException("getTimeSheetDetails", e);
    }

    return timesheet_detail;
}

/**
 * Retrieves timesheet details by Odoo record ID (stable identifier).
 * This is used for deep link navigation from notifications.
 *
 * @param {number} odoo_record_id - The Odoo record ID of the timesheet entry.
 * @param {number} [accountId] - Optional account ID to narrow the search.
 * @returns {Object} - A timesheet detail object, or an empty object if not found.
 */
function getTimeSheetDetailsByOdooId(odoo_record_id, accountId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timesheet_detail = {};

    try {
        db.transaction(function (tx) {
            var query = 'SELECT * FROM account_analytic_line_app WHERE odoo_record_id = ?';
            var params = [odoo_record_id];

            if (accountId !== undefined && accountId !== null && accountId >= 0) {
                query += ' AND account_id = ?';
                params.push(accountId);
            }

            query += ' LIMIT 1';
            var timesheet = tx.executeSql(query, params);

            if (timesheet.rows.length) {
                var row = timesheet.rows.item(0);

                timesheet_detail = {
                    'id': row.id,
                    'instance_id': row.account_id,
                    'account_id': row.account_id,
                    'status': row.status || 'draft',
                    'project_id': row.project_id,
                    'sub_project_id': row.sub_project_id,
                    'task_id': row.task_id,
                    'sub_task_id': row.sub_task_id,
                    'name': row.name,
                    'spentHours': Utils.convertDecimalHoursToHHMM(row.unit_amount),
                    'quadrant_id': row.quadrant_id,
                    'record_date': Utils.formatDate(new Date(row.record_date)),
                    'timer_type': row.timer_type || 'manual',
                    'user_id': row.user_id,
                    'has_draft': row.has_draft || 0,
                    'odoo_record_id': row.odoo_record_id
                };

                Logger.debug("Timesheet", "getTimeSheetDetailsByOdooId found timesheet id:", row.id, "for odoo_record_id:", odoo_record_id)
            } else {
                Logger.error("Timesheet", "No timesheet found for odoo_record_id:", odoo_record_id)
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error in getTimeSheetDetailsByOdooId:", e.message)
        DBCommon.logException("getTimeSheetDetailsByOdooId", e);
    }

    return timesheet_detail;
}

/**
 * Creates a new timesheet entry or updates an existing one in the local SQLite database.
 *
 * The function decides whether to insert or update based on the presence of a valid `id` in `data`.
 * Duration is parsed based on whether the entry is manually recorded or tracked automatically.
 *
 * @param {Object} data - An object representing the timesheet fields:
 *                        - `id`, `instance_id`, `record_date`, `project`, `task`, `description`,
 *                        - `subprojectId`, `subTask`, `quadrant`, `spenthours`, `manualSpentHours`,
 *                        - `isManualTimeRecord`, `status`, `user_id`
 * @returns {Object} - An object containing `success` (boolean) and `error` (string, if any).
 */
function saveTimesheet(data) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var result = { success: false, error: "", id: null };

    // Validation: Ensure ID is provided
    if (!data.id || data.id <= 0) {
        result.error = "Invalid timesheet ID for update.";
        return result;
    }

    try {
        Logger.debug("Timesheet", "saveTimesheet: Saving timesheet data:", JSON.stringify(data))
        db.transaction(function (tx) {
            tx.executeSql(`UPDATE account_analytic_line_app SET
                          account_id = ?,
                          record_date = ?,
                          project_id = ?,
                          task_id = ?,
                          name = ?,
                          sub_project_id = ?,
                          sub_task_id = ?,
                          quadrant_id = ?,
                          unit_amount = ?,
                          last_modified = ?,
                          status = ?,
                          timer_type = ?,
                          user_id = ?,
                          has_draft = 0
                          WHERE id = ?`,
                [
                    (data.instance_id !== undefined && data.instance_id !== null) ? data.instance_id : ((data.account_id !== undefined && data.account_id !== null) ? data.account_id : null),
                    data.record_date || Utils.getToday(),
                    data.project || null,
                    data.task || null,
                    data.description || "",
                    data.subprojectId || null,
                    data.subTask || null,
                    data.quadrant || null,
                    data.unit_amount || 0,
                    timestamp,
                    data.status || "draft",
                    data.timer_type || "manual",
                    (data.user_id !== undefined && data.user_id !== null && data.user_id !== "") ? data.user_id : ((data.instance_id === 0 || data.account_id === 0) ? 1 : null),
                    data.id
                ]);

            result.success = true;
            result.id = data.id;
        });
    } catch (err) {
        result.error = err.message;
    }

    return result;
}

function createTimesheet(instance_id, userid) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var result = { success: false, error: "", id: null };

    var acctId = (instance_id !== undefined && instance_id !== null) ? parseInt(instance_id) : -1;
    if (isNaN(acctId) || acctId < 0) {
        result.error = "Invalid instance_id provided";
        return result;
    }

    var uid = (userid !== undefined && userid !== null) ? parseInt(userid) : 0;
    if (acctId === 0) {
        if (isNaN(uid) || uid <= 0) {
            uid = 1;
        }
    } else {
        if (isNaN(uid) || uid <= 0) {
            result.error = "Invalid user_id provided";
            return result;
        }
    }

    try {
        db.transaction(function (tx) {
            tx.executeSql(`INSERT INTO account_analytic_line_app
                          (account_id, record_date, project_id, task_id, name, sub_project_id,
                          sub_task_id, quadrant_id, unit_amount, last_modified, status, timer_type, user_id, has_draft)
                          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
                [
                    acctId,                    // account_id
                    Utils.getToday(),      // record_date, fallback to today
                    null,                      // project_id
                    null,                      // task_id
                    "",                        // name/description
                    null,                      // sub_project_id
                    null,                      // sub_task_id
                    0,                      // quadrant_id
                    0,                         // unit_amount
                    timestamp,                 // last_modified
                    "draft",                   // status
                    "manual",                  // timer_type - default to manual
                    uid                        // user_id
                ]);

            // Retrieve the last inserted ID
            var rs = tx.executeSql("SELECT last_insert_rowid() as id");
            if (rs.rows.length > 0) {
                result.id = rs.rows.item(0).id;
                result.success = true;
            } else {
                result.error = "Unable to retrieve the inserted record ID.";
            }
        });
    } catch (err) {
        Logger.debug("Timesheet", err.message)
        result.error = err.message;
    }

    return result;
}


/**
 * Creates a new timesheet entry from a given task by directly querying the local SQLite task table,
 * then inserting using createOrSaveTimesheet.
 *
 * @param {number} taskRecordId - The ID of the task to link to the new timesheet.
 * @returns {Object} - { success: boolean, id: number | null, error: string }
 */function createTimesheetFromTask(taskRecordId) {
    Logger.debug("Timesheet", "Creating time sheet for " + taskRecordId)
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var result = { success: false, id: null, error: "" };

    try {
        if (!taskRecordId || taskRecordId <= 0) {
            result.error = "Invalid taskRecordId provided.";
            return result;
        }

        var task = null;
        db.readTransaction(function (tx) {
            var rs = tx.executeSql("SELECT * FROM project_task_app WHERE (odoo_record_id = ? OR id = ?)", [taskRecordId, taskRecordId]);
            if (rs.rows.length > 0) {
                task = rs.rows.item(0);
            }
        });

        if (!task) {
            result.error = "Task not found in local DB." + taskRecordId;
            return result;
        }

        if (!task.project_id || task.account_id === undefined || task.account_id === null || task.account_id < 0) {
            result.error = "Task missing required project/account linkage.";
            return result;
        }

        // Always use the current logged-in user for timesheet creation
        // Even if task has an assigned user, the timesheet should belong to who is creating it
        var userId = Accounts.getCurrentUserOdooId(task.account_id);
        if (task.account_id === 0 && (!userId || userId <= 0)) {
            userId = 1;
        }
        if (!userId || userId <= 0) {
            result.error = "Unable to determine current user for account " + task.account_id;
            return result;
        }
        Logger.debug("Timesheet", "Creating timesheet for current user:", userId)

        // Use createTimesheet(instance_id, user_id) to create the empty record
        var tsResult = createTimesheet(task.account_id, userId);

        if (!tsResult.success) {
            result.error = tsResult.error || "Failed to create base timesheet record.";
            return result;
        }

        var timesheetId = tsResult.id;

        // Now update the created empty timesheet with project, task, description, etc.
        var today = Utils.getToday(); // ensure "yyyy-MM-dd"
        var effectiveTaskId = (task.account_id === 0 || !task.odoo_record_id) ? task.id : task.odoo_record_id;

        var timesheet_data = {
            id: timesheetId,
            instance_id: task.account_id,
            record_date: today,
            project: task.project_id,
            task: effectiveTaskId,
            subprojectId: task.sub_project_id || null,
            subTask: null,
            description: "Timesheet (" + today + ") " + (task.name || ""),
            unit_amount: 0,
            timer_type: "manual", // Default to manual when created from task
            status: "draft",
            user_id: userId  // Use the resolved user ID
        };

        Logger.debug("Timesheet", "Updating created timesheet ID " + timesheetId + " with task data.")

        var updateResult = saveTimesheet(timesheet_data);

        if (updateResult.success) {
            result.success = true;
            result.id = timesheetId;
        } else {
            result.error = updateResult.error || "Failed to update timesheet with task data.";
        }

    } catch (e) {
        result.error = e.toString();
    }

    return result;
}


function createTimesheetFromProject(projectRecordId) {
    Logger.debug("Timesheet", "Creating timesheet for project " + projectRecordId)
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var result = { success: false, id: null, error: "" };

    try {
        var project = null;
        db.readTransaction(function (tx) {
            var rs = tx.executeSql("SELECT * FROM project_project_app WHERE (odoo_record_id = ? OR id = ?)", [projectRecordId, projectRecordId]);
            if (rs.rows.length > 0) {
                project = rs.rows.item(0);
                Logger.debug("Timesheet", "Project data:", JSON.stringify(project))
                Logger.debug("Timesheet", "Account ID:", project.account_id)
                Logger.debug("Timesheet", "User ID:", project.user_id)
            }
        });

        if (!project) {
            result.error = "Project not found in local DB: " + projectRecordId;
            return result;
        }

        if (project.account_id === undefined || project.account_id === null || project.account_id < 0) {
            result.error = "Project missing required account_id. Current value: " + project.account_id;
            return result;
        }

        // Always use the current logged-in user for timesheet creation
        // Projects don't have assigned users, so use whoever is creating the timesheet
        var userId = Accounts.getCurrentUserOdooId(project.account_id);
        if (project.account_id === 0 && (!userId || userId <= 0)) {
            userId = 1;
        }
        if (!userId || userId <= 0) {
            result.error = "Unable to determine current user for account " + project.account_id;
            return result;
        }
        Logger.debug("Timesheet", "Creating timesheet for current user:", userId)

        // Create empty timesheet
        var tsResult = createTimesheet(project.account_id, userId);
        if (!tsResult.success) {
            result.error = tsResult.error || "Failed to create base timesheet record.";
            return result;
        }

        var timesheetId = tsResult.id;
        var today = Utils.getToday();
        var effectiveProjectId = (project.account_id === 0 || !project.odoo_record_id) ? project.id : project.odoo_record_id;

        // Update timesheet with project data
        var timesheet_data = {
            id: timesheetId,
            instance_id: project.account_id,
            record_date: today,
            project: effectiveProjectId,
            task: null, // No specific task for project-level timesheet
            subprojectId: null,
            subTask: null,
            description: "Project Timesheet (" + today + ") " + (project.name || ""),
            unit_amount: 0,
            timer_type: "manual", // Default to manual when created from project
            status: "draft",
            user_id: userId // Use the resolved user ID
        };

        var updateResult = saveTimesheet(timesheet_data);
        if (updateResult.success) {
            result.success = true;
            result.id = timesheetId;
        } else {
            result.error = updateResult.error || "Failed to update timesheet with project data.";
        }

    } catch (e) {
        result.error = e.toString();
    }

    return result;
}


function doesProjectIdMatchSheetInActive(projectId, sheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var matches = false;

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT id FROM account_analytic_line_app WHERE id = ? AND status = ? AND (project_id = ? OR sub_project_id = ?) LIMIT 1",
                [sheetId, "active", projectId, projectId]
            );
            if (rs.rows.length > 0) {
                matches = true;
            }
        });
    } catch (e) {
        Logger.debug("Timesheet", "doesProjectIdMatchSheetInActive failed:", e)
    }

    return matches;
}

function doesTaskIdMatchSheetInActive(taskId, sheetId) {
    //console.log("Checking if sheet ID " + sheetId + " has task ID " + taskId + " in DRAFT status...");

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var matches = false;

    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql(
                "SELECT id FROM account_analytic_line_app WHERE id = ? AND status = ? AND (task_id = ? OR sub_task_id = ?) LIMIT 1",
                [sheetId, "active", taskId, taskId]
            );

            if (rs.rows.length > 0) {
                Logger.debug("Timesheet", "Sheet ID " + sheetId + " with task ID " + taskId + " found in DRAFT timesheets.")
                matches = true;
            }
        });
    } catch (e) {
        Logger.debug("Timesheet", "doesTaskIdMatchSheetInDraft failed:", e)
    }

    return matches;
}


function updateTimesheetWithDuration(timesheetId, durationHours) {
    Logger.debug("Timesheet", "Updating timesheet " + timesheetId + " with hours " + durationHours)

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();
    var time_taken = Utils.convertHHMMtoDecimalHours(durationHours)
    Logger.debug("Timesheet", "Updating duration : " + time_taken)

    try {
        db.transaction(function (tx) {
            // Only update duration and timestamp, preserve existing status
            tx.executeSql(
                "UPDATE account_analytic_line_app SET unit_amount = ?, last_modified = ? WHERE id = ?",
                [time_taken, timestamp, timesheetId]
            );
        });
    } catch (e) {
        Logger.debug("Timesheet", "updateTimesheetWithDuration failed:", e)
    }
}

function markTimesheetAsActiveById(timesheetId) {
    Logger.debug("Timesheet", "Marking timesheet " + timesheetId + " as active")

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();

    try {
        db.transaction(function (tx) {
            // Revert any other timesheets previously marked 'active' to 'draft'
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = 'draft' WHERE status = 'active' AND id != ?",
                [timestamp, timesheetId]
            );
            // Mark target timesheet as active
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "active", timesheetId]
            );
        });
        Logger.debug("Timesheet", "Timesheet " + timesheetId + " marked as active successfully.")
    } catch (e) {
        Logger.debug("Timesheet", "markTimesheetAsActiveById failed:", e)
    }
}

/**
 * Retrieves the account_id for a given timesheet record.
 *
 * @param {number} timesheetId - The ID of the timesheet
 * @returns {number} - The account ID or -1 if not found
 */
function getTimesheetAccountId(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var accountId = -1;
    try {
        db.readTransaction(function (tx) {
            var rs = tx.executeSql("SELECT account_id FROM account_analytic_line_app WHERE id = ? LIMIT 1", [timesheetId]);
            if (rs.rows.length > 0) {
                var raw = rs.rows.item(0).account_id;
                accountId = (raw !== undefined && raw !== null) ? parseInt(raw) : 0;
            }
        });
    } catch (e) {
        Logger.debug("Timesheet", "getTimesheetAccountId failed:", e);
    }
    return accountId;
}

/**
 * Marks a timesheet as saved in the local SQLite database by setting its status to 'saved'.
 * Used for local account timesheets that do not require Odoo sync.
 *
 * @param {number} timesheetId - The ID of the timesheet
 * @returns {Object} - Result with success and error
 */
function markTimesheetAsSavedById(timesheetId) {
    var result = { success: false, error: "", id: timesheetId };
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();

    try {
        db.transaction(function (tx) {
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "saved", timesheetId]
            );
        });
        Logger.debug("Timesheet", "Timesheet " + timesheetId + " marked as saved successfully.");
        result.success = true;
    } catch (e) {
        Logger.error("Timesheet", "markTimesheetAsSavedById failed:", e);
        result.error = e.message;
    }
    return result;
}

/**
 * Marks a timesheet as ready to be synced to Odoo by setting its status to "updated",
 * or as "saved" if it belongs to a local account.
 *
 * @param {number} timesheetId - The ID of the timesheet
 * @returns {Object} - An object with `success` (boolean) and `error` (string) indicating the result
 */
function markTimesheetAsReadyById(timesheetId) {
    var result = { success: false, error: "", id: null };

    // For local accounts, mark directly as 'saved' without Odoo sync validation
    var accountId = getTimesheetAccountId(timesheetId);
    if (accountId === 0) {
        return markTimesheetAsSavedById(timesheetId);
    }

    if (!isTimesheetReadyToRecord(timesheetId)) {
        result.success = false;
        result.error = "Timesheet not ready - both project and task must be selected";
        return result;
    }

    Logger.debug("Timesheet", "Marking timesheet " + timesheetId + " as updated for sync")

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();

    try {
        db.transaction(function (tx) {

            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "updated", timesheetId]
            );
        });
        Logger.debug("Timesheet", "Timesheet " + timesheetId + " marked as updated successfully.")
        result.success = true;
    } catch (e) {
        Logger.debug("Timesheet", "markTimesheetAsReadyById failed:", e)
        result.success = false;
        result.error = e.message;
    }
    return result;
}

/**
 * Checks if a timesheet is finalized (has "updated" or "saved" status).
 *
 * @param {number} timesheetId - The ID of the timesheet to check
 * @returns {boolean} - True if the timesheet is finalized, false otherwise
 */
function isTimesheetFinalized(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var isFinalized = false;

    try {
        db.transaction(function (tx) {
            var result = tx.executeSql("SELECT status FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (result.rows.length > 0) {
                var status = result.rows.item(0).status;
                isFinalized = (status === "updated" || status === "saved");
                Logger.debug("Timesheet", "Timesheet", timesheetId, "status:", status, "finalized:", isFinalized)
            }
        });
    } catch (e) {
        Logger.error("Timesheet", "Error checking timesheet finalization status:", e)
    }

    return isFinalized;
}

function markTimesheetAsDraftById(timesheetId) {
    var result = { success: false, error: "", id: null };

    Logger.debug("Timesheet", "Marking timesheet " + timesheetId + " as draft")

    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var timestamp = Utils.getFormattedTimestampUTC();

    try {
        db.transaction(function (tx) {
            tx.executeSql(
                "UPDATE account_analytic_line_app SET last_modified = ?, status = ? WHERE id = ?",
                [timestamp, "draft", timesheetId]
            );
        });
        Logger.debug("Timesheet", "Timesheet " + timesheetId + " marked as draft successfully.")
        result.success = true;
    } catch (e) {
        Logger.debug("Timesheet", "markTimesheetAsDraftById failed:", e)
        result.success = false;
        result.error = e.message;
    }
    return result;
}

function getTimesheetUnitAmount(timesheetId) {
    var db = Sql.LocalStorage.openDatabaseSync(DBCommon.NAME, DBCommon.VERSION, DBCommon.DISPLAY_NAME, DBCommon.SIZE);
    var unitAmount = 0;
    try {
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT unit_amount FROM account_analytic_line_app WHERE id = ?", [timesheetId]);
            if (rs.rows.length > 0 && rs.rows.item(0).unit_amount !== null) {
                unitAmount = parseFloat(rs.rows.item(0).unit_amount);
            }
        });
    } catch (e) {
        DBCommon.logException("getTimesheetUnitAmount", e);
    }
    return unitAmount;
}
