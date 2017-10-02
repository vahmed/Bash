#!/bin/bash

HOST=$(hostname)
OG_AUTH_KEY="YOUR_OG_API_KEY"
API_URL="https://api.opsgenie.com/v2/alerts" # OpsGenie
LOG=syswatch.log
CONF=syswatch.conf

# Make sure log exists if not create & also make sure config file exists before continuing further
[[ ! -f ${LOG} ]] && touch ${LOG}
[[ ! -f ${CONF} ]] && echo "`date '+%Y/%m/%d %H:%M:%S'` Missing ${CONF} file" | tee -a ${LOG} && exit 1;

# check dependencies:
command -v inotifywait >/dev/null 2>&1 || { echo >&2 "inotifywait not available, please install inotify-tools"; exit 1; }

# create an array then read config file to populate
declare -a array
let i=0
while IFS=$'\n' read -r config; do
[[ "${config}" =~ ^#.*$ ]] && continue
    array[i]="${config}"
    ((++i))
done < dirwatch.conf

# Log the # of directories/teams found
echo "`date '+%Y/%m/%d %H:%M:%S'` Found ${#array[@]} dir to watch" | tee -a ${LOG}

[[ -f .dirs_to_watch ]] && rm -f .dirs_to_watch

# extract directories to watch and push to .dirs_to_watch
let i=0
while (( ${#array[@]} > i )); do
    [[ -z $(echo ${array[i]} | cut -d'=' -f1) ]] || [[ -z $(echo ${array[i]} | cut -d'=' -f2) ]] && echo "`date '+%Y/%m/%d %H:%M:%S'` Invalid config file format" | tee -a ${LOG}
    echo ${array[i]} | cut -d'=' -f1 >> .dirs_to_watch
    ((++i))
done

# check if ._dirs_to_watch exist or exit because inotifywait needs this file with list of files/directories to monitor
[[ ! -f .dirs_to_watch ]] && echo "`date '+%Y/%m/%d %H:%M:%S'` Missing directories to watch in .dirs_to_watch" | tee -a ${LOG} && exit 1;

/usr/bin/inotifywait -q --exclude "\.(swx|swp|bak|bkp)" --exclude "(passwd.*|group.*|shadow.*)" -m -r -e create,close_write,delete --format "%e %w %f" --fromfile .dirs_to_watch | \
while read e d f; do
    echo "`date '+%Y/%m/%d %H:%M:%S'` Event: '${e/CLOSE_WRITE,CLOSE/MODIFY}' Dir: '$d' File: '$f'" | tee -a ${LOG}
    let i=0
    while (( ${#array[@]} > i )); do
    if [[ ${d} =~ $(echo ${array[i]} | cut -d'=' -f1) ]]; then
        NOTIFY=$(echo ${array[i]} | cut -d'=' -f2)
        fi
    ((++i))
    done
    # Set priority on the event by time of day
    H=$(TZ=":US/Eastern" date +%H)
   if (( 8 <= 10#$H && 10#$H < 18 )); then 
        PRI="P2"
    else
        PRI="P3"
    fi
    # OpsGenie Payload
    echo -n '{
            "message":"File Change Alert",
            "alias":"'${HOST%.*.*.*.*}'-'${f}'",
            "description":"Event: '${e/CLOSE_WRITE,CLOSE/MODIFY}'\nDir: '$d'\nFile: '$f'",
            "teams":[{"name":"'${NOTIFY}'"}],
            "details":{"Hostname":"'${HOST}'"},
            "priority":"'${PRI}'"
}' > /tmp/post.txt
    wget -O- -q ${API_URL} \
        --header="Content-Type: application/json" \
        --header="Authorization: GenieKey ${OG_AUTH_KEY}" \
        --post-file=/tmp/post.txt && echo "`date '+%Y/%m/%d %H:%M:%S'` Event Triggered to OpsGenie" | tee -a ${LOG} || echo "`date '+%Y/%m/%d %H:%M:%S'` Event Trigger Failed to OpsGenie" | tee -a ${LOG}
done
