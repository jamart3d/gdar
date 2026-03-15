---
description: Purge large leaked binaries from git history using git filter-repo.
---

# Clean Git History Workflow

**When to use:** After accidentally committing large binaries (build artifacts, .dill caches, etc.) that inflate the repo size.

// turbo-all

## Prerequisites
- Install `git-filter-repo`: `pip install git-filter-repo`
- Ensure all team members have pushed their branches.
- **This rewrites history** — coordinate with collaborators before running.

## Steps

### 1. Identify Large Files
```powershell
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | Sort-Object { [int]($_ -split ' ')[2] } | Select-Object -Last 20
```

### 2. Remove Specific Paths
```powershell
git filter-repo --invert-paths --path "apps/gdar_mobile/build/" --path "apps/gdar_tv/build/" --path "apps/gdar_web/build/"
```

### 3. Force Push
```powershell
git remote add origin https://github.com/jamart3d/gdar.git
git push origin --force --all
git push origin --force --tags
```

### 4. Verify
```powershell
git count-objects -vH
```

> [!CAUTION]
> This is a destructive operation that rewrites git history. All collaborators
> must re-clone or `git fetch --all ; git reset --hard origin/main` after this.
