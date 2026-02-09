# Phase 1: Data Preparation (ETL) Guide

This guide breaks down the data import and cleaning process into manageable chunks. You have already completed the **Cloud Training Labs & Quizzes**.

## 1. Labs & Quizzes (Power BI Training)
Complete the same process for the Power BI track to ensure we have a unified view of all grades.
1.  **Get Data**: Select 'Folder'.
2.  **Path**: Browse to `.../Power BI Training/Labs & Quizes`.
3.  **Combine & Transform**:
    -   Ensure the file name is part of the data if it contains student names or weeks (though typically these files have student details inside).
    -   **Important**: Add a Custom Column `Track` = "Power BI" to distinguish this data from the Cloud Training data you already loaded.
4.  **Append Queries**:
    -   Once loaded, append this new query to your existing `Cloud_Labs_Quizzes` query (or vice versa) to create a single `Fact_Grades` table.
    -   Renaming the final query to `Fact_Grades` is recommended.

## 2. Zoom Attendance (The Nested Folder Solution)
The user has confirmed that `Zoom Attendance` has subfolders (Week 1, Week 2, etc.). **The "Folder" connector is perfect for this because it flattens everything automatically.**

**Objective**: Turn the nested folder structure into a single list of attendance records.

### Step-by-Step for Cloud Training Attendance:
1.  **Get Data -> Folder**: Select the top-level `.../Cloud Training/Zoom Attendance` folder.
    *   *Result*: Power BI will show you a list of ALL files from ALL weeks (Week 1, Week 2, etc.) in a single list. **You do not need to import week by week.**
2.  **Transform Data** (Don't combine yet):
    *   **Filter**: Check the `Name` or `Extension` column. Ensure you only have your data files (e.g., `.csv` or `.xlsx`) and filter out generic names if any (like `DS_Store`).
3.  **Extract Date from Filename (CRITICAL STEP)**:
    *   Before combining, look at the `Name` column (e.g., "2023-10-05 Attendance.csv" or "Day 1.xlsx").
    *   **If the filename has the date**:
        *   Go to `Add Column` -> `Extract` -> `Text Before Delimiter` (e.g., before ".csv").
        *   Then convert that clean text column to **Date** data type. Rename it to `Class Date`.
    *   **If the filename is just "Day 1.xlsx"**:
        *   You might need to use the `Folder Path` column to extract "Week 1" and mapped it, but usually, the filename contains the specific date.
4.  **Combine Files**:
    *   Now click the **Double Arrow** (Combine Files) on the `Content` column.
    *   Select the sample file as requested.
    *   **Important**: Power BI will attempt to automatically remove the source columns. **Ensure your `Class Date` column (created in step 3) is preserved.** If it disappears, you may need to repeat the extraction *after* the expansion, or ensure it's selected in the "Choose Columns" step if generated.
        *   *Alternative*: If Step 3 is too hard before combining, you can Combine first. The resulting table usually keeps a `Source.Name` column. You can extract the date from `Source.Name` *after* combining.
5.  **Transformation Helper Query**:
    *   In the **Transform Sample File** query (automatically created), ensure:
        *   Headers are promoted.
        *   `Duration` (or "Time in Session") is a **Number**.
        *   **Standardization**: Ensure the column with the duration is named "Duration" consistently.
6.  **Final Cleanup (In the main query)**:
    *   **Filter durations**: Any row with `Duration` (or calculated duration) <= 30 minutes should be marked as "Absent" (or just `Share of Attendance` = 0).
    *   **Create [Status]**: `if [Duration] > 30 then "Present" else "Absent"`.
    *   **Add Column [Track]**: "Cloud".
    *   **Remove Unused Columns**: Keep `Learner Name`, `Class Date`, `Duration`, `Status`, `Track`.

### Repeat for Power BI Training Attendance:
1.  Repeat the exact same process for the `.../Power BI Training/Zoom Attendance` folder.
2.  Add Column `[Track]` = "Power BI".
3.  **Append** this to the Cloud Attendance query to make your final `Fact_Attendance`.

## 3. Participation Records (Handling Comma-Separated Names)
The user has identified that the `Participants` column contains a long string of names separated by commas (e.g., "Student A, Student B, Student C..."). We need to split this so each student has their own row.

1.  **Get Data -> Folder**: Target the `.../Participation` folder.
    *   Combine files as usual. Ensure you have a `Date` column and a `Participants` column.
2.  **Split Column by Delimiter (Rows)**:
    *   Select the `Participants` column.
    *   Go to **Transform** tab -> **Split Column** -> **By Delimiter**.
    *   **Select Delimiter**: Comma (`,`).
    *   **Advanced Options**: Select **Split into Rows** (This is the critical part!).
    *   *Result*: You will now have multiple rows for the same date, one for each student name.
3.  **Clean Up Names**:
    *   The split might leave leading/trailing spaces (e.g., " John Doe").
    *   Right-click the `Participants` column -> **Transform** -> **Trim**.
    *   Rename the column to `Learner Name`.
4.  **Add Participation Score**:
    *   The instructions imply these lists represent people who participated. If being on the list means they get a score (e.g., 100% or 10 points), add a Custom Column `Participation Score` = 10 (or whatever the logic is).
    *   *Alternative*: If the file has a separate "Score" column that you need to keep, ensure it duplicates correctly when you split rows.
5.  **Consolidate**:
    *   Add `[Track]` column ("Cloud" or "Power BI").
    *   Append queries if necessary to create `Fact_Participation`.

## 4. Status of Learners
This will be our primary source for the **Learner Dimension**.

1.  **Get Data -> Excel/Folder**: Load the `Status of Learners` files.
2.  **Consolidate**: Combine both tracks.
3.  **Deduplicate**:
    -   Select the unique identifier column (e.g., Email or Name).
    -   Remove Duplicates to ensure one row per student.
    -   This table will be `Dim_Learner`.
4.  **Columns**: Ensure you have:
    -   `Learner Name`
    -   `Track` (Cloud / Power BI)
    -   `Status` (Active, Graduated, Dropout, etc.)

---
**Checkpoint**: By the end of this phase, you should have 4 main queries ready for modeling:
-   `Fact_Grades`
-   `Fact_Attendance`
-   `Fact_Participation`
-   `Dim_Learner`
