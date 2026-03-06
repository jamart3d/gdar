---
name: focus_trap_protection
description: Audit TV UI widgets for focus-safe patterns and node disposal.
---

# Focus Trap Protection Skill

### Context
TV UIs are prone to "focus traps" (where the user cannot navigate away from a section) and "ghost highlights" (where focus nodes are leaked or reused incorrectly).

### Audit Strategy
1. **Disposal Check**: Ensure every custom `FocusNode` created in a `StatefulWidget` is explicitly closed in `dispose()`.
2. **Stable Widget Tree**: In `TvFocusWrapper` and similar decorators, avoid mounting/unmounting children based on focus state if it causes layout shifts. Use `AnimatedOpacity` or zero-padding instead.
3. **Breadcrumb Focus**: Master-Detail layouts (`TvDualPaneLayout`) must implement "Back-to-master" logic to prevent focus from being swallowed by the detail pane after an action.
4. **Keyed Nodes**: Lists of focusable items should use `ValueKey` to prevent focus "ghosting" when the list reorders or filters.

### Helper Script: `scripts/audit_focus_disposal.ps1`
Use this to find potentially leaked focus nodes:
```powershell
Get-ChildItem -Path "lib/ui/widgets/tv/*.dart" -Recurse | Select-String -Pattern "FocusNode" -AllMatches | ForEach-Object {
    $file = $_.Path
    $content = Get-Content $file -Raw
    if ($content -match "FocusNode" -and $content -notmatch "\.dispose\(\)") {
        Write-Warning "Potential leaked FocusNode in: $file"
    }
}
```
