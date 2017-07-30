#!/bin/bash

LOCKFILE=/tmp/syncInet.lock

if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "already running"
    exit
fi

#DECLARE VARIABLES
sync_dir="/analysis/InetsoftConfig"
remote_dir="appserver@samplehost.com:/analysis"
log=".syncInet.txt"
email="myemail@sample.com"

trap 'kill -HUP 0;rm -f ${LOCKFILE}' INT TERM EXIT
echo $$ > ${LOCKFILE}

#FUNCTION TO USE RYSNC TO BACKUP DIRECTORIES
function sync () {

if rsync -avz --exclude 'sree.*' --exclude '*.lock' $sync_dir $remote_dir  &>$log
then
echo "Backup succeeded" >> $log
#mail -s "Backup succeeded $sync_dir" $email < $log
else
mail -s "rysnc failed on $sync_dir" $email < $log
return 1
fi
}


#CHECK IF INOTIFY-TOOLS IS INSTALLED
type -P inotifywait &>/dev/null || { echo "inotifywait command not found."; exit 1; }

#INFINITE WHILE LOOP
while true
do

#START RSYNC AND ENSURE DIR ARE UPTO DATE
#sync  || exit 0

#START RSYNC AND TRIGGER BACKUP ON CHANGE
inotifywait -r -e modify,attrib,close_write,move,create,delete  --format '%T %:e %f' --timefmt '%c' $sync_dir  &>$log && sync

done
rm -f ${LOCKFILE}
