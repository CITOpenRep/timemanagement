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
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/selectors"

Item {
    id: testRoot
    width: units.gu(40)
    height: units.gu(70)

    AssigneeFilterMenu {
        id: testMenu
    }

    SignalSpy {
        id: filterAppliedSpy
        target: testMenu
        signalName: "filterApplied"
    }

    SignalSpy {
        id: filterClearedSpy
        target: testMenu
        signalName: "filterCleared"
    }

    TestCase {
        name: "AssigneeFilterMenuTests"
        when: windowShown

        function init() {
            testMenu.expanded = false;
            testMenu.showAllUsersOption = false;
            testMenu.showAccountName = false;
            testMenu.assigneeModel = [];
            testMenu.selectedAssigneeIds = [];
            filterAppliedSpy.clear();
            filterClearedSpy.clear();
        }

        function test_defaultProperties() {
            compare(testMenu.showAllUsersOption, false);
            compare(testMenu.expanded, false);
            compare(testMenu.showAccountName, false);
            compare(testMenu.selectedAssigneeIds.length, 0);
        }

        function test_showAllUsersOption_initialState() {
            testMenu.showAllUsersOption = true;
            testMenu.selectedAssigneeIds = [];
            verify(!testMenu.isOnlyAllUsersSelected());

            testMenu.selectAllUsers();
            compare(testMenu.selectedAssigneeIds.length, 1);
            compare(testMenu.selectedAssigneeIds[0].user_id, -1);
            verify(testMenu.isOnlyAllUsersSelected());
        }

        function test_buildDisplayAssignees_pinsAllUsersAtTop() {
            testMenu.showAllUsersOption = true;
            testMenu.assigneeModel = [
                { id: 2, name: "Bob", account_id: 1, email: "bob@example.com" },
                { id: 1, name: "Alice", account_id: 1, email: "alice@example.com" }
            ];

            var list = testMenu.buildDisplayAssignees("");
            compare(list.length, 3);
            // First item is "All Users"
            compare(list[0].assigneeId, -1);
            compare(list[0].name, i18n.dtr("ubtms", "All Users"));
            // Subsequent items sorted alphabetically
            compare(list[1].name, "Alice");
            compare(list[2].name, "Bob");
        }

        function test_searchIntegration_filterByName() {
            testMenu.showAllUsersOption = true;
            testMenu.assigneeModel = [
                { id: 1, name: "Alice Smith", account_id: 1, email: "alice@example.com" },
                { id: 2, name: "Bob Jones", account_id: 1, email: "bob@example.com" }
            ];

            // Search by name "alice"
            var resultsAlice = testMenu.buildDisplayAssignees("alice");
            compare(resultsAlice.length, 1);
            compare(resultsAlice[0].name, "Alice Smith");

            // Search by name "bob"
            var resultsBob = testMenu.buildDisplayAssignees("bob");
            compare(resultsBob.length, 1);
            compare(resultsBob[0].name, "Bob Jones");

            // Empty query returns all (All Users + 2 employees)
            var resultsAll = testMenu.buildDisplayAssignees("");
            compare(resultsAll.length, 3);
        }

        function test_selectionExclusivity_specificUserClearsAllUsers() {
            testMenu.showAllUsersOption = true;
            testMenu.selectAllUsers();
            verify(testMenu.isOnlyAllUsersSelected());

            // Select a specific user
            testMenu.addSelectionIfMissing(testMenu.createSelection(10, 1));
            verify(!testMenu.isOnlyAllUsersSelected());
            compare(testMenu.selectedAssigneeIds.length, 1);
            compare(testMenu.selectedAssigneeIds[0].user_id, 10);
            verify(testMenu.isAssigneeSelected(10, 1));
            verify(!testMenu.isAssigneeSelected(-1, -1));
        }

        function test_multiSelection_multipleUsers() {
            testMenu.showAllUsersOption = true;
            testMenu.addSelectionIfMissing(testMenu.createSelection(10, 1));
            testMenu.addSelectionIfMissing(testMenu.createSelection(20, 1));

            compare(testMenu.selectedAssigneeIds.length, 2);
            verify(testMenu.isAssigneeSelected(10, 1));
            verify(testMenu.isAssigneeSelected(20, 1));
            verify(!testMenu.isOnlyAllUsersSelected());
        }

        function test_removeSelection_leavesEmptyWhenLastUserRemoved() {
            testMenu.showAllUsersOption = true;
            testMenu.addSelectionIfMissing(testMenu.createSelection(10, 1));
            compare(testMenu.selectedAssigneeIds.length, 1);

            // Removing the last selected user leaves selection empty (no auto-check of All Users)
            testMenu.removeSelectionIfPresent(testMenu.createSelection(10, 1));
            compare(testMenu.selectedAssigneeIds.length, 0);
            verify(!testMenu.isOnlyAllUsersSelected());
            verify(!testMenu.isAssigneeSelected(-1, -1));
        }

        function test_noUserSelected_doesNotSelectAllUsers() {
            testMenu.showAllUsersOption = true;
            testMenu.selectedAssigneeIds = [];
            verify(!testMenu.isOnlyAllUsersSelected());
            verify(!testMenu.isAssigneeSelected(-1, -1));
            compare(testMenu.selectedAssigneeIds.length, 0);
        }

        function test_filterAppliedSignal() {
            var selections = [testMenu.createSelection(10, 1), testMenu.createSelection(20, 1)];
            testMenu.filterApplied(selections);
            compare(filterAppliedSpy.count, 1);
            compare(filterAppliedSpy.signalArguments[0][0].length, 2);
        }

        function test_filterClearedSignal() {
            testMenu.filterCleared();
            compare(filterClearedSpy.count, 1);
        }

        function test_delegateLayoutAndClick() {
            testMenu.showAllUsersOption = true;
            testMenu.assigneeModel = [
                { id: 10, name: "Alice", account_id: 1, email: "alice@example.com" },
                { id: 20, name: "Bob", account_id: 1, email: "bob@example.com" }
            ];
            testMenu.expanded = true;
            wait(300);

            var listView = null;
            function findListView(item) {
                if (!item) return;
                if (item.toString().indexOf("QQuickListView") !== -1) {
                    listView = item;
                    return;
                }
                for (var i = 0; i < (item.children ? item.children.length : 0); i++) {
                    findListView(item.children[i]);
                    if (listView) return;
                }
            }
            findListView(testMenu);
            verify(listView !== null);

            var ci = listView.contentItem;


            function findItemWithText(rootItem, targetText) {
                if (!rootItem || !rootItem.children) return null;
                for (var i = 0; i < rootItem.children.length; i++) {
                    var ch = rootItem.children[i];
                    if (ch.text && ch.text.indexOf(targetText) !== -1) return ch;
                    var res = findItemWithText(ch, targetText);
                    if (res) return res;
                }
                return null;
            }

            // 1. Click on employee name label selects the user
            var aliceLabel = findItemWithText(listView.contentItem, "Alice");
            verify(aliceLabel !== null, "Alice label should be found");
            testMenu.selectedAssigneeIds = [];
            mouseClick(aliceLabel, 5, 5);
            wait(100);
            compare(testMenu.selectedAssigneeIds.length, 1);
            verify(testMenu.isAssigneeSelected(10, 1));

            // 2. Query fresh aliceLabel and click again to toggle selection off
            aliceLabel = findItemWithText(listView.contentItem, "Alice");
            verify(aliceLabel !== null, "Alice label should be found after re-render");
            mouseClick(aliceLabel, 5, 5);
            wait(100);
            compare(testMenu.selectedAssigneeIds.length, 0);

            // 3. Query fresh bobEmail and click to select Bob
            var bobEmail = findItemWithText(listView.contentItem, "bob@example.com");
            verify(bobEmail !== null, "Bob email should be found");
            mouseClick(bobEmail, 5, 5);
            wait(100);
            compare(testMenu.selectedAssigneeIds.length, 1);
            verify(testMenu.isAssigneeSelected(20, 1));

            // 4. Query fresh allUsersLabel and click to select All Users
            var allUsersLabel = findItemWithText(listView.contentItem, "All Users");
            verify(allUsersLabel !== null, "All Users label should be found");
            mouseClick(allUsersLabel, 5, 5);
            wait(100);
            verify(testMenu.isOnlyAllUsersSelected());




        }
    }
}
