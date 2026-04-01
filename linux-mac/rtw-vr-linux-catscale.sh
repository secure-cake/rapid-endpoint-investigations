#place VR offline collection ZIP files in a diretory, eg "triage_data_linux," then execute this script from that directory
#unzips collections, then copies/parses key files per host to "triage_data_linux" directory
find ./ -name "*.zip" | while read filename; do 
  basename="${filename%.*}" 
  7z x "$filename" -o"./$basename" ; find "./$basename" -name "*.tar.gz" -exec 7z x {} -o"./$basename" \; ; find "./$basename" -name "catscale_collection.tar" -exec tar -xf {} --strip-components=2 -C "./$basename" \;
  cp "./$basename/catscale_out/Process_and_Network/collection-ss-anepo.txt" "./$basename-network-sockets.txt"
  grep '^tcp' "./$basename-network-sockets.txt" | grep 'ESTAB' | awk '{print $6,$7}' | sort -u >> "./$basename-established-connections.txt"
  cp "./$basename/results/Linux.Sys.Pslist.json" "./$basename-pslist.json"
  jq -r '[.Username,.Name, .Exe, .Hash.SHA1] | @csv' "./$basename-pslist.json" | sort -u >> "./$basename-pslist-unique-hash.txt"
  cp "./$basename/catscale_out/Persistence/collection-cron-tab-list.txt" "./$basename-cron-tab.txt"
  tar -xzf "./$basename/catscale_out/Logs/collection-var-log.tar.gz" --strip-components=2 var/log/auth.log --to-stdout | grep -i -E "accepted (password|publickey)" | cut -d " " -f5,7,9 | sort -u >> "./$basename-ssh-auth-successes.txt"
done
