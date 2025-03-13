# I combine this with the hayabusa-copy-file-rename script to concatenate hayabusa offline events csv's into larger files for ingestion into SOF-ELK, max size is 500 MB
$csvDirectory = "D:\cases\2025-123\hayabusa-events-offline-combined

# Define the path and base name for your combined output files
$outputFileBase = "D:\cases\2025-123\hayabusa-events-offline-combined\combined-hayabusa

# Define the maximum file size in bytes (500 MB)
$maxFileSize = 450MB

# Get all CSV files in the directory
$csvFiles = Get-ChildItem -Path $csvDirectory -Filter *.csv

# Initialize an array to hold the combined data
$combinedData = @()

# Initialize file index
$fileIndex = 1

# Function to export data and check file size
function Export-Data {
    param (
        [array]$data,
        [string]$baseFileName,
        [int]$index
    )
    $outputFile = "${baseFileName}_${index}.csv"
    $data | Export-Csv -Path $outputFile -NoTypeInformation
    $fileSize = (Get-Item -Path $outputFile).Length
    return $fileSize
}

# Loop through each CSV file and import the data
foreach ($csvFile in $csvFiles) {
    $data = Import-Csv -Path $csvFile.FullName
    $combinedData += $data

    # Check if the combined data exceeds the maximum file size
    $currentFileSize = Export-Data -data $combinedData -baseFileName $outputFileBase -index $fileIndex
    if ($currentFileSize -gt $maxFileSize) {
        # Export the current data and start a new file
        $fileIndex++
        $combinedData = $data
    }
}

# Export any remaining data
if ($combinedData.Count -gt 0) {
    Export-Data -data $combinedData -baseFileName $outputFileBase -index $fileIndex
}

Write-Output "Combined CSV files into multiple files with a maximum size of $maxFileSize each."
