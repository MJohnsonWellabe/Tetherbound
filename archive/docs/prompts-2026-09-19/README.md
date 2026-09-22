# Prompt library

This directory holds the **dated orchestration contracts** and the **package-level
gameplay contracts** the roadmap consumes. It is not the task queue.

For current work, start at:

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. **`77-CODEX-GOAL-four-biome-push-2026-09-07.md`** — the current run's contract.

## Current contracts (2026-09-07)

- `77-CODEX-GOAL-four-biome-push-2026-09-07.md` — the consolidated plan for the next
  long Codex run: stability, road creature presence, roster wiring, the visual
  sweeps and audits, the combat ladder, Stormwood and Water tails, multiplayer
  upkeep, cheap performance wins, docs upkeep. Supersedes the per-topic handoffs.
- `76-CODEX-combat-depth-performance-and-visual-bar.md` — the combat depth ladder,
  the first Ally frame-time measurement and the owner-run visual verdict, rolled
  into one contract. Lives on `claude/early-game-combat-design-fp3tua` until that
  branch lands; 77 folds it in and overrides its performance ordering with the
  owner's 2026-09-07 priority.
- `75-CODEX-pull-in-pickup-assets-and-finish-the-meadows.md` — the 2026-09-04
  pickup-asset wiring and Meadows finishing order. Its asset wiring landed; its
  "finish the Meadows" pointers are now carried by 77.
- `73-PROGRESSION-VISIBLE-bond-and-level-feedback.md`,
  `74-ART-REFERENCE-owner-boards-for-meshy.md` — still the implementation contracts
  for the bond/level feed and for the art-source order (installed asset → free pack
  → Meshy).

## Package-level gameplay contracts (55–72)

These assemble child systems into the complete Meadows chapter and are still what
`docs/ROADMAP.md`'s gates name. Most have landed at least once; `docs/CURRENT_STATE.md`
§3 and `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s CL-* table say what is still open.

- `55-MEADOWS-gameplay-assembly-master.md` — chapter-wide integration standard.
- `56-OPENING-first-session-to-tournament.md` — fresh start through village tournament.
- `57-TEAM-progression-curve.md` — natural strength/XP progression across major challenges.
- `58-REWARD-resource-economy.md` — rewards/resources must enable something the player wants.
- `59-TRAINER-journey.md` — authored trainer escalation from locals to Warden.
- `60-WILD-ecology-journey.md` — living creature ecology and team-choice pressure across all regions.
- `61-EXPEDITION-rest-rhythm.md` — injury/rest/camp/home as a real adventure rhythm.
- `62`–`66` — the five finished-band packages (Lower Meadows, Quarry/Warrens, River/Relay, Upper Meadows, Stronghold approach).
- `67-FIVE-creature-pressure-and-bond.md` — make five total slots emotionally/mechanically matter.
- `68-CHAPTER-complete-objective-chain.md` — player-facing chapter purpose/handoffs.
- `69-STRONGHOLD-chapter-finale.md` — Hall/Warden/legendary/world-healing payoff.
- `70-MEADOWS-full-chapter-integration-playthrough.md`,
  `71-GATEA-opening-environment-baseline.md`, `72-WORLD-ground-cover-and-mid-layer.md`.

## Archived

Prompts `01`–`54` (the 2026-08 review-item conversion: RG-*, OP-*, W-*, and the
early world/pond/torch/map items) and `COMPATIBILITY_MAP.md` moved to
`archive/docs/prompts/` on 2026-09-07. They were consumed or superseded by the
2026-09-04 plan (`docs/FINISH_THE_MEADOWS.md`, `docs/specs/C1`–`C4`) and the lane
briefs that landed. `docs/ROADMAP.md` still names some of them by short id for
history; read the archive copy only when a CL-* row or a code comment points at one.
