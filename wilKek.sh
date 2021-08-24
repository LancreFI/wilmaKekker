#!/bin/bash
##TEMP FILES
COOKIE="/home/user/wilmaKekker/wilKeksi"
TMPF="/home/user/wilmaKekker/wilTemp"
MESSAGE="/home/user/wilmaKekker/MESSAGE"
MESSAGE_CONT="/home/user/wilmaKekker/MESSAGE_CONT"

##LOGFILE
WILOG="/home/user/wilmaKekker/wilog"

##THE BASE URL OF THE WILMA INSTANCE
WILURL="helsinki.inschool.fi"

##YOUR WILMA CRENDETIALS
USR="user@some.com"
PSW="p4AssW0rds"

##EMAIL SETTINGS
SENDERADD="some@other.net"
SENDERNAM="sendername"
RECIPIENT="other@some.us"

TIME=$(date +%d"."%m"."%Y" "%H"."%M)
echo "#####################################################################" >> "$WILOG"
echo "###         $TIME CHECKING FOR NEW MESSAGES...         ###" >> "$WILOG"
echo "#####################################################################" >> "$WILOG"

##GET SESSION ID
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL 'https://'"${WILURL}"'/' \
  -H 'authority: '"${WILURL}" \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: wilKekker' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'sec-gpc: 1' \
  -H 'sec-fetch-site: none' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-user: ?1' \
  -H 'sec-fetch-dest: document' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cookie: enableAnalytics=true' \
  --compressed > "$TMPF"

SESSID=$(cat "$TMPF"|grep Wilma2LoginID|sed -e 's/^.*D=//' -e 's/; P.*$//')

##LOG IN USING THE SESSION ID AND DEFINED CREDENTIALS
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL 'https://'"${WILURL}"'/login' \
  -H 'authority: '"${WILURL}" \
  -H 'cache-control: max-age=0' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'origin: https://'"${WILURL}" \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'user-agent: wilKekker' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'sec-gpc: 1' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-user: ?1' \
  -H 'sec-fetch-dest: document' \
  -H 'referer: https://'"${WILURL}"'/' \
  -H 'accept-language: en-US,en;q=0.9' \
  --data-urlencode "Login=""${USR}" \
  --data-urlencode "Password=""${PSW}" \
  --data-urlencode "submit=Kirjaudu+sisään" \
  -d 'SESSIONID='"${SESSID}" \
  --compressed > "$TMPF"

LOGOUTKEYS=$(grep -o "formkey.*\">" "$TMPF"|sed -e 's/^.*="//' -e 's/">.*$//')

