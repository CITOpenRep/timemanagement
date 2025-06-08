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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import "../../models/constants.js" as AppConst

Item {
    id: datepicker_tb
    width: parent.width
    height: parent.height

    signal datePicked(string formattedDate)
    property string date: ""
    property string mode: "next" // "previous" or "next"

    function setDate(dateval) {
        console.log("Udpdating date............." + dateval);
        date = dateval;
        date_text_field.text = dateval;
    }

    TextField {
        id: date_text_field
        width: parent.width
        height: parent.height
        readOnly: true
        background: Rectangle {
            radius: 5 // Set the border radius here
            border.color: "#dbdbdb"
            border.width: 1
            color: "white"
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                quickPicker.open();
            }
        }
    }

    CustomDatePicker {
        id: quickPicker
        mode: datepicker_tb.mode  // propagate mode
        onDateSelected: d => {
            console.log("User picked:", d); // e.g. "09-06-2025"

            var parts = d.split("-");
            var formatted = parts[2] + "-" + parts[1] + "-" + parts[0];  // yyyy-MM-dd

            date_text_field.text = formatted;
            date = formatted;
            datepicker_tb.datePicked(formatted);
        }
    }
}
