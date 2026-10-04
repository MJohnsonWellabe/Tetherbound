# Tetherbound — agent instructions

`AGENTS.md` and `CLAUDE.md` are intentionally identical. Update both together.

Build the GAME_BIBLE product: a four-chapter creature expedition action RPG in this pass (Meadows → Tidewake → Cloudreach → Stormwood) for Windows/ROG Ally, controller first, solo or required 1–4-player co-op. **Owner redesign (2026-09-29):** a 15–25-hour normal clear with a loop that is fun to grind but optional to repeat; the spine is building the best five-creature team, and the homestead is its required engine. Eight biomes remain the plan (four built in this pass; hall, schemas and tiers reserve slots for the rest). Five owned companions, directly piloted real-time fights, camps and a homestead supporting authored journeys, regional victory and homecoming. Source presence is not proof the experience works.

## Read and route

**Current build plan (owner-authorized, 2026-09-29):** every lane, Claude or Codex, starts at `CODEX_START_HERE.md`: the redesign build (Waves 0–3, features F16–F49, owner decisions RD-01..RD-37, lanes, file ownership, work orders and stop rules). It supersedes the Phase 1 and Phase 2 briefs; `CLAUDE_START_HERE.md` is now a pointer to it. Both files are part of the authorized live set.

Read STATE first for baseline/status/current authority, then GAME_BIBLE for product, ACCEPTANCE for done, WORKFLOW for process and TECHNICAL for source/run map. Read PRODUCT/ROADMAP when choosing scope or priorities. Read the relevant `docs/design/` contract before implementation; do not reread all twelve for a bounded task with a complete brief.

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
| TRAINING | Creature power: essence, chosen leveling, caps/breakthroughs, Masters and feasts, evolution lines, traits, learnsets/mastery, research log |
| HOMESTEAD | Homestead plot, stations and attachments, material tiers, creature and trainer gear, forward camps |

The full recovery/evidence artifact is `ralph/reports/PLAN-REWRITE/FINDINGS.md`. Archived owner directives retain authority for their scope unless superseded by newer owner direction; the archive is not automatically a live backlog. Do not cold-read it routinely. Open exact recovered sources when a task requires a constraint/provenance/decision detail. Never repeat the false claim that the compressed Bible contains every binding decision. Decision numbers were reused: cite full slug when ambiguous.

## Hard rules

- Godot is locked. Windows/ROG Ally primary, controller first. Compatibility remains the default until new on-device evidence authorizes a renderer change; the owner authorized building a Forward+ path with Low (Compatibility)/Medium/High presets, which becomes the default only after the owner's ROG Ally test passes (owner, 2026-09-29, RD-25).
- A player owns **five creatures total**. No storage, reserve box, hidden sixth, combat loaner loophole or quiet cap expansion.
- **Human never fights.** The trainer may support a fight with Tether Commands (item throw, Rally, tag-switch combo, Tether Snare) on a meter filled by creature hits, but never deals damage (owner, 2026-09-29, RD-12). Creatures do not perform base jobs. Real-time direct creature piloting; **no shields, blocking or held-button gameplay**, except Fly traversal, which may use held input (owner, 2026-09-27). Tap-start channels may continue by state/proximity, never require physical holding.
- Catch only during wild combat; never trainer-owned creatures. Starters are player-exclusive, no alternate wild/trainer/trade source. Freed legendaries volunteer. **Every participant in the fight that freed one receives their own offer, and each participant who accepts keeps their own**, bound to their stable character (owner decision, superseding the former one-durable-recipient-per-world-offer rule). A non-participant receives nothing, and no offer is granted twice to the same character.
- No hunting, butchering, automation or factory economy.
- Light satiety: slow drain, food restores/buffs, soft low-food drawbacks; **never starvation death**. Camping cannot be made necessary by harsher hunger/thirst/cold meters.
- Stack/slot inventory, no carry weight. Multiple death satchels persist. Five visible quick bindings; migrate legacy data without losing items. **One exception (owner, 2026-09-29, RD-35):** the redesign resets saves; v27-and-older saves are refused with a clear message and never overwritten. Migration discipline resumes for every later schema change.
- Creatures taller than the1.80m trainer. Relative scale fixes grow the smaller side, never shrink larger creatures to fit a camera.
- **Reference-backed art is required; the owner now authorizes agents to draft new reference art and run it through the existing Meshy license for scoped current-roster/hero-asset improvements.** This explicitly replaces the owner-supplied-image-only restriction and supplies permission for that workflow; do not ask again merely because an agent drafted the reference. Preserve established identity and scope, inspect the reference before submission, record provenance/task IDs and validate the candidate before integration. No new purchases, roster expansion, unreferenced text-to-3D or unattended generation batches follow from this permission, **except (owner, 2026-09-29):** one new creature, the Stormwood storm bear that Staticub evolves into (RD-28), and one bounded agent-attended overnight batch of about 25–30 named priority assets, capped at 30 generations per night, each with a drafted reference, scale check, code-blind before/after judge and provenance, and left flag-off on failure (RD-26). Historical accepted assets/exceptions retain their dispositions. Routine environment uses coherent installed asset families.
- Reuse installed humanoid cast; F36#0 may regenerate the most-repeated NPC faces only as identity-preserving refinements of the same installed characters, within the RD-26 batch rules (owner, 2026-10-04). Warden rebuild exists at `assets/characters/warden/warden_lod0.glb`. Read ART_DIRECTION's current inventory/provenance routing before relying on an old mesh description.
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

