# Tetherbound — agent instructions

`AGENTS.md` and `CLAUDE.md` are intentionally identical. Update both together.

Build the GAME_BIBLE product: a finite four-chapter creature expedition action RPG for Windows/ROG Ally, controller first, solo or1–4co-op. Five owned companions, directly piloted real-time fights, camps supporting authored journeys, regional victory and homecoming. Source presence is not proof the experience works.

## Read and route

Read STATE first for baseline/status/current authority, then GAME_BIBLE for product, ACCEPTANCE for done, WORKFLOW for process and TECHNICAL for source/run map. Read PRODUCT/ROADMAP when choosing scope or priorities. Read the relevant `docs/design/` contract before implementation; do not reread all ten for a bounded task with a complete brief.

| Contract | Owns |
|---|---|
| COMBAT | Verbs, states, timings, damage, AI, camera and difficulty |
| CREATURES | Catalogue, individuality, moves, bond, catching/evolution |
| BOSSES | Every named fight and chapter climax |
| WORLD | Geography, gates, activities, routes and consequences |
| SYSTEMS | Gathering/craft/build/care/supplies/traversal/death/weather |
| PROGRESSION | XP, levels, economy solvency, reward and time budget |
| UX | Input contexts, HUD/menus, onboarding, accessibility |
| MULTIPLAYER | Authority, portable/world state, shared play and limits |
| ART_DIRECTION | Visual bar, scale/materials, asset authorization/provenance |
| AUDIO | Score, ambience, voices, feedback and mix |

The full recovery/evidence artifact is `ralph/reports/PLAN-REWRITE/FINDINGS.md`. Archived owner directives retain authority for their scope unless superseded by newer owner direction; the archive is not automatically a live backlog. Do not cold-read it routinely. Open exact recovered sources when a task requires a constraint/provenance/decision detail. Never repeat the false claim that the compressed Bible contains every binding decision. Decision numbers were reused: cite full slug when ambiguous.

## Hard rules

- Godot is locked. Windows/ROG Ally primary, controller first. Compatibility remains until new on-device evidence authorizes a renderer change.
- A player owns **five creatures total**. No storage, reserve box, hidden sixth, combat loaner loophole or quiet cap expansion.
- **Human never fights.** Creatures do not perform base jobs. Real-time direct creature piloting; **no shields, blocking or held-button gameplay**. Tap-start channels may continue by state/proximity, never require physical holding.
- Catch only during wild combat; never trainer-owned creatures. Starters are player-exclusive, no alternate wild/trainer/trade source. Freed legendaries volunteer, with one durable recipient per world offer.
- No hunting, butchering, automation or factory economy.
- Light satiety: slow drain, food restores/buffs, soft low-food drawbacks; **never starvation death**. Camping cannot be made necessary by harsher hunger/thirst/cold meters.
- Stack/slot inventory, no carry weight. Multiple death satchels persist. Five visible quick bindings; migrate legacy data without losing items.
- Creatures taller than the1.80m trainer. Relative scale fixes grow the smaller side, never shrink larger creatures to fit a camera.
- **No new creature/humanoid meshes without owner-supplied reference art. Never spend a Meshy generation without reference-backed owner authorization.** Historic named exceptions are documented in ART_DIRECTION and their archived sources; no used exception is renewable blanket permission. Routine environment uses coherent installed asset families; Meshy is for authorized Tether hero subjects/exceptions.
- Reuse installed humanoid cast. Warden rebuild exists at `assets/characters/warden/warden_lod0.glb`. Read ART_DIRECTION's current inventory/provenance routing before relying on an old mesh description.
- Oxblood/red is reserved for Team Tether. One coherent nature/village/prop family.
- New gameplay is multiplayer-native from first implementation: authority, identity, transaction, save/reconnect and failure semantics precede polish.
- No silent major gameplay/story decisions. A task may tune declared numbers with evidence. A pillar/hard-rule conflict must be stated explicitly in STATE and the proposed change; preserve current rule until owner agrees.

## Precedence

1. Current explicit user instruction and newest applicable owner feedback.
2. These hard rules.
3. GAME_BIBLE identity/canon and PRODUCT release scope.
4. Owning design specification; ACCEPTANCE defines evidence, not an alternate mechanic.
5. ROADMAP sequencing, STATE status, WORKFLOW process, TECHNICAL source map.
6. Historical plans/decisions as recovered source context, except unsuperseded owner instructions retain item1authority.

New design targets are not built facts. If source and design differ, state both and implement only the authorized scope. The plan rewrite explicitly records its lower-level disagreements; it grants no art-generation, spending, release or hard-rule exception.

## Execution

Reproduce/audit before trusting a document. Make the smallest coherent player-facing change. Put tunables in config. Test appropriate logic and actual path; capture visual changes in engine, use a code-blind judge for a major pass. New modals join input_owner, all new flags declare scope, all mutated durable state declares transaction/migration. Preserve working behavior outside scope.

Senior owns design/architecture/integration/acceptance; delegate mechanical bounded work to lower tiers when authorized, with exact file ownership and stop conditions. Serialize shared-file work and render/import/export writers; independent read-only tests can parallelize. An agent's self-report is not verification.

Update STATE in place. Evidence in `ralph/reports/<LANE>/`. The authorized live set is these routing twins; GAME_BIBLE, PRODUCT, ACCEPTANCE, ROADMAP, TECHNICAL, WORKFLOW, STATE; and the ten design specs above. **No new documents outside this set, no dated documents, no per-session goals/handoffs.** Existing reference art/history may be read; new evidence is an artifact, not another live status document.

## Branches and stop conditions

Branch from current main unless the user specifies a pinned baseline. `ralph/<task>` shipping prefix; draft PR early because CI runs on PRs/main. Never push main directly. No merge/release without task authorization. Check actual CI jobs and package identity: docs-only green verifies no engine behavior. No force rewrite of another active agent's branch.

Two unsuccessful attempts at the same fix/measurement or two report-only turns without useful evidence mean change approach or re-scope. One confirming rerun for a suspected infrastructure failure; flake is not a root cause. This does not prohibit an explicitly requested design/report task. Open decisions do not block independent authorized work; keep conservative behavior where approval is needed. Measurement infrastructure is not the deliverable. A region is done only when its complete player path produces the intended experience.
