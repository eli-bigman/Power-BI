// ============================================================
// DIM_DATE - Power Query M Code (Shared Version)
// ============================================================
// Refactored to generate dates based on dim_week and fact_participation.
// 
// Steps:
// 1. Get Date Range from dim_week (Start/End dates of the program)
// 2. Extrapolate to include any dates from Participation files if outside the range
// 3. Generate date list
// 4. Add derived columns (Day, Month, Year, etc.)
// ============================================================

let
    // Step 1: Get range from dim_week (The Program Schedule)
    WeekData = dim_week,
    ProgramMinDate = List.Min(WeekData[week_start_date]),
    ProgramMaxDate = List.Max(WeekData[week_end_date]),
    
    // Step 2: Get range from fact_participation (The actual activity)
    // Dependencies: fact_participation must be loaded
    ParticipationData = fact_participation,
    ParticipationDates = Table.SelectColumns(ParticipationData, {"participation_date"}),
    PartMinDate = List.Min(ParticipationDates[participation_date]),
    PartMaxDate = List.Max(ParticipationDates[participation_date]),
    
    // Step 3: Determine overall Min/Max
    // We handle nulls by defaulting to Program dates
    MinDate = List.Min({ProgramMinDate, PartMinDate}),
    MaxDate = List.Max({ProgramMaxDate, PartMaxDate}),
    
    // Step 4: Generate list of dates
    DateList = List.Dates(MinDate, Duration.Days(MaxDate - MinDate) + 1, #duration(1, 0, 0, 0)),
    
    // Step 5: Convert to table
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"date"}, null, ExtraValues.Error),
    TypedDate = Table.TransformColumnTypes(DateTable, {{"date", type date}}),
    
    // Step 6: Add Date Key
    AddDateKey = Table.AddColumn(TypedDate, "date_key", each 
        Date.Year([date]) * 10000 + Date.Month([date]) * 100 + Date.Day([date])
    , Int64.Type),
    
    // Step 7: Add Attributes
    AddYear = Table.AddColumn(AddDateKey, "year", each Date.Year([date]), Int64.Type),
    AddMonth = Table.AddColumn(AddYear, "month", each Date.Month([date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "month_name", each Date.MonthName([date]), type text),
    AddDay = Table.AddColumn(AddMonthName, "day", each Date.Day([date]), Int64.Type),
    AddDayName = Table.AddColumn(AddDay, "day_name", each Date.DayOfWeekName([date]), type text),
    
    // Step 8: Add day of week (Monday = 0)
    AddDayOfWeek = Table.AddColumn(AddDayName, "day_of_week", each 
        Date.DayOfWeek([date], Day.Monday)
    , Int64.Type),
    
    // Step 9: Add week of year
    AddWeekOfYear = Table.AddColumn(AddDayOfWeek, "week_of_year", each Date.WeekOfYear([date]), Int64.Type),
    
    // Step 10: Add is_weekend
    AddIsWeekend = Table.AddColumn(AddWeekOfYear, "is_weekend", each 
        if [day_of_week] >= 5 then 1 else 0
    , Int64.Type),
    
    // Step 11: Reorder
    ReorderedColumns = Table.ReorderColumns(AddIsWeekend, {
        "date_key", "date", "year", "month", "month_name",
        "day", "day_name", "day_of_week", "week_of_year", "is_weekend"
    }),
    
    // Step 12: Set Types
    FinalTypes = Table.TransformColumnTypes(ReorderedColumns, {
        {"date_key", Int64.Type},
        {"date", type date},
        {"year", Int64.Type},
        {"month", Int64.Type},
        {"month_name", type text},
        {"day", Int64.Type},
        {"day_name", type text},
        {"day_of_week", Int64.Type},
        {"week_of_year", Int64.Type},
        {"is_weekend", Int64.Type}
    })
in
    FinalTypes
