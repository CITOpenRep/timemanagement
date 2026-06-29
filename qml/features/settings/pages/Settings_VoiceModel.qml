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
import QtQuick.Controls 2.2
import QtQuick.LocalStorage 2.7 as Sql
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtGraphicalEffects 1.0
import "../components"
import "../../../components"
import "../../../components/navigation" as Nav
Page {
    id: voiceModelSettingsPage
    title: i18n.dtr("ubtms", "Voice Model (Beta)")

    header: SettingsHeader {
        id: pageHeader
        title: voiceModelSettingsPage.title
        trailingActions: [
            Action {
                iconName: "info"
                onTriggered: PopupUtils.open(infoDialogComponent, voiceModelSettingsPage)
            },
            Action {
                iconName: "search"
                onTriggered: {
                    myTaskListHeader.toggleSearchVisibility()
                }
            },
            Action {
                iconName: "reload"
                onTriggered: refreshModels()
                enabled: !isDownloading
            }
        ]
    }

    property string activeModelPath: ""
    property bool isLoading: false
    property bool isDownloading: false
    property string downloadingModelId: ""
    property string downloadingModelName: ""
    property string failedModelId: ""
    property var downloadStatus: { "in_progress": false, "progress": 0, "message": "", "error": "" }
    property int deviceRamMB: 2048
    property bool isVoiceInputEnabled: true
    property string searchQuery: ""
    property var allInstalledModels: []
    property var allAvailableModels: []

    Timer {
        id: searchDebounceTimer
        interval: 300
        onTriggered: {
            filterModels();
        }
    }

    onSearchQueryChanged: {
        searchDebounceTimer.restart();
    }

    function getVoiceInputEnabledSetting() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = true;
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = "voice_input_enabled"');
                if (rs.rows.length > 0) {
                    result = rs.rows.item(0).value === "true";
                }
            });
            return result;
        } catch (e) {
            console.warn("Error reading voice_input_enabled setting:", e);
            return true;
        }
    }

    function saveVoiceInputEnabledSetting(value) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES ("voice_input_enabled", ?)', [value ? "true" : "false"]);
            });
            isVoiceInputEnabled = value;
        } catch (e) {
            console.warn("Error saving voice_input_enabled setting:", e);
        }
    }

    function isModelCompatible(sizeStr) {
        if (!sizeStr) return true;
        var upperSize = sizeStr.toUpperCase();
        var isG = upperSize.indexOf("G") !== -1;
        if (isG) {
            var val = parseFloat(upperSize.replace("G", ""));
            // Assume 1G requires ~2500MB RAM, 1.8G requires ~4000MB RAM.
            var reqRam = val * 2500; 
            return deviceRamMB >= reqRam;
        }
        return true; // MB sizes are usually compatible with any device
    }

    function getActiveModelSetting() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = "voice_to_text/model"; // Default

            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                var rs = tx.executeSql('SELECT value FROM app_settings WHERE key = "active_voice_model"');
                if (rs.rows.length > 0) {
                    result = rs.rows.item(0).value;
                }
            });
            return result;
        } catch (e) {
            console.warn("Error reading active_voice_model setting:", e);
            return "voice_to_text/model";
        }
    }

    function saveActiveModelSetting(value) {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
                tx.executeSql('INSERT OR REPLACE INTO app_settings (key, value) VALUES ("active_voice_model", ?)', [value]);
            });
            activeModelPath = value;
            console.log("Setting saved: active_voice_model =", value);
        } catch (e) {
            console.warn("Error saving active_voice_model setting:", e);
        }
    }

    function refreshModels() {
        if (!mainView.backend_bridge.ready) return;
        
        isLoading = true;
        
        mainView.backend_bridge.call("backend.list_installed_models", [], function(models) {
            isLoading = false;
            var arr = [];
            if (models) {
                for (var i = 0; i < models.length; i++) {
                    arr.push(models[i]);
                }
            }
            allInstalledModels = arr;
            filterModels();
            // After refreshing installed models, refresh available ones
            refreshAvailableModels();
        });
    }

    function filterModels() {
        modelList.clear();
        availableModelList.clear();
        
        var query = searchQuery.toLowerCase();
        
        // Installed models
        for (var i = 0; i < allInstalledModels.length; i++) {
            var m = allInstalledModels[i];
            if (query === "" || (m.m_name && m.m_name.toLowerCase().indexOf(query) !== -1) || (m.m_path && m.m_path.toLowerCase().indexOf(query) !== -1)) {
                modelList.append({
                    "name": m.m_name,
                    "path": m.m_path,
                    "m_source": m.m_source,
                    "size": m.m_size || ""
                });
            }
        }
        
        // Available models
        var installedPaths = [];
        for (var idx = 0; idx < allInstalledModels.length; idx++) {
            installedPaths.push(allInstalledModels[idx].m_path);
        }

        for (var j = 0; j < allAvailableModels.length; j++) {
            var modelId = allAvailableModels[j].id;
            var alreadyInstalled = false;
            for (var k = 0; k < installedPaths.length; k++) {
                if (installedPaths[k].indexOf(modelId) !== -1) {
                    alreadyInstalled = true;
                    break;
                }
            }

            if (!alreadyInstalled) {
                var avM = allAvailableModels[j];
                if (query === "" || (avM.name && avM.name.toLowerCase().indexOf(query) !== -1) || (avM.id && avM.id.toLowerCase().indexOf(query) !== -1)) {
                    availableModelList.append({
                        "id": avM.id,
                        "name": avM.name,
                        "size": avM.size,
                        "url": avM.url
                    });
                }
            }
        }
    }

    function refreshAvailableModels() {
        if (!mainView.backend_bridge.ready) return;
        
        mainView.backend_bridge.call("backend.list_available_models", [], function(models) {
            var arr = [];
            if (models) {
                for (var i = 0; i < models.length; i++) {
                    arr.push(models[i]);
                }
            }
            allAvailableModels = arr;
            filterModels();
        });
    }

    function downloadModel(modelId, url, modelName) {
        if (!mainView.backend_bridge.ready) return;
        
        downloadingModelId = modelId;
        downloadingModelName = modelName;
        isDownloading = true;
        
        // Start global timer widget indication at the bottom
        if (mainView.modelDownloadTimerWidget) {
            mainView.modelDownloadTimerWidget.startSync(0, modelName);
            mainView.modelDownloadTimerWidget.syncStatusMessage = i18n.dtr("ubtms", "Starting download...");
        }

        notifPopup.open(i18n.dtr("ubtms", "Download Started"), i18n.dtr("ubtms", "Downloading %1...").arg(modelName), "info");
        mainView.backend_bridge.call("backend.download_voice_model", [modelId, url], function(res) {
            if (res.status === "started") {
                downloadStatusTimer.start();
            } else {
                isDownloading = false;
                console.error("Download failed to start:", res.message);
                if (mainView.modelDownloadTimerWidget) {
                    mainView.modelDownloadTimerWidget.failSync(res.message || i18n.dtr("ubtms", "Could not start download"));
                }
                notifPopup.open(i18n.dtr("ubtms", "Download Failed"), res.message || i18n.dtr("ubtms", "Could not start download"), "error");
            }
        });
    }

    function cancelDownload() {
        if (!mainView.backend_bridge.ready) return;
        mainView.backend_bridge.call("backend.cancel_voice_model_download", [], function(res) {
            isDownloading = false;
            failedModelId = "";
            downloadStatusTimer.stop();
            if (mainView.modelDownloadTimerWidget) {
                mainView.modelDownloadTimerWidget.failSync(i18n.dtr("ubtms", "Download cancelled"));
            }
            notifPopup.open(i18n.dtr("ubtms", "Download Cancelled"), i18n.dtr("ubtms", "Download of %1 was cancelled and partial data deleted.").arg(downloadingModelName), "info");
            refreshModels();
        });
    }

    function pauseDownload() {
        if (!mainView.backend_bridge.ready) return;
        mainView.backend_bridge.call("backend.pause_voice_model_download", [], function(res) {
            // Timer will catch the state change and handle UI updates
        });
    }

    Component.onCompleted: {
        activeModelPath = getActiveModelSetting();
        isVoiceInputEnabled = getVoiceInputEnabledSetting();
        if (mainView.backend_bridge.ready) {
            refreshModels();
            checkInProgressDownload();
            checkPausedDownloads();
            fetchDeviceRam();
        }
    }

    function fetchDeviceRam() {
        mainView.backend_bridge.call("backend.get_device_total_ram_mb", [], function(ram) {
            if (ram) {
                deviceRamMB = ram;
                console.log("Device RAM detected:", deviceRamMB, "MB");
            }
        });
    }

    function checkPausedDownloads() {
        mainView.backend_bridge.call("backend.get_paused_voice_models", [], function(paused) {
            if (paused && paused.length > 0) {
                // If there are partial downloads, mark the first one as paused (failedModelId handles UI for paused state)
                failedModelId = paused[0];
            }
        });
    }

    function checkInProgressDownload() {
        mainView.backend_bridge.call("backend.get_model_download_status", [], function(status) {
            if (status.in_progress) {
                isDownloading = true;
                downloadingModelId = status.model_id || "";
                downloadStatus = status;
                downloadStatusTimer.start();
            }
        });
    }

    function deleteModel(path, name) {
        if (!mainView.backend_bridge.ready) return;
        
        var dialog = PopupUtils.open(confirmDeleteComponent, voiceModelSettingsPage, {
            "modelPath": path,
            "modelName": name
        });
    }

    Component {
        id: infoDialogComponent
        Dialog {
            id: infoDialog
            title: i18n.dtr("ubtms", "About Voice Models")
            
            Flickable {
                width: parent.width
                height: Math.min(units.gu(50), infoContentColumn.height)
                contentHeight: infoContentColumn.height
                clip: true
                interactive: contentHeight > height

                Column {
                    id: infoContentColumn
                    width: parent.width
                    spacing: units.gu(2)
                    
                    Text {
                        text: i18n.dtr("ubtms", "Voice models allow you to dictate text using your microphone directly into the app. Because processing happens locally on your device, your voice data remains completely private and no internet connection is required after the initial model download.\n\nLarger models provide higher accuracy but require more device memory and space. Smaller models are faster and use fewer resources but may be less accurate.")
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Voice Feature Stages:</b> When you click the voice icon, it will show <b>Starting</b>, then <b>Preparing</b>. Only start speaking once it shows <b>Listening</b>. When stopped, it will show <b>Processing</b> with a yellow bar.")
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Auto-Stop & Limits:</b> If you do not speak for 7 seconds, the voice icon will automatically stop. The maximum duration for a single recording is 5 minutes.")
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Getting Started:</b> Make sure you have enabled the \"Enable voice input\" feature, under voice model (Beta) settings. ")
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Compatibility & Errors:</b> A red warning icon indicates the model is incompatible with your device (usually due to RAM limits), but you can still attempt to download it.")
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Managing Downloads:</b>Check the internet connectivity before downloading a file. Once the voice model is downloaded, select the model you want from the installed models list. Even if only one model is installed, selecting the model is mandatory. The selected model will be shown in bold text, with a tick mark to its right. During download, you will see <b>Loading</b> (downloading), <b>Pause</b>, and <b>Cancel</b> buttons. Pausing or losing internet will preserve your progress, allowing you to resume later from this page. Cancelling will delete the partial download.")
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignJustify
                        color: theme.palette.normal.backgroundText
                        font.pixelSize: units.gu(1.6)
                        lineHeight: 1.2
                        text: i18n.dtr("ubtms", "<b>Deleting Models:</b> To remove an installed model, swipe its name to the left and click the delete icon.")
                    }
                    
                    Button {
                        text: i18n.dtr("ubtms", "Close")
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: PopupUtils.close(infoDialog)
                    }

                    Item {
                        width: parent.width
                        height: units.gu(2)
                    }
                }
            }
        }
    }

    Component {
        id: confirmDeleteComponent
        Dialog {
            id: confirmDeleteDialog
            property string modelPath
            property string modelName
            title: i18n.dtr("ubtms", "Delete Model")
            
            Column {
                spacing: units.gu(2)                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                width: parent.width
                
                Text {
                    text: i18n.dtr("ubtms", "Are you sure you want to delete the voice model '%1'?").arg(confirmDeleteDialog.modelName)
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Row {
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Button {
                        text: i18n.dtr("ubtms", "Cancel")
                        onClicked: PopupUtils.close(confirmDeleteDialog)
                    }
                    
                    Button {
                        text: i18n.dtr("ubtms", "Delete")
                        color: LomiriColors.red
                        onClicked: {
                            mainView.backend_bridge.call("backend.delete_voice_model", [confirmDeleteDialog.modelPath], function(res) {
                                PopupUtils.close(confirmDeleteDialog);
                                if (res.status === "success") {
                                    notifPopup.open(i18n.dtr("ubtms", "Deleted"), i18n.dtr("ubtms", "Model %1 deleted successfully.").arg(confirmDeleteDialog.modelName), "success");
                                    refreshModels();
                                } else {
                                    notifPopup.open(i18n.dtr("ubtms", "Error"), res.message || i18n.dtr("ubtms", "Could not delete model"), "error");
                                }
                            });
                        }
                    }
                }
            }
        }
    }

    Component {
        id: warningComponent
        Dialog {
            id: warningDialog
            property string modelId
            property string modelUrl
            property string modelName
            title: i18n.dtr("ubtms", "Warning")
            
            Column {
                spacing: units.gu(2)
                width: parent.width
                
                Text {
                    text: i18n.dtr("ubtms", "This model is incompatible with your device because it requires more RAM than available. It may cause the app to crash.\n\nBut if you want to download it, you can.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: theme.palette.normal.backgroundText
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Row {
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Button {
                        text: i18n.dtr("ubtms", "Cancel")
                        onClicked: PopupUtils.close(warningDialog)
                    }
                    
                    Button {
                        text: i18n.dtr("ubtms", "Download Anyway")
                        color: LomiriColors.orange
                        onClicked: {
                            PopupUtils.close(warningDialog);
                            downloadModel(warningDialog.modelId, warningDialog.modelUrl, warningDialog.modelName);
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: mainView.backend_bridge
        onReadyChanged: {
            if (mainView.backend_bridge.ready) {
                refreshModels();
                checkInProgressDownload();
                checkPausedDownloads();
                fetchDeviceRam();
            }
        }
    }

    ListModel {
        id: modelList
    }

    ListModel {
        id: availableModelList
    }

    Timer {
        id: downloadStatusTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (!isDownloading) return;
            mainView.backend_bridge.call("backend.get_model_download_status", [], function(status) {
                if (!isDownloading) return;
                if (status.model_id && status.model_id !== downloadingModelId) return;
                
                downloadStatus = status;
                
                // Update global timer widget at the bottom
                if (mainView.modelDownloadTimerWidget) {
                    mainView.modelDownloadTimerWidget.syncProgress = status.progress / 100.0;
                    mainView.modelDownloadTimerWidget.syncStatusMessage = status.message || i18n.dtr("ubtms", "Downloading...");
                }

                if (!status.in_progress) {
                    downloadStatusTimer.stop();
                    isDownloading = false;
                    refreshModels(); // Refresh both lists
                    
                    if (status.is_paused) {
                        failedModelId = downloadingModelId;
                        if (status.error) {
                            console.error("Download error:", status.error);
                            if (mainView.modelDownloadTimerWidget) mainView.modelDownloadTimerWidget.failSync(status.error);
                            notifPopup.open(i18n.dtr("ubtms", "Download Interrupted"), i18n.dtr("ubtms", "Failed to download. You can resume it.").arg(downloadingModelName).arg(status.error), "warning");
                        } else {
                            notifPopup.open(i18n.dtr("ubtms", "Download Paused"), i18n.dtr("ubtms", "Download of %1 is paused.").arg(downloadingModelName), "info");
                        }
                    } else if (status.message === "Cancelled" || status.message === "Download cancelled") {
                        failedModelId = "";
                        // Already handled by cancelDownload() or just silently reset
                    } else if (status.error) {
                        failedModelId = ""; // fallback
                        notifPopup.open(i18n.dtr("ubtms", "Download Failed"), status.error, "error");
                    } else {
                        failedModelId = "";
                        if (mainView.modelDownloadTimerWidget) {
                            mainView.modelDownloadTimerWidget.completeSyncSuccessfully();
                        }
                        notifPopup.open(i18n.dtr("ubtms", "Success"), i18n.dtr("ubtms", "%1 installed successfully!").arg(downloadingModelName), "success");
                    }
                }
            });
        }
    }

    Nav.ListHeader {
        id: myTaskListHeader
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        
        filterModel: []
        showSearchBox: false
        currentFilter: ""

        onCustomSearch: {
            searchQuery = query;
        }
    }

    Flickable {
        id: flickable
        anchors.top: myTaskListHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width

            ListItem {
                width: parent.width
                height: units.gu(7)
                divider.visible: true

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.dtr("ubtms", "Enable Voice Input")
                    font.pixelSize: units.gu(2)
                    color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f5f5f5" : "#111"
                }

                Switch {
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    checked: isVoiceInputEnabled
                    onCheckedChanged: {
                        if (checked !== isVoiceInputEnabled) {
                            saveVoiceInputEnabledSetting(checked);
                        }
                    }
                }
            }

            ListItem {
                width: parent.width
                // height: units.gu(5)
                enabled: false
                Label {
                    text: i18n.dtr("ubtms", "INSTALLED MODELS")
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: LomiriColors.orange
                }
            }

            Repeater {
                model: modelList
                delegate: ListItem {
                    width: parent.width
                    height: units.gu(9)
                    divider.visible: true

                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                enabled: model.m_source === "User"
                                onTriggered: {
                                    deleteModel(model.path, model.name)
                                }
                            }
                        ]
                    }

                    onClicked: {
                        saveActiveModelSetting(model.path);
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: activeModelPath === model.path ? 
                               (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#2b241b" : "#fff1de") : 
                               "transparent"
                        visible: activeModelPath === model.path
                        
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.dp(3)
                            height: parent.height - units.gu(1.6)
                            radius: units.dp(2)
                            color: LomiriColors.orange
                            visible: activeModelPath === model.path
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: units.gu(2)
                            rightMargin: units.gu(6)
                        }
                        spacing: units.gu(0.5)

                        Text {
                            text: model.name
                            font.pixelSize: units.gu(2)
                            font.bold: activeModelPath === model.path
                            color: activeModelPath === model.path ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f5f5f5" : "#111")
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: model.path + (model.size ? " (" + model.size + ")" : "")
                            font.pixelSize: units.gu(1.3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#777"
                            elide: Text.ElideMiddle
                            width: parent.width
                        }
                    }

                    Icon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: units.gu(2)
                        name: "ok"
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        color: LomiriColors.orange
                        visible: activeModelPath === model.path
                    }
                }
            }

            // Empty state for installed models
            Text {
                width: parent.width
                height: units.gu(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: isLoading ? i18n.dtr("ubtms", "Scanning for models...") : i18n.dtr("ubtms", "No installed models found.")
                visible: modelList.count === 0
                color: "#888"
                font.italic: true
            }

            // Available Models Section
            ListItem {
                width: parent.width
                height: units.gu(5)
                enabled: false
                Label {
                    text: i18n.dtr("ubtms", "AVAILABLE FOR DOWNLOAD")
                    font.bold: true
                    font.pixelSize: units.gu(1.5)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: LomiriColors.orange
                }
            }



            Repeater {
                model: availableModelList
                delegate: ListItem {
                    width: parent.width
                    height: units.gu(9)
                    divider.visible: true
                    enabled: true
                    opacity: isDownloading ? (downloadingModelId === model.id ? 1.0 : 0.5) : 1.0

                    onClicked: {
                        if (isDownloading && downloadingModelId === model.id) {
                            pauseDownload();
                        } else if (!isDownloading) {
                            if (!isModelCompatible(model.size)) {
                                PopupUtils.open(warningComponent, voiceModelSettingsPage, {
                                    "modelId": model.id,
                                    "modelUrl": model.url,
                                    "modelName": model.name
                                });
                                return;
                            }
                            if (failedModelId === model.id) {
                                failedModelId = "";
                            }
                            downloadModel(model.id, model.url, model.name);
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: units.gu(2)
                            rightMargin: units.gu(8)
                        }
                        spacing: units.gu(0.5)

                        Text {
                            text: model.name
                            font.pixelSize: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f5f5f5" : "#111"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: model.size
                            font.pixelSize: units.gu(1.3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#888" : "#777"
                            elide: Text.ElideMiddle
                            width: parent.width
                        }
                    }

                    Item {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: units.gu(2)
                        width: units.gu(9)
                        height: units.gu(2.5)

                        Row {
                            anchors.fill: parent
                            spacing: units.gu(1)
                            layoutDirection: Qt.RightToLeft

                            // Warning icon
                            Icon {
                                name: "dialog-warning"
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                color: LomiriColors.red
                                visible: !isModelCompatible(model.size) && (!isDownloading || downloadingModelId !== model.id) && failedModelId !== model.id
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        PopupUtils.open(warningComponent, voiceModelSettingsPage, {
                                            "modelId": model.id,
                                            "modelUrl": model.url,
                                            "modelName": model.name
                                        });
                                    }
                                }
                            }

                            // Default Download icon
                            Item {
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                visible: isModelCompatible(model.size) && (!isDownloading || downloadingModelId !== model.id) && failedModelId !== model.id

                                Image {
                                    id: downloadImg
                                    anchors.fill: parent
                                    source: Qt.resolvedUrl("../../../images/download.svg")
                                    sourceSize: Qt.size(parent.width, parent.height)
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: downloadImg
                                    source: downloadImg
                                    color: LomiriColors.orange
                                }
                            }

                            // Cancel icon (when paused or downloading)
                            Icon {
                                name: "close"
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                color: LomiriColors.red
                                visible: ((!isDownloading || downloadingModelId !== model.id) && failedModelId === model.id) || (isDownloading && downloadingModelId === model.id)
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        cancelDownload();
                                    }
                                }
                            }

                            // Play/Resume icon (when paused)
                            Icon {
                                name: "media-playback-start"
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                color: LomiriColors.green
                                visible: (!isDownloading || downloadingModelId !== model.id) && failedModelId === model.id
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        failedModelId = "";
                                        downloadModel(model.id, model.url, model.name);
                                    }
                                }
                            }

                            // Pause icon (when downloading)
                            Icon {
                                name: "media-playback-pause"
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                color: LomiriColors.orange
                                visible: isDownloading && downloadingModelId === model.id
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        pauseDownload();
                                    }
                                }
                            }

                            BusyIndicator {
                                width: units.gu(2.5)
                                height: units.gu(2.5)
                                running: isDownloading && downloadingModelId === model.id
                                visible: isDownloading && downloadingModelId === model.id
                            }
                        }
                    }
                }
            }

            // Empty state for available models
            Text {
                width: parent.width
                height: units.gu(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n.dtr("ubtms", "All available models are installed.")
                visible: availableModelList.count === 0 && !isLoading
                color: "#888"
                font.italic: true
            }}

        
    }          
    NotificationPopup {
        id: notifPopup
    }
}
