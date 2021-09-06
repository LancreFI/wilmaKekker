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

##BROWSER "SETTINGS"
UAGENT="wilmaKekker v1.0"

TIME=$(date +%d"."%m"."%Y" "%H"."%M)

echo "#####################################################################" >> "$WILOG"
echo "###         $TIME CHECKING FOR NEW MESSAGES...         ###" >> "$WILOG"
echo "#####################################################################" >> "$WILOG"

##GET SESSION ID
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL 'https://'"${WILURL}"'/' \
  -H 'authority: '"${WILURL}" \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: '"${UAGENT}" \
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
  -H 'user-agent: '"${UAGENT}" \
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

##GET THE FORMKEY NEEDED TO LOG OUT
LOGOUTKEYS=$(grep -o "formkey.*\">" "$TMPF"|sed -e 's/^.*="//' -e 's/">.*$//')

##SAVE THE KID(S) ID(S) AND NAME(S) FROM THE PARENTS FRONT PAGE
mapfile -t KIDLIST < <(grep "presentation.*\!" "$TMPF"|sed -e 's/^.*\!//' -e 's/">/:/' -e 's/<\/a.*$//')

##CHECK FOR NEW MESSAGES AND SAVE THE CHILD'S ID IF NEW MESSAGES
mapfile -t < <(grep "badge-lg" "$TMPF")
for row in "${MAPFILE[@]}"
do
        KIDS[${#KIDS[@]}]=$(echo "$row"|sed -e 's/\/messages".*$//' -e 's/^.*\!//')
done

rm "$TMPF"

##GET MESSAGE LIST PER KID
for kid in "${KIDS[@]}"
do
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${kid}"'/messages/list' \
  -H 'authority: '"${WILURL}" \
  -H 'accept: */*' \
  -H 'user-agent: '"${UAGENT}" \
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
        ##GET THE MESSAGES
        mapfile -t < <(cat -A "$TMPF"|sed -e 's/{"Messages":\[//' -e 's/\}]//g' -e 's/\}/\}\n/g' -e 's/,{/{/g'|grep -o '^.*,"Status":1')

        for row in "${MAPFILE[@]}"
        do
                ##GET THE MESSAGE ID FOR THE FIRST NEW MESSAGE
                MSGID=$(echo "$row"|grep -o 'Id":.*"Sub'|sed -e 's/Id"://' -e 's/,.*$//')
                ##GET THE CHILD'S ID TO WHOM THE NEW MESSAGE IS FOR
                mapfile -t KIDID < <(echo "$row"|grep "$MSGID"|grep -Eo '\![0-9]{1,10}'|sed -e 's/\!//')
                ##IF NO ID IS FOUND (FOR EXAMPLE MESSAGES FROM THE OTHER PARENT TO YOU
                if [ -z "$KIDID" ]
                then
                        ##GET THE CHILD'S NAME
                        KIDN=$(echo "$row"|grep -Eo "\(.+SenderStu"|sed -e 's/(//' -e 's/, .*$//')
                        ##FIND THE NAME FROM THE LIST SAVED EARLIER FROM THE PARENT'S FRONTPAGE
                        for name in "${KIDLIST[@]}"
                        {
                                if echo "$name"|grep -q "$KIDN"
                                then
                                        ##GET THE ID VIA THE LIST
                                        KIDID=$(echo "$name"|grep -Eo "^[0-9]{1,10}")
                                fi
                        }
                fi

                ##GET THE MESSAGE
                curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/messages/'"${MSGID}" \
                  -H 'authority: '"${WILURL}" \
                  -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
                  -H 'sec-ch-ua-mobile: ?0' \
                  -H 'upgrade-insecure-requests: 1' \
                  -H 'user-agent: '"${UAGENT}" \
                  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
                  -H 'sec-fetch-site: same-origin' \
                  -H 'sec-fetch-mode: navigate' \
                  -H 'sec-fetch-user: ?1' \
                  -H 'sec-fetch-dest: document' \
                  -H $'referer: https://'"${WILURL}"'/!.'"${KIDID}"'/messages' \
                  -H 'accept-language: en-US,en;q=0.9' \
                  --compressed > "$MESSAGE"

                ##PARSE THE CONTENT
                ROWS=$(wc -l < "$MESSAGE")
                SROW=$(grep -n proptable "$MESSAGE"|sed 's/:.*$//')
                CONTENTSTART=$(grep -n "ckeditor hidden" "$MESSAGE"|sed 's/:.*$//')

                TOPIC=$(grep "<h1>" "$MESSAGE"|sed -e 's/<h1>//' -e 's/<\/h1>//' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g')
                SENDERN=$(grep -n "<th>L.*hett" "$MESSAGE"|sed 's/:.*$//')
                SENDERN=$((SENDERN+4))
                SENTN=$(grep -n "<th>L.*hetet" "$MESSAGE"|sed 's/:.*$//')
                SENTN=$((SENTN+1))

                SENT=$(sed "$SENTN"'q;d' "$MESSAGE"|sed -e 's/^.*<td>//' -e 's/<b.*$//')
                SENDER=$(sed "$SENDERN"'q;d' "$MESSAGE"|sed -e 's/^.*">//' -e 's/<.*$//' -e 's/Ã©/é/g' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g')

                REPLY=0

                ##IF THE NEW MESSAGE IS A REPLY TO AN EARLIER MESSAGE
                if grep -q "m-replybox" "$MESSAGE"
                then
                        REPSTART=$(grep -n "m-replybox" "$MESSAGE"|sed 's/:.*$//')
                        tail -n "$(($ROWS-$REPSTART+1))" "$MESSAGE" > "$TMPF"
                        REPEND=$(grep -m 1 -n "</div>" "$TMPF"|sed 's/:.*$//')
                        head -n"$REPEND" "$TMPF" > "$MESSAGE_CONT"
                        OTROW=$(($(grep -n "Vastauksia:" "$MESSAGE"|sed 's/:.*$//')-3))
                        ORIGTIME=$(sed "$OTROW"'q;d' "$MESSAGE")
                        echo "" >> "$MESSAGE_CONT"
                        echo "------------------------------" >> "$MESSAGE_CONT"
                        echo "" >> "$MESSAGE_CONT"
                        echo "Päivämäärä: $SENT" >> "$MESSAGE_CONT"
                        echo "Lähettäjä:  $SENDER" >> "$MESSAGE_CONT"
                        echo "" >> "$MESSAGE_CONT"
                        REPLY=1
                fi

                tail -n "$(($ROWS-$CONTENTSTART+1))" "$MESSAGE" > "$TMPF"
                CONTENTEND=$(grep -m 1 -n "</div>" "$TMPF"|sed 's/:.*$//')
                head -n"$CONTENTEND" "$TMPF" >> "$MESSAGE_CONT"
                rm "$TMPF"

                ##Kudos to dsmsk80 @https://unix.stackexchange.com/questions/92447/bash-script-to-get-ascii-values-for-alphabet
                chr() {
                        [ "$1" -lt 256 ] || return 1
                        printf "\\$(printf '%03o' "$1")"
                }

                ##CHECK IF THE MESSAGE CONTAINS ANY MAIL ADDRESSES, GET ALL THE MAIL ADDRESSES FROM THE MESSAGE AND DECODE THEM
                if grep -q "data-cfemail" "$MESSAGE_CONT"
                then
                        mapfile -t ENCRYPTED < <(grep -n "data-cfemail=" "$MESSAGE_CONT")
                        for rows in "${ENCRYPTED[@]}"
                        do
                                ENCROW=$(echo "$rows"|sed 's/:.*$//g')
                                COUNTER=0
                                ##THE MAIL ADDRESS IS ENCODED IN LOWER CASE HEX
                                mapfile -t ENCDATA < <(sed "$ENCROW""q;d" "$MESSAGE_CONT"|grep -Po "<a href=.+?data-cfemail.+?</a>"|sed -e 's/^.*cfemail=\"//' -e 's/\".*$//')
                                for ENCSTR in "${ENCDATA[@]}"
                                do
                                        ENCLEN=$(expr length "$ENCSTR")
                                        ##TO UPPERCASE, OTHERWISE THE BASE CONVERSION WILL FAIL
                                        ##THE FIRST HEX IS USED AS A BASE IN XOR
                                        BASE=$(echo "${ENCSTR^^}"|cut -c1-2)
                                        ##SO WE FIRST CONVERT IT ALONE
                                        DECBASE=$(echo "ibase=16; $BASE"|bc)
                                        DECODEDADD=""
                                        COUNTER=3
                                        while [ "$COUNTER" -lt "$ENCLEN" ]
                                        do
                                                ##TO UPPERCASE, OTHERWISE THE BASE CONVERSION WILL FAIL
                                                ENCED=$(echo "${ENCSTR^^}"|cut -c"$COUNTER"-"$((COUNTER+1))")
                                                ((COUNTER+=2))
                                                ##THEN WE CONVERT THE FOLLOWING PARTS ONE BY ONE
                                                DECED=$(echo "ibase=16; $ENCED"|bc)
                                                ##AND XOR THEM WITH THE FIRST TWO HEXES CONVERTED AND SAVE THEM IN A STRING
                                                DECODEDADD+=$(chr $(( ${DECBASE^^} ^ $DECED)))
                                        done
                                        ##NEED TO ESCAPE ALL SPECIAL CHARACTERS, OTHERWISE SED WILL TRY TO INTERPRET THEM
                                        DECREP=$(echo -e "$DECODEDADD" | sed -e 's/\//\\\//g' -e 's/\./\\\./g' -e 's/\&/\\\&/g' -e 's/\$/\\\$/g' -e 's/\%/\\\%/g' -e 's/\?/\\\?/g' -e 's/\!/\\\!/g' -e 's/\*/\\\*/g')
                                        sed -E -i "$ENCROW"'s|<a href=.+?'"$ENCSTR"'|'"$DECREP"'|' "$MESSAGE_CONT"
                                        sed -E -i "$ENCROW"'s/">.email.#[0-9]{1,4}.protected.//' "$MESSAGE_CONT"
                                done
                        done
                fi

                ##CHECK IF THE MESSAGE CONTAINS ANY LINKS
                if grep -q "<a href" "$MESSAGE_CONT"
                then
                        mapfile -t LINKROW < <(grep -n "<a href" "$MESSAGE_CONT")
                        for rows in "${LINKROW[@]}"
                        do
                                ROW=$(echo "$rows"|sed 's/:.*$//g')
                                COUNTER=0
                                mapfile -t LINK < <(sed "$ROW""q;d" "$MESSAGE_CONT"|grep -Po "<a href=\".+?(?=\")"|sed 's/^.*"//')
                                ##GETS ALL THE TEXTS, BUT PUTS THEM ON ONE ROW AND THERE*S NO WAY OF KNOWING WHICH PART BELONGS TO WHAT LINK
                                mapfile -t LINKTXT < <(sed "$ROW""q;d" "$MESSAGE_CONT"|grep -Po "<a href=.+?(?=<\/a>)"|sed -e 's/<a href=.*">//' -e 's/<.*$//') #|tr "##:" "\n")
                                for lin in "${LINKTXT[@]}"
                                do
                                        REPL="$lin ${LINK[$COUNTER]}"
                                        ##NEED TO ESCAPE ALL SPECIAL CHARACTERS, OTHERWISE SED WILL TRY TO INTERPRET THEM
                                        REP=$(echo -e "$REPL" | sed -e 's/\//\\\//g' -e 's/\./\\\./g' -e 's/\&/\\\&/g' -e 's/\$/\\\$/g' -e 's/\%/\\\%/g' -e 's/\?/\\\?/g' -e 's/\!/\\\!/g' -e 's/\*/\\\*/g')
                                        sed -i "$ROW"'s|<a href="'"${LINK[$COUNTER]}"'">'"$lin"'<\/a>|'"$REP"'|' "$MESSAGE_CONT"
                                        COUNTER=$((COUNTER+1))
                                done
                        done
                fi

                ##REMOVE ALL HTML TAGS AND DECODE WHAT EVER HTML ENTITIES YOU NEED TO CHARACTERS
                sed -i -e 's/<[^>]*>//g' \
                -e 's/&auml;/ä/g' -e 's/&Auml;/Ä/g' -e 's/&ouml;/ö/g' -e 's/&Ouml;/Ö/g' -e 's/&acute;/-/g' -e 's/&nbsp;/ /g' \
                -e 's/&quot;/"/g' -e 's/&eacute;/e/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/&/g' -e "s/&apos;/\'/g" \
                -e 's/&euro;/eur./g' -e 's/&aring;/å/g' -e 's/&Aring;/Å/g' -e 's/&Aacute;/Alk./g' -e 's/&aacute;/alk./g' \
                -e 's/&rdquo;/"/g' -e 's/&ldquo;/"/g' -e 's/&ndash;/-/g' -e 's/&times;/ x /g' -e 's/&bull;/ -/g' -e "s/\'//g" \
                -e 's/&oacute;/o/g' -e 's/&sect;/§/g' -e 's/&iacute;/i/g' "$MESSAGE_CONT"

                KIDNAME=$(grep -o '<a href="/!'"$KIDID"'">.*<' "$MESSAGE" | sed -e 's/<[^>]*>//g' -e 's/<//')

                echo "Otsikko:    $TOPIC" > "$MESSAGE"
                echo "" >> "$MESSAGE"

                if [ "$REPLY" -eq 1 ]
                then
                        cat "$MESSAGE_CONT" >> "$MESSAGE"
                else
                        echo "Päivämäärä: $SENT" >> "$MESSAGE"
                        echo "Lähettäjä:  $SENDER" >> "$MESSAGE"
                        echo "" >> "$MESSAGE"
                        cat "$MESSAGE_CONT" >> "$MESSAGE"
                fi

                mail -s "UUSI WILMAVIESTI $KIDNAME!" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$MESSAGE"
                echo "###   A new message for $KIDNAME, sent to $RECIPIENT...." >> "$WILOG"

                ##CLEAN UP OF TEMP FILES
                rm "$MESSAGE" "$MESSAGE_CONT"

                ##WAIT UNTIL PROCESSING NEXT MESSAGE
                sleep 2
        done
else
        echo "###   NO NEW MESSAGES FOUND!" >> "$WILOG"
fi


##LOG OUT
curl -b "${COOKIE}" -c "${COOKIE}" -s -iL 'https://'"${WILURL}"'/logout' \
  -H 'authority: '"${WILURL}" \
  -H 'cache-control: max-age=0' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'origin: https://'"${WILURL}" \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'user-agent: '"${UAGENT}" \
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
