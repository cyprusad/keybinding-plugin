# Keybind Dojo Implementation Tasks

This directory turns [`../PLAN.md`](../PLAN.md) into small, sequential assignments suitable for a coding agent working on one bounded problem at a time.

## Agent operating rules

For every task:

1. Read `docs/PLAN.md` and the assigned task completely before editing.
2. Inspect the current tree and preserve existing user changes.
3. Work only on the assigned task. Do not pull future features forward.
4. Use existing Omarchy source only as a read-only reference; never edit `$OMARCHY_PATH` or `/usr/share/omarchy`.
5. Do not modify the operator’s real `~/.config/hypr` unless the assigned task is the explicit live feasibility task and the user has authorized that live test.
6. Add or update automated tests for the behavior introduced by the task.
7. Run every command listed in the task’s validation section.
8. Stop and report a blocker if an acceptance criterion cannot be met. Do not substitute a riskier architecture.
9. End with a concise report: files changed, checks run, results, and remaining risks.

## Dependency order

| Order | Task | Depends on | Gate |
|---:|---|---|---|
| 1 | [01 — Repository and plugin skeleton](01-repository-and-plugin-skeleton.md) | — | Static plugin validation |
| 2 | [02 — Catalog generator](02-catalog-generator.md) | 01 | Fixture and live read-only catalog checks |
| 3 | [03 — Configuration inspector](03-configuration-inspector.md) | 01 | Symlink/dotfile fixture matrix |
| 4 | [04 — Transactional patcher](04-transactional-patcher.md) | 03 | Mutation tests against temporary fixtures only |
| 5 | [05 — Lua bridge](05-lua-bridge.md) | 02 | Mocked Lua event tests |
| 6 | [06 — Live feasibility gate](06-live-feasibility-gate.md) | 01–05 | Must pass before tasks 07–12 |
| 7 | [07 — Production service](07-production-service.md) | 06 | Event protocol and service tests |
| 8 | [08 — Instant Super Guide](08-super-guide.md) | 07 | Non-interference and latency checks |
| 9 | [09 — Bar widget and onboarding](09-bar-widget-and-onboarding.md) | 04, 07, 08 | One-click integration flow |
| 10 | [10 — Aggregate persistence](10-aggregate-persistence.md) | 07 | Atomic state and recovery tests |
| 11 | [11 — Gamification and recommendations](11-gamification-and-recommendations.md) | 02, 10 | Deterministic pure-logic tests |
| 12 | [12 — Full Dojo overlay](12-full-dojo-overlay.md) | 09–11 | Keyboard/UI acceptance matrix |
| 13 | [13 — Dotfiles and failure hardening](13-dotfiles-and-failure-hardening.md) | 04, 09 | Complete unsafe-config matrix |
| 14 | [14 — Integration, privacy, and performance](14-integration-privacy-performance.md) | 07–13 | Full release gate |
| 15 | [15 — Documentation and release](15-documentation-and-release.md) | 14 | Install/update/remove smoke test |

Tasks 02 and 03 may be implemented independently after task 01, but merge and validate them before task 04. All other tasks are sequential.

## Definition of done

The plugin is ready for a `0.1.0` release only when every task’s acceptance criteria pass, `omarchy plugin validate .` succeeds, `qmllint` succeeds for every QML entry point, `luac -p bridge.lua` succeeds, the complete automated test suite passes, and the live release gate records clean `hyprctl configerrors`.
