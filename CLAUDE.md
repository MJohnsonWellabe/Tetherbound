# Tetherbound — agent instructions

`AGENTS.md` and `CLAUDE.md` are intentionally identical. Update both together.

Build the GAME_BIBLE product: a four-chapter creature expedition action RPG in this pass (Meadows → Tidewake → Cloudreach → Stormwood) for Windows/ROG Ally, controller first, solo or required 1–4-player co-op. **Owner redesign (2026-09-29):** a 15–25-hour normal clear with a loop that is fun to grind but optional to repeat; the spine is building the best five-creature team, and the homestead is its required engine. Eight biomes remain the plan (four built in this pass; hall, schemas and tiers reserve slots for the rest). Five owned companions, directly piloted real-time fights, camps and a homestead supporting authored journeys, regional victory and homecoming. Source presence is not proof the experience works.

## Standing owner directions (override everything below; newest first)

**Owner, 25 Oct 2026 (evening), close-out exception:** a change expected to gain under 0.5 is allowed on its own when it is expected to take a visual item across the 7.5 bar (in practice an item already at about 7.0 or above). The GPU queue puts candidates that would close a criterion first. One lane keeps making big floor-raising swings; the others take near-bar items to 7.5. An approach that fails twice on the same item is parked until there is a new idea.

**Owner, 25 Oct 2026, no long route runs; bigger swings; lane runbook:** "I don't want" routes running one long route. A route piece proves one seam in about 30 minutes from a generated boundary save placed just before that seam; a missing boundary gets a generator profile, never a longer run. Only changes expected to gain more than 0.5 are made; small fixes ride along inside one and never stand alone. Every lane reuses TECHNICAL §8.1 (setup, captures, judging, route pieces) instead of rebuilding harnesses, and adds each new harness fix there. A lane that wraps up writes a handoff (state, open candidates, what worked, its runbook) at the top of its NOTE before its session is archived.

**Owner, 24 Oct 2026, raise the floor:** "We need to bring all the lowest things up to at least 6 first then when everything is at least at 6 bring everything up to 7. Then when everything is at 7 shoot for 7.5." Visual work runs worst-first in tiers on GPU mapped scores: every scored item below 6 is raised to 6, then everything to 7, then to 7.5. Unscored items get a GPU baseline first. The done bar stays 7.5; a candidate already built may still be judged.

**Owner, 24 Oct 2026, creature touches:** "Let's stick with what we have with adding some energy, some elemental effects, and some war torn appearance or hardened appearance to give the unique but still realistic look. Don't go overboard." Current creature meshes stay (no remake programme); each species gains one or two light touches on its existing model (a small elemental effect, or scars and hardened or weathered patches), kept subtle and realistic, no red or oxblood. **Owner, 25 Oct (delegated):** glow appears only where natural to the element (lightning arcs on storm creatures, embers on fire creatures, bioluminescent fins or frills on water creatures), never as glowing seams on fur or hide. Terrapup is a large dog, not a badger.

**Owner, 24 Oct 2026:** "Yes switch to GPU judging and split the rows." Every visual done/not-done verdict is judged on the GPU rig (Medium and High, the `tools/visual_judge/` yardstick, mapped Bar A of 7.5 or above); lanes keep iterating on CPU, but a CPU score no longer closes a row (this retires the CPU-provisional 6.7 rule below). Large rows are tracked per unit on the board: F36 (0) per priority asset, F36 (1) per roster subject, F38–F41 (1) and (2) per catalog item; each sub-row closes on its own GPU pass and the parent when all do. Bars are unchanged.

**Owner, 31 Oct 2026, lane progress:** "If lanes are working without making actual progress on the game then you need to redirect them." Progress means a change landed on main or a criterion closed. CPU scores, pushed arms and reports are not progress. Each lane has at most two arms waiting on the GPU, the GPU machine judges instead of doing hands-on work, and the coordinator redirects or pauses stalled lanes every hour. Full rules: docs/CRITERION_DELIVERY.md, "Lane progress rules".

**Owner, 31 Oct 2026, judging order:** "Yes, judge High first and leave the GPU on overnight." The GPU lane captures and judges each arm at High first, and adds Medium only for an arm whose High mapped score is 7.5 or above. A criterion still closes only at a mapped 7.5 or above on both Medium and High; the bar and the yardstick are unchanged. The owner's GPU machine stays on overnight and the queue runs unattended. Arms ship as data/config flags over flag-off code, so one imported tree serves several arms.

