#!/bin/bash

# Daily Progress Log Generator for Lumina AI
# This script generates a daily progress log with code snapshots

# Configuration
REPO_DIR="/home/ubuntu/lumina-ai"
LOGS_DIR="$REPO_DIR/logs/daily"
DATE=$(date +"%Y-%m-%d")
LOG_FILE="$LOGS_DIR/progress-$DATE.md"
DEVELOPER_NAME="Lumina AI Developer"
TEMPLATE_FILE="$REPO_DIR/docs/templates/daily_progress_log_template.md"

# Ensure logs directory exists
mkdir -p $LOGS_DIR

# Function to get code metrics
get_code_metrics() {
    cd $REPO_DIR
    
    # Get lines added and removed
    STATS=$(git diff --stat HEAD~1 HEAD 2>/dev/null || echo "0 files changed, 0 insertions(+), 0 deletions(-)")
    FILES_CHANGED=$(echo $STATS | grep -o "[0-9]* file" | cut -d' ' -f1 || echo "0")
    LINES_ADDED=$(echo $STATS | grep -o "[0-9]* insertion" | cut -d' ' -f1 || echo "0")
    LINES_REMOVED=$(echo $STATS | grep -o "[0-9]* deletion" | cut -d' ' -f1 || echo "0")
    
    # Count unit tests added (simple approximation)
    TESTS_ADDED=$(git diff --name-only HEAD~1 HEAD | grep -c "test\|Test\|TEST" || echo "0")
    
    # Placeholder for test coverage (would need a proper tool for this)
    TEST_COVERAGE="N/A"
    
    echo "- Lines of code added: $LINES_ADDED"
    echo "- Lines of code removed: $LINES_REMOVED"
    echo "- Files modified: $FILES_CHANGED"
    echo "- Unit tests added: $TESTS_ADDED"
    echo "- Test coverage: $TEST_COVERAGE"
}

# Function to get code snapshots
get_code_snapshots() {
    cd $REPO_DIR
    
    # Get recent commits
    COMMITS=$(git log --pretty=format:"%h" -n 3 2>/dev/null || echo "")
    
    if [ -z "$COMMITS" ]; then
        echo "No commits found."
        return
    fi
    
    SNAPSHOT_COUNT=1
    
    for COMMIT in $COMMITS; do
        # Get the most significant file changed in this commit
        FILE=$(git show --name-only --pretty="format:" $COMMIT | grep -v "^$" | head -1)
        
        if [ -z "$FILE" ]; then
            continue
        fi
        
        # Get commit message
        COMMIT_MSG=$(git log --format=%s -n 1 $COMMIT)
        
        # Get a snippet of the file (up to 15 lines)
        if [ -f "$REPO_DIR/$FILE" ]; then
            SNIPPET=$(head -15 "$REPO_DIR/$FILE" | sed 's/^/    /')
            
            echo "#### Snapshot $SNAPSHOT_COUNT: ${FILE##*/}"
            echo '```'
            echo "$SNIPPET"
            echo '```'
            echo "**File Path:** $FILE"
            echo "**Commit ID:** $COMMIT"
            echo "**Description:** $COMMIT_MSG"
            echo ""
            
            SNAPSHOT_COUNT=$((SNAPSHOT_COUNT + 1))
            
            # Limit to 2 snapshots
            if [ $SNAPSHOT_COUNT -gt 2 ]; then
                break
            fi
        fi
    done
}

# Function to get backup verification status
get_backup_verification() {
    BACKUP_FILE="/home/ubuntu/backups/lumina-ai/lumina-ai-$DATE.zip"
    
    if [ -f "$BACKUP_FILE" ]; then
        BACKUP_STATUS="✅"
        BACKUP_FILENAME="lumina-ai-$DATE.zip"
    else
        BACKUP_STATUS="❌"
        BACKUP_FILENAME="Not found"
    fi
    
    # Check if verification script exists and has been run today
    VERIFY_LOG="/home/ubuntu/backups/lumina-ai/verification-log.txt"
    if [ -f "$VERIFY_LOG" ] && grep -q "$(date +"%Y-%m-%d")" "$VERIFY_LOG"; then
        VERIFY_STATUS="✅"
    else
        VERIFY_STATUS="❌"
    fi
    
    # Check remote repositories (simplified)
    REMOTES=$(git remote 2>/dev/null)
    if [ -z "$REMOTES" ]; then
        REMOTE_STATUS="None configured"
    else
        REMOTE_STATUS="$REMOTES"
    fi
    
    echo "- [$BACKUP_STATUS] Daily backup completed"
    echo "- [$VERIFY_STATUS] Repository verification"
    echo "- Backup ZIP file: $BACKUP_FILENAME"
    echo "- Remote repositories: $REMOTE_STATUS"
}

# Generate the log file
generate_log() {
    # Copy template
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$LOG_FILE"
    else
        # Create basic template if template file doesn't exist
        cat > "$LOG_FILE" << EOF
# Daily Progress Log

## Date: $DATE
## Developer: $DEVELOPER_NAME

### Summary
Brief summary of today's progress and key accomplishments.

### Hours Worked
Total hours worked today: [Hours]

### Code Snapshots

EOF
    fi
    
    # Replace template placeholders
    sed -i "s/\[YYYY-MM-DD\]/$DATE/g" "$LOG_FILE"
    sed -i "s/\[Name\]/$DEVELOPER_NAME/g" "$LOG_FILE"
    
    # Add code snapshots
    SNAPSHOTS=$(get_code_snapshots)
    if [ -z "$SNAPSHOTS" ]; then
        SNAPSHOTS="No code snapshots available for today."
    fi
    
    # Add code metrics
    METRICS=$(get_code_metrics)
    
    # Add backup verification
    BACKUP_VERIFY=$(get_backup_verification)
    
    # Update the log file with dynamic content
    # This is a simplified approach - a more robust solution would use a proper template engine
    sed -i "/\[Code snippet with key implementation\]/c\\$SNAPSHOTS" "$LOG_FILE"
    sed -i "/Lines of code added: \[Number\]/c\\$METRICS" "$LOG_FILE"
    sed -i "/Daily backup completed successfully/c\\$BACKUP_VERIFY" "$LOG_FILE"
    
    echo "Daily progress log generated at $LOG_FILE"
}

# Main execution
generate_log

# Open the log file for editing (if running interactively)
if [ -t 0 ]; then
    ${EDITOR:-vi} "$LOG_FILE"
fi
