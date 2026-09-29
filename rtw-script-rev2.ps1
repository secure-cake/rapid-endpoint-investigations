#NOTE: Assumes "c:\tools\KAPE" executables/content and "d:\cases\case-name\triage_data" paths, adjust as needed
#navigate to KAPE exe folder before running script (example path below)
cd C:\tools\KAPE

#ONLY NEEDS TO BE RUN ONCE
#Install-Module ImportExcel -Force

#Input a "case name," should match the path, e.g. d:\cases\case-name
$casename = read-host -prompt "Input case name"

#invoke-kape script must be in the kape diretory
. .\Invoke-Kape.ps1

#This updates modules, maps, etc; customize directories below as needed. You don't have to run this each time, just the first time and periodically thereafter. 
Invoke-Kape -Module '!!ToolSync' --msource c:\tools\kape --mdest c:\temp

#This updates hayabusa rules; generally run once per case
Invoke-Kape -Module hayabusa_UpdateRules --msource c:\tools\kape --mdest c:\temp

#Use default paths or change the variables below:
$triage_data_directory = "d:\cases\$casename\triage_data\"
$kape_destination_directory = "d:\cases\$casename\kape_output"

#Use the default of 15 days prior for start date and/or change the startdate below; change includedevents as desired - must create evtxecmd-triage kape module with variables to use...see read.me
$startdate = (get-date).AddDays(-15)
$includedevents = '1102','1116','1117','4624','4625','4720','4722','4724','4738','5001','5007','7045','4104','4698','4769'
$csvf = "evtx-triage-output.csv"

#Edit the file extension list below for prioritized MFT output/analysis
$triage_file_extensions = ".exe",".zip",".ps1",".js",".dll",".vbs",".cmd",".bat",".xml",".7z",".rar",".vhd",".avhd"

#Workbook creation uses the ImportExcel module (no Excel install required). One-time install: Install-Module ImportExcel -Scope CurrentUser
Import-Module ImportExcel -ErrorAction Stop

#Combines a list of csv/xlsx files into one workbook, one worksheet per file (worksheet named after the file)
function Merge-FilesToWorkbook {
    param($Files, [string]$OutputPath)
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
    $usedNames = @{}
    foreach ($File in $Files) {
        $ext = $File.Extension.ToLower()
        if ($ext -notin '.csv', '.xlsx') {
            Write-Host " Skipping unsupported file type (ImportExcel cannot read $ext): $($File.Name)"
            continue
        }
        if ($ext -eq '.csv') {
            $data = Import-Csv -Path $File.FullName
            if (-not $data) {
                Write-Host " Skipping empty file: $($File.Name)"
                continue
            }
        }
        #Excel worksheet names: max 31 chars, no []:*?/\ characters, must be unique
        $sheetName = $File.BaseName -replace '[\[\]\:\*\?\/\\]', '_'
        if ($sheetName.Length -gt 31) { $sheetName = $sheetName.Substring(0, 31) }
        $baseName = $sheetName
        $i = 1
        while ($usedNames.ContainsKey($sheetName)) {
            $suffix = "_$i"
            $sheetName = $baseName.Substring(0, [Math]::Min($baseName.Length, 31 - $suffix.Length)) + $suffix
            $i++
        }
        $usedNames[$sheetName] = $true
        if ($ext -eq '.xlsx') {
            #Copy the first worksheet whole (like the original Excel COM copy) so every column, header row and formatting is kept
            Copy-ExcelWorksheet -SourceWorkbook $File.FullName -SourceWorksheet 1 -DestinationWorkbook $OutputPath -DestinationWorksheet $sheetName
        } else {
            $data | Export-Excel -Path $OutputPath -WorksheetName $sheetName
        }
    }
}

