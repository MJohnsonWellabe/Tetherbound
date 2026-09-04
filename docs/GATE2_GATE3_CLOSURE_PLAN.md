# Gate 2 and Gate 3 closure plan

**Status:** written 2026-09-04 by the G3-CLOSURE-PLAN lane (Fable, read-only on code,
data, assets and tests), from `ralph/G3-LAND-0904` at `e902ab04`. It answers one
question: **what has to be true for Gate 2 and Gate 3 to be called done, and in what
order does the remaining work get there?** It sits under `docs/ROADMAP.md` (the
acceptance authority for both gates) and `docs/GATE3_EXECUTION_PLAN.md` (who is doing
what on which files), and it does not replace either. Where it contradicts something
written down it says so and says why; the full list is in
`ralph/reports/G3-CLOSURE-PLAN-0904/REPORT.md`.

Precedence is `CLAUDE.md`'s. Nothing proposed here violates a hard rule; where closing a
gate would need something a hard rule forbids (a new mesh, a Meshy generation without
owner reference art), the item is put in §4 for the owner instead of being smuggled into
a lane.

Every item has an id (`CL-…`) so a lane can cite it. Every acceptance criterion carries a
**fails if**. Sizes are relative: **S** = hours for one agent, **M** = one lane session,
**L** = several sessions or real render time, **XL** = art or an owner decision.

The standard this plan is held to is the one both gates are held to: **an honest fail
with a scoped task list is worth more than a manufactured pass.** Both gates fail today.
That is the first time either has had real evidence, and it is progress.

---

## 0. The three kinds of "not done", and why the distinction runs the plan

Every open item below is one of:

- **Not done.** Nobody has built it. Work is authoring.
- **Done but unproven.** Code and data exist and pass their own tests; no played path or
  blind judge has confirmed the player-facing result. Work is evidence, and the evidence
  may come back as a fail. Most of Gate 3 is here.
- **Proven failing.** A played path or a blind judge answered no. Work is a fix, then the
  same evidence again. Gate 2's presentation clause is here.

They are ordered by risk, not by effort. "Done but unproven" is the dangerous one,
because the repo's own history (`archive/reports/GATE_F_RUN_3_FINDINGS.md`) shows five
segments of "evidence" that described one harness defect, and this week's round of Gate 3
lanes produced four segment runs whose fails resolve to harness defects again. The plan
therefore front-loads the instrument (§3, stage 1) before spending anything on evidence
that the instrument would corrupt.

---

## 1. Where each gate stands

### 1.1 Gate 2 — village → Pond → South Bridge

`docs/ROADMAP.md` Gate 2 has three acceptance clauses and a checkpoint. Against each:

| Clause | State | Kind | Evidence |
|---|---|---|---|
| Blind judge, Bar A yes / Bar B "same kind of game", remaining gaps named as art-not-in-build | **not met** | proven failing (four passes: MID-LAYER, TREE-SILHOUETTE, its after-fix pass, 2.8's route pass; all no / no) | `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`; ROADMAP §Acceptance status note |
| Evidence template PASS; no dead-travel interval over ~60 s that is not intentional | dead travel **met** (63 s and 71 s, both classified intentional, none over 75 s); template **FAIL** on presentation and on 2.5's roster-decision clause | proven failing on two fields; the dead-travel classification is a Fable judgement at the top of the range and should be re-read after 2.13's bridge work makes the second interval an approach to something | 2.8 §2, §5; `CURRENT_STATE.md` §5 |
| Perf proxy within budget; the owner's Ally frame-rate check | proxy **met** (`band1_open` 6,891 draws / 10.79 M primitives against 7,500 / 12.0 M); Ally check **open** | met / owner-only | 2.8 §3; `CURRENT_STATE.md` §3 P0 (owner, hardware) |
| Checkpoint: tag `gate2-candidate`, `VISUAL_BIBLE.md` gap list updated | not done | not done | — |

**Fails if** any lane tags `gate2-candidate` while the blind-judge clause stands as
written, because the clause as written cannot be moved by the gate's tasks (§5). The
correction in §5 is what makes the tag reachable at all.

Task status, 2.1–2.16:

| Task | State | Kind | Owner now |
|---|---|---|---|
| 2.1–2.7 | landed | done; 2.4 and 2.7 measured, 2.2/2.3 judged no / no | — |
| 2.8 evidence run | done, verdict FAIL | proven failing | — |
| 2.9 Pond walker | open | proven failing (harness, world exonerated by `probe_pond_stranding.gd` 0/10 wedged) | G3-HARNESS |
| 2.10 post-tournament recovery beat | open | not done (design), partly directed by the owner 2026-09-03 ("give revives after the tournament") | G3-OPENING-FIX (Fable contract needed) |
| 2.11 revived creature not re-deployed | open | proven failing in the harness; player-facing or not is unconfirmed | G3-OPENING-FIX |
| 2.12 one roster decision on the Band 1 route | open | proven failing (mid-fight rotation only; no catch, no keep-or-release) | G3-BAND1-FINISH (Fable contract needed) |
| 2.13 props, palette, terrain form, the bridge | open | proven failing (judge-named, itemised) | G3-BAND1-FINISH; the needs-art half is §4 |
| 2.14 stale trace thresholds | open | proven failing (instrument) — `S04.json:858`, `S05.json:1221` still carry 1,200 / 3,000 | G3-HARNESS |
| 2.15 the evidence pipeline cannot show a creature | open | proven failing (four passes) | **nobody** — not in `GATE3_EXECUTION_PLAN.md` §6, and it gates every visual verdict in both gates (§3) |
| 2.16 Bramblebun candy pink, day and night | open | proven failing (measured at night; judge-named by day) | G3-CREATURE-COLOUR |

### 1.2 Gate 3 — bands 2–5 and the finale

`docs/ROADMAP.md` Gate 3's acceptance per band is: evidence template PASS; the finished-
region checklist in `docs/GAME_VISION.md` §8; a blind judge per band. Its own §1 of
`GATE3_EXECUTION_PLAN.md` corrects the segment range: Gate 3 is S06–S10e, not S04–S10.
Gate 3 also inherits Gate 2's standard per band.

| Band / segment | Played? | Verdict | Kind | What the run actually established |
|---|---|---|---|---|
| Band 2 / S06 | yes, synthetic entry (`build_s06_entry_synthetic.gd`) | 78 P / 17 F / 11 delegated, **FAIL** | done but unproven | rootstone gather, quarry walk, Warrens walk and entry all PASS. The 17 fails are two root causes: `S06-22`'s blind `combat_quick ×34` block wiped the party against Dorn and the body walked into the Warrens fainted (death satchel, reset to the bridge); and `build_catalogue` never released input after a workbench interact `S06.json`'s own `S06-30` comment calls a transcriber's invention (Band 2 has no crafting site). Guardian G-9 data authored; **the guardian fight with its profile has never been played**, because G-2 landed after S06 ran. |
| Band 3 / S07 | yes, synthetic entry (`build_s07_entry_synthetic.gd`) | 90 P / 20 F / 9 delegated, **FAIL** | done but unproven | Kest fight and the walk to Hess PASS. 17 of 20 fails are one cause: `S07-32`'s blind `combat_quick ×34` block ran out with Hess's Mudsnout alive, combat never ended, and the party was ground to 0 HP standing still. **V-1/V-2/C-1 are applied and have never been seen in play.** `S07-26` asserts `the_long_water` at a point 700 m from that region. |
| Band 4 / S08 | yes, synthetic entry (`build_s08_entry_synthetic.gd`) | stopped at Oreth, **FAIL** | done but unproven | crossing → grove → two catches → saddle and `orb_prime` crafted → mounted, ridden, dismounted → the ridden leg to Halder all PASS. The lead fainted in the wild Meadowhart fight and no step switches or revives, so Halder and Oreth were "fought" by a fainted creature and `combat_quick` outside combat opened the Build catalogue, which never closed. **C-4/C-5/C-7 applied, never seen in play; Vess and the Sigil gate never reached.** |
| Band 5 / S09 | yes, synthetic entry (`build_s09_entry_synthetic.gd`) | 79 steps, 14 F, **FAIL** | done but unproven, with one real visual PASS | Corr's dialogue never handed off to combat (`narrative_modal` held; the same press-count shape S02's own notes record); `S09-33`'s `move_to` drove into `sigil_gate_gorge_west` and pinned there. **P-5.1 (the Hall grows) PASSED a blind judge** on a real 12-frame capture — the only Gate 3 visual verdict that exists. Dead travel 63 m over 651 m from `_probe_band5_approach.gd`, not from S09. R-3 and Ness's CURRENT authored (live now that G-2 is in). |
| Finale / S10a–e | **no** (frame budget: hours per sub-segment) | none under the protocol | done but unproven | `smoke_gate_e_finale.gd`, `smoke_stronghold.gd`, `smoke_stronghold_reload.gd` and the new `smoke_finale_persistence.gd` (three real save/load windows) all pass. W-1/W-2/W-3/W-7 applied and re-verified by the same smokes. The Warden measured 38–101 % longer than Hald before W-1. W-4 open. |

