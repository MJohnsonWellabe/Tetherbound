# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `🔒` needs Meshy credits. `model:` the cheapest tier that can do the
job. `tests:` exactly what to run.

**Owner play gates were retired 2026-08-16.** Every `▶` gate (`R2.9`, `R4.12`,
`R6.3`, `MQ1-gate`, `SH53`, and the `R9.5` exit gate) is gone by owner
directive, along with the pointer to the owner-only blind-playtest protocol.
`docs/decisions/D21` stays as history and reads as superseded, not violated.
The loop no longer parks on a gate — see `ralph/PROMPT.md` for what it does at
the end of the backlog.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue. **Any firing
that reaches a `model: fable` item must not do the creative work in its own
session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**MODEL FLOOR SUSPENDED, owner directive 2026-08-17: "drop to sonnet for
everything."** Taken to protect the account's seven-day rate limit, which was at
`allowed_warning` with a reset of 2026-08-22 03:00 UTC while the owner asked for
the first two bands of content finished before it hits. **The newer word wins**
over the `model: fable` floor above, the same way `D23` lets the owner's later
word win over the spec — so `model:` lines in this file now read as a *ceiling*,
not a floor, and a `fable` tag means "this is ceiling-setting work, be
conservative" rather than "dispatch fable".

What that costs is real and is recorded rather than papered over: the fable
floor exists because a weaker first pass becomes a ceiling a later pass cannot
rescue, and `MQ2B` is exactly that kind of item. A lane working a `fable`-tagged
item under this directive should prefer arranging and connecting what exists
over inventing new fiction, keep new named things few and small, and write down
in `ralph/NOTES.md` anything that genuinely wanted a stronger pass.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks. `model: haiku` when it is
just screenshots.

---

## RECONCILED 2026-08-17 (OPS1) — 35 items closed in one pass

**This file had drifted badly and this note exists so the drift is legible
rather than silently tidied.** Across 2026-08-16/17 a coordinated run landed 76
commits to `main`; almost none of them were marked here, because bookkeeping was
centralised on a coordinator that then spent the night on merges instead. That is
`OPS1`'s own failure mode, happening while `OPS1` sat open.

Closed in this pass, verified against `git log origin/main` rather than against
anyone's memory: `OW1` `OW2` `OW4` `OW7` `OW8` `OW9` `OW10` `OW11` — the whole
owner-reported ROG list — plus `PERF1` `PERF2` `WALL1` `TEST1` `EXP1` `MERGE1`
`LANE1` `UI-PAD1` `UI-PAD2` `PT-03` `PT-04` `PT-15` `PT-17` `PT-18` `PT-19`
`PT-23` `OF18` `EV10` `MQ1B` `R7.3` `R7.6` `R7.7` `R7.8` `R7.9` `OW5A-rework`.

Four more are **shipped and in flight** on `ralph/integrate-3` — `OW3`, `OW12`,
`OW1-remainder` and the collision-streaming work — each marked in place rather
than closed, because a branch that has not landed is not done no matter how
green it is.

**The rule that made the difference, and it is worth keeping:** a shipped item
is one whose content is an ancestor of `main`. Not a green branch, not a lane
saying so, not a branch ref that looks right — `UI-PAD1`'s ref had moved and an
ancestor check called it missing while its code was demonstrably in the tree.
Check the tree.

---

## CI-COVERAGE-1 — 31 smoke_*.gd files exist with no CI job (non-blocking)

Filed by `STRANDED-P3` while reconciling `origin/claude/gate-a-core-verbs-8aaw7g`'s
CI-wiring commit (`a9215a1b`) against current `main`: `main` had already wired
its own (later, differently-shaped) `verify-owner-regressions-shard` /
`verify-gate-evidence-shard` / `verify-continuous-core-known-red` jobs closing
most of that same gap, so `a9215a1b` itself conflicted heavily and was not
cherry-picked whole — reopening its own already-superseded job structure would
have thrown away `main`'s more complete version for no gain. What `a9215a1b`
still names that `main`'s version does not: `smoke_title_new_game`,
`smoke_save_persistence`, `smoke_gate_a_build_segment_meadows`,
`smoke_gate_a_map_cycle`, `smoke_no_double_prompt`, `smoke_collision_streaming`
— six Gate A checkpoint/lifecycle regressions that exist on disk and run in no
CI job. A broader sweep of `tests/smoke_*.gd` against the current `ci.yml`
found 25 more beyond those six: `smoke_backpack_pad_target`,
`smoke_build_menu_footprint`, `smoke_build_menu_pad_pick`,
`smoke_camera_probe`, `smoke_controller_catching`,
`smoke_craft_panel_controller`, `smoke_creature_control`, `smoke_evolution`,
`smoke_exploration_legend`, `smoke_gateb_flags`,
`smoke_hud_handheld_legibility`, `smoke_interactable_sightline`,
`smoke_menu_focus`, `smoke_menu_owns_dpad`, `smoke_mouse_look`,
`smoke_name_prompt_controller`, `smoke_name_prompt_keyboard`,
`smoke_pond_water`, `smoke_prompt_hotbar_dock`, `smoke_release`,
`smoke_rename_pad_trigger`, `smoke_step_up`, `smoke_village_smith`,
`smoke_village_trade`, `smoke_village_trainer`, `smoke_wake_softlock`.

