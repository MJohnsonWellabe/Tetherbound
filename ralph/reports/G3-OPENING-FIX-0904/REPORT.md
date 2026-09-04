# G3-OPENING-FIX-0904

Three defects that strand a player whose team is fine, all in the first hour, all
presenting as "the game refuses and I don't know why." Branched from
`ralph/G3-LAND-0904` (44f06cf9). Pushed as `ralph/G3-OPENING-FIX-0904`, no PR.

## 0. A blocker found before any of the three could be verified

Before touching any of the three assigned defects, `tests/smoke_catching.gd` — the
closest existing coverage the brief named — was run against the landed tree and
failed immediately: `no wild creature to throw at`. Root cause:
`encounter_director.gd::_spawn_creatures()` threw `Invalid access to property or
key 'combat' on a base object of type 'Dictionary'` on the very FIRST spawn cluster
processed (order 0, the practice Bramblebun cluster every one of these defects and
their tests need). The crash came from commit `4444381e` ("G-2: give every named
opponent its own fight"), landed on this branch earlier the same day, in a new
inline merge loop:

```gdscript
for block: Dictionary in [elder, (spawn.get("alpha", {}) as Dictionary) if spawn.get("alpha", {}) is Dictionary else {}]:
    if block.get("combat", {}) is Dictionary and not (block["combat"] as Dictionary).is_empty():
```

Both array elements were provably empty, valid Dictionaries (order 0's cluster
authors neither `alpha` nor `elder`) — this reads as a genuine Godot 4.7
GDScript-VM/compiler edge case in a typed `for` loop iterating an array literal
built from a ternary, not a data problem. Rewritten as explicit locals
(`scripts/combat/encounter_director.gd`):

```gdscript
var alpha_block: Dictionary = spawn.get("alpha", {}) if spawn.get("alpha", {}) is Dictionary else {}
var named_blocks: Array[Dictionary] = [elder, alpha_block]
for block in named_blocks:
    var block_combat: Variant = block.get("combat", {})
    if block_combat is Dictionary and not (block_combat as Dictionary).is_empty():
```

Confirmed the fix by reverting it and re-running `tests/smoke_catching.gd`: fails
identically without the fix, passes with it. This crash is not one of the three
named defects, but every one of them was unreachable without it — it is why this
report opens with it rather than burying it in defect 1's section. `tests/
smoke_catching.gd` is the regression test (already existed; not new).

## 1. The tutorial catch cannot throw a second orb (GAME-11/RIG-26)

**Root cause: not reproducible as "the orb never leaves the hand" once §0's crash
is fixed.** Direct reproduction of the exact S02.json retry shape — arm via
`interact`, steer the camera onto the body every physics frame like `track_aim`
does, release, repeat — against the real practice cluster threw and spent an orb
on every one of four consecutive cycles (stock 15→14→13→12→11), striking every
time. `throw_aim.gd` and `combat_manager.gd`'s arm/guard/release state machine is
sound: the 0.15s `_guard` correctly prevents the same physical press from both
arming and instantly releasing (verified by tree order — `ThrowAim` is a child of
`CombatManager`, so the parent's `_physics_process` runs first each tick and the
child's guard has already been set before it checks it).

Two things this session found instead:

- **§0's crash.** Before the fix, no wild creature spawned at all, so a Gate F run
  hitting this on a bad boot would show symptoms indistinguishable from a
  first-throw-only session, depending on exactly when in the segment the crash
  landed.
- **The Gate F harness's own `catch_throw` telemetry only detects a STRUCK orb.**
  `operator_harness.gd:6090-6092` emits `catch_throw` only when
  `combat_state().phase` transitions to `"absorb"` — set exclusively by
  `combat_manager.gd::_on_orb_struck()`. A thrown orb that MISSES
  (`_on_orb_missed()`) never sets that phase, so it produces **zero** harness
  telemetry: no `catch_throw`, and there is no `catch_refused`/`throw_refused`
  detector in the harness at all. "Zero `catch_throw` events across three
  retries" is therefore consistent with three real, orb-spending throws that all
  missed — not with three presses that did nothing. This is a telemetry gap in
  `tools/gate_f/operator_harness.gd`, which is explicitly not mine to touch
  (G3-HARNESS owns it); flagged here for that lane rather than fixed.

**One real, narrow gap found and fixed regardless:** `throw_aim.gd::_release()`'s
`_spend_orb()` failure path emitted no signal at all — the one refusal in the file
that broke its own stated house rule (every other refusal in this file, and
`try_begin_aim()`'s own "no orbs left", explains itself). If the satchel's last
orb of the spent tier is ever removed by something else between arming and
release, the player's press did nothing observable — exactly the shape "the
second orb never left the hand" describes, whatever actually causes it. Fixed to
emit `throw_refused.emit("no orbs left")` before `_leave_aim()`.

**Test:** `tests/smoke_catch_retry.gd` (new). Drives the real practice cluster
through four consecutive arm→track→release cycles via `interact`, same as
`S02.json`, and asserts every cycle either spends an orb or explains itself with a
signal — silently doing neither is the exact defect. Confirmed it fails without
§0's fix (reverted `encounter_director.gd` alone, re-ran: `no wild creature
spawned near the practice cluster`) and passes with it.

## 2. A creature revived from the Satchel is not re-deployed (2.11)

**Confirmed: the shipped game does not re-deploy.** `summon_active_creature()` is
only ever called from `party.revision` changing (a different slot selected) or an
explicit `creature_recall` press — never from a stat change. `tab_backpack.gd`'s
Revive branch called `creature_instance.gd::revive()` directly on the RefCounted,
which bumps nothing `party.revision`-visible. So a creature revived while nothing
is currently deployed (the exact post-tournament handoff GATE2-EVIDENCE-0903
measured — S05-09a's own load never auto-deploys a fainted active creature, and
nothing ever retries once it stops being fainted) stayed undeployed:
`can_challenge()`/`no_usable_ally()` unchanged by the revive, confirmed
"nothing... requires a recall press" against the live game before any fix.

**Fix** (`scripts/ui/tab_backpack.gd`): after a successful Revive on the party's
currently-active creature, call `EncounterDirector.summon_active_creature()`
right there. This is a no-op every other time (that function already refuses
while something is deployed, mid-fight, or the active creature isn't the one just
revived), so it can never override a creature the player deliberately put away —
`dismiss_active_creature()` never faints anything, so the "was fainted, now
revived, nothing deployed" state cannot arise from a deliberate dismiss. Also
corrected a stale comment claiming "nothing in the shipped item set sets a
`revive` field yet" — `data/items/items.json`'s `revive` item does, and the
branch is live in production.

**Test:** `tests/smoke_revive_redeploy.gd` (new). Builds a real party member,
deploys it through `summon_active_creature()`, faints it directly
(`take_damage`), dismisses it (`dismiss_active_creature()` — reaches the exact
`_ally_body == null` + fainted state a fresh load leaves, without needing an
actual save/load round trip), confirms `no_usable_ally()`/`can_challenge()` are
correctly blocked, then opens the REAL Satchel with a real pad press (same
`_pad()`/`InputEventJoypadButton` routing as `smoke_backpack_player_eats.gd`),
uses a real Revive item on the fainted row, and asserts `ally_body()` is non-null
and `can_challenge(practice_trainer)` is true afterward — with no
`creature_recall` press anywhere in the file. Confirmed it fails without the
`tab_backpack.gd` fix (reverted, re-ran: all three assertions fail).

## 3. Post-tournament recovery (2.10)

### 3a. The refusal line now names the real reason

`no_usable_ally()` collapsed two distinct causes into one line ("Get it back on
its feet first — a bed will do it, or something to revive it on the spot"), which
is only true for one of them. The other — a healthy party with nothing currently
deployed (a fresh load, per RIG-13's own general "a load restores the party and
deploys nothing"; or a deliberate dismiss) — was told to go heal a creature that
was never hurt.

Added `encounter_director.gd::usable_ally_blocker() -> String`, returning
`"fainted"` or `"undeployed"`. `trainer_npc.gd::_on_challenged()` now picks
between the existing `trainer_no_usable_creature` conversation (fainted — line
unchanged, still correct for that case) and a new `trainer_no_ally_deployed`
("You haven't got anything out. Call one of your team out first.") for the
undeployed case. Both are the same generic, one-id-for-every-trainer shape
`trainer_no_usable_creature` already used (`data/dialogue/trainers.json`), for the
same reason: the fix has to reach all ~27 trainers without a per-trainer edit.

**Tests:** `tests/smoke_trainer_no_usable_ally.gd` (existing, unmodified —
confirmed still green: the fainted case is unchanged) and
`tests/smoke_trainer_no_ally_deployed.gd` (new), its companion for the undeployed
case — dismisses a healthy ally, confirms `usable_ally_blocker() == "undeployed"`,
and asserts the trainer opens `trainer_no_ally_deployed`, not the fainted line and
not a false "defeated".

### 3b. Where recovery lives: the champion beat restores the team

**Decision: the champion beat (the tournament's own closing line,
`tournament_final_beaten`) fully heals and revives the whole party.**

Reused `home_recovery.gd::rest()` — the exact thing a Creature Bed already does to
one party member (`heal_fully()` plus the same flat overnight rest XP) — applied
to every member at once, behind a new dialogue effect `heal_party`
(`sequence_director.gd::_drain_effects()`/`_heal_party()`). Attached to
`tournament_final_beaten` (Oskar's line, fired unconditionally the instant the
final round is won) rather than `tournament_halda_champion` (which requires a
separate, optional walk back to Halda — its own file comment already says the
saddle-pattern reward does not depend on that walk, and a player who skips it
would otherwise get no recovery at all).

**Rejected alternatives, and why:**

- **Halda or Mira selling/handing over recovery.** Turns the fix for a problem the
  tournament itself caused into a transaction layered onto a beat that is already
  handing the player a reward (the saddle pattern). Reads as the game taxing its
  own design.
- **The Trail Camp becoming the authored recovery stop.** Sits roughly 900m south
  of the tournament, past Old Bram's own fight (per `trainers.json` positions:
  tournament ~(20,12), Old Bram (195,905), the Trail Camp beyond both Old Bram and
  the second field trainer Gil, South Bridge (14,1314)). Recovery that only lands
  AFTER the first post-tournament battle does not answer the battered walk OUT of
  the arena — only whatever comes after Old Bram — so it does not close the gap
  GATE2-EVIDENCE-0903 actually measured (both Old Bram and the South Bridge
  gatekeeper refused).

Both alternatives use only what already exists (Halda's own dialogue slot; the
Trail Camp's existing landmark status) — neither was implemented, per the
instruction not to invent a new system; the champion beat option does too
(the dialogue effect pipeline and `home_recovery.gd::rest()` both already
existed).

**Test:** `tests/smoke_tournament_heal.gd` (new). Builds a real five-creature
party in the exact battered shape GATE2-EVIDENCE-0903 measured (three fainted,
two hurt), plays `tournament_final_beaten` through the real `DialoguePanel` (same
seam `smoke_village_smith.gd` already proved reaches the real satchel for
`give:`), and asserts every creature is unfainted and at full HP afterward.
Confirmed it fails without the JSON effect (reverted `data/dialogue/bands/
band1_lower_meadows.json` alone, re-ran: 3 still fainted, 5 still short of full).

## Tests run

- `tests/smoke_catching.gd` — FAILS on the unpatched tree (§0), PASSES patched.
- `tests/smoke_catch_retry.gd` (new) — PASSES; fails without §0's fix.
- `tests/smoke_revive_redeploy.gd` (new) — PASSES; fails without the
  `tab_backpack.gd` fix.
- `tests/smoke_trainer_no_usable_ally.gd` (existing) — PASSES, unmodified
  behaviour for the fainted case confirmed unchanged.
- `tests/smoke_trainer_no_ally_deployed.gd` (new) — PASSES.
- `tests/smoke_tournament_heal.gd` (new) — PASSES; fails without the dialogue
  effect.
- `tests/smoke_opening.gd`, `tests/smoke_gate_a_opening_segment.gd` — both PASS
  on the patched tree (closest existing continuous coverage named in the brief).
- `tests/run_tests.gd` (full unit suite, ~28 min) — launched; see
  `ralph/reports/G3-OPENING-FIX-0904/unit_suite.log` for the tail if this report
  was committed before it finished. [Update this line with the final PASS/FAIL
  count before landing if the run completed in-session.]
- Targeted unit files also run individually and green: `test_dialogue_runner.gd`
  (66 tests), `test_tutorial_orb_floor.gd`, `test_tutorial_faint_floor.gd`,
  `test_encounter_combat_override.gd`, `test_opening_beats.gd`.

## Files touched

Owned, as scoped:

- `scripts/combat/throw_aim.gd` — silent `_spend_orb()` refusal now signals.
- `scripts/combat/encounter_director.gd` — §0's crash fix; `usable_ally_blocker()`.
- `scripts/story/sequence_director.gd` — `heal_party` dialogue effect.
- `data/dialogue/bands/band1_lower_meadows.json` — `heal_party` on
  `tournament_final_beaten`.
- `scripts/ui/tab_backpack.gd` (revive flow only) — auto-redeploy on revive.
- `tests/` — five new smoke tests, listed above.

Touched narrowly outside the letter of the ownership list, because the fix could
not be delivered without them (both are the necessary wiring for "no_usable_ally
messaging", which the brief does list against `encounter_director.gd`):

- `scripts/world/trainer_npc.gd` — picks between the two existing/new
  conversations based on `usable_ally_blocker()`. Six lines.
- `data/dialogue/trainers.json` — the new `trainer_no_ally_deployed` id, in the
  same generic, all-trainers file `trainer_no_usable_creature` already lives in.

Not touched, per ownership: `tests/helpers/stick_navigator.gd`,
`tools/gate_f/**`, `scripts/ui/playground_hud.gd`, any `vegetation.json`/
`terrain_playground.json`.

## Proposed follow-up (not implemented, out of scope)

- **G3-HARNESS**: `operator_harness.gd`'s `catch_throw`/`catch_result` detectors
  have no miss/refusal case — a genuine throw that misses is invisible to Gate F
  telemetry. Worth a `catch_refused`/`orb_missed`-driven event alongside the
  existing `phase == "absorb"` one, so a future "zero catch_throw" reading can be
  trusted at face value.
- **RIG-13** (pre-existing, not one of this lane's three): a save/scene load never
  auto-deploys any creature, fainted or not — `S05-09a`'s own scripted
  `creature_recall` press is the harness's standing workaround. Out of scope
  here; 2.11's fix only closes the "revived but undeployed" half of it.
