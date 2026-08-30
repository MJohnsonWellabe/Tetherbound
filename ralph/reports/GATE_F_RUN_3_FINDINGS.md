# Gate F run 3 — findings about the GAME

**Rewritten:** 2026-08-30, from `ralph/reports/gate-f-run-20260828T183531Z`'s
own `INVENTORY.json`/`events.jsonl`/`notes/*.md` files. **Branch:**
`ralph/T2-GATEF`. **Candidate:** `main@26f0db4`, unchanged for every segment.
**Lanes run:** logic only. **No pixels were captured** — see
`GATE_F_CAPTURE_LANES.md`. **Companion:** `GATE_F_RUN_3_RIG_FINDINGS.md` —
findings about the instrument; read it first if you have not, because most of
what makes this run hard to read is there, not here.

**Run state at rewrite time:** S01-S09 complete, S10 BLOCKED at step 27/121 on
a genuine cost gate, X02 complete, X03 killed mid-run (not evidence, preserved
as `X03-killed-1/`), X04 now complete (see below), X01/X03/X05-X08 not yet
run by this lane (X03 and X06 held on the T2-STRANDING verdict per the
coordinator's 2026-08-29T16:06 correction).

> **T2-GATEF-RUN4 update, 2026-08-30 (`ralph/T2-GATEF-RUN4`):** **GAME-0
> (below) and T1 (dark-features inventory, `trainer_npc.gd`'s dialogue
> collapse) are both fixed, live-tested, and pushed** — see the GAME-0
> section for the fix shape and `tests/smoke_trainer_no_usable_ally.gd` for
> the live proof. Neither fix produced a healthy `S03-exit.json` by itself:
> chasing why surfaced two NEW, still-open findings — see **GAME-8** (the
> Mira-shop exit walk traps the navigator against `shop_interior.gd`'s own
> counter/shelf collision, unrelated to the door BUILDPLACE round 3 already
> fixed) and **GAME-9** (the tool-equip sequence does not reliably keep the
> intended tool equipped across a full segment replay's own gathering loop)
> below, both new to this pass. **A healthy S03 -> S09 chain still does not
> exist.** See `ralph/reports/handover-T2-GATEF-RUN4-2026-08-30.md` for the
> full evidence trail.

---

## The headline finding: the player has been stranded at the South Bridge since partway through S05, and it dominates everything downstream

This is not a footnote. **Every single `move_to` step in the kept S06, S07,
S08, S09, and the first 22 steps of S10 fails**, each one stopping between
1.6 km and 6.3 km short of its target, and **every failure lands within a few
metres of the same spot** — x∈[0,16], y∈[-8,-2], z∈[1314,1326], the South
Bridge carve corridor's own centre:

| segment | asked to reach | stopped at | short by |
|---|---|---|---|
| S06 | Old Quarry (403,1794) | (13,-3,1314) | 618.2 m |
| S07 | river/relay (150,3500) | (8,-3,1318) | 2186.2 m |
| S08 | ironwood grove (-345,5060) | (15,-4,1324) | 3753.0 m |
| S09 | outer watch (64,7400) | (2,-3,1321) | 6079.4 m |
| S10 | Hall (0,7560) | (8,-3,1318) | 6241.6 m |

**Read S06 through S09's FAIL counts (21, 22, 22, 12 respectively) as this one
stranding, counted once per assertion that depends on the player's location or
on a flag gated behind reaching the next region — not as 77 independent
findings about bands 2 through 5's own content.** Every band-3/4/5 objective
flag (`relay_captain_defeated`, `captive_rescued`, `relay_disabled`,
`mill_crossing_restored`, all three `defeated_captain_*` flags,
`hall_approach_open`) is unset as a direct, mechanical consequence of the
player never arriving.

**What this means for the run's coverage:** five consecutive segments (S05's
tail through S09) plus the first fifth of S10 have produced almost no new
information about bands 2 through 5's actual content — encounter design,
regional identity, pacing, difficulty curve — because the player is not
reaching any of it. This is the dominant fact this run has to report about
Track 2 for bands 2-5, and it is worth stating plainly: **this run cannot
speak to whether Stone & Root, River & Relay, Upper Meadows, or the Stronghold
approach are fun, fair, or well-paced, because the player was not there.**

**RESOLVED since this document's first rewrite: this is a RIG defect, not a
GAME defect, confirmed live in the engine.** Credit for this diagnosis
belongs entirely to the concurrent T2-STRANDING lane
(`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md`,
`origin/ralph/T2-STRANDING@08506512`); `ralph/GATE_F_RUN_3_RIG_FINDINGS.md`'s
RIG-21 has the full mechanism. In one line: **S03's own catch loop fainted
the player's only creature on a fair, non-buggy roll, and no step-script
from S03 onward ever assigns it to one of the three creature beds S03 itself
builds before sleeping — so the heal that would have fixed everything never
happens.** A fainted-only party cannot be summoned into the world, every
gate/trainer fight downstream correctly refuses to start without a usable
creature, the South Bridge gate is a real and correctly-locked physical
barrier that only opens on beating its guard, and every `move_to` past that
point is asking the harness to walk through a permanently shut gate — which
is what drives it into the carve edges and the recovery-volume loop above.
**A real player is never stuck here**: creature beds are an always-available
recovery path and human movement is never gated on creature state (hard
rule). The actual player-facing gap is narrower and is recorded as GAME-5
below. The fix (a rig step-script change only, `tools/gate_f/segments/
S03.json`) is pushed but **not yet validated end to end** — a separate,
pre-existing defect in the tutorial's own build-placement steps (not
introduced by this fix) still prevents an automated run from ever completing
a creature bed, so a healthy S03 exit save does not exist yet. **S05 through
S10's evidence in this run describes this one root cause, not bands 2-5's
own content, and does not become valid retroactively** — a real re-run from
a healthy S03 onward is still needed.

