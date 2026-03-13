# Task: Monorepo Architectural Audit & Strategic Roadmap
**Role:** Senior Flutter Architect
**Project:** gdar (package: shakedown)

## Objective
Audit the repository for a Melos-managed monorepo transition. 

## Audit Requirements
1. **Coupling Analysis:** Check 'lib/' for UI/Logic tight coupling.
2. **8MB Asset Strategy:** Propose sharing logic for 'output.optimized_src.json' using path-dependencies or package-assets.
3. **Architecture Mapping:** Plan split into /packages/shakedown_core and /apps/ targets (Mobile, TV, Web).
4. **Platform Contract:** Verify "No Material on Web" compliance per AGENTS.md.
5. **Difficulty Rating:** Scale 1-10.
