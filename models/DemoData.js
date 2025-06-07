.import QtQuick.LocalStorage 2.7 as Sql

/* Name: record_demo_data
* This function will fill the demo data, and every time it will erase existing
* and fill demo data
*/

function record_demo_data() {
    var db = Sql.LocalStorage.openDatabaseSync("timemanagement", "1.0", "Time Management", 1000000);

    db.transaction(function(tx) {
        tx.executeSql('delete from account_analytic_line_app');
        tx.executeSql('delete from project_task_app');
        tx.executeSql('delete from project_project_app');
    });

    db.transaction(function(tx) {
        tx.executeSql('delete from project_project_app');

        tx.executeSql("INSERT INTO project_project_app (id, name, planned_start_date, planned_end_date, allocated_hours)\
            VALUES (1, 'Internal DEC-2024', '12/01/2024', '12/25/2024', 30),\
            (2, 'Meeting 2024', '01/01/2024', '12/31/2024', 200),\
            (3, 'Travel Q4-2024', '06/01/2024', '12/31/2024', 80),\
            (4, 'SO Generation', '01/01/2025', '31/01/2025', 25)\
            ");
    });

    db.transaction(function(tx) {
        tx.executeSql('delete from project_task_app');
        tx.executeSql("INSERT INTO project_task_app (id, name, project_id, start_date, end_date, initial_planned_hours)\
            VALUES (1, 'DEC Week1', 1, '12/02/2024', '12/06/2024', 10),\
            (2, 'DEC Week2', 1, '12/09/2024', '12/13/2024', 10),\
            (3, 'DEC Week3', 1, '12/16/2024', '12/20/2024', 10),\
            (4, 'DEC Week4', 1, '12/23/2024', '12/27/2024', 10),\
            (5, 'DEC Week5', 1, '12/30/2024', '12/31/2024', 2),\
            (6, 'Client Visit', 2, '01/01/2024', '31/01/2024', 12),\
            (7, 'Finalize Project', 2, '02/01/2024', '28/01/2024', 12),\
            (8, 'Deployment', 2, '03/01/2024', '03/31/2024', 20),\
            (9, 'Berlin Visit', 3, '06/01/2024', '06/05/2024', 20),\
            (10, 'London Visit', 3, '06/01/2024', '06/05/2024', 20),\
            (11, 'India Visit', 3, '06/01/2024', '06/05/2024', 22)\
            ");
    });

    db.transaction(function(tx) {
        tx.executeSql('delete from account_analytic_line_app');
        tx.executeSql("INSERT INTO account_analytic_line_app (id, name, project_id, task_id, unit_amount, quadrant_id, record_date)\
            VALUES (1, 'Discussion with Marc', 1, 1, 2, 0, '12/03/2024'),\
            (2, 'Discussion with Team', 1, 1, 2, 3, '12/04/2024'),\
            (3, 'Attend call and discuss for upgrades', 2, 5, 3, 1, '12/01/2024'),\
            (5, 'Discussion with CEO',1, 1, 2, 1, '12/05/2024')\
            ");
    });
}
