# Tetherbound — agent instructions

`AGENTS.md` and `CLAUDE.md` are intentionally identical. Update both together.

Build the GAME_BIBLE product: a four-chapter creature expedition action RPG in this pass for Windows/ROG Ally, controller first, solo or required 1–4-player co-op. Eight good hours can pass; future growth to eight biomes remains outside this pass. Five owned companions, directly piloted real-time fights, camps supporting authored journeys, regional victory and homecoming. Source presence is not proof the experience works.

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
- Catch only during wild combat; never trainer-owned creatures. Starters are player-exclusive, no alternate wild/trainer/trade source. Freed legendaries volunteer. **Every participant in the fight that freed one receives their own offer, and each participant who accepts keeps their own**, bound to their stable character (owner decision, superseding the former one-durable-recipient-per-world-offer rule). A non-participant receives nothing, and no offer is granted twice to the same character.
- No hunting, butchering, automation or factory economy.
- Light satiety: slow drain, food restores/buffs, soft low-food drawbacks; **never starvation death**. Camping cannot be made necessary by harsher hunger/thirst/cold meters.
- Stack/slot inventory, no carry weight. Multiple death satchels persist. Five visible quick bindings; migrate legacy data without losing items.
- Creatures taller than the1.80m trainer. Relative scale fixes grow the smaller side, never shrink larger creatures to fit a camera.
- **Reference-backed art is required; the owner now authorizes agents to draft new reference art and run it through the existing Meshy license for scoped current-roster/hero-asset improvements.** This explicitly replaces the owner-supplied-image-only restriction and supplies permission for that workflow; do not ask again merely because an agent drafted the reference. Preserve established identity and scope, inspect the reference before submission, record provenance/task IDs and validate the candidate before integration. No new purchases, roster expansion, unreferenced text-to-3D or unattended generation batches follow from this permission. Historical accepted assets/exceptions retain their dispositions. Routine environment uses coherent installed asset families.
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

New design targets are not built facts. If source and design differ, state both and implement only the authorized scope. The plan rewrite records its lower-level disagreements. The explicit owner art-workflow authorization above applies; it does not authorize purchases, a commercial platform launch or unrelated hard-rule changes. Rolling development downloads follow the settled-spec delivery rule below.

## Execution

Owner resource direction: coding and existing tools/assets, including the already-held Meshy license; no assumed commissioning or new expenditure. Keep mechanics checks brief and focused using the current implementation before adding proposed systems. Preserve required correctness/save/co-op regressions. Keeping the same five beloved companions is success; later content must reward their development. Agent-drafted references and Meshy submission are owner-authorized under the art rule above. Release co-op must support invitation joining without manual addresses or router configuration; the existing ENet fallback alone does not meet that target.

Reproduce/audit before trusting a document. Make the smallest coherent player-facing change. Put tunables in config. Test appropriate logic and actual path; capture visual changes in engine, use a code-blind judge for a major pass. New modals join input_owner, all new flags declare scope, all mutated durable state declares transaction/migration. Preserve working behavior outside scope.

Senior owns design/architecture/integration/acceptance; delegate mechanical bounded work to lower tiers when authorized, with exact file ownership and stop conditions. Serialize shared-file work and render/import/export writers; independent read-only tests can parallelize. An agent's self-report is not verification. **Once the owner has settled a spec, agents perform implementation, independent review, gameplay/visual validation, PR merge and rolling development-download publication without another human review gate.** The named acceptance proof still has to pass; a failed or unavailable check stays open. New pillar/hard-rule decisions, purchases and a commercial platform launch are separate owner decisions. WORKFLOW §1.1 defines the four lanes and proof chain.

For this four-chapter pass, use ROADMAP F01–F15 as the feature-request/PRD boundaries, X01–X07 for shared work, and ACCEPTANCE §6.1 for each feature's pass/fail criteria. Decompose the active feature into bounded work orders under its ID as WORKFLOW §1.1 specifies; the 13 chapter cards are integrated exit gates, not interchangeable feature requests.

Update STATE in place. Evidence in `ralph/reports/<LANE>/`. The authorized live set is these routing twins; GAME_BIBLE, PRODUCT, ACCEPTANCE, ROADMAP, TECHNICAL, WORKFLOW, STATE; and the ten design specs above. **No new live planning/status documents, no dated documents, no per-session goals/handoffs.** `.github/pull_request_template.md` is the process input form, not a second specification. Existing reference art/history may be read; new evidence is an artifact, not another live status document.

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

Branch from current main unless the user specifies a pinned baseline. `ralph/<task>` shipping prefix; draft PR early because CI runs on PRs/main. Never push main directly. A settled spec and its acceptance criterion authorize the matching implementation, independent agent review, automatic PR merge and rolling development-release publication once the required checks pass. Do not merge a change that alters an unsettled product decision or publish a commercial launch without its separate owner decision. Check actual CI jobs and package identity: docs-only green verifies no engine behavior. No force rewrite of another active agent's branch.

Two unsuccessful attempts at the same fix/measurement or two report-only turns without useful evidence mean change approach or re-scope. One confirming rerun for a suspected infrastructure failure; flake is not a root cause. This does not prohibit an explicitly requested design/report task. Open decisions do not block independent authorized work; keep conservative behavior where approval is needed. Measurement infrastructure is not the deliverable. A region is done only when its complete player path produces the intended experience.
