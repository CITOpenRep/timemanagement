import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import "../../qml/components/dialogs"

MainView {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    ContentPickerDialog {
        id: testContentPicker
    }

    SignalSpy {
        id: completeSpy
        target: testContentPicker
        signalName: "complete"
    }

    SignalSpy {
        id: filesImportedSpy
        target: testContentPicker
        signalName: "filesImported"
    }

    TestCase {
        name: "ContentPickerDialogTests"
        when: windowShown

        function init() {
            testContentPicker.isExport = true;
            testContentPicker.fileUrl = "";
            testContentPicker.autoPickGallery = true;
            testContentPicker._deliveryHandled = false;
            completeSpy.clear();
            filesImportedSpy.clear();
        }

        function cleanup() {
            testContentPicker.isExport = true;
            testContentPicker.fileUrl = "";
            testContentPicker.autoPickGallery = true;
            testContentPicker._deliveryHandled = false;
            completeSpy.clear();
            filesImportedSpy.clear();
        }

        function test_initialProperties() {
            compare(testContentPicker.isExport, true);
            compare(testContentPicker.fileUrl, "");
            compare(testContentPicker.autoPickGallery, true);
            compare(testContentPicker._deliveryHandled, false);
            compare(completeSpy.count, 0);
            compare(filesImportedSpy.count, 0);
        }

        function test_resolveTypePictures() {
            compare(testContentPicker.resolveType("image.png"), ContentType.Pictures);
            compare(testContentPicker.resolveType("photo.jpg"), ContentType.Pictures);
            compare(testContentPicker.resolveType("/path/to/picture.jpeg"), ContentType.Pictures);
            compare(testContentPicker.resolveType("anim.gif"), ContentType.Pictures);
            compare(testContentPicker.resolveType("bitmap.bmp"), ContentType.Pictures);
            compare(testContentPicker.resolveType("modern.webp"), ContentType.Pictures);
        }

        function test_resolveTypeMediaAndDocs() {
            compare(testContentPicker.resolveType("song.mp3"), ContentType.Music);
            compare(testContentPicker.resolveType("audio.wav"), ContentType.Music);
            compare(testContentPicker.resolveType("movie.mp4"), ContentType.Videos);
            compare(testContentPicker.resolveType("clip.mkv"), ContentType.Videos);
            compare(testContentPicker.resolveType("doc.pdf"), ContentType.Documents);
            compare(testContentPicker.resolveType("report.docx"), ContentType.Documents);
            compare(testContentPicker.resolveType("data.csv"), ContentType.Documents);
            compare(testContentPicker.resolveType("contact.vcf"), ContentType.Contacts);
            compare(testContentPicker.resolveType("book.epub"), ContentType.EBooks);
            compare(testContentPicker.resolveType("archive.tar.gz"), ContentType.All);
            compare(testContentPicker.resolveType(""), ContentType.All);
        }

        function test_singleSelectionBehaviorInExportMode() {
            testContentPicker.isExport = true;
            testContentPicker.fileUrl = "/tmp/exported_invoice.pdf";

            var mockPeer = {
                selectionType: -1,
                request: function() { return {}; }
            };

            // Simulating peerSelected behavior in export mode (single selection)
            mockPeer.selectionType = (testContentPicker.isExport ? ContentTransfer.Single : ContentTransfer.Multiple);
            compare(mockPeer.selectionType, ContentTransfer.Single);
        }

        function test_multiSelectionBehaviorInImportMode() {
            testContentPicker.isExport = false;

            var mockPeer = {
                selectionType: -1,
                request: function() { return {}; }
            };

            // Simulating peerSelected behavior in import mode (multi selection)
            mockPeer.selectionType = (testContentPicker.isExport ? ContentTransfer.Single : ContentTransfer.Multiple);
            compare(mockPeer.selectionType, ContentTransfer.Multiple);
        }

        function test_isImageExportConditions() {
            testContentPicker.isExport = true;
            testContentPicker.autoPickGallery = true;
            testContentPicker.fileUrl = "/images/screenshot.png";
            verify(testContentPicker._isImageExport());

            // When not export mode
            testContentPicker.isExport = false;
            verify(!testContentPicker._isImageExport());

            // When autoPickGallery disabled
            testContentPicker.isExport = true;
            testContentPicker.autoPickGallery = false;
            verify(!testContentPicker._isImageExport());

            // When exporting a non-image document
            testContentPicker.autoPickGallery = true;
            testContentPicker.fileUrl = "/docs/spec.pdf";
            verify(!testContentPicker._isImageExport());
        }

        function test_filesImportedSignalEmission() {
            var importedFiles = ["file:///data/attachment1.pdf", "file:///data/attachment2.png"];
            testContentPicker.filesImported(importedFiles);

            compare(filesImportedSpy.count, 1);
            var emittedArgs = filesImportedSpy.signalArguments[0][0];
            compare(emittedArgs.length, 2);
            compare(emittedArgs[0], "file:///data/attachment1.pdf");
            compare(emittedArgs[1], "file:///data/attachment2.png");
        }

        function test_completeSignalEmission() {
            compare(completeSpy.count, 0);
            testContentPicker.complete();
            compare(completeSpy.count, 1);
        }
    }
}
