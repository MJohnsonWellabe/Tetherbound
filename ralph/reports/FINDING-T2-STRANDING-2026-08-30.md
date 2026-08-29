# FINDING — the South Bridge stranding is a RIG defect, not a GAME defect

**Verdict: RIG, confirmed live in the engine.** The world is behaving exactly
as designed at every point in this chain. The fix is in
`tools/gate_f/segments/S03.json` (pushed alongside this finding); full
mechanism and evidence below.

## Live-engine confirmation

`tools/gate_f/probe_stranding_cause.gd`, run against this run's own real
`S05-exit.json` (`godot --headless --path . --script
tools/gate_f/probe_stranding_cause.gd`), reproduces the exact block and its
exact cure:

```
load_slot(4) applied: true
party size after load: 1
active creature: Moss  fainted=true  hp=0.0/1.18
--- pressing creature_recall (RIG-13's S05-09a step: summon_active_creature()) ---
summon_active_creature() returned: false
can_challenge(south_bridge_grunt) BEFORE healing: false
--- healing the party's only creature the way a creature bed does (heal_fully()) ---
active creature after heal_fully(): fainted=false hp=1.18/1.18
summon_active_creature() after heal returned: true
can_challenge(south_bridge_grunt) AFTER healing: true
PROBE PASS
```

Nothing else changed between the two `can_challenge()` calls — not position,
not the gate, not any flag. Healing the party's one creature is the entire
difference between permanently blocked and immediately able to fight the
South Bridge grunt.

## The chain, each link verified against source and this run's own telemetry

1. **S03's own catch loop can faint the player's only creature on a real,
   non-buggy roll.** `gate-f-run-20260828T183531Z/S03/telemetry/events.jsonl`
   has a `faint` event at `t=256.0`, `type: combat_hit`: "Moss fainted",
   `hp: 0.0/1.18`. RIG-18 (`RESTARTS.md`) already found the *catching* odds
   were fair; it never checked the player's own creature's HP during the same
   fights. It was fainting.

2. **`encounter_director.gd::summon_active_creature()` (line 864) correctly
   refuses to deploy a fainted creature**: `if creature == null or
   bool(creature.get("fainted")) or bool(creature.get("resting")): return
   false`. This is the same action RIG-13's fix (`S0n-09a`, "press
   creature_recall after every load") presses after every segment boot. With
   the party's only creature fainted, it silently no-ops every time, forever.

3. **`can_challenge()` (line 1568) correctly refuses every trainer/gate fight
   without a deployed ally**: `if _ally == null or _ally.fainted or
   _ally_body == null or not is_instance_valid(_ally_body): return false`.
   Confirmed directly in this run's own S05 telemetry: the "Old Bram" fight
   at S05-34..38 shows only `dialogue` events, never `combat_start` — the
   step-script's button presses succeeded, but no fight ever staged, exactly
   like the South Bridge grunt three minutes later.

4. **`trainer_npc.gd::_on_challenged()` (lines 171-172) cannot distinguish
   "no usable creature" from "already beaten"** — it shows the trainer's
   `defeated` conversation whenever `can_challenge()` is false for ANY
   reason. This is why `RESTARTS.md` saw the South Bridge grunt open with
   his post-victory lines ("Take it, I'll tell them you had a key already")
   on a completely fresh approach: not a flag bug, just the one fallback
   branch a fainted-ally refusal and an already-won fight share. This is a
   minor, real, secondary UX defect worth a Track 3 ticket (a player in this
   state gets no explanation at all — `_creature_control_offer()` also
   returns an empty prompt rather than any text when the only creature is
   fainted) but it is not the stranding's cause.

5. **The South Bridge gate is a real, correctly-locked physical collision
   barrier** (`gated_crossing.gd`, `GateCollision` `StaticBody3D`,
   `_shape.disabled` only flips on `_unlock()`), and `south_bridge_key` is
   exclusively `south_bridge_grunt`'s combat reward
   (`data/config/bands/band1_lower_meadows/trainers.json:188`, confirmed by
   the 2026-08-22 owner directive comment at line 163). Since the fight can
   never start (step 2-3), the key is never obtained, and the gate never
   opens. This is the intended design, working correctly.

