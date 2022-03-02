#!/bin/bash
###
## Call the script with one or more of the following arguments:
## -h  --> get homework and upcoming exams and email them to the recipient
## -m  --> get unread messages and email them to the recipient
## -no --> get the teacher's notes for the current date
###
##TEMP FILES
COOKIE="/home/user/wilmaKekker/wilKeksi"
TMPF="/home/user/wilmaKekker/wilTemp"
TMPF2="/home/user/wilmaKekker/wilTemp2"
TMPF3="/home/user/wilmaKekker/wilTemp3"
TMPF4="/home/user/wilmaKekker/wilTemp4"
HWFILE="/home/user/wilmaKekker/wilHw"
NOTEFILE="/home/user/wilmaKekker/wilNts"
MESSAGE="/home/user/wilmaKekker/MESSAGE"
MESSAGE_CONT="/home/user/wilmaKekker/MESSAGE_CONT"
WILARGS="/home/user/wilmaKekker/wilArgs_temp"

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
UAGENT="wilmaKekker v3.0"

##OTHER
TIME=$(date +%d"."%m"."%Y" "%H"."%M)
MAXARGS=3

##MESSAGES FUNCTION
getMessages()
{
        echo "#####################################################################" >> "$WILOG"
        echo "###         $TIME CHECKING FOR NEW MESSAGES...         ###" >> "$WILOG"
        echo "#####################################################################" >> "$WILOG"

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

                        TOPIC=$(grep "<h1>" "$MESSAGE"|sed -e 's/<h1>//' -e 's/<\/h1>//' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g')
                        SENDERN=$(grep -n "<th>L.*hett" "$MESSAGE"|sed 's/:.*$//')
                        SENDERN=$((SENDERN+4))
                        SENTN=$(grep -n "<th>L.*hetet" "$MESSAGE"|sed 's/:.*$//')
                        SENTN=$((SENTN+1))

                        SENT=$(sed "$SENTN"'q;d' "$MESSAGE"|sed -e 's/^.*<td>//' -e 's/<b.*$//')
                        SENDER=$(sed "$SENDERN"'q;d' "$MESSAGE"|sed -e 's/^.*">//' -e 's/<.*$//' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g')

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

                        ##GET ALL THE MAIL ADDRESSES FROM THE MESSAGE AND DECODE THEM
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

                        if grep -q "<a href" "$MESSAGE_CONT"
                        then
                                mapfile -t LINKROW < <(grep -n "<a href" "$MESSAGE_CONT")
                                for rows in "${LINKROW[@]}"
                                do
                                        ROW=$(echo "$rows"|sed 's/:.*$//g')
                                        COUNTER=0
                                        mapfile -t LINK < <(sed "$ROW""q;d" "$MESSAGE_CONT"|grep -Po "<a href=\".+?(?=\")"|sed 's/^.*"//')
                                        ##GETS ALL THE TEXTS, BUT PUTS THEM ON ONE ROW AND THERE*S NO WAY OF KNOWING WHICH PART BELONGS TO WHAT LINK
                                        mapfile -t LINKTXT < <(sed "$ROW""q;d" "$MESSAGE_CONT"|grep -Po "<a href=.+?(?=<\/a>)"|sed -e 's/<a href=.*">//' -e 's/<.*$//')
                                        for lin in "${LINKTXT[@]}"
                                        do
                                                if [[ "$lin" == "${LINK[$COUNTER]}" ]]
                                                then
                                                        REPL="$lin"
                                                else
                                                        REPL="$lin ${LINK[$COUNTER]}"
                                                fi
                                                
                                                ##NEED TO ESCAPE ALL SPECIAL CHARACTERS, OTHERWISE SED WILL TRY TO INTERPRET THEM
                                                REP=$(echo -e "$REPL" | sed -e 's/\//\\\//g' -e 's/\./\\\./g' -e 's/\&/\\\&/g' -e 's/\$/\\\$/g' -e 's/\%/\\\%/g' -e 's/\?/\\\?/g' -e 's/\!/\\\!/g' -e 's/\*/\\\*/g')
                                                if [[ "${LINK[$COUNTER]}" == "#OnlyHTTPAndHTTPSAllowed" ]]
                                                then
                                                        sed -i "$ROW"'s|<a href="'"${LINK[$COUNTER]}"'">'"$lin"'<\/a>|'"$lin"'|' "$MESSAGE_CONT"
                                                else
                                                        sed -i "$ROW"'s|<a href="'"${LINK[$COUNTER]}"'">'"$lin"'<\/a>|'"$REP"'|' "$MESSAGE_CONT"
                                                fi

                                                COUNTER=$((COUNTER+1))
                                        done
                                done
                        fi

                        ##REMOVE ALL HTML TAGS AND DECODE WHAT EVER HTML ENTITIES YOU NEED TO CHARACTERS
                        sed -i -e 's/<[^>]*>//g' "$MESSAGE_CONT"
                        perl -C -MHTML::Entities -Mutf8 -CS -pe 'decode_entities($_);' < "$MESSAGE_CONT" | sed -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g' > "$TMPF"
                        mv "$TMPF" "$MESSAGE_CONT"

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
                        rm "$MESSAGE" "$MESSAGE_CONT"
                        
                        ##WAIT UNTIL PROCESSING NEXT MESSAGE
                        sleep 2
                done
        else
                echo "###   NO NEW MESSAGES FOUND!" >> "$WILOG"
        fi
}

##NOTES FUNCTION
getNotes()
{
        echo "#####################################################################" >> "$WILOG"
        echo "###         $TIME CHECKING FOR NEW NOTES...            ###" >> "$WILOG"
        echo "#####################################################################" >> "$WILOG"
        touch "$NOTEFILE"

        NTFDATE=$(date +%-d.%-m.%Y)
        
        for name in "${KIDLIST[@]}"
        do
                ##GET THE ID VIA THE LIST
                KIDID=$(echo "$name"|grep -Eo "^[0-9]{1,10}")
                KIDNAME=$(echo "$name"|sed -e 's/^.*://')
                NSUBR="0"

                ##GET THE COURSE NAMES FROM THE STUDENT'S FRONTPAGE
                curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/' \
                  -H 'authority: '"${WILURL}" \
                  -H 'upgrade-insecure-requests: 1' \
                  -H 'user-agent: '"${UAGENT}" \
                  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
                  -H 'sec-gpc: 1' \
                  -H 'sec-fetch-site: same-origin' \
                  -H 'sec-fetch-mode: navigate' \
                  -H 'sec-fetch-user: ?1' \
                  -H 'sec-fetch-dest: document' \
                  -H $'referer: '"${WILURL}"'/' \
                  -H 'accept-language: en-US,en;q=0.9' \
                  --compressed > "$TMPF2"

                ##GET THE TEACHER'S NOTES
                curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/attendance/view?range=0' \
                  -H 'authority: '"${WILURL}" \
                  -H 'upgrade-insecure-requests: 1' \
                  -H 'user-agent: '"${UAGENT}" \
                  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
                  -H 'sec-gpc: 1' \
                  -H 'sec-fetch-site: same-origin' \
                  -H 'sec-fetch-mode: navigate' \
                  -H 'sec-fetch-user: ?1' \
                  -H 'sec-fetch-dest: document' \
                  -H $'referer: '"${WILURL}"'/!'"${KIDID}"'/attendance' \
                  -H 'accept-language: en-US,en;q=0.9' \
                  --compressed > "$TMPF3"

                ##GREP FOR NEW NOTES BY DATE
                NTFSROW=$(grep -n "<td align=\"right\">$NTFDATE" "$TMPF3"|sed 's/: .*$//')

                ##IF NOTES ARE FOUND FOR THE DATE SEARCHED
                if [ "$NTFSROW" ]
                then
                        echo ".----------------------------------------" > "$NOTEFILE"
                        echo "| $KIDNAME's notes for $NTFDATE:" >> "$NOTEFILE"
                        echo "|----------------------------------------" >> "$NOTEFILE"

                        NTFEROW="$NTFSROW"

                        ##HANDLE ROW BY ROW UNTIL THE CURRENT ROW'S END TAG IS REACHED
                        until [ $(sed "$NTFEROW""q;d" "$TMPF3"|grep -o "</tr") ]
                        do
                                ##GET THE NOTE
                                NOTE=$(sed "$NTFEROW""q;d" "$TMPF3"|grep "<td class=\"event"|sed -e 's/^.*title="//' -e 's/">/ (/' -e 's/<\/td.*$/)/' -e 's/<sup.*<\/sup>//'|sed -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g')
                                ##IF THE NOTE HAS ACTUAL CONTENT
                                if [ "$NOTE" ]
                                then
                                        ##GET THE SUBJECT'S NAME
                                        NSUB=$(grep -oP -m1 "^(.*?);" < <(echo "$NOTE")|sed -e 's/;//')

                                        ##GET THE ROW CONTAINING THE SUBJECT'S DESCRIPTION
                                        NSUBR=$(grep -n "$NSUB" "$TMPF2"|sed 's/: .*$//')

                                        ##IF THE SUBJECT'S NAME HAS BEEN DEFINED (NSUBR IS NOT DEFINED, IF THE DESC WASN'T FOUND ON THE FRONTPAGE OF THE CHILD)
                                        if [ "$NSUB" ] && [ "$NSUBR" ]
                                        then
                                                ((NSUBR=NSUBR+1))
                                                ##GET THE SUBJECT DESCRIPTION
                                                NSUBN=$(sed "$NSUBR""q;d" "$TMPF2"|sed -e 's/^.*>: //' -e 's/ &#160.*$//')
                                                ##REPLACE THE SUBJECT'S NAME WITH BOTH THE NAME AND THE DESCRIPTION
                                                NOTEF=$(echo "$NOTE"|sed "s/$NSUB/$NSUB: $NSUBN/")
                                                ##FORM THE FINAL NOTE
                                                NOTE=$(echo "$NOTEF"|sed -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g')
                                        fi
                                echo "  $NOTE" >> "$NOTEFILE"
                                fi
                                ((NTFEROW=NTFEROW+1))
                        done;
                        
                        echo "'----------------------------------------" >> "$NOTEFILE"
                        mail -s "$(date +%d.%m.%Y) TUNTIMERKINNÄT!" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$NOTEFILE"
                        echo "###   $(date +%d.%m.%Y) notes for $KIDNAME sent to $RECIPIENT...." >> "$WILOG"

                        ##REMOVE TEMP FILES
                        rm "$TMPF2" "$TMPF3" "$NOTEFILE"
                fi
        done
}

##HOMEWORK FUNCTION
getHomework()
{
        echo "#####################################################################" >> "$WILOG"
        echo "###         $TIME CHECKING FOR HOMEWORK...             ###" >> "$WILOG"
        echo "#####################################################################" >> "$WILOG"
        touch "$HWFILE"
        for name in "${KIDLIST[@]}"
        do
                SCOUNTER=0
                ##GET THE ID VIA THE LIST
                KIDID=$(echo "$name"|grep -Eo "^[0-9]{1,10}")
                KIDNAME=$(echo "$name"|sed -e 's/^.*://')
                curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/' \
                  -H 'authority: '"${WILURL}" \
                  -H 'accept: */*' \
                  -H 'user-agent: '"${UAGENT}" \
                  -H 'x-requested-with: XMLHttpRequest' \
                  -H 'sec-gpc: 1' \
                  -H 'sec-fetch-site: same-origin' \
                  -H 'sec-fetch-mode: cors' \
                  -H 'sec-fetch-dest: empty' \
                  -H $'referer: https://'"${WILURL}"'/!'"${KIDID}"'/messages' \
                  -H 'accept-language: en-US,en;q=0.9' \
                  --compressed > "$TMPF2"

                mapfile -t SUBJECTS < <(grep -Po 'groups/[0-9]{1,100}"' "$TMPF2"|sed -e 's/^.*\///' -e 's/"//')
                for subj in "${SUBJECTS[@]}"
                do
                        curl -b "${COOKIE}" -c "${COOKIE}" -s -iL $'https://'"${WILURL}"'/!'"${KIDID}"'/groups/'"${subj}" \
                          -H 'authority: '"${WILURL}" \
                          -H 'upgrade-insecure-requests: 1' \
                          -H 'user-agent: '"${UAGENT}" \
                          -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
                          -H 'sec-gpc: 1' \
                          -H 'sec-fetch-site: same-origin' \
                          -H 'sec-fetch-mode: navigate' \
                          -H 'sec-fetch-dest: document' \
                          -H $'referer: https://'"${WILURL}"'/!'"${KIDID}"'/' \
                          -H 'accept-language: en-US,en;q=0.9' \
                          --compressed > "$TMPF3"

                        COURSE=$(sed $(($(grep -n "Kurssi<" "$TMPF3"|sed 's/:.*$//')+1))'q;d' "$TMPF3"|sed -e 's/^.*<td>//' -e 's/<\/td.*$//' -e 's/Ã¶/ö/g' -e 's/Ã€/ä/g' -e 's/Ã¥/å/g'|sed -e 's/Ã/Ö/g')

                        ##IF THERE ARE NO TESTS OR HOMEWORK, THEN THESE VARIABLES ARE DEFINED
                        ISTEST=$(grep "lle ei ole merkitty tulevia kokeita" "$TMPF3")
                        ISHW=$(grep "lle ei ole merkitty kotiteht" "$TMPF3")

                        ##IF THE VARIABLE IS NOT DEFINED, THERE ARE UPCOMING TESTS
                        if [ -z "$ISTEST" ]
                        then
                                TESTSSTR=$(grep -n "Tulevat kokeet" "$TMPF3"|sed 's/:.*$//')
                                tail -n $(($(wc -l "$TMPF3"|sed 's/ .*$//')-$TESTSSTR)) "$TMPF3" > "$TMPF4"

                                ##THE PAST TESTS ARE NOT DEFINED, IF NO TESTS HAS YET BEEN COMPLETED
                                ENDFIND=$(grep "Menneet kokeet" "$TMPF4")
                                if [ -z "$ENDFIND" ]
                                then
                                        TESTSER=$(($(grep -n "<h3.*Kotiteht" "$TMPF4"|sed 's/:.*$//')-1))
                                else
                                        TESTSER=$(($(grep -n "Menneet kokeet" "$TMPF4"|sed 's/:.*$//')-1))
                                fi
                                head -n "$TESTSER" "$TMPF4" > "$TMPF2"

                                ##BECAUSE SHOWING TESTS HELD TODAY IS USELESS
                                mapfile -t TESTSD < <(grep -v "$(date +%d.%m.%Y)" < <(grep "<td.*\">" "$TMPF2"|sed -e 's/^.*">//' -e 's/<\/.*$//'))
                                if [ "${#TESTSD[@]}" -gt 0 ]
                                then
                                        mapfile -t TESTS < <(grep "<td>" "$TMPF2"|sed -e 's/^.*<td>[0-9]\{1,2\}:.*$//' -e 's/^.*<td><\/td>.*$//' -e 's/^.*<td>//' -e 's/<\/td.*$//' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g'|perl -C -MHTML::Entities -pe 'decode_entities($_);')
                                        TESTCOUNTER=0
                                        ##IF THIS IS THE FIRST MATCH FOR THE CHILD
                                        if [ "$SCOUNTER" -eq 0 ]
                                        then
                                                echo " " >> "$HWFILE"
                                                echo "#########################" >> "$HWFILE"
                                                echo "# $KIDNAME" >> "$HWFILE"
                                                echo "#########################" >> "$HWFILE"
                                                ((SCOUNTER++))
                                        fi

                                        echo " " >> "$HWFILE"
                                        echo ".-----------------------" >> "$HWFILE"
                                        echo "| Kurssi: $COURSE" >> "$HWFILE"
                                        echo ".-----------------------" >> "$HWFILE"
                                        echo "| !! TULEVIA KOKEITA !!" >> "$HWFILE"
                                        ##PRINT TEST DATE AND TEST DESCRITPTION
                                        for testd in "${TESTSD[@]}"
                                        do
                                                echo "|      $testd" >> "$HWFILE"
                                                echo "| ${TESTS[$TESTCOUNTER]} ${TESTS[$TESTCOUNTER+1]} ${TESTS[$TESTCOUNTER+2]}" >> "$HWFILE"
                                                ((TESTCOUNTER+3))
                                        done
                                        echo "'-----------------------" >> "$HWFILE"
                                else
                                        ##IF THERE WERE ONLY TESTS MARKED FOR THE CURRENT DATE, THEN WE NEED TO DEFINE THE VARIABLE
                                        ISTEST="DEFINED"
                                fi
                        fi

                        ##IF THE VARIABLE IS NOT DEFINED, THERE IS HOMEWORK
                        if [ -z "$ISHW" ]
                        then
                                HCOUNTER=0
                                HWSROW=$(grep -n "<h3.*Kotiteht" "$TMPF3"|sed 's/:.*$//')
                                tail -n $(($(wc -l "$TMPF3"|sed 's/ .*$//')-$HWSROW)) "$TMPF3" > "$TMPF4"
                                HWEROW=$(($(grep -n "<h3.*Tuntip.*kirja" "$TMPF4"|sed 's/:.*$//')-1))
                                head -n "$HWEROW" "$TMPF4" > "$TMPF3"
                                mapfile -t HWD < <(grep "<td.*\">" "$TMPF3"|sed -e 's/^.*">//' -e 's/<\/.*$//')
                                mapfile -t HW < <(grep "<td>" "$TMPF3"|sed -e 's/^.*<td>/Läksy: /' -e 's/<\/td.*$//' -e 's/Ã€/ä/g' -e 's/Ã¶/ö/g' -e 's/Ã©/é/g' -e 's/Ã¥/å/g' -e 's/â\x80\x8b//g' -e 's/â/-/g' -e 's/Ã\x84/Ä/g' -e 's/Ã/Ö/g' -e 's/\x80//g' -e 's/\x93//g' -e 's/Â//g' -e 's/¯//g'|perl -C -MHTML::Entities -pe 'decode_entities($_);')
                                for date in "${HWD[@]}"
                                do
                                        ##IF THE DATE IS TODAY, AS WE ONLY LOOK FOR THE HOMEWORK FOR THE CURRENT DATE
                                        if [ "$(date +%d.%m.%Y)" == "$date" ]
                                        then
                                                ##IF NO HOMEWORK ROWS HAVE BEEN HANDLED YET
                                                if [ "$HCOUNTER" -eq 0 ]
                                                then
                                                        ##IF THERE WERE NO TESTS FOR THE SUBJECT
                                                        if [ ! -z "$ISTEST" ]
                                                        then
                                                                ##IF THIS IS THE FIRST MATCH FOR THE KID
                                                                if [ "$SCOUNTER" -eq 0 ]
                                                                then
                                                                        echo " " >> "$HWFILE"
                                                                        echo "#########################" >> "$HWFILE"
                                                                        echo "# $KIDNAME" >> "$HWFILE"
                                                                        echo "#########################" >> "$HWFILE"
                                                                        ((SCOUNTER++))
                                                                fi

                                                                echo " " >> "$HWFILE"
                                                                echo ".-----------------------" >> "$HWFILE"
                                                                echo "| Kurssi: $COURSE" >> "$HWFILE"
                                                                echo ".-----------------------" >> "$HWFILE"
                                                        fi
                                                        ##PRINT THE DATE FOR THE HOMEWORK ASSIGNMENT
                                                        echo "| Kotiläksyt $date" >> "$HWFILE"
                                                fi
                                                ##PRINT THE HOMEWORK
                                                echo "|  '----> ${HW[$HCOUNTER]}" >> "$HWFILE"
                                                ((HCOUNTER++))
                                                echo "'-----------------------" >> "$HWFILE"
                                        fi
                                done
                                rm "$TMPF3" "$TMPF4"
                        fi
                done
        done

        mail -s "$(date +%d.%m.%Y) KOTILÄKSYT!" -aFrom:"$SENDERNAM"\<"$SENDERADD"\> "$RECIPIENT" < "$HWFILE"
        echo "###   $(date +%d.%m.%Y) homework sent to $RECIPIENT...." >> "$WILOG"
        rm "$TMPF2" "$HWFILE"
}

##MAIN FUNCTION
startMain()
{
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

        ##CALL THE FUNCTIONS BASED ON GIVEN ARGUMENTS AND REMOVE DUPLICATES
        mapfile -t ARGLIST < <(sort "$WILARGS"|uniq)
        rm "$WILARGS"
        for arg in "${ARGLIST[@]}"
        do
                if [ "$arg" = "-m" ]
                then
                        getMessages
                elif [ "$arg" = "-no" ]
                then
                        getNotes
                elif [ "$arg" = "-h" ]
                then
                        getHomework
                else
                        echo "###   ERROR IN ARGUMENTS: $arg" >> "$WILOG"
                fi
        done

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
}

##HANDLING ARGUMENTS FOR THE SCRIPT
if [ $# -eq 0 ]
then
        echo "Arguments needed, none specified!"
        exit 1
elif [ $# -gt "$MAXARGS" ]
then
        echo "Too many arguments specified!"
        exit 1
else
        touch "$WILARGS"
        for arg in "$@"
        do
                ##CHECKING FOR VALID ARGUMENTS
                if [ "$arg" != "-m" ] && [ "$arg" != "-no" ] && [ "$arg" != "-h" ]
                then
                        echo "Unknown argument $arg!"
                        if [ -f "$WILARGS" ]
                        then
                                rm "$WILARGS"
                        fi
                        exit 1
                else
                        echo "$arg" >> "$WILARGS"
                fi
        done
        ##IF ALL IS GOOD START THE MAIN FUNCTIION
        startMain
fi
