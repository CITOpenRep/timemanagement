import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/constants.js" as AppConst

Text {
    id: quadrantLabel

    /**
     * The full display label, e.g.:
     * "Do First (Important & Urgent )"
     */
    property string quadrantKey: "Do First (Important & Urgent )"

    /**
     * Normalizes the quadrantKey to one of: Do, Plan, Delegate, Delete
     */
    readonly property string normalizedKey: {
        if (quadrantKey.indexOf("Do First") === 0)
            return "Do";
        else if (quadrantKey.indexOf("Do Next") === 0)
            return "Plan";
        else if (quadrantKey.indexOf("Do Later") === 0)
            return "Delegate";
        else if (quadrantKey.indexOf("Don't do") === 0)
            return "Delete";
        else
            return "Plan"; // fallback
    }

    readonly property color quadrantColor: ({
        "Do": AppConst.Colors.Quadrants.Q1,
        "Plan": AppConst.Colors.Quadrants.Q2,
        "Delegate": AppConst.Colors.Quadrants.Q3,
        "Delete": AppConst.Colors.Quadrants.Q4
    })[normalizedKey] || "#AAAAAA"

    text: quadrantKey
    color: quadrantColor
    font.pixelSize: units.gu(AppConst.FontSizes.ListSubSubHeading)
}
