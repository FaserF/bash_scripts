#!/bin/bash
#Script for R851T Platform Updates - for r51M see below
telegram_channel=$1
telegram_bot_api=$2
temppath=/share/scripts/tclsw.txt
if [ ! -f $temppath ]; then
    echo "600" > $temppath
    echo "100" >> $temppath
fi
re='^[0-9]+$'
old=0
old=$(head -1 $temppath)
newest=$old
position=99
celesw=$(curl -s "http://celesw.tcl.com" | grep -o -e "R851T02-LF1V..." | sort -ru | head -n 1 | sed 's/.*LF1V//')
if ! [[ $celesw =~ $re ]] ; then
   echo "Cant fetch version for international page, setting version to 0"
   celesw=0
fi
celesw_two=$(curl -s "http://celesw.tcl.com" | grep -o -e " RT51 V..." | sort -ru | head -n 1 | sed 's/.*RT51 V//')
if ! [[ $celesw_two =~ $re ]] ; then
   echo "Cant fetch version for international page as usb flash, setting version to 0"
   celesw_two=0
fi
brasilian=$(curl -k -s "https://www.semptcl.com.br/suporte/tcl/download-de-drivers-e-manuais/?ne=55p8m&categoria=televisores&opcao=driver" | grep -o -e "Versão:...." | sort -ru | head -n 1 | sed 's/.*Versão: //')
if ! [[ $brasilian =~ $re ]] ; then
   echo "Cant fetch version for brasilian page, setting version to 0"
   brasilian=0
fi
#eu Page needs to be fixed
#eu=$(curl -k -s "https://www.tcl.com/eu/en/service/service-model.html/50EP660" | grep -A5 "SOFTWARE" | sort -ru | head -n 1 | sed 's/.*RT51_Android//')
if ! [[ $eu =~ $re ]] ; then
   echo "Cant fetch version for eu page, setting version to 0"
   eu=0
fi
#usa=$(curl -k -s "https://tclnordic.zendesk.com/hc/en-us/articles/360012806599-TCL-TV-software-downloads" | grep -A2 "EP660...." | sed '1,2d' | sed 's/.*<td>Version: v//' | sed 's/.\{5\}$//')
if ! [[ $usa =~ $re ]] ; then
   echo "Cant fetch version for usa page, setting version to 0"
   usa=0
fi
#australia=$(curl -k -s "https://support.tclelectronics.com.au/software-version/" | grep "R851T...." | sort -ru | head -1 | sed 's/.*"><u>V//' | sed 's/[</u>].*$//')
if ! [[ $australia =~ $re ]] ; then
   echo "Cant fetch version for australia page, setting version to 0"
   australia=0
fi
fourpdadl=$(curl -k -s 'https://4pda.ru/forum/index.php?showtopic=973246&st=4000#entry97613600-1' \
  | xmlstarlet format --html 2>/dev/null \
  | xmlstarlet select --template --value-of '//a[last()]/@href[.=contains(.,"-update.cedock.com")]' -n)
fourpda=$(echo $fourpdadl |  grep -o -e "R851T02-LF1V..." | sort -ru | head -n 1 | sed 's/.*R851T02-LF1V//')
if ! [[ $fourpda =~ $re ]] ; then
  fourpdadl=$(curl -k -s 'https://4pda.ru/forum/index.php?showtopic=973246&st=4000#entry97613600-1' \
  | xmlstarlet format --html 2>/dev/null \
  | xmlstarlet select --template --value-of '//a[last()]/@href[.=contains(.,"celesw.tcl.com")]' -n)
  fourpdadl=$(echo $fourpdadl | awk -F'http://' '{print $NF}')
  fourpdadl="http://$fourpdadl"
  fourpda=$(echo $fourpdadl |  grep -o -e "Update-41%20RT51%20V..." | sort -ru | head -n 1 | sed 's/.*Update-41%20RT51%20V//')
  if ! [[ $fourpda =~ $re ]] ; then
    echo "Cant fetch version for 4pda page, setting version to 0"
    fourpda=0
  fi
fi

versions=($celesw $celesw_two $brasilian $eu $usa $australia $fourpda)

echo "----"
echo "Newest version on international page: $celesw"
echo "Newest version on international page as usb flash: $celesw_two"
echo "Newest version on brasilian page: $brasilian"
echo "Newest version on eu page: $eu"
echo "Newest version on usa page: $usa"
echo "Newest version on australian page: $australia"
echo "Newest version on 4pda thread: $fourpda"
echo "Last known version: $old"
echo "----"

