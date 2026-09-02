# S03 attempt 7 finding: real aim-steering converges (slowmo fix confirmed), but the catch loop still hits the 2-Revive wall

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`, attempt 7.
**Candidate:** `284069f9bf206e3fd95ac0a39577760ae3e3a803` (this branch merged onto
`origin/main` HEAD `953a357f` at run start — carries `ralph/OWNER-0902-CATCH-SLOWMO`
plus the village-population, load-time and village-readability fixes landed
on `main` since this branch was cut).
**Run directory:** `ralph/reports/gate-f-run-20260901T220548Z-s03fix/S03`
(attempt 6's own S03 output renamed to `S03-superseded-6` before this run).
**Segment:** S03 catch loop, all 10 numbered attempts (`S03-32a`..`S03-32j`).
**Result:** 404P/32F/8SKIP steps, `INVENTORY.json complete: false`.

## In one line

`ralph/OWNER-0902-CATCH-SLOWMO` (35% target speed while aiming) genuinely
fixes the aiming-difficulty problem attempt 6's `force_aim` harness shortcut
was invented to route around: real `track_aim` steering now converges to
"reticle confirmed on body" in 10-38 frames every time it runs, well inside
its 240-frame budget, versus never converging before. **But the party still
only reached 3 of 5**, and the run still ends the same way attempt 6 did —
every recovery attempt from the 4th catch attempt onward FAILs with "the
satchel does not hold it at all" because the ladder's starting grant of 2
Revive draughts is exhausted. The revive-economy question attempt 6 raised
is confirmed real, not an artifact of the aiming problem that came before it.

## 1. What changed before this run

1. Merged `origin/main` into `ralph/GATE-F-S03-CATCH-LOOP` (clean, no
   conflicts) to pick up `ralph/OWNER-0902-CATCH-SLOWMO`
   (`data/config/catching.json`'s `aim.target_slowdown_scale: 0.35`, read by
   `wild_creature.gd` while `throw_aim.gd`'s AIMING state is active) and
   everything else landed on `main` since this branch was cut.
2. Replaced all 10 occurrences of attempt 6's harness-only `force_aim` step
   in `tools/gate_f/segments/S03.json` (`S03-36a2`..`S03-36j2`) with real
   `track_aim` steps — the same steering primitive S02's own required catch
   is measured on (`budget_frames: 240`, matching `S02-41b`/`S02-43db`).
   `_step_force_aim` is left in place in `operator_harness.gd`, unused by
   S03 for this attempt.

No other game code, data, or config was changed to produce this finding.

## 2. Real aiming now converges

Of the 10 numbered attempts, 6 reached a live fight and ran `track_aim`
for real (attempts a, c, e, f, h, i — the other 4 never started a fight at
all, see §4). Every one of those 6 converged well inside budget:

| attempt | frames to `eligible` |
|---|---|
| a | 32 |
| c | 32 |
| e | 33 |
| f | 10 |
| h | 32 |
| i | 38 |

This is the direct comparison point against attempt 5 (pre-slowdown, real
`track_aim` not even present in the script) and attempt 6 (post-slowdown,
but steering replaced by the `force_aim` snap rather than tested): this is
the first run in this whole verification chain where scripted analog-stick
steering has actually caught up to a live wild creature. The slowdown fix
is doing exactly what `ralph/OWNER-0902-CATCH-SLOWMO`'s own commit intended.

## 3. The catch loop still stops at 3 creatures, on the same wall as attempt 6

Five throws actually fired (attempts a, c, e, f, h — i's throw at t=458.45
registered as attempt i, not a 6th; see raw telemetry). Only **one** landed
a catch (attempt e, t=364, party grew 2 -> 3 — the target was down to
8.15/106.2 HP, ~8%, the only throw against a genuinely weakened target).
The other four threw at targets sitting around 48-65% HP and, per
`data/config/catching.json`'s own steep `hp_curve`, had correspondingly poor
catch odds even with a dead-centre eligible throw — this is the catch RNG
working as designed against under-weakened targets, not an aiming defect,
and is a separate observation from the revive wall below.

Revive recovery:

- Starting grant: 2 Revive draughts (confirmed in the S02-exit save carried
  into this segment).
- `S03-32ar2`/`S03-32br2`/`S03-32cr2` (`focus_item 'revive'`) all PASS —
  the item was found and available through recovery blocks a, b and c.
- `S03-32dr2` onward (recovery blocks d through j) all **FAIL**: `"FAIL
  focus_item 'revive': the satchel does not hold it at all. Carrying:
  {"berries":8,"knife":1,"orb_basic":4x,"torch":1}"` — no `revive` key in
  the inventory at all from this point on.
- Exit party: 3 members (Moss, Bramblebun, Bramblebun), **all three at
  0 HP** (fainted), objective still reads "Build your full team of five for
  the village tournament."

This is the same failure mode attempt 6 hit with `force_aim` (party capped
at 4 there, 3 here — the difference is catch-RNG variance on how weakened
each target was when thrown at, not the revive mechanic itself). Real aiming
did not change the outcome: the ladder cannot recover from more than two
faints with its current starting grant, however reliably the throws land.

## 4. Secondary finding: 4 of 10 attempts never started a fight

Attempts b, d, g and j all FAILed at "challenge it" before any fight began,
each for a different reason visible in the live interact prompt at that
moment:

- attempt b: prompt was `"Pick berries"` — the nearest interactable was a
  harvest node, not a wild bramblebun.
- attempt d, g: prompt was `"Put Bramblebun away"` — the nearest
  interactable was the player's own already-caught Bramblebun party member
  offering a swap, not a wild one.
- attempt j: prompt was `"Bramblebun is out of the fight."` — a fainted ally.

This is a `move_to_entity`/prompt-arbiter targeting gap independent of the
aim/revive question this run set out to answer — worth a look, but out of
scope for this checkpoint and not touched here.

## 5. Open question, unchanged: is 2 Revive draughts the intended ladder grant?

Per the coordinator's own framing before this run: does the party need to
retreat and restock Revives mid-ladder by design (an intended, harder
design this segment's script does not currently model), or is the starting
grant meant to be larger so a full 10-attempt catch ladder is completable
in one uninterrupted push? This run answers the *aiming* half of that
question (aiming is no longer the excuse) but not the *design* half. Not
decided here — flagged back to the coordinator, same as attempt 6.
