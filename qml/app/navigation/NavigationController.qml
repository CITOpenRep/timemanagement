import QtQuick 2.6

Item {
    id: navigationController

    property var apLayout
    property var globalDrawer

    function navigateTo(url, pageNum) {
        if (!apLayout || typeof apLayout.setPageGlobal !== "function") {
            return;
        }
        apLayout.setPageGlobal(url, pageNum);
    }

    function navigateMenuItem(item) {
        if (!item) {
            return;
        }
        navigateTo(item.pageUrl, item.pageNum);
    }

    function pushPageFromPrimary(relativePageUrl, options) {
        if (!apLayout || !apLayout.primaryPage || typeof apLayout.addPageToNextColumn !== "function") {
            return;
        }
        apLayout.addPageToNextColumn(apLayout.primaryPage, Qt.resolvedUrl("../../" + relativePageUrl), options || {});
    }

    function popPrimaryPages() {
        if (!apLayout || typeof apLayout.removePages !== "function") {
            return;
        }
        apLayout.removePages(apLayout.primaryPage);
    }

    function closeGlobalDrawer() {
        if (!globalDrawer || typeof globalDrawer.close !== "function") {
            return;
        }
        globalDrawer.close();
    }
}
