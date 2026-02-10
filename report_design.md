# Power BI Report Design Specification

This document outlines the data modeling, DAX measures, and visual layout for the **Dare Careers Student Progress Dashboard**. It is designed to meet the requirements in [instructions.txt](file:///c:/Users/RichardElinamNutsuga/Documents/xcode/Power%20Bi/Power-BI/instructions.txt) using the refactored Power Query data model.

---

## 1. Data Modeling (Star Schema)

Before building visuals, ensure your relationships are set up correctly in the **Model View**.

### Relationships
*   **Active Relationships**:
    *   `fact_attendance[email]`  Wait... Linking Fact to Fact is bad. linking Fact to Dim is good.
    *   `fact_attendance[email]` -> `dim_learner[email]` (*Many-to-One*)
    *   `fact_grades[email]` -> `dim_learner[email]` (*Many-to-One*)
    *   `fact_participation[email]` -> `dim_learner[email]` (*Many-to-One*)
    *   `fact_attendance[attendance_date]` -> `dim_date[date]` (*Many-to-One*)
    *   `fact_participation[participation_date]` -> `dim_date[date]` (*Many-to-One*)
*   **Inactive Relationships** (Use `USERELATIONSHIP` if needed, but not required here yet).

> **Crucial Note on Linking**: `fact_grades` uses "Week Number" and "Track" but might not have specific Dates. You can link `fact_grades[week_number]` to `dim_week[week_number]`, but `dim_week` is not directly linked to `dim_date` in a standard date-key way.
> *Recommendation*: For week-based reporting, filter `dim_week`. For date-based reporting, filter `dim_date`.

---

## 2. DAX Measures

Create a new table named `_Measures` to hold these calculations.

### A. Base Counts
```dax
Total Learners = DISTINCTCOUNT(dim_learner[learner_id])

Total Certifications = 
CALCULATE(
    [Total Learners], 
    dim_learner[is_certified] = 1
)

Total Graduations = 
CALCULATE(
    [Total Learners], 
    dim_learner[is_graduated] = 1
)

Total Dropouts = 
CALCULATE(
    [Total Learners], 
    dim_learner[current_status] = "Dropout" || dim_learner[current_status] = "In Progress" -- Adjust based on your exact status logic
)
```

### B. Rates (Page 1 Charts)
```dax
Graduation Rate = DIVIDE([Total Graduations], [Total Learners], 0)

Certification Rate = DIVIDE([Total Certifications], [Total Learners], 0)

Dropout Rate = DIVIDE([Total Dropouts], [Total Learners], 0)
```

### C. Attendance Metrics
*Start by calculating the "Attended" status at the row level (already done in Power Query as `is_attended`), but we measure it dynamically.*

```dax
// Count of sessions where the student attended > 30 mins
Total Sessions Attended = SUM(fact_attendance[is_attended])

// Total possible sessions (distinct count of session dates/tracks)
Total Sessions Available = DISTINCTCOUNT(fact_attendance[attendance_date])

// Average Attendance Rate %
Avg Attendance Rate = 
AVERAGEX(
    VALUES(dim_learner[learner_id]), 
    DIVIDE([Total Sessions Attended], CALCULATE(DISTINCTCOUNT(fact_attendance[attendance_date])), 0)
)
```

### D. Activity & Scores
```dax
// Daily Participation Score (assuming 1 participation = 1 point or 100%)
Avg Participation Score = 
AVERAGEX(
    VALUES(dim_learner[learner_id]),
    DIVIDE(COUNTROWS(fact_participation), [Total Sessions Available], 0)
) 
// Note: Adjust denominator if participation is tracked differently than attendance days.

Avg Assessment Score = AVERAGE(fact_grades[score])

Total Hours Spent = SUM(fact_attendance[duration_hours])
```

---

## 3. Visual Layout Specification

### 📄 Page 1: Overall Performance Metrics
**Goal**: High-level summary for stakeholders.

1.  **Header**: "Dare Careers - Program Performance Overview"
2.  **Slicers (Right or Left Panel)**:
    *   `dim_learner[cohort]` (Dropdown)
    *   `dim_learner[track]` (Buttons/Tiles)
    *   `dim_learner[certification_status]`
3.  **KPI Cards (Top Row)**:
    *   **Total Learners**
    *   **Total Graduations**
    *   **Total Certifications**
    *   **Total Dropouts**
4.  **Charts (Main Body)**:
    *   **Bar Chart**: *Graduation Rate by Cohort* (Axis: Cohort, Values: Graduation Rate)
    *   **Bar Chart**: *Certification Rate by Track* (Axis: Track, Values: Certification Rate)
    *   **Line/Area Chart**: *Avg Attendance over Time* (Axis: dim_date[Week], Values: Avg Attendance Rate)
    *   **Column Chart**: *Avg Assessment Scores by Assessment Type* (Axis: Assessment Type (Lab/Quiz), Values: Avg Assessment Score)

### 📄 Page 2: Detailed Learner Insights
**Goal**: Deep dive for trainers to identify at-risk students.

1.  **Header**: "Learner Detail View"
2.  **Slicers**:
    *   `dim_learner[cohort]`
    *   `dim_learner[track]`
    *   `dim_learner[current_status]` 
    *   `dim_learner[learner_name]` (Searchable Dropdown)
3.  **Learner Summary Cards (Top)**:
    *   **Selected Learner Name** (Use `SELECTEDVALUE` DAX or a Card)
    *   **Their Attendance %**
    *   **Their Avg Grade**
    *   **Total Hours**
4.  **Main Visual (The Matrix)**:
    *   **Rows**: `dim_learner[learner_name]`
    *   **Columns**: 
        *   `[Total Hours Spent]`
        *   `[Avg Attendance Rate]` (Apply Conditional Formatting: Red if < 70%)
        *   `[Avg Assessment Score]`
        *   `[Total Sessions Attended]`
        *   `[current_status]`
5.  **Drill-Through (Optional)**:
    *   Right-click a student to see their *daily* attendance log or *weekly* grade trend.

---

## 4. Implementation Checklist
1.  **Load Data**: Apply all Power Query changes.
2.  **Model**: Connect `email` fields in Model View.
3.  **Measures**: Create the DAX measures listed above.
4.  **Visuals**: Build Page 1 and Page 2.
5.  **Polish**: Add consistent titles, align formatting (decimals, percentages), and apply theme colors (Professional Blue/Teal).