New design targets are not built facts. If source and design differ, state both and implement only the authorized scope. The plan rewrite records its lower-level disagreements. The explicit owner art-workflow authorization above applies; it does not authorize purchases, a commercial platform launch or unrelated hard-rule changes. Rolling development downloads follow the settled-spec delivery rule below.

## Execution

**RD-37 (owner, 2026-09-29): selective checks and continuous implementation.** Do not run unit tests or full CI automatically for every change or PR. Choose only named acceptance proofs or checks necessary to prevent substantial rework; reuse relevant passing evidence. Full suites/full CI are exceptional gates for explicitly required evidence or integration risk that scoped checks cannot cover. An unlabelled CI green is process evidence only when engine jobs did not run. Advance independent next tasks on lane branches while checks/CI run, using a pushed dependency candidate where needed; retain dependency landing order, exact ownership and serialized import/render/export writers. Never skip, disable or quarantine a test to make a selected check pass.

**RD-36 (owner, 2026-09-29): minimum necessary testing, batched validation.** Prioritize content and code generation. Use only checks required by acceptance or substantial rework risk; reuse passing evidence for unchanged relevant source and paths. Related criteria may share a bounded implementation/validation batch, with evidence and an independent verdict for each. Do not repeat a full suite per criterion or docs/evidence-only update. Broad save/autoload/shared-system changes and explicitly named full-suite acceptance still need one full batch run; fixes need affected checks unless wider risk justifies more. Preserve required save, authority/transaction, real-path and visual proofs, CI, and the prohibition on skipping, disabling or quarantining tests. CODEX_START_HERE §7.2 and WORKFLOW §5 apply this owner override.

Owner resource direction: coding and existing tools/assets, including the already-held Meshy license; no assumed commissioning or new expenditure. Keep mechanics checks brief and focused using the current implementation before adding proposed systems. Preserve required correctness/save/co-op regressions. Keeping the same five beloved companions is success; later content must reward their development. Agent-drafted references and Meshy submission are owner-authorized under the art rule above. Release co-op must support invitation joining without manual addresses or router configuration; the existing ENet fallback alone does not meet that target.

Reproduce/audit before trusting a document. Make the smallest coherent player-facing change. Put tunables in config. Test appropriate logic and actual path; capture visual changes in engine, use a code-blind judge for a major pass. New modals join input_owner, all new flags declare scope, all mutated durable state declares transaction/migration. Preserve working behavior outside scope.

Senior owns design/architecture/integration/acceptance; delegate mechanical bounded work to lower tiers when authorized, with exact file ownership and stop conditions. Serialize shared-file work and render/import/export writers; independent read-only tests can parallelize. An agent's self-report is not verification. **Once the owner has settled a spec, agents perform implementation, independent review, gameplay/visual validation, PR merge and rolling development-download publication without another human review gate.** The named acceptance proof still has to pass; a failed or unavailable check stays open. New pillar/hard-rule decisions, purchases and a commercial platform launch are separate owner decisions. WORKFLOW §1.1 defines the four lanes and proof chain.

For this four-chapter pass, use ROADMAP F01–F49 as the feature-request/PRD boundaries (F16–F49 are the redesign rows in CODEX_START_HERE), X01–X07 for shared work, and ACCEPTANCE §6.1–§6.2 for each feature's pass/fail criteria. Decompose the active feature into bounded work orders under its ID as WORKFLOW §1.1 specifies; the 13 chapter cards are integrated exit gates, not interchangeable feature requests.
Independent F rows can run in parallel lanes with exact path ownership (ROADMAP §3). Serialize shared-file edits and Godot writers; accept integrated chapters in earned handoff order. The Phase 1 and Phase 2 lanes are superseded by the redesign waves (CODEX_START_HERE §4, §7.5); still-open F01–F15 criteria fold into the new rows. Push lane work at least hourly and rebuild the board hourly (CODEX_START_HERE §7.3). Claude lanes may do scene-level art from installed asset families (kitbash, materials, shaders, lighting, dressing); new meshes and Meshy work stay with Codex (owner, 2026-09-27).