6. **Every `move_to` step from S05 onward that targets a point past the
   bridge is asking the harness to walk through a permanently, legitimately
   locked gate.** The straight-line primitive has no "this target is
   unreachable, stop" case; it keeps trying, and in trying appears to drift
   near the gully edges around the gate. `scripts/world/severed_spokes.gd`'s
   `_add_carve_failsafe()`/`_on_carve_failsafe_entered()` — a real,
   correctly-functioning system that returns a player who falls into a carve
   back to the road — fires every time this happens, which is the 600+
   `[severed_spokes] player went over the edge` lines per segment
   `handover-GATE-F-RUN-3-2026-08-29.md` already recorded. The failsafe is
   not malfunctioning; it is being triggered on a genuine loop the walker
   cannot break out of on its own.

## Why this is RIG and not GAME

Every system inspected — the fainted-ally combat gate, the trainer dialogue
fallback (modulo the minor UX gap noted above), the physical bridge lock, and
the carve recovery volume — is doing exactly what its own code and comments
say it should. **A real player is not stuck here**: S03 builds three creature
beds specifically for this ("R4.8... `heal_fully()` — GAME_DESIGN.md's own
phrase: 'revives a fainted creature'"), and `data/config/progression.json`'s
own `creature_bed` comment says sleeping through the night completes any
occupied bed's heal immediately. `tools/gate_f/segments/S03.json` builds
those three beds (`S03-176`..`S03-205`) and even sleeps at home afterward
(`S03-223`..`227`) — but never once assigns the fainted creature to a bed
first, so the sleep step heals nobody. That is the gap: an ordinary,
available recovery action the step-script never takes, not a broken world.

## The fix (pushed with this finding)

`tools/gate_f/segments/S03.json` gains five steps (`S03-205a`..`S03-205e`)
immediately after the three beds are confirmed built and before the existing
sleep sequence: walk to a bed (`move_to_entity` on `creature_bed.gd`),
interact, confirm the only row in the rest panel, close it. The segment's own
already-scripted sleep then completes the heal, so the S03 exit save carries
a healthy party into S04 onward — which should resolve the stranding for
every segment downstream, since nothing else in the chain needed to change.

## URGENT correction — the exposure boundary, and X04 is NOT immune

Two lanes and the coordinator have each stated a different boundary for
which entry saves are clean. Here is the one built directly on the event
log, checked exit save by exit save, this run's own files:

| Exit save | Party | Fainted? |
|---|---|---|
| `S02-exit.json` | Moss, hp 117.6 | **No — clean** |
| `S03-exit.json` | Moss, hp 0.0 | **Yes** |
| `S04-exit.json` | Moss, hp 0.0 | **Yes** |
| `S05-exit.json` | Moss, hp 0.0 | **Yes** |
| `S06-exit.json` | Moss, hp 0.0 | **Yes** |
| `S07-exit.json` | Moss, hp 0.0 | **Yes** |
| `S08-exit.json` | Moss, hp 0.0 | **Yes** |
| `S09-exit.json` | Moss, hp 0.0 | **Yes** |

**The boundary is exactly `S02-exit` / `S03-exit`, not S05 or S06.** Every
exit save from S03 onward carries the permanently fainted party.

**Consequence: X04 is not structurally immune, and should not be run against
its declared entry saves as currently seeded.** X04.json seeds from
`S04-exit.json` (`X04-007`), presses `creature_recall` (`X04-013a`, which
will silently fail exactly like every other segment — the ally is fainted),
then walks to `south_bridge_grunt` and asserts `input_context == combat`
(`X04-021`) — **the identical shape that FAILED in S05** (`S05-48`, this
run's own telemetry). Every later X04 case that depends on that fight
starting (CB-07 intentional loss, CB-08 faint-mid-fight, CB-09 switching
under pressure) is built on a fight that cannot start, for the same reason
S05-S09 could not. `S06-exit.json` and `S09-exit.json` (X04's other two entry
saves) are equally fainted (see the table above) — there is no clean X04
entry point anywhere in this run.

**X01 is also seeded from a contaminated save** (`S03-exit.json`,
`X01-006`) — I did not verify whether its own matrix includes any
combat-context cell sourced from a fight that needs to actually start (much
of X01 is menu/UI navigation, which does not depend on `can_challenge()`),
so I am not calling it contaminated the way X04 clearly is — but "entry save
predates the stranding" is simply false for X01 as currently seeded, and
whoever runs it should check for combat-context cells specifically before
trusting them.

**X07, X08 and X05 remain the segments I can actually confirm are unaffected**
— X07/X08 are teleport-permitted DIAG audits with no save dependency, and
X05 (session lifecycle) tests save/load mechanics themselves rather than
combat, so a fainted party does not change what it is measuring (though its
own party-state checks should expect a fainted Moss on every save from S03
onward, not a healthy one, until this fix's saves replace them).

## Impact on other lanes / comparability of prior results

**The fix touches only `tools/gate_f/segments/S03.json` — a rig step-script.
No file under `scripts/`, `data/`, or any other game-code/content path was
touched.** It changes what actions the harness performs (it now assigns the
party's fainted creature to a bed before the segment's existing sleep step);
it does not change the game or the world in any way.

Consequences for comparability, stated directly per the coordinator's ask:

- **Every result T2-GATEF collects on X07, X08, X05, X01 and X04 stays fully
  valid and comparable**, before or after this fix lands: none of those
  segments' entry saves or step-scripts are touched by it, and the fix
  changes nothing about game behaviour they could observe.
- **X03 and X06 are correctly held back** — both depend on saves at or after
  the stranding, and those saves will change once S03 (and everything
  chained after it) is re-run with a healthy party. Do
  not run them against the current stranded saves; do not run them against
  saves produced before this fix landed and call that current evidence.
- **S05 through S10's existing evidence describes the stranding, not bands
  2-5**, exactly as flagged in this session's own handover — that evidence
  does not become valid retroactively; it needs a real re-run from a
  healthy S03 onward. This was already known going in; this fix is what
  makes that re-run possible, not a change to what those nine "complete"
  segments already recorded.

## The player-facing dialogue question — my read, per the coordinator's ask

The coordinator asked me to assess `trainer_npc.gd::_on_challenged()`
showing the `defeated` conversation line whenever `can_challenge()` is false
for any reason, including "your only creature is fainted" — is this
player-reachable, is it a soft-lock, and is the obvious-looking fix actually
small? My read, checked against the tree rather than assumed:

1. **Player-reachable: yes, confirmed.** `autoload/party.gd::all_fainted()`
   is defined and has **zero callers anywhere in the codebase** — grepped
   across `scripts/`, `autoload/`, `tools/`. Nothing auto-heals, blacks out,
   or otherwise intervenes when the party's only usable creature faints.
   Player movement itself is never gated on creature state (human never
   fights, by hard rule), so a real player can walk up to the South Bridge
   grunt with a fainted-only party exactly as this run's rig did, with no
   safety net catching them first.
2. **Not a soft-lock — a confusing dead end.** Creature beds (built during
   the S03 tutorial, before the player ever leaves for the bridge) and
   camp-placed beds anywhere in the field (X02's own build lab exercises
   this) are a real, always-available recovery path, and the player's own
   movement is never blocked by creature state, so backtracking to heal and
   returning is always possible. The actual failure is that the game gives
   **no explanation at all**: the trainer's `defeated` line falsely claims a
   win that never happened, and `encounter_director.gd::_creature_control_
   offer()` shows no prompt whatsoever (not even an explanatory one) when the
   only creature is fainted — so a player without genre knowledge could sit
   confused at the gate for a while, but is never unable to recover.
3. **The fix is not as small as the diff would suggest, because of where it
   lives, not what it does.** Distinguishing "already beaten" from "no
   usable creature" is a small, safe-looking change in isolation (`can_
   challenge()` already computes the exact reason at L1568; giving it a
   sibling query rather than changing its boolean contract — which 8+ call
   sites across `scripts/` and `tests/` depend on as a bare bool, grepped and
   confirmed — is the low-risk shape). But the query lives in
   `scripts/combat/encounter_director.gd`, which my brief explicitly does
   not own (a type-system lane, T3-TYPECHART, is changing damage resolution
   there concurrently), and the branch consuming it lives in `trainer_npc.gd`,
   shared by every one of the ~17+3 trainers in the game. **I have not
   implemented this and do not think I should** — not because the change
   itself is large, but because it sits in a file I was told is someone
   else's, actively being edited, right now. Whoever routes it: the smallest
   safe shape is a new method (e.g. `no_usable_ally() -> bool`) beside `can_
   challenge()`, consumed by one new branch in `_on_challenged()`, with a
   single generic line (not per-trainer data) rather than touching all
   ~20 trainer entries in `data/config/bands/**/trainers.json`.

## Full-segment and isolated validation, both done

**A real S03 replay** (`tools/gate_f/run_segment.sh S03`, from a scratch copy
of this run's own `S02-exit.json`, logic mode) finished `INVENTORY.json
"complete": true`. Its exit save's Moss is **still fainted** — but not
because of anything wrong with the new steps. `S03-205` (unmodified,
pre-existing) itself FAILs — `creature_bed_built_3 NOT set` — and this is
**not new**: the same run's original evidence copy shows the identical FAIL
at the identical step (`S03-173`/`S03-205` both FAIL in
`gate-f-run-20260828T183531Z/S03/notes/S03.md` too). The tutorial's
build-placement sequence (analog-stick ghost placement) fails to register
`home_built`/`creature_bed_built_3` in this environment, in both runs,
independent of this fix — a separate, pre-existing, already-recorded defect,
not something I introduced or something in scope for this task. With no bed
ever actually built, my new steps correctly and safely FAILed rather than
mis-firing: `S03-205b` refused to press the wrong live prompt ("Ripplet is
out of the fight." does not contain "Rest a Creature" — not pressed), exactly
the safety `interact_with`'s prompt-matching is there for.

**Because that pre-existing failure blocked validating the new steps' own
correctness via the full segment, I validated them in isolation instead**:
`tools/gate_f/probe_bed_rest_sequence.gd` loads this run's real
`S05-exit.json` (fainted Moss), builds a REAL `creature_bed.gd` the way
`build_placer.gd` does (`build_real()` + `set_build_index()`), then drives
the exact sequence `S03-205a`..`S03-205e` assumes:

```
live prompt near the bed: "...Rest a Creature"
panel open: true, visible=true
assign_creature(0) returned: true
bed occupied after assign: true
active creature resting=true rest_bed_index=0
--- ticking creature-bed recovery forward ---
hp after simulated recovery: 1.18/1.18  fainted=false
PROBE PASS
```

Every assumption the new steps make — the exact prompt text, the panel
opening, row 0 resolving to the party's only creature, the recovery actually
clearing `fainted` — is confirmed against real game code. **The fix is
correct; it is untested against a live segment run only because of an
unrelated, pre-existing bug in the tutorial's own build-placement steps**,
which is worth a separate ticket (I did not chase it further — out of scope,
and it does not touch the South Bridge stranding this task was about) but
should be named: whoever picks it up should look at why the `stick`-driven
ghost placement in `S03-118`..`204` doesn't register with `home_progress.gd`
in this environment, since it blocks BOTH the home and creature-bed tutorial
objectives from ever completing in an automated run, which is very likely
inflating the FAIL counts already recorded against S03 in the original
evidence for reasons that have nothing to do with the stranding.
