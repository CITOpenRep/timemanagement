import QtQuick 2.7
import Lomiri.Components 1.3
import "js/html-sanitizer.js" as HtmlSanitizer

Rectangle {
    id: root
    property alias text: previewText.text
    property string title: i18n.dtr("ubtms", "Description")
    property bool is_read_only: true
    property bool useRichText: true

    // Store the original HTML content to preserve formatting
    property string originalHtmlContent: ""

    width: parent.width
    height: parent.height//column.implicitHeight
    color: "transparent"

    signal clicked
    signal contentChanged(string content)

    // Function to get the raw text content with formatting preserved
    function getFormattedText() {
        // Return the stored original HTML content, not the Qt-converted text
        // Qt's TextArea converts HTML when using Text.RichText format,
        // which adds DOCTYPE and <html> tags - we want to preserve the original
        console.log("[RichTextPreview] getFormattedText returning, full content:");
        console.log(originalHtmlContent);
        return originalHtmlContent || "";
    }

    /**
     * Get text content asynchronously (API compatible with RichTextEditor)
     * @param callback - Function to call with the HTML content
     */
    function getText(callback) {
        var content = getFormattedText();
        if (callback) {
            callback(content);
        }
    }

    /**
     * Check if content is valid HTML content (not corrupted editor internals)
     * Uses the centralized HtmlSanitizer validation.
     * @param content - HTML string to validate
     * @return true if content is valid, false if it contains editor internals
     */
    function isValidContent(content) {
        if (!content) return true; // Empty is valid
        var validation = HtmlSanitizer.validate(content);
        if (!validation.isValid) {
            console.log("[RichTextPreview] Invalid content:", validation.issues.join(", "));
        }
        return validation.isValid;
    }

    /**
     * Sanitize HTML content using the centralized HtmlSanitizer.
     * Handles Qt wrappers, Odoo HTML, and Squire output.
     * @param content - HTML string that may need sanitization
     * @return Clean HTML content
     */
    function sanitizeHtml(content) {
        if (!content) return "";
        
        // Check if sanitization is needed
        if (HtmlSanitizer.needsSanitization(content)) {
            console.log("[RichTextPreview] Sanitizing HTML content");
            var result = HtmlSanitizer.sanitize(content);
            console.log("[RichTextPreview] Sanitized result:", result ? result.substring(0, 100) : "(empty)");
            return result;
        }
        
        return content;
    }

    // Function to set content with HTML preservation
    function setContent(htmlContent) {
        console.log("[RichTextPreview] setContent called with length:", htmlContent ? htmlContent.length : 0);
        
        // Validate content - reject if it contains editor internals
        if (!isValidContent(htmlContent)) {
            console.warn("[RichTextPreview] Ignoring corrupted content (contains editor internals)");
            return;
        }
        
        // Sanitize the HTML to remove Qt wrapper if present
        var cleanContent = sanitizeHtml(htmlContent || "");
        
        // Store the clean HTML
        originalHtmlContent = cleanContent;
        
        // Prevent onTextChanged from overwriting originalHtmlContent
        _settingContent = true;
        previewText.text = cleanContent;
        _settingContent = false;
    }

    /**
     * Set HTML document content (API compatible with RichTextEditor)
     * @param doc - HTML string to set
     */
    function setDocument(doc) {
        setContent(doc);
    }

    /**
     * Set text content (API compatible with RichTextEditor)
     * @param htmlText - HTML string to set
     */
    function setText(htmlText) {
        setContent(htmlText);
    }

    /**
     * Sync content (API compatible with RichTextEditor)
     * Returns the current content for immediate sync needs
     */
    function syncContent() {
        // RichTextPreview is synchronous - return the stored original HTML
        // Do NOT use previewText.text as Qt adds DOCTYPE and <html> tags
        return originalHtmlContent || "";
    }

    // Property to track if content was set programmatically
    property bool _settingContent: false

    Column {
        id: column
        width: parent.width
        height: parent.height
        spacing: units.gu(1)
        Label {
            text: title
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
        }

        Item {
            id: textContainer
            width: parent.width
            height: maxHeight
            clip: true

            anchors.margins: units.gu(2)

            property int maxHeight: units.gu(16)

            TextArea {
                id: previewText
                textFormat: useRichText ? Text.RichText : Text.PlainText

                readOnly: is_read_only
                color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(2)

                width: parent.width - units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                // Update originalHtmlContent when user types
                onTextChanged: {
                    // Only update if user is typing (not read-only) and we're not setting content programmatically
                    // Also reject Qt-processed HTML with DOCTYPE (comes from reading .text property back)
                    if (!is_read_only && !_settingContent) {
                        // Don't save Qt-processed HTML back to originalHtmlContent
                        if (text.indexOf("<!DOCTYPE") === -1 && text.indexOf("<html") === -1) {
                            originalHtmlContent = text;
                            // Emit signal for draft tracking
                            root.contentChanged(text);
                        }
                    }
                }

                Rectangle {
                    // visible: !isReadOnly
                    anchors.fill: parent
                    color: "transparent"
                    radius: units.gu(0.5)
                    border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                    border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                    // z: -1
                }

                Item {
                    id: floatingActionButton
                    width: units.gu(3)
                    height: units.gu(3)
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    z: 10
                    visible: true

                    Rectangle {

                        radius: units.gu(.5)
                        color: LomiriColors.orange
                        anchors.fill: parent
                        Image {
                            id: expansionIcon

                            source: "../../images/expansion.png"
                            width: units.gu(1.5)
                            height: units.gu(1.5)
                            // anchors.right: parent.right
                            //  anchors.rightMargin: units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clicked()
                            }
                        }
                    }
                }
                //  padding: units.gu(2)
            }
        }
    }
}
