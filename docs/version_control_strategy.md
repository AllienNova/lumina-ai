# Git Configuration and Backup Strategy for Lumina AI

This document outlines our comprehensive Git configuration and backup strategy to ensure we never lose code during the Lumina AI development process.

## Git Configuration

### Local Repository Setup
- Main repository location: `/home/ubuntu/lumina-ai`
- Git initialized with `git init`
- Configured with appropriate `.gitignore` file to exclude build artifacts, IDE files, and sensitive information

### Commit Strategy
- Frequent commits (at least every 30 minutes during active development)
- Descriptive commit messages following conventional commits format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `refactor:` for code refactoring
  - `test:` for adding tests
  - `chore:` for maintenance tasks

### Branching Strategy
- `main` branch for stable code
- `develop` branch for active development
- Feature branches for specific features (e.g., `feature/provider-service`)
- Hotfix branches for urgent fixes (e.g., `hotfix/memory-leak`)

## Backup Mechanisms

### Primary Remote Repository
- GitHub repository: https://github.com/kimhons/lumina-ai
- Configured as `origin` remote
- Automated pushes after significant commits

### Secondary Remote Repository
- GitLab repository (to be configured)
- Configured as `backup` remote
- Automated daily pushes

### Local Backups
- Daily ZIP archives of the entire repository
- Stored in `/home/ubuntu/backups/lumina-ai`
- Naming convention: `lumina-ai-YYYY-MM-DD.zip`
- Retention policy: Keep last 7 daily backups

### Automated Backup Script
- Located at `/home/ubuntu/lumina-ai/scripts/backup.sh`
- Runs daily via cron job
- Creates ZIP archive and pushes to both remote repositories
- Logs all backup activities

## Code Recovery Procedures

### From Local Repository
1. Use `git log` to identify the commit to recover
2. Use `git checkout <commit-hash>` to restore to that point
3. Create a new branch if needed with `git checkout -b recovery-branch`

### From Remote Repository
1. Clone the repository: `git clone https://github.com/kimhons/lumina-ai.git`
2. Navigate to the repository: `cd lumina-ai`
3. Check out the desired branch or commit

### From ZIP Backup
1. Locate the appropriate backup in `/home/ubuntu/backups/lumina-ai`
2. Extract the ZIP file to a temporary location
3. Copy the needed files to the working directory

## Continuous Integration

- GitHub Actions workflow for automated testing
- Verification of code integrity after each push
- Notification system for build failures

## Documentation Versioning

- Documentation stored in the `docs` directory
- Versioned alongside code in the Git repository
- Major documentation versions tagged in Git

## Emergency Contacts

- GitHub Support: support@github.com
- Repository Owner: kimhons@github.com

## Verification Procedures

- Daily repository integrity check
- Weekly backup restoration test
- Monthly full recovery drill

This comprehensive strategy ensures multiple layers of protection against code loss, with redundant backup mechanisms and clear recovery procedures.
