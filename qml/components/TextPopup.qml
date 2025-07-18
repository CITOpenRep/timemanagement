/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import Lomiri.Components.Popups 1.3

Item {
    id: textPopupWrapper
    width: 0
    height: 0

    signal textContentChanged(string newText)

    property string popupTitle: "Text Content"
    property string popupText: ""
    property bool allowEdit: false

    Component {
        id: textDialogComponent

        Dialog {
            id: textDialog
            title: textPopupWrapper.popupTitle

            Rectangle {
                width: units.gu(80)
                height: units.gu(60)
                color: theme.palette.normal.background
                
                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)
                    
                    ScrollView {
                        width: parent.width
                        height: parent.height - buttonRow.height - units.gu(2)
                        
                        TextArea {
                            id: contentTextArea
                            width: parent.width
                            text: textPopupWrapper.popupText
                            textFormat: Text.RichText
                            readOnly: !textPopupWrapper.allowEdit
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            
                            Rectangle {
                                visible: textPopupWrapper.allowEdit
                                anchors.fill: parent
                                color: "transparent"
                                radius: units.gu(0.5)
                                border.width: parent.activeFocus ? units.gu(0.2) : units.gu(0.1)
                                border.color: parent.activeFocus ? LomiriColors.orange : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#d3d1d1" : "#999")
                                z: -1
                            }
                        }
                    }
                    
                    Row {
                        id: buttonRow
                        anchors.right: parent.right
                        spacing: units.gu(1)
                        
                        TSButton {
                            text: "OK"
                            width: units.gu(10)
                            height: units.gu(5)
                            onClicked: {
                                if (textPopupWrapper.allowEdit && contentTextArea.text !== textPopupWrapper.popupText) {
                                    textPopupWrapper.textContentChanged(contentTextArea.text);
                                }
                                PopupUtils.close(textDialog);
                            }
                        }
                        
                        TSButton {
                            text: "Cancel"
                            visible: textPopupWrapper.allowEdit
                            width: units.gu(10)
                            height: units.gu(5)
                            onClicked: {
                                contentTextArea.text = textPopupWrapper.popupText;
                                PopupUtils.close(textDialog);
                            }
                        }
                    }
                }
            }
        }
    }

    function open(title, text, editable) {
        popupTitle = title || "Text Content";
        popupText = text || "";
        allowEdit = editable || false;
        PopupUtils.open(textDialogComponent);
    }
}
