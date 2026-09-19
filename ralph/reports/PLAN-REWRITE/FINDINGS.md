# Tetherbound: recovery, findings and product decision

## Evidence boundary

Baseline: `b8eda885810c577bc46e6cf096b01ea36531690f` (PR #131, consolidation). The requested fetch, checkout and hard reset succeeded in the existing main checkout, `D:/tetherbound/owner-kickoff-closeout-r3`; the other checkout already had unrelated work. This branch is `ralph/plan-rewrite`. This task changes design documents only. Existing untracked imports and evidence are excluded.

The earlier PLAN-REVIEW at `44f578d2a193f090088a8e8f8a110df3bf0b15a9` is reused for its census and source inspection, not treated as infallible. This recovery corrects its ordered-bond claim: `scripts/creatures/bond_milestones.gd::tier()` counts **any** completed task, following D76; the JSON header is stale. No new runtime, visual, hardware or campaign acceptance is claimed by this documentation task.

Archive paths differ from the prompt's shorthand. The complete recovery includes both `archive/docs/owner/` and `owner-2026-09-19/`, earlier `archive/owner/`, both `biomes/` and `biomes-2026-09-19/`, and both `specs/` and `specs-2026-09-19/`. Sparse-excluded files were read as complete Git blobs from the pinned commit, not inferred from filenames. Decisions are keyed by full filename because six numbers repeat. Coverage and deliberate dispositions appear below. Historical implementation assertions are historical unless independently supported by the baseline source.

## Phase 1 findings

<!-- ROOT_FINDINGS -->

## Phase 2 central decision

<!-- ROOT_DECISION -->

## Recovery: gameplay specifications and historical state

Each row restores a constraint, explicitly supersedes an obsolete instruction, or records an unresolved dependency. Destination names refer to the new live document set. Recovery is not permission to reinstate every old proposal.

| ID | Source | Missing, misleading or load-bearing detail | Deliberate disposition / destination |
|---|---|---|---|
| S01 | `archive/docs/specs-2026-09-19/GAME_DESIGN.md` §§3,29 and `MEADOWS_PROGRESSION_SPEC.md` §§23–34 | Eight legendary conduits maintain artificial **Tether Rifts**. Team Tether monopolizes movement, trade, knowledge and migration; its claim that separation prevents disaster may contain truth. Warden warns rather than gloats. | Retain in GAME_BIBLE. Four shipped chapters resolve a regional campaign; eight-force cosmology does not promise eight playable biomes. |
| S02 | same, progression spec §§27–31 | Reconnection must visibly change travel and have consequences, not just set a next-level flag. World reassembly originally promises migrating ecology and new conflicts. | Retain authored physical reconnection and NPC consequence beats in WORLD/BOSSES; explicitly cut simulated migration, moving whole terrain masses and an eight-biome campaign. |
| S03 | GAME_DESIGN §§10–13; progression spec §4 | Personal names, battle history, physical beds, favourite food, Best Creature and conserved identity through evolution produce attachment. Starter exclusivity and no starter evolution matter. | CREATURES separates built mechanics from promised reactions; preserve identity/limited evolution, specify attachment through experiences rather than claim sentiment from a cap. |
| S04 | GAME_DESIGN §11; progression spec §20 | HP/attack/defence are the stats; no universal speed stat. New silhouettes were first demanded, then production constraints explicitly accepted imperfect meshes and material differentiation. | CREATURES/ART_DIRECTION retain the production constraint and state its ceiling. No silent mesh authorization. |
| S05 | GAME_DESIGN §§14–17 | Physical catching is vulnerable handover to the human; trainer cannot fight, target trainer-owned or fainted creatures for capture, or auto-start a peaceful encounter. | COMBAT/CREATURES retain. No replacement sixth-slot staging owned by the party. |
| S06 | GAME_DESIGN §§18–24 | Slot/stack inventory; no meat/leather/hunting economy; tools wear and repair freely; farming is not watered; manual map pins, no creature radar/free fast travel. | SYSTEMS/UX retain. Fishing's earlier inclusion is explicitly cut from the minimum release rather than quietly treated as implemented. |
| S07 | GAME_DESIGN §§25–33 | Multiple death satchels, no creature/XP loss; five-space 30–60 minute stronghold; repeat a fight ten times and want the eleventh; finite authored geography. | SYSTEMS/BOSSES/ACCEPTANCE retain intent; duration becomes a measured budget, not extra grinding to fill it. |
| S08 | GAME_DESIGN asset policy | Private asset entitlement is not public shipping clearance. Provenance and public redistribution rights must be checked before distribution. | ART_DIRECTION/ROADMAP release dependency; use installed ledger references, do not claim legal clearance from file presence. |
| S09 | `MEADOWS_PROGRESSION_CURVE.md` | Per-band wild high ≤ exit, low ≤ entry, high ≥ entry−2, no falling band; replacement must not be prohibitively underlevelled. `five_slot.max_catch_level_deficit=2`, minimum six wild options. | PROGRESSION retains constraints; stale 3→8→10→13→16→20 table replaced by source 3→9→12→15→17→21. Record source violations before retuning. |
| S10 | same | Older 'no type chart', 'no feeding', and empty-band claims are not current deficiencies. | Explicitly superseded by type_chart, creature_condition and actual band data. No duplicate implementation lanes. |
| S11 | `MEADOWS_VERTICAL_SLICE.md`; progression spec §§3,17–18 | Meadows must be the first complete game; D42 compresses 4–7h to 3–4h through XP, rewards, materials, travel and density, not deleting bands or shrinking terrain. | GAME_BIBLE/PROGRESSION/WORLD retain four chapter pacing as target, not certification. |
| S12 | `OPENING_SEQUENCE.md` | Door cannot skip Grandpa; in-fiction automatic intervention, not an error toast. Mandatory starter naming and in-conversation orb previews supersede physical outdoor choice. | UX retains. Other two starters' 'visible afterwards' prose conflicts with modal implementation and earlier text; treat visible aftermath as unbuilt dressing, never wild/trainer availability. |
| S13 | same | Opening gift movement once silently deleted healing supplies. Four gift components, tutorial landed-throw conversion, orb floor and faint recovery are separate anti-deadlock guarantees. | UX/CREATURES/ACCEPTANCE retain all; cite `opening.json`, opening dialogue, `test_tutorial_faint_floor.gd`, `test_opening_healing_kit.gd`. Intro-only guarantees expire at first catch. |
| S14 | `C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` R1-1–6 | Terrapup ride mid-Meadows, Galewisp Fly later, Ripplet Teleport later; choice captions visible before confirmation. Burrowback/Tuskroot mounts, not Mudsnout/Ashtusk. Generic saddle, no saddle born on mesh, rider visible; offsets measured. | CREATURES/SYSTEMS/UX retain promise; current Fly capability mismatch is integration debt. Obsolete 'no later biome code' fences superseded by four-chapter authorization. |
| S15 | C1 R1-7–8 | Galewisp Scout at four overlooks (300m reveal; no movement); Ripplet active Water-catching affinity +0.15 were explicit early compensation proposals. | Deliberately drop both from minimum scope in CREATURES: third combat skills provide immediate distinct play, while catch affinity would distort catch economy. Preserve later traversal promise and flag this disagreement. |
| S16 | C1 R1-9–13, §6 | Each starter needs a favorable and unfavorable gatekeeper matchup. Riding cannot bypass physical gates; same jump ceiling, no ride stamina, saddle persists on deployed equipped animal. | COMBAT/SYSTEMS/ACCEPTANCE preserve gate and starter checks. Do not preserve obsolete test assertion that Fly can never exist anywhere. |
| S17 | `C2_TASK_FEED.md` T1–6 | Finite flag-derived tasks, surfaced once, counters/rewards exactly once, pins derived rather than authoritative, one main story line, one transient event queue, no generic branching quest engine. | UX/SYSTEMS preserve semantics, mark broad task-feed generalization partial/not built. Existing later-biome conversations may require acceptance/return; do not silently delete their earned flags. |
| S18 | C2 T7 | Four relay shutdowns: Quarry/Dorn, River/Vance, Ridge/patrol, Approach/Corr; each heals only own station group; Hall owns far approach and stronghold. Do not add duplicate guards. | WORLD retains as authored optional/critical progression with existing source status; visible local payoff required. Never count decorative machines as four complete activities. |
| S19 | C2 T8–12 | 31 battle-entry tally is not 31 distinct people; alpha tally 16 sites plus Warrens; caught OR beaten counts. Sigil pins carry no second reward; resource surveys count permanent nodes; camps require actual site-specific rests. | WORLD/PROGRESSION/UX retain correct accounting. Count generated from source IDs; no copied stale denominators. No candy from counters. |
| S20 | C2 §§2.7,5–7 | Local request migration must preserve flags/rewards; density precedes pins; tasks do not gate main path; no repeats, timers, abandon/fail, indiscriminate unseen pins. | UX/WORLD preserve. Scope down surveys/camp checklist before quality if needed; do not require an extra generic framework before adding authored content. |
| S21 | `C3_VILLAGE_REPLAN.md` V1–7 | Houses form a street; berry field/grove/stone yard; at most five street villagers, Grandpa indoors; redistribute cast, don't delete. Tam receives hammer before construction rung. | WORLD/UX retain. Specific old target coordinates are survey intent, not authority over current verified placements. |
| S22 | C3 V5,V8–10 | Preserve opening anchors, tournament consent/readiness and physical gate clearance. Prompt substring selection, fence geometry, source stock and gather approaches once caused hidden failures. | TECHNICAL/ACCEPTANCE retain regression dependencies; tests should ultimately identify stable IDs rather than force all future dialogue to avoid words. No route can be deemed repaired from teleport placement alone. |
| S23 | C3 §§5–8 | Flats/path/apron changes require affected terrain bake, other placement edits do not; probes precede coordinates; one coherent bake rather than stale mixed config/binaries. | TECHNICAL/WORKFLOW retain bake/provenance discipline; stale bake-duration estimates are not present scheduling guarantees. |
| S24 | `C4_CAMPING_NECESSARY.md` N1 | Owner requires camping to matter, expressly forbids solving it by faster hunger, thirst, cold or fatigue meter. Player drain0.8/min; creature1.1/min. | SYSTEMS retains exact satiety baseline and attrition/recovery purpose. |
| S25 | C4 N2–7 | Proposed strain ceiling, damage0.20/faint0.25/revive0.10/cap0.40; capped shops, night upper-half levels/aggro×1.5/strain×1.5, unrested×1.25, rest XP5% cap40, hatching HUD. These are absent from baseline condition/instance. | Do not claim built. SYSTEMS deliberately replaces stacking penalties with one bounded injury rule and visible rest benefit; no night/unrested multiplication, no passive XP farming. Explain why repetitive recovery is not attachment. |
| S26 | C4 N4,§10 | ≥120% lead HP damage per road leg and ≥24% strain were proposed camping proof; evidence clause inconsistently expects an unbedded team to arrive whole while N6 forbids healing unbedded HP. | Drop these forced-damage/inconsistent acceptance targets. ACCEPTANCE measures actual rest choices, time and understood reasons; keep physical beds meaningful. |
| S27 | `COMBAT_DEPTH_PLAN.md` §§1–4 | Lost original rungs include Y geometry skill, level4 learnset, reactive charged/skill AI, per-species wind, and player-side commitment. Poise/wind/burst implementation alone does not prove a reader beats mashing. | COMBAT/CREATURES/ROADMAP restore third-skill/AI requirements as unbuilt and keep exact built timings separate from target retunes. |
| S28 | combat plan §§4–9 | Proposed loud type1.5/.67 conflicts with existing type-chart rationale and compounded 2× TMs. Owner had open decisions; later burst approval does not approve every proposal. | COMBAT deliberately retain1.25/.80 initially; reward reads through shapes, punish windows and feedback. Rebalance only after actual roster/pilot evidence. Restore reader≤55% masherHP, reader≥75% top-fight success, no entry singlehit≥50% as test targets with honest sampling. |
| S29 | `MEADOWS_PROGRESSION_SPEC.md` §§6,12 | Original6–10 optional activities was **per first biome**, and ~12–17 trainer battles; later docs escalated to6–10 per major region without a content budget. | WORLD/PRODUCT/ACCEPTANCE deliberately define one chapter total, with regional minimum coverage and meaningful payout, not 138–290 shallow errands. Actual31 Meadows battle rows supersede old trainer estimate. |
| S30 | progression spec §§1,20–22,36 | Earlier demanded black-silhouette differentiation becomes impossible when rerenders prohibited. Humanoid palette example green was superseded by oxblood faction language and installed cast. | ART_DIRECTION explicitly retain current owner/reference policy, no silent adoption of obsolete scales/green uniforms. |
| S31 | `archive/docs/CURRENT_STATE.md` §0 capability ledger and Wave5 | Dynamo/Stormheart/Water entry and named Water spawns/HUD are landed; live STATE says unbuilt/held. Levelcap100 and sizes1.90–7.20 documented historically and found in source. | STATE/TECHNICAL correct. Synthetic L44 chapter fixtures prove bounded routes, not earned fresh campaign. |
| S32 | CURRENT_STATE §§0,3–5 | Fresh paths failed on aim state, competing interaction providers, beds, guardian combat, quarry collision; copied saves and CI greens repeatedly overclaimed. Gates/tasks complete could still fail experience acceptance. | STATE retains unresolved earned path; WORKFLOW/ACCEPTANCE distinguish built, integrated, proven, accepted. Do not resurrect every old symptom as a current defect. |
| S33 | CURRENT_STATE §0 and §4 | Realm lifecycle, finalized-death withdrawal, delayed reward acceptance, carried portable gear, save rollback, reconnect and cached HUD providers have real regression histories. Loading once336s; terrain support/body scale invalidated paper ROAD proofs. | TECHNICAL/ACCEPTANCE preserve save/realm/identity and physical-route checks; performance numbers historical, not current benchmarks. |
| S34 | CURRENT_STATE visual checkpoints | Numerous grass/material/geometry candidates withdrawn after ties/regressions; no full commercial visual or Ally acceptance. Fixed footprint, real camera/frustum and terrain line of sight matter more than adding bodies to a catalogue. | ART_DIRECTION/ROADMAP require controlled motion evidence and stop repeated unproductive global tint/scatter experiments. |
| S35 | CURRENT_STATE §4 | Fresh vs occupied saves, input modals, fixed inventory slot assumptions, docs-only green CI, rescued retries and stale packages are known evidence traps. | WORKFLOW retains one-confirming-run rule, actual job/log review and exact package identity. Test origin failure, not only last assertion. |
| S36 | CURRENT_STATE §5 | Gate2 seeded S03 continuation1169s/2360m had bounded presentation/roster-pressure failures; Ironwood freeze was an old walker bug already fixed in main, not automatically terrain. Pond analogy not rerun. | FINDINGS retains historical evidence limits; never use these numbers as four-chapter hours or re-open a repaired navigator from prose. |

Root full-read coverage: `GAME_DESIGN.md`, `MEADOWS_PROGRESSION_CURVE.md`, `MEADOWS_VERTICAL_SLICE.md`, `OPENING_SEQUENCE.md`, `COMBAT_DEPTH_PLAN.md`, all four C1–C4 contracts, `MEADOWS_PROGRESSION_SPEC.md`, and all1,270 lines of `CURRENT_STATE.md`. Remaining full archive coverage follows in the delegated sections. Source comments are included in recovery but may be stale; executable readers decide built status.

## Recovery: decision records

<!-- DECISION_RECOVERY -->

## Recovery: owner directives, art and performance

<!-- OWNER_RECOVERY -->

## Recovery: biome contracts and world specifications

<!-- BIOME_RECOVERY -->

## Recovery: multiplayer specifications

<!-- MP_RECOVERY -->

## Final validation and unresolved approvals

<!-- FINAL_VALIDATION -->
