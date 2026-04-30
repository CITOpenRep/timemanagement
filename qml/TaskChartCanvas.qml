// Reusable Canvas-based horizontal bar chart for top task time visualization.
import QtQuick 2.12
import Lomiri.Components 1.3
import "chartUtils.js" as ChartUtils

Item {
    id: root

    property var tasksData: []
    property color accentColour: Theme.palette.selected.background
    property int highlightedIndex: -1

    signal taskSelected(string taskId)

    readonly property int barCount: tasksData ? tasksData.length : 0
    readonly property real rowHeight: units.gu(6.5)
    readonly property real leftLabelWidth: units.gu(13)
    readonly property real rightValueWidth: units.gu(7)
    readonly property real chartPadding: units.gu(2)
    readonly property real barHeight: units.gu(5)
    readonly property string paintSignature: ChartUtils.chartSignature(tasksData, accentColour, highlightedIndex)

    implicitHeight: units.gu((barCount * 6.5) + 4)

    onPaintSignatureChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            if (ctx.reset) {
                ctx.reset();
            }
            ctx.clearRect(0, 0, width, height);

            var textColor = Theme.palette.normal.backgroundText;
            var subtleRule = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.08);
            var barColor = accentColour;
            var maxHours = ChartUtils.maxTaskHours(root.tasksData);
            var usableWidth = width - root.leftLabelWidth - root.rightValueWidth - (root.chartPadding * 2);
            var radius = units.dp(2);

            ctx.textBaseline = "middle";
            ctx.font = units.dp(12) + "px Ubuntu";

            for (var i = 0; i < root.tasksData.length; i++) {
                var task = root.tasksData[i];
                var top = root.chartPadding + (i * root.rowHeight);
                var centerY = top + (root.rowHeight / 2);
                var barTop = centerY - (root.barHeight / 2);
                var value = Number(task.totalHours || 0);
                var fraction = maxHours > 0 ? value / maxHours : 0;
                var barWidth = Math.max(units.gu(2), usableWidth * fraction);
                var barX = root.leftLabelWidth + root.chartPadding;
                var isHighlighted = root.highlightedIndex < 0 || root.highlightedIndex === i;
                var alpha = isHighlighted ? 1.0 : 0.6;

                ctx.fillStyle = subtleRule;
                ctx.fillRect(barX, top + root.rowHeight - units.dp(1), usableWidth, units.dp(1));

                ctx.fillStyle = Qt.rgba(barColor.r, barColor.g, barColor.b, alpha);
                drawRoundedBar(ctx, barX, barTop, barWidth, root.barHeight, radius);

                ctx.save();
                ctx.beginPath();
                ctx.rect(0, top, root.leftLabelWidth - units.gu(1), root.rowHeight);
                ctx.clip();
                ctx.fillStyle = textColor;
                ctx.fillText(ChartUtils.elide(task.name || "", 18), 0, centerY);
                ctx.restore();

                ctx.fillStyle = textColor;
                ctx.fillText(ChartUtils.formatHours(value), barX + Math.min(barWidth + units.gu(1), usableWidth + units.gu(1)), centerY);
            }
        }

        function drawRoundedBar(ctx, x, y, width, height, radius) {
            var safeRadius = Math.min(radius, width / 2, height / 2);
            ctx.beginPath();
            ctx.moveTo(x, y);
            ctx.lineTo(x + width - safeRadius, y);
            ctx.quadraticCurveTo(x + width, y, x + width, y + safeRadius);
            ctx.lineTo(x + width, y + height - safeRadius);
            ctx.quadraticCurveTo(x + width, y + height, x + width - safeRadius, y + height);
            ctx.lineTo(x, y + height);
            ctx.closePath();
            ctx.fill();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.tasksData || root.tasksData.length === 0) {
                return;
            }

            var index = Math.floor((mouse.y - root.chartPadding) / root.rowHeight);
            if (index >= 0 && index < root.tasksData.length) {
                root.taskSelected(root.tasksData[index].id);
            }
        }
    }
}
