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

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Controls 2.2 as Controls
import Lomiri.Components.Popups 1.3
import "../../../../models/timesheet.js" as TimesheetModel
import "../../../../models/accounts.js" as Account
import "../../../../models/global.js" as Global
import "../../../components"

Page {
    id: mainPage



    title: i18n.dtr("ubtms", "Time Manager - Time Management Dashboard")
    anchors.fill: parent
    property bool isMultiColumn: apLayout.columns > 1
    property bool isLoading: false
    property string loadingMessage: i18n.dtr("ubtms", "Loading dashboard...")
    property int refreshStage: -1
    property int lastRefreshAccountId: -999999

    // Timer for deferred loading - gives UI time to render loading indicator
    Timer {
        id: loadingTimer
        interval: 50  // 50ms delay to ensure UI renders
        repeat: false
        onTriggered: _doRefreshData()
    }

    onVisibleChanged: {
        if (visible) {
            // Update navigation tracking when Dashboard becomes visible
            Global.setLastVisitedPage("Dashboard");

            refreshData();
        }
    }

    onIsMultiColumnChanged: {
        if (isMultiColumn) {
            if (typeof mobileChartTabBar !== "undefined") {
                mobileChartTabBar.currentIndex = 0;
            }
            if (typeof mobileChartsView !== "undefined") {
                mobileChartsView.currentIndex = 0;
            }
        }
    }


    header: PageHeader {
        id: header
        StyleHints {
            foregroundColor: "white"
            backgroundColor: LomiriColors.orange
            dividerColor: LomiriColors.slate
        }
        title: i18n.dtr("ubtms", "Account") + " [" + accountPicker.selectedAccountName + "]"
        visible: true

        // Notification Bell in header
        leadingActionBar.actions: [
            Action {
                id: drawerAction
                iconName: "navigation-menu"
                text: i18n.dtr("ubtms", "Menu")
                visible: !isMultiColumn
                onTriggered: {
                    globalDrawer.open()
                }
            }
        ]

      //  trailingActionBar.visible: isMultiColumn ? false : true
        trailingActionBar.numberOfSlots: 5

        trailingActionBar.actions: [
            Action {
                id: infoAction
                iconName: "info"
                visible:!isMultiColumn
                text: i18n.dtr("ubtms", "Chart Info")
                onTriggered: {
                    PopupUtils.open(Qt.resolvedUrl("../components/ChartInfoPopup.qml"))
                }
            },
            Action {
                id: notificationAction
                iconSource: notificationBell.totalCount > 0 ? "../../../images/notification_active.png" : "../../../images/notification.png"
                text: notificationBell.totalCount > 0 ? 
                      i18n.dtr("ubtms", "Notifications") + " (" + notificationBell.totalCount + ")" : 
                      i18n.dtr("ubtms", "Notifications")
                onTriggered: {
                    notificationBell.loadNotifications();
                    if (notificationBell.totalCount > 0) {
                        notificationBell.openPopup();
                    } else {
                        notifPopup.open("No Notifications", "You have no new notifications", "info");
                    }
                }
            },
            Action {
                iconName: "reminder-new"
                text: i18n.dtr("ubtms", "New Timesheet")
                onTriggered: {
                    const defaultAccountId = Account.getDefaultAccountId();
                    const result = TimesheetModel.createTimesheet(defaultAccountId, Account.getCurrentUserOdooId(defaultAccountId));
                    if (result.success) {
                        apLayout.addPageToCurrentColumn(mainPage, Qt.resolvedUrl("../../../Timesheet.qml"), {
                            "recordid": result.id,
                            "isReadOnly": false
                        });
                    } else {
                        console.error("Error creating timesheet: " + result.message);
                    }
                }
            }
        ]
    }

    function refreshData() {
        console.log("🔄 Refreshing Dashboard data...");
        var targetAccountId = accountPicker.selectedAccountId;
        if (isLoading && refreshStage >= 0 && lastRefreshAccountId === targetAccountId) {
            return;
        }

        lastRefreshAccountId = targetAccountId;
        refreshStage = 0;
        loadingTimer.stop();
        loadingMessage = targetAccountId === -1
            ? i18n.dtr("ubtms", "Preparing all-account dashboard...")
            : i18n.dtr("ubtms", "Preparing dashboard...");
        isLoading = true;
        // Use Timer to defer the actual data loading,
        // giving QML time to render the loading indicator first
        loadingTimer.interval = 50;
        loadingTimer.start();
    }

    function finishRefreshData() {
        loadingTimer.stop();
        refreshStage = -1;
        loadingMessage = i18n.dtr("ubtms", "Loading dashboard...");
        isLoading = false;
    }

    function _doRefreshData() {
        try {
            switch (refreshStage) {
            case 0:
                console.log("🟢 Dashboard refresh stage 0: priority matrix");
                if (typeof ehoverMatrix !== "undefined" && ehoverMatrix.refreshQuadrants) {
                    ehoverMatrix.refreshQuadrants();
                }
                loadingMessage = i18n.dtr("ubtms", "Loading project chart...");
                refreshStage = 1;
                loadingTimer.interval = 0;
                loadingTimer.start();
                return;
            case 1:
                console.log("🟢 Dashboard refresh stage 1: project chart");
                if (typeof projectchart !== "undefined") {
                    projectchart.refreshForAccount(accountPicker.selectedAccountId);
                }
                loadingMessage = i18n.dtr("ubtms", "Loading additional charts...");
                refreshStage = 2;
                loadingTimer.start();
                return;
            case 2:
                console.log("🟢 Dashboard refresh stage 2: additional charts");
                if (mobileProjectChartLoader.item && typeof mobileProjectChartLoader.item.reloadData === "function")
                    mobileProjectChartLoader.item.reloadData();
                if (mobileTaskChartLoader.item && typeof mobileTaskChartLoader.item.reloadData === "function")
                    mobileTaskChartLoader.item.reloadData();
                break;
            default:
                break;
            }
        } catch(e) {
            console.error("🔴 _doRefreshData ERROR: ", e);
        }
        finishRefreshData();
    }

    DialerMenu {
        id: fabMenu
        anchors.fill: parent
        z: 9999
        menuModel: [
            {
                label: i18n.dtr("ubtms", "Task")
            },
            {
                label: i18n.dtr("ubtms", "Timesheet")
            },
            {
                label: i18n.dtr("ubtms", "Activity")
            }
        ]
        onMenuItemSelected: {
            if (index === 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../tasks/pages/Tasks.qml"), {
                    "recordid": 0,
                    "isReadOnly": false
                });
            }
            if (index === 1) {
                const result = TimesheetModel.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
                if (result.success) {
                    apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Timesheet.qml"), {
                        "recordid": result.id,
                        "isReadOnly": false
                    });
                } else {
                    console.error("Error creating timesheet: " + result.message);
                }
            }
            if (index === 2) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Activities.qml"), {
                    "isReadOnly": false
                });
            }
        }
    }

    Flickable {
        id: flick1
        width: parent.width
        height: parent.height - header.height
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        contentWidth: parent.width
        contentHeight: quadrantColumn.height + units.gu(4)
        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 1000
                easing.type: Easing.OutBounce
            }
        }

        Column {
            id: quadrantColumn
            width: parent.width
            spacing: units.gu(3)
            anchors.top: parent.top
            anchors.margins: units.gu(1)

            Item {
                id: quadrantWrapper
                width: parent.width
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: quadrantContainer
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    color: "transparent"
                    radius: units.gu(1)
                    border.color: "transparent"
                    border.width: 0

                    EHower {
                        id: ehoverMatrix
                        width: parent.width * 0.98
                        height: width
                        autoRefreshOnAccountChange: false
                        anchors.centerIn: parent
                        quadrant1Hours: "120.2"
                        quadrant2Hours: "65.5"
                        quadrant3Hours: "55.0"
                        quadrant4Hours: "178.1"
                        onQuadrantClicked: {}
                    }
                }
            }

            Item {
                id: mobileChartsTabs
                width: parent.width - units.gu(2)
                height: mobileChartsColumn.height
                anchors.horizontalCenter: parent.horizontalCenter
                visible: true

                Column {
                    id: mobileChartsColumn
                    width: parent.width
                    spacing: units.gu(1)

                    Controls.TabBar {
                        id: mobileChartTabBar
                        width: parent.width
                        visible: !isMultiColumn
                        height: visible ? implicitHeight : 0
                        currentIndex: 0
                        onCurrentIndexChanged: {
                            if (mobileChartsView.currentIndex !== currentIndex)
                                mobileChartsView.currentIndex = currentIndex;
                        }

                        background: Rectangle {
                            color: Theme.palette.normal.background
                            radius: units.gu(1)
                            border.width: 1
                            border.color: Theme.palette.normal.base
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Overview")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Projects")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Controls.TabButton {
                            text: i18n.dtr("ubtms", "Tasks")
                            width: mobileChartTabBar.width / 3
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Controls.SwipeView {
                        id: mobileChartsView
                        width: parent.width
                        height: currentIndex === 0 ? projectchart.implicitHeight
                               : currentIndex === 1 && mobileProjectChartLoader.item ? mobileProjectChartLoader.item.implicitHeight
                               : currentIndex === 2 && mobileTaskChartLoader.item ? mobileTaskChartLoader.item.implicitHeight
                               : units.gu(40)
                        currentIndex: 0
                        interactive: !isMultiColumn
                        clip: true
                        onCurrentIndexChanged: {
                            if (mobileChartTabBar.currentIndex !== currentIndex)
                                mobileChartTabBar.currentIndex = currentIndex;
                        }

                        Item {
                            ProjectPieChart {
                                id: projectchart
                                width: parent.width * 0.95
                                height: implicitHeight
                                autoRefreshOnAccountChange: false
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Item {
                            Loader {
                                id: mobileProjectChartLoader
                                anchors.fill: parent
                                active: !isMultiColumn && mobileChartsView.currentIndex === 1
                                source: "../charts/Charts3.qml"
                                onLoaded: {
                                    if (item) {
                                        item.autoRefreshOnAccountChange = false;
                                    }
                                }
                            }
                        }

                        Item {
                            Loader {
                                id: mobileTaskChartLoader
                                anchors.fill: parent
                                active: !isMultiColumn && mobileChartsView.currentIndex === 2
                                source: "../charts/Charts4.qml"
                                onLoaded: {
                                    if (item) {
                                        item.autoRefreshOnAccountChange = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

        } // end Column
    } // end Flickable

    Scrollbar {
        flickableItem: flick1
        align: Qt.AlignTrailing
    }

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (apLayout.columns === 3) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Dashboard2.qml"));
            }
        }
    }

    BottomEdge {
        id: bottomEdge
        enabled: !isMultiColumn
        height: parent.height

        hint {
            iconName: "add"
            text: i18n.dtr("ubtms", "New Timesheet")
            visible: !isMultiColumn
        }

        preloadContent: false

        contentComponent: Component {
            Item {
                width: bottomEdge.width
                height: bottomEdge.height
            }
        }

        onCommitCompleted: {
            const result = TimesheetModel.createTimesheet(Account.getDefaultAccountId(), Account.getCurrentUserOdooId(Account.getDefaultAccountId()));
            if (result.success) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Timesheet.qml"), {
                    "recordid": result.id,
                    "isReadOnly": false
                });
            } else {
                console.error("Error creating timesheet: " + result.message);
            }
            collapse();
        }
    }

    Connections {
        target: accountPicker
        onAccepted: function (accountId, accountName) {
            header.title = i18n.dtr("ubtms", "Account") + " [" + accountName + "]";
            refreshData();
        }
    }

    // NotificationBell component handles all notification UI
    NotificationBell {
        id: notificationBell
        visible: false
        parentWindow: mainPage
        
        // Track previous count to detect new notifications
        property int previousCount: 0
        
        onTotalCountChanged: {
            if (totalCount > previousCount && previousCount > 0) {
                var newCount = totalCount - previousCount;
                notifPopup.open(
                    i18n.dtr("ubtms", "New Notifications"),
                    i18n.dtr("ubtms", "You have %1 new notification(s)").arg(newCount),
                    "info"
                );
            }
            previousCount = totalCount;
        }
        
        // Handle navigation from notification clicks
        onNavigateToRecord: {
            if (navType === "Task" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../tasks/pages/Tasks.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Activity" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Activities.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isReadOnly": true
                });
            } else if (navType === "ProjectUpdate" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Updates.qml"), {
                    "recordid": recordId,
                    "accountid": accountId,
                    "isOdooRecordId": true,
                    "isReadOnly": true
                });
            } else if (navType === "Project" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Projects.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            } else if (navType === "Timesheet" && recordId > 0) {
                apLayout.addPageToNextColumn(mainPage, Qt.resolvedUrl("../../../Timesheet.qml"), {
                    "recordid": recordId,
                    "isReadOnly": true
                });
            }
        }
    }

    // Simple notification popup for messages
    NotificationPopup {
        id: notifPopup
    }

    Component.onCompleted: {
        console.log("Dashboard status is: " + mainPage.status);
        // Load notifications on startup
        notificationBell.loadNotifications();
    }

    // Loading indicator overlay
    LoadingIndicator {
        anchors.fill: parent
        visible: isLoading
        message: loadingMessage
    }
}