**The general-mechanism finding is closed.** G-2 (per-body `combat` override merged in
`wild_creature.set_engaged()`) landed on this branch at `4444381e` with
`tests/test_encounter_combat_override.gd`. That answers the encounter contract's §9
question 5 by implementation rather than by ruling. Every `combat` block authored in
round one is live: the guardian (G-9), Vance's Tuskroot (V-2), Halder and Vess (C-4/C-5),
Ness, the R-3 doorstep alpha, Hald (W-7) and the Warden's five (W-2). **None of them has
been played through a fair fight.** Oreth's C-3 (Mosshell WALL, Brooktail CURRENT) is
**not** authored — `band3_the_river_lock/trainers.json`'s `captain_riverwatch` carries no
`combat` on any member; G3-BAND3 and G3-BAND4 each recorded it as the other's.

**The chapter chain** (`ralph/reports/gate-f-run-g3-20260904T001916Z`, main at
`3c73aab5`, no Gate 3 lane on it): S01 13/13; S02 77/5; S03 475/38 **with an exit save**,
past where run 3 died; S04 50/21. Read the S04 number with two caveats, not one:

- the coordinator's own note — S04 ran the pre-2.8 script, which walks to a marshal
  coordinate already satisfied from the bracket board and never signs in (2.8 §4.1);
- **and** the S03 exit it loaded is not a healthy S04 entry: `S03-39` party size 4 (wanted
  5), all twenty training rounds failed to reach a wild Bramblebun (`S03-51n*a`, the prompt
  under the thumb was "Gather deadwood" or "Put Bramblebun away"), the home-site walk
  stopped 31.4 m short at (−10, 1, −9) so `home_built`, `player_slept_at_home` and
  `tournament_team_fed` never set, and `S03-223` found no `player_bed.gd` node in the
  world. S04's `tournament_training_ready` / `tournament_condition_ready` / `tournament_entered`
  NOT-set fails follow from that entry state whatever script ran.

So the chain's S05 onward, if it continues from this S04 exit, carries no `tournament_won`
and will not be quotable either. The chain has answered "does S03 write an exit save
now" (yes) and has not yet answered "is there a healthy S03 → S09 chain" (the question in
its own `RUN_METADATA.json`). That question is still open and is `CL-R1`.

**The Gate 1 dependency, stated plainly.** Gate 3's "does the chapter play" runs through
S02 and S03, which are Gate 1's segments. S02's five fails are the second orb throw
(`S02-43d/f/h`: three `interact` presses never re-enter `combat_aim`; the GAME-12 shape
from run 3, never root-caused) plus a stale row threshold; S03's 38 are the three
clusters above. Gate 1 is not this plan's gate, but nothing in §3 stage 4 can happen until
those two segments hand over a five-creature, home-built, slept party. G3-OPENING-FIX owns
the throw; nobody in §6 owns the S03 training-walk and home-site walk fails (`CL-H6`).

### 1.3 The `GAME_VISION.md` §8 checklist, per band, honestly

Fourteen items per region. On the current evidence, every band's *data-side* items
(geography, reason to enter, ecology, temptation, gathering, trainers, discovery,
memorable encounter, camp, transition) are verified by config, tests and probes for bands
2–5 and read as met by the lanes. Three items are not closable that way for any band:

- **no long purposeless travel stretch** — measured by probe for Band 5 (63 m) and by the
  D70 census for bands 2–4 (165 / 163 / 156 m worst gaps); **not measured by a played
  segment for any Gate 3 band**, because every segment was corrupted before its
  dead-travel meter could run clean (S06's 615 m peak is the death-satchel re-walk; S08's
  549 m is a transcribed backtrack a real player would not walk);
- **day/night readability** — no Gate 3 band has a night frame judged; Band 5's capture
  has night frames and the judge's only note was cloud texture;
- **acceptable target-hardware performance** — owner-only for every band (§4).

"It must also pass a continuous playthrough from the prior gate to the next gate" — no
band has. That is the sentence Gate 3 is graded on and it is why every band is "done but
unproven" rather than "done".

---

## 2. The complete remaining work, deduplicated

Grouped by what kind of work it is. Where two places claim an item, both are named.
"Source" cites where the finding lives; "Claimed by" says which round-two lane §6 assigns
it to, or **unassigned**.

### 2.A The instrument — gates every evidence run (§3 stage 1)

