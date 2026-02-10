// ============================================================
// DIM_WEEK - Power Query M Code (Metadata Driven)
// ============================================================
// Refactored to derive weeks from Folder Names and Filenames in Zoom Attendance.
// Does NOT read the file contents, making it extremely fast.
//
// Steps:
// 1. List files in Zoom Attendance folders
// 2. Extract Week Number from Folder path
// 3. Extract Date from Filename
// 4. Group by Week Number to find Min and Max Date
// ============================================================

let
    // Step 1: Get metadata from BasePath
    Source = Folder.Files(BasePath),
    
    // Step 2: Filter to only CSV files in Zoom Attendance folders
    FilteredCSV = Table.SelectRows(Source, each 
        [Extension] = ".csv" and Text.Contains([Folder Path], "Zoom Attendance")
    ),
    
    // Step 3: Extract Week Number from folder path
    AddWeekNumber = Table.AddColumn(FilteredCSV, "week_number", each 
        let
            FolderPath = [Folder Path],
            WeekMatch = Text.BetweenDelimiters(FolderPath, "Week ", "\"),
            WeekNum = if WeekMatch = "" or WeekMatch = null then 
                try Number.FromText(Text.BeforeDelimiter(Text.AfterDelimiter(FolderPath, "Week "), "\")) otherwise null
            else 
                try Number.FromText(WeekMatch) otherwise null
        in
            WeekNum
    , Int64.Type),
    
    // Step 4: Extract Date from Filename
    AddDate = Table.AddColumn(AddWeekNumber, "file_date", each 
        let
            FileName = Text.Replace([Name], ".csv", ""),
            ParsedDate = try Date.From(DateTime.FromText(FileName, [Format="dd-MMM-yyyy"])) otherwise null
        in
            ParsedDate
    , type date),
    
    // Step 5: Filter out any parse errors
    ValidRows = Table.SelectRows(AddDate, each [week_number] <> null and [file_date] <> null),
    
    // Step 6: Group by week_number to find Min (Start) and Max (End) dates
    // Note: We group ACROSS all tracks to standardized the week definition.
    GroupedWeeks = Table.Group(ValidRows, {"week_number"}, {
        {"week_start_date", each List.Min([file_date]), type date},
        {"week_end_date", each List.Max([file_date]), type date}
    }),
    
    // Step 7: Sort by Week Number
    SortedWeeks = Table.Sort(GroupedWeeks, {{"week_number", Order.Ascending}}),
    
    // Step 8: Add Week Label
    AddWeekLabel = Table.AddColumn(SortedWeeks, "week_label", each "Week " & Text.From([week_number]), type text),
    
    // Step 9: Reorder
    ReorderedColumns = Table.ReorderColumns(AddWeekLabel, {"week_number", "week_start_date", "week_end_date", "week_label"}),
    
    // Step 10: Set Types
    FinalTypes = Table.TransformColumnTypes(ReorderedColumns, { 
        {"week_number", Int64.Type}, 
        {"week_start_date", type date}, 
        {"week_end_date", type date},
        {"week_label", type text}
    })
in
    FinalTypes
