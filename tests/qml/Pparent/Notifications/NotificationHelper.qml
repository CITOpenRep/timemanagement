import QtQuick 2.7

Item {
    property string push_app_id: ""
    property int count: 0
    function updateCount(c) {
        count = c;
    }
}