| Id | Item | Source | Claimed by | Size | Kind |
|---|---|---|---|---|---|
| CL-H1 | **Blind press blocks in every Gate 3 segment.** `S06.json`, `S07.json`, `S08.json`, `S09.json` contain zero `fight_until_resolved` steps; every trainer and wild fight is `press combat_quick, times: N`. `SEGMENT_SCHEMA.md` names this failure mode. S06 (Dorn), S07 (Hess), S08 (wild Meadowhart) all derailed on it. Re-script every fight step in S06–S09 with `fight_until_resolved`, a post-faint switch or revive by item identity (never slot), and a party-health assert before each trainer challenge. | G3-BAND2 addendum; G3-BAND3 §4b; G3-BAND4 addendum | G3-HARNESS names only "S08 has no post-faint switch or revive" — **S06, S07 and S09 are not in its brief** | M | proven failing (instrument) |
| CL-H2 | **Dialogue → combat handoff by press count.** Corr at S09 (`narrative_modal` held), and the same shape recorded un-answered in S02's superseded runs. Replace fixed press counts on every `battle:`-effect conversation with advance-by-predicate, the way 2.8 rewrote S04's rounds (greet → predicate → greet → `fight_until_resolved`). | G3-BAND5 S09 §1; 2.8 §4.2 | unassigned | S–M | proven failing (instrument) |
| CL-H3 | **The walker.** Three defects in `tests/helpers/stick_navigator.gd`: cannot leave the Pond basin on a long uphill bearing (2.9, world exonerated); cannot round the `village_boundary` concave corner past TrailGate (`CURRENT_STATE` §3 P2, 79 side-flips in 133 s); and `move_to` drives straight into `sigil_gate_gorge_west` instead of the causeway (S09-33, the same trap S10c/d hit on the return leg). `RUN_METADATA.json` for the chain says `ralph/FENCE-CORNER-0903` fixed the corner; **no such branch or commit exists on `origin` today** and the file's last change is 2026-08-31. Treat the corner fix as lost. Fix all three in the walker, never by teleporting past geometry (2.9's own rule), and re-run `probe_pond_stranding.gd`'s ring unchanged as the guard. | 2.8 §4.4 / §7; `CURRENT_STATE` §3; G3-BAND5 S09 §2; `HANDOFF_2026-09-03.md` §4 | G3-HARNESS (2.9 only) | M–L | proven failing (instrument) |
| CL-H4 | **Stale route-row thresholds** (2.14): `S04.json:858` wants 1,200 rows, `S05.json:1221` wants 3,000; S02-60 wants 900 of a segment that wrote 565. Re-derive all three from real play clocks at 2 Hz. | 2.8 §4.7; chain S02 | G3-HARNESS (S04/S05 only; S02 is new) | S | proven failing (instrument) |
| CL-H5 | **The freeze-record trap.** Every isolated logic-lane run refuses to start unless a run-local `RUN_METADATA.json` declares `lanes.logic.display_server` as headless; three lanes and the coordinator each lost a launch to it. §4b of the execution plan documents the workaround. Cheapest permanent fix: `run_segment.sh` writes the lane declaration itself when invoked in logic mode, so the harness's `_freeze_display_claim()` finds it; do **not** edit the tracked 2026-08-27 record. Also fill `suite_state_at_freeze` truthfully every time. | `GATE3_EXECUTION_PLAN.md` §4b; all four band reports | unassigned | S | proven failing (instrument) |
| CL-H6 | **S03's three failure clusters** (chain S03, 475/38): (a) twenty training rounds never reach a wild Bramblebun and the live prompt is a gather node or "Put … away" — the walk targets a species, not an individual, and a companion standing in the way wins the prompt; (b) the home-site walk to (−6, −40) stops 31.4 m short at (−10, 1, −9) with "0 held" — which, per GAME-10's own lesson, does not mean the body was free to move; (c) `S03-223` finds no `player_bed.gd` node although `S03-205` says the creature bed stands, and `S03-224`'s prompt is "Engage Mudsnout". Root-cause each against the world (a real player at the same spots) before touching the script. Until S03 hands over five creatures, a built home and a sleep, no S04 onward is quotable. | chain S03 notes | unassigned | M | proven failing (instrument or game, undecided) |
| CL-H7 | **`S07-26` region assert** — `the_long_water` asserted at (150, 3500), ~700 m from the region's centre near (−150, 4200). One-line fix. | G3-BAND3 §4b | unassigned | S | proven failing (instrument) |
| CL-H8 | **`S06-30`'s invented workbench beat.** Band 2 authors no crafting site; the step exists because a transcriber added one. Either remove the beat from S06 or, if the `build_catalogue` context genuinely fails to release after a workbench interact, that is a game defect in shared UI (`build_menu.gd` / `craft_panel.gd` / `game_menu.gd`) — S08 hit the same stuck context by a different route, and run 3's GAME-3/GAME-4 recorded the catalogue's focus and context oddities. Decide which with one live probe before either lane spends a session. | G3-BAND2 addendum root cause 2; G3-BAND4 addendum; run 3 GAME-3/4 | unassigned | S to decide, M if game | undecided |
| CL-H9 | **The evidence pipeline cannot show a creature** (2.15). The capture lane teleports to a traced position and never restages: no deployed companion, fight frames with no fight, level-up frames with no event. Four blind passes in a row have been unable to see the thing the game is named after. Make the capture lane stage what it photographs (deploy the companion after load, capture a fight frame inside a fight, nameplates where the game has them) and reject a frame that fails a "creature at readable size beside the 1.80 m trainer" check the way `.gitignore`'s evidence rule already rejects grass-less frames. | 2.8 §8.2, ROADMAP 2.15; `MEADOWS_EXIT_CRITERION.md` evidence rule | **unassigned** | M | proven failing (instrument) |
| CL-H10 | **Capture lanes S06C–S10cC have never run.** Every Gate 3 segment delegates its §G frames; the debt is real (`tools/gate_f/run_inventory.py`). Not runnable honestly until CL-H9 lands. | chain `RUN_METADATA.json`; every band report | unassigned | L (xvfb render time) | not done |
| CL-H11 | **S10 cost.** Run 3's S10 was refused by the harness's own cost gate at 0.097 s/frame; G3-FINALE priced S10c alone at 3,530–10,388 s. The finale segments need a faster host or a further split; nothing else in this plan can make S10a–e affordable. | run 3 §S10; G3-FINALE addendum 2 | unassigned | L | not done |

### 2.B Game defects found by playing, not yet fixed

| Id | Item | Source | Claimed by | Size | Kind |
|---|---|---|---|---|---|
| CL-G1 | **The second orb throw never leaves the hand** (GAME-12 / RIG-26): after a failed catch, `interact` does not re-enter `combat_aim`. Reproduced in the chain's S02 with 13+ orbs. Root-cause with a live probe of `probe_s02_encounter.gd`'s shape; the three candidate causes are named in run 3. This is the mechanism `max_catch_failures: 1` depends on, so it is the opening's stated forgiveness that is broken. | run 3 GAME-12; chain S02 | G3-OPENING-FIX | M | proven failing |
| CL-G2 | **A revived creature is not re-deployed** (2.11): both Band 1 fights refused to start on a fully healthy party until a `creature_recall` press was added. Confirm in the shipped game; if real, it is a trap the refusal line ("a bed will do it, or something to eat") makes worse. | 2.8 §4.5 | G3-OPENING-FIX | S–M | proven failing in harness |
| CL-G3 | **Post-tournament recovery is not a designed beat** (2.10): three of five on 0 HP with ten Revives in the satchel and nothing in the chapter picks the team up. The owner's 2026-09-03 instruction ("give revives after the tournament") is implemented in the harness as a menu block, not in the game. Needs a Fable contract choosing among: the champion beat restores the team; Halda or Mira provide recovery; the Trail Camp is the authored stop. Make `no_usable_ally()`'s line name the real reason. | 2.8 §4.6 / §7 | G3-OPENING-FIX (Sonnet implements; the contract is unwritten) | M | not done (design) + proven failing (line) |
| CL-G4 | **Tutorial catch unstable across KO / re-engage rounds** (`CURRENT_STATE` §3 P1): two different failures on consecutive runs of one commit; the chain's `known_open_defects_at_freeze` names it as the single most likely thing to end a chain early. Related to CL-G1 and CL-H6(a) by mechanism; one root cause may close all three. | `CURRENT_STATE` §3 | unassigned (OPENING-FIX by adjacency) | M | proven failing |
| CL-G5 | **`stronghold_occupation.gd` never reacts to `legendary_freed`.** The Hall's exterior garrison dressing (braziers, work-lamps, checkpoint camp) is placed once and never withdraws or goes dark; `meadow_healing.gd` touches lit tether fittings and named beaten trainers only. A11 ("the world looked changed because of what I did") is weaker for it. | G3-FINALE §5 | unassigned (BAND5 file) | S | not done |
| CL-G6 | **The Riding Saddle does not cost Ironwood.** `recipes_rootstone.json`'s `saddle` is rootstone 3 / wood 4 / fiber, with its own `_comment_ironwood` spelling out the one-line change to make when SF31 lands. SF31 landed. Spec Band 4 and prompt 65 both say "Rootstone and Ironwood". | G3-BAND4 §"not this lane's file" | unassigned (G3-ECONOMY's neighbourhood) | S | not done |
| CL-G7 | **`material_get_instance_shader_parameters` null-material error** during guardian dressing (`burrow_warrens.gd:2957` → `creature_body.gd:492`), seen by four lanes, chased by none, non-fatal in all. Cheap to chase; it opens every headless world boot's log with an engine error, which is exactly what hid the title-screen null call for weeks. | every band report; `GATE3_EXECUTION_PLAN.md` §6 | coordinator, unrouted | S | undecided |
| CL-G8 | **Band 2 and Band 4 wild ceilings sit below the corrected team entry** (8 vs 9; 14 vs 15). Every wild in the band is weaker than the team on arrival, not just by exit. Still inside `max_catch_level_deficit: 2` by a margin of one. G3-ECONOMY flagged and did not act because BAND2/BAND4 were authoring against those numbers. Decide `wild_band` per band now that round one is landed; D69 (the band widens from the bottom) is the rule to apply. | G3-ECONOMY §1 | unassigned | S | not done (tuning) |
| CL-G9 | **The pacing probe says the chapter is OVER the 3–4 h target** (4.71 h projected, D42). Gate 4's charter, not this plan's, but it is the exit criterion's K1 and nobody has budgeted for it. Recorded so a corrected Gate 3 curve is not read as a solved pace. | G3-ECONOMY §1 | Gate 4 | L | proven failing (against D42) |

