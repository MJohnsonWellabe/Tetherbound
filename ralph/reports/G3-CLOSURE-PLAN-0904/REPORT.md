# G3-CLOSURE-PLAN-0904 — report

**Lane:** Gate 2 / Gate 3 closure plan (Fable, read-only on code, data, assets, tests).
**Branch:** `ralph/G3-CLOSURE-PLAN-0904` from `ralph/G3-LAND-0904` at `e902ab04`. No pull
request; the coordinator lands it. **Deliverable:** `docs/GATE2_GATE3_CLOSURE_PLAN.md`.
Touched: that file and this directory only.

## The plan's decisions, one screen

| # | Decision | Where |
|---|---|---|
| 1 | Both gates **fail today**, for the first time on real evidence; every open item is classed as *not done*, *done but unproven*, or *proven failing*, and the plan is ordered by that class, not by effort. | plan §0, §1 |
| 2 | **Gate 2** fails on the blind-judge clause (four passes no / no) and on 2.5's roster-decision clause; dead travel and the perf proxy pass; the Ally check is owner-only. 2.9–2.16 are the whole residue; **2.15 (capture staging) is assigned to nobody and gates every visual verdict in both gates.** | §1.1, CL-H9 |
| 3 | **Gate 3** is "done but unproven" in every band: four segments were played on synthetic entries and every FAIL resolves to a harness defect (blind `combat_quick ×N` press blocks in S06–S09, press-count dialogue handoff, the walker). The finale ran only as smokes. The one visual PASS in the gate is P-5.1. | §1.2 |
| 4 | **G-2 is closed** (`4444381e`, `test_encounter_combat_override.gd`); every authored `combat` profile is live and **none has been played through a fair fight**. Oreth's C-3 is not authored — it fell between G3-BAND3 and G3-BAND4. | §1.2, CL-E1, CL-E3 |
| 5 | **The instrument goes first.** Stage 1 is harness, walker, capture staging and the cheap corrections; stage 2 is one merge and one re-bake; stage 3 per-segment evidence in parallel; stage 4 the continuous chain; stage 5 the owner. No profile may be retuned from a pre-CL-H1 run. | §3 |
| 6 | **Correct Gate 2's acceptance bar** into three parts — (a) vegetation/creature/night judged against 2.2–2.7 and 2.16, (b) composition/props/terrain judged against 2.13, (c) Bar A / Bar B asked only after (a), (b) and 2.15 — on played-route stands with a companion deployed, never posed. Gate 3's per-band judge inherits the same split; Bar A / B asked once at Gate 4. Split the checkpoint into `gate2-candidate` and `gate2-done`. **This does not rescue the current verdict.** | §5 |
| 7 | Nine items are cheap enough that leaving them open is worse than doing them; four things nobody has budgeted are named plainly (VFX, a branching tree form, the S10 cost, pacing at 4.7 h). | §6 |
| 8 | Six of the seven round-one Gate 3 reports are on the landing branch; the Band 3 report and its S07 run artefacts are only on `origin/ralph/G3-BAND3-0903` (`8e5e2a9c`). | CL-D3 |

The brief says nine lanes are in flight on round two; `docs/GATE3_EXECUTION_PLAN.md` §6
names six plus this one. The plan assigns work by item, names the §6 lane where one
claims it, and marks the rest **unassigned** for the coordinator to route.

## Every place the plan contradicts something currently written down

