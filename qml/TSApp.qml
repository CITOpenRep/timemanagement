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
import "../models/dbinit.js" as DbInit
import "app"
MainView {
    id: mainView

    objectName: "TS"
    applicationName: "ubtms"
    property bool init: true
    property alias globalTimerWidget: globalWidgets.globalTimerWidget
    property alias backend_bridge: globalWidgets.backend_bridge
    property alias imagePreviewer: globalWidgets.imagePreviewer
    property alias accountPicker: globalWidgets.accountPicker
    property alias notifPopup: globalWidgets.notifPopup
    property alias infobar: globalWidgets.infobar

    property int currentAccountId: -1
    property string currentAccountName: ""


    SystemIntegrationManager {
        id: systemIntegration
        rootApp: mainView
        apLayout: apLayout
    }

    StartupManager {
        id: startupManager
        notifPopup: globalWidgets.notifPopup
        notificationSystem: systemIntegration.notificationSystem
        handleDeepLinkCallback: handleDeepLink
    }
    width: units.gu(50)
    //  width: Screen.desktopAvailableWidth < units.gu(130) ? units.gu(40) : units.gu(130)
    // width: units.gu(50) //GM: for testing with only one column
    // height: units.gu(95)

    signal globalAccountChanged(int accountId, string accountName)
    signal accountDataRefreshRequested(int accountId)
    GlobalWidgets {
        id: globalWidgets
        rootApp: mainView
    }
    AppLayout {
        id: apLayout
        rootApp: mainView
        globalDrawer: globalDrawer
        
        
    }

    

    

    

    Component.onCompleted: {
        DbInit.initializeDatabase();

        loadAndApplyTheme();
        updateSystemBadge();
        checkDaemonSetupNeeded();
        checkForUnsavedDrafts();
        cleanupDeletedRecordDrafts();
        checkStartupArguments();

        Qt.callLater(function () {
            apLayout.setFirstScreen();
        });
    }

    function checkStartupArguments() {
        startupManager.checkStartupArguments(Qt.application.arguments);
    }

    function handleDeepLink(uri) {
        if (systemIntegration && typeof systemIntegration.handleDeepLink === "function") {
            systemIntegration.handleDeepLink(uri);
        } else {
            console.warn("Deep link handler unavailable:", uri);
        }
    }
    function checkDaemonSetupNeeded() {
        startupManager.checkDaemonSetupNeeded();
    }

    function updateSystemBadge() {
        startupManager.updateSystemBadge();
    }

    function checkForUnsavedDrafts() {
        startupManager.checkForUnsavedDrafts();
    }

    function cleanupDeletedRecordDrafts() {
        startupManager.cleanupDeletedRecordDrafts();
    }

    function loadAndApplyTheme() {
        startupManager.loadAndApplyTheme();
    }

    AppDrawer {
        id: globalDrawer
        apLayout: apLayout
    }
}
