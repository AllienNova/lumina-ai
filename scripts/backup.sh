#!/bin/bash

# Automated backup script for Lumina AI project
# This script creates a ZIP backup of the repository and pushes to remote repositories
# It should be run daily via cron job

# Configuration
REPO_DIR="/home/ubuntu/lumina-ai"
BACKUP_DIR="/home/ubuntu/backups/lumina-ai"
DATE=$(date +"%Y-%m-%d")
BACKUP_FILE="$BACKUP_DIR/lumina-ai-$DATE.zip"
LOG_FILE="$BACKUP_DIR/backup-log.txt"
GITHUB_REMOTE="origin"
GITLAB_REMOTE="backup"
RETENTION_DAYS=7

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Log function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> $LOG_FILE
    echo "$1"
}

log "Starting Lumina AI backup process"

# Navigate to repository
cd $REPO_DIR || {
    log "ERROR: Could not navigate to repository directory $REPO_DIR"
    exit 1
}

# Create ZIP backup
log "Creating ZIP backup of repository"
zip -r $BACKUP_FILE . -x "*.git/*" "node_modules/*" "target/*" "build/*" "dist/*" "*.class" "*.jar" "*.war" "*.zip" "*.tar.gz" "*.rar" || {
    log "ERROR: Failed to create ZIP backup"
    exit 1
}
log "ZIP backup created at $BACKUP_FILE"

# Git operations - commit any changes
log "Checking for uncommitted changes"
if [[ $(git status --porcelain) ]]; then
    log "Uncommitted changes found, creating automatic backup commit"
    git add .
    git commit -m "Automatic backup commit - $DATE" || {
        log "WARNING: Failed to create automatic commit"
    }
    log "Automatic commit created"
else
    log "No uncommitted changes found"
fi

# Push to GitHub if remote exists
if git remote | grep -q "$GITHUB_REMOTE"; then
    log "Pushing to GitHub remote ($GITHUB_REMOTE)"
    git push $GITHUB_REMOTE --all || {
        log "WARNING: Failed to push to GitHub remote"
    }
    log "Successfully pushed to GitHub remote"
else
    log "GitHub remote not configured, skipping push"
fi

# Push to GitLab if remote exists
if git remote | grep -q "$GITLAB_REMOTE"; then
    log "Pushing to GitLab remote ($GITLAB_REMOTE)"
    git push $GITLAB_REMOTE --all || {
        log "WARNING: Failed to push to GitLab remote"
    }
    log "Successfully pushed to GitLab remote"
else
    log "GitLab remote not configured, skipping push"
fi

# Clean up old backups
log "Cleaning up backups older than $RETENTION_DAYS days"
find $BACKUP_DIR -name "lumina-ai-*.zip" -type f -mtime +$RETENTION_DAYS -delete || {
    log "WARNING: Failed to clean up old backups"
}
log "Backup cleanup completed"

# Verify backup
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Backup verification: File exists with size $SIZE"
else
    log "ERROR: Backup verification failed - file does not exist"
    exit 1
fi

log "Backup process completed successfully"