Not wired in this pass: none confirmed green against current `main` first
(a red job added blind is worse than an unwired test — it wedges every branch
behind a check nobody has seen pass), and 31 files is real re-audit scope, not
a side effect of a CI-wiring cherry-pick. Worth a dedicated pass: run each
against current `main`, confirm or fix it, then wire it into an existing
shard (or the unit suite if it's cheap enough to run every commit).

---

## STRONGHOLD-R2-remainder — three things round 2 on the stronghold frames left open (2026-08-23)

Filed by `STRONGHOLD-R2` (see `ralph/DONE.md` for what it did fix and the
measurements). Each of these is left open on purpose rather than half-done.

### STRONGHOLD-BLIND-PASS — the blind critique still has not run on this site · `model: fable` · `tests: visual`

**This is the blocking one, and it is infrastructure, not art.**
`conventions.md` requires a blind critic for visual-affecting work. Two
consecutive lanes on this site could not spawn one: `create_session` returned
"the service is temporarily unavailable" on every attempt (round 1 recorded it,
round 2 tried six times across a whole session), and this lane has no
in-process subagent tool. Invoking the `visual-judge` skill directly is not a
substitute — it loads inline, into a context that already knows what changed,
which is exactly what its own header says the mechanism depends on not
happening.

**Everything a critic needs is already staged, so this is one step when the
spawn service is up:**

1. On an idle box (1-minute load under 8), run
   `tools/capture_stronghold_approach.gd` — the REAL-scene version of the three
   viewpoints. Judge `shots/wayfinding_full/`, not `shots/wayfinding/`:
   `capture_castle_lite.gd` skips the vegetation scatter, so its frames show the
   stronghold in an unbroken mown lawn and a critic will correctly rank "the
   field is empty" first while describing the capture rather than the world.
2. Sheet them (`tools/contact_sheet.gd -- --dir=res://shots/wayfinding_full`).
3. Spawn a critic against a scratch branch carrying the PNGs — `shots/` is
   gitignored, so a fresh container cannot otherwise see them.
   `scratch/stronghold-r2-frames` (commit `3b0250d`) is round 2's, built as
   origin/main's tree plus the four lite PNGs; rebuild it the same way with the
   full-scene set. Point the critic at the frames and `docs/reference/` and tell
   it nothing else.

Until that runs, treat round 2's frames as **improved-and-unjudged**. The
improvement is measured (`tools/frame_stats.py` deltas are in `DONE.md`);
whether it is any GOOD is the question that has not been asked.

### STRONGHOLD-MERLONS — three merlon sizes in one silhouette · `model: fable` · `tests: smoke_stronghold, visual`

Named by round 1's critique, confirmed and located by round 2, not fixed. The
castle shows the curtain's crenellations at module scale **2.6**, the gatehouse
flankers' at **3.4** and the keep's crown at **3.8** in the same frame, plus a
fourth size — the inner bailey ring at **2.0** — showing behind the flankers in
`silhouette-approach`.

Not fixed because every candidate is a re-author rather than a tune. Merlons are
part of each module's mesh and `building_prefabs.json` carries one uniform
`scale` per module, so crenellation size is welded to tower size. Dropping the
flankers to the curtain's 2.6 costs 3.3m of gatehouse height, which has to be
regained by stacking a second course — and that moves the measured south face
(z -10.79) that the flanker banners, the two teal work lamps and
`STRONGHOLD-R2`'s own gate-jamb filler modules are all placed against, plus the
flanker colliders. Doable, but it is a massing change on the hero landmark and
wants its own pass with `tools/_probe_castle_gaps.gd` re-run after it.

### BAND4-RIDGE-WHITE — the glitch-white mesh on the band4 ridge crest · `model: sonnet` · `tests: visual`

Untouched and unconfirmed. The second-path rule says confirm it is real geometry
and not a capture artefact before changing anything, and confirming it means a
Band 4 render. Round 2's box ran at load 12–30 on four cores with ~1GB free and
five other lanes capturing and testing into each other; its own full-scene
capture was starved out at 11 minutes without printing a line. Needs an idle box
and one render, then either a fix or a note that the capture invented it.

## Phase -1.8 — what verifying the integration-ABC merge left open (2026-08-22)

Filed by `GATES-ABC-VERIFY` (see `ralph/DONE.md`). Each of these was found by
reproducing something in the RUNNING game, and each is left open on purpose
rather than half-fixed inside a verification pass. Full evidence in
`ralph/reports/OWNER_PLAYTEST_RECONCILIATION_2026-08-22.md`.

### CATCH-FEEL — the throw lands about a third of the time · `model: sonnet` · `tests: smoke_gate_a_opening_segment, smoke_controller_catching` · OP9 / prompt 45

**CORRECTED after more runs.** Over **27** physical launches on the fixed aim
path: **6 strikes, ~22%** — not the 36% an early 11-launch sample suggested.
Every run now catches (3/3 after the aim fix, on launches 3, 7 and 1), so this
no longer blocks the chapter — `catch_math.gd`'s tutorial failure bound
guarantees the catch on the second LANDED throw. But two thirds of throws
missing is the owner's OP9 ("current throw aiming feels bad") stated as a
number, and the blind playtest independently reached the same place from the
other side: at that rate Grandpa's opening 15 orbs is about two attempts, and
nothing on the route restocks before Tam unlocks the recipe.

**It is worse than an average, because the tutorial's safety net needs TWO
landed throws.** `catch_math.gd::apply_failure_bound` guarantees the catch on
the second LANDED throw, and `smoke_gate_a_opening_segment.gd` spends eight
orbs. At a 22% strike rate the chance of landing at most one in eight is **45%**.
Run-level observation matches: **3 of 5 fresh-save runs caught, 2 did not**,
both failures reading `eight natural weakened-target launches produced 1
strike(s), 7 miss(es), and no catch` on the FIXED aim path.

So the honest state is: the aim defect is genuinely fixed, and roughly **half**
of fresh saves still cannot complete the chapter's first taught mechanic within
the orbs they are given. Gate B sits downstream of this beat, and the Gate A
continuous core cannot reliably get past it either — which is why the
build/gather/sleep segment behind it is currently unproven end to end.

**Do not fix this by widening the assist reticle without playing it.** Two
separate things were already wrong here and both were mistaken for odds tuning
— see `dc4724b` (the aim loop drove the rig PIVOT's yaw while the aim camera
sits offset over the shoulder) and `d1ec734` (the throw button had no pad
binding at all, so nothing was ever launched). A third round of "raise the
numbers" without reproducing first would be the same mistake again.

### ORB-BLOCKED — your own creature eats your orbs, silently · `model: sonnet` · `tests: smoke_controller_catching`

The blind playtest logged three of eight throws with `first_hit=AllyCreature`
or `first_hit=Body` — the player's own creature and their own trainer intercept
the orb. It is spent (`throw_aim.gd::_spend_orb()` runs before flight resolves)
and the only feedback is the generic `"the orb went wide"` from
`combat_manager.gd::_on_orb_missed()`. Nothing says what actually happened, so
the mechanic reads as random. Compounds CATCH-FEEL directly.

At minimum the refusal should NAME the blocker. Whether the orb should be
refunded, or the throw should pass through the ally, is a design call.

### MAP-FOG-LANDMARKS — the other half of owner directive §3 · `model: sonnet` · `tests: test_map_fog`

§3 has two halves. "The village and the roads out of it start revealed" shipped
in `GATES-ABC-VERIFY` (`map_landmarks.json`'s `starting_reveal`, pinned from
both sides by `test_map_fog.gd`). "**Named landmarks show as icons through the
fog** once an NPC has told the player about them" did not, and was filed rather
than half-built: it needs a "somebody told me about this" state distinct from
`map_state.gd`'s existing `_discovered` ("I have stood next to it"), plus the
dialogue hooks that set it. Do not conflate the two states — the whole point is
that a landmark can be known of and unvisited.

### HUD-JUDGE-5 — five UI defects a blind critic named · `model: fable` · `tests: smoke_hud_handheld_legibility, smoke_prompt_hotbar_dock`

From the blind visual pass over `shots/_diag/hud_*.png` at 1280x800, the Ally's
own panel resolution. The sixth defect it named (the same button labelled twice)
is fixed; these five are not:

- the party panel is too transparent to stay legible over dark scenery —
  "Ripplet Lv 1" loses contrast where the hilltop shows through, while the same
  rows over sky read fine;
- the objective text wraps raggedly, "creature." alone and right-aligned on its
  own line;
- the satiety block is clipped by its own panel: "FOOD" and "100%" run to the
  edge with no padding, amber on amber;
- four near-identical white-cross icons sit in hotbar slots that appear empty —
  "if four slots are empty they should look empty, not each hold a phantom icon";
- an unexplained underline strip under the bottom legend, read as "a progress
  bar at 0% or a leftover debug element".

It also named what WORKS and a later pass should not undo: the trainer's
silhouette and ground contact, and the party panel's information hierarchy —
the KO state "genuinely clear at a glance... already better than programmer UI".

### LANDMARK-BLACK — the hilltop landmark renders unlit · `model: sonnet` · `tests: visual`

In all four weather frames the ridge-top rock-and-tree cluster — the thing the
opening composition points at — renders as a near-black cutout with no internal
form, while the grass beside it is fully lit, with stair-stepped alpha edges
distinctly cruder than the tree at frame right. The blind critic ranked it the
second-biggest gap from the references and read it as a bug rather than a
choice: "nothing else in the scene is that dark". Possibly a material or
LOD/billboard fault rather than composition. D1's, but worth a look before the
regional pass tunes anything around it.

### OBJECTIVE-LEVEL-UP — level-up feedback was never driven on screen · `model: sonnet` · `tests: new`

OP11 asks that a level-up announce identity, new level and any unlock. Nothing
in this pass drove a level-up and read the resulting on-screen text, so it is
recorded NOT VERIFIED rather than assumed. `smoke_tournament_bracket.gd` fights
real rounds and would be a cheap place to assert it.

### HUD-JUDGE-2 — the five UI defects the second blind judge named

`ralph/reports/OWNER_PLAYTEST_RECONCILIATION_2026-08-22.md` Addendum 5. All five
read off frames rendered AFTER the HUD lineage landed, so they are current, and
all five are cosmetic rather than functional:

- the persistent legend out-shouts the contextual prompt it sits above
  (`exploration-prompt.png`) -- the judge's own words, "it wins a fight it
  should lose";
- the hotbar leaks past the dialogue panel, leaving a stray slot 5
  (`dialogue-panel.png`);
- `"Catch your first wild / creature."` orphans its last word, right-aligned,
  in all seven UI frames;
- four of five hotbar slots draw near-identical icons -- at 30% they read as
  one item repeated;
- `[C]` bracket-text sits beside boxed key glyphs in the same legend: two
  visual grammars in one line, and the gray makes `[C]` read as disabled.

NOT taken on the verification branch on purpose. This is HUD-EMPHASIS lineage
work that has already been through its own blind-judge rounds; re-tuning widths,
alignment and z-order at the end of a verification pass risks regressing what
those rounds bought, for defects that cost the player nothing functional.

Two of the judge's findings are deliberately NOT here, and the next firing
should not re-add them from the report: the combat-prompt "text collides with
text" was a capture artefact (fixed in `capture_ui_glyphs.gd`), and the "RB
named twice" duplication was read off `_diag` frames rendered forty minutes
before `f6fe2932` fixed it.

### BOARD-BRACKET — the tournament board's lines do not join

The names are legible and read as real village record-keeping, which is what the
owner directive asked for. The bracket PLUMBING is wrong: round-two joins sprout
horizontal strokes that float and never meet the semifinal cleanly, and the
final dangles into empty panel with no slot label. The right half of the board
is empty gray. Anyone who has seen a bracket reads this one as drawn wrong.

Also from the same frame: the board FACE is a flat untextured gray-green with
vector-crisp hairlines and the HUD's own sans-serif, inside a frame-and-posts
that do read as carpentry. Judge's summary -- "carpentry frame, UI panel face".
Needs a texture pass, which is small art rather than scene work.

### STARTER-PORTRAITS — two of three starters face away from the camera

`starter-picker.png`: Terrapup presents a readable 3/4 view, Ripplet is side-on
with its face barely resolved, Galewisp shows its back. This is the single
moment the game asks the player to choose a permanent companion BY APPEARANCE,
and two thirds of the choices hide the thing being chosen. The poses differ
again in `name-prompt.png`, so these are live renders with uncontrolled framing
rather than authored portraits -- the fix is camera control on the picker, not
new art. The judge rated the creature designs themselves as the strongest thing
in the whole frame set, which makes the framing the only thing in the way.

### CATCH-FEEL: the ~3% strike rate was the stale-aim harness, not the mechanic

**Supersedes BOTH entries below, including the "straight reticle" one, which was
wrong on two code facts I asserted without reading the functions involved.**

What the code actually does, read this time rather than inferred:

- **`launch_assist_max_distance` bounds the LEAD, not the range.** In
  `predict_launch_point()` the clamp is `lead = predicted - centre`, then
  `if lead.length() > max_distance`. It limits how far AHEAD of the creature's
  centre the aim point may be pulled -- a guard against a pathological velocity
  snapping the aim across the arena. A throw at 6m is assisted exactly as much
  as a throw at 2m. The comparison against `flow.engage_range: 6.0` was
  meaningless: the two numbers measure different things.
- **The launch is already ballistic.** `_launch_direction()` returns
  `_ballistic_direction(origin, point, ...)`, which solves the low arc that
  LANDS on the aim point. `_aim_direction()` carries a comment recording that
  exact fix and why. "A straight reticle aiming a ballistic orb" describes a bug
  that was fixed before I filed it.

What the measurement was. The 40-throw and 33-throw runs that produced ~3% were
taken on the build with the stale-aim regression -- the step-aside moved the
player AFTER the aim, so every throw was aimed from a position the player had
already left. Fixed at `ab4ae014`. Re-run on the fixed build, the Gate A opening
catches Bramblebun **on launch 1**, range 3.61m, assist applied, offset 0.60.
One throw, one strike.

So the eliminations below stand -- it was never the catch roll, and it was never
the reticle geometry -- but the headline number was an artefact of my own
harness, and the mechanism I proposed to explain it does not exist. What is
carried forward is the instrumentation: `orb.gd` now reports each miss's closest
approach, what it needed, and what ended the flight, and `throw_aim.gd` logs the
throw range and launch direction at release. A future "the throw feels bad"
report gets answered with those numbers instead of a fourth theory.

Then the Gate B run found the thing that was actually broken, and it was not the
catch at all. See the entry below.

Open, honestly: the strike rate is measured on a harness aimer, not on a human
with a thumbstick. What is now closed is the half a harness CAN answer.

---

### CATCH-FEEL, the real one: the trainer walks away from their own throw

`throw_aim.gd::_enter_aim()` hands the trainer locomotion and `_leave_aim()`
takes it back. A RELEASED throw goes through neither: it keeps the aim camera
deliberately ("watching your own orb arc away is the shot") and sets `state`
directly. So from the moment the orb leaves the hand, through the flight and
through the whole catch resolution, the trainer is still a live walking actor.

Measured in the Gate B continuous run, 2026-08-23:

| | at release | at breakout |
| --- | --- | --- |
| trainer | z = -37.5, 3.34m from the Bramblebun | z = -20.4 |
| wild | z = -40.2 | z = -40.3 (had not moved) |

A second run caught it mid-stride: at the breakout, `movable=true`, velocity
**5.00 m/s**, 24.38m from the wild.

Every throw after that was made from twenty-five metres. At `speed` 17 under
`gravity` 14 an orb cannot reach past v²/g -- about twenty metres -- so
**nineteen consecutive orbs were spent on throws that were never physically
capable of landing**, each reported to the player as the same four words: "the
orb went wide". That is the owner's *"I never know if I was close"* exactly: the
reticle promises, the orb falls eighteen metres short, the orb is gone.

Fixed in three parts, one per half of the failure:

- `_set_trainer_movable(false)` at release. The root cause -- and it also
  restores the resolution as a shot, since the camera is in close on the orb for
  those seconds while the trainer was jogging out of the county.
- A locked-on throw beyond ballistic reach is refused rather than spending the
  orb. Gated on the committed assist point, so deliberately lobbing an orb at the
  ground in front of you is still legal.
- A miss reports how near it came and what ended the flight, so a graze and an
  eighteen-metre miss stop reading identically.

`tests/test_throw_reach_and_miss_message.gd` pins both pure functions. The
forensics stay in the shipping code: three wrong diagnoses came out of a miss
that reported one word.

---

**Superseded, and wrong -- kept only so the mistake is not repeated.**

### CATCH-FEEL root cause: a straight reticle aiming a ballistic orb

**Supersedes the entry below, which was measured through a broken harness and
drew the wrong conclusion twice.** Read this one.

Two clean runs (2026-08-23, after the stale-aim regression was fixed):

| | gateb21 | gateb22 |
| --- | --- | --- |
| throws eligible (reticle on the body, clear line) | 28 of 40 (70%) | 25 of 33 (76%) |
| `first_hit` was the Bramblebun | **40 of 40** | **33 of 33** |
| actual strikes | 1 | 1 |

**Every single raycast hit the creature. Aim was never the problem.** Seventy-six
percent of throws had the reticle genuinely inside the target body with clear
line of sight, and roughly three percent landed.

The mechanism, read from the code rather than guessed:

- `orb.gd` is **ballistic** -- "a real projectile on a real arc", gravity 14.0,
  and deliberately so: §15 forbids throwing without player aim and "a hitscan
  gives nothing to aim".
- `throw_aim.gd::launch_assist_diagnostics()`'s `eligible` means only *in front*
  + *reticle inside body* + *raycast reaches target*. It does **not** consider
  distance.
- `launch_assist` is what reconciles a straight reticle with a parabola, by
  leading the launch. It is bounded by `launch_assist_max_distance: 2.6`.
- `combat.json`'s `flow.engage_range` is **6.0**.

So past 2.6 metres the game shows a reticle sitting on the creature, then throws
an unled parabola at it. The miss is systematic, not unlucky, and it is exactly
the owner's *"I never know if I was close"*: the feedback says on-target and the
orb goes elsewhere.

**What is verified vs inferred.** Verified: the eligibility rates, that every
raycast hit the target, the strike counts, that `eligible` ignores distance, and
both config numbers. Inferred (strongly, but not directly measured): that the
throws in these runs happened beyond 2.6m, so the assist never applied. The
harness engages within a 6m range and does not currently log throw distance --
**logging it is the one measurement that would close this**, and it is a
one-line addition to `_log_launch_assist`.

**The lever, if the inference holds:** raise `launch_assist_max_distance` to
cover `engage_range`. That is not a feel judgement -- it is two configs
disagreeing about how far away a fight is, and the assist exists precisely to
make an aimed throw land.

---

**Superseded, kept because its eliminations are still true.**

### CATCH-FEEL measured: the difficulty is AIM, not the roll

Ninety-eight launches across the 2026-08-22/23 evidence runs, tallied by the
reason `throw_aim.gd::launch_assist_diagnostics()` reports before each orb is
committed:

| reason | count | share |
| --- | --- | --- |
| `reticle_outside_body` | 51 | **52%** |
| `eligible` | 34 | 35% |
| `line_of_sight_blocked` | 13 | 13% |

**Only about a third of throws are even eligible.** The ~22% strike rate is not
a catch roll being unkind -- it is that half of all throws never have the
reticle on the creature, and an eighth have something in the way. OP9 has been
carried as "catching is too hard", which reads as a probability complaint; the
data says it is an aiming complaint, and those have different fixes.

Two shipped numbers worth the owner's eye, both in `data/config/catching.json`,
whose own header says "ALL of it is TUNABLE... the expected feedback is
'catching is too hard', 'aiming is fiddly', 'I never know if I was close' --
every one of those has to be answerable by editing this file":

- `launch_assist_reticle_fraction: 1.0` -- the reticle must sit inside the body
  radius to earn any launch lead. A near miss earns nothing.
- `launch_assist_max_distance: 2.6` -- **but `combat.json`'s `flow.engage_range`
  is 6.0.** So the assist covers less than half the distance at which fights
  actually happen. Past 2.6 m a player is throwing unaided at a moving target
  through a wind-up.

That mismatch is not a feel judgement, it is two configs disagreeing about how
far away a fight is.

**Deliberately not tuned here.** These runs aim by aligning the camera's forward
vector to the body; a human aims at a reticle they can see, and the two are not
the same aimer. A number changed on harness evidence alone would be tuning feel
by proxy. What the owner needs is the lever and the measurement, which is what
this entry is -- the honest next step is one owner pass with
`launch_assist_max_distance` raised to cover the engage range, and BP2's
interception fix already in (orbs now pass through your own creature).

### DEAD-REST — `home_recovery.gd` has no production callers

Found while reconciling prompt 61's "two rest semantics coexist" note. They do
not coexist; one is dead.

`scripts/creatures/home_recovery.gd::rest()` is an instant `heal_fully()` plus
rest XP. Across the whole project it is **preloaded once and invoked never**:
`scripts/ui/creature_bed_panel.gd:25` holds the `const`, and no line anywhere in
`scripts/` or `autoload/` calls it. Its only callers are two TEST files --
`tests/test_fainting.gd` (8 sites) and `tests/smoke_stronghold.gd:254`.

The live path is `autoload/game_state.gd`: `_tick_creature_bed_recovery()` heals
gradually per frame from `progression.json`'s `creature_bed.full_heal_seconds`,
and `complete_creature_bed_rests()` pays the full-rest bonus overnight. That is
the path `smoke_gate_a_rest_torch.gd` asserts on ("bed recovery was not
gradual"), and it is what the stronghold's rest point actually uses, because
`stronghold.gd::_build_recovery_point()` builds a real `CREATURE_BED`.

**Why this is worth an entry rather than a deletion right now.** This is the
same shape as the twelve stale harnesses this branch already fixed, one step
further along: `test_fainting.gd` passes, and what it proves is that a function
nothing calls behaves as written. `conventions.md`'s own rule -- "a test that
passes because the feature is absent is worse than no test" -- covers this from
the other side.

`smoke_stronghold.gd:254` is the sharper case: it calls `HOME_RECOVERY.rest()`
directly to simulate the stronghold's recovery, so it asserts against a code
path the game does not take at that point in the chapter. It would keep passing
if the real bed recovery broke.

The work: decide whether `home_recovery.gd` is deleted (and `test_fainting.gd`'s
eight sites retargeted at the live path) or given a real caller. Not done here
because deleting production code and rewriting two suites is not a change to
make at the end of a verification pass -- but it should not sit unnamed either.
`stronghold.gd`'s comment, which claimed the reuse that was not happening, is
corrected on this branch.

### CONTINUOUS-CORE — the village/gather/build continuation has never run

Gate B cannot be proven end-to-end until this passes. Everything below is
observed, not inferred.

**It is unreachable, and has been since `integration-ABC`.** The village,
material-route and paid-build segments live inside
`smoke_gate_a_opening_segment.gd` behind `--gate-a-continuous-core`, and **no CI
shard has ever passed that flag**. Two worktree runs at `a22534ff` on
2026-08-23 settled what that means:

| worktree run | outcome |
| --- | --- |
| base harness, base gameplay | dies at boot: `required action 'combat_throw' has no physical joypad binding` |
| CURRENT harness, base gameplay | dies at the catch: `launch 1 left the satchel empty; the opening is now a dead end` |

So there is **no working baseline**. The path could not have been exercised at
that merge by any route, which is why the axe-swing failure below cannot be
attributed by comparison — nothing ever reached it. (The second row is also an
independent confirmation of the orb-floor dead-end, reproduced on untouched
base code by a harness that had never seen it.)

**Where it fails now**, with the diagnostic added on this branch:

```
physical interact on the node did not start the visible axe swing
(arbiter winner=Interactable, equipped=, prop=<null>, cooling=false)
```

Two facts in one line. The tool is **not in the player's hand** at the moment of
the press — `equipped` is empty and `prop` is null — despite the helper's own
check three lines earlier verifying the axe was equipped AND visible. And the
arbiter's winner is a generic `Interactable`, not the harvest node the helper
selected. Something takes the tool out of hand between the verification and the
press, and the press lands on the wrong node.

Ruled out already: the hammer gate (`_hammer_opens_the_catalogue` requires
`equipped_tool == BUILD_TOOL` and returns false immediately with an axe in
hand), and swing timing (`SWING_SECONDS` is 0.45 ≈ 27 frames against the
helper's 8-frame tap, so a started swing would still register).

### Progress 2026-08-23, and the one change that would end this

**The filed defect is FIXED.** All three tools swing on this path now:

```
[swing-probe] swing_at -> true (equipped=axe)
[swing-probe] swing_at -> true (equipped=pickaxe)
[swing-probe] swing_at -> true (equipped=knife)
```

The blocker was not the game. `_gather_authored_node` pressed the hotbar slot
unconditionally, and a tool slot TOGGLES (`playground_hud.gd:2228`, the owner's
"press slot, tool in hand" directive) -- so with the tool already in hand the
press STOWED it. Two consecutive runs failing at two different points with no
code change between them is what named it.

**What is left is not one bug.** Each beat past the swing is a beat that has
never executed, and they surface one at a time, each costing a ~20-minute run.
Fixed so far: the toggle, and the door helper demanding "walk within 1.65m" when
the real condition is "walk until the world offers it, then press" (the door sat
enabled and offerable for twenty seconds while the player walked into a wall).

### CONFIRMED 2026-08-23: the extraction is REQUIRED, not preferred

Three fixes were tried against the flakiness and the evidence rejected two of
them, which is worth recording so nobody retries them:

| attempt | result |
| --- | --- |
| toggle-aware equip | **real fix**, kept -- the swing works |
| village-centroid start instead of an invented (6,4) | **did not fix it** -- Tam went from 20m to 11m away and still failed |
| sidestep when something else holds the interact line | **did not fix it** -- the player never gets close enough to sidestep |

The working diagnostic finally named the state:

```
could not activate Tam cycle 1 (7.7m away, arbiter winner=EncounterDirector)
```

**The arbiter is a red herring.** `prompt_arbiter.choose_index()` ranks by
priority then distance; `_creature_control_offer()` carries priority -1, so
Tam's ordinary offer beats it whenever Tam makes one. At 7.7m he is outside his
prompt radius and makes none, so the EncounterDirector fallback wins by being
the only offer in the world. The winner is a SYMPTOM of the distance, not a
cause.

**The player is stuck at 7.7m and cannot close.** Same shape as the door stuck
at a stubbornly identical 3.6m two attempts earlier: `_step_toward()` walks a
straight line at the target and the village has buildings in it. From a
hand-chosen start, some targets are behind geometry; which ones depends on where
you started, which is why five runs failed at five different beats.

**So the fix is not a better coordinate -- there isn't one.** Any point chosen
by hand is behind something for some target. The opening leaves the player on
the authored path where straight-line walking works, and that is not a fact any
computed centre can reproduce.

**Extract the opening from `smoke_gate_a_opening_segment.gd` into a helper and
have Gate B PLAY it.** That is now demonstrated as necessary rather than
preferred: two principled alternatives were tried and measured, and both failed
for the same reason. It also deletes the second definition of the opening path
that granting created.

Scope, for whoever picks it up: `_run()` lines 54-224 plus roughly twenty
movement/input helpers, out of a 969-line file that currently PASSES. The value
is not only Gate B -- it makes the opening a reusable segment like the village,
material and build ones already are.

---

**UPDATE 2026-08-23: the extraction shipped, and it did NOT fix this.** Recorded
because the prediction above was confident and is now measured wrong.

`tests/helpers/gate_a_opening_drive.gd` exists, Gate B plays the opening
beat-for-beat, and the tutorial catch now passes inside Gate B (launch 1 in one
run, launch 2 in another) after the trainer-locomotion fix. The player is left
where the game actually leaves them -- (22.0, 1.0, -28.0), on the authored path,
exactly as this entry argued for.

Tam is still unreachable. The distance went the WRONG way:

```
could not activate Tam cycle 1 (18.3m away, arbiter winner=EncounterDirector)
```

7.7m from a hand-chosen start, 18.3m from the real one. So "any point chosen by
hand is behind something" was true, and the authored start is genuinely more
faithful, but the conclusion drawn from it -- that faithful positioning is what
the village travel needed -- was wrong. `_step_toward()` walks a straight line,
the village has buildings in it, and eighteen metres of straight line through a
village is worse than eight.

**What is actually left is pathing, not positioning.** The village segment needs
either authored waypoints between the opening's exit and each villager, or a
real navigation query. That is a different piece of work from anything tried in
the five attempts tallied above, and none of those attempts touched it.

The catch blocker this entry was filed behind is gone; this is now purely a
harness-travel problem on the known-red continuous-core path.

---

**Superseded, kept for its eliminations -- the swing is fine, the SEGMENT is flaky.**

Instrumenting `tool_hold.swing()` itself settled it:

```
[tool-probe] swing STARTED with 'axe'
[tool-probe] swing STARTED with 'pickaxe'
[tool-probe] swing STARTED with 'knife'
```

All three started, and that run went PAST the swing and past Mira's door -- the
beat that had blocked the two runs before it -- and failed at Oskar instead.

**Across five runs with no code change between them, the segment failed at five
different beats:** the axe swing, Mira's door twice, Tam once, Oskar once. That
is not a defect in any of them. It is one flaky traversal, and each "bug" found
so far past the toggle fix has been the same flakiness surfacing wherever that
run happened to run out of budget.

So the entry below is superseded: do NOT go hunting a race inside `swing()`.
There isn't one. `swing()` refuses on exactly two conditions and the probe
confirms it starts when asked.

**What is actually wrong is upstream of all of it**, and it is the thing this
entry already named: `smoke_gate_b_continuous.gd` GRANTS the opening and drops
the player at a hand-picked (7, 4). Every beat after that is walked from a
position the game never produced, on walk budgets (1200-1800 frames) tuned for
the position it does. Some runs make it, some do not, and which beat runs out of
budget first is luck.

**The fix remains one change, not five:** extract the opening into a shared
helper and have Gate B PLAY it. Then the player stands where the game left them,
the budgets mean what they were tuned to mean, and this whole class evaporates.
Chasing individual beats past that point is chasing variance.

---

**Superseded — the earlier read of this, kept for the eliminations it records.** Run 11 printed
`swing_at -> true` for axe, pickaxe and knife and walked on to Mira's door. Run
15, same code, failed at the first swing:

```
BEFORE: equipped=axe  prop=Node3D(Axe_Bronze2)
AFTER:  equipped=axe  prop=Axe_Bronze2  is_swinging=false
```

`tool_hold.gd::swing()` refuses on exactly two conditions -- `_equipped.is_empty()`
or `is_swinging()` -- and the diagnostic shows NEITHER holds. The tool is in
hand, nothing is mid-swing, and the swing still did not start. It should have
returned true, and in run 11 it did.

So this is not a logic error to be found by reading; it is a race, and the next
session should instrument INSIDE `tool_hold.swing()` and `_sync_equipped()`
rather than re-derive the above. Note `SWING_SECONDS` is 0.45 (~27 frames)
against the helper's 8-frame tap, so "the swing finished before the check" does
not explain it either -- that was ruled out on 2026-08-22.

**Also stuck at Mira's door** on runs that get past the swing, and the shape of
that matters too:

```
could not reach or activate door 'Door' in 1200 frames
(player 3.6m away, prompt enabled=true)
```

The SAME 3.6m across runs. A distance that does not shrink is the player walking
into geometry, not walking slowly -- and the arbiter never offers the door from
there.

**The likely root is the granted opening, and that is the thing to fix.**
`smoke_gate_b_continuous.gd` grants the opening beat rather than playing it,
then places the player at a hand-picked (7, 4). That was flagged as a risk when
it was taken and has now caused three position-dependent failures in a row:
Tam unreachable, then the same at 112m after a respawn, now this door. The
harness is approaching the village from wherever a made-up coordinate put it.

So the fix is not another position tweak. It is to **extract the opening from
`smoke_gate_a_opening_segment.gd` into a shared helper** the way the village,
material and build segments already are, and have Gate B PLAY it. Then the
player stands where the game left them, every time, and this whole class of
failure cannot occur. It also removes the second definition of the opening path
that granting created -- the exact drift this branch spent the night fixing
twelve times over.

**CI now runs it** as `verify-continuous-core-known-red` with
`continue-on-error: true`. That is temporary and the comment there says so: a
job that runs and reports red beats a flag nothing passes, because the failure
is visible on every run instead of invisible forever. **Remove
`continue-on-error` when this is fixed.**

Worth stating plainly for whoever picks this up: `ralph/DONE.md` described this
path as working. It has never run. That is the twelve-stale-harnesses finding
one step further along — not a test asserting a dead pad map, but an entire
evidence path nothing could execute.

## Phase -1.7 — what the blind critics found once Gate A's defects were fixed (2026-08-22)

These are remainder items recorded per `conventions.md` rather than iterated on
further. Each was named by an independent Fable critic judging rendered frames
with no knowledge of what changed and no sight of prior critiques.

### WEATHER-2 — the lighting rig does not participate in the weather
OP21-21's washed-out grey is **fixed and independently confirmed**: fog now
reads as deliberate morning mist and the critic called it the best of the four
states. Measured saturation went 0.18 -> 0.36 with four hue families recovered,
`clear` is weighted 3.0 against the others, and `max_consecutive_non_clear: 2`
bounds any grey run. What the same critic found instead:

- **`cloudy` is now crushed, not washed out.** Ground measured ~(20,30,3), the
  darkest of the four, and there are **no clouds** — it is the clear-sky dome
  desaturated. Real overcast light is flatter and often *brighter* in shadow;
  this preset does the reverse. The critic's read: "did my brightness setting
  break?" It is the one state a player would report as a fault.
- **The sun shadow is identical in all four states** — same angle, same
  hardness. Clear earns it; cloudy, fog and rain contradict it. Quoted:
  "one lighting rig with a dimmer and a sky swap, not four weathers."
- **Weather never touches the ground.** Rain has no wet grade or specular
  response and its streaks are invisible against terrain, so the lower two
  thirds of the frame is just "cloudy, bluer." Fog sits at the horizon only —
  the midground is as crisp as clear, so it reads as a backdrop rather than
  atmosphere you stand in.
- **Foreground values are crushed in the dark states**, near-black green in
  exactly the screen region the player watches. Marginal on a 7-inch panel.
- Grass tufts render at identical acid brightness in every state, reading as
  faintly emissive under cloudy and rain.
- Present in all four and so not a weather defect: the crest tree/rock cluster
  renders near-black even under full sun, which reads as an unlit material.

Highest-value single change, per the critic: give `cloudy` real cloud cover and
**raise** ambient while softening the sun shadow, instead of dimming everything.
That also stops cloudy and rain reading as near-duplicates. All fixes are
in-scene grade/lighting work; none need new art.

### TWO-SUNS — there are two suns in the sky at golden hour
`site/img/camp-dusk.jpg` (now deleted) has two orange discs in the upper sky,
one upper-left and one upper-centre. Captured through `WorldLook`'s own
`golden` preset in `data/config/art.json`, so this is what the preset renders,
not a capture-harness artefact — a second sun quad, or a sky element
duplicated by the preset. An independent blind critic found it in the first
second of looking. Everything else in that frame is among the better lighting
in the build, which is why it is worth fixing rather than reshooting around.

### SITE-ART-DEBT — what a blind pass found across the whole frame set
An independent critic judged every committed page frame against
`docs/reference/tetherbound-meadows-keyart.png` with no knowledge of what had
changed. Six frames were pulled outright (see the note in `site/index.html`'s
CSS). What it found across the rest is scene/art work, not page work:

- **The sky is a bare vertical gradient in every daylight frame.** The key art
  has cumulus in all seven panels. Named the cheapest available upgrade and the
  main reason the wide shots read as empty.
- **One green, foreground to horizon**, with mown-lawn striping visible in
  `hero-meadow`. The key art's ground is flower drifts, dirt breakup, rock
  scatter and shaded pockets.
- **A white floating quad** appears in `01-spawn-outward`, `03-rise-overlook`,
  `06-charged-attack-lands` and `aim-arc` — same artefact, four frames. `06`
  also has the `SKY-PLANES` translucent rectangles in it.
- **Cube-with-a-rock-texture architecture** at the gate and the relay: no
  silhouette, no trim, no scale cues, and the relay's walls read as knee-high
  edging beside a 3m gateway. Human figures inside it are dwarfed 4–5x by the
  pylons.
- **Team Tether's oxblood has not landed.** In the key art it is the danger
  colour on their banners; in the build their only signature is a teal glow
  line that reads as a friendly waypoint path.
- `village-talk` clips a HUD panel mid-word at the left edge and puts white
  objective text over an orange roof.

Verdict on the two bar questions: does it read as the key art's world — **no**,
though `mill-crossing` and `village-square` get within reach; does it read as
the same kind of game as the Palworld references — **from `aim-arc` and
`02-arena-opens` alone, yes**, from the whole set, no.

### SPOKE-VIEWS — `tools/capture_severed_spokes.gd` photographs empty meadow
Its seven viewpoints are pre-`OW5B`/`OW5D` and put the eye ~700m from where
these roads now are: `stone_gate`'s eye is `[-164, -1.3]`, the sealed gate is
at `[-688.9, 2517.9]`. A run using them renders open grass and reports success.
`data/config/terrain_playground.json`'s `spokes.routes` carries the live
numbers (last road point + blocker centre) and `tools/capture_site_story.gd`
now reads those; the spokes tool should do the same rather than hold a second
copy. Nothing is wrong with the spokes themselves — shot from the right place
they read exactly as intended, a sealed arch with a live Tether pylon beside it
and the conduit line running away.

### LEGENDARY-CAGE — the containment VFX renders as flat white slabs
`stronghold_climax.gd::_build_cage()` asks for a cold teal ring (`#7fd8c4` at
energy 2.2). Under the project's own GL Compatibility renderer the emissive
clamps and the ring photographs as a dozen opaque white bars across the animal
— see `site/img/legendary-bound.jpg`, which is the chapter's last image and its
worst-looking one. The stag behind them is fine. Likely fixes: drop the energy
below 1.0 and carry the colour in albedo, or make the bars thinner and
translucent, or both. Judge it from a capture, not from the inspector.

### SITE-SHOTS — the story page is written, and four of its frames need a Godot run
`OP21-22` is done: `site/index.html` is rewritten around the actual premise
(Team Tether back and draining the land, Grandpa too old for the journey, the
player steps up, five creatures, the village trainers and Oskar's South Bridge
Key -> Warrens -> relay -> captains ->
Warden -> the region heals), with the road to Meadows Hall as an ordered
six-leg journey and the reserved tether teal used only where Team Tether is.

**Update, same day, second pass.** The owner read the page and rejected it:
the frames were stale, the starters do not stand by the door any more, and the
stronghold is nowhere near the village. Godot 4.7 was installed into the
session container by hand (it is not in the image), the project imported, and
`tools/capture_site_story.gd` + `tools/capture_roster_ordinary.gd` written and
run — so the page now carries ten new frames and the story is rebuilt on
`GAME_DESIGN.md` §3 as amended by `D23`, `MEADOWS_PROGRESSION_SPEC.md` §23–31
and `docs/OPENING_SEQUENCE.md`. What is left from the first pass is below.

The first pass could not capture anything: **no Godot in the session's
container**, so the page was rebuilt from the frames already committed. Judging
those frames honestly against the page's own no-misrepresentation rule cost two
of them, and both are now deleted rather than left committed-and-broken:

- **`opening-bedroom.jpg`** was an undressed white blockout room with a bed,
  under the caption "First light in Grandpa's farmhouse". The section keeps its
  copy and runs three figures instead of four.
- **`village-square.jpg`** was ~70% roof tiles: the `village-square` viewpoint
  in `tools/capture_site_shots.gd` puts the camera inside a roof. Coordinates
  left alone and the defect commented in the tool — re-aiming a camera in a 3D
  scene is not a blind change.

The captures wanted, in value order, all needing one Godot session:

1. **`tether-site.jpg`** — a close frame of a relay site: pylon ring, cabling,
   drained ground. `.s-tether` is wired for it already and falls through to
   `03-rise-overlook.jpg`, which has all three in the middle distance but too
   small to carry the section. Highest-value shot the story page lacks.
2. **Meadows Hall approach** and **the Warden**. The road section ends at both
   and shows neither.
3. Re-aim `village-square`; dress and re-shoot the farmhouse interior.
4. `camp-dusk.jpg` has untextured orange spheres floating over the horizon;
   `weather-rain.jpg` is flat overcast with no readable rain (its caption was
   rewritten to say "grey" rather than promise rain the frame does not show).
   The second overlaps `WEATHER-2` above — fix the weather, then re-shoot.

Also closed in passing: all fifteen `site/img/*.jpg.import` Godot sidecars were
committed and published to Pages despite `site/README.md` telling everyone not
to since the page was written. Untracked, and `site/img/*.import` is in
`.gitignore` now so the rule enforces itself.

**Update, 2026-08-23, third pass.** All four captures landed; `site/README.md`
carries the per-frame detail now rather than duplicating it here. Findings
worth keeping in this ledger:

- **`village-square.jpg` was already fixed before this pass started.**
  `capture_site_story.gd`'s own viewpoint (not `capture_site_shots.gd`'s, which
  is still deliberately broken per item 3 above) landed on `main` in `6cdf8dc9`,
  before this session existed. This section's "captures wanted" list and
  `site/index.html`'s own CSS comment both still said the file was absent; both
  were reconciled against the real committed image rather than re-derived from
  stale prose. Evidence-backed already-fixed, `CLAUDE.md`'s own rule.
- **`tether-site.jpg`** — first-guess camera coordinates, computed from
  `tether_relay.json`'s own site frame rather than eyeballed, rendered clean on
  the first Godot run. Sited on the west-run pylons: a lit pylon close in
  frame, sagging cable to its neighbours, drained ground, the compound wall
  and open gate behind it.
- **The Warden** — took three renders, not one, and the failures are the
  reusable finding. First: `focus_node: "WardenTrainer"` is
  `stronghold_climax.gd`'s trainer *placer*, parented to the world and never
  itself moved — the camera landed at world (0,0,0), the village, not the
  stronghold. The body is a child of the placer, named from trainers.json's
  own `name` field (`"Warden Aldis"` for `warden_aldis`) — that is what a
  `focus_node` tree-walk actually needs. Second: with the right node, a wide
  3/4 frame was mostly black void — the Warden Arena has no window and only
  faint trim-light fill (`stronghold.gd`'s `OmniLight`s default to energy
  0.5). Third, and shipped: a close portrait crop, which reads as a
  deliberate low-key reveal rather than as underexposed.
- **`opening-bedroom.jpg`** was not re-dressed, only re-verified. The loft
  already has a real `BedTwin` and nightstand (`grandpa_house.gd`'s furniture
  pass); the "undressed white blockout" description was of the stale
  committed frame, not of current `main`.
- **`camp-dusk.jpg`** — re-verified, not re-fixed. A fresh capture's sky is
  clean; whatever produced the "two orange discs" this item originally
  described does not reproduce now. No second `DirectionalLight3D` or second
  sky material exists in the scene or the tool, so there was no code path to
  fix even if it had reproduced.
- **`weather-rain.jpg`** — re-verified, not re-shot. A fresh capture is
  near-pixel-identical to the committed frame: real rain streaks, visible on
  close inspection, deliberately faint by an already blind-pass-validated
  design (`world_weather.gd`: "a faint, mostly-transparent line, not a light
  source"). Nothing here was a capture bug.
- **Meadows Hall approach (`.s-hall`) stays gated**, and the reason changed.
  `STRONGHOLD-MAT` landed (`97f4ff32`, unrelated lane) — the stronghold has
  real textured masonry now. `SKY-PLANES` has not: a fresh capture from the
  approach viewpoint shows several large translucent quads standing directly
  behind the hall, dominating the skyline. Its root cause
  (`rift_collapse.gd`'s `StormWall`, at the storm_road blocker) reads as a
  different, distant site, but the defect is visible from here too — do not
  re-wire this figure on the strength of the root-cause location alone
  without rendering the actual approach viewpoint again first.

### PERF-LOD — Terrain3D vegetation LOD is written, tested and deliberately switched off

All ~130k vegetation instances render at LOD0 regardless of distance. `lod0_range`
and `fade_margin` are a real working lever — semantics verified against upstream
Terrain3D 1.0.2 source, not guessed — and per-layer values already exist in
`data/config/vegetation.json`. The two `asset.set()` calls in
`scripts/world/vegetation.gd` that activate them are commented out behind a
`TODO(PERF-2)`.

They are off **on purpose**. `conventions.md` requires a blind pass for
visual-affecting work, and no before/after frames have ever been produced, so
activating it would ship an unverified change to the approved lush pond pocket
and the open-field contrast. Two lanes independently reached that judgement and
both left it inert rather than shipping on no evidence.

**Four capture attempts have now failed, all the same way.** The last was a
single continuous foreground run that reached **43 minutes** (past an 1800s
bar) and never emitted either view. The world stands up fine during the run —
129,723 props scattered, village/stronghold/relay placed, no errors — so the
tool is not broken. Box load went from 1.00 at dispatch to 8.7–12.6 within
minutes as other lanes entered their own render phases.

**CORRECTED 2026-08-22 — the diagnosis above was wrong.** This entry
originally blamed `playground_world.gd::_ready()` standing up village, trainers,
quarry, relay, river and stronghold. That was plausible and false. The real
cause is that **`--headless` combined with `--rendering-driver opengl3` hangs
forever**, verified on a bare `ColorRect` with no project scenes at all; drop
`--headless`, keep `xvfb-run`, and the same script renders in under a second.
See `ralph/conventions.md`'s art-pipeline traps for the correct invocation.

The world was never the problem: one lane got through the full Meadows
stand-up, 129,723 scattered props and a 240-frame settle in about 50 seconds on
an idle box. **The LOD capture very likely just works once the invocation is
fixed** — it needs no minimal scene and no reduced `SETTLE_FRAMES`. Try it
before assuming anything else is wrong.

Worth keeping in perspective: the two large measured performance wins already
landed (the missing scatter bake, ~45x on load; the O(n^2) interaction-provider
registration, ~5x on boot). LOD is an unmeasured speculative lever on top of
those, which is why it is recorded here rather than forced through.

### BUILD-KIT-4 — what round 3 left
Tracked in `BLOCKED.md` for the parts needing an owner decision. Not blocked and
still open: interior cross-braces read as scaffolding from inside (real geometry
within the 0.4m wall thickness, not a double-sided plane — investigated with a
scoped `cull_mode` probe), the corner-seam fix is not visually verified, the
door leaf sits proud of its frame at the top hinge, and a stray grey brick block
sits behind the interior braces.

## Phase -1.6 — the owner played the mid-build (owner-reported, 2026-08-18)

**Reported from a real ROG session mid-build, verbatim notes.** This is the
instrument no test in this repo substitutes for, and it outranks the visual
convergence work that was running when it arrived: **several of these make the
game unplayable, not ugly.**

Ordered blockers first. Where an item repeats an earlier report the earlier one
is named, because the symptom coming back means the mechanism was never fixed —
this project's own header rule from Phase -1.5.

### Already in flight — VERIFY BEFORE YOU BUILD

**Added 2026-08-18 (OPS18) at the owner's instruction:** *"if some of these, like
the torch fix, is already in flight you can take it off the list or tell it to
just verify if it's still a problem when we get to that item."*

Nothing is deleted, because **in flight is not the same as fixed** and this
project has twice sent a lane to rewrite code that already existed. Instead each
overlapping item carries what is already running against it. **When you reach one
of these, reproduce it on current `main` first. "Already fixed by X, here is the
evidence" is a complete and valued outcome and it is faster than the work.**

| item | already running / landed | what to verify |
|---|---|---|
| `RG1` `RG4` `RG5` `RG6` | **`RG-INPUT` lane, launched** | it owns all four; do not open a second lane on them |
| `RG2` `RG9` `RG10` `RG22`(hand) | **`RG-GATHER` lane, launched** | same — one lane owns the gathering queue |
| `RG11` stones like white paper | **`MAT-BLOCKOUT`, root-caused, on `ralph/MAT-BLOCKOUT`** | **very likely already fixed.** Its diagnosis: `harvest_node.gd` loaded `Rock_Medium_1/3.gltf` via `load()+instantiate()` with **no material treatment at all**, so the picked-up rocks kept their native cool grey (value 0.46, saturation 0.09) while `vegetation.gd`'s scatter warms the *same models* toward stone tones. One model, two looks, depending on which system placed it. Re-shoot before doing anything |
| `RG22` torch brightness | **`NIGHT-LIGHT` lane** owns `torch.gd`'s light path | it is separately establishing whether the torch is lit **at all** at night — `OF18` found the auto-torch silently never fired for the feature's whole life. Do not tune brightness until that answer exists |
| `RG21` progressive day/night, short night | **`NIGHT-LIGHT`** is inside `art.json`'s presets | adjacent, not the same: that lane is fixing *legibility*, this item is *transition and length*. Coordinate rather than both editing `art.json` |
| `RG20` no creatures anywhere | **`VEG-SITING`** was asked to investigate and report, not fix | read its finding first — it may already name whether this is spawn siting, density, or where the cameras point |
| `RG23` invisible blockers | **`SPINE-WEDGE` + `RIVER-GATE` landed**; `CORRIDOR-FIX` in `integrate-9` | the *invisible blocker* half is a known family — `CarveFailsafe` `Area3D` volumes and a spoke's 146 m severing trench, both fixed. Re-walk before assuming it survived. **The missing-collision-on-rocks half is genuinely new** |
| `RG24` the pointless gorge | **`SPINE-WEDGE` shortened `storm_road`'s carve** from a 73 m reach each way to 30 m | **See the owner's own description below — it very likely IS that carve, and the two items pull in opposite directions.** Measure before changing anything |
| `RG25` long load | `PERF2` (boot 233s→48s), `VEG-CORRIDOR` (68→117s), `EXP1`'s allowance | boot cost has moved three times today. **Re-measure from `user://boot_log.txt` on current `main`** before treating the owner's figure as current |
| `RG15` minimap | `world_extent.gd` landed — the map baker and minimap now read the corridor's real bounds | the *extent* half may be done. **Rotate-to-heading, full-screen and zoom are untouched** |
| `RG25` title screen | unblocks `EV9`, which has been parked for weeks | `EV9`'s wordmark and orb-count panel have had nowhere to mount because `D18` boots straight into the world. Do them together |


---

### DONE — RG2, RG9, RG10, RG22 (the RG-GATHER group)
**LANDED on `main`: `c9870df7` (RG2) and `210c1ae5` (RG9+RG10+RG22).**

- `RG2` the swing that would not connect — the hit cone was measured off
  `Model` rather than the player's body.
- `RG9`/`RG10` chop-then-gather split.
- `RG22` **the torch now reaches the hand** — the diff-and-restore that `OPS19`
  root-caused from `31ca353`. The root cause note was used rather than merely
  filed, which is the whole point of writing findings down.

**Two things the lane could not know, settled here.**

**1. Its "mysterious cancelled run" was the unit-test timeout, and it is fixed.**
`RG-GATHER` flagged a `verify-unit-tests` run cancelled ~9 minutes in, called
it "not a failure, not a timeout shape", and asked whether *something external
was cancelling runs on this branch*. Nothing external was. **GitHub reports a
`timeout-minutes` kill as `cancelled`,** which is the single most misleading
signal in this repo's CI — see the handover. Better still, the lane
independently measured the thing that proves it: its own note records the full
local suite taking **13–15 minutes per run**. The CI ceiling at the time was
**12**. The suite could not have passed. That is strong outside confirmation
that raising 10 → 12 was never going to be enough, and that splitting it
(`44a0a226`, two round-robin shards) was the right call rather than a lucky
one. **No one needs to investigate this.**

**2. The torch now requires being equipped, and that changes how night is
judged.** Before `RG22`, `torch.gd::_is_on()` had **no equip-state gate at
all** — it reported "on" at night whether or not the torch had ever been drawn.
It now stays dark, at any hour, unless it is genuinely the equipped tool, which
matches `OW12`'s "an unequipped torch is an inert satchel row".

**Consequence for whoever re-judges `NIGHT-LIGHT`'s unjudged round 4: any
capture that samples luminance without equipping the torch first will now read
as permanently dark, and that is CORRECT, not a regression.** `tools/
capture_night_light.gd` was written before this landed — check it equips before
sampling, or the night work will be judged against a torch that was never lit.
The lane hit exactly this itself: `OF18`'s existing smoke regression started
failing the moment the gate went in, because it tested auto-lighting with the
torch never equipped.

**Tiny remainder, deliberately not landed, and smaller than it looks.**
`ralph/RG-GATHER` still carries `f0113faf`, a one-line `.uid` sidecar for
`tools/capture_mat_blockout.gd`. Checked rather than assumed: **no test in this
repo enforces `.uid` presence**, and **two** files under `tools/` lack one on
`main`, not one — `capture_mat_blockout.gd` and `capture_night_light.gd`
(NIGHT-LIGHT's own capture tool, which that lane also never generated). Godot
regenerates them on import, so the cost is a dirty tree after opening the
editor, not breakage.

**RESOLVED 2026-08-18.** Installing Godot 4.7 in the coordinator container and
running a project import generated every missing sidecar, and there were **six,
not two** — the earlier count only checked `tools/*.gd`. The others were
`scripts/world/felled_resource.gd`, `tests/smoke_post_modal_control.gd`,
`tests/test_band_dialogue.gd` and `tests/test_felled_resource.gd`. All six land
with this branch. Lesson worth keeping: the way to find missing `.uid` files is
to run the import, not to grep one directory.

### RG24-CONFIRMED — it is the storm road's collapsed-bridge trench
**Rendered in-engine 2026-08-18** with `tools/_probe_storm_pass.gd`, six
viewpoints at `shots/storm_pass/`. The identification the entry below reasoned
out from arithmetic is now **confirmed by eye**: the dirt path runs straight
past the trench's east end and continues north, and from the stronghold
approach the cut simply stops with open meadow beside it. It does not read as
a blocker because it is not one.

Owner's five decisions of 2026-08-18 answered everything except this one, and
this is the frame to show him: `shots/storm_pass/03-the-way-round-east-end.png`.

**Shown to the owner. His answer, verbatim:** *"the hole seems like it should
be impassable other than by bridge. if I can walk around it in 15 seconds,
what's the point. maybe a bridge that is protected by two team tether grunts.
you beat them then go across."* He also placed his own earlier memory of this
spot: he played before `OW5D` relocated the stronghold here, so what he saw
then was the same trench with open ground behind it — same gorge, different
neighbour, not a different bug.

### STORM-GATE — two Team Tether grunts guard the storm road crossing
`model: sonnet` · `tests: smoke_traversal, smoke_trainer_battle` · `area: content, combat, terrain`

**This works, and unusually cleanly — every piece it needs already exists in
some form:**

- **The bridge mechanism is not new.** `scripts/world/gated_crossing.gd` is
  exactly this — "one authored crossing over one authored gap, shut until the
  player has the thing that opens it" — already built twice (`south_bridge.gd`,
  `mill_crossing.gd`). A third subclass here follows an established pattern,
  not a new one.
- **Gating on a defeat instead of an item needs almost no new mechanism.**
  `item_gate.gd::is_open()` is `progression.has(flag_id)`. `trainer_npc.gd`
  already writes a `defeat_flag` into that same progression store on winning a
  battle (`already_beaten()` reads it back the same way). A crossing gated on
  "beat this trainer" reads a flag a battle already writes — the two systems
  already share one store. `item_gate.gd`'s existing multi-key support (`SF34`
  — a gate may require more than one id at once, all-or-nothing) is exactly
  the shape "beat both grunts" needs.
- **A trainer-gated path already exists as a shipped pattern**: `OW6` (closed)
  puts a challengeable captain on the trail with the same gate-the-path
  grammar, one trainer instead of two guarding a specific span.
- **Two Team Tether grunts do not need a new asset.** `docs/
  MEADOWS_PROGRESSION_SPEC.md` §36 already specifies a rank/colour system for
  reused NPC geometry — Grunt: charcoal, muted forest green, minimal gold —
  so "the same base model communicates hierarchy" with no unique geometry.
  Build from the trainer rig with §36's grunt palette, the same move `R7.2`'s
  three villagers already made. A Team Tether grunt base is *licensed* as a
  possible second human generation (`D23` §22) but explicitly not required —
  §37: "must not block Meadows implementation waiting for unique 3D assets for
  every NPC." `D23` separately warns that a bare `tint` key destroys material
  separation past a couple of NPCs — check `R7.2`'s own result before assuming
  tint alone is enough here.
- **It is thematically exact, not just convenient.** `severed_spokes.gd`'s own
  header: *"Team Tether did not build seven random dead-end roads. They
  severed existing connections."* This blocker's `kind` is already
  `collapsed_bridge`, and `_build_sealed_road`'s oxblood palette is reserved
  for "Team Tether banners, equipment and uniforms" — the road is already
  authored as their own work. Two of their grunts holding the span they
  collapsed is the payoff it has been quietly set up for.

**The one real caveat, and it is a decision, not a detail.** The far side leads
nowhere yet. `far_road` ends at `z 7618.89`; the world boundary is `z 7680` —
about 61 m of margin, no content. `D46` picked this exact spoke to sever
*because* "nothing in Bands 0-2 sends a player there... the storm road leads to
a severed end and nothing else." Beating two grunts to reach 61 m of empty
field just moves "walked around it to nothing" behind a fight instead of
removing it. Two honest paths:

1. **Build a small payoff on the far side now** — not Storm Country itself
   (Biome 2, stays out per `CLAUDE.md`), but something proportionate to 61 m: a
   ruined outpost, a vista, one beat that rewards the fight symbolically.
   `RIVER-OVERHANG` already clamps authored geometry to this exact boundary, so
   there is a working pattern for building right up against it.
2. **Gate it anyway, with nothing beyond.** The fight and the crossing are the
   content; the payoff is narrative (you have beaten Team Tether at their own
   severed road), not a place. Cheaper, and it can grow a far-side beat later
   without touching the gate — `gated_crossing.gd` does not care what is on the
   other side of the span it opens.

**Recommendation, not a decision: option 2 first.** It is buildable today, it
directly answers "what's the point", and nothing about it forecloses adding a
far-side beat later.

**Done when:** two Team Tether grunts stand at the storm road crossing;
defeating both opens a real bridge over the carve (`building_prefabs.gd`, one
village family per `D24`); the crossing persists open across a reload
(`item_gate.gd`'s existing flag-backed persistence — no bespoke save state);
and `smoke_traversal` proves the trench is impassable everywhere except the
bridge until it opens.

### STRONGHOLD-MAT — the stronghold renders untextured, and it is the biggest
### thing in the game
`model: sonnet` · `tests: smoke_stronghold` · `area: visual`
Found incidentally while shooting `RG24`, not looked for. In
`shots/storm_pass/03-the-way-round-east-end.png` the stronghold is a flat black
slab; in `06-oblique-whole-blocker.png` it is a group of untextured grey boxes.

This is the same class of defect `RG11`/`MAT-BLOCKOUT` fixed for quarry stone
and the Warrens wall (`D63`: shared-model material drift is a bug, not a
ceiling, until checked) — but on the largest structure in the Meadows, legible
from hundreds of metres. **Check `D63`'s exact failure first**: one model
reaching the world down two code paths, only one of which warms its material.

**ADDRESSED by `GATE-E-STRONGHOLD-ART` (2026-08-23), and the diagnosis above is
wrong — worth reading before anyone re-opens it.** It is not `D63`'s failure and
there is no unwarmed material path; `building_prefabs.gd` retints every castle
module correctly and always has. The castle renders black because `art.json`
puts the sun in the NORTH sky (pitch -44, yaw -40) while `landmark.gd` puts the
gate, ramp and whole approach on the SOUTH side, so the hero face is backlit at
every hour the chapter is played and lit by ambient fill alone — measured near
luma 0.012 on `gate-close` against a 0.49–0.60 reference range. Fixed by raising
the retint ladder and by giving the garrison its own fires
(`stronghold_occupation.gd`), not by repainting. See `DONE.md`. **Remaining: the
blind visual-judge pass could not be spawned during that lane (session service
unavailable) — the frames are improved and unjudged, and the blind pass still
owes this item.**

### SKY-PLANES — large translucent quads hang in the air over the stronghold
`model: sonnet` · `tests: smoke_stronghold` · `area: visual`
Visible in both `shots/storm_pass/01-road-approach.png` and
`06-oblique-whole-blocker.png`: several big flat translucent rectangles
standing in the sky above and behind the stronghold, at a scale that reads from
the whole approach. Not a subtle artefact and not previously reported.
Unknown cause — candidates are an LOD/impostor plane, a shadow-catcher, or a
wall mesh with a broken transform.

**FIXED by `GATE-E-STRONGHOLD-ART` (2026-08-23). None of the three candidates.**
They are `scripts/world/rift_collapse.gd`'s `StormWall_0/1/2` — the storm-road
seam backdrop, correct material, correct transform, simply being looked at from
1.4–2.0km away by viewpoints that did not exist when it was authored. That file
still claims its meshes sit "outside the 512m terrain"; the 8192m corridor move
silently ended that. Fixed with a viewing band
(`rift_collapse.json`'s `visible_within_metres` / `fade_metres`) rather than a
colour, applied to `FarCountry` too since it would inherit the same defect the
moment `legendary_freed` is set. Identification tool:
`tools/_probe_sky_slabs.gd`. If a translucent rectangle turns up on some other
horizon, probe it the same way before assuming it is this one — `BILLBOARD-WHITE`
below is a separate, still-open report.

### STRONGHOLD-TETHER-HERO-PROPS — what this site would spend a Meshy generation on
`model: sonnet` · `tests: smoke_stronghold` · `area: visual` · **blocked on owner reference art**
Recorded by `GATE-E-STRONGHOLD-ART` rather than generated, because `CLAUDE.md`
reserves Meshy for Team Tether hero objects **and never without owner-supplied
reference art**, and there is none for any of these. Everything that lane
shipped is installed-asset kit-bash; these are the places where that is visibly
the ceiling rather than the choice:

- **A real brazier / fire-basket.** Currently two primitives (post + bowl) with
  `torch_prop.gd`'s billboard flame seated in it, because `assets/**` ships no
  brand, lantern or brazier mesh at all — `torch_prop.gd`'s own header already
  recorded that gap. It reads as a dark cup on a stem at 26m.
- **A Team Tether gate pylon / relay mast for the gatehouse.** The teal work
  lamps are an emissive sphere in a cylinder housing. The relay site and the
  tether machine both have real apparatus; the fortress that Team Tether
  actually holds has none of it on the outside.
- **A barbican or outer-works gate for the ramp foot.** The approach reads as a
  camp beside a ramp rather than a controlled entry. Note the terrain bound
  recorded in the castle recipe before designing one: the Rise flank climbs
  +34m twenty metres west of the wall and the heightfield ends ~30m east, so a
  sprawl has to go SOUTH down the approach, not around the footprint.
- **A hanging banner with real cloth silhouette.** The kit's `Banner.obj` is a
  flat pennant; nine of them now hang on the south face and they read as small
  red flags rather than as an occupying army's colours.

### BILLBOARD-WHITE — untextured white cards standing among the trees
`model: sonnet` · `tests: smoke_playground` · `area: visual`
`shots/storm_pass/01-road-approach.png`, right of frame: several plain white
rectangles standing upright in the grass among the copse. Reads as a billboard
or card with a missing/unassigned texture. `BLOCKED.md`'s `EV2-landmark-oak`
records the precedent — a config bug that made `CherryBlossom_3` render in its
native pink looked like an asset limitation and was not one.

### RG24 — The gorge that is not worth walking around
`model: sonnet` · `tests: smoke_traversal` · `area: terrain`

**Owner, 2026-08-18, asked to identify which gorge he meant:** *"don't know
where the gorge was. it was along a path. it was small. like took fifteen
seconds to walk around."*

He could not name the location, so **identify it by measurement, not by
memory.** `movement.json` gives `walk_speed` 5.0 m/s, so fifteen seconds of
detour is **roughly 60-75 m of walking** — meaning the feature itself is on the
order of **20-40 m across**, sitting **on or beside an authored path**.

That measurement rules the candidates in and out:

- **`storm_road`'s carve — the strong match.** `SPINE-WEDGE` cut it to a 30 m
  reach each way, and walking around a 30 m reach is ~60-75 m, i.e. about
  fifteen seconds. It is on a road, which matches "along a path". **Check this
  first.**
- **`D46`'s dry-gorge reach at the river's north end — ruled out.** That is
  part of a 340 m channel and is nothing like "small" or fifteen seconds.
- **`SC14`'s south gully** — measure it; it was cut to seal a road, so it is on
  a path by construction.

**If it is `storm_road`'s carve, this item and `SPINE-WEDGE` are in direct
conflict and the owner must settle it before anyone digs or fills.** `SPINE-WEDGE`
shortened that carve deliberately; `RG24` says the result is pointless. Both
cannot be satisfied by tuning the same number. Bring him a screenshot of the
identified feature and the two options — remove it entirely, or give it a
reason to exist (something on the far side, or a crossing) — rather than a
description. He could not place it from memory, which is itself evidence that
it reads as nothing: a feature nobody can locate afterwards is not landmarking.

**DONE — the screenshot went to the owner and he answered.** He wants the
crossing gated, not removed: *"maybe a bridge that is protected by two team
tether grunts. you beat them then go across."* Turned into a build task —
`STORM-GATE`, filed with `RG24-CONFIRMED` above.

### RG1 — The game freezes after coming out of an interaction or a menu

**MEASURED 2026-08-18 by `RG-INPUT` — neither named freeze reproduces on
current `main`.** The lane built a real repro rather than eyeballing it and
shipped it as `tests/smoke_post_modal_control.gd`, so a regression is caught
rather than re-reported. **Do not re-chase these two freezes.** Ask the owner
whether he still sees them on a current build; if he does, it is a third case
and the existing test is the place to add it.
`model: opus` · `tests: smoke_menu, smoke_modal_stacking, new` · `area: ui, blocker`
Owner: *"The game seems to freeze a lot after coming out of an interaction or
menu. Like interacting with the trader at the beginning then it freezes. Doing a
build, then it freezes."*

**Highest priority item in the phase. A freeze ends the session.** Two named
reproductions: the opening trader conversation, and completing a build. Both are
"a modal closed and control did not come back", which points at the pause shell
or the interaction arbiter failing to release rather than at either feature.

`game_menu.gd::open()` pauses the tree and `PlaygroundHUD` inherits `PAUSABLE`;
`OW10` built `scripts/ui/input_owner.gd` so a panel that owns input joins a
group and world verbs ask `current()`. **A panel that registers as owner and
never deregisters would look exactly like this.** Check the release path on
every panel, not just the two named.

Reproduce on a real build before writing a fix. Do not guess a mechanism.

### DONE — RG2 — You cannot swing a tool at anything

**LANDED `c9870df7`.** Hit cone was measured off `Model` instead of the player body.
`model: opus` · `tests: smoke_playground, test_inventory, new` · `area: gameplay, blocker`
Owner: *"I can pull out a pickaxe and such but I can't swing at the stones or
trees or anything."*

**Gathering is the core loop and it is inoperable.** The tool reaches the hand
(`tool_hold.gd` works) but the swing verb does not connect to anything.
`harvest_logic.gd` has a public `gather()` that a swing and a prompt-press are
both meant to run. Find which half is missing: the input binding, the swing
animation's hit window, or the target query.

Related and probably the same root: `RG3`'s "no prompt tells me what button".

### RG3 — Nothing on screen tells you what any button does
`model: opus` · `tests: smoke_playground, smoke_menu` · `area: ui, blocker`
Owner: *"There's a button that brings up the build menu even though nothing on
screen tells me that... something on screen should say b-build, x-map,
y-inventory, rb change pal. Not necessarily those buttons but the idea."* And:
*"I can pull out a torch even without a prompt to tell me what button to hit."*

A controller-first game with no button legend. **This is the cheapest large win
in the phase** — the verbs exist and work; the player cannot discover them.

### RG4 — Builds will not place, except the workbench
`model: opus` · `tests: smoke_free_build, test_build_grid` · `area: build, blocker`
Owner: *"The builds even with free build on won't place. Except a workbench."*

Free build on, ghost armed, nothing lands. The workbench working is the clue —
find what it does that the others do not. `build_placer.gd`'s header claims the
ghost/rotate/snap/grid system "was working the entire time", so trust the
measurement over the claim.

### DONE — RG5 — The build menu leaks input to the character

**LANDED `a2b82f79` (RG-INPUT).** Movement and jump now gate behind `input_owner.gd`. Worth confirming in play — the report was about feel, and a passing test is not the same claim.

**FIXED on `ralph/RG-INPUT` (a2b82f79), bundled in `integrate-12`.** Movement
and jump are now gated behind `input_owner.gd`. Verify in play before closing —
the owner's report was about feel, and a passing test is not the same claim.
`model: opus` · `tests: smoke_free_build, smoke_menu` · `area: ui, blocker`
Owner: *"When the building menu is up, pressing directions and pressing a still
controls the character too and the menu."*

**This is `OW10` returning, and `UI-PAD2` predicted exactly it.** `OW10` built
the input-owner gate and converted `playground_hud.gd`'s pollers only;
`UI-PAD2` recorded that `build_placer.gd` polls `build_place`, `build_rotate`,
`build_snap_cycle` and `build_cancel` directly and **asks `input_owner.gd`
nothing** — and that the build menu is the one panel that deliberately does not
pause the tree. It was filed as "structural, not observed." It is now observed.

### RG6 — Menus still do not read every input
`model: opus` · `tests: test_controls, smoke_menu` · `area: ui, blocker`
Owner: *"Menus don't read every input still."*

Third report of this class (`OW10`, `UI-PAD1`, now this). Needs the owner's
exact screen and button to be actionable — **ask before guessing**, or
instrument every menu to log which action it saw and reproduce from that.

### RG7 — Reloading a save does not restore your game
`model: opus` · `tests: test_save_format, smoke_opening, new` · `area: save, blocker`
Owner: *"When you reload a game you don't go back to where you were. So I
reloaded with a creature already then had to go back through grandpas dialogue.
I was able to get a second creature and second things from the villagers... I
also can pick up the tms again but I don't get a second one. You shouldn't be
allowed to pick it up a second time. It should be gone."*

**A save that does not restore position or story flags is a save that does not
work**, and it lets a player duplicate one-time gifts. The workbench persisting
is the one thing that did survive, which narrows it: placed builds save, player
transform and progression flags do not.

One-time pickups must be consumed permanently — the same "it should be gone"
rule `HARVEST-ALL` just applied to chopped trees.

### RG8 — You lose camera control during a creature fight
`model: opus` · `tests: smoke_combat, new` · `area: combat, blocker`
Owner: *"You no longer control the camera when you're in a creature fight."*

Combat is the game's centrepiece and you cannot look around in it.

---

### DONE — RG9 — Harvesting should be chop-then-gather, not gather-a-standing-tree

**LANDED `210c1ae5`.**
`model: opus` · `tests: smoke_playground, test_inventory, new` · `area: gameplay`
**Owner directive, and it changes the harvest model that `HARVEST-ALL` just
shipped:** *"You shouldn't be able to gather a standing tree. You should have to
chop it. Then it becomes downed wood. Then you gather that. Same for stone."*

So a resource is a two-stage object: standing → felled → gathered, with the
felled stage a real pickup-able thing in the world. `HARVEST-ALL` made every
tree and rock harvestable and permanent; **this makes the first stage a chop
rather than a pickup.** Build on that work rather than reverting it.

### DONE — RG10 — Harvestables should not glow

**LANDED `210c1ae5`.**
`model: sonnet` · `tests: smoke_playground` · `area: visual`
Owner: *"Items to harvest shouldn't be gold lit up orbs. They shouldn't light up
at all."*

**Supersedes `R2.3` and its remainder**, which built the glint deliberately to
answer an earlier owner report that gathering "seems to randomly pop up". The
newer word wins. Note the glint is now on *every* tree and rock after
`HARVEST-ALL`, so removing it also removes tens of thousands of billboards —
report the frame-time change.

Leave `R2.3`'s reasoning in place with a note naming this item, so the reversal
is legible.

### DONE — RG11 — Stones look like white paper

**LANDED main (7fa9735e), via MAT-BLOCKOUT.** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: none (visual)` · `area: visual`
Owner: *"Stones look like white paper."* Wood on the ground is *"okay"*.

Almost certainly the same class as `MAT-BLOCKOUT`'s quarry rootstone reading as
"pale mint/seafoam hatching" — check whether one fix covers both before treating
them separately.

### RG12 — TMs should read as orbs on the ground, in their own colour
`model: sonnet` · `tests: none (visual)` · `area: visual, items`
Owner: *"Tms should look like orbs on the ground but w different color than
normal orbs."*

### RG13 — Too many recipes are available at the start
`model: sonnet` · `tests: test_recipes` · `area: progression`
Owner: *"You have too many recipes available at the beginning."* A gate, not a
deletion — most should unlock through play.

### RG14 — Once a piece is chosen you cannot read how to place or rotate it
`model: opus` · `tests: smoke_free_build` · `area: ui`
Owner: *"Once I choose what I wanted to build the build menu went away and I
actually couldn't read how to place or rotate the piece anymore."*

`OW11` deliberately made the menu close on pick so the world is visible — that
is right and stays. What is missing is the placement control legend surviving
the menu. Same family as `RG3`.

---

### RG15 — The minimap does not work for this world
`model: opus` · `tests: smoke_menu, test_map_state` · `area: ui, map`
Owner: *"On the mini map up should be the way I'm moving. Always."* · *"The
minimap isn't built for this world. It also needs to be full screenable with
zoom in and out."* · *"I can't navigate using the map at all."*

Three things: **rotate to heading**, **a full-screen map with zoom**, and a
world-scale fit — the minimap's span was authored for a 512 m square and the
world is 8192 x 2048 m.

### RG16 — The player has no idea which way to go
`model: fable` · `tests: test_dialogue_runner, test_progression_state` · `area: npc, progression`
Owner: *"Maybe you should also have grandpa say head east to the bridge and have
our overall objective be head east to the bridge or something then have the game
tell us if we're going east by looking at the minimap. I have no idea if I'm
going the right way."*

An objective the player can hold in their head, spoken by an NPC, reflected on
the map. Pairs with `RG15` and `RG17`.

### RG17 — The tether pylons should be the navigation line, with an NPC at the first
`model: fable` · `tests: none` · `area: world, npc`
Owner: *"Where the first tether pillars starts there should be an NPC telling
you that they're draining the land and whatever. These should go in a continuous
line to the stronghold. That will help navigation."*

**This is a strong idea and it is cheap**: the pylons already exist as Team
Tether hero objects, and a continuous line of them from the first pylon to the
stronghold turns the story's own fiction into the map's spine. It also gives the
drained-ground grammar (`D45`) something to follow.

### RG18 — Onboarding: the player is never told what the game is
`model: fable` · `tests: test_progression_state` · `area: ui, progression`
Owner: *"I don't understand what to do as a player... I should understand that I
need to gather, build, level up my pals, get stronger, build a home, build pal
beds, level up more, etc. There should be on screen prompts working you through
these like in palworld."*

A guided opening chain. `OW9` shipped two handover beats (gather, then build);
this asks for the whole ladder, surfaced on screen rather than only in dialogue.

### RG19 — A village tournament as the early goal

**UNRESOLVED, found 2026-08-22 while writing the download page: the tournament
and the spec's Band 1 are two different first gates, and nothing says which
wins.** `grep -ril tournament scripts/ data/ tests/` returns **zero hits** — it
is entirely unbuilt, which is expected. What is not expected is that the higher-
precedence `docs/MEADOWS_PROGRESSION_SPEC.md` §3 BAND 1 does not use a
tournament at all: its first-band structure is a three-trainer circuit (Mira /
Oskar / Tam, all four standing in
`data/config/bands/band1_lower_meadows/trainers.json` today alongside Bryn) and
its first hard gate is the **South Bridge Key**, taken off Oskar the Bridgehand
(§3 L304–307, and step 10 of §38's sequence). The tournament appears in
`docs/TETHERBOUND_GAME_VISION.md` §3 and in this entry, both of which the
canon order in `CLAUDE.md` puts *below* the spec.

So whoever builds this has to settle one thing first, and it is a real design
question rather than a bookkeeping one: **is the tournament the Band 1 gate
(replacing Oskar's key), or a village event that sits alongside it?** Both are
defensible — the owner asked for a tournament in an owner-approved note, and
the spec's key-off-a-trainer gate is already half-standing in data. Do not
quietly implement one and leave the other in the docs; that is how the download
page ended up promising players a tournament that does not exist, which is
what surfaced this.

The condition-system ordering below is unaffected either way.


**OWNER APPROVED, 2026-08-18: "yes we should spec out creature condition."**
The tournament is confirmed, and the owner named the part to build first: the
**creature condition system** (rested / fed / happy) that gates entry. Spec that
before any tournament bracket, arena or reward code — it is the load-bearing
half and the half that does not yet exist. The bracket is comparatively
ordinary work that can follow.

Why this ordering is the right one and not just the owner's preference:
condition is the mechanic that finally gives the **five-creature limit** and
**satiety (`D29`)** a reason to matter early. Both currently exist without
pressure — you can ignore satiety and never feel the cap. An entry gate on
condition converts two dormant systems into a reason to care, which is worth
more than the tournament itself.

Deliverable for the spec: what "rested", "fed" and "happy" each mean as state,
where they are stored, how the player *sees* them (they must be legible before
they can be a gate), how they decay and recover, and which existing systems
already half-implement them. Take a `docs/decisions/` number. **Do not invent
the numeric thresholds as permanent** — pick tunables per `CLAUDE.md` and label
them.

`model: fable` · `tests: new` · `area: content, progression`
**Owner design proposal, recorded verbatim rather than interpreted:** *"Maybe
there should be a tournament near the beginning in grandpas village that we
enter. In order to enter you have to go catch five pals and get them to level 3
or something. They have to be well rested, well fed, and happy. Then they allow
you to enter. Winning gives you coins and sets you on your way to fight team
tether."*

**This is a new content beat and it needs the owner's confirmation before
building** — it introduces an entry gate on creature condition (rested, fed,
happy) and a tournament format the spec does not currently describe. It also
gives the five-creature limit and the satiety system a reason to matter early,
which is the strongest argument for it.

---

### RG20 — There are no creatures anywhere
`model: opus` · `tests: test_spawns_data, smoke_playground` · `area: creatures, blocker`
Owner: *"There are no creatures anywhere which is a problem for a game that's
featuring creatures as the key thing."*

**Independently confirmed by the blind critic**, which noted across all five
Band 2 rounds that no creature ever appears in frame. Two reports from
completely different methods agreeing makes this real and not a sampling
accident. Spawn siting, spawn density, or spawn activation — measure which.

### RG21 — Day and night should be progressive and unequal
`model: sonnet` · `tests: smoke_playground` · `area: world, visual`
Owner: *"day shouldn't just switch to night. It should progressively do it like
real life. However night shouldn't be equal length to day. It should be pretty
short. However valheim does it."* And separately: *"night is forever."*

Two changes: a **continuous** transition rather than a switch, and a **short
night** relative to day. Interacts with `NIGHT-LIGHT` — coordinate.

### PARTLY DONE — RG22 — The torch is too dim and does not go in your hand

**The hand-attach half LANDED `210c1ae5`** — the torch reaches the hand, and now gates on equip state (see the capture warning below). **The brightness half is still open and deliberately gated** until the night rounds settle; see the note further down.
`model: sonnet` · `tests: smoke_playground` · `area: gameplay, visual`
Owner: *"The torch should probably light up a little more."* · *"The torch
doesn't go in your hand like a axe does. It should."*

`torch.gd` bone-attaches and `items.json:550` records it as the pattern
`tool_hold.gd` copied for tools — so the hand-attach exists and is not working
in play. `OW12` made the torch a carried item; this is its remainder.

**ROOT-CAUSED, 2026-08-18, by the `NIGHT-LIGHT` lane while investigating
something else — read this before re-deriving anything.** The hand-attach is
not broken, it is *absent*: `scripts/player/torch.gd` was reverted to its
pre-`OW12` form by a merge-conflict resolution in `31ca353`. The real `OW12`
implementation — gate on `GameState.equipped_tool`, mesh via `tool_hold.gd` —
still exists in the tree's history at `3a8f9ee:scripts/player/torch.gd` and
can most likely be **restored directly** rather than rewritten. Start by
diffing those two revisions. `NIGHT-LIGHT` investigated `torch.gd` but
deliberately did **not** edit it, so the file is unheld.

Also from `NIGHT-LIGHT`, and load-bearing for the *brightness* half: night's
own ambient floor moved a long way in this same session (`near_luma` from
0.000–0.015 up to 0.028–0.107, depending which round ships). The torch's
relative contribution has **not** been re-checked against the new floor and
may now read as weak or redundant for a reason that has nothing to do with the
torch. Do not tune torch brightness until the night rounds are judged and
settled — tuning against a moving target is wasted work. The hand-attach half
has no such dependency and can proceed immediately.

### RG23 — Rocks with no collision, and invisible things you get stuck on
`model: opus` · `tests: smoke_traversal` · `area: collision`
Owner: *"Some rocks I can walk straight through with no collision. Then I get
stuck on something I can't even see. It makes no sense."*

**Both halves in one sentence, and the second half is the `WALL1`/`SPINE-WEDGE`
family** — invisible blockers there turned out to be `CarveFailsafe` `Area3D`
volumes and a spoke's severing trench, never terrain. Use
`get_slide_collision()`'s collider identity; do not sample `ground_height_at()`.

The missing-collision half is new: scattered rocks are `MultiMesh` instances and
only some carry colliders. Establish which.

### DONE (superseded by STORM-GATE) — RG24 — The gorge in the middle of the map stops nothing
`model: sonnet` · `tests: smoke_traversal` · `area: terrain`
Owner: *"There's a giant gorge/hole in the middle of the map that I just walked
around. Seemed pretty pointless. It didn't keep me from anything. It needs to
extend if it's supposed to keep anyone out."*

Kept as the original report. Identified as `storm_road`'s carve and turned into
a build task at `STORM-GATE` — see that entry for the fix.

### RG25 — Long load on the ROG, and there is no title or save screen
`model: opus` · `tests: verify_export, smoke_menu` · `area: perf, ui`
Owner: *"The game takes a long time on a rog to load. There needs to be a load
screen when your start the game to choose your saved game. There also needs to
be an exit when you go to the menus to quit the game."*

Three things: **boot cost on target hardware**, a **title/save-select screen**,
and **quit from the menu**. The title screen also answers `EV9`'s long-open
question — the branded wordmark and the orb-count panel have had nowhere to
mount because the game boots straight into the world by `D18`. **`D18` is now
superseded by this directive**; record that rather than quietly reversing it.

---

## Phase -1.5 — the owner played the ROG build (owner-reported, 2026-08-16)

Reported from the real handheld, which is the instrument no test in this repo
substitutes for. **Three of these have been "fixed" before** — check the current
build before rebuilding, then fix the mechanism rather than the symptom, because
the symptom has come back every time so far.

The owner also asked whether they were on an old build. Partly answered here:
`OW3`'s fog does not exist in code at all, and `OW1`'s hotbar has no separate
section *by design* — so those two are real regardless of build age.

### OW12 — The torch should be a carried item, not a thing you build
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_playground, test_inventory` · `area: ui`
Owner, 2026-08-16: *"torches need to be a carry able item not placeable one."*

**Both halves already exist, which makes this smaller than it sounds.** A carried
torch is real — `scripts/player/torch.gd` bone-attaches it, and `items.json:550`
names it as the pattern `tool_hold.gd` copied for tools. A placeable torch is
also real — `buildables.json:121-133`, free to build.

**This supersedes `OF24`, and that should be said out loud rather than quietly
undone.** `OF24` was itself an explicit owner directive — *"Torch building should
be free"* — and `buildables.json:133` records it verbatim. The newer word wins
(the same rule D23 applies to the spec), but leave the old `_comment_free` in
place with a note naming this item, so the reversal is legible to whoever reads
that file next.

Working assumption, cheap for the owner to reverse in one line: the carried torch
becomes the real one and reaches the hand from the inventory the way a tool does;
the buildable is retired rather than kept as a second path. If retiring it
strands camp lighting at night, say so instead of inventing a replacement.

**Done when** a player can take a torch out of the backpack and carry it lit,
and is not offered a torch to build.

### OW3 — The whole map is revealed before you explore anything
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
Owner: *"The full map is rendered before I explore anything."*

**Confirmed in code, not just reported:** `scripts/world/map_baker.gd` contains
no fog, reveal, explored or discovery logic of any kind. Spec §16's rule — the
map reveals explored areas and landmarks and *never reveals everything
automatically* — was never built. This is the surviving half of `R7.4` and the
owner has now hit it; do that item's remainder here.

### OW5 — The Meadows should be a long journey from home, not a compact square
`model: fable` · `tests: smoke_traversal` · `area: terrain`
**The owner's world-shape directive, and the largest item in this phase.**

Owner: *"The meadow needs to read as a long journey away from home ending at the
stronghold. But the whole area should be a big square. It's a long trail working
progressively further from Grandpa's house. You can go off the trail for
different tasks. It can wind and fork and whatever but this should be the
general layout. Walking end to end should take several in game days so you have
to camp along the way."*

**SUPERSEDED IN PART, 2026-08-16, by the owner in conversation. The square is
gone.** Recorded here because it existed only in a chat thread, and a decision
document was already citing it while this entry still said the opposite — the
same failure that made a sibling session paint the roster against boards it
could not see (`docs/HANDOFF_2026-08-16_colour_and_brief.md`). His words:

> *"the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square. it should be
> long as I've stated but can be significantly less wide. like maybe it's five
> minutes of walking from side to side."*

> *"a day from midnight to midnight should take about 10 minutes. a walk from
> the end of the meadows to the other end should take 40 minutes."*

At `walk_speed` 5.0 and `day_length_seconds` 600 that is **~12,000 m of trail**
and **~1,500 m of width**. Everything else below stands.

One arithmetic caution for whoever sizes it: 40 minutes is a *walking* figure,
and a player who cycles sprint sustains about 7.0 m/s once
`stamina.regen_delay` 1.1 and `regen_per_second` 18 are both counted — roughly
28 minutes for the same trail. Size to the directive, but know the spread.

So: a long, narrow **corridor**, with a winding, forking **trail** through it
that carries the player progressively away from home and ends at the stronghold.
Off-trail is where optional work lives, and the flanks are broken land or sea.
The end-to-end walk must be long enough that camping on the way is forced rather
than optional — which is what finally gives `camp` a job beyond the first night,
and what makes the stronghold read as far away instead of nearby.

This supersedes `R7.3`'s framing. R7.3 keeps only its bake-and-capacity half
(does the terrain footprint and Terrain3D region count support this, and what
does it cost on the Ally). **The shape is this item.**

Read `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 (`MQ2A`, the Meadows
macro-world redesign) before starting — it is the existing quality brief for
exactly this work and it says START WITH FABLE.

**Done when** walking the trail end to end takes several in-game days, the
stronghold is visibly the far end of a journey rather than a neighbour, and the
existing regions (quarry, warrens, river, relay, Ironwood) hang off a trail
rather than sitting near the start.


**A constraint `OW5C` inherits from `OF15` (added 2026-08-16).** The player's
`floor_max_angle` is 45 deg, and a confirmed wedge at (60, -106) on the rocky rise
turned out most likely to be slope rather than props — a route crossing ground the
character controller refuses to climb. **No trail segment may cross ground steeper
than `floor_max_angle`.** Assert it with a probe over the candidate route *before*
the bake, not by walking it afterwards: `height_at` is analytic and unbounded, so
the whole spine can be sampled without baking anything, and at hours per bake that
is not optional. A trail that is 12 km long has 12 km of chances to make this
mistake once.


**STATUS, 2026-08-17. The corridor is BUILT and does not yet land.**

- `OW5A` — the macro layout, measured and region-aligned. **Landed.**
- `OW5B` — the footprint and the bake. **Built.** 8192 x 2048 m, `world_bounds`
  x [-1024,1024] z [-512,7680], **64 baked region files committed** against
  main's 4. The bake was also factored to take a region set, with a bit-identity
  test, so a future edit costs ~143 s a region instead of 153 minutes.
- `OW5C` — the trail, the loops, the edges. **Built.** `trail.bands[]` is the
  spine, `trail.loops[]` the regional loops, `trail.shortcuts[]` the quarry haul
  road and the river ferry; they join the road set through
  `playground_heightfield.road_polylines()`, never as `paths.routes` entries,
  because `signpost.gd` fits four arms.
- `OW5D` — the §10 relocation. **Built**, and honest about its own gap: its
  `spawns.json` comment records that *"Ground truth at every new site was NOT
  re-probed by this pass"* and that test files were out of scope.
- `OW5E` — **OPEN, and the only thing between the corridor and `main`.** See its
  own entry below.
- **The end-to-end check is still owed** and is the thing that proves this
  worked: walk the trail in-engine with a probe measuring real path length,
  side-to-side width and elapsed in-game days, and confirm 40 minutes end to end
  and about 5 side to side **against the actual route**, not the design document.
  Filed as `OW5-walk`.


### OW5E — make the relocated world pass its own tests
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in `d4de94a3`, CI run 1349 green
on all 19 jobs — the first fully green run the corridor has ever had. All six
jobs fixed. Two of them were not the corridor's fault and are worth keeping in
mind: `verify-unit-tests` was two stale test assertions (`test_map_state.gd`
failed to PARSE on a removed `GRID` const, silently skipping all 21 map-state
tests including the save-format ones), and the duplicate `vegetation.build()`
it found came from a coordinator merge resolution, not a lane. Two further real
bugs were found by walking the re-baked ground: `world_perimeter.gd` queried
height exactly on the baked grid's EXCLUSIVE edge, so all 55 south-cap collision
segments took one flat wrong height and a player could step over the wall into
the void; and `smoke_boss.gd`'s `BARRIER_LIMIT_M` had been computed from carve
config that postdated the only bake in existence, never measured.

`model: sonnet` · `tests: the six failing jobs` · `area: terrain, tests`
**The corridor cannot reach `main` until this closes.** `ralph/integrate-3` is 24
commits ahead and 6 of 19 CI jobs fail (run 32023204240). They are not the
`verify-aggression` intermittency; they are real, and they split three ways:

**Tests still asserting the pre-corridor world.** `verify-settings`: *"The Pond
is listed at (-342.0,507.0), expected (-92.0,100.0)"*, same for River Road and
Mountain Road. The landmarks moved correctly; the test hardcodes old
coordinates. Derive the expectation from config the way `OW3` just taught
`test_map_state.gd` to, or this breaks again at `OW6`.

**The world genuinely wrong at a new site.** `verify-warrens`: *"the deepest
chamber is not under the hill (terrain y=-4.2 vs floor y=-3.8)"* — a dungeon
poking out of a hillside. `verify-relay`: *"the player climbed onto the
apparatus pad from the yard; the traversal is not the route"*. `verify-boss`:
D41's regrowth clause unpaid. `verify-traversal`: fell through the world at the
south cap; the river divides nothing at two stations; the Old Mill Crossing
cannot be crossed. **Fix the world, not the assertion** — `verify-relay`'s check
is a real design guarantee.

**Probably a test bug — check before touching either side.** `verify-traversal`
probes the river's near bank at **x=1027**, which is outside `world_bounds`
max_x of 1024. And `verify-unit-tests` exits 1 on *"31 resources still in use at
exit"* with RID leaks, which may be shutdown noise (`D06`) rather than a failed
test.

Also surfaced by the same run and worth its own commit: `verify-settings`
reports *"Map is now I — so is Open the satchel. Both will fire."*

### OW5-walk — walk the corridor and prove the forty minutes
**CLOSED 2026-08-17 (OPS11).** Landed on `main` (`86ed571f`..`ee811226`).
The corridor has now been walked with a real `CharacterBody3D` driven through
the shipped `player_controller.gd` — real capsule, real `floor_max_angle`, real
`_try_step_up`, real `move_and_slide()`, steering by writing `camera_rig.yaw`
and holding `move_forward`. `ground_height_at` was used only to place the body
and never consulted about progress.

**The three numbers, measured:**

| | measured | at `walk_speed` 5.0 |
|---|---|---|
| end-to-end spine, WALKED | **11,316.6 m** | **37.7 min** |
| config polyline, for comparison | 11,516.4 m | 38.4 min |
| in-game days end to end | | **3.77** at `day_length_seconds` 600 |
| width at z 910 / 3600 / 6340 | ~2,041.9 m each | **6.81 min** |

**Length passes: 37.7 against the owner's 40**, 6% short, and the walk tracks
the authored polyline at 0.983 walked/config — so the arithmetic was never wrong
about distance. **Width misses: 6.8 min against "maybe five minutes", 36% too
wide**, uniformly at all three stations. See `OW5-width`.

**Two probe traps worth keeping**, both of which produced a wrong number before
the lane caught them: the world *moves* the body (`CarveFailsafe` writes
`global_position`) and a naive displacement sum credits every recovery to the
corridor's length — steps above 2 m in one tick are now counted separately, and
that count is what named the river defect. And an escape that must be repeated
is not an escape: the unstick routine reported success 653 times at one spot,
frame-by-frame honest and completely useless.

**Runtime, for whoever walks it next:** headless throughput measured at 56–73
physics frames/sec, so 11.5 km at the real walk speed costs ~30 minutes of wall
clock. No speed scaling or teleporting was needed. Keep it a `tools/_probe_*`;
do not extend `smoke_traversal.gd` to do it.

**What it did not cover:** the spine only — not the 10 loops or 2 shortcuts —
and the spine starts at z −16 while the world runs 496 m further north.

### OW5-walk — the original entry
**START HERE (OPS4, 2026-08-17).** `OW5E` has landed, so this is unblocked and
it is the corridor's exit gate: the whole 8192x2048 m world is now on `main` and
**nobody has walked it end to end.** Every number behind it is still arithmetic.
Until this runs, `OW6` (the captain onto the trail) and `MQ2B` are building on an
unverified route.

`model: sonnet` · `tests: new probe` · `area: terrain`
The owner's original ask, in his own words, and still unverified against
anything but arithmetic. Once `OW5E` lands: drive a body along the real trail
and measure **actual path length, actual side-to-side width, and elapsed
in-game days**, then compare against 40 minutes end to end and ~5 minutes across.

Do not measure the design document. `OW5A` computed an 11,594 m spine and a
27.9-degree worst slope from the config; this item exists because a route that
computes correctly can still fail to be walkable — which is exactly what the
phantom wall turned out to be, three wrong diagnoses deep.

### RIVER-GATE — the river is a one-way wall, and the authored crossing cannot be crossed
**CLOSED 2026-08-17 (OPS14) — and the premise was wrong.** Landed `7c5dc6d3`.
**Both crossings work, in both lock states, with zero world teleports**, walked
with the real Player on unmodified `main`:

| | locked | unlocked | teleports |
|---|---|---|---|
| South Bridge | −9.1 m | +22.9 m | 0 |
| Old Mill Crossing | −8.0 m | +23.7 m | 0 |

South Bridge reproduces `OW5C`'s own −9.1/+23.3 and `smoke_traversal`
independently agrees at the mill. **No opening was punched, because none was
needed.** The chain *does* overlap the deck in plan — the middle 11.0 m of the
18.4 m span — but a volume's ceiling is `lip_y - LIP_CLEARANCE` and the deck
stands **5.10 m above it**, so a body on the span never enters one.

**Nothing asserted that, and the two heights come from different places** — the
deck from the crossing's `flats` pads, the ceiling from the river's own
depth/rim. So the lane shipped the assertion instead of a geometry change:
`tests/test_river_crossings_stay_open.gd` (chain covers the whole 2,300 m course
with no gap; the deck run stands clear of every volume under it; the channel
under the deck is still covered), verified failable both ways. An opening was
built and measured before being rejected — it changed the walk by nothing and
cost the coverage under the bridge. `D56` records it. **That is what
`tether_relay`'s `deck_y` and `smoke_boss`'s `BARRIER_LIMIT_M` cost when two
independently-derived heights drift.**

**Where the 712 teleports actually came from — the SPINE, not the crossing.**
See `SPINE-ROUTE` below. `OW5-walk`'s reading was a reasonable inference from a
real symptom and it was wrong; the coordinator relayed it to the owner as fact,
which it was not.

### RIVER-GATE — the original entry, superseded above
`model: opus` · `tests: smoke_traversal, new` · `area: terrain, world`
**NEEDS AN OWNER DECISION BEFORE THE FIX. Filed 2026-08-17 (OPS11) from
`OW5-walk`, and it closes `OW5C`'s three-failed-fixes entry — it was never a
seam.**

At Old Mill Crossing `(-145.5, 4195.7)` the first end-to-end run logged **712
recovery teleports at one spot** and would have looped until timeout.
`get_slide_collision()` returns **zero colliders** — nothing is touching the
body — because the thing stopping it is not a collider. `river.gd:60-101` builds
a chain of abutting `CarveFailsafe` **Area3D** volumes along the *entire* river
course via `severed_spokes.gd::_add_carve_failsafe`, each writing
`global_position` on `body_entered` to put the player back on the village bank.
The spine's crossing walks straight into that chain, and recovery always aims at
`VILLAGE`, so **the river cannot be crossed southward here in either lock
state.**

**This reframes `OW5C`'s other river finding rather than contradicting it.**
"The river divides nothing" at the open-water stations and "the river is
absolute at the crossing" are both true: the failsafe chain spans the channel
between the rims, so a body on the open bank never enters it and a body that
descends at the authored crossing always does. Section 9's premise is not
un-built — it is **inverted**. The barrier works where it should not, and the
crossing does not work at all.

**NO OWNER DECISION IS NEEDED — corrected 2026-08-17 (OPS12), after actually
reading the docs.** This entry and the coordinator's report both said the fix
needed a design call. That was wrong: the design is fully specified and almost
entirely built, and what is missing is one hole in one volume chain.

**The plan, from the documents:**

- `docs/decisions/D46` — *"The only ground link between the near Meadows and the
  far bank is the Old Mill Crossing (`SE22`), which is shut until the Mill
  Bridge Gear is in the satchel."* The river dividing absolutely is the whole
  point of D46; it deliberately cost one severed spoke (the storm road) to
  achieve, chosen by searching every bearing at 1° and every offset at 2.5 m.
- Spec §Band 3 (The River Lock) — Team Tether holds the crossing, the bridge
  keeper is captured; clearing the **Tether Relay Station** frees the captive,
  who *"restores or provides the Upper Crossing Key / Mill Bridge Gear"* and
  **the crossing opens**.
- Spec Gate 1 — the earlier **South Bridge** is the same grammar: *"a physical
  key/mechanism, not a UI level lock"*, its key from Oskar the Bridgehand.

**And the machinery already exists.** `scripts/world/gated_crossing.gd` is the
shared base with `key_item_id` and an open flag; `south_bridge.gd` passes
`("south_bridge", "south_bridge_key", "south_bridge_open")`; `mill_crossing.gd`
declares `MILL_KEY_ITEM := "mill_bridge_gear"`; and `data/dialogue/relay.json:26`
grants it — `give:mill_bridge_gear:1` — on the rescue line, gated on the relay
captain's defeat flag (`relay_site.json:42` explains that wiring in full). The
whole intended chain is built.

**So the defect is narrow and mechanical.** `river.gd:60-101` adds one
`CarveFailsafe` volume per course segment with `end_fade: 0.0` so consecutive
volumes **abut** — deliberately gapless, *"or a player lands in the gap between
two boxes and the failsafe that exists for exactly that never fires."* Nothing
excepts the authored crossing. `old_mill_crossing`'s `channel.failsafe: false`
only stops `_crossing_carve` adding a **second** failsafe; it does not subtract
the river's. So the river's chain spans the one gap the crossing exists to
provide, and recovery always aims at `VILLAGE`.

The file's own header states the intent it then fails to honour: *"Fall in, wake
up on the side you started from, walk to the Old Mill Crossing like everyone
else."* Today there is no walking to it.

**The fix: punch a hole in the chain at each authored crossing, and let the
existing gate do the gating.** Two mechanical questions for the implementer, not
for the owner — exclude the crossing's deck footprint from the chain, or cap the
volume ceiling below the deck (`lip_y - LIP_CLEARANCE`); and keep catching a
player who falls in *beside* the deck, so the hole is the deck's footprint and
not the whole segment. Acceptance is both lock states: locked stops the player,
unlocked lets them across.

### DONE — SPINE-ROUTE — 11 m of Band 3's trail runs two metres to the side of its own bridge

**LANDED integrate-11 (d926d679).** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: smoke_traversal, the walk probe over a z-window` · `area: terrain`
**Filed 2026-08-17 (OPS14). This is the real cause of `OW5-walk`'s 712 recovery
teleports, and it is a two-metre data error.**

`OW5C` nudged Old Mill Crossing from x −150 to −152 to clear a collision-shape
seam — **and moved the crossing without moving the spine.** Band 3's trail still
crosses at x = −150 while the deck's centreline is at −152, so **11 m of
authored trail lies inside a river recovery volume two metres east of the
bridge.** A body walking the authored route falls in beside the deck, is
returned to the village bank, walks back, and repeats — which is exactly the 712
teleports, and why three separate fixes to the *crossing* never helped: the
crossing was never the problem.

**Fix the spine, not the world.** The bridge is correct and now has a test
holding it correct (`RIVER-GATE`). Move Band 3's waypoints onto the deck's real
centreline, then re-walk that window to prove it — `tools/_probe_ow5_walk.gd
--mode=spine --z_from --z_to` walks a window in a fraction of the ~30 min the
full spine costs.

`trail.bands[]` was out of scope for both lanes that found this, which is why it
is still open. **It is in scope for you, and only these waypoints are** — the
spine's overall shape is settled and was measured at 11,316.6 m / 37.7 min.

**Do not re-nudge the crossing.** It sits at −152 for a measured reason and is
now pinned by a test.

### SPINE-WEDGE — bodies stop on walkable ground at four places on the spine
**CLOSED 2026-08-17 (OPS14), in the `integrate-4` bundle. Not terrain — a
spoke's own trench.** `storm_road`'s `collapsed_bridge` carve was `half_length`
55 + `end_fade` 18: **a 73 m reach each way, a 146 m trench laid across the
corridor to sever a 3 m road.** The spine's last leg to the stronghold gate
crossed it at full 11 m depth, the trench carries a `CarveFailsafe`, and every
body that fell in was returned to `road[4]` at (−33.99, 7513.46) —
character-for-character `OW5-walk`'s "stronghold gate approach" wedge, which it
had reported as *"Terrain, 12–17 degrees"*, i.e. walkable angles. **No amount of
looking at the terrain would have found the spoke.**

Cut to 20/10, a 30 m reach: the road is still severed at full depth and D50's
65.6° walls are untouched, and the spine now passes 7.6 m clear of the
zero-depth contour. **Exactly the edit `river_gorge` already took for the same
reason** (70/22 → 26/14, because its trench was gouging the pond). Re-baked
regions −1:14 and 0:14 only — the whole of that carve's footprint. `D55` records
the rule: *a spoke may not block the road it is not severing.*

**Two lanes converged on this independently** — `RIVER-GATE`'s volume scan found
the same site from the other direction and confirmed that **exactly two stretches
of spine on the whole map lie inside any recovery volume.** One was this; the
other is `SPINE-ROUTE` above. `OW5-walk`'s other three wedge sites are cleared by
that same scan.

### SPINE-WEDGE — the original entry, superseded above
`model: sonnet` · `tests: smoke_traversal, new probe run` · `area: terrain, collision`
Filed 2026-08-17 (OPS11) from `OW5-walk`. **This is the `WALL1` class of defect
again, and this time there are coordinates and normals for every instance.** All
four are terrain, all at angles well inside the player's 45° `floor_max_angle`,
and the worst ends with `on_floor=false` and **zero colliders**:

| where | surface | normal from up | trail lost |
|---|---|---|---|
| stronghold gate approach, six wedges at (−30..−34, 7513..7519) | `Terrain` | 12–17° | **57.6 m — the last 57 m to the gate** |
| South Bridge (5.5, **−13.0**, 1333.7) — the body is down *in* the gully | `Terrain` | 16° | 26.9 m |
| (336.3, 5.7, 3749.8) | `Terrain` | **4.6°, nearly flat** | 17.0 m |
| (−417.0, −3.1, 2465.9) | `Terrain` | 11.6° | 5.1 m |

South Bridge is not a regression of `OW5C`'s lock fix — that fix measured a real
before/after and is not in question; walking end-to-end simply arrives
differently, falls into the gully and cannot climb out.

**Do not sample `ground_height_at()` to investigate this** — that scalar misled
three separate investigations of the phantom wall. Re-run
`tools/_probe_ow5_walk.gd` (`--mode=spine --z_from/--z_to` walks a window, ~30
min for the whole spine, far less for one window) and read what the physics
engine reports.

**The stronghold one is the most urgent** because `OW6` places the captain along
that route, and today the final approach to the gate is not walkable.

### SPINE-LAYOUT — the trail runs through a building and past a post standing on it

**OWNER DECIDED, 2026-08-18: "route around the warrens but going through is a
shortcut."** Both, and in that order of priority:

1. **The spine routes AROUND the Burrow Warrens.** That is the default path and
   the one the 173.4 m gap between wp30 `(-420, 2470)` and wp31 `(-330, 2630)`
   must stop being. A player following the trail never walks into a wall.
2. **Going through stays possible, as a shortcut.** The Warrens gains a way
   through that is faster than the detour. That makes the building a piece of
   optional routing knowledge rather than an obstacle — a player who learns it
   is rewarded, a player who does not is never blocked.

This is strictly more work than either option alone, so build (1) first and
land it: a routed-around spine is shippable on its own, and the shortcut is
additive. Do not hold (1) waiting for (2).

`model: fable` · `tests: smoke_traversal` · `area: terrain, village`
Filed 2026-08-17 (OPS11) from `OW5-walk`. Both are authored placement, i.e.
layout questions rather than bugs, which is why the walking lane correctly left
them alone:

- **The spine runs into the Burrow Warrens' own structure.** Between wp30
  `(-420, 2470)` and wp31 `(-330, 2630)`, collider
  `BurrowWarrens/@StaticBody3D@3458`, contact normal 90° from up — a vertical
  wall. **173.4 m skipped, the single largest gap on the spine.** Not terrain,
  not scatter: the building. Either the trail routes around the Warrens or the
  Warrens gains a way through.
- **A signpost stands on the trail it labels.** `TrailheadSignpost_14/Post_Collision`
  collides at `(0.2, 6999.5)`; spine waypoint 71 is `(0, 7000)`. The body got
  around it, so it is an annoyance rather than a blockage — but it is a post on
  the centreline of its own road.

### DONE — RIVER-OVERHANG — the river is authored past the edge of the baked world

**LANDED integrate-11 (d926d679).** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: none` · `area: terrain`
Filed 2026-08-17 (OPS11) from `OW5-walk`. `river.course` runs to x ±1150 while
the baked region grid is valid to ~±1022, so three course points sit outside the
world and every boot prints `carve failsafe at (1090.0, 4100.0) has no ground to
measure; skipped`.

**This fully explains `OW5C`'s "a third station reports no ground at all
(1027,4101)"** — that reading is the authoring overhang, not a hole in the
world. Nothing is red today because `smoke_traversal.gd::_pick_river_stations`
excludes it via `RIVER_EDGE_MARGIN` 40. Clamp the course to the baked extent and
the boot noise goes with it.

### OW5-width — the corridor is 36% wider than the owner asked for
**CLOSED 2026-08-17 (OPS12) by the owner: "the width is fine as is."** The
measurement stands — 2,041.9 m, 6.81 min, at all three stations — and the
five-minute figure is superseded rather than missed. **Do not narrow the world
or re-bake for width.** What the measurement still buys is the flanks: 500 m of
currently-bare ground either side of the trail is `VEG-CORRIDOR`'s and `MQ3`'s
problem now, not a reason to change the footprint.

`model: fable` · `tests: smoke_traversal` · `area: terrain`
**Filed 2026-08-17 (OPS11) from `OW5-walk`'s measurement.** Owner's words: *"maybe it's five minutes of walking from side to
side."* Walked: **2,041.9 m, 6.81 min**, at all three stations, agreeing to
0.1 m — the body walked a dead straight line across the corridor everywhere and
nothing blocked it, so this is the authored width, not an obstacle artefact.

**Nobody ever chose 2,048 m.** `world_bounds` x [−1024, 1024] is simply where
the perimeter went when the footprint was made region-aligned, and nothing
measured it against the five minutes until now. The owner's figure implies
~1,500 m.

It misses in the direction that costs most: **1.4 extra minutes of empty walking
per crossing, in a corridor whose length is already right** — and the flanks are
currently bare (`VEG-CORRIDOR`), so that width is 500 m of nothing on each side.

**Three options, and the choice is the owner's:** narrow the world (a re-bake,
and 2,048 → 1,536 is not region-aligned — 1,024 is, so this is not a free dial);
keep the width and fill the flanks so the crossing earns its time; or accept
6.8 min and treat the five-minute figure as superseded. **Do not re-author the
world to make a number come out right without asking.**

### DONE — OW6 — The captain you can challenge is too close to the start

**LANDED integrate-11 (d926d679).** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: none` · `area: village`
Owner: *"The captain to challenge is way too close to where you start. You need
to work to find him."* Positions are data (`data/config/trainers.json`), so this
is a placement change once `OW5` establishes the trail — sequence it after, or
it gets moved twice.

**UNBLOCKED but constrained, 2026-08-17 (OPS11).** `OW5-walk` has measured the
route: 11,316.6 m walked, 37.7 min, so there is a real trail to place against
and the distance is trustworthy (walked/config 0.983). Two things it found bear
directly on where the captain can go:

- **The last 57.6 m to the stronghold gate is not walkable** (`SPINE-WEDGE`, six
  wedges at (−30..−34, 7513..7519)). Do not place him past that until it clears.
- **The spine cannot be walked south past Old Mill Crossing at all**
  (`RIVER-GATE`). A captain placed beyond z 4196 is currently unreachable on
  foot, however far along the trail he looks in the config.

`trainers.json` is also now band-split (`BAND-SPLIT`) — edit the band file, and
take an `order` from that band's reserved range.

## Phase -1.45 — measured performance, and what three blind reviews found

Filed 2026-08-16 by the coordinating session. Everything here is measured, not
suspected; the numbers are in each item.

### CAP1 — a capture scene for interiors, so a room does not cost a world
**CLOSED 2026-08-17 (OPS8).** Landed on `main` in `cab638ae`.
`tools/capture_interior.gd` builds only what an interior needs — the sky/sun/fog
rig, the camera rig and its `set_target(target, profile)` seam, a bare player
body, and `grandpa_house.gd` at the origin. Measured warm, same import cache
both paths so only the world-build step differs: **10m35s → 1m12s for three
frames, 8.8x.** `PT-03`'s 24–32 min figure was cold, where the gap is larger.

`model: sonnet` · `tests: none` · `area: perf`
`PT-03` spent **24–32 minutes booting the whole Meadows** — terrain, 23,707
scatter instances, the village — to photograph the inside of one room. Every
future interior task pays that, which is the kind of cost that quietly stops
people taking frames at all. A scene that instantiates only the interior under
test plus its camera profile would boot in seconds. `grandpa_house.gd`'s
kit-owns-the-exterior/script-owns-everything-else split is what makes this
possible; `tools/capture_loft_exit.gd` is the worked example to generalise.

### DONE (owner call) — PT-03-remainder — the stair affordance failed its blind pass

**CLOSED BY THE OWNER, 2026-08-18: "loft stairs are fine."** No work. He has
played it; the blind critic has not. A critic scoring the affordance 2/10 is
evidence, but it is evidence about a rendered frame, and the owner reporting
that he can find and use the stairs in play outranks it. **Do not reopen this
on the strength of another blind pass** — reopen it only if a real player, or
the owner, actually fails to find the stairs.

This also means the open question it carried — whether the loft slab's edge had
to change shape — is answered "no", and the geometry stays as built.

`model: fable` · `tests: smoke_opening` · `area: village`
`PT-03`'s root cause is correct and settled — the loft slab occludes every tread
from a standing eye, so no light could ever have worked, and `D52` records the
measured sightlines. **The affordance does not.** A blind critic given the pair
unlabelled: *"a post is not an exit — it doesn't say down, it doesn't say
through, it doesn't say walkable. 0/10 before, 2/10 after. That is not the
difference between lost and found."* A frame aimed **straight down the −51°
bearing at the stair head** still shows no treads, no descending rail and no
opening — so this is not "the player is facing the wrong way."

The evidence says the honest question is not a stronger rail but whether **the
loft slab's edge has to change shape** — a cut-back, a visible stairwell
opening, or the camera bias that was rejected. That is a decision about the
room, and it is the owner's.

Also open from the same pass, and separate: the interior camera profile spends
the bottom half of frame on empty floor with the player's head at the very
bottom edge. Predates this item.

### OW1-remainder — the backpack's remaining legibility defects
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
From the blind usability pass, judged at 40% scale as a seven-inch proxy. Two
are genuine defects rather than opinions: **nothing shows *what* you are
holding** (the source tile keeps its full count, no ghost, no cursor — so a
player who misses the text thinks nothing happened), and **the quick bar gives
all five chips the same cyan** while a stack is held, so "cursor is here" and
"valid target" are the same colour — `_refresh_quick_bar()`'s
`_slot_style(_bar_focused == i or _held >= 0)`, a two-line fix.

The rest: Escape silently stops meaning Close while holding; the 1–5 badges are
4–5 px and the font renders "4" like a Cyrillic Ч; "6 of 24 slots used" and
"GEAR" are unreadable at 40%; the held state is announced in four places; "6
Orb" should be "6 Orbs"; the screen is Backpack while the grid inside is
Satchel; and `Menu + View held, or F10 Reset all controls` is a leftover from a
controls screen sitting in an inventory footer.

---

## Phase -1.40 — the phantom wall, and three diagnoses that were wrong

Filed 2026-08-17. **Every item in this phase corrects an earlier confident
answer, including two of the coordinator's own.** Recorded that way on purpose:
the sequence of wrong diagnoses is the most useful thing here, because each was
plausible and each cost work.

> **CHECK THE TREE BEFORE WORKING ANY ITEM IN PHASES −1.40 THROUGH −1.45.**
> Added 2026-08-17 (OPS9), after it caught two lanes in one hour. These phases
> were filed in a burst on 2026-08-16/17 during a run that was landing a commit
> every few minutes, and **several items were fixed by commits that landed
> within the hour while the entry still read as open.** `TEST2` was filed at
> `bbc6b850` and `UI-PAD1` — the very next commit, 40 minutes later — closed
> two of its four named gaps; the `TEST2` lane found this only because it
> checked each one against `main` first. `UI-PAD3` then turned out to be
> shipped in full. Neither is a bookkeeping slip to tidy: an item that reads
> open and is done sends a lane to write code that already exists, and the
> lane will usually write it rather than argue with the queue.
>
> So the first step on any item here is `git log`/`git grep` against `main` for
> the thing the item says is missing. **Reporting "already shipped, here is the
> SHA" is a complete and valued outcome**, and is faster than the work.

### UI-PAD3 — `ui_accept` cannot replace a poll on a screen with no Button to press
**CLOSED 2026-08-17 (OPS9). It was already shipped when it was filed** — verified
in the tree, four checks, not by a branch ref:

- `tab_backpack.gd`'s `menu_confirm` **poll is gone**; the only two remaining
  mentions are footer label strings (`:1083`, `:1319`), which is exactly the one
  removal this item prescribed.
- `starter_picker.gd`, `combat_hud.gd`, `name_prompt.gd` and `tab_creatures.gd`
  all still carry their polls, which is what the item says must happen.
- `test_controls.gd` carries both `test_no_two_menu_context_actions_share_a_button`
  (widened past keyboard, :308) and `test_ui_accept_still_answers_the_keyboard`
  (:362) — the trap-guard this item named.

`model: sonnet` · `tests: test_controls` · `area: ui`
**Corrects `UI-PAD1` as filed by the coordinator**, which said: add the joypad
binding, then remove each now-redundant `menu_confirm` poll in the same change.
The lane checked before deleting and found **four of the five polls must stay** —
removing them would have broken three working screens:

| screen | why |
|---|---|
| `starter_picker.gd` | 0 Buttons — the orbs are custom-drawn. The poll is the only input it has. |
| `combat_hud.gd` | 0 Buttons — the switch selector is custom-drawn. Same. |
| `name_prompt.gd` | 0 Buttons — on-screen keyboard, already device-guarded. |
| `tab_creatures.gd` | Has Buttons, but `_begin_evolution` sets `_list.visible = false`, so nothing is focusable during the ceremony. `_end_evolution` re-grabbing focus is the tell. |
| `tab_backpack.gd` | Has Buttons **and** the rows are focused. The only genuinely redundant one. Removed. |

**The rule:** `ui_accept` can only replace a poll on a screen that has a
focusable `Button` for it to press. Check for `Button.new()` before deleting
anything.

**And the double-confirm everyone braced for does not arise**, for a reason
worth keeping: **Enter has always been both `ui_accept` and `menu_confirm` on
the keyboard.** Any screen with a focused Button beside a `menu_confirm` poll
would already have been firing twice for every keyboard player — and none was.
Adding JOY:0 makes the pad behave exactly as the keyboard already did. *When
weighing whether a new pad binding will double-fire, ask what the keyboard
already does first; it is usually already the answer.*

**One trap, now pinned by a test:** listing a built-in `ui_*` action in
`project.godot` **replaces** the engine defaults rather than adding to them.
`ui_accept`'s Enter / KP-Enter / Space survive only because `UI-PAD1` restated
them by hand; dropping one would quietly take Enter away from every menu in the
game. `tests/test_controls.gd::test_ui_accept_still_answers_the_keyboard` holds
that line.

### PT-17-test — the rename flow has no test for its own trigger path
`model: sonnet` · `tests: new` · `area: ui`
Flagged by the lane that rebased `PT-17`, about work it did not write: the
original commit added no dedicated test for the `tab_creatures.gd` rename flow
itself — H-key → prefilled `name_prompt` → `set_nickname`. Existing tests cover
the nickname mechanism generically, not that trigger path. The gap predates the
rebase and was correctly judged outside "make it landable".

### OPS3 — the unit suite takes nine minutes under load, and looks hung
`model: none (note)` · `area: ops`
`tests/run_tests.gd` took **over 500 s** on a loaded container and was killed
once by a lane that believed a global input change had deadlocked it. It had
not: it completed in ~9 minutes reporting 959 tests / 80,924 assertions / 0
failed. Companion to `OPS2` (concurrent headless runs corrupting each other's
script loading). **Give the suite room before concluding it hung**, and
serialise runs.

---

## Phase -1.41 — what the UI lane found on its way out

The four owner-reported UI items shipped in one lane on 2026-08-16 (`OW11`,
`OW10`, `OW4`, `OW8`). On finishing, that lane was asked to write down what it
had learned that did not belong in a diff. **What came back was larger than the
four items it had just closed**, and none of it would have survived otherwise —
which is the whole argument for `LANE1`'s notepad. Verbatim record in
`ralph/NOTES.md` on `ralph-status`.

### TEST2 — four tests that passed while the thing they name was broken
`model: sonnet` · `tests: the ones named here` · `area: tests`
Companion to `TEST1`, which asks the same question of the smoke suite generally.
These four are specific, found the hard way, and each is a distinct shape:

1. **No test in this repo chooses a build piece through input.**
   `tests/smoke_free_build.gd` calls itself "the menu-driving shortcut of arming
   `pending_build` directly" (~:152), and `tests/smoke_build_menu_footprint.gd`
   calls `menu.call("_select_category", i)`. That is exactly why a build menu no
   controller can operate has been green this whole time.
2. **`InputEventAction` hides every binding bug.** `tests/smoke_menu.gd` drives
   the backpack target picker end to end and asserts the heal lands — and passes
   on code where a pad could not confirm at all, because `InputEventAction` names
   the action directly and never travels the `InputMap`. **Any test asserting
   "the player can do X" with an action event asserts something weaker than it
   reads.** `tests/smoke_backpack_pad_target.gd` is the pattern to copy: real
   joypad events, button indices read from the live `InputMap`.
3. **`test_controls.gd::test_no_two_menu_context_actions_share_a_keyboard_key`
   only sees keyboard.** It does `var key := event as InputEventKey` and
   `continue`s on anything else, so joypad collisions are invisible. Its own
   failure message talks about a verb being "dead" — the exact bug that then went
   unnoticed on the pad side. Widening it to joypad buttons is cheap.
4. **`OW8`'s own test is weaker than it looks, recorded by its author.**
   `tests/smoke_prompt_hotbar_dock.gd` fails on pre-`OW8` code *only* on its
   structural assertion; all four rect-intersection cases pass there, because
   `_reflow_prompt` recomputes from the hotbar's live rect on `resized` and the
   harness grants the frames. **That is why the two previous OW8 fixes tested
   green and still failed on the owner's hardware, twice.** Anyone judging that
   fix by the rect cases alone concludes there was never a bug. The shared-parent
   assertion is the load-bearing one.

### OPS2 — two concurrent headless Godot runs corrupt each other's script loading
`model: sonnet` · `tests: none` · `area: ops`
Two concurrent headless runs on a four-core container produced
`Attempt to open script ... resulted in error 'File not found'` for a file
present on disk; re-running serially passed. Every lane brief now says serialise
your runs, but that is instruction, not enforcement. **If a smoke test dies with
a missing-script error, check what else was running before believing it** — this
is a plausible source of "flaky" CI that is not flaky at all.

---

## Phase -1.42 — the tourniquets, and the questions nobody asked

Filed 2026-08-16 by the coordinating session, as a self-audit rather than as
new work discovered. Every item here exists because a fix that shipped today
was a *workaround*, and the thing it worked around is still standing. They are
filed so the workarounds cannot quietly become the design.

## Phase -1.4 — the blind playtest's open findings (2026-08-15/16)

Full record in `docs/reviews/2026-08-15-full-blind-playtest/`. The six repairs
that pass already shipped; these are §7's leftovers. `PT-03` is the one the
report calls the highest-value remaining fix for a first-time player.

## Phase 7 — the village lives, the meadow reads

### R7.4 — Map reveal rule · `model: sonnet` · `tests: smoke_menu` · §23
**CLOSED 2026-08-17 (OPS7), on this item's own terms.** Its last line says to
close it if the fog already behaves, and it does: `5cb90968` ("OW3: the map
hides what you have not walked, and walking reveals more of it") is an ancestor
of `main`.

**The check below sends you to the wrong file, which is worth keeping rather
than quietly deleting.** `map_baker.gd` still contains no fog, reveal or
explored logic — grepping it, exactly as instructed, returns nothing and would
have you conclude the feature was never built. `OW3` put the reveal in
`tab_map.gd` and `minimap.gd` instead, which is the right place: the baker
renders the world once, and what the *player* has seen is view state, not
terrain. A closing check that names a file rather than a behaviour will keep
doing this.

**Re-scoped 2026-08-16.** The old text said the `map` action was "read by
nobody" — false since the map button was wired. The map, the minimap and the
player's heading arrow all exist and work.

What survives is only spec §16's rule: the map reveals explored areas and
landmarks and **never reveals everything automatically**. Check
`scripts/world/map_baker.gd` before writing anything — if the fog already
behaves, close this item.

### OF15 — Geometry snags: player can get stuck in places
`model: sonnet` · `tests: smoke_traversal (extend)`
Owner-reported, 2026-08-15. Movement getting wedged/blocked rather than passing
through. Needs locations logged from a fresh playthrough before a fix can be
scoped.

**CLOSED 2026-08-17 (OPS4).** The detector landed on `main` in `05264fda`, and
porting it taught something worth keeping: **its exclusions had to be re-derived,
not copied.** `STUCK_EXCLUDE_RADIUS` was a 200 m radius because the world was a
disc with a ring fence; the corridor has no centre. And it had no slope
exclusion at all — it never needed one on the old gentle disc, but the corridor
is built out of deliberately unclimbable rises, and ported as-is it reported
three wedges on correct terrain near (62,-105), where the ground climbs 7.1 m
over 8 m and a shape query finds no prop at all. Now excluded by edge margin and
by a slope probe sampled at **both** 4 m and 8 m — one ring is not enough.

**SOLVED 2026-08-17 — it was Captain Halder, and it took four diagnoses.**
`WALL1` found it: `spawns.json`'s seeded rng resolved Galecrest's home to 3.15 m
from a captain `trainers.json` hand-places at `[52.0,-122.0]` with a real
0.36 m capsule collider. The chase ran through his body. `is_on_wall()` was
true because there really was a wall — just not a terrain one, which is why
every terrain-side investigation came back clean. A frame-by-frame slide dump
named `Captain Halder/Body` on every residual frame.

The three wrong answers before it, kept because the sequence is the lesson:
props (a spacing filter was built and measured working, and the wedge survived
it); terrain slope (disproved — the ground reads 5-11 degrees and the wedged
body ran a MORE permissive 55-degree limit than the player's 45); collision
shape seams (a real and independent defect — `collision_shape_size` had been
silently stuck at 16 m, never the 256 the code believed, because the setter is
a no-op out of the tree — worth fixing on its own and it halved the residual,
but not the cause).

Closing this item. What survives it is a rule now in `OW5`: **a route is not
proven walkable by sampling the heightfield.** `ground_height_at()` lied to
three separate investigations. Walk a body and read what the physics engine
reports.

Superseded detail from 2026-08-16, kept for the record: A lane confirmed
the wedge at **(60, -106)** and **(65, -108)** and blamed clumped tree colliders.
A cross-layer spacing filter was built against that diagnosis, measured working
(23,707 placements to 23,650; rocks 345 to 300, trees 129 to 118) — **and the
player still wedges at (60, -106).** So the diagnosis was wrong. The evidence
points at terrain slope on the rocky rise instead: an earlier traversal run ended
that leg at exactly `(60.0, 0.2, -106.3)` after 46 m of a 190 m walk, and a review
of the same ground noted it "snags on the rocky rise". The player's
`floor_max_angle` is 45 deg, so the test may be flagging correct behaviour at a
place a route should never have crossed.

It is parked because **that ground is about to be rewritten.** `OW5B`/`OW5C`
rebake the world and lay a new trail; fixing terrain that is being replaced this
week is wasted work. The durable outcome is a constraint, not a repair, and it is
recorded on `OW5` rather than here: **no trail segment may cross ground steeper
than `floor_max_angle`, and a probe must assert it before the trail is committed.**
Re-open this item only if the wedge survives the rebake.

## Phase 6.5 — the quality plan's own items (owner's quality plan)

**Filed as backlog entries 2026-08-17 (OPS7), after a fresh coordinator found
they were missing.** `MQ1A` and `MQ1B` shipped and were closed out of this
phase, which left the header empty — and `MQ2B`, `MQ3` and `PW2` had never been
transcribed here at all. They existed only in
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md`.

**That made this file wrong about the thing it claims to be.** Its first line
says it is the state of the project. A session reading it top to bottom today
would count fifteen open items, most of them small, and conclude the game is
nearly done — while the largest block of remaining work on the project sat in a
planning document with no entry anywhere in the queue. The previous
coordinator's own handover named `MQ2B` and the `MQ3` umbrella as the work after
`OW6`, citing IDs this file did not contain.

The plan stays authoritative for what these mean and what "done" is; these
entries exist so the queue stops omitting them. Do not duplicate the plan's
prose here — read §6, §7 and §8 there.

### BAND-SPLIT — one content file per band, so bands can be authored concurrently
`model: opus` · `tests: run_tests, smoke_playground, smoke_traversal, a new identity test` · `area: data, world`
**Owner-requested, 2026-08-17:** *"can you fan out agents to do the corridor
design work concurrently. so each agent builds a separate band then they all
come back and we have the full corridor?"*

That is the right end state and the bake already supports its terrain half —
`OW5B` factored the bake to take a region set with a bit-identity test, because
every pixel is computed from its own coordinate and nothing else, so adjacent
regions baked independently agree exactly at the boundary.

**What blocks it is data layout, not agents.** All Meadows content lives in four
monolithic top-level arrays — `spawns.json` (`spawns`), `props.json`
(`clusters`), `harvest.json` (`nodes`), `trainers.json` (`trainers`). Every
band's content goes in the same arrays in the same files, so five band agents
would edit all four files continuously and conflict on every one. **File
exclusions are the mechanism that actually keeps this project's lanes off each
other, and they cannot help when the unit of exclusion is a file and the unit of
work is a band.** This item makes the unit of ownership match the unit of work.

**The load-bearing requirement is identity, not tidiness.** The merged result
must load identically to today — same entries, same values, **same order**.
Order is not cosmetic here: `spawns.json` resolves creature homes through a
seeded RNG, and `WALL1` was ultimately a spawn landing 3.15 m from a hand-placed
trainer. A merge that changes iteration order moves seeded placement, and the
world changes with nobody editing content. Prove it with a test that is
demonstrated failing, not by reading the diff.

**Scope guards.** Author no content — not one spawn, prop, node or trainer; that
is `MQ2B`/`MQ3` and it is fable work. Keep genuinely global keys (`trainers.json`'s
`flow`/`prompts`, `spawns.json`'s `respawn_seconds`/`roles`) in one place rather
than sharding them into five copies that can drift. `vegetation.json` is scatter
*rules*, not placements — leave it alone; its problem is `VEG-CORRIDOR`.

**Done when** five disjoint file sets exist, one per band, an identity test holds
the merge honest, and the next coordinator can hand five agents five bands
without a shared file between them.

### CI-BOSS — `verify-boss` is intermittent, and it has now cost two innocent branches
`model: sonnet` · `tests: smoke_boss.gd itself` · `area: tests, ops`
Filed 2026-08-17 (OPS13). **This is `TEST1`'s question answered by a second
example, and it is no longer a suspicion.**

| branch | its own diff | run | outcome |
|---|---|---|---|
| `ralph/TEST2` | two test files, `project.godot` untouched | dispatch failed, **green on re-run** | not its diff |
| `ralph/PT-17-test` | one new rename test | dispatch failed, re-run requested | not its diff |

Both were green on all 19 jobs on their own push and red only on the
`ralph-merge` dispatch of the same tree. The root failure is a single line —
**"the boss fight never resolved inside 9000 frames"** — and the six `FAIL`s
after it are all consequences of that one, not six independent failures.

**"Never resolved inside N frames" is a timing-dependent assertion**, which is
exactly the shape `TEST1` asks about: which smoke tests depend on a position, a
spawn, a timing window or an RNG draw they do not control? `verify-aggression`
was the first (fixed by `CI-AGGRESSION`); `verify-boss` is the second.

**Why this is worth a lane rather than a shrug:** `ralph-merge.yml` only
fast-forwards fully-green branches, so an intermittent job does not annoy
anyone — it silently stops healthy work from shipping and leaves no trace
saying so. It has now delayed two landings in one evening, and the next lane to
hit it may "fix" its own innocent diff to make the red go away.

**Do not just raise the frame budget.** Find what the fight is actually waiting
on — whether the boss can fail to engage from a given start position, or a
timing window depends on load. The container was under four concurrent lanes
both times, which is itself a clue.

### DONE — BAND-SPLIT-2 — the rest of what still makes five band agents collide

**LANDED integrate-11 (d926d679).** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: run_tests, an identity test per split` · `area: data, world`
Filed 2026-08-17 (OPS11) from the `BAND-SPLIT` lane's own answer to "will five
agents authoring five bands actually work now?" — *"for the four configs I
split: yes, today. For 'and then combine them into a finished world': not yet."*
**A band author who can add a creature, a prop, a harvest node and a trainer but
cannot add a clearing, a footprint or a landmark can only populate terrain that
already exists.** In the lane's own fix order:

1. **`vegetation.json`'s `clearings` (9) and `footprints` (7)** are positional
   arrays in a monolith — exactly the shape just split — and all sit near the
   origin. Every building, camp or structure a band places needs a footprint or
   grass grows through its floor. A guaranteed five-way collision on one file,
   ~an hour, mechanical: same `order` + per-band treatment, leaving the scatter
   *rules* alone. **Distinct from `VEG-CORRIDOR`** — same file, different
   problem, neither blocks the other.
2. **`data/dialogue/` is already multi-file and already uses this pattern** (an
   explicit const path list merged in `dialogue_runner.gd:32-45`) but is split
   by chapter beat, not band. Every new trainer's conversation lands in one
   `trainers.json` and Band 2 has no file at all. Adding
   `data/dialogue/bands/<band>.json` to that list is small. Do it with (1).
3. **`terrain_playground.json` is the real gate** and is harder: the spine is
   genuinely global — Band N's first point is Band N−1's last — so
   `trail.bands[]` cannot be partitioned. The lane's *guess*, explicitly flagged
   as a guess, is that the derived/decorative arrays (anchors, landmarks, rises)
   are band-local and could be cut the same way while the spine stays whole and
   coordinator-owned. **Measure which arrays are actually band-local before
   committing to it.**
4. **`docs/decisions/` is already colliding on `main` today** with no fan-out at
   all: two `D50-` files and two `D53-` files exist. Five agents each writing a
   decision doc will keep minting duplicates. Cheapest fix is **the coordinator
   assigning the number in the brief**.
5. **The `order` reserved ranges (Band N → `N000`–`N999`) are documented, not
   enforced at author time.** The uniqueness test catches a collision at CI
   time on whichever branch merges second — loud rather than silent, which is
   the right failure mode. **Put each band's range in its brief** rather than
   relying on the author reading a comment.

### VEG-CORRIDOR — the scatter still only dresses a 512 m square at the origin
`model: opus` · `tests: smoke_playground, run_tests, a placement-extent test` · `area: vegetation, terrain, perf`
**Blocks `MQ2B`, and was found by asking what the corridor actually looks like
today rather than what the bake produced.** Verified in code, not inferred:

`playground_world.gd:597` passes `config.get("world_size", 512)` into
`vegetation.build()`, and `scatter_rules.all_placements` → `placements_for`
samples every clump and stray inside `[-half, +half]` on **both** axes, where
`half = world_size * 0.5 = 256`. `world_size` is still 512 on purpose —
`terrain_playground.json`'s own `_comment_world` records `OW5B` keeping it there
because vegetation, the minimap and the map baker all assumed the old square.

The map half of that has since been fixed: `map_baker.gd` and `minimap.gd` now
go through `world_extent.gd`, which reads the corridor's real asymmetric bounds.
**Vegetation is what is left.**

`OW5E` widened exactly one part of this and said so in its own comment
(`scatter_rules.gd:531-546`): an authored **anchor** may now be placed anywhere
in the corridor, checked against `field.world_bounds()` — which is what fixed
the quarry `deadfall` at (403,1803) being silently rejected on every attempt and
`smoke_boss.gd`'s D41 regrowth check finding nothing drained. That comment ends
"This widens what an ANCHOR may pass, not what a clump/stray may sample."

So today: the corridor runs z −512 to 7680, and **all ~23.7k scattered instances
sit in z −256 to +256** — roughly the first 3% of a 7,560 m trail. Everything
past it is correctly-shaped, correctly-baked bare landform with a handful of
authored anchors on it. That is not a quality problem to be tuned; it is a
bound.

**This is why it cannot simply be widened to the corridor and shipped.** Density
that reads well over 512 m becomes ~30x the instance count over 8192 x 2048 m if
naively scaled, and boot already cost 3m08s before the corridor existed
(`PERF2`), with scatter alone at 45 s. The answers interact with the streaming
work already on `main`. Expect this to need per-band density that is authored,
not uniform, and to be measured on the Ally rather than assumed.

**Sequence it after `OW5-walk`.** That lane is measuring real traversal over the
whole corridor right now, and what it reports about distance, collision and
streaming is the input to how this should be bounded. Do not start it blind.

**Done when** the trail is dressed for its whole length, per-band, with the
instance count and boot cost measured before and after and stated as numbers —
and when a placement-extent test fails if the scatter ever silently reverts to a
square again.

### NIGHT-LIGHT — night renders as near-total black, and a blind critic has named it three rounds running
`model: sonnet` · `tests: smoke_playground, a night luminance check` · `area: visual, world`
**Filed 2026-08-17 (OPS16) from `MQ2B`'s convergence loop.** Three consecutive
independent blind passes ranked this in their top three, and round 1 put it
plainly: the night frames are *"crushed to near-total black... failing the
keyart's explicit 'day and night create different moods' direction by simply
not rendering a scene."*

**It is not a framing problem, which is the thing worth knowing.** Round 2
moved the night camera from ~85 m to ~10 m of its subject specifically to test
that, and recorded that 06/07 *"are still close to black even at 10m."* So the
subject is lit the same either way — this is the lighting preset, not the shot.

Evidence in the tree: `docs/reviews/band2/round-0*/` — the night JPEGs are
~2 KB against ~22 KB for the day frames at the same resolution, which is the
compressor telling you there is almost nothing in the image.

**Why the content lane could not fix it:** it is a global preset
(`data/config/art.json`'s night entry), not a Band 2 question, and `MQ2B`
correctly refused to edit a world-level setting from inside a band. It is now
one of the two gaps holding that band's convergence.

**Related and probably interacting:** `torch.gd` auto-lights at night (`OF18`
fixed a real race where `_world_look` cached null and the feature never fired
for the whole life of the feature). Check whether the torch is actually lit in
these frames before tuning exposure — a correctly-dark night with a broken
torch is a different bug from a night that is too dark with a working one.

**This is visual-affecting work**, so it needs the blind pass per
`ralph/conventions.md`, and the same convergence rule applies. Do not simply
raise ambient until frames look nice on a desktop monitor — judge at 40%
downscale as the seven-inch handheld proxy, which is where the owner plays.

### DONE — MAT-BLOCKOUT — two landmark assets read as untextured blockout at close range

**LANDED main (7fa9735e).** Closed by the coordinator in the same pass that landed it.
`model: sonnet` · `tests: none (visual)` · `area: visual, assets`
**Filed 2026-08-17 (OPS16) from `MQ2B`'s convergence loop.** Named by the blind
critic in rounds 2, 3 and 4, in the same rank each time, and **only visible once
round 2 moved the cameras close** — round 1's 85–110 m shots could not see it:

- **The Old Quarry's rootstone deposits** read as *"a pale mint/seafoam...
  hatch-patterned surface"* that *"doesn't read as stone at all."*
- **The Burrow Warrens' wall** is *"completely flat-shaded... no texture... it
  looks like unfinished blockout geometry."* The round-1 frame set shows it as a
  flat grey box against grass.

Both are shared assets rather than Band 2's own content, which is why the band
lane left them alone — correctly, since fixing a material in one band fixes or
breaks it everywhere.

**Decide first whether this is a material bug or an asset ceiling**, because the
two have very different answers and this project has been caught by the
difference before. `EV2-landmark-oak` in `BLOCKED.md` records a case where a
config bug made `CherryBlossom_3` render in its native pink instead of the
intended green — *a real bug that looked like an asset limitation* — and
`vegetation.json`'s `grove` layer never keying `Leaves_CherryBlossom` was the
cause. A mint-green hatch pattern on stone has exactly that smell: a material or
UV that was never assigned, not a model that cannot look like rock.

**If it turns out to be a genuine asset ceiling**, that is a `BLOCKED.md` entry
for the owner under `CLAUDE.md`'s no-new-Meadows-meshes rule, not something to
work around — and it is the "needs art that is not in the build" outcome the
owner's own stopping rule anticipates.

**Also unresolved from the same rounds, and cheaper**, listed here so it is not
lost: an unexplained *"kite-shaped shadow"* intruding bottom-centre in three
round-1 frames. Round 2 tested the obvious hypothesis — a parked out-of-shot
trainer body — by moving it further away, **and the shape survived**, so that
explanation is disproved rather than untested. Round 1 also named a floating
icon in frame 01 and a cyan sparkle in frame 03 with no visible source.

**ROUND 6 STATUS, 2026-08-18.** `docs/reviews/band2/round-06/`, landed
`335a6dc7`/`6136d4b7`. Not flat — real measured movement AND a new defect, so
per `OPS15` this does not count toward the two-consecutive-flat stop and
`MQ2B` stays open.

- **Night converges.** `NIGHT-LIGHT`'s round-4 fix (`e250a2f7`) measured:
  `near_luma` 0.000→0.083/0.020 on both night frames (was literal flat
  black), chroma% 5.5x/24x, well past the 0.03 noise floor. Clears the bar.
- **Bare-ground gap closes at the two measured stretches.** `VEG-SITING`
  (`5645a20`, landed after round 5) sites corridor clumps along the trail
  instead of uniformly across the 2048 m box; chroma% moved 13x and 2.4x at
  the two spots round 4's berries sit at.
- **New defect, not previously reported in any round-1..5 README:** flat
  blank-white cross-quad billboard cards, planted in ground or floating, in
  4 of 8 day frames. Filed below as `VEG-WHITECARD`. **This is the
  remaining thing standing between `MQ2B` and closing** — the zero-creature
  finding (Bar A/B) is unchanged since round 1 and not this band's to fix
  (no spawn sits on any of these 8 viewpoints' paths).
- **Not a regression, not worth re-opening:** the critic also flagged the
  Warrens wall in frame 04 as flat-shaded blockout. Cropped 2x — the
  `MAT-BLOCKOUT` stone texture (`7fa9735e`) is genuinely there, it just
  doesn't read at the 640x360 judging resolution from that viewpoint's
  distance. Legibility-at-distance note, not a `MAT-BLOCKOUT` reopen.

**Next round should be scoped, not full**: land `VEG-WHITECARD`'s fix, then
a round 7 that only re-checks those 4 frames rather than re-surveying all 8
from scratch — everything else round 6 measured is solid.

### VEG-WHITECARD — blank white billboard cards planted in the ground or floating, 4 of 8 Band-2 day frames
`model: sonnet` · `tests: none yet — needs a repro` · `area: visual, world`
**Filed 2026-08-18 from `MQ2B` round 6.** Flat, blank white cross-quad
billboard cards in `docs/reviews/band2/round-06/01-early-forest-day.jpg`
(one large, foreground), `02a`, `02b`, and `04` (several small, strung along
tree lines at range). New to round 6 — grepped every prior round's README
for white/billboard/impostor/blank, no hits.

**Already ruled out** by the round-6 lane: a missing texture on
`Grass_Wide_Short`/`Wide_Tall.gltf` (the newest grass species, added under
`OF12-remainder`) — both correctly reference `Grass.png`, file exists,
`.import` present. **Not yet investigated:** runtime material binding.
`vegetation.gd`'s `_warn_about_shared_models` describes a *tint*
last-writer-wins bug, not a blank-white one, so probably not the same
mechanism — could be a Godot auto-LOD dropping the alpha-cutout material on
a `MultiMesh` instance. This needs in-engine node inspection, which is out
of scope for a content-survey round; give it its own lane before round 7.

**Done when:** the white cards are gone from a re-render of the same 4
frames, and the fix is understood well enough to say why (not just that
re-rendering happens to look different).

### MQ2B — prove one region at finished quality before scaling
**STOPPING RULE CHANGED BY THE OWNER, 2026-08-17 (OPS15).** Verbatim:

> *"the current band we are working on should work until a blind review agent
> determines there's nothing else we can do to make it work more like palworld
> with our current terrain system and assets."*

**So a band is not one authoring pass. It is a loop that a blind critic ends.**
Author, render real frames of the band (day *and* night, real eye height), run
`.claude/skills/visual-judge` told nothing about what changed or what answer is
wanted, fix the defects it names, re-render, repeat.

**The instrument already existed and already does exactly this.** `visual-judge`
compares frames against `docs/reference/palworld-0*.jpg` — five real Palworld
screenshots — and its Bar B is *"Shown these frames beside
`docs/reference/palworld-0*.jpg`, would…"*. Nothing new needed building for this
directive; it named the bar the skill was already using.

**Stop on convergence, not on a round count** (`ralph/conventions.md`): a round
counts as improvement only if the critic names a **new** defect or
`tools/frame_stats.py` shows measured movement on an axis the critique is about.
**Stop after two consecutive rounds with neither** — two, not one, because a
single flat round is often a fix that has not landed yet. Reordered defects,
reworded defects and "still not fixed" are not improvement.

**"With our current terrain system and assets" is the owner's own bound, and it
is the load-bearing half.** It makes *"this needs art that is not in the build"*
a legitimate stopping point rather than a failure. `R9.4` is the precedent: four
uncapped rounds, four blind critics, every measurable axis moved, and both
critics still ranked "needs art that is not in the build" first. It had not
stopped early — it had run out of what tuning could reach. A defect needing a new
mesh, a Meshy generation or a terrain-system change **is the wall**; record it
(`BLOCKED.md` or a labelled remainder) with the round count and what the last two
rounds failed to move, and do not chase past the bound. `CLAUDE.md`'s no-new-
Meadows-meshes and no-generation-without-owner-reference-art rules still bind.

**This rule applies to whichever band is current**, not only Band 2 — it is how a
band is finished from now on.

### MQ2B — the original entry

`model: fable` · `tests: none (playtest gate)` · `area: terrain, world-layout, content`
Plan §6. **Starts with fable — it is ceiling-setting authorship.** Take the first
appropriate Meadows region and finish it to production standard: terrain
composition, vegetation structure, readable paths, a major landmark, an
exploration loop, a reconnect or shortcut, meaningful gatherable placement,
creature habitat, an optional discovery, a memorable encounter, day and night
readability, and no empty filler stretches.

This is the production recipe, not one region's decoration. The plan's expansion
rule is explicit: only after this region passes may its principles be used to
author the remaining bands, and what gets copied is the quality bar, never the
layout.

**Sequence it after `OW5-walk`.** Finishing a region to production standard
along a route whose real length nobody has measured is how content gets placed
twice — the same reason `OW6` waits.

**Done when** a blind playtest spends meaningful time exploring the region
voluntarily rather than following the critical path through it, and can say what
made it visually distinct, what made it mechanically interesting, where they
chose to leave the path, and what landmark they navigated by.

### MQ3 — the Meadows content umbrella
`model: fable` per major content beat · `tests: per unit` · `area: content, quests`
Plan §7. **This is not one task and must not be taken as one.** It is the
creative umbrella over the existing progression-sized units; break implementation
into those units and author them in unlock order, so each section can be played
and judged before later content depends on it. Build progression plumbing first
where still unbuilt — state tracking, keys and gates, quest log, objective
transitions — without over-generalising for a second biome that is forbidden
until the Meadows passes its exit gate.

**The corridor is what makes this large.** The world went from a 512 m square to
8192 x 2048 m yesterday, and `OW5D` relocated the already-approved content into
it rather than adding any. So bands beyond the first are, today, mostly empty
ground. Each region owes a clear entry, a clear purpose, recognisable geography,
one meaningful critical-path objective, an optional discovery, a memorable
encounter, working navigation, day/night usability, a real reason to explore,
and a clear transition to the next.

Side content may be authored before the XP economy exists; reward wiring can land
later, and per the plan the design must not be hardcoded around XP per hour
before `R4.1` provides levels.

### PW2 — alpha / elder wild variants
`model: fable` · `tests: per encounter` · `area: creatures, content`
Plan §8. Folds into `MQ3`'s regional content rather than running as its own pass.
Rare landmark encounters that give optional paths a reason to exist. **No new
Meadows creature meshes** (`CLAUDE.md`, D23) — and explicitly not "normal
creature, larger scale, more HP": each needs at least one real behavioural or
encounter difference, such as a different aggression pattern, altered cadence,
group behaviour, unique habitat, environmental advantage, a move variant, a
special arena, or unusual time-of-day presence.

## Phase -0.6 remainder — the look

### EV9 — Rebuild the HUD, remainder

**OWNER APPROVED A TITLE SCREEN, 2026-08-18: "yes title screen."** This
unblocks both of EV9's remaining pieces at once — they were never two problems,
they were one missing mount point:

- the branded display font / `ev9_display_lettering_style_guide.png` finally has
  a wordmark to be applied to;
- the `orb_capture` icon still needs an orb-count panel, but a title screen is
  where the game's own presentation gets settled, so decide the panel there.

Note `D18` boots straight into the world **by decision**, not by omission. A
title screen supersedes that for the boot path, so **write the new decision
doc rather than silently contradicting `D18`** — say what changed and why the
owner asked for it. Build the screen first, then EV9's two pieces on top; they
are cheap once something exists to mount them on.

`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Most of this item shipped across four slices. **Tested at
physical 7-inch scale, not on a desktop monitor** — §17 is explicit.

Genuinely still open:
- `orb_capture` icon has no mount point — there is no orb-count panel anywhere
  in the current HUD to hang it on. Needs a panel first, or the owner naming a
  different place it belongs.
- A branded display font matching the "TETHERBOUND" key-art logotype, and
  gradient/beveled bar fills. The owner supplied a style board
  (`ev9_display_lettering_style_guide.png`) but there is nowhere to apply it:
  the game boots straight into the world (D18) and renders no wordmark
  anywhere. Needs a title screen to exist first, or a different mount point.
- Compass — the bible says "if it exists"; it doesn't, and inventing one is not
  this item's job.

## Phase 8.5 — the chapter's own audit

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm none
of them installed, requested or planned a new creature mesh. Cheap, and worth
doing once at the end, because the constraint is a budget the owner holds and a
single quiet violation spends it.

---

## Phase 9 — polish

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet`
### R9.2 — Controller UI readability on the Ally · `model: sonnet`
### R9.3 — Performance on target hardware · `model: sonnet`

---

## Ops

### OPS1 — Backfill `DONE.md`, and fix what let it drift
`model: haiku` · `tests: none`
`DONE.md`'s newest entry is `SG44+SG46+R8.5+R8.6`, and it has **no entries** for
OF19–OF33, SC12–SC15, SD16–SD18, SE21–SE30, SF31/SF34, SG38/SG40, R8.1–R8.4,
SH47 or the playtest repairs — roughly 25 shipped items. The loop's
"move it to DONE.md when you ship" contract is broken, and that is the root
cause of the 2026-08-16 prune that produced this file. Backfill from `git log`,
then state in `PROMPT.md` what a firing owes when it ships.

Also record the work that shipped with **no backlog item at all**, so it is not
re-done: elixirs (D45), tonics (D47), moves becoming non-interchangeable, the
workbench becoming a real crafting station with craftable tools, and
tool-in-hand + assignable hotbar + the map button (save format 6→7).

---

## Found along the way — small, unscheduled

- **`tether_relay.json`'s console gate is a seam waiting on a dependency that
  already shipped.** Its `requires_flag` is `""` with a comment saying to set it
  to `relay_captain_defeated` "once SE25 has landed" — and `SE25` is recorded
  done in this file, with `relay_captain` in
  `bands/band3_the_river_lock/trainers.json` setting exactly that flag. So the
  relay console can currently be shut down without beating the captain who
  guards it, and the authored intent (mechanism built, `tests/smoke_relay.gd`
  already sets the value and checks the refusal) has been one string away from
  live since SE25 merged. NOT flipped here: it is a behaviour change and this
  lane had no Godot to run `smoke_relay` against. Third instance of the same
  pattern in this file after `PERF-LOD` and `GATEC-CURVE`'s inert wild bands —
  worth a sweep for `requires_flag`/`if_flag` seams whose named dependency has
  since landed. `model: sonnet`

- **GATEC-ECOLOGY / GATEC-TRAINERS — the corridor's empty half, found 2026-08-22
  and closed.** Bands 3 and 5 shipped empty `spawns.json` files and Band 4 held
  one cluster across its 2240m, so from the Burrow Warrens to the Warden — three
  of five regions, the entire back half of the chapter — the world contained two
  Meadowharts. Band 2 shipped an empty `trainers.json`, so the quarry/warrens
  region was wild traversal plus one dungeon boss and the first Team Tether
  fight did not happen until the relay in Band 3. Both closed on
  `claude/gatec-progression-curves-ep2j4x` (19 spawn clusters, 2 grunts, 17
  trainer battles chapter-wide). **The lesson worth keeping is the failure mode,
  not the fix:** `GATEC-CURVE` had just authored per-region wild escalation into
  `chapter_curve.json` and wired `encounter_director` to resolve it from a
  cluster's world z — a correct mechanism with no clusters in three of five
  regions to apply to. Same shape as the `PERF-LOD` entry above: written, tested,
  and inert. Prefer checking that a new rule has content to act on over checking
  that the rule is right. `model: opus`

- **Band 4 has no harvest nodes of its own.** The region named
  `band4_upper_meadows_ironwood` contains zero harvest entries; the ironwood
  grove its name refers to is five nodes authored in
  `bands/band2_stone_and_root/harvest.json` at z=2461, 12m from the Burrow
  Warrens entrance. Not a bug in Band 2 — the grove is sited fine and the player
  cuts it where they already are — but Band 4 is the chapter's longest region
  and gives the player nothing to gather in it. Belongs to
  `65-BAND4-finished-upper-meadows.md`. `model: sonnet`

- **`stronghold_climax.json`'s Warden fallback is pre-OW5D.** Its `warden.fallback`
  is `[232, -206]` and its `site` comment describes arena boxes at z -227..-169,
  both from before the corridor moved north; `bands/band5.../trainers.json`
  carries the relocated `[90.2, 7569.4]` with the offset written down. Fallback-only,
  so it bites solely when the building fails to build — but that is exactly when
  a fallback is read, and it would put the Warden 7.7km from his own room.
  `model: sonnet`

- **The three Sigil captains do not escalate along the corridor.** In route order
  Riverwatch (z=4350) tops at 16, Field (z=5590) at 15, Ridge (z=6460) at 16.
  Any order opens the gate so no order is wrong, but the first captain met is
  currently the joint-hardest. `GATEC-CURVE` already retuned two of the three, so
  this is a deliberate leave-alone pending owner play rather than an oversight.
  `model: sonnet`

- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what they
  know, the rescued NPC returning, story check-ins. The farmhouse should not
  become a room you never re-enter after the first twenty minutes. `R7.6`'s
  berry farm is the first answer to this. `model: sonnet`

---

## Done

Ids only. `git log` and `DONE.md` are the record; this list exists so a firing
can tell at a glance that an id is spent.

- OF15 — done
- EV10 — done
- EXP1 — done
- LANE1 — done
- MERGE1 — done
- MQ1B — done
- OF18 — done
- OW1 — done
- OW10 — done
- OW11 — done
- OW2 — done
- OW4 — done
- OW5A-rework — done
- OW7 — done
- OW8 — done
- OW9 — done
- PERF1 — done
- PERF2 — done
- PT-03 — done
- PT-04 — done
- PT-15 — done
- PT-17 — done
- PT-18 — done
- PT-19 — done
- PT-23 — done
- R7.3 — done
- R7.6 — done
- R7.7 — done
- R7.8 — done
- R7.9 — done
- TEST1 — done
- UI-PAD1 — done
- UI-PAD2 — done
- WALL1 — done
- BG1 — done
- BG2 — done
- CO1 — done
- EV1-remainder — done
- EV2 — done
- EV2-trunk-colour — done
- EV3 — done
- EV3-remainder — done
- EV3-remainder-2 — done
- EV3-remainder-3 — done
- EV3-remainder-4 — done
- EV3-remainder-5 — done
- EV4 — done
- EV4-hillside-seam — done
- EV4-hillside-seam-remainder-2 — done
- EV4-hillside-seam-remainder-3 — done
- EV4-hillside-seam-remainder-4 — done
- EV4-textures — done
- EV4-textures-lighting — done
- EV4-textures-remainder — done
- EV5 — done
- EV5-remainder-2 — done
- EV6 — done
- EV6-remainder — done
- EV6-remainder-well-rocktrim-shadow — done
- EV7 — done
- EV7-remainder — done
- EV8 — done
- EV9-double-prompt — done
- HD1 — done
- HD1-remainder — done
- HD2 — done
- HD2-remainder — done
- LP1 — done
- LP4 — done
- LP7 — done
- LP8 — done
- LP9 — done
- MQ1A — done
- NP1 — done
- NP2 — done
- NP3 — done
- NP4 — done
- NP4-rig — done
- NP4-uv-split — done
- NP6 — done
- NP7 — done
- OF1 — done
- OF2 — done
- OF3 — done
- OF4 — done
- OF4-rebuild — done
- OF4-remainder-mound — done
- OF5 — done
- OF6 — done
- OF7 — done
- OF8 — done
- OF9 — done
- OF10 — done
- OF10-remainder — done
- OF11-remainder — done
- OF12-remainder — done
- OF13 — done
- OF16 — done
- OF19 — done
- OF20 — done
- OF21 — done
- OF22 — done
- OF23 — done
- OF24 — done
- OF25 — done
- OF26 — done
- OF27 — done
- OF28 — done
- OF29 — done
- OF30 — done
- OF31 — done
- OF32 — done
- OF33 — done
- R0.11 — done
- R1.1 — done
- R2.1 — done
- R2.2 — done
- R2.3 — done
- R2.4 — done
- R2.5 — done
- R2.7 — done
- R2.8 — done
- R3.1 — done
- R3.1-remainder — done
- R3.2 — done
- R3.3 — done
- R4.1 — done
- R4.1-remainder — done
- R4.2 — done
- R4.3 — done
- R4.4 — done
- R4.5 — done
- R4.6 — done
- R4.7 — done
- R4.8 — done
- R4.9 — done
- R4.10 — done
- R4.11 — done
- R5.2 — done
- R5.3 — done
- R6-village-notification-freed-instance — done
- R6.1 — done
- R6.2 — done
- R7.5 — done
- R8.1 — done
- R8.2 — done
- R8.3 — done
- R8.4 — done
- R8.5 — done
- R8.6 — done
- R9.4-remainder-2 — done
- R9.4-remainder-6 — done
- R9.4-remainder-8-rocks-repeat — done
- R9.4-remainder-9 — done
- R9.4-remainder-9-combat — done
- RB1 — done
- SA0 — done
- SA0-orbs — done
- SA1 — done
- SA1-lod — done
- SA2 — done
- SA2-flake — done
- SA3 — done
- SA4 — done
- SA5 — done
- SA6 — done
- SA7 — done
- SA8 — done
- SB9 — done
- SB10 — done
- SB11 — done
- SC12 — done
- SC13 — done
- SC14 — done
- SC15 — done
- SD16 — done
- SD17 — done
- SD18 — done
- SE21 — done
- SE22 — done
- SE23 — done
- SE25 — done
- SE27 — done
- SE30 — done
- SF31 — done
- SF33 — done
- SF33-remainder — done
- SF34 — done
- SG38 — done
- SG40 — done
- SG44 — done
- SG46 — done
- SH47 — done
