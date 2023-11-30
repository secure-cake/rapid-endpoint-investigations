# Rapid Windows Endpoint Investigations 
Scripts and notes for performing rapid Windows endpoint "tactical triage" and investigations with Velociraptor and KAPE. 
First, acquire and stage the tooling: 
-  Velociraptor (download): https://github.com/Velocidex/velociraptor/releases (tested with 0.7.4)
-  KAPE (register, download, support the project!): https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape

Executables for KAPE Modules (download and copy to KAPE\Modules\bin\):
  -  NirSoft BrowsingHistoryView & WebBrowserDownloads: https://www.nirsoft.net/ (..\modules\bin\browsinghistoryview.exe - browserdownloadsview.exe)
  -  ObsidianForensics Hindsight: https://github.com/obsidianforensics/hindsight (..\modules\bin\hindsight.exe)
  -  Hayabusa: https://github.com/Yamato-Security/hayabusa/releases (..\modules\bin\hayabusa\)

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

Copy the offline collector executable to the system/s you are investigating. If you chose "ZIP" collection type, a ZIP file and log file will be created in the directory where the collector is saved.

If you chose "AWS Bucket" collector, a log file will be created in the directory where the collector is saved and a ZIP file will be uploaded to your Bucket. If upload fails, ZIP file will be located in the diretory where the collector was saved.

**IMPORTANT:** Run the collector as ADMINISTRATOR 
