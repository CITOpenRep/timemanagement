# QML Unit Testing Guide

This directory contains automated unit tests for QML components using Qt Quick Test (`qmltestrunner` and `QtTest 1.0`).

## Running Tests

To run the full QML test suite inside the Clickable container:

```bash
clickable test
```

To run a specific test file or filter by test name:

```bash
clickable test -- -functions test_openDisplaysMessageAndEmitsSignal
```

## Test Directory Structure

```
tests/
├── qml/
│   ├── README.md                  # This guide
│   ├── QtCharts/                  # Mock QtCharts module for headless/unit test execution
│   │   ├── qmldir                 # Module definition registering mock ChartView, PieSeries, etc.
│   │   ├── ChartView.qml          # Mock ChartView container component
│   │   ├── Legend.qml             # Mock Legend component
│   │   ├── Margins.qml            # Mock Margins component
│   │   ├── PieSeries.qml          # Mock PieSeries component with slice management
│   │   └── PieSlice.qml           # Mock PieSlice component with slice properties
│   ├── models/                    # JavaScript core and model test suites
│   │   ├── tst_accounts.qml       # Test suite for account management, defaults, sync settings, and deletion
│   │   ├── tst_activity.qml       # Test suite for activity data, sanitizeId, type icons, date filters, and CRUD
│   │   ├── tst_constants.qml      # Test suite for constants and quadrant color configuration
│   │   ├── tst_dashboard_user_filter.qml # Test suite for dashboard user filter state, models, and queries
│   │   ├── tst_logger.qml         # Test suite for logger levels, formatting, and PII sanitization
│   │   ├── tst_main.qml           # Test suite for Main.js date helpers, name resolvers, and spent hours queries
│   │   ├── tst_notifications.qml  # Test suite for notifications creation, read status, and sync notifications
│   │   ├── tst_project.qml        # Test suite for project details, offline cache, favorites, and project updates
│   │   ├── tst_task.qml           # Test suite for task model filters, assignee parsing, date status, and CRUD
│   │   ├── tst_timer_service.qml  # Test suite for timer service state transitions and duration
│   │   ├── tst_timesheet.qml      # Test suite for timesheet creation, duration, readiness, and status transitions
│   │   └── tst_utils.qml          # Test suite for date, time, duration, and URL utilities
│   ├── scripts/                   # Feature scripts and helper utility test suites
│   │   ├── tst_chartutils.qml     # Test suite for chart data formatting, percentages, and sorting
│   │   ├── tst_chartworker.qml    # Test suite for chart WorkerScript asynchronous processing
│   │   ├── tst_htmlsanitizer.qml  # Test suite for HTML tag sanitization, color normalization, and validation
│   │   ├── tst_navigationroutes.qml # Test suite for navigation routes and page URL resolution
│   │   ├── tst_squirebridge.qml   # Test suite for Squire.js QtWebEngine messaging bridge
│   │   └── tst_taskformutils.qml  # Test suite for task form validation and save data preparation
│   ├── tst_accountselectordialog.qml # Test suite for AccountSelectorDialog picker and account switch
│   ├── tst_activitydetailscard.qml # Test suite for ActivityDetailsCard activity details, assignee, due date, and action signals
│   ├── tst_assigneefiltermenu.qml # Test suite for AssigneeFilterMenu multi-selection, search, and delegate interaction
│   ├── tst_chartinfopopup.qml     # Test suite for ChartInfoPopup guide dialog and chart section descriptions
│   ├── tst_attachmentmanager.qml  # Test suite for AttachmentManager attachment list, file deletion, and upload signals
│   ├── tst_backendbridge.qml      # Test suite for BackendBridge signal dispatch between QML and Python
│   ├── tst_colorpicker.qml        # Test suite for ColorPicker palette and custom color
│   ├── tst_contentpickerdialog.qml # Test suite for ContentPickerDialog single/multi selection
│   ├── tst_customdatepicker.qml   # Test suite for CustomDatePicker picker component
│   ├── tst_daterangeheaderfilter.qml # Test suite for DateRangeHeaderFilter filter toggle and active range text
│   ├── tst_daterangeselector.qml  # Test suite for DateRangeSelector date bounds and range pick
│   ├── tst_dayselector.qml        # Test suite for DaySelector day selection signals
│   ├── tst_ehower.qml             # Test suite for EHower 2x2 priority matrix layout and quadrant hours
│   ├── tst_ehowerindicator.qml    # Test suite for EHowerIndicator quadrant key normalization and quadrant colors
│   ├── tst_filterableheadercontents.qml # Test suite for FilterableHeaderContents filter state integration
│   ├── tst_formdrafthandler.qml   # Test suite for FormDraftHandler draft autosave, change tracking, and unsaved changes
│   ├── tst_globaltimerwidget.qml  # Test suite for GlobalTimerWidget system component
│   ├── tst_imagepreviewer.qml     # Test suite for ImagePreviewer image display, close actions, and download states
│   ├── tst_infobar.qml            # Test suite for InfoBar feedback component
│   ├── tst_inlineoptionselector.qml # Test suite for InlineOptionSelector radio-style option selection
│   ├── tst_loadingindicator.qml   # Test suite for LoadingIndicator running state and visibility
│   ├── tst_loadmorefooter.qml     # Test suite for LoadMoreFooter loading state and retry trigger
│   ├── tst_modeldownloadtimerwidget.qml # Test suite for ModelDownloadTimerWidget download progress and cancel controls
│   ├── tst_multiassigneeselector.qml # Test suite for MultiAssigneeSelector multi-select IDs array output
│   ├── tst_mytasksclosedindicator.qml # Test suite for MyTasksClosedIndicator closed/completed tasks badge
│   ├── tst_notificationbell.qml   # Test suite for NotificationBell unread counter badge and navigation
│   ├── tst_notificationpopup.qml  # Test suite for NotificationPopup message, dismiss, and timeout
│   ├── tst_outlinedtextfield.qml # Test suite for OutlinedTextField text input component
│   ├── tst_personalstageselector.qml # Test suite for PersonalStageSelector user-specific stage selection dialog
│   ├── tst_projectcard.qml        # Test suite for ProjectCard dashboard summary card and progress bar
│   ├── tst_projectdetailscard.qml # Test suite for ProjectDetailsCard project info, status badge, progress, and timer controls
│   ├── tst_projectlist.qml        # Test suite for ProjectList hierarchy navigation stack, list model population, and selection
│   ├── tst_projectpiechart.qml    # Test suite for ProjectPieChart pie slice data loading, sorting, and empty state
│   ├── tst_projectstageselector.qml # Test suite for ProjectStageSelector stage list per project
│   ├── tst_savediscarddialog.qml  # Test suite for SaveDiscardDialog save, discard, and cancel signals
│   ├── tst_selectionbutton.qml    # Test suite for SelectionButton selection state and click
│   ├── tst_settingsheader.qml     # Test suite for SettingsHeader page header and trailing actions
│   ├── tst_settingslistitem.qml   # Test suite for SettingsListItem settings list item and click handling
│   ├── tst_settingspagelayout.qml # Test suite for SettingsPageLayout layout wrapper and header anchoring
│   ├── tst_stagefiltermenu.qml    # Test suite for StageFilterMenu stage filter menu toggling
│   ├── tst_statusselector.qml     # Test suite for StatusSelector status changes and badge color
│   ├── tst_taskchartcanvas.qml    # Test suite for TaskChartCanvas horizontal bar chart rendering and task selection
│   ├── tst_taskdetailscard.qml    # Test suite for TaskDetailsCard task details card info and action signals
│   ├── tst_tasklist.qml           # Test suite for TaskList tasks list rendering, filter, and search logic
│   ├── tst_tasknamefield.qml      # Test suite for TaskNameField task name input validation and signal emission
│   ├── tst_taskpriorityselector.qml # Test suite for TaskPrioritySelector star-based priority level selector
│   ├── tst_taskrecordactionsgrid.qml # Test suite for TaskRecordActionsGrid task action buttons and signal emission
│   ├── tst_taskrow.qml            # Test suite for TaskRow task list row presentation and hours display
│   ├── tst_taskschedulefields.qml # Test suite for TaskScheduleFields planned hours and date range inputs
│   ├── tst_taskstageselector.qml  # Test suite for TaskStageSelector project task stage selection dialog
│   ├── tst_tasktimechart.qml      # Test suite for TaskTimeChart drilldown time tracking chart navigation and model updates
│   ├── tst_timepickerpopup.qml    # Test suite for TimePickerPopup time selection and confirmation
│   ├── tst_timerecorderwidget.qml # Test suite for TimeRecorderWidget timer start, stop, and pause actions
│   ├── tst_timesheetdescriptionpopup.qml # Test suite for TimeSheetDescriptionPopup description editing dialog
│   ├── tst_timesheetdetailscard.qml # Test suite for TimeSheetDetailsCard entry summary display and workflow signals
│   ├── tst_tsbutton.qml           # Test suite for TSButton action button component
│   ├── tst_tsiconbutton.qml       # Test suite for TSIconButton circular icon button component
│   ├── tst_tslabel.qml            # Test suite for TSLabel styled text component
│   ├── tst_tsprogressbar.qml      # Test suite for TSProgressbar progress indicator
│   ├── tst_tssearchbar.qml        # Test suite for TSSearchBar search input component
│   ├── tst_tsswitch.qml           # Test suite for TSSwitch toggle switch component
│   ├── tst_updatesdetailscard.qml # Test suite for UpdatesDetailsCard update summary, timestamp, status, and progress
│   ├── tst_voicetimerwidget.qml   # Test suite for VoiceTimerWidget voice recording states and timer controls
│   └── tst_workitemselector.qml   # Test suite for WorkItemSelector project and task selection logic
```