### 2.C Gate 2's residual — Band 1 composition and presentation

| Id | Item | Source | Claimed by | Size | Kind |
|---|---|---|---|---|---|
| CL-B1 | **One roster decision on the Band 1 route** (2.12): site the temptation creature so the direct route meets it, then record a catch or a considered refusal in the template. Needs a Fable contract (which creature, where on the spine, what it costs). | 2.8 §5; ROADMAP 2.12 | G3-BAND1-FINISH | S–M | proven failing |
| CL-B2 | **2.13, scene half — no new art.** Grow the trees to 12–18 m and fix the trunk ratio (grow, never shrink); cluster the tree line with clearings and a mouth, ≥3× scale variance per family; drift the flowers; pull the grass highlight off lime; **re-reserve the red family** — oxblood off village roofs, tree trunks and friendly HUD icons, back onto Team Tether; push the fog far plane out; a shadow decal with canopy shape; stop the camera rendering from inside a bush at (−333, 510); Halda's plank/torso intersection; the terrain-blend seam at the bridge; the orphan fence segments; the mill's sails or its name; signposts; the smooth dome hill; water shading. **Tree height, clustering and the dome hill are bake inputs** (`vegetation.json`, `terrain_playground.json`) and so are proposals for the coordinator's single re-bake, not lane edits. | 2.8 §8.3; JUDGE §8; ROADMAP 2.13 | G3-BAND1-FINISH | L (several slices; each slice re-judged on the same sixteen stands) | proven failing |
| CL-B3 | **2.13, needs-art half.** A built South Bridge with Team Tether presence (gate, barricade, oxblood banners, a guard — the chapter's first physical gate renders as a bare plank frame on a grey deck); one Meadows landmark to navigate by; tree meshes with branch structure below the canopy; combat and reward VFX; distinct NPC silhouettes; facial detail on the trainer. Costed in §4, not attempted here. What *can* be attempted inside the hard rules: the bridge dressed from the installed village family, Team Tether prop kit and the grunt rig (banner, barricade, a posted guard), and the installed `watchtower_landmark.gd` silhouette sited where Band 1's far plane needs one. | JUDGE "not fixable by scene work"; ROADMAP 2.13 | G3-BAND1-FINISH names "the South Bridge is visually unbuilt" without saying which half | M for the in-rules dressing; XL for the rest | not done |
| CL-B4 | **HUD** (from the first judge ever to see one): food bar outside a 5 % safe area; objective / action / interact hierarchy that does not separate; health-text contrast; the interact pill covering the object it names; the raw `--` in the objective line; the team panel visible in two of sixteen frames; the minimap carrying almost nothing. Owner 2026-09-03 item 8 (health and food stacked) was routed to HUD-INPUT-0903, whose report directory holds a contact sheet and no report, so whether it landed is unevidenced; G3-HUD should check the same file. | JUDGE §6; owner playtest 2026-09-03 | G3-HUD (first four) | M | proven failing |
| CL-B5 | **Bramblebun's palette** (2.16): `field_emission` 0.9 → 2.5 overshot by day (candy pink, judge) and by night (glowing blob, measured). Time-of-day scaling for `field_emission` / `field_degreen`, mirroring `creature_emission_floor`. Then re-measure Mudsnout / Terrapup / Burrowback against the 1.5:1 bar, which only Bramblebun has been measured against. | `CURRENT_STATE` §3; JUDGE §2; ROADMAP 2.16 | G3-CREATURE-COLOUR | M | proven failing |
| CL-B6 | **Gate 2's blind judge, re-run on the same sixteen played-route stands** after CL-B2, CL-B4, CL-B5 and CL-H9 land — with a companion deployed and a fight in the fight frame. This is the evidence the corrected clause (§5) is graded on. | 2.8 §8; ROADMAP acceptance | unassigned | M (render + judge) | evidence |

### 2.D Gate 3's residual — the encounter contract and the bands

| Id | Item | Source | Claimed by | Size | Kind |
|---|---|---|---|---|---|
| CL-E1 | **Oreth's C-3** — Mosshell WALL, Brooktail CURRENT — is not authored. Both band lanes recorded it as the other's. Owner: band 3 data (`band3_the_river_lock/trainers.json`, plus the `band_split_baseline` mirror in the same commit). | contract §4.2; BAND3 §2; BAND4 addendum | **unassigned** (fell between two lanes) | S | not done |
| CL-E2 | **C-2** — Oreth's stale `facing_deg` (−31.4 today; his own comment flags it) and a three-prop Riverwatch post at his stand. Band 3 data / props. | contract §4.1; BAND3 §8 | unassigned | S | not done |
| CL-E3 | **Every authored `combat` profile is unplayed.** Guardian WALL (S06), Vance's CHARGER (S07), Halder CHARGER/CURRENT and Vess DIVER (S08), Ness CURRENT and the R-3 alpha (S09), Hald DIVER/WALL and the Warden's five (S10). G-3's own **fails if** (two profiles indistinguishable to a blind tester; any profile one-shots a full-health entry-level creature) has never been scored. Needs CL-H1 first, then one played segment per band, then the three-sentence test (G-1) recorded in each band's template. G3-FINALE's "what the Warden's fight should feel like" paragraph is the check for S10. | contract G-1/G-3/G-9/V-2/C-3..5/W-2; every band report | the band lanes, after G3-HARNESS | M per band | done but unproven |
| CL-E4 | **W-4** — the Warden Arena's end wall and door dressed, ring kept empty, the Warden's silhouette re-measured at 16 m against 1.5:1. Needs xvfb render time and a blind judge. | contract §5.2; G3-FINALE addendum | G3-WARDEN-ARENA | M–L | not done |
| CL-E5 | **R-2** — the duty board at the waystop. `stronghold_climax.gd::_place_readout` must become reachable for a second config entry (G3-FINALE's file), then G3-BAND5 adds the readout and its conversation (text already drafted, checked against the spoiler test). Two lanes, one order. | contract §7.2; G3-BAND5 | G3-WARDEN-ARENA names "R-2 the waystop duty board" | S + S | not done |
| CL-E6 | **P-5.2** — the scorched pocket visible from the spine: one pylon spur or drained-ground tongue toward (121, 7336), the TM's glow and the Mudsnout's silhouette on the near edge. A `vegetation.json` / `terrain_playground.json` proposal → the single re-bake. | contract §6.4; G3-BAND5 | coordinator (bake) | S to author, then the bake | not done |
| CL-E7 | **R-4** — Team screen rows show the bond task line, `battles_fought`, `caught_on_day` and the Best mark. UI lane; all four fields exist on `creature_instance`. Without it R-7 (history against history at the ceremony) cannot be true. | contract §7.2 | unassigned | S–M | not done |
| CL-E8 | **The Warrens interior visual pass.** Owner 2026-09-03 finding 9 ("burrow warrens doesn't look good"); G-8 assigns it to "the Band 2 world lane", which does not exist in round two. `MEADOWS_EXIT_CRITERION.md` E5 calls the Warrens "the standing GOOD example; protect it" — the two disagree, and the owner's newer statement wins until a blind judge on real frames says otherwise. | owner playtest 2026-09-03 #9; contract G-8 | **unassigned** | M–L | proven failing (owner) |
| CL-E9 | **Per-band blind judge** for bands 2, 3 (after V-1's move), 4 and the Hall (W-4). Band 5 has P-5.1 only. Needs CL-H9/H10. C-6's **fails if** (three captain frames read as the same location) and G-5's (the opponent not nameable as unusual at 6 m) are the assertions. | ROADMAP Gate 3 acceptance; contract C-6, G-5 | unassigned | L | not done |
| CL-E10 | **The `_probe_band5_approach.gd` `03-mid-route` shot faces away from the Hall.** A capture-aim defect in a shared tool, flagged not fixed; costs one frame of P-5.1's sequence its meaning. | G3-BAND5 P-5.1 | unassigned | S | proven failing (instrument) |
| CL-E11 | **A refused Veridian goes nowhere** (R-8). Story decision, §4. | contract §7.3 | owner | XL (decision) then S | not done |

### 2.E Corrections to things written down (cheap, and leaving them open is worse)

| Id | Item | Where | Size |
|---|---|---|---|
| CL-D1 | `chapter_curve.json` band 2 `tuning`: "the band has no trainers of its own, which is prompt 59's gap" — it has four (`quarry_picket_dorn`, `warrens_watch_pell`, `band2_outrider_kest`, `night_watch_farro`). G3-ECONOMY owns the file and edited the same string without removing the sentence. | `data/config/chapter_curve.json:36` | S |
| CL-D2 | `docs/prompts/64` "Current empty Band 3 spawn data" and `docs/prompts/66` "Current empty Band 5 spawn data" — 54 and 23 clusters respectively (band 5's 23 is D70's crescendo, not a gap). Both prompts pre-date the reset; a one-line note each. | `docs/prompts/64-…:29`, `66-…:35` | S |
| CL-D3 | **G3-BAND3's report is not on the landing branch.** `65e1c939` merged the branch at a point before commit `8e5e2a9c` ("Report: Band 3 verified against prompt 64, Gate F S07 played and diagnosed"), so `ralph/reports/G3-BAND3-0903/` and its S07 run artefacts exist only on `origin/ralph/G3-BAND3-0903`. `GATE3_EXECUTION_PLAN.md` §6 says it was written "after a pass over all seven Gate 3 lane reports"; six are on this branch. Merge the branch tip. | `ralph/G3-LAND-0904` | S |
| CL-D4 | **The "two Warrens clearings waiting on the re-bake" claim is stale.** `band2_stone_and_root/vegetation.json`'s clearing entries last changed 2026-09-02 (`ca78933a`); both bakes were re-run for the merged config at `3c73aab5` (PR #29, 2026-09-03) under the freshness guards; nothing on this branch has touched a bake input since. The clearings are in the shipped bake. The in-file `_why` strings, G3-BAND2 §"Vegetation changes proposed", and §6 of the execution plan all still say "waiting". Correct the strings; keep the rule (one re-bake, after the merge, never before) for the *new* proposals: CL-B2's tree and terrain items and CL-E6. The same reasoning closes G3-BAND5's "terrain bake freshness for the drain stations is unconfirmed": `terrain_playground.json` last changed in the same #29 commit that re-baked terrain. | `vegetation.json` band 2 `_why`; BAND2 report; `GATE3_EXECUTION_PLAN.md` §6 | S |
| CL-D5 | `docs/CURRENT_STATE.md` §5 "Gate 3 / 4: not started" is stale by a full round; its Gate 1 paragraph carries two generations of text (lines 239–241 say "much closer" and then list the reds of the morning before). Rewrite both from this plan once round two lands. `docs/ROADMAP.md` Gate 3's "S04–S10" → "S06–S10e" per the execution plan §1. | `docs/CURRENT_STATE.md` §5; `docs/ROADMAP.md` | S |
| CL-D6 | `GATE3_EXECUTION_PLAN.md` §4's open questions, three of five now have answers: the Warden reads harder (measured, then W-1 raised him); the relay's escalation is V-1/V-2 applied but unplayed; Band 5 is not an empty corridor (26/30/22 creatures counted live at three eyes, 63 m worst gap). Record them. | `docs/GATE3_EXECUTION_PLAN.md` §4 | S |
| CL-D7 | `MEADOWS_EXIT_CRITERION.md` B2 says Bramblebun measures 1.08:1 (open); it is 1.568:1 since 2.4, and the open item is now the overshoot. B4 "no contact shadows" is closed by 2.4's contact ellipse. E5 vs the owner's finding 9, see CL-E8. | `docs/acceptance/MEADOWS_EXIT_CRITERION.md` | S |

### 2.F Evidence runs (the things that actually close the gates)

| Id | Run | Closes | Needs first | Size |
|---|---|---|---|---|
| CL-R1 | **S01 → S05 chain on the merged SHA**, healthy: five creatures, home built, slept, fed, tournament won, bridge earned by play. | Gate 1's proof-by-play; Gate 2's template (2.12's decision recorded; 2.10 in game, not a menu block); the premise of every Gate 3 chain claim | CL-H3, H4, H6, G1, G2, G3, B1 | L (S03 alone is ~30 min wall; the rest ~20) |
| CL-R2 | **S06, S07, S08, S09 each on its own synthetic entry**, re-run after CL-H1/H2 — "S0N, given a clean entry, does X", never "the chapter does X". Each fills the template, scores its contract **fails if** rows, records the three sentences (G-1). | each band's "does this band play"; CL-E3 | CL-H1, H2, H3(gorge), H5, H7, H8 | M per band, parallel |
| CL-R3 | **S10a–e** under the protocol, or an honest substitute the coordinator names (the smokes already cover the mechanism; the protocol run is what covers the *walk* and the frames). | the finale's "does this band play" | CL-H11; CL-E4 for its frames | L |
| CL-R4 | **The re-bake**, once, after the round-two merge, both bakes, then a CI run whose code jobs ran (35–45 min) and green freshness guards. | every vegetation and terrain proposal (CL-B2, CL-E6) | the merge | M |
| CL-R5 | **Capture lanes** S05C (Gate 2's sixteen stands) and S06C–S10cC, with CL-H9's staging, then one blind judge per band. | Gate 2's corrected clause (§5); Gate 3's per-band judge; C-6, G-5, P-5.2, W-4 | CL-H9, H10, R4 | L |
| CL-R6 | **The continuous S01 → S10e chain** on the SHA that carries everything above. Only it says whether the party arriving at Band 4 is the party the curve assumes and whether travel between bands is dead. | Gate 3's "does the chapter play"; the §8 sentence "pass a continuous playthrough from the prior gate to the next" | CL-R1, R2, R3 all PASS individually | L (the S10 cost problem included) |
| CL-R7 | **The owner's hardware pass** (§4). | the four [OWNER-ONLY] items in both gates' acceptance | a released build carrying CL-R4's bake | owner |

---

## 3. Ordering, with the dependencies named

Five stages. Inside a stage everything is parallel; between stages the arrow is real.

### Stage 1 — the instrument and the cheap corrections (now; disjoint files)

- **CL-H1, H2, H4, H5, H7, H8** — the Gate F step scripts and `run_segment.sh`. One lane
  (G3-HARNESS's brief widened to all of them, or a second harness lane; they are one
  file family).
- **CL-H3** — the walker. Same lane or its own; `stick_navigator.gd` is one file with
  three defects and one guard probe.
- **CL-H6** — S03's clusters, root-caused against a real body before scripting.
- **CL-H9** — the capture lane's staging. Independent of everything else in this stage
  and **the longest pole for every visual verdict in both gates**; start it now.
- **CL-G1, G2, G3, G4** — G3-OPENING-FIX (G3 needs its Fable contract written first; the
  owner's revive instruction bounds it).
- **CL-G5, G6, G7, G8, E1, E2, E5 (placer half), E7, E10** — small, owned, disjoint.
- **CL-B1, B4, B5** and the non-bake slices of **CL-B2** — the Band 1, HUD and creature
  lanes as briefed.
- **CL-E4** — the arena, if xvfb time is available; otherwise it moves to stage 3.
- **CL-D1 … D7** — the corrections. **CL-D3 first**: land the Band 3 report before
  anyone else reads §6 and counts seven.

**Why this stage is first:** every evidence run in stages 3–5 reads through the harness,
and every one run this week returned a FAIL whose root cause was the harness. Spending a
render session on S06C before CL-H9 lands produces a sixteenth frame set with no
creature in it.

### Stage 2 — one merge, one re-bake (coordinator)

Land stage 1 onto `ralph/G3-LAND-0904`, apply the collected vegetation and terrain
proposals (CL-B2's tree/terrain slices, CL-E6), run **both** bakes once, commit bake and
config together, then a pull request whose head commit is code and whose code jobs ran.
**Never before the merge** (PR #29's lesson: two internally consistent branches are
fresh for neither). Bake proposals that arrive after this bake wait for the next merge;
do not run a second bake for one lane.

**Fails if** a bake is run on a lane branch, or if the merged tree's
`verify-scatter-bake-freshness` / `verify-terrain-bake-freshness` are green only because a
`RETRIES` rescue turned 0-for-1 into green.

### Stage 3 — evidence per segment, in parallel (the band lanes)

- **CL-R1** (S01–S05) — the coordinator's, because it crosses Gate 1 and 2.
- **CL-R2** (S06–S09) — each band lane, its own seed, its own template, its contract rows.
  These re-runs are what turn "done but unproven" into pass or fail for the profiles
  (CL-E3), Dorn's placement, the relay's escalation, the captains' floor and ceiling
  (C-4's measured floor and ceiling; C-5's ≥ 75 % HP arrival test), and Band 5's
  dialogue→combat and gorge routing.
- **CL-R3** (S10) — as the coordinator can afford it. The smokes stand as the mechanism's
  evidence in the meantime and should be stated as such, not as the protocol's.
- **CL-R5** capture lanes and per-band judges — after CL-H9 and stage 2's bake, so the
  frames show the shipped bake with a creature in them.
- **CL-B6** — Gate 2's judge on the same sixteen stands, same time.

Anything that comes back FAIL here re-enters stage 1 for that band only, is re-converged
alone, and is not allowed to block the other bands (the execution plan's own method).

### Stage 4 — the continuous chain (coordinator)

**CL-R6**, only once every segment has passed on its own. Its verdict is Gate 3's. Its
S05 also re-scores Gate 2's template on a party that got there by play rather than by
`build_gate2_seed.gd`'s levelling allowance.

### Stage 5 — the owner (§4)

The released build that carries stage 2's bake goes to the Ally. The four owner-only
items and the questions in §4 close there or not at all.

### The dependencies that are not obvious from the stages

- **G-2 before combat data** — already satisfied (`4444381e`); but **combat data before
  a fair fight is meaningless**, so no lane may retune a profile from S06–S09 results
  produced before CL-H1. G3-BAND2's own addendum says this about Dorn; it applies to every
  named opponent.
- **CL-H9 before any Bar B answer.** Bar B is the creature-collection question and no
  frame set has ever contained a creature at size. Until staging exists, a "no" on Bar B
  measures the instrument.
- **CL-E5's placer before CL-E5's board.** G3-WARDEN-ARENA (owns `stronghold_climax.gd`)
  lands first; G3-BAND5's dialogue and readout entry second.
- **CL-B3's in-rules bridge dressing before the dead-travel classification is re-read.**
  The 71 s interval ends at a bridge the judge could not see; if the bridge becomes a
  destination the interval's classification improves for free, and if it does not the
  interval is the weaker of the two and should be treated as the finding it nearly is.
- **CL-R1 before CL-R6**, obviously, and **CL-H6 before CL-R1**: an S03 that hands over
  four creatures and no home makes S04 unquotable regardless of S04's script.

---

## 4. What only the owner can close

Kept separate because no container work closes any of it, and because §K of the master
protocol says the operator must not fabricate a proxy.

### 4.1 [OWNER-ONLY] per `GATE_F_MASTER_PROTOCOL.md` §0.4, both gates

| Item | Where it is asserted | What the owner needs |
|---|---|---|
| ROG Ally frame rate with grass on | Gate 1 and Gate 2 acceptance; `CURRENT_STATE` §3 P0 | one A/B measurement on the released build carrying GRASS-CULL's culling and the fresh bake (the released build before 2026-09-03 had no scatter at all, so every earlier hardware report described an empty world) |
| Interact reliability on hardware | Gate 1; `CURRENT_STATE` §3 P0 (root-caused and fixed in `tool_hold.gd::swing_at()`) | confirm on the pad |
| Player sleep | Gate 1; `CURRENT_STATE` §3 P1 | try Grandpa's loft bed and the bedroll on the current build (the question "was the loft bed ever tried" is still unanswered) |
| Day counter / day-night advancing on device | Gate 1; `CURRENT_STATE` §3 P1 | the action that preceded the stuck counter |
| Windows export identity | protocol §0.5 | the export is verified to *build* and to *pack* the scatter; behaviour on Windows is the owner's |
| Twitch feel, controller latency, audio, handheld legibility at 1280×800 | protocol §K | the same pass |

### 4.2 Design questions escalated — **answered by the owner 2026-09-04**

`docs/owner/OWNER_DIRECTIVES_2026-09-04.md` records the answers verbatim with triage.
In short: V-5 yes; W-1 confirmed; a refused Veridian roams the land, uncatchable; R-3
confirmed; Halda restores the team; the visual half runs as its own track; art comes
from free packs first and the owner designs in Meshy when three candidates fail; fix the
dialogue camera and the dialogue portrait (every NPC is drawn with the player's face);
the grass clump-card question is closed (procedural grass is enough); Grandpa's loft bed
is owner-reproduced as broken; the hardware pass is later. The new items that fall out
are CL-E12, CL-G10, CL-G11, CL-G12 and CL-A1 below. The list as it stood, kept for the
record:

From `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` §9, with what has happened since:

1. **V-5** — heal the relay's own three drain stations on `relay_disabled`, reading D41's
   "the land heals when the machinery fails". Recommended yes; nobody has implemented it.
2. **W-1** — the Warden's front raised to 18/18/19/19/20. **Implemented by G3-FINALE
   ahead of an answer**, inside every guard test, with the pacing measured. The owner
   should confirm or reverse; the alternative (lower Hald) is still available.
3. **R-8** — where a refused Veridian goes. Recommended: seen again at the Highfield
   herd after the healing, unengageable.
4. **R-3** — a once-only wild alpha at 16–19 on the last 60 m before the Hall. Authored
   and live; optional and catchable; confirm it is intended pressure, not a wall.
5. **G-2** — scope. **Answered by implementation** (`4444381e`); no longer a question,
   recorded so the contract's §9 can be updated.

From Gate 2 and the ledger:

6. **2.10** — which beat restores the team after the tournament (champion beat, Halda or
   Mira, or the Trail Camp as the authored stop). The 2026-09-03 instruction settles that
   *something* does; the plan recommends the champion beat (Halda hands over the revives
   with the saddle recipe, the place the player already is), with the Trail Camp kept as
   the field stop it already is.
7. **The Gate 2 acceptance bar** — §5 below. A project decision the owner should see.
8. **The dialogue camera** — villagers read too small in conversation (`CURRENT_STATE`
   §3 P2, owner decision pending).
9. **The grass clump-card blade redesign** — asked and unanswered (`CURRENT_STATE` §3).

### 4.3 The art the judge says is not in the build, against the hard rules

Every blind pass has ended with the same "needs art" list. Each line is checked here
against `CLAUDE.md`, because that is where the budget question actually lives:

| Ask | Hard-rule position | What is possible without the owner | What needs the owner |
|---|---|---|---|
| A built South Bridge with Team Tether presence | Meshy is reserved for Team Tether hero objects; still needs owner reference art | dress it from the installed village family, Team Tether props and the grunt rig (CL-B3) | a hero gate mesh, if the dressed version is judged insufficient |
| One Meadows landmark to navigate by | one nature family, one village family, one prop family | site the installed watchtower silhouette, or the mill with sails, on Band 1's far plane | a new landmark mesh |
| Tree meshes with branch structure below the canopy | **no new nature meshes**; one nature family | grow and cluster the installed forms (CL-B2); the judge says scaling a trunk-plus-blob cannot make an oak | a decision to add one branching tree form, with reference art |
| Creature silhouettes that read at 16 px; a companion on screen | no new creature meshes | the companion is CL-H9 (staging) and a game defect if the shipped game never deploys after load (run 3 GAME-2); silhouette by material, scale, animation | nothing more without reversing a hard rule |
| Combat and reward VFX | no rule against it; nobody has budgeted it | a level-up flourish and hit spark are shader/particle work inside the installed kit | a decision that Bar B is worth it |
| Distinct NPC bodies; facial detail on the trainer | reuse the installed humanoid cast; a new humanoid is exceptional | material and silhouette variants | reference art for any new body |

**The plain statement:** Bar A and Bar B as currently worded cannot both go to "yes"
without at least two of these (a companion visibly on screen, and combat that produces a
picture). The first is inside the plan (CL-H9 plus GAME-2 if it is real). The second has
no owner and no budget line anywhere in `docs/ROADMAP.md`. If the owner wants Bar B to be
answered yes, VFX needs a lane; if not, Bar B's wording should say what it is actually
measuring (§5).

**Owner's answer, 2026-09-04:** free packs first; if the first three candidates fail, the
owner designs the reference in Meshy. That gives the table above a lane:

| Id | Item | Size | Kind |
|---|---|---|---|
| CL-A1 | **Art sourcing.** For each row of the table above, in this order — the South Bridge gate and Team Tether presence, a Meadows landmark, a branching tree form, combat/reward VFX, distinct NPC bodies — find up to three free-pack candidates that match the installed families' style and scale (`docs/art/HUMANOID_ASSET_INVENTORY.md` and the nature/village/prop family rule are the yardstick), install each in place, render it on the stand where the judge named the gap, and put the three to a blind judge. A pass ships; three fails go to the owner with the contact sheet as the Meshy brief. The one-family rules are relaxed only for the specific object the owner then designs. | M per row; the tree and VFX rows are L | not done |

The rows above that were "needs the owner" are now "needs CL-A1, then maybe the owner".

### 4.4 New items from the 2026-09-04 answers

| Id | Item | Source | Size | Kind |
|---|---|---|---|---|
| CL-E12 | **V-5 implemented:** on `relay_disabled`, run `meadow_healing` for the relay's own three drain stations only (a station filter on the existing mechanism, not a new system). Evidence: a before/after frame from the `06-relay-standing` stand shows the ground change inside the site radius. | contract V-5; owner 2026-09-04 #1 | S–M | not done |
| CL-G10 | **The dialogue camera.** Villagers read too small in conversation; a conversation framing in `camera_rig.gd` that puts the speaker at a readable size at 1280×800 on the pad. Evidence: a frame from a real conversation judged legible at handheld resolution. | `CURRENT_STATE` §3 P2; owner #8 | M | not done |
| CL-G11 | **Every NPC is drawn with the player's portrait.** `assets/ui/portraits/` holds `trainer.png` and `grandpa.png` only; 125 of 138 authored `portrait` entries in `data/dialogue/` name `trainer.png`, so Mira, Oskar, Tam, Bram, Halda, every Team Tether rank and the Warden speak with the player's face. `dialogue_panel.gd:205` draws exactly what the line names, so the fix is art plus data: one portrait per installed humanoid rig, rendered from the installed meshes (no new mesh), each conversation's `portrait` re-pointed to its speaker, and a test that no non-player speaker resolves to `trainer.png`. | owner #8b | M | proven failing (owner) |
| CL-G12 | **Grandpa's loft bed does not work** on the owner's build. The in-engine probe passes, so the defect is between the probe's path and the real one: the prompt, the reach, interact arbitration on the loft, or the bed's placement. Root-cause on a real body driven up the loft stair, not by re-running the probe. Reopens `CURRENT_STATE` §3's "verified in-engine". | owner #9b; `CURRENT_STATE` §3 P1 | S–M | proven failing (owner) |

Closed by the same answers, no lane: the grass clump-card redesign (procedural grass is
enough); W-1 as shipped; R-3 as shipped. R-8 (CL-E11) is now specified: the refused
Veridian **roams the land and is uncatchable** — the lane chooses where it is seen
inside that rule.

---

## 5. Recommendation on Gate 2's acceptance bar

**Correct it. 2.8 §6 is right, and the current wording is a defect in the gate, not in the
lanes.** Every blind pass against 2.2–2.7 answered no / no and named residual causes —
props, fence, signposts, sails, water, lighting, terrain form, the bridge — that no task
in 2.2–2.7 was scoped to touch. A gate that can complete every task it names and still not
move its own verdict will read as a failure of the people who did the work, forever. It
has already done so three times.

2.8 deliberately did not lean on this to reach its verdict, and neither does this plan:
the current FAIL stands on grounds inside the gate's reach (no roster decision; Bramblebun
off-palette by day; scatter that reads as a rule; trees at 2.3× the trainer). Correcting
the bar does not pass the gate. It makes the gate passable by the work it contains.

**Proposed replacement for the first acceptance clause**, for the coordinator to put in
`docs/ROADMAP.md` and the owner to see:

> **Blind judge, on stands taken from the played route's own trace** (gameplay camera,
> HUD on, a companion deployed, a fight frame containing a fight — never posed survey
> viewpoints, which flatter a build), in three parts:
>
> **(a) The vegetation, creature and night clause** — judged against 2.2, 2.3, 2.4, 2.7
> and 2.16: silhouette variety named as improved; a mid-layer present between grass and
> canopy; scatter that reads as laid out, not as a rule; creature separation from ground
> ≥ 1.5:1 measured **and** the judge no longer naming any creature as off-palette by day
> or night; night midground readable. **Fails if** the judge names any of these as
> unchanged on the same stands where they were named before.
>
> **(b) The composition, props and terrain clause** — judged against 2.13 (scene half):
> each item the 2.8 judge itemised is named as improved on the same stand it was named
> on; the South Bridge reads as a held crossing from the approach; the red family is
> reserved. **Fails if** any itemised 2.13 scene item is still named on its stand, or if
> oxblood appears on a friendly surface.
>
> **(c) Bar A and Bar B**, asked only after (a) and (b) pass and after the capture lane
> can put a creature in frame at size (2.15): Bar A yes; Bar B "trying to be the same kind
> of game", **with the remaining gaps named as art-not-in-build and that list checked
> against `CLAUDE.md`'s hard rules** so the project knows which gaps are a decision and
> which are a lane. **Fails if** Bar B is answered on a frame set with no companion beside
> the trainer and no fight in the fight frame — that answer measures the instrument.

Two consequences, stated so they are not rediscovered:

- **Gate 3's "blind judge per band" inherits the same defect** and should be read the
  same way: per band, clause (a) plus the band's identity contracts (C-6 for the
  captains' sites, P-5.1 for the Hall, G-5 for named opponents at 6 m), with Bar A / Bar B
  asked once for the chapter at Gate 4 after 2.13 lands — not per band, where every band
  would fail on the same props and lighting Band 1 fails on.
- **The template's roster clause stays as written.** "At least one roster decision in
  play" is inside the gate's reach and 2.12 is scoped; do not soften it to "rotation".

The checkpoint tag `gate2-candidate` is placed when (a) and (b) pass and the template
passes; `gate2-done` (a new tag, proposed) when (c) passes and the owner's Ally check is
recorded. Splitting the tag is what lets the project say honestly where it is.

---

## 6. What "done" costs

Not a date. Relative sizing, and the items that are cheap enough that leaving them open
costs more than doing them.

### 6.1 By stage

| Stage | Contents | Size | Parallelism |
|---|---|---|---|
| 1 | eleven harness/instrument items, nine game defects, the Band 1 / HUD / creature lanes, the small contract items, seven doc corrections | the bulk of the remaining lane work; S/M each, one L (CL-B2's slices), one L (CL-H3 if the walker's corner-following is rebuilt) | high — nearly everything is disjoint by file |
| 2 | one merge, one bake, one CI run | M, coordinator only | none |
| 3 | five segment runs, five capture lanes, five judges, Gate 2's judge | each M; the captures and S10 are L | high across bands; serial inside a band on FAIL |
| 4 | the chain | L (S03 alone is 28 min wall; S10 is the cost problem) | none |
| 5 | the owner | one hardware session plus nine decisions | — |

### 6.2 Cheap enough that leaving them open is worse

Each of these is S, has an owner or an obvious one, and is currently generating false
readings, wasted launches or stale reasoning:

- **CL-D3** — the Band 3 report off the landing branch. Every reader of §6 is being told
  seven reports were read.
- **CL-D4** — the "waiting on re-bake" strings. They will cause a bake to be run for a
  clearing that is already baked.
- **CL-H5** — the freeze-record trap. Four launches lost already; the fix is a few lines
  in `run_segment.sh`.
- **CL-H4, CL-H7** — thresholds and a wrong region assert. Each is one number; each
  turns a passing segment into a "FAIL" someone has to read.
- **CL-D1, CL-D2** — the stale "no trainers" and "empty spawn data" sentences. A lane
  reading them will author against a world that does not exist.
- **CL-E1** — Oreth's profile. Fell between two lanes; one row and a fixture mirror.
- **CL-G6** — the saddle's Ironwood cost. The comment says exactly what to type.
- **CL-G5** — the garrison never withdrawing. A flag check in one script; A11 is weaker
  without it.
- **CL-G7** — the null-material error. It opens every boot log with an engine error.

### 6.3 What nobody has budgeted

Said plainly, per the brief:

- **VFX** (combat, catch, level-up). No lane, no prompt, no roadmap line. Without it Bar B
  stays no on the judge's own reasoning ("legible as fights almost entirely because of
  VFX"). §4.3.
- **A branching tree form.** Growing and clustering the installed forms (CL-B2) is the
  most the hard rules allow; the judge says it will not make an oak. If the owner holds
  the no-new-nature-mesh rule, Bar A's "oak groves you walk under" should be read as
  "groves at oak scale" and the bar should say so.
- **The S10 cost.** The finale segments cannot be walked under the protocol on this
  class of host in one session. Either a faster host, a further split, or an explicit
  decision that the smokes are the finale's evidence of record.
- **Pacing at 4.7 h against 3–4 h.** Gate 4's charter, but Meadows completion (K1)
  depends on it and no retune is scheduled.
- **The Warrens interior visual pass** the owner asked for on 2026-09-03 (CL-E8). Assigned
  by the contract to a lane that does not exist.
- **Capture staging** (CL-H9 / 2.15). In the roadmap, not in round two's assignments, and
  it gates every visual verdict in both gates.

### 6.4 What closing each gate actually requires, in one paragraph each

**Gate 2 is done when:** S05 on the merged SHA, entered from a played S04, records a
catch or a considered refusal on the direct route, reaches a startable fight with no
menu recovery block, and passes its template; the perf proxy holds after the re-bake; a
blind judge on the same sixteen played-route stands, with a companion deployed, passes
clauses (a) and (b) of §5; the tag is placed; and, separately, the owner's Ally
frame-rate check is recorded. **Fails if** any of those is claimed on a posed stand, a
levelled seed, or a `RETRIES` rescue.

**Gate 3 is done when:** each of S06, S07, S08, S09 passes on its own synthetic entry
with `fight_until_resolved` fights and its contract **fails if** rows scored (including
the three-sentence test for the guardian, Vance, each captain, Hald and the Warden); the
finale's evidence is either S10a–e under the protocol or the coordinator's written
decision that the smokes stand in for it; each band has a blind judge on staged frames
answering clause (a) and its identity contracts; the §8 checklist's three unmeasured
items (dead travel by play, night readability, hardware) are measured, owner-only aside;
and the continuous S01 → S10e chain passes on the SHA that carries all of it. **Fails if**
any band's "pass" comes from a run whose entry was not the previous segment's played
exit *and* the plan does not say so in the sentence that claims it.

---

## 7. Where this plan contradicts something currently written down

Listed in full in `ralph/reports/G3-CLOSURE-PLAN-0904/REPORT.md`. The ones that change what
a lane does next: CL-D3 (the seventh report is not here), CL-D4 (the clearings are baked),
CL-H3 (the fence-corner fix does not exist on `origin`), CL-E1 (Oreth's profile fell
between two lanes), the S04 caveat having two causes not one (§1.2), and the Gate 2
acceptance bar (§5).