---

## GAME-0 — a fainted-only party's "is out of the fight" interaction offer permanently outranks every other interaction in the world

**FIXED 2026-08-30, `ralph/T2-GATEF-RUN4`, commit `7490fc18`.**
`encounter_director.gd::interaction_offer()`'s fainted-ally statement now
carries ordinary priority (0, matching `interactable.gd`'s own default) and
a distance past any real interact radius (9999.0, was 0.0) instead of
priority 100 / distance 0.0. It still wins — and still tells the player why
nothing else is responding — when it is the only offer on the table, but
now loses the arbiter's tie-break to any real, closer offer (a trainer
prompt, a village greeting, a harvest node, a creature bed) instead of
substituting for one. Live-confirmed both ways in
`tests/smoke_trainer_no_usable_ally.gd`: a fainted, deployed ally at a
never-fought trainer now opens the honest `trainer_no_usable_creature`
line (see T1 below) instead of getting no response at all, and does not
block gathering or building either — confirmed directly in a real S03
segment replay (`ralph/reports/gate-f-run4-s03-validation-2/`), where six
real `gather` events fire normally with Moss permanently fainted from
`t=438` onward. **This does not, by itself, produce a healthy S03 exit
save** — see GAME-8/GAME-9 below for what still blocks that.

**Original finding, kept for history:**

**Severity: SHIP, possibly higher.** Credit: found by the T2-BUILDPLACE lane
(`origin/ralph/T2-BUILDPLACE@cb3e8b56`) while validating the S03
build-placement fix above, not by this operator. Recorded here at the top of
this document because it is, on its face, more severe than the stranding
itself: it is a real, live-engine-confirmed defect in
`scripts/combat/encounter_director.gd::interaction_offer()`, not a rig
step-script gap.

**The mechanism:** whenever the player's tracked ally has fainted,
`interaction_offer()` unconditionally returns a priority-100, distance-0
statement (`"<ally> is out of the fight."`) with **no proximity gate** —
checked before the function's own `_engageable()` distance logic runs at
all. `prompt_arbiter.gd` ranks by priority before distance, always, so this
one line **outranks every other interaction in the world**: every NPC
greeting, every harvest node, every creature bed's own rest prompt — for the
rest of the live session. It does not clear on its own; only a fresh
save/load resets the tracked ally reference (per RIG-13/RIG-21's own
finding elsewhere in this run).

**Player-facing consequence, stated plainly: a real player whose only
creature faints during the opening catch attempts — an ordinary, expected
outcome of catching a wild creature, not a rare edge case — becomes unable
to interact with anything in the world afterward, with no in-game hint that
a reload is the fix.** They cannot reach the creature beds that would heal
their party (GAME-5, above), cannot talk to any NPC, cannot gather, cannot
open a door. The only way out is knowledge external to the game: quit and
reload. This is a stronger claim than GAME-5's "confusing, not a soft-lock"
— GAME-5 was about one specific trainer's dialogue; this is about *every*
interaction surface in the game simultaneously, discovered because it is
the exact state this run's own fainted-Moss saves have been in since S03.

**Not fixed, and correctly not fixed by either lane that found pieces of
it**: `scripts/combat/encounter_director.gd` belongs to neither
T2-STRANDING nor T2-BUILDPLACE's file ownership (a concurrent T3-TYPECHART
lane is actively editing it), so both lanes named it loudly rather than
touching it. **This operator did not verify it independently** — it is
relayed here from T2-BUILDPLACE's own commit message, which states it was
confirmed via a real segment replay (Mira's `interact_with` FAILing on
exactly this prompt) rather than inferred. Whoever owns
`scripts/combat/encounter_director.gd` next should treat this as the
highest-priority item in this document.

**Independently re-derived, not just repeated, by T2-STRANDING and
T2-BUILDPLACE separately** (`ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md`,
`ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md`, `origin/ralph/
T2-BUILDPLACE`): T2-BUILDPLACE hit this defect independently while proving
out its own, unrelated fix (Mira's dialogue in S03), traced it to the same
line (`interaction_offer()`), and its own handover states its severity
assessment even more strongly than this document originally did — "a
genuine soft-lock risk in the opening tutorial," and explicitly *more
severe than the South Bridge stranding it superficially resembles*, because
the stranding had a documented recovery path (creature beds) while this
defect blocks reaching that recovery path too, with nothing reachable
through ordinary play once it triggers. Two lanes finding the identical
mechanism from two different starting investigations is real corroboration,
not restated hearsay — treat GAME-0 as confirmed, not merely alleged.

---

## What this run DOES establish about the game, positively

### GAME-OK-1 — the front door is sound

S01, 13 of 13 steps PASS, on a fresh `user://`: process start to title
interactive in 500 ms; the title screen owns input and a real Control holds
focus (a stick moves something); no save present, Start New Game enters the
world directly with no overwrite confirmation; a new game starts with zero
creatures, as the five-creature rule requires; the quest log tracks the first
main-chain rung correctly.

### GAME-OK-2 — the opening's first encounter works, confirmed by a dedicated probe, independent of the harness's own S02 script

S02's own step script never gets a fight to start (see the companion RIG
document — this is a harness gap, `press interact` blind rather than a
resolved engage). But `DIAG-S02-ENCOUNTER/FINDING.md`, driving the same
production path with a purpose-built probe, confirmed the encounter mechanism
itself works end to end: the bed, the loft crossing, Grandpa's briefing
advanced by predicate, the starter picker (the five-creature rule's first
bite — the other two stay with Grandpa), the naming pad walked cell by cell,
and then, at the exact coordinates S02 pressed at, one `interact`:

