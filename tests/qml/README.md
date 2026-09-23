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
│   ├── README.md             # This guide
│   └── tst_infobar.qml       # Example test suite for InfoBar component
```

Clickable automatically discovers all files matching `tst_*.qml` under `tests/qml/` as configured in `clickable.yaml`.

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