Clickable automatically discovers all files matching `tst_*.qml` under `tests/qml/` as configured in `clickable.yaml`.

## Mocking Native Modules via `-import tests/qml`

Components that depend on native or platform modules (such as `QtCharts 2.0`) can be tested headlessly without requiring native C++ Qt plugin binaries or display servers.

In `clickable.yaml`, test execution is configured with:

```bash
test: qmltestrunner -input tests/qml -import tests/qml
```

The `-import tests/qml` option instructs the QML engine's import resolver to look inside `tests/qml/` for QML modules. When a component or test executes `import QtCharts 2.0`, QML finds `tests/qml/QtCharts/qmldir` and resolves `ChartView`, `PieSeries`, `PieSlice`, `Legend`, and `Margins` to the mock QML implementations in `tests/qml/QtCharts/`.

This mechanism allows:
- Testing chart-dependent components (e.g., `ProjectPieChart`, `EHower`) in headless CI/CD environments.
- Simulating slice interactions, hover events, and animations in pure QML without GPU requirements.
- Fast execution and complete isolation from native charting backend state.

## Anatomy of a QML Test Case

Every test file follows this standard template:

```qml
import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components/feedback"

Item {
    width: units.gu(40)
    height: units.gu(70)

    // 1. Declare the component under test
    InfoBar {
        id: testTarget
    }

    // 2. Optional: Declare SignalSpies for signal verification
    SignalSpy {
        id: openedSpy
        target: testTarget
        signalName: "opened"
    }

    // 3. Define the TestCase suite
    TestCase {
        name: "InfoBarTests"
        when: windowShown

        // Run before each test function
        function init() {
            testTarget.close();
            openedSpy.clear();
        }

        // Test function: Must start with "test_"
        function test_initialProperties() {
            compare(testTarget.visible, false);
            compare(testTarget.text, "");
        }

        function test_openAction() {
            testTarget.open("Hello", 2000);
            compare(testTarget.visible, true);
            compare(openedSpy.count, 1);
        }

        // Asynchronous / timer verification
        function test_timerAutoClose() {
            testTarget.open("Expiring", 100);
            tryCompare(testTarget, "visible", false, 500);
        }
    }
}
```

## Key Assertions and Helpers

| Function | Usage | Description |
|---|---|---|
| `compare(actual, expected)` | `compare(item.visible, true)` | Strict equality check |
| `verify(condition)` | `verify(item.width > 0)` | Boolean condition check |
| `tryCompare(item, property, value, timeout)` | `tryCompare(item, "visible", false, 1000)` | Polls until property matches or timeout expires |
| `wait(ms)` | `wait(200)` | Pauses test execution for specified duration |
| `mouseClick(item, x, y, button)` | `mouseClick(buttonItem)` | Simulates user click on an Item |
| `keyClick(key)` | `keyClick(Qt.Key_Return)` | Simulates keyboard input |

## Guidelines for New Tests

1. **Isolation**: Always use `init()` or `cleanup()` to reset component state and clear `SignalSpy` counts between tests.
2. **Dimension Constraints**: Wrap the component inside an `Item` with defined width and height (e.g., using `units.gu(N)`) so layout calculations function properly.
3. **No Network or DB Calls**: Unit tests should focus on presentation components and pure UI state. For backend and sync logic, use mock data fixtures.
