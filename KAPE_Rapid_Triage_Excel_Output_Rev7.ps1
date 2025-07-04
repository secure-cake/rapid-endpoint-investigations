#navigate to KAPE exe folder before running script (example path below)
cd C:\tools\KAPE

#invoke-kape script must be in the kape diretory
. .\Invoke-Kape.ps1

#This updates modules, maps, etc; customize directories below as needed. You don't have to run this each time, just the first time and periodically thereafter. 
Invoke-Kape -Module '!!ToolSync' --msource c:\tools\kape --mdest c:\temp

#This updates hayabusa rules; generally run once per case
Invoke-Kape -Module hayabusa_UpdateRules --msource c:\tools\kape --mdest c:\temp

#change three variables below for casename, triage dir and output dir
$casename = 'rtw_case'
$triage_data_directory = "d:\cases\$casename\triage_data"
$kape_destination_directory = "d:\cases\$casename\kape_output"

#change the startdate below for evtx triage, change includedevents as desired - must create evtxecmd-triage kape module with variables to use...see read.me
$startdate = '2025-5-25'
$includedevents = '1102,1116,1117,4624,4625,4720,4722,4724,4738,5001,5007,7045,4104,4698'
$csvf = "evtx-triage-output.csv"

#if prompted to save in Excel, click don't save
(get-childitem -Directory $triage_data_directory).name | ForEach-Object {
    #Performs browser data, artifacts of execution, rolled up into Excel web-execution artifacts
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module ObsidianForensics_Hindsight,NirSoft_BrowsingHistoryView,NirSoft_WebBrowserDownloads,AppCompatCacheParser,PECmd,AmcacheParser,SBECmd -mvars csv
    #Performs EVTX and Hayabusa Logon Summary EVTX processing...not rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_'-evtx' -Module EvtxECmd -mvars csv
    #Performs EVTX and Hayabusa Summary EVTX processing...rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module hayabusa_OfflineEventLogs -mvars csv
    #Performs EVTX triage analysis based on date and event id, rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module !EvtxECmd-Triage -mvars startdate:$startdate^includedevents:$includedevents^filename:$csvf
    #Perofrms $MFT file listing analysis for C-D-E drives, output to mft-filelisting sub-directory...not rolled up into Excel. NOTE that you can define different file extensions per partition, if beneficial. 
    Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CC%3A -mdest "$kape_destination_directory\$_-c-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
    get-content "$kape_destination_directory\$_-c-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in ".exe",".zip",".ps1",".js",".dll",".vbs",".cmd",".bat",".xml",".7z",".rar",".vhd",".avhd")} | Export-Csv $kape_destination_directory\$_'-c-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
    Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CD%3A -mdest "$kape_destination_directory\$_-d-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
    get-content "$kape_destination_directory\$_-d-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in ".exe",".zip",".ps1",".js",".dll",".vbs",".cmd",".bat",".xml",".7z",".rar",".vhd",".avhd")} | Export-Csv $kape_destination_directory\$_'-d-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
    Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CE%3A -mdest "$kape_destination_directory\$_-e-drive-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
    get-content "$kape_destination_directory\$_-e-drive-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -in ".exe",".zip",".ps1",".js",".dll",".vbs",".cmd",".bat",".xml",".7z",".rar",".vhd",".avhd")} | Export-Csv $kape_destination_directory\$_'-e-drive-mft_filelisting_executable_files.csv' -NoTypeInformation
    #Copies triage-collection "results" to kape_output directory for review
    Copy-Item $triage_data_directory\$_\results\*Netstat.csv  $kape_destination_directory\$_'-netstat-encriched.csv'
    Copy-Item $triage_data_directory\$_\results\*Autoruns.csv  $kape_destination_directory\$_'-autoruns.csv'
    Copy-Item $triage_data_directory\$_\results\*pslist.csv  $kape_destination_directory\$_'-pslist.csv'
    Copy-Item $triage_data_directory\$_\results\*Services.csv  $kape_destination_directory\$_'-services.csv'
    Copy-Item $triage_data_directory\$_\results\*DNSCache.csv  $kape_destination_directory\$_'-dnscache.csv'
    #Combines all csv and xls files into a workbook per station...not including MFT
    $ExcelObject=New-Object -ComObject excel.application
    $ExcelObject.visible=$true
    $ExcelFiles=Get-ChildItem -Path $kape_destination_directory\$_ -Recurse -Include *.csv, *.xls, *.xlsx

    $Workbook=$ExcelObject.Workbooks.add()
    $Worksheet=$Workbook.Sheets.Item("Sheet1")

    foreach($ExcelFile in $ExcelFiles){
 
        $Everyexcel=$ExcelObject.Workbooks.Open($ExcelFile.FullName)
        $Everysheet=$Everyexcel.sheets.item(1)
        $Everysheet.Copy($Worksheet)
    $Everyexcel.Close($False)
 
    }
$Workbook.SaveAs("$kape_destination_directory\$_-web-and-exe-evtx.xlsx")
$ExcelObject.Quit()
}