| # | Written where | Says | The plan says | Why |
|---|---|---|---|---|
| 1 | `GATE3_EXECUTION_PLAN.md` §6 | written "after a pass over all seven Gate 3 lane reports" | six are on `ralph/G3-LAND-0904`; G3-BAND3's is not | `git merge-base --is-ancestor 8e5e2a9c HEAD` is false; `65e1c939` merged the branch before its report commit |
| 2 | `GATE3_EXECUTION_PLAN.md` §6; G3-BAND2 report; `band2_stone_and_root/vegetation.json` `_why` strings | Band 2's two Warrens clearings are "waiting on the coordinator's single re-bake" | they are in the shipped bake | the clearings last changed at `ca78933a` (2026-09-02); both bakes were re-run under the freshness guards at `3c73aab5` (#29, 2026-09-03); no bake input has changed on this branch since |
| 3 | G3-BAND5 report | terrain bake freshness for the approach drain stations is unconfirmed | confirmed by the same reasoning | `terrain_playground.json` last changed in the #29 commit that re-baked terrain |
| 4 | chain `RUN_METADATA.json` `known_open_defects_at_freeze` | `ralph/FENCE-CORNER-0903` fixed `stick_navigator` for the corner and is not on this SHA | the fix does not exist on `origin` at all | no such branch, no commit message, `stick_navigator.gd` last changed 2026-08-31 |
| 5 | coordinator commit `a7742567` | S04's 21 fails are unquotable because the script is pre-2.8 | true, and there is a second cause: the S03 exit it loaded has party 4, no home, no sleep, no feed (`S03-39`, `S03-51n*a`, `S03-108`, `S03-173`, `S03-223`) | S04's `tournament_training_ready` / `condition_ready` / `entered` NOT-set fails follow from the entry state whatever script runs; S05 onward from this chain will not be quotable either |
| 6 | `GATE3_EXECUTION_PLAN.md` §6 (G3-HARNESS brief) | "S08 has no post-faint switch or revive" | S06, S07 and S09 have the same defect; none of the four has a `fight_until_resolved` step | `grep -c fight_until_resolved tools/gate_f/segments/S0{6,7,8,9}.json` → 0, 0, 0, 0 |
| 7 | `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` §8 / §9 q5; G3-BAND2/BAND4/BAND5/FINALE reports | G-2 is the coordinator's pending change / an open scope question | landed at `4444381e` with a test | on this branch |
| 8 | G3-BAND3 report §2 ("C-3..C-7 belong to the encounters lane"); G3-BAND4 addendum ("Oreth's C-3 lives in band 3 data, not touched") | each says the other owns Oreth's profile | nobody authored it | `captain_riverwatch`'s three members carry no `combat` key |
| 9 | `data/config/chapter_curve.json:36` | Band 2 "has no trainers of its own, which is prompt 59's gap" | four trainers | `band2_stone_and_root/trainers.json` |
| 10 | `docs/prompts/64` line 29; `docs/prompts/66` line 35 | "Current empty Band 3 / Band 5 spawn data" | 54 and 23 clusters | file inspection; Band 5's 23 is D70's crescendo |
| 11 | `docs/CURRENT_STATE.md` §5 | "Gate 3 / 4: not started"; the Gate 1 paragraph carries two generations of text | Gate 3 has run one full round; Gate 1's paragraph should be rewritten from evidence | this plan §1 |
| 12 | `docs/ROADMAP.md` Gate 3 | segments "S04–S10" | S06–S10e | execution plan §1 |
| 13 | `GATE3_EXECUTION_PLAN.md` §4 | "Does the Warden read as the hardest fight?" open | measured (38–101 % longer than Hald), then W-1 raised him; owner to confirm | G3-FINALE §1 and addendum |
| 14 | `GATE3_EXECUTION_PLAN.md` §4 | "Is Band 5 an empty corridor?" open | no: 26 / 30 / 22 creatures counted live at three eyes; 63 m worst gap | G3-BAND5 probes |
| 15 | `docs/acceptance/MEADOWS_EXIT_CRITERION.md` B2, B4, E5 | Bramblebun 1.08:1 open; no contact shadows; the Warrens interior is "the standing GOOD example; protect it" | 1.568:1 since 2.4 and now overshooting; contact ellipse shipped; the owner's 2026-09-03 finding 9 says the Warrens "doesn't look good" and outranks E5 until a blind judge on real frames says otherwise | `CURRENT_STATE` §3; owner playtest |
| 16 | `docs/ROADMAP.md` Gate 2 acceptance, first clause | Bar A yes / Bar B on the five survey stands plus village and bridge approach | replace with the three-part clause in plan §5, on played-route stands with a companion deployed | 2.8 §6; four passes no / no on causes outside 2.2–2.7's scope; posed stands flatter |
| 17 | G3-FINALE report §1 (first pass) | "no change to `warden_aldis`" | superseded by its own addendum (W-1 applied) | the addendum stands; recorded so the first-pass sentence is not quoted |
| 18 | `GATE3_EXECUTION_PLAN.md` §6 "Still open, owned by the coordinator" | the single re-bake is needed for the Warrens clearings, P-5.2 and Band 1's dome hill / tree layout | needed for P-5.2 and Band 1's proposals only; the Warrens clearings are done | item 2 |

## Questions escalated to the owner

Kept in plan §4; listed here so the coordinator can route them in one message.

1. **V-5** — heal the relay's own drain stations on `relay_disabled` (D41 reading). Recommended yes.
2. **W-1** — the Warden's front is now 18/18/19/19/20, implemented ahead of an answer. Confirm, or lower Hald instead.
3. **R-8** — where a refused Veridian goes. Recommended: seen again at the Highfield herd, unengageable.
4. **R-3** — a once-only wild alpha at 16–19 on the last 60 m before the Hall is live. Confirm it is intended pressure.
5. **2.10** — which beat restores the team after the tournament. Recommended: the champion beat (Halda), with the Trail Camp kept as the field stop.
6. **The Gate 2 acceptance bar** — the three-part correction in plan §5, and the `gate2-candidate` / `gate2-done` split.
7. **Art against the hard rules** — a hero South Bridge gate (Meshy is reserved for Team Tether hero objects; needs reference art), a Meadows landmark mesh, one branching tree form (would reverse "no new nature meshes"), combat / reward VFX (no rule, no budget), distinct NPC bodies. Which of these, if any, gets reference art; if none, Bar A's "oak groves you walk under" should be re-read as "groves at oak scale" and Bar B's wording should say what it measures.
8. **The dialogue camera** (villagers read small in conversation) — pending since 2026-09-02.
9. **The grass clump-card blade redesign** and **whether Grandpa's loft bed was ever tried** — both asked in `CURRENT_STATE.md` §3, both unanswered.
10. **The hardware pass** — Ally frame rate with grass on, interact on the pad, player sleep, day/night advancing, on the first released build that packs the scatter (every earlier hardware report described an empty world).

## What I did not do

- No code, data, asset, shader, test or harness file was read for editing or edited; every "do" is addressed to a lane by item id with the file named.
- No Godot run. Every number is quoted from a report, a notes file, an inventory, a config file or `git`.
- Did not decide any of the ten questions above; recommended and flagged.
- Did not message any lane or the coordinator.
