# WeMuRe: Weekly Music Releases

## Description

WeMuRe is a simple script that keep you up to date with the latest releases of you favorite music artists. So as to achieve this goal, it will consult the MusicBrainz API and send an email including information of the approaching releases.

![](result.jpg)

## Installation and configuration

### Configuration file

WeMuRe uses a configuration file located in **/etc/wemure.conf** with the sender and recipient addresses that will be used to send the mail, along with the MusicBrainz IDs of the artists that user likes, so that he is notified whenever they release new music.

WeMuRe uses MusicBrainz IDs instead of the name of the artist so as to avoid confussion in cases where several artists use the same name.

Example configuration file:
```
email end222@example.com # Recipient
from wemure@example.com # Sender
id bce172fc-51bb-43f7-9a25-b406a0a581d5 # ITZY
id de4feabc-cd21-4568-a09c-2086bfebe2f4 # LOONA
id 99689c05-4f6d-4bff-9b00-06731277fe42 # WJSN
id 05dffdbe-dc6e-4c8d-a075-50a09c4cb45c # Architects
id 074e3847-f67f-49f9-81f1-8c8cea147e8e # Bring me the Horizon
id a97f393a-13a7-4645-8bba-f10bd22d7228 # Dreamcatcher
id a436dd02-0549-4c91-b608-df451217fdeb # Parkway Drive
id 8da127cc-c432-418f-b356-ef36210d82ac # Twice
id eee862ac-0d4d-441c-94fe-9e2c681d7a48 # GFriend
id 24e58672-0956-4e3b-87a4-aaf3d52094aa # While She Sleeps
id 2eaf4267-4dd6-412a-9bb0-596afb90215b # REZZ
id 4f0cb3b7-6c06-4317-ae35-ddf3106a17ee # Red Velvet
```

### Periodic execution

WeMuRe does not execute periodically by itself. Instead, its execution has to be programmed using Cron.

Below, there is an example of a crontab entry that executes the program every Monday at 1AM, assuming that WeMuRe is installed in /usr/bin/wemure:
```
# min	hour	day	month	weekday	command
0	1	*	*	1	/usr/bin/wemure
```
