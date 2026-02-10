(FolderPath as text) as text =>
let
    // Normalize path to lowercase to handle "Data" vs "data"
    LowerPath = Text.Lower(FolderPath),
    
    // Find the part after "data\"
    AfterData = Text.AfterDelimiter(LowerPath, "data\", {0, RelativePosition.FromEnd}),
    
    // Split by "\" and grab the first part (which should be the track folder)
    Parts = Text.Split(AfterData, "\"),
    
    // Get the first part (e.g., "awscloud training")
    TrackFolder = if List.Count(Parts) > 0 then Parts{0} else null,
    
    // Remove " training" suffix
    CleanTrack = if TrackFolder <> null then Text.Replace(TrackFolder, " training", "") else null,
    
    // Proper Case the result (e.g., "awscloud" -> "AWSCloud")
    // Note: This is a simple proper casing, might need adjustment if specific casing is required (like "PowerBI" vs "Powerbi")
    FinalTrack = 
        if CleanTrack = "awscloud" then "AWSCloud"
        else if CleanTrack = "powerbi" or CleanTrack = "power bi" then "PowerBI"
        else Text.Proper(CleanTrack)
in
    FinalTrack
