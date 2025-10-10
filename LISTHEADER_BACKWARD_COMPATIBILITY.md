# ListHeader Backward Compatibility Implementation

## Overview
The `ListHeader.qml` component now supports both the **old API** (individual properties) and the **new API** (array-based model) for defining filter buttons.

## Problem
When we refactored `ListHeader` to use a dynamic `filterModel` array to support unlimited filter buttons, we broke backward compatibility with pages that were using the old API with hardcoded properties (`label1-7`, `filter1-7`).

## Solution
Implemented a backward compatibility layer that automatically builds the `filterModel` array from legacy properties when they are set.

## How It Works

### Old API (Still Supported)
```qml
ListHeader {
    id: taskListHeader
    
    label1: "Today"
    label2: "This Week"
    label3: "This Month"
    
    filter1: "today"
    filter2: "this_week"
    filter3: "this_month"
    
    onFilterSelected: {
        // handle filter change
    }
}
```

### New API (Recommended)
```qml
ListHeader {
    id: myTaskListHeader
    
    Component.onCompleted: {
        var filters = [
            {label: "All", filterKey: "null"},
            {label: "Inbox", filterKey: "52"},
            {label: "In Progress", filterKey: "53"}
        ];
        filterModel = filters;
    }
    
    onFilterSelected: {
        // handle filter change
    }
}
```

## Implementation Details

1. **Legacy Property Watchers**: The component watches for changes to `label1-7` properties
2. **Automatic Model Building**: When legacy properties change, `buildFilterModelFromLegacyProperties()` is called
3. **Priority**: If `filterModel` is explicitly set (new API), legacy properties are ignored
4. **Component Initialization**: On `Component.onCompleted`, the function checks if legacy properties are set and builds the model accordingly

## Benefits

✅ **No Breaking Changes**: Existing pages (Timesheet, Tasks, Activity) continue to work without modification
✅ **New Pages Can Use New API**: Pages like MyTasks can use the dynamic `filterModel` approach
✅ **Flexible**: Supports unlimited filter buttons when using new API
✅ **Maintainable**: Old pages can be gradually migrated to new API at convenience

## Migration Path

While the old API continues to work, new pages should use the `filterModel` approach:

### To Migrate from Old to New API:

1. Remove individual `label1-7` and `filter1-7` properties
2. Build a `filterModel` array with `{label, filterKey}` objects
3. Set the `filterModel` property in `Component.onCompleted` or dynamically

### Example Migration:

**Before:**
```qml
ListHeader {
    label1: "All"
    label2: "Active"
    label3: "Draft"
    filter1: "all"
    filter2: "active"
    filter3: "draft"
}
```

**After:**
```qml
ListHeader {
    Component.onCompleted: {
        filterModel = [
            {label: "All", filterKey: "all"},
            {label: "Active", filterKey: "active"},
            {label: "Draft", filterKey: "draft"}
        ];
    }
}
```

## Pages Currently Using Each API

### Old API (Legacy, but still working):
- `Timesheet_Page.qml` - Uses label1-3, filter1-3 (All, Active, Draft)
- `Task_Page.qml` - Uses label1-6, filter1-6 (Today, This Week, This Month, Later, Done, All)
- `Activity_Page.qml` - Uses label1-6, filter1-6 (Today, This Week, This Month, Later, OverDue, All)

### New API (Dynamic):
- `MyTasks.qml` - Uses `filterModel` array with personal stages loaded from database

## Notes

- The backward compatibility layer has minimal performance impact
- Legacy properties are only processed when `filterModel` is empty
- The new API is preferred for new development due to its flexibility
