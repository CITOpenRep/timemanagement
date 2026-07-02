# Draft Manager & Rich Text Editor

This document outlines the key features designed to enhance data entry and prevent data loss within the application, specifically focusing on the Draft Manager and the Rich Text Editor.

---

## Unsaved Drafts Alert (Draft Manager)
The application features a robust Draft Manager to prevent data loss across tasks, timesheets, activities, and project updates.

### Crash and Unsaved Session Recovery
* Upon launching the app, if there is unsubmitted work, an **Unsaved Drafts Found** popup may appear.
* This pop-up notifies the user of unsubmitted work from a previous session (e.g., Timesheets, Project Updates).
* It prompts the user to open the respective forms to restore their changes.
* If the application crashes or the device powers off while you are actively creating a task, project update, or activity, the content is not lost. 
* Opening the respective creation form (or the specific lost task) again will automatically pre-fill all the previously entered details.

### Navigating Away (Unsaved Changes)
* If you click the back navigation arrow while actively creating or editing an item, an **Unsaved Changes** warning pop-up will appear to prevent accidental data loss.
* You will be prompted with three options:
    * **Save:** Saves the current progress.
    * **Discard:** Deletes the unsaved work and navigates away.
    * **Cancel:** Closes the pop-up so you can continue editing.

### Draft Timesheets
* Unsaved timesheet entries are safely stored in a dedicated **Draft** tab within the Timesheets screen.
* These incomplete entries are clearly marked with an orange **DRAFT** label, allowing you to easily identify and resume them.

---

## Rich Text Editor
To provide comprehensive formatting for descriptions, the application includes a dedicated Rich Text Editor for Tasks, Project Updates, and Activities.

### Accessing the Editor
* While viewing or editing the **Description** field of a task, project update, or activity, tap the **Expand (⤢)** icon.
* This action opens a full-screen "Description" page, providing a distraction-free environment for drafting detailed content.

### Formatting Tools
The editor features a top toolbar with various styling options to format your text like:
* **Bold (B), Italic (I), Underline (U), Strikethrough (S):** Standard text emphasis tools.
* **Font Size (e.g., 11pt):** Adjust the size of the text.
* **Text Color (A):** Apply different colors to highlight specific text.
* **Text Alignment/Lists:** Format paragraphs or create bulleted/numbered lists for better readability etc.

### Voice Input Integration
* **Microphone Icon:** Located on the far left of the formatting toolbar. Tapping this icon activates the configured Voice Model, allowing you to dictate text directly into the rich text editor without typing.

### Saving Changes
* Once you have finished editing, tap the **Tick (✔)** button in the top-right corner to save your changes and apply them to the description field.
