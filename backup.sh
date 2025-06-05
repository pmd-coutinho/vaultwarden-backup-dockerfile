#!/bin/bash
# Script to backup Vaultwarden data to Google Drive

# Configuration
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="vaultwarden_backup_${TIMESTAMP}.tar.gz"
GDRIVE_BACKUP_DIR="vaultwarden-backups"
RETENTION_DAYS=30  # Keep backups for 30 days
BACKUP_DIR="/backup"
TEMP_DIR="$BACKUP_DIR/temp"

echo "Starting Vaultwarden backup at $(date)"

# Ensure backup directories exist
mkdir -p "$TEMP_DIR"
echo "Created temp directory: $TEMP_DIR"
ls -la "$BACKUP_DIR"

# Use docker to create a backup of the volume
echo "Creating backup of Vaultwarden data..."
echo "Checking if vaultwarden-data volume exists..."
docker volume ls | grep vaultwarden-data

# Create the backup directly in the BACKUP_DIR to avoid path issues
docker run --rm \
  -v vaultwarden-data:/vaultwarden-data:ro \
  -v "$BACKUP_DIR:/backup" \
  alpine:latest \
  sh -c "cd /vaultwarden-data && tar czf /backup/$BACKUP_FILE ."

# Verify backup was created
echo "Checking backup file:"
ls -la "$BACKUP_DIR"

# Check if rclone is configured
if [ ! -f /root/.config/rclone/rclone.conf ]; then
    echo "Error: rclone is not configured. Please mount the rclone config file at /root/.config/rclone/rclone.conf"
    exit 1
fi

# List rclone remotes to verify configuration
echo "Available rclone remotes:"
rclone listremotes

# Create the destination directory in Google Drive if it doesn't exist
echo "Creating destination directory in Google Drive if it doesn't exist..."
rclone mkdir gdrive:"$GDRIVE_BACKUP_DIR"

# Upload to Google Drive
echo "Uploading backup to Google Drive..."
rclone copy "$BACKUP_DIR/$BACKUP_FILE" gdrive:"$GDRIVE_BACKUP_DIR" -v

# Check if upload was successful
if [ $? -eq 0 ]; then
    echo "Backup successfully uploaded to Google Drive at $(date)"
else
    echo "Error uploading backup to Google Drive at $(date)"
    exit 1
fi

# Clean up the temporary backup
echo "Cleaning up local backup file..."
rm -f "$BACKUP_DIR/$BACKUP_FILE"

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
