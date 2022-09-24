[BROKEN, WILL MAYBE FIX ONE DAY IF I HAVE TOO MUCH TIME ON MY HANDS]

# wilmaKekker
Check for new Wilma messages, homework and upcoming exams and forward them to your email.

Define temp file locations, logfile location (or /dev/null if you don't want logging), the base URL of your Wilma instance, your credentials and the email settings.

Then you just start running the script with needed parameters every time you want to check for new messages or homework and exams in Wilma.

If new messages, homework or upcoming exams are found, the script will send them to your email.

Works for accounts with multiple children too.

Just finished this so hasn't been tested that much yet. 

Not much error checking atm. maybe I'll add some later...

I take no responsibility of anything you decide to do with this.

## Call the script with one or more of the following arguments:
## -h --> get homework and upcoming exams and email them to the recipient
## -m --> get unread messages and email them to the recipient
## -no --> get the teacher's notes for the current date

</br>
</br>----</br>
</br>Update 180222: Added the functionality of getting teacher's notes for the current day, provided the teacher has filled them in. If you call this twice in the same day it will give you the results you got on the earlier run that day + possible new notes. So it's not keeping track of what it's already sent you. I've put this on Cron to be run once a day at 16:00. Usage: bash wilKek.sh -no.</br></br>
Also fixed a brain fart in the homework and tests -handling.</br>
</br>
</br>----</br>
</br>Update 070122: Updated the message content sanitation to remove wide character dash.</br>
</br>
</br>----</br>
</br>Update 051021: Recompiled to functions for easier debugging. Added the combined homework and upcoming exams polling. Changed the way of decoding HTML-entities. Now the script needs to be called with arguments!</br>
</br>
</br>----</br>
</br>Update 060921: Added the capability of handling new replies to messages and emailing them too. Fixed a bug when handling messages sent to you by the other parent.</br>
</br>
</br>----</br>
</br>Update 310821: Fixed a lot of bugs, added a parser to parse all links to text and also a decrypter to decrypt the Cloudflare Email Address Obfuscation and include the email addresses in the content as text.</br>
</br>
----</br>
</br>
Todo: </br>
    - Also email all notifications and notes from the teachers.</br>
    - Remove all weird characters from the content smarter, at the moment this is just a bundle of randomness. </br>
    - Something something, dumpster fire.</br>
</br>
#####################################</br>
-Wilmaviestit sähköpostiin
