#NOTE: Assumes "c:\tools\KAPE" executables/content and "d:\cases\case-name\triage_data" paths, adjust as needed
#navigate to KAPE exe folder before running script (example path below)
cd C:\tools\KAPE

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
    $ExcelObject=New-Object -ComObject excel.application
    $ExcelObject.visible=$false
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
    $ExcelObject = $null
    $Workbook = $null
    $Worksheet = $null

    $ExcelObject1=New-Object -ComObject excel.application
    $ExcelObject1.visible=$false
    $ExcelFiles1=Get-ChildItem -Path $triage_data_directory\$_\results\* -include "*Netstat.csv","*Autoruns.csv","*system.pslist.csv","*Services.csv","*DNSCache.csv","*Executables.WritableDirs.csv"
    
    $Workbook1=$ExcelObject1.Workbooks.add()
    $Worksheet1=$Workbook1.Sheets.Item("Sheet1")

    foreach($ExcelFile1 in $ExcelFiles1){
        
        $Everyexcel=$ExcelObject1.Workbooks.Open($ExcelFile1.FullName)
        $Everysheet=$Everyexcel.sheets.item(1)
        $Everysheet.Copy($Worksheet1)
        $Everyexcel.Close($False)
    }

    $Workbook1.SaveAs("$kape_destination_directory\$_-netstat-pslist-autoruns-dns-services-exes.xlsx")
    $ExcelObject1.Quit()
    $ExcelObject1 = $null
    $Workbook1 = $null
    $Worksheet1 = $null
[GC]::Collect()
}
