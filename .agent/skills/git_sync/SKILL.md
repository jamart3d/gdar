# Git Sync Skill

Standardize version control operations for saving and updating the codebase.

**TRIGGERS:** save, push, pull, sync, commit, update

## Save Changes
1. Check state: `git status`.
2. Stage all: `git add .`.
3. Generate descriptive commit message.
4. Commit: `git commit -m "..."`.
5. Push: `git push`.

## Update Codebase
1. Check for local modifications: `git status`.
2. If modified, warn user to stash or commit.
3. If clean, pull: `git pull`.
