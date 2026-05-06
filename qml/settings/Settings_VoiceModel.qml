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
import "../components/settings"
import "../components"

Page {
    id: voiceModelSettingsPage
    title: i18n.dtr("ubtms", "Voice Model Settings")

    header: SettingsHeader {
        id: pageHeader
        title: voiceModelSettingsPage.title
        trailingActions: [
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
    property var downloadStatus: { "in_progress": false, "progress": 0, "message": "", "error": "" }

    function getActiveModelSetting() {
        try {
            var db = Sql.LocalStorage.openDatabaseSync("myDatabase", "1.0", "My Database", 1000000);
            var result = "voice_to_text/model"; // Default

            db.transaction(function (tx) {
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
        modelList.clear();
        
        mainView.backend_bridge.call("backend.list_installed_models", [], function(models) {
            isLoading = false;
            if (models && models.length > 0) {
                for (var i = 0; i < models.length; i++) {
                    modelList.append({
                        "name": models[i].m_name,
                        "path": models[i].m_path,
                        "size": models[i].m_size || ""
                    });
                }
            }
            // After refreshing installed models, refresh available ones
            refreshAvailableModels();
        });
    }

    function refreshAvailableModels() {
        if (!mainView.backend_bridge.ready) return;
        
        availableModelList.clear();
        mainView.backend_bridge.call("backend.list_available_models", [], function(models) {
            if (models && models.length > 0) {
                // Only show models that are NOT installed
                var installedPaths = [];
                for (var i = 0; i < modelList.count; i++) {
                    installedPaths.push(modelList.get(i).path);
                }

                for (var j = 0; j < models.length; j++) {
                    var modelId = models[j].id;
                    // Check if already installed (simple check by ID in path or similar)
                    var alreadyInstalled = false;
                    for (var k = 0; k < installedPaths.length; k++) {
                        if (installedPaths[k].indexOf(modelId) !== -1) {
                            alreadyInstalled = true;
                            break;
                        }
                    }

                    if (!alreadyInstalled) {
                        availableModelList.append({
                            "id": models[j].id,
                            "name": models[j].name,
                            "size": models[j].size,
                            "url": models[j].url
                        });
                    }
                }
            }
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

    Component.onCompleted: {
        activeModelPath = getActiveModelSetting();
        if (mainView.backend_bridge.ready) {
            refreshModels();
            checkInProgressDownload();
        }
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

    Connections {
        target: mainView.backend_bridge
        onReadyChanged: {
            if (mainView.backend_bridge.ready) {
                refreshModels();
                checkInProgressDownload();
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
            mainView.backend_bridge.call("backend.get_model_download_status", [], function(status) {
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
                    if (status.error) {
                        // Show error
                        console.error("Download error:", status.error);
                        if (mainView.modelDownloadTimerWidget) {
                            mainView.modelDownloadTimerWidget.failSync(status.error);
                        }
                        notifPopup.open(i18n.dtr("ubtms", "Download Failed"), i18n.dtr("ubtms", "Failed to download %1: %2").arg(downloadingModelName).arg(status.error), "error");
                    } else {
                        if (mainView.modelDownloadTimerWidget) {
                            mainView.modelDownloadTimerWidget.completeSyncSuccessfully();
                        }
                        notifPopup.open(i18n.dtr("ubtms", "Success"), i18n.dtr("ubtms", "%1 installed successfully!").arg(downloadingModelName), "success");
                    }
                }
            });
        }
    }

    Flickable {
        id: flickable
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            // spacing: units.gu(1)

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

                    onClicked: {
                        saveActiveModelSetting(model.path);
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: activeModelPath === model.path ? 
                               (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#222" : "#f0f0f0") : 
                               "transparent"
                        visible: activeModelPath === model.path
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
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#f5f5f5" : "#111"
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
                        if (!isDownloading) {
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

                    Icon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: units.gu(2)
                        source: Qt.resolvedUrl("../images/download.svg")
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        color: LomiriColors.orange
                        visible: !isDownloading || downloadingModelId !== model.id
                    }

                    BusyIndicator {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: units.gu(2)
                        running: isDownloading && downloadingModelId === model.id
                        visible: isDownloading && downloadingModelId === model.id
                        width: units.gu(2.5)
                        height: units.gu(2.5)
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
