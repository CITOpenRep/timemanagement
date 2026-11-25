import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/workflow"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    AttachmentManager {
        id: testManager
        account_id: 1
        resource_type: "project.project"
        resource_id: 10
    }

    SignalSpy {
        id: uploadStartedSpy
        target: testManager
        signalName: "uploadStarted"
    }

    SignalSpy {
        id: uploadCompletedSpy
        target: testManager
        signalName: "uploadCompleted"
    }

    SignalSpy {
        id: uploadFailedSpy
        target: testManager
        signalName: "uploadFailed"
    }

    SignalSpy {
        id: itemClickedSpy
        target: testManager
        signalName: "itemClicked"
    }

    TestCase {
        name: "AttachmentManagerTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testManager.clearAttachments();
            testManager.account_id = 1;
            testManager.resource_type = "project.project";
            testManager.resource_id = 10;
            uploadStartedSpy.clear();
            uploadCompletedSpy.clear();
            uploadFailedSpy.clear();
            itemClickedSpy.clear();
        }

        function cleanup() {
            testManager.clearAttachments();
            uploadStartedSpy.clear();
            uploadCompletedSpy.clear();
            uploadFailedSpy.clear();
            itemClickedSpy.clear();
        }

        function test_initialProperties() {
            compare(testManager.account_id, 1);
            compare(testManager.resource_type, "project.project");
            compare(testManager.resource_id, 10);
            compare(testManager._busy, false);
            compare(testManager.title, "Attachments");
        }

        function test_setAttachmentsPopulatesModel() {
            var items = [
                {
                    id: 1,
                    name: "document.pdf",
                    url: "/tmp/document.pdf",
                    mimetype: "application/pdf",
                    size: 1024,
                    odoo_record_id: 101,
                    account_id: 1
                },
                {
                    id: 2,
                    name: "photo.jpg",
                    url: "/tmp/photo.jpg",
                    mimetype: "image/jpeg",
                    size: 2048,
                    odoo_record_id: 102,
                    account_id: 1
                }
            ];

            testManager.setAttachments(items);

            compare(testManager.model.count, 2);
            var first = testManager.model.get(0);
            compare(first.name, "document.pdf");
            compare(first.mimetype, "application/pdf");
            compare(first.odoo_record_id, 101);

            var second = testManager.model.get(1);
            compare(second.name, "photo.jpg");
            compare(second.mimetype, "image/jpeg");
            compare(second.odoo_record_id, 102);
        }

        function test_setAttachmentsDeduplicatesItems() {
            var duplicateItems = [
                { id: 1, name: "file.txt", odoo_record_id: 200, account_id: 1 },
                { id: 2, name: "file.txt", odoo_record_id: 200, account_id: 1 }
            ];

            testManager.setAttachments(duplicateItems);

            compare(testManager.model.count, 1);
        }

        function test_appendAndClearAttachments() {
            testManager.appendAttachment({
                id: 10,
                name: "single.png",
                mimetype: "image/png",
                odoo_record_id: 300,
                account_id: 1
            });
            compare(testManager.model.count, 1);

            testManager.appendAttachment({
                id: 11,
                name: "second.png",
                mimetype: "image/png",
                odoo_record_id: 301,
                account_id: 1
            });
            compare(testManager.model.count, 2);

            testManager.clearAttachments();
            compare(testManager.model.count, 0);
        }

        function test_formatSizeHelper() {
            compare(testManager._fmtSize(500), "500 B");
            compare(testManager._fmtSize(1024), "1.0 KB");
            compare(testManager._fmtSize(1048576), "1.0 MB");
            compare(testManager._fmtSize(1073741824), "1.0 GB");
        }

        function test_metaLineLabelHelper() {
            compare(testManager._metaLineLabel("image/jpeg", 100), "Image");
            compare(testManager._metaLineLabel("application/pdf", 100), "PDF Document");
            compare(testManager._metaLineLabel("audio/mpeg", 100), "Audio file");
            compare(testManager._metaLineLabel("video/mp4", 100), "Video file");
            compare(testManager._metaLineLabel("application/vnd.ms-excel", 100), "Spreadsheet");
            compare(testManager._metaLineLabel("application/octet-stream", 100), "Document");
        }

        function test_iconNameHelper() {
            compare(testManager._iconName("image/png"), "image-x-generic-symbolic");
            compare(testManager._iconName("application/pdf"), "application-pdf-symbolic");
            compare(testManager._iconName("video/mp4"), "video-x-generic-symbolic");
            compare(testManager._iconName("audio/ogg"), "audio-x-generic-symbolic");
            compare(testManager._iconName(""), "document-open");
        }

        function test_iconBoxColorHelper() {
            compare(testManager._iconBoxColor("image/png"), "#009688");
            compare(testManager._iconBoxColor("application/pdf"), "#D32F2F");
            compare(testManager._iconBoxColor("audio/mp3"), "#7B1FA2");
            compare(testManager._iconBoxColor("video/mp4"), "#388E3C");
        }

        function test_iconLightBgColorHelper() {
            compare(testManager._iconLightBgColor("image/png"), "#E0F2F1");
            compare(testManager._iconLightBgColor("application/pdf"), "#FFEBEE");
            compare(testManager._iconLightBgColor(""), "#F5F5F5");
        }

        function test_handleSyncEvents() {
            testManager._handleSyncEvent({
                event: "ondemand_upload_message",
                payload: "Uploading 50%..."
            });
            compare(testManager._statusMessage, "Uploading 50%...");

            testManager._handleSyncEvent({
                event: "ondemand_upload_completed",
                payload: true
            });
            compare(uploadCompletedSpy.count, 1);
            compare(testManager._busy, false);

            testManager._handleSyncEvent({
                event: "ondemand_upload_completed",
                payload: false
            });
            compare(uploadFailedSpy.count, 1);
            compare(testManager._busy, false);
        }

        function test_uploadStartedSignalUpdatesBusyState() {
            testManager.uploadStarted();

            compare(uploadStartedSpy.count, 1);
            compare(testManager._busy, true);
        }

        function test_itemClickedSignalEmission() {
            var itemData = {
                id: 99,
                name: "file.zip",
                odoo_record_id: 999
            };

            testManager.itemClicked(itemData);

            compare(itemClickedSpy.count, 1);
            compare(itemClickedSpy.signalArguments[0][0].name, "file.zip");
        }

        function test_pendingUploadCountKeepsBusyState() {
            testManager._pendingUploadCount = 3;
            testManager.uploadStarted();
            compare(testManager._busy, true);

            // First file completes but 2 still pending -> remains busy
            testManager.uploadCompleted();
            compare(testManager._busy, true);

            // Last file completes -> busy becomes false
            testManager._pendingUploadCount = 0;
            testManager.uploadCompleted();
            compare(testManager._busy, false);
        }

        function test_extractFilePathsDeduplicationAndNormalizing() {
            // Test array of objects with .url and duplicates
            var rawFiles = [
                { url: "file:///media/photo1.jpg" },
                { url: "file:///media/photo2.png" },
                { url: "file:///media/photo1.jpg" }, // duplicate
                { url: "/media/photo3.pdf" }
            ];
            var extracted = testManager._extractFilePaths(rawFiles);
            compare(extracted.length, 3);
            compare(extracted[0], "/media/photo1.jpg");
            compare(extracted[1], "/media/photo2.png");
            compare(extracted[2], "/media/photo3.pdf");

            // Test null/empty input
            compare(testManager._extractFilePaths(null).length, 0);
            compare(testManager._extractFilePaths([]).length, 0);

            // Test array of plain string paths
            var strFiles = ["file:///doc/a.txt", "file:///doc/b.txt", "file:///doc/a.txt"];
            var strExtracted = testManager._extractFilePaths(strFiles);
            compare(strExtracted.length, 2);
            compare(strExtracted[0], "/doc/a.txt");
            compare(strExtracted[1], "/doc/b.txt");
        }

        function test_uploadFilesIgnoresWhenBusy() {
            testManager._busy = true;
            uploadStartedSpy.clear();
            testManager.uploadFiles([{ url: "file:///test.jpg" }]);
            // Should not start a new upload when busy
            compare(uploadStartedSpy.count, 0);
            testManager._busy = false;
        }
    }
}
