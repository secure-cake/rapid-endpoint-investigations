# Rapid Windows Endpoint Investigations 
Scripts and notes for performing rapid Windows endpoint "tactical triage" and investigations with Velociraptor and KAPE. 
First, acquire and stage the tooling: 
-  Velociraptor (download): https://github.com/Velocidex/velociraptor/releases (tested with 0.7.4)
-  KAPE (register, download, support the project!): https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape

Executables for KAPE Modules (download and copy to KAPE\Modules\bin\):
  -  NirSoft BrowsingHistoryView: https://www.nirsoft.net/utils/browsing_history_view.html (SAVE TO: ..KAPE\modules\bin\browsinghistoryview.exe
  -  NirSoft Browser Downloads View: https://www.nirsoft.net/utils/web_browser_downloads_view.html (SAVE TO: ..KAPE\modules\bin\browserdownloadsview.exe)
  -  ObsidianForensics Hindsight: https://github.com/obsidianforensics/hindsight (SAVE TO: ..KAPE\modules\bin\hindsight.exe)
  -  Hayabusa: https://github.com/Yamato-Security/hayabusa/releases (Install/Unzip Hayabusa, then COPY all of the installation-directory contents to a "hayabusa" directory AND rename the hayabusa-2.x.x-win-x64.exe to "hayabusa.exe": ..KAPE\modules\bin\hayabusa\)
  -  NOTE: You will need to run the !!ToolSync module (now included in the rapid triage script) or launch Gkape and click the "sync with github" button at the bottom before running the script!

Custom EvtxECmd Module:
NOTE: I failed to alter the module ID and have updated the !EvtxECmd-Triage.mkape module in this repo to address that issue!
  -  Download !EvtxECmd.mkape from this repo, save to your KAPE\Modules\!Local directory

Documentation References:
 - Velociraptor: https://docs.velociraptor.app/blog/2023/2023-07-27-release-notes-0.7.0/
 - KAPE: https://ericzimmerman.github.io/KapeDocs/#!index.md

Other Requirements:
    -  PowerShell 7.x
    -  S3 with user/IAM policies, if desired for Velociraptor Offline Collector Upload (notes coming soon!)
    -  Microsoft Excel
    
---------------
## High-Level Workflow Steps

Acquire Artifacts {point of impact} - Using Velociraptor Offline Collector

Analyze Artifacts {start from event context} - Using KAPE and Invoke-KAPE to parse

Identify IOCs {m...i...n...d} - Filter out "normal" & focus on meaningful impact (Memory-Identity-Network-Disk)

Expand Context {find attack extents}

Contain {from attack extents}


NOTE: See the "Incident Response Capabilities Matrix Model" for more details - https://securecake.com/f/incident-response-capabilities-matrix-model---preamble?blogcategory=IRCMM

----------------

## Velociraptor Offline Collector Configuration
Download and execute current, stable version of Velocraptor (see link above for download and documentation): 
>velociraptor-v0.7.0-4-windows-amd64.exe gui

Click on "Server Artifacts" (left-hand flyout menu), "Build Offline Collector" (paper airplane icon), then search and "click to add" artifacts:
 - Windows.Network.NetstatEnriched (NOTE: Change ProcessNameRegex to = “.”)
 - Windows.System.Pslist
 - Windows.KapeFiles.Targets (NOTE: Select "_KapeTriage")
 - Windows.Sysinternals.Autoruns

Configure "Collection:"
 - Collection Type: **ZIP**
     - Output Format: CSV and JSON
     - Pause for Prompt: Check
     - Filename Format: (I usually clear "Collection" for brevity)
-  Collection Type: **AWS Bucket** (See "AWS Collection Upload Configuration" NOTES below)
   -  S3 Bucket: your-triage-upload-bucket-name (no "/")
   -  Credentials Key: copy/paste your AWS IAM Access Key here (remove any trailing space!)
   -  Credentials Secret: copy/paste your AWS IAM Secret Key here (remove any trailing space!)
   -  Region: us-east-1 (edit according to your desired region)
   -  File Name Prefix: your-case-specific-folder-name/ (include trailing "/")
   -  Output Format: CSV and JSON
   -  Pause for Prompt: Check
-  Launch/Download Collector:
   -  Click "Server.Utils.CreateCollector, Uploaded Files," then click "Collector_velociraptor-vn.n.n-windows-amd64.exe"
   -  If you receive browser warnings, "keep" and download
   -  Rename collector descriptively, eg "case-xyz-offline-collector-win-x64.exe"

## AWS Collection Upload Configuration: 
If you want to use automatic upload to S3 for your Velociraptor Offline Collector, configure the following: 
-  S3 Bucket: I create a "triage upload" bucket and then create a "sub-folder:"
  -  Bucket: your-company-dfir-uploads (Use SSE, do not specify Key)
  -  Folder in Bucket: 2023-11-case-xyz
