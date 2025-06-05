# Vaultwarden Backup to Google Drive for Coolify

This repository contains the necessary files to set up automated backups of your Vaultwarden data to Google Drive using Coolify.

## Setup Instructions

### 1. Set up Google Drive API Credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Enable the Google Drive API
4. Create OAuth 2.0 credentials (OAuth client ID)
   - Application type: Desktop application
   - Name: Vaultwarden Backup
5. Download the credentials JSON file

### 2. Configure rclone

You need to configure rclone with your Google Drive account. Run the following commands on your local machine:

```bash
# Install rclone if you don't have it
curl https://rclone.org/install.sh | sudo bash

# Configure rclone
rclone config

# Follow the prompts:
# 1. Choose 'n' for new remote
# 2. Name it 'gdrive'
# 3. Select 'drive' for Google Drive
# 4. Leave client_id and client_secret blank unless you have your own
# 5. Select 'scope' as 1 (full access)
# 6. Leave root_folder_id blank
# 7. Leave service_account_file blank
# 8. Choose 'y' to edit advanced config (if needed)
# 9. Choose 'n' for auto config
# 10. Follow the URL provided to authorize rclone
# 11. Choose 'y' to configure this as a team drive if applicable
# 12. Choose 'y' to confirm your settings
```

After configuration, copy the rclone config file:
```bash
cp ~/.config/rclone/rclone.conf /path/to/save/rclone.conf
```

### 3. Set up in Coolify

1. In Coolify, go to "Services" and click "New Service"
2. Select "Docker" as the service type
3. Choose "Build from Dockerfile" and upload or point to this repository
4. Configure the service with the following settings:
   - Name: vaultwarden-backup
   - Build Command: Leave empty
   - Start Command: Leave empty
   - Docker Network: Same network as your Vaultwarden container
   - Environment Variables: None required
   - Volumes:
     - Mount `/var/run/docker.sock:/var/run/docker.sock` (to allow Docker commands)
     - Mount `/path/to/saved/rclone.conf:/root/.config/rclone/rclone.conf` (your rclone config)

5. Set up a scheduled task in Coolify:
   - Go to your vaultwarden-backup service
   - Click on "Scheduled Tasks"
   - Add a new task with cron expression: `0 2 * * *` (runs daily at 2:00 AM)
   - Command: Leave empty (it will use the entrypoint)

### 4. Test the Backup

To test if the backup is working correctly:

1. In Coolify, go to your vaultwarden-backup service
2. Click "Execute" on the scheduled task
3. Check the logs to see if the backup was successful

## Troubleshooting

- If you see "Error: rclone is not configured", check that your rclone.conf file is correctly mounted
- If Docker commands fail, ensure that `/var/run/docker.sock` is correctly mounted
- Check that the vaultwarden-data volume is accessible from the backup container
