# Omakeez progress

| Task | Status | Commit | Notes |
|---|---|---|---|
| 01 — Repository and plugin skeleton | Complete | 2ae6a48 | Manifest, loadable entry points, bar/panel lifecycle, smoke harness, and validations pass. |
| 02 — Catalog generator | Complete | 88e1679 | Offline and live read-only validation pass: 228 active bindings, valid Lua, and second run reports `changed:false` with unchanged mtime. |
| 03 — Configuration inspector | Complete | 512367d | Read-only path, symlink, safety, marker, Git, and diff inspection pass in fixtures and live mode. |
| 04 — Transactional patcher | Complete | 1ffa8d8 | Fixture-only transactional enable/disable, hash checks, backups, Lua validation, atomic replacement, and restoration pass. |
| 05 — Lua bridge | Complete | 6bc16ab | Fail-closed bridge, exact protocol matching, modifier state, duplicate-load guard, and mock stress tests pass. |
| 06 — Live feasibility gate | Complete | 75ef370 | Live bridge PASS: 267-match matrix, physical lifecycle/chord checks, p95 1 ms, 0.1600% five-minute Quickshell CPU ceiling, identical bind metadata, and byte-identical cleanup. |
| 07 — Production service | Complete | c4023c6 | Strict catalog/protocol service, async regeneration and bridge inspection, inline settings, lock/polkit state, debounced fullscreen queries, and QML model tests pass. |
| 08 — Instant Super Guide | Complete | dce6e24 | Pre-created per-screen visual guide, focused-monitor routing, delay/suppression behavior, exact filtering, truncation, highlight timing, and guide model tests pass. |
| 09 — Bar widget and onboarding | Complete (manual gate passed) | dd3b60c | Bar status/streak tooltip, consent preview, exact diff/hash boundary, fixture safety tests, settings panel, readable guide layout, and live consent flow pass. Full access to truncated bindings remains Task 12. |
| 10 — Aggregate persistence | Superseded by privacy release | 06c0026 | The stats writer, `stats.json`, recovery logic, and activity-history tests are removed. Omakeez no longer persists shortcut use. |
| 11 — Gamification and recommendations | Superseded by privacy release | 06c0026 | XP, levels, streaks, quests, recommendations, and their runtime/tests are removed. |
| 12 — Full Dojo overlay | Superseded by privacy release | 06c0026 | The unused browse/practice/progress overlay is removed from the manifest and repository; the focused visual guide remains. |
| 13 — Dotfiles and failure hardening | Complete | c368aaa | Symlink/deployment/marker/permission/dependency matrix, safe state handling, troubleshooting backup listing, and immediate guide disconnect behavior pass. |
| 14 — Integration, privacy, and performance | Complete (manual gate passed) | 98fcd92 | Automated suite and live release evidence pass; manual lock/privacy/reset/focused-monitor checks pass, with the 1Password app prompt documented outside the detection boundary. |
| 15 — Documentation and release | Submitted; automated validation passed | 54193c5 | README, security, troubleshooting, changelog, privacy boundary, bridge source comments, release-gate docs, and selected live screenshots are aligned with the guide-only product. The official marketplace manifest, Quattro compatibility, and automated security baseline checks pass. Listing review remains with the marketplace maintainers in issue #3726. |

## Marketplace publication

- [x] Public release repository available at `cyprusad/omakeez`.
- [x] Local manifest, QML lint, Lua syntax, hardening, and complete test suite pass at `54193c5`.
- [x] Official marketplace submission opened as `omacom/omarchy-plugin-marketplace#3726`.
- [x] Marketplace structure, Quattro compatibility, and automated security baseline validation pass at `54193c5`.
- [ ] Marketplace maintainer listing approval is pending.

## UX polish workstream

| Polish | Status | Commit | Notes |
|---|---|---|---|
| 01 — Super Guide behavior and look | Complete (manual UX gate passed) | 24b5a91 | The ranked canopy follows the familiar `SUPER+K` order from the center outward in both primary and secondary rows, resolves physical `code:N` bindings through the active XKB keymap, and uses stepped corner caps that attach to the secondary row plus extended edge wings to expose six additional low-priority shortcuts. The duplicate Copilot menu binding is labeled accurately but excluded from the guide. Shift/Ctrl/Alt discovery is a terse header hint with no footer or counts, active lanes use human-readable chords, and the guide aligns with the top screen edge. Expansion preserves the entire visible canopy frame and balances only hidden choices into its interior; fully fitting lanes keep that same frame. The visible overflow pill matches a binding card while its wider reserved slot preserves the stepped secondary row. Header guidance uses normal sentence case around all-caps shortcut names, and chord text is larger and bolder than its description. Two-line cards, contrast shield, and restrained motion remain. True backdrop blur is deferred because it would require compositor-specific configuration. See `UX_POLISH_01_SUPER_GUIDE.md`. |
| 02 — Privacy-first guide coverage | Complete | 06c0026 | `SUPER`, `CTRL`, `ALT`, and `SHIFT` root the hold-to-reveal guide under consent. The first-held root is stable until release, and added modifiers select the exact chord lane. There is no activity persistence, telemetry, or selection policy. See `PRIVACY_FIRST_GUIDES.md`. |
| 03 — Omakeez panel and privacy simplification | Complete | 06c0026 | The rebranded panel provides visual settings and controlled integration with no gamification surfaces; the obsolete stats/recommendation runtime and full Dojo overlay are removed. Setup and enabled states use a consistent visual hierarchy, the bar has no activity badge, and the original keyboard glyph remains after the rejected logo experiment. See `UX_POLISH_02_OMAKEEZ_OVERLAY.md`. |