**Owner, 1 Nov 2026, creature design rule (from the owner's concept rounds; supersedes the 24 Oct "no remake programme" and the 25 Oct "never glowing seams on fur or hide" lines below):** every creature is a believable adult animal: lean, four-legged or its natural stance, mostly real fur, feathers or scales, with ONE elemental trait: glowing eyes plus glowing lines, veins or markings in its element, optionally partial natural plates of stone or bark on the spine, head or shoulders. No mascot or chibi, no upright humanoid, no full-body overgrowth, no big floating effects. The owner's favourites in game are Mosshell, Stormtrail and Veridian; owner picks: Terrapup A (lean rottweiler, mossy stone plates, jade eyes), Bramblebun A (four-legged hare, bark plates, glowing green veins, leafy tail), Trailpup concept 1 (nearly real coyote, glowing amber paws and eyes), Brooktail C (deep-river black otter, glowing aqua spots), Pipwing A (white and pale-blue owl, glowing feather edges and eyes), Galewisp A, Mudsnout A (root lines) and Mirejaw B; the rest follow the same rule ("You can do the rest and decide"). Remakes are Meshy candidates, flag-off until judged; species identity, silhouette and colours are kept; red and oxblood stay Team Tether only; creatures stay taller than the trainer.

**Owner, 22 Oct 2026, creature style:** "The in game models are more the vibe we're going for. They should be scoring higher." Then: "that galecrest, wolf and ram and stormursa are really strong. The rest should get to that style and level of quality." Galecrest, Tanglevolt, Stormcapra and Stormursa (board: `docs/reference/owner-creature-style-bar.png`) set the creature style and quality bar; every other creature is brought to that naturalistic style and quality, keeping its identity (species, silhouette, colours). Stylised remakes stop and stay off. Judges score creatures on readability (silhouette and value against the ground, visible eyes and face, rim light), pose, scale and integration; naturalistic rendering and fur/feather/scale detail are on-style, never a defect. The 7.5 bar is unchanged.

**Owner, 22 Oct 2026:** "Fix the yardstick then get our scores improved til we have a good looking game." Every visual verdict uses `tools/visual_judge/` (standard `JUDGE_PROMPT.md`, at least 3 anchor pairs per batch via `anchor_tiles.py`, `calibrate.py` mapping onto the original judges' scale); a criterion is done at a mapped three-judge Bar A mean of 7.5 or above (the bar is unchanged; the CPU-provisional rule below applied to mapped scores until 24 Oct, when GPU judging replaced it). Integrated route proof: "pieces that start with what they need proven by handoffs of runs that end at the right spot"; a committed manifest proves each seam, and nothing restarts a chain.

**Owner kickoff, 20 Oct 2026 (CT):** "Build as much of the plan as you can. I'm not doing the remote right now so readjust. Build what you can and close criteria." The coordinator runs the owner-approved weekly close plan (functional criteria first, then visuals with large Meshy batches) in cloud lanes from `origin/main`. No GPU machine is available: captures render on CPU (Mesa llvmpipe, Low/Compatibility). Owner, 17 Oct: without the GPU remote, "lower the threshold to account for the difference and run a GPU pass later". So a CPU three-judge Bar A mean of 6.7 or above (7.5 minus the measured 0.8 CPU/GPU gap on the same unchanged scene) counts as met, marked "CPU-provisional", until a GPU pass confirms 7.5; a GPU score below 7.5 reopens the criterion.

**Owner direction, 15 Oct 2026 20:50 CT (#572, 6206195964; specific to the Codex machine, superseded by the 17 Oct restart unless work returns to that machine):** Routes runs first, one active native lane; Look/Fights/Creatures pause native, capture, import and integration work. Performance follows when Routes has nothing runnable: smallest game-side full-vegetation Meadows Medium memory fix, existing capture without allocation errors, record frame time/VRAM for F25#4/F26. Visual work resumes after that fix lands. Meshy generation may continue; candidates stay OFF. Delete only clean, remotely reachable checkouts from the exact 30 inactive roots; skip and list dirty or unrecoverable roots. Keep restart checkouts, native stages, .artifacts, saves/evidence and required coordinator/shared Git. D floor 5 GiB, C about 1 GiB; all time, memory and proof limits unchanged.

When any line in this file, CODEX_START_HERE, WORKFLOW, ACCEPTANCE, a design contract, STATE or the board conflicts with this list, this list wins. Agents must not reinterpret these into stricter versions.

0. **Visual bar is 7.5 (owner, 15 Oct 2026; was 8.5).** A visual criterion or item is done at a three-judge Bar A mean of 7.5 or above. The gain/stop rule is unchanged: park after two consecutive rounds gaining under 0.5.
1. **Real art investment: Meshy with no generation cap (owner, 15 Oct 2026).** Make new assets wherever they raise the look: environment hero pieces, props, buildings, materials/textures, creatures, and installed characters (identity kept). There is no nightly or total generation cap, and Meshy is not a last resort after scene tweaks. Per asset, keep only the drafted reference, scale check, task-id provenance and flag-off until its scene passes judging. Use the existing Meshy account; if credits run out, report it on #572 and keep going with other work.
2. **Integrated proof in pieces, never full runs (owner, 13 Oct 2026; restated 15 Oct).** F49#0, chapter cards and every route/continuous criterion are proven as independent pieces. A piece may start from a disclosed generated boundary save (`tools/earned_saves/`) or an earlier piece's save. It does not re-earn earlier chapters or wait for the previous piece. Pieces run independently and in parallel; each passes on its own. The whole passes when every piece passes and each handoff matches by a reviewed manifest. No run plays through the game.
3. **Criterion delivery first (owner, 14 Oct 2026).** `docs/CRITERION_DELIVERY.md`: implement and prove criteria; no harness/tool/test work beyond the smallest fix for a reproduced blocker.
4. **Direct GPU runs (owner, 14 Oct 2026).** Native/GPU proofs run Godot directly from the lane's own checkout at its pushed commit with the existing script. No native stage, materialization, pinned-blob checks, leases or receipts. A check unrelated to the criterion never blocks a run. One GPU process at a time.

## Read and route

**Owner, 14 Oct 2026: criterion delivery first.** Read [docs/CRITERION_DELIVERY.md](docs/CRITERION_DELIVERY.md) before work. Current lanes are stopped pending owner restart. Implement and prove criteria; no harness/tool/test work except a reproduced blocker requiring the smallest necessary correction. Reuse preserved infrastructure; do not rebuild it.

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
- **Reference-backed art is required; the owner now authorizes agents to draft new reference art and run it through the existing Meshy license for scoped current-roster/hero-asset improvements.** This explicitly replaces the owner-supplied-image-only restriction and supplies permission for that workflow; do not ask again merely because an agent drafted the reference. Preserve established identity and scope, inspect the reference before submission, record provenance/task IDs and validate the candidate before integration. No new purchases, roster expansion, unreferenced text-to-3D or unattended generation batches follow from this permission, **except (owner, 2026-09-29):** one new creature, the Stormwood storm bear that Staticub evolves into (RD-28), and one bounded agent-attended overnight batch of about 25–30 named priority assets, capped at 30 generations per night, each with a drafted reference, scale check, code-blind before/after judge and provenance, and left flag-off on failure (RD-26). **The 30-per-night cap and the "where a scene change can't fix it" limit are superseded: Standing owner direction 1 (15 Oct 2026).** **Owner, 13 Oct 2026, 12:55 PM CT:** Codex may also use Meshy wherever the F38–F41 look pass needs a hero asset that a scene change can't fix. Each asset keeps the same per-asset rules (drafted reference, scale check, code-blind before/after judge, provenance, flag-off on failure), and generations stay within the existing license with no purchases. Historical accepted assets/exceptions retain their dispositions. Routine environment uses coherent installed asset families.
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

**Owner, 13 Oct 2026:** no long runs: continuous/integrated criteria (chapter cards, F49#0) are proven as chained pieces that hand off through saved checkpoints. All visual work is scored out of 10 (three averaged code-blind judges, fixed camera sets, Bar A first, Medium/High where a GPU is available); 7.5 or above is done (owner, 15 Oct 2026; was 8.5), and an item stops after two consecutive rounds gaining under 0.5. The F38–F41 look pass starts now, run by Codex's Astra tier in four biome lanes (WORKFLOW §8.1 rules 9–11). Reproduce/audit before trusting a document. Make the smallest coherent player-facing change. Put tunables in config. Test appropriate logic and actual path; capture visual changes in engine, use a code-blind judge for a major pass. New modals join input_owner, all new flags declare scope, all mutated durable state declares transaction/migration. Preserve working behavior outside scope.

Senior owns design/architecture/integration/acceptance; delegate mechanical bounded work to lower tiers when authorized, with exact file ownership and stop conditions. Serialize shared-file work and render/import/export writers; independent read-only tests can parallelize. An agent's self-report is not verification. **Once the owner has settled a spec, agents perform implementation, independent review, gameplay/visual validation, PR merge and rolling development-download publication without another human review gate.** The named acceptance proof still has to pass; a failed or unavailable check stays open. New pillar/hard-rule decisions, purchases and a commercial platform launch are separate owner decisions. WORKFLOW §1.1 defines the four lanes and proof chain.

For this four-chapter pass, use ROADMAP F01–F49 as the feature-request/PRD boundaries (F16–F49 are the redesign rows in CODEX_START_HERE), X01–X07 for shared work, and ACCEPTANCE §6.1–§6.2 for each feature's pass/fail criteria. Decompose the active feature into bounded work orders under its ID as WORKFLOW §1.1 specifies; the 13 chapter cards are integrated exit gates, not interchangeable feature requests.
Independent F rows can run in parallel lanes with exact path ownership (ROADMAP §3). Serialize shared-file edits and Godot writers; accept integrated chapters in earned handoff order. The Phase 1 and Phase 2 lanes are superseded by the redesign waves (CODEX_START_HERE §4, §7.5); still-open F01–F15 criteria fold into the new rows. Push lane work at least hourly and rebuild the board hourly (CODEX_START_HERE §7.3). Claude lanes may do scene-level art from installed asset families (kitbash, materials, shaders, lighting, dressing); new meshes and Meshy work stay with Codex (owner, 2026-09-27). The F38–F41 visual catalog is Codex-led (Astra, four biome lanes, started 13 Oct by owner direction, no longer last); Claude takes its UI and creature-pose rows and the code-blind judging (owner, 2026-10-12).

Update STATE in place. Evidence in `ralph/reports/<LANE>/`. Commit only written verdicts, small JSON/receipts and at most one `_sheet*.png` contact sheet (under 1.5 MB) per round; per-frame captures, videos, zips and caches go to CI artifacts or stay local (repo-size limit, owner 17 Oct 2026; `.gitignore` enforces it outside `gate-f-*`). The authorized live set is these routing twins; GAME_BIBLE, PRODUCT, ACCEPTANCE, ROADMAP, TECHNICAL, WORKFLOW, STATE; and the twelve design specs above. The owner authorized the two new contracts TRAINING and HOMESTEAD (2026-09-29). The owner authorized `docs/CRITERION_DELIVERY.md` (14 Oct 2026) as the binding delivery policy; it is part of the live set. **No new live planning/status documents, no dated documents, no per-session goals/handoffs.** `.github/pull_request_template.md` is the process input form, not a second specification. Existing reference art/history may be read; new evidence is an artifact, not another live status document.

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
these skill packages, not permission for additional planning documents. The project skills `visual-judge` and `criterion-delivery` are also mirrored in `.agents/skills/` for Codex; keep both copies identical.

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

Branch from current main unless the user specifies a pinned baseline. Every branch uses the `tb/` prefix; never create `ralph/` or `claude/` branches. One reused branch per lane: a lane works on a single long-lived `tb/<lane>` branch and merges `origin/main` back in after each landing. **Self-landing (owner, 2026-09-28; testing/batching updated by RD-36):** there is no coordinator and no lane channel. When a criterion or coherent batch closes, the lane independently re-checks each criterion, runs the necessary batch checks under RD-36, updates the board and STATE, and hands its pushed branch head to the coordinator, who lands ready lanes together in one consolidated PR with one CI run (owner, 2026-10-10: no per-lane PRs or per-PR CI; WORKFLOW §8). CI verifies that PR (WORKFLOW §8; `CODEX_START_HERE.md` §7.2). No scratch branches (dispatch render.yml with a commit SHA). Never push main directly. A settled spec and its acceptance criterion authorize the matching implementation, independent agent review, automatic PR merge and rolling development-release publication once the required checks pass. Do not merge a change that alters an unsettled product decision or publish a commercial launch without its separate owner decision. Check actual CI jobs and package identity: docs-only green verifies no engine behavior. No force rewrite of another active agent's branch.

Two unsuccessful attempts at the same fix/measurement or two report-only turns without useful evidence mean change approach or re-scope. One confirming rerun for a suspected infrastructure failure; flake is not a root cause. This does not prohibit an explicitly requested design/report task. Open decisions do not block independent authorized work; keep conservative behavior where approval is needed. Measurement infrastructure is not the deliverable. A region is done only when its complete player path produces the intended experience.
