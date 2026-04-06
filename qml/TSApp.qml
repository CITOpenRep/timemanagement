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
import QtQuick.Controls 2.2 as Controls
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtQuick.Layouts 1.11
import QtQuick.LocalStorage 2.7 as Sql
import "../models/dbinit.js" as DbInit
import "../models/draft_manager.js" as DraftManager
import "../models/notifications.js" as Notifications
import Pparent.Notifications 1.0
import "components"
import "."
import "components/settings"
import "settings"

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

        // Load and apply saved theme preference
        loadAndApplyTheme();
        
        // Update system badge to reflect current unread notifications
        updateSystemBadge();
        
        // Check if daemon setup is needed (missing dependencies)
        checkDaemonSetupNeeded();
        
        // Check for unsaved drafts from previous session (crash recovery)
        checkForUnsavedDrafts();
        
        // Clean up drafts for deleted records
        cleanupDeletedRecordDrafts();
        
        // Check for deep link URL in command line arguments (notification click)
        checkStartupArguments();

        Qt.callLater(function () {
            apLayout.setFirstScreen(); // Delay page setup until after DB init

        });
    }
    
    // Check if app was launched with a deep link URL (via notification click)
    function checkStartupArguments() {
        startupManager.checkStartupArguments(Qt.application.arguments);
    }

    // Forward all deep links to SystemIntegrationManager so panel and in-app notifications
    // use the exact same navigation code path.
    function handleDeepLink(uri) {
        if (systemIntegration && typeof systemIntegration.handleDeepLink === "function") {
            systemIntegration.handleDeepLink(uri);
        } else {
            console.warn("Deep link handler unavailable:", uri);
        }
    }
    
    // Function to check if background sync daemon needs setup
    function checkDaemonSetupNeeded() {
        startupManager.checkDaemonSetupNeeded();
    }
    
    // Function to update the system badge with current unread notification count
    function updateSystemBadge() {
        startupManager.updateSystemBadge();
    }
    
    // Function to check for unsaved drafts on app startup (crash recovery)
    function checkForUnsavedDrafts() {
        startupManager.checkForUnsavedDrafts();
    }
    
    // Function to clean up drafts for deleted records on app startup
    function cleanupDeletedRecordDrafts() {
        startupManager.cleanupDeletedRecordDrafts();
    }

    // Function to load saved theme preference and apply it
    function loadAndApplyTheme() {
        startupManager.loadAndApplyTheme();
    }

    AppDrawer {
        id: globalDrawer
        apLayout: apLayout
    }
}
