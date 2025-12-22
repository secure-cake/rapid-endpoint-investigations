## RTW Script UPDATES
I've re-worked (and renamed!) the script to update/improve a few things: [rtw-script-rev1](https://github.com/secure-cake/rapid-endpoint-investigations/blob/main/rtw-script-rev1.ps1)
- Reduces the necessity to review/update variables:
- -  Now prompts for "case name" input
  -  Defaults to "15 days" prior to current date for EVTX triage processing/output
- Removes errors if "D, E, F" MFT files are not present 
- Improves performance by streamlining EVTX processing
- Combines "netstat, pslist, dnscache, services, executable-file hashes" to a single Workbook for review/analysis
- LAST BUT NOT LEAST: Sorts all Worksheets in the "web-exe-evtx" Workbook by date/time automatically!!!

## Rapid Endpoint Investigations - WIKI
The previous README, with REI details, walk-through, extra links, etc. are now in the WIKI!<br />
Check out the Wiki for some related, misc items: [HERE](https://github.com/secure-cake/rapid-endpoint-investigations/wiki/Rapid-Endpoint-Investigations-%E2%80%90-Wiki-Home)<br />
