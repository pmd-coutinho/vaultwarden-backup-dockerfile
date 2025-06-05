#!/bin/bash
# Script to backup Vaultwarden data to Google Drive

# Configuration
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="vaultwarden_backup_${TIMESTAMP}.tar.gz"
GDRIVE_BACKUP_DIR="vaultwarden-backups"
RETENTION_DAYS=30  # Keep backups for 30 days
TEMP_DIR="/backup/temp"

echo "Starting Vaultwarden backup at $(date)"

# Ensure temp directory exists
mkdir -p "$TEMP_DIR"

# Use docker to create a backup of the volume
echo "Creating backup of Vaultwarden data..."
docker run --rm -v vaultwarden-data:/data -v "$TEMP_DIR:/backup" alpine sh -c "cd /data && tar czf /backup/$BACKUP_FILE ."

echo "Backup created: $TEMP_DIR/$BACKUP_FILE"

# Check if rclone is configured
if [ ! -f /root/.config/rclone/rclone.conf ]; then
    echo "Error: rclone is not configured. Please mount the rclone config file."
    exit 1
fi

# Upload to Google Drive
echo "Uploading backup to Google Drive..."
ls $TEMP_DIR
rclone copy "$TEMP_DIR/$BACKUP_FILE" gdrive:"$GDRIVE_BACKUP_DIR"

# Check if upload was successful
if [ $? -eq 0 ]; then
    echo "Backup successfully uploaded to Google Drive at $(date)"
else
    echo "Error uploading backup to Google Drive at $(date)"
    exit 1
fi

# Clean up the temporary backup
rm -f "$TEMP_DIR/$BACKUP_FILE"

# Clean up old backups on Google Drive
echo "Cleaning up old backups on Google Drive..."
OLD_BACKUPS=$(rclone lsf gdrive:"$GDRIVE_BACKUP_DIR" --min-age ${RETENTION_DAYS}d)
if [ ! -z "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        rclone delete gdrive:"$GDRIVE_BACKUP_DIR/$old_backup"
        echo "Deleted old backup: $old_backup"
    done
fi

echo "Backup process completed at $(date)"
