#!/bin/bash

# Automated verification script for Lumina AI repository
# This script checks the integrity of the repository and backups
# It should be run daily via cron job

# Configuration
REPO_DIR="/home/ubuntu/lumina-ai"
BACKUP_DIR="/home/ubuntu/backups/lumina-ai"
LOG_FILE="$BACKUP_DIR/verification-log.txt"
LATEST_BACKUP=$(find $BACKUP_DIR -name "lumina-ai-*.zip" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)

# Ensure log directory exists
mkdir -p $BACKUP_DIR

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> $LOG_FILE
    echo "$1"
}

log "Starting Lumina AI repository verification process"

# Check repository existence
if [ ! -d "$REPO_DIR" ]; then
    log "ERROR: Repository directory $REPO_DIR does not exist"
    exit 1
fi

# Check if it's a git repository
cd $REPO_DIR || {
    log "ERROR: Could not navigate to repository directory $REPO_DIR"
    exit 1
}

if [ ! -d ".git" ]; then
    log "ERROR: $REPO_DIR is not a git repository"
    exit 1
fi

# Check git status
log "Checking git status"
git status >> $LOG_FILE 2>&1 || {
    log "ERROR: Git repository is in an invalid state"
    exit 1
}

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
    log "WARNING: Uncommitted changes found in repository"
else
    log "Repository is clean, no uncommitted changes"
fi

# Verify latest backup
if [ -z "$LATEST_BACKUP" ]; then
    log "ERROR: No backup files found in $BACKUP_DIR"
else
    log "Latest backup: $LATEST_BACKUP"
    
    # Check backup file integrity
    if unzip -t "$LATEST_BACKUP" > /dev/null; then
        log "Backup file integrity check: PASSED"
        
        # Create temporary directory for extraction
        TEMP_DIR=$(mktemp -d)
        log "Extracting backup to temporary directory for verification: $TEMP_DIR"
        
        # Extract backup
        unzip -q "$LATEST_BACKUP" -d "$TEMP_DIR" || {
            log "ERROR: Failed to extract backup for verification"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Compare file count
        REPO_FILES=$(find $REPO_DIR -type f -not -path "*/\.git/*" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/build/*" -not -path "*/dist/*" | wc -l)
        BACKUP_FILES=$(find $TEMP_DIR -type f | wc -l)
        
        log "Repository file count: $REPO_FILES"
        log "Backup file count: $BACKUP_FILES"
        
        if [ $BACKUP_FILES -lt $((REPO_FILES * 9 / 10)) ]; then
            log "WARNING: Backup contains significantly fewer files than repository"
        else
            log "Backup file count verification: PASSED"
        fi
        
        # Clean up
        rm -rf "$TEMP_DIR"
    else
        log "ERROR: Backup file is corrupted"
    fi
fi

# Check backup script
if [ ! -f "$REPO_DIR/scripts/backup.sh" ]; then
    log "ERROR: Backup script not found"
else
    if [ ! -x "$REPO_DIR/scripts/backup.sh" ]; then
        log "ERROR: Backup script is not executable"
    else
        log "Backup script check: PASSED"
    fi
fi

# Check cron job for backup script
CRON_CHECK=$(crontab -l 2>/dev/null | grep -c "backup.sh")
if [ $CRON_CHECK -eq 0 ]; then
    log "WARNING: No cron job found for backup script"
else
    log "Cron job check: PASSED"
fi

log "Repository verification completed"

# Summary
echo "======================" >> $LOG_FILE
echo "VERIFICATION SUMMARY" >> $LOG_FILE
echo "======================" >> $LOG_FILE
grep "ERROR\|WARNING" $LOG_FILE | tail -n 10 >> $LOG_FILE
echo "======================" >> $LOG_FILE

# Exit with error if any errors were found
if grep -q "ERROR" $LOG_FILE; then
    log "Verification completed with ERRORS"
    exit 1
else
    log "Verification completed successfully"
    exit 0
fi
