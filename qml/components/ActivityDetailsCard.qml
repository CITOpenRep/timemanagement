import QtQuick 2.12
import Lomiri.Components 1.3
import "../../models/utils.js" as Utils
import "../../models/activity.js" as Activity

ListItem {
    id: root
    width: parent.width
    height: units.gu(10)

    property string notes: ""
    property string activity_type_name: ""
    property string summary: ""
    property int activity_type_id: -1
    property string user: ""
    property string due_date: ""
    property string state: ""
    property int id: -1
    property var odoo_record_id
    property var account_id
    property int colorPallet: 0

    signal cardClicked(int accountid, int recordid)
    signal markAsDone(int accountid, int recordId)

    function truncateText(text, maxLength) {
        if (text.length > maxLength) {
            return text.slice(0, maxLength) + '...';
        }
        return text;
    }

    function stripHtmlTags(text) {
        if (!text || typeof text !== "string")
            return "";

        // Enhanced HTML document and tag removal
        var cleaned = text
        // Remove DOCTYPE declarations
        .replace(/<!DOCTYPE[^>]*>/gi, '')
        // Remove HTML comments
        .replace(/<!--[\s\S]*?-->/gi, '')
        // Remove style blocks completely (including CSS)
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
        // Remove script blocks completely
        .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
        // Remove head section completely
        .replace(/<head[^>]*>[\s\S]*?<\/head>/gi, '')
        // Remove all HTML tags with their attributes (most comprehensive approach)
        .replace(/<\/?[^>]+(>|$)/gi, '')
        // Clean up any remaining tag fragments
        .replace(/<[^>]*$/gi, '').replace(/^[^<]*>/gi, '')
        // Replace line break tags specifically (in case they survived)
        .replace(/&lt;br\s*\/?&gt;/gi, ' ').replace(/&lt;\/br&gt;/gi, ' ')
        // Replace common HTML entities
        .replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&').replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&quot;/gi, '"').replace(/&#39;/gi, "'").replace(/&apos;/gi, "'").replace(/&hellip;/gi, '...').replace(/&mdash;/gi, '—').replace(/&ndash;/gi, '–').replace(/&copy;/gi, '©').replace(/&reg;/gi, '®').replace(/&trade;/gi, '™')
        // Handle numeric HTML entities (like &#160; for &nbsp;)
        .replace(/&#\d+;/gi, ' ').replace(/&#x[0-9a-f]+;/gi, ' ')
        // Remove CSS style declarations that might remain as text
        .replace(/\s*{\s*[^}]*}\s*/gi, ' ').replace(/[a-zA-Z-]+\s*:\s*[^;]+;/gi, '')
        // Remove extra whitespace, line breaks, and tabs
        .replace(/\s+/g, ' ').replace(/\n+/g, ' ').replace(/\r+/g, ' ').replace(/\t+/g, ' ')
        // Remove any remaining < or > characters
        .replace(/[<>]/g, '')
        // Remove leading/trailing whitespace
        .trim();

        return cleaned;
    }

    function hasHtmlTags(text) {
        // Check if text contains HTML tags
        return /<[^>]*>/.test(text);
    }

    function smartTruncate(text, maxLength) {
        // Check if text contains HTML tags
        if (hasHtmlTags(text)) {
            // Use rich text truncation
            return truncateRichText(text, maxLength);
        } else {
            // Use simple truncation for plain text
            return truncateText(text, 25);
        }
    }

    function truncateRichText(text, maxLength) {
        // Strip HTML tags for length calculation, but return original for display
        var strippedText = stripHtmlTags(text);
        if (strippedText.length > maxLength) {
            // Find the cutoff point in the original text that corresponds to maxLength characters of content
            var currentLength = 0;
            var result = "";
            var inTag = false;

            for (var i = 0; i < text.length && currentLength < maxLength; i++) {
                var currentChar = text.charAt(i);
                if (currentChar === '<') {
                    inTag = true;
                } else if (currentChar === '>') {
                    inTag = false;
                    result += currentChar;
                    continue;
                }

                result += currentChar;
                if (!inTag) {
                    currentLength++;
                }
            }
            return result + '...';
        }
        return text;
    }

    clip: true
    trailingActions: ListItemActions {
        actions: [
            Action {
                iconName: "tick"
                // color: "#4CAF50"
                onTriggered: markAsDone(root.account_id, root.odoo_record_id)
            }
        ]

        delegate: Item {
            width: units.gu(6)
            height: parent.height

            Icon {
                anchors.centerIn: parent
                name: action.iconName
                width: units.gu(2)
                height: units.gu(2)
                color: "#4CAF50" // Your desired color
            }

            MouseArea {
                anchors.fill: parent
                onClicked: action.trigger()
            }
        }
    }

    Rectangle {
        id: left_rect
        anchors.fill: parent
        border.color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#444" : "#dcdcdc"
        radius: units.gu(0.2)
        anchors.leftMargin: units.gu(0.2)
        anchors.rightMargin: units.gu(0.2)
        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#111" : "#fff"
        // subtle color fade on the left

        Row {
            anchors.fill: parent
            spacing: units.gu(1)

            //anchors.leftMargin: units.gu(1.5)
            Rectangle {
                width: parent.width * 0.025
                height: parent.height
                // anchors.left: parent.left
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Utils.getColorFromOdooIndex(colorPallet)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Utils.getColorFromOdooIndex(colorPallet).r, Utils.getColorFromOdooIndex(colorPallet).g, Utils.getColorFromOdooIndex(colorPallet).b, 0.0)
                    }
                }
            }
            Image {
                width: parent.height / 2
                height: parent.height / 2
                fillMode: Image.PreserveAspectFit
                source: "../images/" + Activity.getActivityIconForType(activity_type_name)
                anchors.verticalCenter: parent.verticalCenter
                // anchors.margins: units.gu(2)
                //  anchors.leftMargin: units.gu(3)
            }

            Rectangle {
                id: leftrect
                width: parent.width * 0.65
                height: parent.height
                color: "transparent"

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: units.gu(0.4)

                    Column {
                        width: parent.width - units.gu(4)
                        height: parent.height - units.gu(2)
                        spacing: units.gu(0.2)

                        Text {
                            text: (typeof root.summary === "string" && root.summary.trim() !== "" && root.summary !== "0") ? Utils.truncateText(root.summary, 20) : "No Summary"
                            textFormat: Text.PlainText
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "white" : "black"
                            font.pixelSize: units.gu(2)
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            clip: true
                            width: parent.width - units.gu(2)
                        }

                        Text {
                            text: (typeof root.notes === "string" && root.notes.trim() !== "" && root.notes !== "0") ? Utils.truncateText(root.stripHtmlTags(root.notes), 30) : "No Notes"
                            textFormat: Text.PlainText
                            font.pixelSize: units.gu(1.6)
                            maximumLineCount: 1
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            width: parent.width - units.gu(2)
                            height: units.gu(2)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                        }

                        Text {
                            text: root.user ? "Assigned to: " + root.user : "Unassigned"
                            width: parent.width - units.gu(2)
                            font.pixelSize: units.gu(1.6)
                            height: units.gu(3)
                            color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#80bfff" : "#222"
                            //    anchors.right: parent.right
                            //  anchors.bottom: root.bottom
                        }
                    }
                }
            }

            Rectangle {
                id: right_rect
                width: parent.width * 0.40  // 25% of total width
                height: parent.height
                color: "transparent"

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1)
                    spacing: units.gu(0.4)

                    Text {
                        text: root.activity_type_name || ("Type ID: " + root.activity_type_id)
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#555"
                    }

                    Text {
                        text: Qt.formatDate(new Date(root.due_date), "dd MMM")
                        font.pixelSize: units.gu(1.5)
                        horizontalAlignment: Text.AlignRight
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#bbb" : "#222"
                    }

                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(2.2)
                        color: root.state === "done" ? "#4CAF50" : root.state === "open" ? "#FF9800" : "#9E9E9E"

                        Text {
                            anchors.centerIn: parent
                            text: root.state ? root.state.toUpperCase() : "N/A"
                            font.pixelSize: units.gu(1.2)
                            color: "white"
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cardClicked(root.account_id, root.odoo_record_id)
    }
}