##CHECK FOR NEW MESSAGES AND SAVE THE CHILD'S ID IF NEW MESSAGES
mapfile -t < <(grep "badge-lg" "$TMPF")
for row in "${MAPFILE[@]}"
do
        KIDS[${#KIDS[@]}]=$(echo "$row"|sed -e 's/\/messages".*$//' -e 's/^.*\!//')
done

rm "$TMPF"

for kid in "${KIDS[@]}"
do
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${kid}"'/messages/list' \
  -H 'authority: '"${WILURL}" \
  -H 'accept: */*' \
  -H 'user-agent: wilKekker' \
  -H 'x-requested-with: XMLHttpRequest' \
  -H 'sec-gpc: 1' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H $'referer: https://'"${WILURL}"'/!'"${kid}"'/messages' \
  -H 'accept-language: en-US,en;q=0.9' \
  --compressed >> "$TMPF"
done

if [[ -f "$TMPF" ]]
then
  echo "###   NEW MESSAGES FOUND!" >> "$WILOG"
  mapfile -t < <(cat -A "$TMPF"|sed -e 's/{"Messages":\[//' -e 's/\}]//g' -e 's/\}/\}\n/g' -e 's/,{/{/g'|grep -o '^.*,"Status":1}$')
  for row in "${MAPFILE[@]}"
  do
        MSGID=$(echo "$row"|grep -o 'Id":.*"Sub'|sed -e 's/Id"://' -e 's/,.*$//')
        KIDID=$(echo "$row"|grep -o '\!.*[0-9]\\'|sed -e 's/\!//' -e 's/\\//')

        curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/messages/'"${MSGID}" \
          -H 'authority: '"${WILURL}" \
          -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
          -H 'sec-ch-ua-mobile: ?0' \
          -H 'upgrade-insecure-requests: 1' \
          -H 'user-agent: wilKekker' \
          -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
          -H 'sec-fetch-site: same-origin' \
          -H 'sec-fetch-mode: navigate' \
          -H 'sec-fetch-user: ?1' \
          -H 'sec-fetch-dest: document' \
          -H $'referer: https://'"${WILURL}"'/!.'"${KIDID}"'/messages' \
          -H 'accept-language: en-US,en;q=0.9' \
          --compressed > "$MESSAGE"

        ROWS=$(wc -l < "$MESSAGE")
        SROW=$(grep -n proptable "$MESSAGE"|sed 's/:.*$//')
        CONTENTSTART=$(grep -n "ckeditor hidden" "$MESSAGE"|sed 's/:.*$//')

        tail -n "$(($ROWS-$CONTENTSTART+1))" "$MESSAGE" > "$TMPF"
        CONTENTEND=$(grep -m 1 -n "</div>" "$TMPF"|sed 's/:.*$//')
        head -n"$CONTENTEND" "$TMPF" > "$MESSAGE_CONT"
        rm "$TMPF"
        TOPIC=$(grep "<h1>" "$MESSAGE"|sed -e 's/<h1>//' -e 's/<\/h1>//')
        SENDERN=$(grep -n "<th>L.*hett" "$MESSAGE"|sed 's/:.*$//')
        SENDERN=$((SENDERN+4))
        SENTN=$(grep -n "<th>L.*hetet" "$MESSAGE"|sed 's/:.*$//')
        SENTN=$((SENTN+1))

        SENT=$(sed "$SENTN"'q;d' "$MESSAGE"|sed -e 's/^.*<td>//' -e 's/<b.*$//')
        SENDER=$(sed "$SENDERN"'q;d' "$MESSAGE"|sed -e 's/^.*">//' -e 's/<.*$//')

        if grep -q "<a href" "$MESSAGE_CONT"
        then
                mapfile -t ROW < <(grep -n "<a href" "$MESSAGE_CONT"|sed 's/:.*$//')
                mapfile -t LINK < <(grep -o "<a href.*>" "$MESSAGE_CONT"|sed -e 's/<a href="//' -e 's/">.*$//')
                ##AS THE LINK TEXT MIGHT CONTAIN MORE THAN ONE WORD
                mapfile -t LINKTXT < <(grep -o "<a href.*<\/a>" "$MESSAGE_CONT"|sed -e 's/^.*">//' -e 's/<.*$//')
        fi

        COUNT=0
        for row in "${ROW[@]}"
        do
                REPL="${LINKTXT[$COUNT]} ${LINK[$COUNT]}"

                ##NEED TO ESCAPE ALL SPECIAL CHARACTERS, OTHERWISE SED WILL TRY TO INTERPRET THEM
                REP=$(echo -e "$REPL" | sed -e 's/\//\\\//g' -e 's/\./\\\./g' -e 's/\&/\\\&/g' -e 's/\$/\\\$/g' -e 's/\%/\\\%/g' -e 's/\?/\\\?/g' -e 's/\!/\\\!/g' -e 's/\*/\\\*/g')
                sed -i "$row""s/<a href.*<\/a>/""$REP""/" "$MESSAGE_CONT"
                COUNT=$((COUNT+1))
        done
        ##REMOVE ALL HTML TAGS AND DECODE WHAT EVER HTML ENTITIES YOU NEED TO CHARACTERS
        sed -i -e 's/<[^>]*>//g' \
        -e 's/&auml;/ä/g' -e 's/&Auml;/Ä/g' -e 's/&ouml;/ö/g' -e 's/&Ouml;/Ö/g' -e 's/&acute;/-/g' -e 's/&nbsp;/ /g' \
        -e 's/&quot;/"/g' -e 's/&eacute;/e/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/&/g' -e "s/&apos;/\'/g" \
        -e 's/&euro;/eur./g' -e 's/&aring;/å/g' -e 's/&Aring;/Å/g' -e 's/&Aacute;/Alk./g' -e 's/&aacute;/alk./g' \
        -e 's/&rdquo;/"/g' -e 's/&ldquo;/"/g' -e 's/&ndash;/-/g' -e 's/&times;/ x /g' "$MESSAGE_CONT"

        KIDNAME=$(grep -o '<a href="/!'"$KIDID"'">.*<' "$MESSAGE" | sed -e 's/<[^>]*>//g' -e 's/<//')

        echo "Päivämäärä: $SENT" > "$MESSAGE"
        echo "Lähettäjä:  $SENDER" >> "$MESSAGE"
        echo "" >> "$MESSAGE"
        echo "Otsikko:    $TOPIC" >> "$MESSAGE"
        echo "" >> "$MESSAGE"
        cat "$MESSAGE_CONT" >> "$MESSAGE"
        mail -s "UUSI WILMAVIESTI $KIDNAME!" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$MESSAGE"
        echo "###   A new message for $KIDNAME, sent to $RECIPIENT...." >> "$WILOG"
        rm "$MESSAGE" "$MESSAGE_CONT"

        ##WAIT UNTIL PROCESSING NEXT MESSAGE
        sleep 2
  done
fi

##LOG OUT
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL 'https://'"${WILURL}"'/logout' \
  -H 'authority: '"${WILURL}" \
  -H 'cache-control: max-age=0' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'origin: https://'"${WILURL}" \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'user-agent: wilKekker' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'sec-gpc: 1' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-user: ?1' \
  -H 'sec-fetch-dest: document' \
  -H $'referer: https://'"${WILURL}"'/' \
  -H 'accept-language: en-US,en;q=0.9' \
  --data-urlencode 'formkey='"${LOGOUTKEYS}" \
  --compressed > /dev/null

##CLEAN UP OF TEMP FILES
rm "$COOKIE"
echo "#####################################################################" >> "$WILOG"
echo "###                             DONE                             ####" >> "$WILOG"
echo "#####################################################################" >> "$WILOG"
