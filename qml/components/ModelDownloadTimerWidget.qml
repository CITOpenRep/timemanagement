import QtQuick 2.7
import Lomiri.Components 1.3
import "."

GlobalTimerWidget {
    id: downloadWidget
    
    // Override completion logic to connect to our specific download events
    Component.onCompleted: {
        var root = downloadWidget;
        while (root.parent) {
            root = root.parent;
            if (root.backend_bridge) {
                backendBridge = root.backend_bridge;
                // Connect our specialized handler for download-specific events
                backendBridge.messageReceived.connect(handleDownloadEvent);
                break;
            }
        }
    }
    
    // Specialized handler for voice model downloads
    function handleDownloadEvent(data) {
        if (!data || !data.event || !isSyncing)
            return;
            
        // This widget only handles download_* events
        switch(data.event) {
            case "download_progress":
                syncProgress = data.payload / 100.0;
                break;
            case "download_message":
                syncStatusMessage = data.payload;
                break;
            case "download_completed":
                completeSyncSuccessfully();
                break;
            case "download_error":
                failSync(data.payload);
                break;
        }
    }

    // Custom naming logic for downloads (overriding conceptual logic)
    function updateSyncMessage() {
        if (!isSyncing)
            return;

        var progressPercent = Math.round(syncProgress * 100);

        if (progressPercent < 15) {
            syncStatusMessage = i18n.dtr("ubtms", "Initializing download...");
        } else if (progressPercent < 80) {
            syncStatusMessage = i18n.dtr("ubtms", "Downloading model files...");
        } else if (progressPercent < 95) {
            syncStatusMessage = i18n.dtr("ubtms", "Extracting and installing...");
        } else {
            syncStatusMessage = i18n.dtr("ubtms", "Installation complete!");
        }
    }
    
    // Ensure naming logic runs when progress changes
    onSyncProgressChanged: updateSyncMessage()
}
