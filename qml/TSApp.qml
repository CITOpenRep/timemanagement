/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.6
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.11
import QtQuick.LocalStorage 2.7 as Sql
import "../models/dbinit.js" as DbInit
import "components"
import "."

/*
Todo: Need to Visit this Page Again and Refactor it.
This is the Main View of the Application.
It contains the AdaptivePageLayout which is used to switch between different layouts based on the screen size

*/
MainView {
    id: mainView

    objectName: "TS"
    applicationName: "ubtms"
    property bool init: true
    property alias globalTimerWidget: globalTimerWidget
    property alias backend_bridge: backend_bridge

    property int currentAccountId: -1
    property string currentAccountName: ""

    width: units.gu(50)
    //  width: Screen.desktopAvailableWidth < units.gu(130) ? units.gu(40) : units.gu(130)
    // width: units.gu(50) //GM: for testing with only one column
    // height: units.gu(95)

    signal globalAccountChanged(int accountId, string accountName)
    signal accountDataRefreshRequested(int accountId)

    GlobalTimerWidget {
        id: globalTimerWidget
        z: 9999
        anchors.bottom: parent.bottom
        visible: false
        showNotification: function (title, message, type) {
            notifPopup.open(title, message, type);
        }
    }

    BackendBridge {
        id: backend_bridge

        onMessageReceived: function (data) {}

        onPythonError: function (tb) {
            console.error("[FAILURE] Critical Error from backend");
        }

        onReadyChanged: if (ready) {
            console.log("Backend ready");
        }
    }


    // --- Fullscreen Image Previewer, Mainly used by attachment manager ---
    //GOKUL, This can be moved as a component ? Later
    Rectangle {
        id: imagePreviewer
        anchors.fill: parent
        color: "#444"
        visible: false
        z: 999   // ensure it's above all other elements
        focus: true

        property url imageSource: ""

        Image {
            id: overlayImage
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            source: imagePreviewer.imageSource
        }

        Button {
            id: closeBtn
            text: "\u2715"
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: units.gu(1)
            onClicked: imagePreviewer.visible = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: imagePreviewer.visible = false
        }
    }


    // Account Filter , Remove this , not needed, use AccountSelectorDialog
    AccountFilter {
        id: accountFilter
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 1000
        visible: false

        onAccountChanged: {

            currentAccountId = accountId;
            currentAccountName = accountName;

            globalAccountChanged(accountId, accountName);

            accountDataRefreshRequested(accountId);
            accountFilterVisible = false;
            dashboard_page.instanceSelected(accountId, accountName);
        }
    }

    AccountSelectorDialog {
        id: accountPicker
        titleText: "Switch account"
        restrictToLocalOnly: false

        onAccepted: function(id, name) {
            // persist selection, refresh views, trigger sync, etc.
            console.log("Account chosen:", id, name)
        }
        onCanceled: console.log("Account selection canceled")
    }



    // Global notification popup
    NotificationPopup {
        id: notifPopup
    }

    InfoBar {
        id: infobar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: units.gu(10)
    }

    AdaptivePageLayout {
        id: apLayout
        anchors.top: accountFilter.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        property bool isMultiColumn: true
        property Page currentPage: splash_page
        property Page thirdPage: dashboard_page2
        primaryPage: splash_page

        layouts: [
            //Tablet Layout
            PageColumnsLayout {
                when: width > units.gu(80) && width < units.gu(130)
                // column #0
                PageColumn {
                    minimumWidth: units.gu(30)
                    maximumWidth: units.gu(50)
                    preferredWidth: width > units.gu(90) ? units.gu(20) : units.gu(15)
                }
                // column #1
                PageColumn {
                    minimumWidth: units.gu(50)
                    maximumWidth: units.gu(80)
                    preferredWidth: units.gu(80)
                }
            },

            //Desktop Layout
            PageColumnsLayout {
                when: width >= units.gu(130)
                // column #0
                PageColumn {
                    minimumWidth: units.gu(30)
                    maximumWidth: units.gu(50)
                    preferredWidth: units.gu(40)
                }
                // column #1
                PageColumn {
                    minimumWidth: units.gu(70)
                    maximumWidth: units.gu(100)
                    preferredWidth: units.gu(80)
                }
                // column #2
                PageColumn {
                    fillWidth: true
                }
            }
        ]

        Splash {
            id: splash_page
        }
        Menu {
            id: menu_page
        }
        Dashboard {
            id: dashboard_page

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    if (dashboard_page.visible && typeof dashboard_page.refreshData === 'function') {
                        dashboard_page.refreshData();
                    }
                }
            }
        }
        Dashboard2 {
            id: dashboard_page2

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Dashboard2 data for account:", accountId);
                    if (dashboard_page2.visible && typeof dashboard_page2.refreshData === 'function') {
                        dashboard_page2.refreshData();
                    }
                }
            }
        }
        Timesheet {
            id: timesheet_page

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Timesheet data for account:", accountId);
                    if (timesheet_page.visible && typeof timesheet_page.refreshData === 'function') {
                        timesheet_page.refreshData();
                    }
                }
            }
        }
        Activity_Page {
            id: activity_page

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Activity data for account:", accountId);
                    if (activity_page.visible && typeof activity_page.get_activity_list === 'function') {
                        activity_page.get_activity_list();
                    }
                }
            }
        }
        Task_Page {
            id: task_page

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Task data for account:", accountId);
                    if (task_page.visible && typeof task_page.getTaskList === 'function') {
                        task_page.getTaskList(task_page.currentFilter || "today", "");
                    }
                }
            }
        }
        Project_Page {
            id: project_page

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Project data for account:", accountId);
                    if (project_page.visible && project_page.projectlist && typeof project_page.projectlist.refresh === 'function') {
                        project_page.projectlist.refresh();
                    }
                }
            }
        }
        Settings_Page {
            id: settings_page
        }
        Timesheet_Page {
            id: timesheet_list

            Connections {
                target: mainView
                onAccountDataRefreshRequested: function (accountId) {
                    console.log("🔄 Refreshing Timesheet List data for account:", accountId);
                    if (timesheet_list.visible && typeof timesheet_list.fetch_timesheets_list === 'function') {
                        timesheet_list.fetch_timesheets_list();
                    }
                }
            }
        }

        function setFirstScreen() {
            switch (columns) {
            case 1:
                primaryPage = dashboard_page;
                currentPage = dashboard_page;
                break;
            case 2:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                addPageToNextColumn(primaryPage, currentPage);
                break;
            case 3:
                primaryPage = menu_page;
                currentPage = dashboard_page;
                addPageToNextColumn(primaryPage, currentPage);
                addPageToNextColumn(currentPage, thirdPage);
                break;
            }
            init = false;
        }

        function setCurrentPage(page) {
            console.log("📄 Setting current page to:", page);
            switch (page) {
            case 0:
                currentPage = dashboard_page;
                thirdPage = dashboard_page2;
                if (apLayout.columns === 3)
                // Could add third page logic here if needed
                {}
                break;
            case 1:
                currentPage = timesheet_page;
                thirdPage = null;
                break;
            case 2:
                currentPage = activity_page;
                thirdPage = null;
                break;
            case 3:
                currentPage = task_page;
                thirdPage = null;
                break;
            case 4:
                currentPage = project_page;
                thirdPage = null;
                break;
            case 5:
                currentPage = sync_page;
                thirdPage = null;
                break;
            case 6:
                currentPage = settings_page;
                thirdPage = null;
                break;
            case 7:
                currentPage = timesheet_list;
                thirdPage = null;
                break;
            }
        }

        onColumnsChanged: {
            console.log("📐 Layout columns changed to:", columns);
            if (init === false) {
                switch (columns) {
                case 1:
                    primaryPage = dashboard_page;
                    addPageToCurrentColumn(primaryPage, currentPage);
                    break;
                case 2:
                    primaryPage = menu_page;
                    addPageToNextColumn(primaryPage, currentPage);
                    break;
                case 3:
                    primaryPage = menu_page;
                    addPageToNextColumn(primaryPage, currentPage);
                    if (thirdPage != "")
                        addPageToNextColumn(currentPage, thirdPage);
                    break;
                }
            }
        }
    }

    function reloadApplication() {
        try {
            if (typeof apLayout.removePages === 'function') {
                apLayout.removePages(apLayout.primaryPage);
            }

            apLayout.primaryPage = splash_page;
            apLayout.currentPage = splash_page;
            apLayout.thirdPage = dashboard_page2;

            init = true;

            Qt.callLater(function () {
                try {
                    apLayout.setFirstScreen();
                    Qt.callLater(function () {
                        refreshAppData();
                    });
                } catch (layoutError) {
                    console.error("❌ ERROR during setFirstScreen():", layoutError);
                    refreshAppData();
                }
            });
        } catch (e) {
            console.error("❌ ERROR during application reload:", e);
            refreshAppData();
        }

        console.log("✅ Full application reload completed");
    }

    function refreshAppData() {
        if (dashboard_page && typeof dashboard_page.refreshData === 'function') {
            dashboard_page.refreshData();
        }

        if (dashboard_page2 && typeof dashboard_page2.refreshData === 'function') {
            dashboard_page2.refreshData();
        }

        if (timesheet_list && typeof timesheet_list.fetch_timesheets_list === 'function') {
            timesheet_list.fetch_timesheets_list();
        }

        if (timesheet_page && typeof timesheet_page.refreshData === 'function') {
            timesheet_page.refreshData();
        }

        if (activity_page && typeof activity_page.get_activity_list === 'function') {
            activity_page.get_activity_list();
        }

        if (task_page && typeof task_page.getTaskList === 'function') {
            task_page.getTaskList(task_page.currentFilter || "today", "");
        }

        if (project_page && project_page.projectlist && typeof project_page.projectlist.refresh === 'function') {
            project_page.projectlist.refresh();
        }

        // Force UI layout refresh
        Qt.callLater(function () {
            forceAllPagesUIRefresh();
        });
    }

    function forceAllPagesUIRefresh() {
        if (timesheet_list && timesheet_list.timesheetlist) {
            timesheet_list.timesheetlist.forceLayout();
        }

        if (task_page && task_page.tasklist) {
            task_page.tasklist.forceLayout();
        }

        if (project_page && project_page.projectlist) {
            project_page.projectlist.forceLayout();
        }

        if (activity_page && activity_page.activitylist) {
            activity_page.activitylist.forceLayout();
        }
    }

    function openAccountDrawer() {
        if (accountFilter && typeof accountFilter.refreshAccounts === 'function') {
            accountFilter.refreshAccounts();
        } else {
            console.warn("⚠️  accountFilter.refreshAccounts function not available");
        }
    }

    Component.onCompleted: {
        DbInit.initializeDatabase();

        // Load and apply saved theme preference
        loadAndApplyTheme();

        Qt.callLater(function () {
            apLayout.setFirstScreen(); // Delay page setup until after DB init

        });
    }

    // Function to load saved theme preference and apply it
    function loadAndApplyTheme() {
        try {
            var savedTheme = getSavedThemePreference();

            if (savedTheme !== "" && savedTheme !== null && savedTheme !== undefined) {
                Theme.name = savedTheme;
            } else {
                // No saved theme found, set and save a default theme
                var defaultTheme = "Ubuntu.Components.Themes.Ambiance";
                Theme.name = defaultTheme;
                saveThemePreference(defaultTheme);
            }
        } catch (e) {
            // Fallback to light theme if there's an error
            Theme.name = "Ubuntu.Components.Themes.Ambiance";
            console.warn("⚠️  Theme loading failed, using fallback:", e);
        }
    }

    // Function to get saved theme preference from database
    function getSavedThemePreference() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var themeName = "";

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Get saved theme
                var result = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', ['theme_preference']);
                if (result.rows.length > 0) {
                    themeName = result.rows.item(0).value;
                }
            });

            return themeName;
        } catch (e) {
            console.warn("⚠️  Error getting saved theme preference:", e);
            return "";
        }
    }

    // Function to save theme preference to database
    function saveThemePreference(themeName) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save theme preference (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
            });

            console.log("💾 Theme preference saved:", themeName);
        } catch (e) {
            console.warn("⚠️  Error saving theme preference:", e);
        }
    }
}