## Commit log

| Commit | Scope |
|---|---|
| `c284cd1` | Add approved engineering plan. |
| `2ae6a48` | Add Task 01 plugin skeleton and shell smoke harness. |
| `88e1679` | Add Task 02 offline catalog generator, fixtures, and tests. |
| `512367d` | Add Task 03 read-only bridge inspector and fixture tests. |
| `1ffa8d8` | Add Task 04 transactional bridge patcher and fixture test. |
| `6bc16ab` | Add Task 05 fail-closed Lua bridge and mock harness. |
| `7dd6bdb` | Correct the live Hyprland keyboard callback signature discovered during Task 06. |
| `07488dc` | Record the first live feasibility failure and safe config restoration. |
| `13e79af` | Load the bridge from the installed plugin path. |
| `25dd38e` | Harden bridge reload behavior and live catalog normalization. |
| `070c9c5` | Add the Task 06 live timing probe and minimal guide surface. |
| `d3dc99a` | Load the feasibility service in the installed Omarchy shell. |
| `af08db5` | Correct the bar widget properties found during live validation. |
| `75ef370` | Record the Task 06 PASS and add the 267-entry live catalog matrix. |
| `c4023c6` | Implement the Task 07 production service and its protocol/catalog test suite. |
| `dce6e24` | Implement the Task 08 instant Super Guide and its focus/filtering test suite. |
| `2171c07` | Implement the Task 09 bar widget, onboarding consent preview, settings panel, and fixture safety tests; pause before live consent. |
| `dd3b60c` | Finish Task 09 presentation fixes and record the live manual consent gate as passed. |
| `e45f586` | Add aggregate usage persistence, recovery storage, reset confirmation, and Task 10 tests. |
| `ce34f8f` | Record Task 10 completion in the progress checklist. |
| `c057362` | Add deterministic gamification, streaks, quests, recommendations, and real progress surfaces. |
| `c368aaa` | Harden integration/recovery paths and add the Task 13 scenario matrix. |
| `2b7fb92` | Implement the full Dojo overlay shell and static smoke test. |
| `1b99c95` | Harden overlay styling, keycap surfaces, and shortcut interception. |
| `59b2d2a` | Clarify the overlay close affordance and Escape guidance. |
| `cd486b4` | Make the close control and Escape keycap visibly explicit; simplify search text. |
| `e0ca7aa` | Make Tab focus navigation wrap and show the active tab target. |
| `833f6ca` | Stabilize overlay keyboard focus and align binding keycaps with menu surfaces. |
| `2a252b3` | Add `/` and `Ctrl+F` keyboard shortcuts to refocus search. |
| `3ebe8f5` | Match binding keycaps to the Practice menu surface. |
| `f234331` | Match binding result rows to the Practice menu background; manual Task 12 gate passed. |
| `b799d8a` | Record Task 12 completion and its full overlay commit trail. |
| `75d6433` | Add the Task 14 all-suite runner and release-gate automation. |
| `03302ac` | Add Task 14 release evidence and the manual-gate checklist. |
| `90bbfd1` | Explain local data storage and privacy in Settings. |
| `0ffc0de` | Record release-gate preflight. |
| `d3f7838` | Record local data inspection. |
| `3d62a9b` | Record tracking round-trip verification. |
| `7efc421` | Record ordinary typing privacy verification. |
| `eb4e95a` | Fix stats writer input closure so aggregate data persists. |
| `fdf297f` | Record aggregate tracking evidence. |
| `f0d72f5` | Capture exact stats release evidence. |
| `73a830f` | Record guide settings verification. |
| `f7fcae5` | Record shell and Hyprland reload recovery. |
| `1863dfd` | Record lock-screen suppression. |
| `e0b5435` | Make local-data reset actionable during pending stats flushes. |
| `4530df8` | Record stats reset and recovery verification. |
| `771db7f` | Add the UX Polish 01 Super Guide behavior and look plan. |
| `6ce5632` | Model ranked, dense Super Guide canopy layouts and readable raw key labels. |
| `77df621` | Render the transparent glass Super Guide canopy. |
| `dc67acd` | Fix deferred production-service timer restarts found during live refresh. |
| `e0d4f01` | Expand Super Guide overflow on pointer hover. |
| `e0d9b52` | Polish canopy expansion motion and record the implementation checkpoint. |
| `815a533` | Add a theme-aware Super Guide contrast gradient and legible two-line cards. |
| `fea4f41` | Mirror Omarchy's `SUPER+K` ordering and resolve physical code bindings through XKB. |
| `81f61ca` | Add wide-screen Super Guide corner caps for two more low-priority bindings. |
| `7b5974a` | Alternate the Super Guide secondary row outward from the overflow pill. |
| `74d5441` | Extend wide-screen guide edge wings for four more visible shortcuts. |
| `969adf9` | Label Omarchy's Copilot key and hide its duplicate menu binding from the guide. |
| `4a7c0eb` | Step Super Guide corner caps inward on the secondary row. |
| `8a8a929` | Attach Super Guide corner caps to the outer secondary-card boundary. |
| `034002d` | Replace opaque modifier counts with plain-language Shift/Ctrl/Alt discovery guidance. |
| `a9df5a4` | Move Shift/Ctrl/Alt discovery to the header and remove the footer. |
| `e56f846` | Render active guide lanes as shortcut chords instead of internal masks. |
| `76b1856` | Align the Super Guide content with the top screen edge. |
| `ca70cda` | Preserve the canopy's spatial map for hover expansion and fully fitting lanes. |
| `2fedeea` | Repack expanded and fully fitting Super Guide lanes into solid terrace rows. |
| `49be0a0` | Preserve the visible canopy frame while filling its open interior on expansion. |
| `89dd507` | Match the visible overflow pill to a normal guide card. |
| `00f9b2c` | Retain the wide reserved overflow slot so the stepped canopy geometry stays fixed. |
| `eb42dba` | Use Omarchy-style all-caps language throughout the Super Guide header. |
| `03cfb79` | Emphasize shortcut chords and use sentence-case header guidance. |
| `36461e2` | Generalize the held-modifier guide to Super, Ctrl, Alt, and Shift roots. |
| `041650c` | Center sparse modifier-guide lanes symmetrically. |
| `9f68b3e` | Rename the plugin, protocol, state namespace, and documentation to Omakeez. |
| `88f3ae8` | Polish setup wording, action alignment, and theme-aware integration diffs. |
| `7bf197f` | Clarify setup review and replacement diff, remove catalog-progress noise, and make Enable the Enter-activated primary CTA. |
| `4c59c1e` | Clarify configuration paths and safety states, with adaptive green/amber fallback guidance. |
| `3aa22af` | Replace the empty Git diagnostic with explicit tracked/not-tracked status. |
| `e26455d` | Organize the review card into explicit Symlink, Git, and final Safety checks. |
| `d113df3` | Simplify the bridge diff explanation and link to the public bridge source. |
| `92b9a56` | Clarify setup hierarchy with matched section headers, a Next step CTA, and optional tools. |
| `a384240` | Replace the checklist-like setup layout with a compact decision-led enable flow. |
| `096b051` | Size the setup panel to visible content and expand it only for the requested diff. |
| `0c87919` | Include scroll insets in compact sizing so the primary CTA cannot be clipped. |
| `10e2c3e` | Clarify that the visual guide exposes registered keyboard shortcuts. |
| `529b300` | Isolate Omakeez from stale Keybind Dojo bridge state and simplify enabled settings. |
| `14c93db` | Keep the bridge inert through initial catalog generation, then activate it on the next key event. |
| `aa68851` | Strengthen active settings hierarchy with all-caps groups and native separators. |
| `cedfa66` | Remove streak/XP metadata and number badge from the Omakeez bar status. |
| `d073175` | Replace user-facing tracking language with visual-guide language. |
| `f609fec` | Align onboarding headings and separators with the active Omakeez panel. |
| `e2f3e66` | Use an all-caps setup title and remove the redundant enable section heading. |
| `198ce71` | Capitalize the enabled panel's top-level OMAKEEZ heading. |
| `623ffe6` | Soften major headings and give Delay and Fullscreen one uniform field-label style. |
| `e1ac277` | Put visual guide settings first, remove the GUIDE heading, and move integration controls to the bottom. |
| `1569b81` | Center and promote the Disable visual guide action. |
| `b35a729` | Add independently persisted Super, Shift, Ctrl, and Alt guide-root toggles. |
| `6c537e3` | Stage compact and outline native O-key marks for live visual comparison. |
| `0aa86c6` | Replace the under-resolved mark with distinct bar micro and panel full O-key optical sizes. |
| `c72ca9d` | Remove the rejected vector-mark experiment and restore the original keyboard glyph. |
| `06c0026` | Remove activity persistence, gamification, and the unused full Dojo overlay. |
| `503544a` | Add security-oriented bridge comments and retain only the intentional public source-audit URL. |
| `7f4fd3a` | Add selected Super Guide, enabled-panel, and setup-panel release screenshots to the README. |
| `62e727d` | Prepare the guide-only release documentation and metadata. |
| `96de811` | Record the successful fresh-clone release smoke. |
| `4d042da` | Record the selected release screenshots in the progress log. |
| `57a6590` | Simplify public documentation to the current visual-guide-only product. |
| `4727768` | Record the final public-language simplification. |
| `54193c5` | Clear marketplace validation by renaming the onboarding screenshot and aligning stale release assertions. |
