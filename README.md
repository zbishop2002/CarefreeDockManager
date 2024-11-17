# Carefree Docker Container Manager
### Automatic Docker Container Backups/Updates - With Easy Discord Message Status Updates  

**CarefreeDockManager** helps you set up a seamless, hands-off solution for Docker container backups and updates. It brings together some fantastic FOSS tools:
- **[Watchtower](https://github.com/containrrr/watchtower)**: Automatically updates selected containers, has out-of-the-box Shoutrrr integraton for status updates 
- **[docker-backup](https://github.com/muesli/docker-backup)**: Creates .tar archive backup of all volumes, even bind mounts. The archives can be loaded as docker images if an update breaks
- **[Shoutrrr](https://github.com/containrrr/shoutrrr)**: Sends Discord notifications about your backup/update status for more passive administration

The cherry on top is the `container-backup.sh` custom script. Scheduling the script in your crontab enables pre-update backups with Shoutrrr integration 

### Shoutrrr Discord Notification Setup 
![ ](discord-status-update-demo.gif)
- Make a Discord server and choose the desired channel for the notifications. **Edit Channel -> Integrations -> Create Webhook -> Copy Webhook URL**

The webhook URL will come formatted as seen in #1. To use it with shoutrrr in your compose.yml, convert it to #2's format.
1. https://discord.com/api/webhooks/WEBHOOKID/TOKEN
2. discord://TOKEN@WEBHOOKID
### Watchtower Template Docker Compose
*Note:* `WATCHTOWER_SCHEDULE` *uses cron formatting*

```
services:
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Toronto
      - WATCHTOWER_CLEANUP=false
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_REVIVE_STOPPED=false
      - WATCHTOWER_SCHEDULE=0 30 8 * * 1
      - WATCHTOWER_NOTIFICATIONS=shoutrrr
      - WATCHTOWER_NOTIFICATION_URL=discord://TOKEN@WEBHOOKID
    command:
      - container1
      - container2
      - container3
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    network_mode: host
    restart: unless-stopped
```

### Golang Installation

| Ubuntu/Debian                                          | Arch Linux/Manjaro    | Fedora                       |
| ------------------------------------------------------ | --------------------- | ---------------------------- |
| `sudo apt update && \`<br>`sudo apt install -y golang` | `sudo pacman -Syu go` | `sudo dnf install -y golang` |

### Docker-Backup Installation

```
git clone https://github.com/muesli/docker-backup.git
```

```
cd docker-backup
``````

```
go build
```
### Shoutrrr Installation

```
go install github.com/containrrr/shoutrrr/shoutrrr@latest
```

### Automatic Backup Script Template with Shoutrrr Integration
- After modifying this template for your system, choose someplace to store it and make it a cron job. A day before the scheduled watchtower update is recommended
- Use the exact same webhook link from the Watchtower docker compose 
- The cron job must be on root's crontab or that of another admin account

```
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

```
*- Note: The --tar flag causes docker-backup to export a duplicate of the entire container's filesystem, bind volumes included.*
  *- This is the default because it is safer, though it can take much more space*
  *- Removing the --tar flag will make the backup a .json file, which takes up far less space but won't always be able to salvage container data*


### Restore Container from Tar Archive 

Load .tar as a docker image
```
docker load < path/to/archive.tar
```

Identify the IMAGE ID or REPOSITORY:TAG of the loaded image.
```
docker images
```
