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
# High-Level Workflow Steps

Acquire Artifacts {point of impact} - Using Velociraptor Offline Collector

Analyze Artifacts {start from event context} - Using KAPE and Invoke-KAPE to parse

Identify IOCs {m...i...n...d} - Filter out "normal" & focus on meaningful impact (Memory-Identity-Network-Disk)

Expand Context {find attack extents}

Contain {from attack extents}


NOTE: See the "Incident Response Capabilities Matrix Model" for more details - https://securecake.com/f/incident-response-capabilities-matrix-model---preamble?blogcategory=IRCMM

----------------

