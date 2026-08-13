# D32 — Mid-combat pal switching becomes real

**Date:** 2026-08-13 · **Decided by:** the owner, as one of four canon
changes approved alongside `D29`, `D30` and `D31`.

## The decision

Switching pals during a fight stops being reserved input and becomes a real
mechanic. **Tap** `combat_switch_left` / `combat_switch_right` cycles the
active fighter to the next non-fainted party member. **Hold** either opens a
short party selector (UI spec §9.4). No time-slow — the spec allows it "if
current combat design already permits", and Tetherbound's combat has never
had one, so this stays real-time throughout.

## Why

`project.godot` has shipped `combat_switch_left` (line 215) and
`combat_switch_right` (line 221) since `D15`'s control-remapping pass, fully
rebindable, fully shown on the Settings > Controls screen — and read by
nothing. `combat_manager.gd`'s own header has said since M2 that "the switch
SEAM is here (`_active_index` into `_party`)" so a later milestone could add
members "rather than restructuring this file." That milestone is this one.
The owner confirmed the mechanic directly, same session as `D29`/`D30`/`D31`.

## What changes on disk

- `scripts/combat/combat_manager.gd` — `_active_index` gains a real
  advance-to-next-non-fainted operation, driven by the two switch actions
  read alongside the fight's other polled input. This is the same
  index-into-`_party` mechanism the header comment already named as the
  seam; a faint that empties the active slot and a deliberate switch both
  resolve through it, so the fight has exactly one way of changing who is
  fighting rather than two.
- Guards, all in `combat_manager.gd`: no switch while the player is aiming a
  throw (`throw_aim.gd` has camera and control), and no switch while a catch
  is resolving (`State.RESOLVING`). A switch lockout of roughly 1.5 seconds
  after any switch — tunable — stops the tap from being spammed into a
  stutter of pals.
- `data/config/combat.json` — a new `switch` block: `lockout_seconds`
  (~1.5, tunable), following the file's own `ALL TUNABLE` header.
- `scripts/ui/combat_hud.gd` — the held-selector view: a short vertical
  party strip near the lower-left controlled-Pal block (spec §9.4), reusing
  the party-reveal treatment the exploration HUD already has (spec §6.1)
  rather than inventing a second one.

## What was deliberately not built

- **Time-slow on hold.** The spec offers it conditionally; Tetherbound's
  combat has no precedent for pausing or slowing the world mid-fight
  (`D07`: piloted, real-time, no dodge button because movement is the
  dodge), and adding one here would be a second design decision riding in on
  this one.
- **Switching to a fainted pal.** The cycle skips fainted party members
  entirely; there is no way to select one, matching the existing rule that a
  faint already ends that pal's part in the fight.
- **AI-controlled switching, or auto-switch-on-faint.** The player always
  chooses. If every party member faints, the fight still ends the way it
  always has — this decision adds a way to switch voluntarily, not a
  survival mechanic.

## What it supersedes

Nothing structural — `D15` reserved the bindings for exactly this, and
`combat_manager.gd`'s M2-era header comment ("no switching UI") is now
finished, not contradicted.
