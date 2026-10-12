import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    LoadMoreFooter {
        id: testFooter
        width: testRoot.width
    }

    SignalSpy {
        id: loadMoreSpy
        target: testFooter
        signalName: "loadMore"
    }

    TestCase {
        name: "LoadMoreFooterTests"
        when: windowShown

        function findSpinner(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.running !== undefined) {
                    return child;
                }
                var sub = findSpinner(child);
                if (sub) return sub;
            }
            return null;
        }

        function findMouseArea(rootItem) {
            for (var i = 0; i < rootItem.children.length; i++) {
                var child = rootItem.children[i];
                if (child.onClicked !== undefined && child.enabled !== undefined) {
                    return child;
                }
                var sub = findMouseArea(child);
                if (sub) return sub;
            }
            return null;
        }

        function init() {
            testFooter.isLoading = false;
            testFooter.hasMore = true;
            loadMoreSpy.clear();
        }

        function cleanup() {
            testFooter.isLoading = false;
            testFooter.hasMore = true;
            loadMoreSpy.clear();
        }

        function test_initialProperties() {
            compare(testFooter.isLoading, false);
            compare(testFooter.hasMore, true);
            compare(testFooter.visible, true);
            compare(testFooter.height, units.gu(6));
            compare(loadMoreSpy.count, 0);
        }

        function test_hasMoreTogglesVisibilityAndHeight() {
            testFooter.hasMore = false;
            compare(testFooter.visible, false);
            compare(testFooter.height, 0);

            testFooter.hasMore = true;
            compare(testFooter.visible, true);
            compare(testFooter.height, units.gu(6));
        }

        function test_loadingStateShowsSpinnerAndDisablesMouseArea() {
            var spinner = findSpinner(testFooter);
            verify(spinner !== null, "ActivityIndicator spinner must exist in component");
            var mouseArea = findMouseArea(testFooter);
            verify(mouseArea !== null, "MouseArea must exist in component");

            // When idle (not loading)
            testFooter.isLoading = false;
            compare(spinner.running, false);
            compare(spinner.visible, false);
            compare(mouseArea.enabled, true);

            // When loading
            testFooter.isLoading = true;
            compare(spinner.running, true);
            compare(spinner.visible, true);
            compare(mouseArea.enabled, false);

            // Back to idle
            testFooter.isLoading = false;
            compare(spinner.running, false);
            compare(spinner.visible, false);
            compare(mouseArea.enabled, true);
        }

        function test_loadMoreSignalEmission() {
            compare(loadMoreSpy.count, 0);
            testFooter.loadMore();
            compare(loadMoreSpy.count, 1);
        }

        function test_mouseClickTriggersLoadMore() {
            var mouseArea = findMouseArea(testFooter);
            verify(mouseArea !== null);

            testFooter.isLoading = false;
            testFooter.hasMore = true;
            mouseClick(mouseArea);

            compare(loadMoreSpy.count, 1);
        }

        function test_multipleRetryTriggers() {
            var mouseArea = findMouseArea(testFooter);
            verify(mouseArea !== null);

            // Simulating click to retry load
            mouseClick(mouseArea);
            compare(loadMoreSpy.count, 1);

            // Once finished loading and items still exist, another click triggers again
            testFooter.isLoading = false;
            mouseClick(mouseArea);
            compare(loadMoreSpy.count, 2);
        }

        function test_mouseAreaDisabledWhenNoMoreItems() {
            var mouseArea = findMouseArea(testFooter);
            verify(mouseArea !== null);

            testFooter.hasMore = false;
            compare(mouseArea.enabled, false);
        }
    }
}
