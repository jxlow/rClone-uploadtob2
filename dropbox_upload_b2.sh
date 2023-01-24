#!/usr/bin/env bash

#function for pushover notifications
#token in .env, do source .env first

function pushover() {
    timestamp1=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    curl -s \
    --form-string "token=$PUSHOVER_TOKEN" \
    --form-string "user=$PUSHOVER_USER" \
    --form-string "message=Dropbox upload to B2 Xaeta failed/$1 - ${timestamp1}." \
    --form-string "title=Script Failure" \
    --form-string "device=$pushover_device" \
    https://api.pushover.net/1/messages.json
}

cd "$path_local"

countfile=$(ls -l . | egrep -c '^-')
timestamp=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
echo "${timestamp} - There are $countfile files in the dropbox folder"

if [ "$countfile" -ge 5 ]; then
    timestamp2=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    echo ${timestamp2} - Continuing script..
else
    timestamp2=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    echo ${timestamp2} - Exiting script due to less than 5 files.
    exit 1
fi

# rclone copy --------------------------------------------------------------
timestamp_copy=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
echo ${timestamp_copy} - Copying files from Dropbox to B2 now..
rclone copy "$path_local" "$path_b2" --exclude-from "$path_exclude"
exit_code_copy=$?

if [ "$exit_code_copy" -eq 0 ]; then
    timestamp_a=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    echo ${timestamp_a} - Copy successful.
else
    echo Copy failed.
    # Pushover notification
    comment='copy failure'
    pushover "$comment"
    exit 1
fi

# rclone check --------------------------------------------------------------
timestamp_check=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
echo ${timestamp_check} - Checking..
rclone check "$path_local" "$path_b2" --size-only --one-way --exclude-from "$path_exclude"
exit_code_check=$?

if [ "$exit_code_check" -eq 0 ]; then
    timestamp_b=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    echo ${timestamp_b} - Check successful.
else
    echo Check failed.
    # Pushover notification
    comment='Check failure'
    pushover "$comment"
    exit 1
fi

# rclone delete --------------------------------------------------------------
timestamp_del=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
echo "${timestamp_del} - Deleting files in Dropbox.."
rclone delete "$path_local" --exclude-from "$path_exclude"
exit_code_delete=$?

if [ "$exit_code_delete" -eq 0 ]; then
    timestamp_c=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
    echo ${timestamp_c} - Delete successful.
else
    echo Delete failed.
    # Pushover notification
    comment='Delete failure'
    pushover "$comment"
    exit 1
fi

cd /
timestamp4=$(TZ="Asia/Singapore" date '+%d/%m/%Y %H:%M:%S')
echo ${timestamp4} - Dropbox upload completed without any failures. 