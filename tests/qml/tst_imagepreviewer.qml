import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/system"
import "../../models/dbinit.js" as DbInit

MainView {
    id: testRoot
    width: units.gu(50)
    height: units.gu(80)

    ImagePreviewer {
        id: testPreviewer
    }

    TestCase {
        name: "ImagePreviewerTests"
        when: windowShown

        function initTestCase() {
            DbInit.initializeDatabase();
        }

        function init() {
            testPreviewer.visible = false;
            testPreviewer.imageSource = "";
            testPreviewer.originalFilename = "";
            testPreviewer.mimetype = "image/*";
            testPreviewer.accountId = 0;
            testPreviewer.recordId = 0;
            testPreviewer.busy = false;
            testPreviewer._downloadedOnce = false;
        }

        function cleanup() {
            testPreviewer.visible = false;
        }

        function test_initialProperties() {
            compare(testPreviewer.visible, false);
            compare(testPreviewer.imageSource, "");
            compare(testPreviewer.originalFilename, "");
            compare(testPreviewer.mimetype, "image/*");
            compare(testPreviewer.accountId, 0);
            compare(testPreviewer.recordId, 0);
            compare(testPreviewer.busy, false);
            compare(testPreviewer._downloadedOnce, false);
        }

        function test_setImageSourceAndMetadata() {
            testPreviewer.imageSource = "file:///tmp/sample.png";
            testPreviewer.originalFilename = "sample.png";
            testPreviewer.mimetype = "image/png";
            testPreviewer.accountId = 1;
            testPreviewer.recordId = 42;

            compare(testPreviewer.imageSource.toString(), "file:///tmp/sample.png");
            compare(testPreviewer.originalFilename, "sample.png");
            compare(testPreviewer.mimetype, "image/png");
            compare(testPreviewer.accountId, 1);
            compare(testPreviewer.recordId, 42);
        }

        function test_openAndCloseActions() {
            // Open previewer
            testPreviewer.visible = true;
            compare(testPreviewer.visible, true);

            // Close via property
            testPreviewer.visible = false;
            compare(testPreviewer.visible, false);
        }

        function test_downloadedOncePropertyToggling() {
            testPreviewer._downloadedOnce = false;
            compare(testPreviewer._downloadedOnce, false);

            testPreviewer._downloadedOnce = true;
            compare(testPreviewer._downloadedOnce, true);
        }

        function test_busyStateTracking() {
            compare(testPreviewer.busy, false);

            testPreviewer.busy = true;
            compare(testPreviewer.busy, true);

            testPreviewer.busy = false;
            compare(testPreviewer.busy, false);
        }

        function test_refreshDownloadedFlagWithZeroIds() {
            testPreviewer.accountId = 0;
            testPreviewer.recordId = 0;
            testPreviewer._refreshDownloadedFlag();
            compare(testPreviewer._downloadedOnce, false);
        }
    }
}