Update STATE in place. Evidence in `ralph/reports/<LANE>/`. The authorized live set is these routing twins; GAME_BIBLE, PRODUCT, ACCEPTANCE, ROADMAP, TECHNICAL, WORKFLOW, STATE; and the twelve design specs above. The owner authorized the two new contracts TRAINING and HOMESTEAD (2026-09-29). **No new live planning/status documents, no dated documents, no per-session goals/handoffs.** `.github/pull_request_template.md` is the process input form, not a second specification. Existing reference art/history may be read; new evidence is an artifact, not another live status document.

## Imported skills: local adapters and precedence

The owner requested six complete skills from `mattpocock/skills` at commit
`c55ee46073ed923f86ce59a5eb3b6d895095d1b7`: `writing-for-agents`, `grilling`,
`grill-me`, `grill-with-docs`, `wayfinder`, and `handoff`. Their upstream files
are unchanged in `.claude/skills/`, beside the existing project skills, and
mirrored in `.agents/skills/` for Codex discovery. Both include all upstream
files, including `agents/openai.yaml`; the upstream MIT notice is
`LICENSE.mattpocock` in each skills root. Update both copies together and verify
file-for-file equality. Full copies keep Windows checkouts working when Git
symlinks are disabled. This owner-authorized import is an exception only for
these skill packages, not permission for additional planning documents.

Read these adapters before applying an imported skill; this file and WORKFLOW
override its instructions:

- On platforms without a `Skill` tool, read the named local `SKILL.md` and its
  required references. `grill-me` delegates to the installed `grilling` skill.
  Preserve Codex invocation policy from `agents/openai.yaml`; the upstream
  `disable-model-invocation` field alone is not the Codex policy.
- `grilling` is a design interview in rounds. The user's answers settle choices;
  agents investigate facts. Its shared-understanding gate applies to the design
  being interviewed, not independent already-authorized work. It never grants
  permission to implement the game. Keep answers/status in STATE and settled
  specifications in the owning live documents.
- `grill-with-docs` calls `domain-modeling`, which is not part of this import.
  Report that missing dependency if invoked; use the existing owning live
  documents for authorized decisions rather than inventing ADR/glossary files
  or silently installing another skill.
- `wayfinder` assumes a configured tracker and also calls uninstalled
  `domain-modeling`, `research`, and `prototype` skills. Report those limitations
  when relevant. Do not run or request `setup-matt-pocock-skills`, create its
  fallback local tracker, or replace STATE/ROADMAP with a parallel ledger.
  External issue maps require explicit task scope. Its one-ticket-per-session
  stop and `research/<name>` branches do not override WORKFLOW's task completion,
  branch prefixes or continuation of independent authorized work.
- `handoff` asks for an OS-temp session handoff. WORKFLOW §11 instead requires
  updating STATE in place and linking existing evidence; retain that convention
  unless the owner explicitly changes it. Installing this skill is not invoking
  its handoff-file behavior.
- `writing-for-agents` is guidance for clarity and routing. Its pruning and
  document-splitting advice cannot remove load-bearing constraints, break the
  AGENTS/CLAUDE identity rule, or expand the authorized live document set.

## Branches and stop conditions

Branch from current main unless the user specifies a pinned baseline. Every branch uses the `tb/` prefix; never create `ralph/` or `claude/` branches. One reused branch per lane: a lane works on a single long-lived `tb/<lane>` branch and merges `origin/main` back in after each landing. **Self-landing (owner, 2026-09-28; testing/batching updated by RD-36):** there is no coordinator and no lane channel. When a criterion or coherent batch closes, the lane independently re-checks each criterion, runs the necessary batch checks under RD-36, updates the board and STATE, and lands it through its own PR to `main` with auto-merge. CI verifies that PR (WORKFLOW §8; `CODEX_START_HERE.md` §7.2). No scratch branches (dispatch render.yml with a commit SHA). Never push main directly. A settled spec and its acceptance criterion authorize the matching implementation, independent agent review, automatic PR merge and rolling development-release publication once the required checks pass. Do not merge a change that alters an unsettled product decision or publish a commercial launch without its separate owner decision. Check actual CI jobs and package identity: docs-only green verifies no engine behavior. No force rewrite of another active agent's branch.

Two unsuccessful attempts at the same fix/measurement or two report-only turns without useful evidence mean change approach or re-scope. One confirming rerun for a suspected infrastructure failure; flake is not a root cause. This does not prohibit an explicitly requested design/report task. Open decisions do not block independent authorized work; keep conservative behavior where approval is needed. Measurement infrastructure is not the deliverable. A region is done only when its complete player path produces the intended experience.