-  IAM Console:
   -  Create a User: Users\Create User\2023-11-case-xyz (I name the User based on the "case")
   -  Create Inline Policy: Click user (2023-11-case-xyz"), Add Permissions, Create Inline Policy, JSON (copy/paste policy below, changing SID and bucket/folder names:
```
{ 
    "Version": "2012-10-17", 
    "Statement": [ 
      { 
        "Sid": "yourcompanyuploadonly", 
        "Effect": "Allow", 
        "Action": [ 
          "s3:PutObject" 
        ], 
        "Resource": [ 
            "arn:aws:s3:::your-company-dfir-uploads/2023-11-case-xyz", 
            "arn:aws:s3::: your-company-dfir-uploads/2023-11-case-xyz /*" 
        ] 
      } 
  ] 
} 
```
- IAM Console (continued):
  - Save Changes
  - Click the "Security Credentials" tab, "Create Access Key," select "Application running outside AWS," Next, provide descriptive name tag
  - Copy/paste Access Key and Secret Key (see "Collection Type: AWS Bucket" config above) [save/record securely as required]

**IMPORTANT:** The IAM Keys are easily extracted from the VR Offline Collector, so make certain the policy is narrow and applies ONLY to the "triage" bucket/folder

## Velociraptor Offline Collector Execution
NOTE: I highly recommend you test your offline collector prior to deployment!

Copy the offline collector executable to the system/s you are investigating. If you chose "ZIP" collection type, a ZIP file and log file will be created in the directory where the collector is saved. At completion, "Press the Enter Key to end."

If you chose "AWS Bucket" collector, a log file will be created in the directory where the collector is saved and a ZIP file will be uploaded to your Bucket and saved in the diretory where the collector was saved/executed. "Press the Enter Key to end."

**IMPORTANT:** Run the collector as ADMINISTRATOR 

----------------

## Using KAPE and Invoke-KAPE to Parse Offline Triage Collection
Stage your ZIP file/s and edit the Kape_Rapid_Triage_Excel_Rev2.ps1 script to match your drive and folder structure:

I use an EC2 Windows 2022 instance, creating an OS Volume (C: - 120 GB) and a Case/Data Volume (D: - 1 to 2 TB, mostly for IOPs but also to accommodate numerous collections).
I'll then create a "case folder," eg D:\cases\2023-11-1-abc, with a "triage_data" subdirectory, and copy one or more ZIP files into that subdirectory. 
You can manually unzip the ZIP files, if there are only one or two, or you can use the "expand-archive-triage-data-rev3.ps1" script (requires PoSh 7.x) to unzip all ZIP files in your "triage_data" folder, automatically creating unique subfolders for each ZIP-file output. 

NOTE: I store all of my tools on the OS Volume (C:\Tools\..) and then delete and re-create the Case/Data Volume for each Case. 

Next, review the Kape_Rapid_Triage_Excel_Rev2.ps1 script and change variables to match your setup:
NOTE: I use Visual Studio Code to open/edit/run the Script
  1.  In your Terminal, navigate to the directory where you installed KAPE ("Invoke-Kape.ps1" should be in the same directory):
      - eg C:\Tools\KAPE
  2.  Edit the case directory variables:
      - $casename = '2023-11-1-abc'
      - $triage_data_directory = "D:\cases\$casename\triage_data"
      - $kape_destination_directory = "D:\cases\$casename\kape_output"
  3.  Edit the EVTX triage variables:
      - $startdate = '2023-11-01'
      - $includedevents = (add/delete as desired!)
      - $csvf = (this is the output file name, change as desired)
  4.  Edit the MFT File Listing file extensions, as desired (line 29):
      - Example - Add file extension: ...ps1") -or ($_.Extension -eq ".7z")}
  5.  Run the script!
Upon completion, you should have three directories, one CSV file and one XLSX file for each Triage Collection under your Case Folder\kape_output:
-  eg D:\cases\2023-11-1-abc\kape_output\Workstation01 (original ZIP collection files)
-  eg D:\cases\2023-11-1-abc\kape_output\Workstation01-evtx (processed EVTX files)
-  eg D:\cases\2023-11-1-abc\kape_output\Workstation01-mft-filelisting (processed MFT files)
-  eg D:\cases\2023-11-1-abc\kape_output\Workstation01\Workstation01-mft_filelisting_executable_files.csv (MFT filtered on specified File Extensions)
-  eg D:\cases\2023-11-1-abc\kape_output\Workstation01\Workstation01-web-and-exe.evtx.xlsx (combined output from "triage" EVTX, Hayabusa, Web and Execution artifacts)
  
NOTE: Don't forget you have some pre-extracted/parsed data in the D:\cases\2023-11-1-abc\triage_data\Workstation01\results folder (Autoruns, Netstat, PSlist)

## Find Evil!
You have some context already or you wouldn't be here, doing this! Start with that: date/timestamp, process name, user account, filename, etc. 
This process is designed for expedient, actionable intelligence, not minutae! I'd start with:
-  The "-web-and-exe-evtx.xslx" workbok and with Hayabusa "high/critical" findings
-  Check "Nestat Enriched" and "PSList" (NOTE: these are located in the ..\triage_data\Workstation01\results folder)
-  After that, I'll usually pivto to MFT file listing, looking for files of interest based on "date/timestamp" (noted below)

Once you identify a date/timestamp, use that intelligence to narrow your review of other artifacts:
-  Start with "concurrent" (what happened at or about the same time?)
-  Expand your date/timestamp scope to look for "antecedent" indicators (what happend right after?)
-  Expand your date/timestamp scope to look for "precedent" indicators (what happend right before?)
-  Take whatever "clues" (aka IOC's) and search for "attack extents" (the end of indicators on the endpoint, other endpoints, all endpoints in your environment)

**NOTE:** Don't forget that you have the unfiltered versions of parsed EVTX and MFT available for follow-up/deeper analysis (D:\cases\2023-11-1-abc\kape_output\Workstation01-mft-filelisting\Filesystem ... and Workstation01-evtx\EventLogs)
