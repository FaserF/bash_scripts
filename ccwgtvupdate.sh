#!/bin/bash
telegram_channel=-1001263577170
telegram_bot_api=1047222738:AAG6PXsDO6br6n8hy1N9NN3snilzLf2tROs
temppath=/share/scripts/ccwgtvsw.txt
touch $temppath
re='^[0-9]+$'
old=0
old_full=$(cat $temppath)
#Removes . from Number and everything after it
old=$(echo $old_full | cut -f1 -d".")
newest=$old
position=99
firmware_full=$(curl -s "https://support.google.com/chromecast/answer/7124014" | grep -o -e "Build Number:..........." | sort -ru | head -n 1 | sed 's/.*Build Number: //')
#Removes . from Number and everything after it
firmware=$(echo $firmware_full | cut -f1 -d".")
if ! [[ $firmware =~ $re ]] ; then
   echo "Cant fetch firmware, setting version to 0"
   firmware=0
fi

echo "----"
echo "Newest version on google page: $firmware_full"
echo "Last known version: $old_full"
echo "----"

if [[ "$firmware" -gt "$old" ]]; then
    link="https://support.google.com/chromecast/answer/7124014"
    securitypatch=$(curl -s "https://support.google.com/chromecast/answer/7124014" | grep -o -e "Security Update:.................." | sort -ru | head -n 1)
    curl -s "https://api.telegram.org/bot$telegram_bot_api/sendMessage?chat_id=$telegram_channel&disable_web_page_preview=1&text=New Chromecast with Google TV Update available in Version $firmware_full - $securitypatch - More Information $link"
    echo "New Update found: $firmware_full - Download $link"
    echo "$firmware_full" > $temppath
fi
