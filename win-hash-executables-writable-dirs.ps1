$FormatEnumerationLimit=-1
$dayssincemodified = '-5'
$paths='c:\users','c:\programdata','c:\windows\temp'
$extensions = ".exe",".bat",".ps1",".json",".dll",".vbs",".cmd",".scr",".vhd"
$hostname = hostname
$date = Get-Date -format "yyyy-MM-dd"
get-childitem -path $paths -Recurse -Force -ErrorAction SilentlyContinue | where {$_.LastWriteTime -gt (get-date).AddDays($DaysSinceModified)} | where {$_.extension -in $extensions} | Get-FileHash -Algorithm sha1 -ErrorAction SilentlyContinue | Export-Csv $hostname-$date.csv -NoTypeInformation
