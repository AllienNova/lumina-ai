#!/bin/bash

# Automated backup initialization script for Lumina AI project
# This script sets up the automated backup system including cron jobs

# Configuration
REPO_DIR="/home/ubuntu/lumina-ai"
BACKUP_DIR="/home/ubuntu/backups/lumina-ai"
SCRIPTS_DIR="$REPO_DIR/scripts"
LOG_FILE="$BACKUP_DIR/backup-init.log"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $LOG_FILE
}

log "Starting Lumina AI backup system initialization"

# Check if scripts exist and are executable
if [ ! -f "$SCRIPTS_DIR/backup.sh" ]; then
    log "ERROR: Backup script not found at $SCRIPTS_DIR/backup.sh"
    exit 1
fi

if [ ! -f "$SCRIPTS_DIR/verify_repo.sh" ]; then
    log "ERROR: Verification script not found at $SCRIPTS_DIR/verify_repo.sh"
    exit 1
fi

# Make scripts executable if they aren't already
chmod +x $SCRIPTS_DIR/backup.sh
chmod +x $SCRIPTS_DIR/verify_repo.sh
log "Scripts are now executable"

# Create initial backup
log "Creating initial backup"
$SCRIPTS_DIR/backup.sh
if [ $? -ne 0 ]; then
    log "WARNING: Initial backup failed"
else
    log "Initial backup completed successfully"
fi

# Run initial verification
log "Running initial repository verification"
$SCRIPTS_DIR/verify_repo.sh
if [ $? -ne 0 ]; then
    log "WARNING: Initial verification failed"
else
    log "Initial verification completed successfully"
fi

# Set up cron jobs
log "Setting up cron jobs"
TEMP_CRON=$(mktemp)
crontab -l > $TEMP_CRON 2>/dev/null || echo "" > $TEMP_CRON

# Check if cron jobs already exist
if grep -q "backup.sh" $TEMP_CRON; then
    log "Backup cron job already exists"
else
    echo "# Lumina AI automated backup - added $(date)" >> $TEMP_CRON
    echo "0 1 * * * $SCRIPTS_DIR/backup.sh >> $BACKUP_DIR/cron-backup.log 2>&1" >> $TEMP_CRON
    log "Added backup cron job"
fi

if grep -q "verify_repo.sh" $TEMP_CRON; then
    log "Verification cron job already exists"
else
    echo "# Lumina AI repository verification - added $(date)" >> $TEMP_CRON
    echo "0 2 * * * $SCRIPTS_DIR/verify_repo.sh >> $BACKUP_DIR/cron-verify.log 2>&1" >> $TEMP_CRON
    echo "0 8,12,16,20 * * * $SCRIPTS_DIR/verify_repo.sh >> $BACKUP_DIR/cron-verify-quick.log 2>&1" >> $TEMP_CRON
    log "Added verification cron jobs"
fi

# Install new crontab
crontab $TEMP_CRON
if [ $? -ne 0 ]; then
    log "ERROR: Failed to install cron jobs"
    rm $TEMP_CRON
    exit 1
else
    log "Cron jobs installed successfully"
fi

# Clean up
rm $TEMP_CRON

# Create a README for the backup system
cat > $BACKUP_DIR/README.md << EOF
# Lumina AI Backup System

This directory contains automated backups of the Lumina AI repository.

## Backup Files

- Daily ZIP backups named \`lumina-ai-YYYY-MM-DD.zip\`
- Retention policy: 7 days

## Log Files

- \`backup-log.txt\`: Main backup log
- \`verification-log.txt\`: Repository verification log
- \`cron-backup.log\`: Output from cron backup jobs
- \`cron-verify.log\`: Output from cron verification jobs
- \`cron-verify-quick.log\`: Output from quick verification jobs

## Manual Operations

To manually trigger a backup:
\`\`\`
/home/ubuntu/lumina-ai/scripts/backup.sh
\`\`\`

To manually verify the repository:
\`\`\`
/home/ubuntu/lumina-ai/scripts/verify_repo.sh
\`\`\`

## Cron Schedule

- Full backup: Daily at 1:00 AM
- Full verification: Daily at 2:00 AM
- Quick verification: Every 4 hours during working hours (8 AM, 12 PM, 4 PM, 8 PM)

Last setup: $(date)
EOF

log "Created backup system README"

# Final status
log "Backup system initialization completed successfully"
log "Backup directory: $BACKUP_DIR"
log "Backup script: $SCRIPTS_DIR/backup.sh"
log "Verification script: $SCRIPTS_DIR/verify_repo.sh"
log "Cron jobs installed for automated execution"

echo ""
echo "===== Lumina AI Backup System ====="
echo "Initialization completed successfully"
echo "Backup directory: $BACKUP_DIR"
echo "See $LOG_FILE for details"
echo "=================================="