#Loop that compares $old with the versions and updates it
for index in "${!versions[@]}"
do
    version="${versions[index]}"
    #echo ${versions[$arg-1]}
    if [ "$version" -gt "$old" ]
    then
        if [ "$version" -gt "$newest" ]
        then
            position=$index
            newest=$version
        fi
    fi
done

max_number=$(($old + 150))
counter=$newest

#Loop that tries to get a newer version
echo "Trying to see if an update exists for the next 150 Versions on eu Server"
until [ $counter -eq $max_number ]
do
  link=http://eu-update.cedock.com/apps/resource2/V8R851T02/V8-R851T02-LF1V$counter/
  #echo "Checking version $counter at Download Link $link"
  result_curl=$(curl -s -o /dev/null -w "%{http_code}" $link)
  if [ "$result_curl" == "403" ]; then
    max_number=$counter
    newest=$counter
    link_new="Build number before .zip is missing in download link -> http://as-update.cedock.com/apps/resource2/V8R851T02/V8-R851T02-LF1V$counter/FOTA-OTA/V8-R851T02-LF1V$counter.zip"
    position=7
    echo "Newer Version found: $newest"
  else
    ((counter++))
  fi
done

echo "Newest TCL R851T Android TV Version is: $newest"

if [ "$old" != "$newest" ]; then
    if [ "$position" = "0" ]; then
        dllink="http://celesw.tcl.com"
    elif [ "$position" = "1" ]; then
        dllink="http://celesw.tcl.com"
    elif [ "$position" = "2" ]; then
        dllink=$(curl -k -s "https://www.semptcl.com.br/suporte/tcl/download-de-drivers-e-manuais/?ne=55p8m&categoria=televisores&opcao=driver" | grep -A3 "Versão: " | sed 's/^.*\(https:.*.zip\).*$/\1/' | sed -e '/div>/,+5d')
    elif [ "$position" = "3" ]; then
        dllink="https://www.tcl.com/eu/en/service/service-model.html/50EP660"
    elif [ "$position" = "4" ]; then
        dllink=$(curl -k -s "https://tclnordic.zendesk.com/hc/en-us/articles/360012806599-TCL-TV-software-downloads" | grep -A3 "EP660...." | sed '1,3d' | sed 's/.*<td><a href="//' | sed 's/.\{59\}$//')
    elif [ "$position" = "5" ]; then
        dllink=$(curl -k -s "https://support.tclelectronics.com.au/software-version/" | grep "R851T...." | sort -ru | head -1 | sed 's/.*<a href="//' | sed 's/["><].*//')
    elif [ "$position" = "6" ]; then
        dllink=$fourpdadl
    elif [ "$position" = "7" ]; then
        dllink=$link_new
    fi
    curl -s "https://api.telegram.org/bot$telegram_bot_api/sendMessage?chat_id=$telegram_channel&disable_web_page_preview=1&text=New TCL **R851T** Android TV Update available in Version **$newest**  ----->  Download $dllink"
    echo "New Update found: $newest - Download $dllink"
    sed -i "1s/.*/$newest/" $temppath
fi

#Script for r51M Platform (for example P815/P816) Updates - for R851T see above
echo "-----Beginning script for the r51M Platform------"
old_r51M=0
old_r51M=$(cat $temppath | head -2 | tail -1)
newest_r51M=$old_r51M
max_number=$(($old_r51M + 150))
counter=$newest_r51M

#Loop that tries to get a newer version
echo "Trying to see if an update exists for the next 150 Versions on eu Server"
until [ $counter -eq $max_number ]
do
  link_r51M=http://eu-update.cedock.com/apps/resource2/V8R51MT02/V8-R51MT02-LF1V$counter/FOTA-OTA/V8-R51MT02-LF1V$counter.zip
  #echo "Checking version $counter at Download Link $link_r51M"
  if curl --output /dev/null --silent --head --fail "$link_r51M"; then
    max_number=$counter
    newest_r51M=$counter
    dllink_r51m=$link_r51M
    echo "Newer Version found: $newest_r51M"
  else
    ((counter++))
  fi
done

if [ "$old_r51M" != "$newest_r51M" ]; then
    curl -s "https://api.telegram.org/bot$telegram_bot_api/sendMessage?chat_id=$telegram_channel&disable_web_page_preview=1&text=New TCL **R851T** Android TV Update available in Version **$newest_r51M**  ----->  Download $dllink_r51m"
    echo "New Update found and pushed to telegram: $newest_r51M - Download $dllink_r51m"
    sed -i "2s/.*/$newest_r51M/" $temppath
fi