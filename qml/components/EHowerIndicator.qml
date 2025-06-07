/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import QtQuick 2.7
import QtQuick.Controls 2.2
import "../../models/constants.js" as AppConst

Text {
    id: quadrantLabel
    property string quadrantKey: "Do"

    // Normalize to title case
    readonly property string normalizedKey: quadrantKey.charAt(0).toUpperCase() + quadrantKey.slice(1).toLowerCase()

    // Mapping of colors
    readonly property color quadrantColor: ({
            "Do": AppConst.Colors.Quadrants.Q1,
            "Plan": AppConst.Colors.Quadrants.Q2,
            "Delegate": AppConst.Colors.Quadrants.Q3,
            "Delete": AppConst.Colors.Quadrants.Q4
        })[normalizedKey] || "#AAAAAA"

    text: normalizedKey   // ✅ fixed here
    color: quadrantColor
    font.pixelSize: units.gu(1.6)
}