```
director.interaction_offer = {"actionable":true,"distance":5.990,
                              "label":"Engage Bramblebun","priority":0}
pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

Confirmed on 30 of 30 samples across 30 play-seconds at a steady 5.99 m
against a 6.00 m reach. **The chapter's opening is not a dead end.**

### GAME-OK-3 — the interaction arbiter behaves correctly under modals

While a conversation owns input, the arbiter reports no winning provider and
an empty prompt, and `interact` does nothing — even with an actionable offer
standing 1.71 m away. Correct, deliberate behavior (`interaction_arbiter.gd`).

### GAME-OK-4 — S03 produced real, if unlucky, combat

With the rig fixed to walk to a live individual and press only a real engage
prompt (see companion doc, RIG-16/17), S03 fought three real
engage/combat/throw cycles. All three throws missed the catch — ordinary
variance at whatever this species/orb combination's real chance is, not by
itself a finding about the odds (protocol §0.6) — but the fights themselves
ran, resolved, and the world state (HP, fainting, re-engage refusal against a
stale prompt) all behaved as designed.

---

## Findings

### GAME-1 — opening the pause shell on a controller can fire the destructive backpack-drop verb

**Severity: SHIP candidate.** Player-facing, on the first pause menu of the
chapter, on the primary input device. `project.godot` binds both
`game_menu` and `backpack_drop` to joypad button 6 (Start/Menu). The pause
shell opens on the Satchel tab, so the press that opens the shell also lands
on the backpack tab's destructive drop verb if focus happens to be sitting on
it. Observed in S02: `game_menu opened the shell: context world ->
menu_backpack, focus on 'Drop it'`. `tab_backpack.gd` carries a guard
(`_ignore_drop_until_release`) for exactly this symptom; the operator's own
notes record it not holding on at least one attempt. Independent of the
stranding and of any rig gap — this is a controller-first project (hard rule)
and Start is the controller's most-pressed button.

### GAME-2 — after a load, nothing is deployed, and only a low-priority interaction line says so

**Severity: recorded as an OBSERVATION for Phase B, not asserted as a
defect** — whether this needs a change is a design call this run does not
make. Loading a save restores the party but deploys no creature body;
`_sync_active_creature()` declines to summon when nothing is out. The only
on-screen indication is a non-actionable interaction line (`Call out Moss`),
which only appears when nothing else is offering anything nearby and is
restated nowhere else (quest log, HUD, party screen). Whether a real player
would notice this at all is unmeasured here — no pixels were captured.

### GAME-3 — the build catalogue's d-pad focus navigation repeatedly fails to move onto the next piece cell

**Severity: SHIP candidate.** Measured in X02 (seeded from `S03-exit`, before
the stranding — this is not a stranding artefact). Across at least seven
distinct build-catalogue cells in a single session, a `ui_right`/`ui_down`
press reported "did not move focus off" the currently-focused button:

```
X02-036  focus the floor piece    — FAIL: ui_right did not move focus off @Button@62324
X02-049  focus the wall piece (1) — FAIL: 2x ui_right did not move focus off @Button@65678
X02-054  focus the wall piece (2) — FAIL: 2x ui_right did not move focus off @Button@66152
X02-059  focus the wall piece (3) — FAIL: 2x ui_right did not move focus off @Button@66626
X02-064  focus the doorway piece  — FAIL: 3x ui_right did not move focus off @Button@67109
X02-069  focus the roof piece     — FAIL: 4x ui_right did not move focus off @Button@67655
X02-082  focus the camp           — FAIL: 5x ui_right did not move focus off @Button@69395
X02-087  focus the creature bed   — FAIL: 6x ui_right did not move focus off @Button@70067
```

Each failure still allowed the piece to be armed and placed afterward (the
`arm the * ghost` steps immediately following all PASS), so this reads as a
**focus-reporting/navigation defect rather than a hard block** — the game
still let the operator proceed, but the on-screen focus indicator a real
player relies on to know what they are about to place did not visibly move
when the input said it should. §8's own standard (a poll-only reader that
reports a working menu while the stick moves nothing) is exactly the defect
class this matches. Worth a real player test: does the highlighted piece
actually change, or does only the *placed* piece change while the highlight
stays put?

### GAME-4 — the craft panel's `input_context` never leaves `world`, even while it appears to function

**Severity: recorded as an ambiguity, not asserted as a defect** — the
underlying mechanism (does crafting actually require exclusive input
ownership, or is this by design) is not decidable from this run's telemetry
alone. In X02, interacting with the workbench (`X02-015`) is immediately
followed by an assert that the craft panel owns input, which FAILs:
`input_context=world (wanted prefix panel)`. The subsequent focus-move steps
also FAIL (`did not move focus off nothing`) — consistent with no panel
Control ever holding focus. Yet the very next step, an unconditional
`ui_accept` press, is followed by a `PASS` on "the axe costs 4 wood/3 stone/2
fiber and the satchel pays it," and the same pattern repeats for the pickaxe.
**Two readings are both consistent with this telemetry and this run cannot
distinguish them:** (a) the craft panel genuinely opened and crafted
correctly, but `input_context`'s accessor does not recognize it as a panel
owner (an instrumentation gap, RIG-8's shape, not a player-facing defect); or
(b) the panel never actually opened and the `ui_accept` press did something
else that happened to also pay for and grant the axe. Not chased further this
pass — flagged for whoever next has capture-lane or live-probe access to the
craft panel's actual `Control.has_focus()` state at this exact moment.

### GAME-5 — a player whose only creature faints gets no explanation and a trainer falsely claims a win that never happened

**The trainer-dialogue half FIXED 2026-08-30, `ralph/T2-GATEF-RUN4`, commit
`7490fc18`** (dark-features inventory item T1). Exactly the candidate shape
described at the end of this entry: `encounter_director.gd::no_usable_ally()`
is a new sibling query beside `can_challenge()` (which keeps its existing
bare-bool contract, all 8+ call sites untouched), consumed by one new
branch in `trainer_npc.gd::_on_challenged()` that opens a single generic
conversation (`trainer_no_usable_creature`, `data/dialogue/trainers.json`)
instead of the false `defeated` line — one line, shared by all ~27
trainers, not per-trainer data. Live-confirmed both directions in
`tests/smoke_trainer_no_usable_ally.gd`: a fainted ally gets the honest
line and no fight starts; healing the same ally reopens the ordinary
challenge conversation on the same trainer, same session. **Still open:**
`encounter_director.gd`'s creature-control offer still shows no prompt at
all when the only creature is fainted — not touched by this fix, a smaller
remaining gap.

**Original finding, kept for history:**

**Severity: SHIP candidate.** Found by the T2-STRANDING lane while
diagnosing the South Bridge stranding's root cause (RIG-21, companion doc),
recorded here because it is a genuine player-facing gap independent of the
stranding itself. `autoload/party.gd::all_fainted()` exists and has zero
callers anywhere in the codebase — nothing auto-heals, blacks out, or
otherwise intervenes when a player's only usable creature faints.
`trainer_npc.gd::_on_challenged()` cannot distinguish "no usable creature"
from "already beaten" and shows the same `defeated` conversation line for
both, so a trainer a player has never fought will claim a win that never
happened. Separately, `encounter_director.gd`'s creature-control offer shows
no prompt at all — not even an explanatory one — when the only creature is
fainted. **Not a soft-lock**: creature beds (built during the S03 tutorial
before the player ever leaves for the first fight) are always available and
human movement is never gated on creature state, so a player can always
backtrack and heal. But the game gives no indication this is what's needed
— a player without genre knowledge could sit confused at a locked gate for
a while, misled by dialogue that claims a fight already happened. Recorded
here as a candidate fix scope, not implemented by this run: the smallest
safe shape (per T2-STRANDING's own assessment) is a new query beside
`can_challenge()` (e.g. `no_usable_ally()`) consumed by one new branch in
`_on_challenged()`, since `can_challenge()`'s existing boolean contract has
8+ call sites depending on it as a bare bool.

### GAME-6 — `menu_cancel` (B) does not close the pause shell from the Backpack or Creatures tabs

**Severity: SHIP candidate.** Found in X01's controller/menu exhaustion
matrix, and it is not a one-off: **10 separate matrix cells** all reproduce
the identical shape — `FAIL menu_cancel left the shell open: context
menu_backpack -> menu_backpack` (7 times, `X01-056/059/064/067/078/084/101`)
and `context menu_creatures -> menu_creatures` (3 times,
`X01-1539/1569/1647` by line, matrix cells on that tab). **Confirmed as
tab-specific, not universal**: the identical probe on the Map tab
(`X01-350`) correctly reports `menu_cancel closed the shell: context
menu_map -> world`. B/`menu_cancel` is the controller's back button and the
standard way to leave any menu — a player on the Satchel or Creatures tab
(two of the most-visited tabs in the game) pressing the expected button to
back out finds it does nothing, repeatably, regardless of which control was
pressed immediately before it in the matrix. Independent of the stranding,
independent of RIG-14's tab-cycle-count issue (this is about a press that
should close the shell entirely, not about landing on the wrong tab).

### GAME-8 — RESOLVED (T2-GATEF-RUN5): the exit leg was pointed at a target behind a wall, and the room is not a player trap

> **T2-GATEF-RUN5, 2026-08-30.** Fixed, and the original diagnosis below is
> kept because it is right about the symptom and wrong about the cause in a
> way worth not repeating.
>
> **Cause.** `S03-59a` already asked for the right point (cottage_a's door
> staging point, building-local (1.0, 4.0)) but its `close_enough` was 2.0 m
> and the doorway is 1.9 m away, so the leg returned true standing INSIDE
> the shop at local (0.78, 2.15). `S03-60` then aimed at Oskar, who is at
> building-local **(-5.66, 0)** — due west, through the wall the crates are
> stacked against, 180 degrees from the door. Every waypoint tried across
> four sessions reproduced the same wedge because none of them changed that
> fact. Fixed by tightening `close_enough` to 0.8 (budget 400 -> 1500) so
> the leg cannot end until the body is outside the building.
>
> **`stick_navigator.gd` fixed too, and it needed it.** Its clearance probe
> was one hairline ray at hip height: blind to the crates (tops 0.50 m and
> 0.945 m), grazing the counter (top 1.00 m), and blind to width, so the
> 0.14 m wall/crate gap read as open corridor. Measured live at the wedge
> point it reported 1.50 m where the body has 0.25 m. It now sweeps the
> body's own volume (nine rays, three heights by three lateral offsets,
> lowest above `STEP_HEIGHT` so a kerb is not a wall), refuses a side
> narrower than the body, backs out of a pocket, and drops a detour that
> has stopped moving the body.
>
> **The open question in this entry is answered: NO, a real player cannot
> get stuck there.** From four starts inside the pocket, holding the stick
> at the door with no detour logic, all four escape to the door lane
> (`tools/gate_f/probe_shop_exit_clearance.gd`, question 3). A 0.14 m gap
> does not admit a 0.8 m-wide body. `shop_interior.gd` is unchanged and
> needs no change.
>
> **Evidence.** `tools/gate_f/probe_shop_exit_clearance.gd`: from behind
> Mira's counter, out to the staging point ARRIVES in 38 walking frames and
> Oskar ARRIVES in 79 more, against a 3000-frame budget exhaustion for the
> direct line.

#### Original entry (T2-GATEF-RUN4), kept for the record

**Severity: RIG for the harness's own walk, but the underlying geometry is
a real GAME-side authoring question.** Found by `ralph/T2-GATEF-RUN4`
chasing why a real S03 replay (with T2-BUILDPLACE round 3's door + revive
fix, and this session's own GAME-0/T1 fixes, all in place) still ends with
a permanently fainted party. `S03-60` ("walk past Oskar on the way back",
`tools/gate_f/segments/S03.json`) fails identically to BUILDPLACE round
3's own record — stuck ~4.3m short at world (18.76,-3.18) — **even after**
a new staging step (`S03-59a`, this session) routes the walk through the
same door-approach point `S03-52` already uses reliably on the way in.

Live-engine diagnosis (`tools/gate_f/probe_oskar_walk_trace.gd`,
`tools/gate_f/probe_oskar_stuck_geometry.gd`, both new this session,
committed): the stuck point is local `(-1.37, 0.3..2.37)` in `cottage_a`'s
own building space — pinned directly against the room's west wall
(`INNER_HALF_W=1.69`) and the two stock-crate shelf boxes
`shop_interior.gd::_build_counter()` places at local `(-1.3, 0.25/0.72,
1.5)`. A physics shape-query at every recorded stuck position hits
`cottage_a_3/Collision` (the exterior wall body) and one of
`cottage_a_3/Interior/@StaticBody3D@*` (the counter or a shelf) every
time. The counter itself (local x:[-1.6,0.9], z:[-0.6,-0.1]) sits directly
on the straight line between Mira's own stand-behind-the-counter position
(local `0,-1.4`) and the door (local x=1.0) — `tests/helpers/
stick_navigator.gd`'s generic wall-slide detour logic, written for open
outdoor obstacles, picks a side to slide around the counter and gets
wedged in the ~0.3-0.4m gap between the shelf boxes and the wall instead
of clearing it. **Every waypoint tried this session** (the raw target, the
same door-staging point used for entry, an explicit door-lane point at
local x=1.3 clear of the counter's own edge by 0.4m) reproduces the same
stuck point or a near-identical one — this is not a coordinate-tuning
problem the way the door was. One asymmetry worth noting for whoever picks
this up: the ENTRY leg (`S03-52c`, door to Mira) is live-confirmed clean
every time; only the EXIT leg (Mira back out past the counter) traps,
which points at the detour's side-choice heuristic behaving differently by
direction of travel rather than at the room being uniformly impassable.

**Not fixed this session.** A real fix is either: (a) give the navigator a
multi-point local route around known interior furniture (a per-room
waypoint table, which `stick_navigator.gd`'s own header explicitly says it
was built to avoid needing), or (b) revisit `shop_interior.gd`'s counter/
shelf placement so a straight line from behind the counter to the door
does not have to clip it at all (the counter comment already claims this
is true for the ENTRY direction — "left of the door lane, so walking in
never walks into it" — but the exit case was never checked). Recorded here
rather than attempted blind, per this session's own budget.

### GAME-9 — RESOLVED (T2-GATEF-RUN5): the tool bindings were addressed by press count, and `ui_left` does not wrap a grid row

> **T2-GATEF-RUN5, 2026-08-30.** Root-caused, reproduced exactly, fixed.
>
> The isolated probe and the segment were never running the same recipe.
> `probe_tool_equip_sequence.gd` looks the item's slot up
> (`inventory.find_slot`) and drives the cursor there; `S03.json` pressed
> `ui_right` four times, counting cells along a FRESH save's fill order. Two
> things break that count, and the second is decisive: the bag is not fresh
> (both Revives spent, potions 3 -> 1, before a tool is bound), and
> **`ui_left` does not wrap up a grid row**, so from the knife's cell the
> three left presses walked backwards along row 0 instead of reaching the
> pickaxe on row 1 of a 6-column grid. `S03-56f`'s own note asserted that
> wrap; it does not happen.
>
> `tools/gate_f/probe_tool_equip_depleted_bag.gd` rebuilds run 4's own
> depleted bag and runs both schemes against it. The shipped counts leave
> the hotbar `["", "", "potion_small", "knife", ""]` — **precisely the
> `{hotbar_slot: 3, item: "knife"}` all six gathers reported.** The
> slot-addressed scheme on the same bag leaves `["", "axe", "pickaxe",
> "knife", ""]`.
>
> Fix: new harness action `focus_item` (`operator_harness.gd`,
> `tools/gate_f/SEGMENT_SCHEMA.md`) backed by `gate_f_probe.gd::
> satchel_slot_of()`/`satchel_focus()`/`satchel_columns()`. Same real `ui_*`
> events; it reads the cursor between them and navigates column-then-row.
> `S03-56d/f/h` name the item now. An unreachable cell or an absent item
> FAILs loudly instead of binding the wrong thing in silence.

#### Original entry (T2-GATEF-RUN4), kept for the record

**Severity: SHIP candidate, unconfirmed root cause.** Also found chasing
the same S03 replay above. Six real `gather` events fire in
`ralph/reports/gate-f-run4-s03-validation-2/S03/telemetry/events.jsonl`
(GAME-0's fix means gathering is no longer blocked by the fainted-ally
lockout at all — a genuine positive result) but `home_materials_gathered`
never sets. Every one of those six events' own `equipped` field reads
`{hotbar_slot: 3, item: "knife"}` — **the same tool, the same slot, for
every single gather attempt**, despite `S03.json`'s own gathering loop
(`S03-67-equip`, `S03-71-equip`, `S03-73-equip`, ...) pressing `hotbar_2`/
`hotbar_3`/`hotbar_4` in rotation between nodes to switch tools for wood/
stone/fiber in turn, and despite the tool-assign sequence
(`S03-56c`..`S03-56i`) binding axe->slot 2, pickaxe->slot 3, knife->slot 4
by the same shape `tools/gate_f/probe_tool_equip_sequence.gd` already
proved PASS **in isolation from a fresh `S02-exit.json`**. Something about
running that same sequence after ~450 seconds of real prior segment state
(two real fights, two revives, a third unhealed faint, the Mira-door
detour) leaves slot 3 bound to knife rather than pickaxe, or leaves the
`hotbar_X` presses not actually switching the live equipped item — this
session did not distinguish which. **Not fixed, not root-caused past this
point** — the isolated probe's own PASS means whoever chases this next
should look at what state persists across a full replay that a
fresh-load probe never carries, the same lesson GAME-8 and the earlier
BUILDPLACE rounds each independently relearned this run.

### GAME-10 — Oskar's creature-swap panel is opened by his greeting and never closed (FIXED in the segment, T2-GATEF-RUN5)

**Severity: RIG (segment authoring), fixed. Recorded because of what it
hid, not because it was hard.** Found by `ralph/T2-GATEF-RUN5` the moment
GAME-8's fix let `S03-60` reach Oskar for the first time in five sessions.

Oskar's greeting ends with `shop:creatures:oskar`
(`data/dialogue/village.json`), which
`sequence_director.gd::_maybe_open_shop()` opens as a **SwapPanel** the
instant his dialogue box closes — exactly the way Mira's greeting opens her
goods shop. Mira's is closed by `S03-56` and the world re-asserted by
`S03-56a`. **Oskar's branch had neither step.**

The run's telemetry pins `input_context` at `panel:SwapPanel` from
`S03-62` to the end of the segment, and every downstream symptom is that
one fact wearing a different hat:

- every `hotbar_N` press was swallowed by
  `playground_hud.gd::_world_input_allowed()`, so `equipped` read
  `{hotbar_slot: -1, item: ""}` through the entire gathering loop **even
  though the exit save shows the bar correctly bound** to
  `["", "axe", "pickaxe", "knife", ""]`. GAME-9's fix had landed and the
  tools still could not be drawn — a reader looking only at `equipped`
  would have concluded GAME-9 was not fixed;
- every walk reported **`0 held` while never leaving `(19,-6)`**, because a
  panel owning input is not the same thing as locomotion being disabled and
  `stick_navigator.gd::can_walk()` cannot tell the difference. That is worth
  noting on its own: **"0 held" does not mean "the body was free to move."**
- 71 of 393 steps FAILed, all of them here.

**Fix:** `S03-62a` (`menu_cancel`) and `S03-62b`
(`assert input_context == "world"`), mirroring Mira's own pair. The assert
is the half that matters for next time: without it a single stuck panel
reports as seventy-one unrelated-looking failures. **71 FAIL -> 48 FAIL,
315 PASS -> 340 PASS**, with real materials gathered and one building
placed for the first time.

**The general lesson, third instance this run:** a segment step that opens
a pausing panel needs a matching close AND a context assert. Mira's branch
has both; Oskar's had neither; nobody could see it while GAME-8 meant his
dialogue never ran. Any other `shop:` / `battle:` effect reached for the
first time by a future fix should be audited for the same pair before the
replay is trusted.
### GAME-11 — the chapter's first fight is one the starter can lose, and the practice creature is not a tutorial creature (OPEN, T2-GATEF-RUN6)

**Severity: BLOCKER candidate. Found by fixing the rig defects that had been
hiding it for six runs.** Once S02 could actually stage its fight (RIG-26),
the fight itself became observable for the first time, and it is not the
forgiving tutorial the opening documents describe.

`docs/OPENING_SEQUENCE.md` beats 6-8 are the chapter's first piloted fight
and first catch, and `data/config/opening.json` is explicit about the
intent: the species is chosen because it has *"the highest catch_rate in
species.json (0.60), chosen for the opening's forgiving first catch"*, and
`max_catch_failures: 1` exists so that *"the tutorial catch cannot fail
twice."* `data/config/progression.json`'s own tuning comment states the
enemy levels the chapter fields as running **"2 at the practice fight"** up
to 22 in the stronghold gauntlet.

**None of that is what the opening actually stages.** There is no dedicated,
level-pinned practice creature. `encounter_director.gd::wild_creature()` is
`_wild_of_species(_role_species("practice"))` — it returns whichever member
of the world's ordinary seeded bramblebun population happens to be nearest.
`tools/gate_f/diag/probe_s02_encounter.gd` resolved that name against **64
live bramblebuns**, and `data/config/bands/band1_lower_meadows/spawns.json`
pins no level on any of the fourteen bramblebun clusters, so each one takes
the band's ordinary level roll.

Measured across four RUN6 runs of S02 on this candidate:

| | |
|---|---|
| starter (`starter_level` 3) | 117.6 HP |
| practice bramblebun, roll A | 104.3 HP |
| practice bramblebun, roll B | **124.2 HP**, recorded **level 5** in the exit save |
| design intent, per `progression.json` | **level 2** |

**The starter loses, and it is not an unlucky roll.** Across **five** RUN6
runs of S02 on this candidate, with the rig defects fixed and the fight
staging every time:

| | |
|---|---|
| runs where the fight staged | **5 of 5** |
| runs where the starter FAINTED | **4 of 5** |
| runs where the catch landed | **1 of 5** |

The one success threw at 80% opponent HP and got a favourable roll; it did
not survive the fight so much as end it early. The fourth run is the clean
losing case, with the full attack script (a charged attack plus three quick
attacks) spent:

```
t=219.25  combat_start   my_hp=117.6   opponent_hp=104.3
t=266.35  faint          my_hp=0.0     opponent_hp=76.1
t=267.97  combat_end
```

and the fifth run shows the same shape with a throw in it, thrown far too
late because the script is still trading blows while the starter is dying:

```
t=219.27  combat_start   my_hp=117.6   opponent_hp=104.3
t=254.22  catch_throw    my_hp=26.6    opponent_hp=65.2    <- throw fails
t=269.72  faint          my_hp=0.0     opponent_hp=65.2
```

Forty-seven seconds in the fourth run, no `catch_throw` at all, and the
player's creature died having removed 28 of the opponent's 104 HP — most of the scripted
attacks missed a target that moves (`player_quick.range` 2.6 m,
`cone_degrees` 100). A level-3 creature with 117 HP is being asked to beat a
level-5 creature with 124 HP, in the fight the game uses to teach combat,
before the player has any second creature, any potion beyond one, or any
way to retreat.

This also explains why the first catch is a coin toss even with the rig
fixed: the throw has to happen while the fight is still alive, and the
fight is frequently not alive long enough. Of four RUN6 runs, the catch
landed once.

**What this is not.** It is not the catch odds — those are T5-FEEL's
OP-0830-5 and were separately diagnosed and fixed at the accuracy scale on
`ralph/T5-FEEL`. It is not the rig: RIG-26 and RIG-27 below are fixed, and
the fight now stages, is piloted, deals damage and emits its full event
trail.

**Two candidate fixes, and the choice is a design one, not a coding one.**
Either the opening spawns its own practice creature at a pinned low level
(the `level` key `spawn_wild()`'s own `opts` already supports, which would
make `progression.json`'s "2 at the practice fight" true), or the band roll
near the opening meadow is floored so the first thing a player meets cannot
outclass the starter. The first is narrower and matches the documented
intent; it is what I would recommend, but it is the owner's call and I have
not made it.

### GAME-12 — after a failed catch the aim re-opens and the throw never fires (OPEN, T2-GATEF-RUN6)

**Severity: HIGH candidate. Newly observable, for the same reason GAME-11
is.** `combat_manager.gd:1273` applies `catch_math.apply_failure_bound()`
whenever `_tutorial_catch_failure_bound >= 0`, so with
`max_catch_failures: 1` the **second landed throw is forced to succeed**.
That guarantee is the opening's stated promise that "the tutorial catch
cannot fail twice."

**It is currently unreachable, because there is no second landed throw.**
RUN6 added three retry blocks to S02 (re-aim, throw, wait). The telemetry
shows every one of them re-entering the aim and none of them throwing:

```
t=227.22  ctx=combat_aim   pressed interact x2      <- aim entered
t=227.32  ctx=combat       pressed interact x1
t=227.70  catch_throw                               <- throw 1 fires
t=230.08  catch_result                              <- throw 1 fails

