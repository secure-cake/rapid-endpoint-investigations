#navigate to KAPE exe folder before running script (example path below)
cd C:\tools\KAPE

#invoke-kape script must be in the kape diretory
. .\Invoke-Kape.ps1

#This updates modules, maps, etc; customize directories below as needed
Invoke-Kape -Module '!!ToolSync' --msource c:\tools\kape --mdest c:\temp

#change three variables below for casename, triage dir and output dir
$casename = '2023-0829-abc'
$triage_data_directory = "D:\cases\$casename\triage_data"
$kape_destination_directory = "D:\cases\$casename\kape_output"

#change the startdate below for evtx triage, change includedevents as desired - must create evtxecmd-triage kape module with variables to use
$startdate = '2023-08-01'
$includedevents = '1102,1116,1117,4624,4625,4720,4722,4724,4738,5001,5007,7045'
$csvf = "evtx-triage-output.csv"

#if prompted to save in Excel, click don't save
(get-childitem -Directory $triage_data_directory).name | ForEach-Object {
    #Performs browser data, artifacts of execution, rolled up into Excel web-execution artifacts
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module ObsidianForensics_Hindsight,NirSoft_BrowsingHistoryView,NirSoft_WebBrowserDownloads,AppCompatCacheParser,PECmd,AmcacheParser,SBECmd -mvars csv
    #Performs EVTX and Hayabusa Logon Summary EVTX processing...not rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_'-evtx' -Module EvtxECmd,hayabusa_UpdateRules,hayabusa_OfflineLogonSummary -mvars csv
    #Performs EVTX and Hayabusa Summary EVTX processing...rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module hayabusa_OfflineEventLogs -mvars csv
    #Performs EVTX triage analysis based on date and event id, rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\auto\C%3A -mdest $kape_destination_directory\$_ -Module !EvtxECmd-Triage -mvars startdate:$startdate^includedevents:$includedevents^filename:$csvf
    #Perofrms $MFT file listing analysis, output to mft-filelisting sub-directory ...not rolled up into Excel
    Invoke-Kape -msource $triage_data_directory\$_\uploads\ntfs\%5C%5C.%5CC%3A -mdest "$kape_destination_directory\$_-mft-filelisting" -Module 'MFTECmd_$MFT_FileListing' -mvars csv
    get-content "$kape_destination_directory\$_-mft-filelisting\FileSystem\*FileListing.csv" | ConvertFrom-Csv | Where-Object {($_.Extension -eq ".exe") -or ($_.Extension -eq ".zip") -or ($_.Extension -eq ".ps1")} | Export-Csv $kape_destination_directory\$_'-mft_filelisting_executable_files.csv' -NoTypeInformation
    #Combines all csv and xls files into a workbook per station...not including MFT or Bulk_Extractor
    $ExcelObject=New-Object -ComObject excel.application
    $ExcelObject.visible=$true
    $ExcelFiles=Get-ChildItem -Path $kape_destination_directory\$_ -Recurse -Include *.csv, *.xls, *.xlsx

    $Workbook=$ExcelObject.Workbooks.add()
    $Worksheet=$Workbook.Sheets.Item("Sheet1")

    foreach($ExcelFile in $ExcelFiles){
 
        $Everyexcel=$ExcelObject.Workbooks.Open($ExcelFile.FullName)
        $Everysheet=$Everyexcel.sheets.item(1)
        $Everysheet.Copy($Worksheet)
    $Everyexcel.Close()
 
    }
$Workbook.SaveAs("$kape_destination_directory\$_-web-and-exe-evtx.xlsx")
$ExcelObject.Quit()
}
