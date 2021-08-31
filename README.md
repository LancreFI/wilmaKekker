# wilmaKekker
Check for new Wilma messages and forward them to your email.

Define temp file locations, logfile location (or /dev/null if you don't want logging), the base URL of your Wilma instance, your credentials and the email settings.

Then you just start running the script every time you want to check for new messages in Wilma.

If new messages are found, the script will send them to your email.

Works for accounts with multiple children too.

Just finished this so hasn't been tested that much yet. Also most likely need to add some HTML-entities to the list of entities to decode.

Not much error checking atm. maybe I'll add some later...

I take no responsibility of anything you decide to do with this.
</br>
</br>----</br>
</br>Update 310821: Fixed a lot of bugs, added a parser to parse all links to text and also a decrypter to decrypt the Cloudflare Email Address Obfuscation and include the email addresses in the content as text.</br>
</br>
----</br>
</br>
Todo: 
    - At some point also identify message replies as new messages and email them.</br>
    - Also email all notifications and notes from the teachers.</br>
    - Something something, dumpster fire.</br>
</br>
#####################################</br>
-Wilmaviestit sähköpostiin