t=233.67  ctx=combat_aim   pressed interact x2      <- aim entered again
t=233.75  ctx=combat       pressed interact x1
          (no catch_throw)
t=240.08  ctx=combat_aim   pressed interact x2      <- and again
t=240.17  ctx=combat       pressed interact x1
          (no catch_throw)
t=246.50  ctx=combat_aim   pressed interact x2      <- and again
t=246.58  ctx=combat       pressed interact x1
          (no catch_throw)
```

Three re-aims, zero throws, reproduced across two runs. The party had 13+
orbs, so `throw_aim.gd::try_begin_aim()`'s "no orbs left" refusal is not
it. **Not root-caused this session** — I did not get a focused probe onto
it, and I am not going to guess between "the aim is entered and cancelled
by the second tap of the same press", "a post-resolution lockout the retry
lands inside", and "the throw is refused for a reason nothing surfaces."
Each is testable in one live probe of the shape
`probe_s02_encounter.gd` already uses.

**Why it matters beyond the rig:** if a real player's first throw fails —
which at these HP levels is the common case, see GAME-11 — this is the
mechanism that is supposed to catch them. A player who cannot land a second
throw, in the beat that gates the road gate, with fifteen orbs and no
resupply before the gate, is stranded exactly the way
`sequence_director.gd:1128-1134`'s own comment worries about for the miss
case.


---

## Per-segment summary

| segment | steps | PASS | FAIL | DELEGATED | what dominates the FAILs |
|---|---:|---:|---:|---:|---|
| S01 | 14 | 13 | 0 | 1 | clean |
| S02 | 75 | 61 | 6 | 8 | first-catch engagement never fires from S02's own blind press (see companion doc); road-gate flag consequently unset |
| S03 | 338 | 284 | 47 | 7 | RIG-13/14/15/16/17/18 history (see companion doc); real combat achieved, team stayed at 1 |
| S04 | 73 | 53 | 14 | 6 | tournament ungated by team-of-1 (RIG-18); zero combat_start |
| S05 | 77 | 58 | 6 | 13 | South Bridge gate never opens (open question, see companion doc) |
| S06 | 104 | 72 | 21 | 11 | South Bridge stranding (RIG-13) |
| S07 | 99 | 68 | 22 | 9 | South Bridge stranding |
| S08 | 135 | 102 | 22 | 11 | South Bridge stranding |
| S09 | 76 | 56 | 12 | 8 | South Bridge stranding |
| S10 | 27/121 (BLOCKED) | 19 | 6 | 2 | stranding through step 22; genuine cost-gate BLOCKER at step 27 |
| X02 | 170 | 146 | 20 | 4 | build-catalogue focus defect (GAME-3), craft-panel context ambiguity (GAME-4), RIG-14 tab-cycle shape (see companion doc) |
| X04 | 124 | 104 | 12 | 8 | **zero combat_start events, entry saves compromised** — all three of X04's entry saves carry a permanently fainted party (RIG-21) and its own move_to steps separately undershoot every combat site regardless (RIG-19); see `X04/CONTAMINATED_ENTRY_SAVES.md` — none of its combat/faint/switching assertions are readable as findings |
| X05 | 313 (STOPPED at ~250, 10/16 seed blocks) | n/a — no INVENTORY.json | n/a | n/a | 8 real `S0n-exit` blocks + 2 extra slot saves completed and are readable; every one of those 8 blocks' own "verify save actually writes" check FAILs on the same RIG-14-shaped tab-navigation miss (RIG-22) — no confirmed evidence the Save tab writes a file anywhere in this run; operator stopped the segment once its remaining 6 blocks (missing `S10-exit` + 5 missing `X06-awkward-*` saves) had reproduced RIG-4's known pattern 4 times in a row — see `X05/INCOMPLETE.md` |
| X01 | 1203 | 1092 | 103 | 8 | `menu_cancel` fails to close the shell on Backpack/Creatures tabs, 10 cells (GAME-6); locomotion held 3601 frames by a narrative modal twice (RIG-5's already-documented shape recurring); only 4-5 of 103 FAILs mention combat, consistent with T2-STRANDING's read that X01 is low-exposure despite its S03-exit/S08-exit entries also being fainted-party saves |

`HANDOFF_PROVENANCE.md` in the run directory records which entry save each
segment actually had — not in every case the one §B names (RIG-10/RIG-12).

---

## S10's BLOCKER is a real capacity limit, not a pricing bug

S10 ran 27 of 121 steps (19 PASS, 6 FAIL, 2 DELEGATED) before the harness's
own cost gate refused to continue: `0.097 s/frame`, measured immediately
after a real combat exchange (`combat_quick` x38, a party switch,
`combat_quick` x24), against `40195 s` (11.2 h) predicted for the remainder
versus `13974 s` of budget left. Unlike CD-7c (RIG-2, a genuine
divide-by-a-handful-of-frames pricing artifact, already fixed), this price
jump tracks real combat-dense content (the gauntlet, elites, the Warden, the
legendary choice) and is not a rig bug to patch. No `S10-exit` save exists.
The practical fix is a faster host or splitting S10 into smaller segments
each under the 14400 s ceiling — not a shorter wait, which the protocol
itself says would just mean fights do not resolve.

---

## What this run still cannot conclude

1. **Nothing about bands 2 through 5's own content, pacing, or difficulty** —
   the player never arrived. **Root cause resolved as RIG, not GAME**
   (RIG-21, companion doc): S03's own catch loop fainted the player's only
   creature on a fair roll, and no step-script ever healed it before sleeping,
   so every trainer/gate fight downstream correctly refused to start. A real
   re-run from a healthy S03 is still needed; this run's S05-S10 evidence
   describes this one root cause, not bands 2-5.
2. **Nothing about combat at all, anywhere past S03.** Zero `combat_start`
   events in S04 through S10, and zero in X04 too — **X04's entry saves are
   all fainted-party saves** (RIG-21), so none of its combat assertions are
   readable regardless of its own separate `move_to` budget defect (RIG-19,
   companion doc) which would have undershot every combat site anyway. **This
   run has no combat evidence whatsoever past S03's three real (if all-missed)
   catch attempts.** Difficulty, fairness, camera behavior during a fight,
   faint/recovery, and switching under pressure remain completely
   unevidenced by this run.
3. **Nothing about how the game looks.** No pixels were captured; every
   prescribed §G frame is delegated and unpaid — see `GATE_F_CAPTURE_LANES.md`.
4. **Nothing about the chapter's finale, the Warden fight, or the legendary
   choice** — S10 BLOCKED at step 27/121, genuinely, on cost.
5. **Nothing about pacing or first-clear timing** past the opening — the
   journey's later segments were played in a world the player could not
   traverse.
6. **Nothing about device performance, audio, controller feel, or handheld
   legibility** — all `[OWNER-ONLY]` per §K, unchanged.

## What this run DOES conclude, positively, and should not be re-litigated

1. The front door (boot, title, new game, zero starting creatures) works.
2. The opening's core encounter mechanism works end to end, on the production
   path, independent of the harness's own scripting gap in S02.
3. The interaction arbiter correctly refuses input to the world while a modal
   owns it.
4. Real combat, once it is correctly triggered (S03, with the rig fixed),
   resolves correctly — HP tracking, fainting, re-engage refusal against a
   stale prompt all behaved as designed.
5. Two independent, player-facing UI defects exist regardless of the
   stranding or any rig gap: the Start-button drop-verb collision (GAME-1)
   and the build-catalogue focus-navigation gap (GAME-3).
