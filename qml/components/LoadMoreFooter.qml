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
import Lomiri.Components 1.3

/**
 * LoadMoreFooter - A footer component for infinite scroll ListView
 *
 * Usage in a ListView:
 *   ListView {
 *       footer: LoadMoreFooter {
 *           isLoading: isLoadingMore
 *           hasMore: hasMoreItems
 *           onLoadMore: {
 *               loadMoreData()
 *           }
 *       }
 *   }
 */
Item {
    id: loadMoreFooter
    
    // Width should match parent ListView
    width: parent ? parent.width : 0
    height: visible ? units.gu(6) : 0
    
    // Public properties
    property bool isLoading: false
    property bool hasMore: true
    property bool darkMode: theme.name === "Ubuntu.Components.Themes.SuruDark"
    
    // Signal emitted when "Load more" is requested
    signal loadMore()
    
    // Only visible when there are more items to load
    visible: hasMore
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        
        Row {
            anchors.centerIn: parent
            spacing: units.gu(1.5)
            
            // Loading spinner (visible when loading)
            ActivityIndicator {
                id: spinner
                anchors.verticalCenter: parent.verticalCenter
                running: loadMoreFooter.isLoading
                visible: loadMoreFooter.isLoading
            }
            
            // "Load more" label (visible when not loading)
            Label {
                id: loadMoreLabel
                anchors.verticalCenter: parent.verticalCenter
                visible: !loadMoreFooter.isLoading
                text: i18n.tr("Load more...")
                color: darkMode ? LomiriColors.silk : LomiriColors.slate
                fontSize: "medium"
            }
            
            // "Loading..." label (visible when loading)
            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: loadMoreFooter.isLoading
                text: i18n.tr("Loading...")
                color: darkMode ? LomiriColors.silk : LomiriColors.slate
                fontSize: "medium"
            }
        }
        
        // Click handler for manual trigger
        MouseArea {
            anchors.fill: parent
            enabled: !loadMoreFooter.isLoading && loadMoreFooter.hasMore
            onClicked: {
                loadMoreFooter.loadMore()
            }
        }
    }
}
