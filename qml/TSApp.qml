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
import "../models/dbinit.js" as DbInit

MainView {
    id: mainView

    objectName: "TS"
    applicationName: "ubtms"
    property bool init: true

    width: units.gu(50)
    //  width: Screen.desktopAvailableWidth < units.gu(130) ? units.gu(40) : units.gu(130)
    // width: units.gu(50) //GM: for testing with only one column
    // height: units.gu(95)

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
           // console.log("First Screen " + columns);
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
        DbInit.initializeDatabase();
        Qt.callLater(function () {
            apLayout.setFirstScreen(); // Delay page setup until after DB init
        });
    }
}