#If prompted to save in Excel, click don't save
(get-childitem -Directory $triage_data_directory).name | ForEach-Object {
    #Performs browser data, artifacts of execution, rolled up into Excel web-execution artifacts
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module ObsidianForensics_Hindsight,NirSoft_BrowsingHistoryView,NirSoft_WebBrowserDownloads,AppCompatCacheParser,PECmd,AmcacheParser,SBECmd,LECmd -mvars csv
    #Performs EVTX and Hayabusa Logon Summary EVTX processing...not rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_'-evtx' -Module EvtxECmd -mvars csv
    #Performs EVTX and Hayabusa Summary EVTX processing...rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module hayabusa_OfflineEventLogs -mvars csv
    #Creates prioritized EVTX triage output, replaces EVTX triage analysis KAPE module, parsing EVTXeCMD output instead (faster/more efficient)
    get-content $kape_destination_directory\$_'-evtx'\EventLogs\*EvtxECmd_Output.csv | ConvertFrom-Csv | Where-Object {($_.TimeCreated -gt $Startdate) -and ($_.EventID -in $includedevents)} | Export-Csv $kape_destination_directory\$_\EventLogs\$csvf -NoTypeInformation
    #Performs $MFT file listing analysis for C-D-E-F drives, output to mft-filelisting sub-directory...not rolled up into Excel. Edit "triage_file_extensions" variable above to customize output.   
    Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CC%3A -mdest "$kape_destination_directory\$_-c-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
    get-content "$kape_destination_directory\$_-c-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in $triage_file_extensions)} | Export-Csv $kape_destination_directory\$_'-c-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
    $d_drive_mft_path = "%5C%5C.%5CD%3A"
    if (Test-Path -path $d_drive_mft_path){
        Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CD%3A -mdest "$kape_destination_directory\$_-d-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
        get-content "$kape_destination_directory\$_-d-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in $triage_file_extensions)} | Export-Csv $kape_destination_directory\$_'-d-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
        }else {
        Write-Host " No D-Drive MFT found."    
        }
    $e_drive_mft_path = "%5C%5C.%5CE%3A"
      if (Test-Path -path $e_drive_mft_path){
        Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CE%3A -mdest "$kape_destination_directory\$_-e-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
        get-content "$kape_destination_directory\$_-e-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in $triage_file_extensions)} | Export-Csv $kape_destination_directory\$_'-e-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
        }else {
        Write-Host " No E-Drive MFT found."    
        }
    $f_drive_mft_path = "%5C%5C.%5CF%3A"
    if (Test-Path -path $f_drive_mft_path){
        Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CF%3A -mdest "$kape_destination_directory\$_-f-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
        get-content "$kape_destination_directory\$_-f-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in $triage_file_extensions)} | Export-Csv $kape_destination_directory\$_'-e-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
        }else {
        Write-Host " No F-Drive MFT found."    
        }  
    #Sorts the CSV files, combined below, by date/time column, before combingin them
    $TimeColumn = @('Timecreated','Timestamp','KeyLastWriteTimestamp','Visit Time','Start Time','FileKeyLastWriteTimestamp','LastModified','LastWriteTime','TargetAccessed','LastModifiedTimeUTC')
    $CSVFiles = Get-ChildItem -Path $kape_destination_directory\$_ -Recurse -Exclude *MFTeCMD* -Include *.csv
    ForEach ($CSVFile in $CSVFiles) {
    (Import-Csv -Path $CSVFile.FullName) | Sort-Object -Property $TimeColumn | Export-Csv -path $CSVFile.FullName -Force -NoTypeInformation
    }   
    
    #Combines all csv and xls files into a workbook per station...not including MFT or the full EVTX (just evtx-triage-output)
    $ExcelFiles=Get-ChildItem -Path $kape_destination_directory\$_ -Recurse -Include *.csv, *.xls, *.xlsx
    Merge-FilesToWorkbook -Files $ExcelFiles -OutputPath "$kape_destination_directory\$_-web-and-exe-evtx.xlsx"

    $ExcelFiles1=Get-ChildItem -Path $triage_data_directory\$_\results\* -include "*Netstat.csv","*Autoruns.csv","*system.pslist.csv","*Services.csv","*DNSCache.csv","*Executables.WritableDirs.csv"
    Merge-FilesToWorkbook -Files $ExcelFiles1 -OutputPath "$kape_destination_directory\$_-netstat-pslist-autoruns-dns-services-exes.xlsx"
[GC]::Collect()
}
