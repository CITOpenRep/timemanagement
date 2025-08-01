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

    width: units.gu(50)
    //  width: Screen.desktopAvailableWidth < units.gu(130) ? units.gu(40) : units.gu(130)
    // width: units.gu(50) //GM: for testing with only one column
    // height: units.gu(95)

    GlobalTimerWidget {
        id: globalTimerWidget
        z: 9999
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: false
    }

    AdaptivePageLayout {
        id: apLayout
        anchors.fill: parent
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
        }
        Dashboard2 {
            id: dashboard_page2
        }
        Timesheet {
            id: timesheet_page
        }
        Activity_Page {
            id: activity_page
        }
        Task_Page {
            id: task_page
        }
        Project_Page {
            id: project_page
        }
        Settings_Page {
            id: settings_page
        }
        Timesheet_Page {
            id: timesheet_list
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
            //   console.log("In setCurrentPage Page is :" + page + " Current Page" + currentPage);
            switch (page) {
            case 0:
                currentPage = dashboard_page;
                thirdPage = dashboard_page2;
                if (apLayout.columns === 3)
                //                        addPageToNextColumn(currentPage,thirdPage);
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
            //  console.log("onColumnsChanged: " + columns + " width " + units.gu(width));
            if (init === false) {
                //  console.log("currentPage: " + currentPage + "Primarypage: " + primaryPage + " column changed " + columns + " width " + units.gu(width));
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
    Component.onCompleted: {
        // console.log("From OnComplete " + columns);

        // Initialize database first
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


                // Set Light Mode as default (you can change this to SuruDark if you prefer dark)
                var defaultTheme = "Ubuntu.Components.Themes.Ambiance";
                Theme.name = defaultTheme;
                saveThemePreference(defaultTheme);

               
            }
        } catch (e) {

            // Fallback to light theme if there's an error
            Theme.name = "Ubuntu.Components.Themes.Ambiance";
        }
    }

    // Function to get saved theme preference from database
    function getSavedThemePreference() {
        try {
            //   console.log("🗄️ Opening database for theme preference...");
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var themeName = "";

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Get saved theme
                var result = tx.executeSql('SELECT value FROM app_settings WHERE key = ?', ['theme_preference']);
                //   console.log("🗄️ Database query result rows:", result.rows.length);
                if (result.rows.length > 0) {
                    themeName = result.rows.item(0).value;
                    // console.log("🗄️ Found saved theme in database:", themeName);
                }
            });

            return themeName;
        } catch (e) {
            console.warn("🗄️ Error getting saved theme preference:", e);
            return "";
        }
    }

    // Function to save theme preference to database
    function saveThemePreference(themeName) {
        try {
            // console.log("💾 Saving theme preference to database:", themeName);
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);

            db.transaction(function (tx) {
                // Create settings table if it doesn't exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');

                // Save theme preference (INSERT OR REPLACE)
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)', ['theme_preference', themeName]);
                //    console.log("💾 Theme preference saved successfully:", themeName);
            });

            //    console.log("💾 Database transaction completed for theme:", themeName);
        } catch (e) {
            console.warn("💾 Error saving theme preference:", e);
        }
    }
}
