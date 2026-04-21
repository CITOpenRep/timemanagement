import QtQuick 2.6
import Lomiri.Components 1.3
import QtQuick.LocalStorage 2.7 as Sql

Item {
    id: globalWidgets
    z: 10000
    
    property var rootApp
    property alias globalTimerWidget: globalTimerWidget
    property alias backend_bridge: backend_bridge
    property alias notifPopup: notifPopup
    property alias imagePreviewer: imagePreviewer
    property alias accountPicker: accountPicker
    property alias infobar: infobar
    
    anchors.fill: parent

    GlobalTimerWidget {
        id: globalTimerWidget
        z: 999
        anchors.bottom: parent.bottom
        visible: false
        showNotification: function (title, message, type) {
            notifPopup.open(title, message, type);
        }
    }

    BackendBridge {
        id: backend_bridge
        onPythonError: function (tb) {
            console.error("[FAILURE] Critical Error from backend");
        }
        onReadyChanged: if (ready) {
            console.log("Backend ready");
        }
    }

    ImagePreviewer {
        id: imagePreviewer
        anchors.fill: parent
    }

    AccountSelectorDialog {
        id: accountPicker
        titleText: i18n.dtr("ubtms", "Switch account")
        restrictToLocalOnly: false

        onAccepted: function (id, name) {
            if(rootApp) {
                rootApp.currentAccountId = id;
                rootApp.currentAccountName = name;
                rootApp.globalAccountChanged(id, name);
                rootApp.accountDataRefreshRequested(id);
            }
        }
    }

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
}
