---
description: Analyzes code or screenshots to suggest Liquid Glass and Neumorphism improvements.
---
When the user runs `/improve_liquid` alongside a file path, code snippet, or an attached UI screenshot, execute the following workflow:

1. **Analyze the Target**: Review the current UI implementation or image for compliance with the GDAR **Liquid Glass** and **Neumorphism** design philosophy.
2. **Identify Deficiencies**: Actively look for:
   - Missing frosted glass blur (`BackdropFilter`).
   - Standard Material 3 organic/breathing ripples (these must be replaced with Apple-style spring/scale-down physics).
   - Incorrect typography (must be `Inter`) or iconography (must be `lucide_icons`).
   - Overly heavy Neumorphic shadows or incorrect translucency layering (`.withValues()` should be used to bleed underlying colors).
3. **Propose Improvements**: Generate a concise, bulleted list of suggested component-level changes. Focus on applying established project wrappers (e.g., `LiquidGlassWrapper`, `NeumorphicWrapper`) or structural changes to achieve the premium aesthetic. 
4. **Refactor (Upon Approval)**: Once the user approves the proposed changes, execute the code modifications ensuring strict use of `const` constructors to prevent unnecessary rebuilds.
