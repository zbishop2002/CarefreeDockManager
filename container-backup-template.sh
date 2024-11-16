#!/bin/bash

# Define a function to send the backup status to Discord
send_notification() {
    local message=$1
    /home/username/go/bin/shoutrrr send discord://TOKEN@WEBHOOKID "$message"
}

# Trap function to handle script interruption
trap 'send_notification "Docker Container Backup Incomplete. Attempt Manually"' INT

# Perform docker backups
/home/username/docker-backup/docker-backup backup --tar container1 && \
/home/username/docker-backup/docker-backup backup --tar container2

# Send success notification if no interruption
if [ $? -eq 0 ]; then
    send_notification "Docker Container Backup Complete"
fi

