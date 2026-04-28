import QtQuick 2.6
import Lomiri.Components 1.3
import "../features/settings/components" as SettingsComponents

Column {
    id: root
    width: parent ? parent.width : 0

    property var menuItems: []
    property string selectedPageUrl: ""
    signal itemSelected(var item)

    Repeater {
        model: root.menuItems

        SettingsComponents.SettingsListItem {
            width: root.width
            iconName: modelData.iconName
            iconColor: modelData.iconColor
            text: i18n.dtr("ubtms", modelData.textKey)
            showDivider: modelData.showDivider === undefined ? true : modelData.showDivider
            active: modelData.pageUrl === root.selectedPageUrl
            onClicked: root.itemSelected(modelData)
        }
    }
}
