#prerequisites = 7z (sudo apt install p7zip-full)
#stage your VR collections (zip files) in a directory (triage_data_linux)
#execute this to extract each zip file to a folder based on filename (host)
find ./ -name "*.zip" | while read filename; do 
  basename="${filename%.*}" 
  7z x "$filename" -o"./$basename" ; find "./$basename" -name "*.tar.gz" -exec 7z x {} -o"./$basename" \; ; find "./$basename" -name "catscale_collection.tar" -exec tar -xf {} --strip-components=2 -C "./$basename" \;
done
