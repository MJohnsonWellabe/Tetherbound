# Gate F leg — isolated S08 test (Upper Meadows / Band 4)

Branch `ralph/GATE-F-LEG-S08`. **This is conditional/isolated evidence: S08,
given a clean hand-seeded entry, does X — not a claim about the whole
chapter.** `ralph/GATE-F-FOUNDATION` never landed during this work; per a
coordinator correction mid-session, the blocking defect it would have carried
(GAME-F4, below) was diagnosed and self-applied instead of waiting on it.

## The seed

`saves/S07-exit.json`, a hand-authored stand-in for a real S07 exit, loaded
through the production title-screen Load path (not injected into a running
scene):

- Party of 5, levels 14–17 by the end of the run: Tuskroot, Trailpup,
  Duskhush, Galecrest, Meadowhart. Full HP, iv 0.5 (neutral) on every stat,
  no traits, no boosts. Tuskroot placed first (tankiest) so the mount species
  is not the first thing exposed on the road; Meadowhart last, reached by
  four `party_cycle` presses before mounting.
- A `saddle` already in the satchel — assumption stated explicitly: a real
  S04 tournament-final win over Oskar's Meadowhart grants it
  (`data/config/tournament.json`'s own comment), so this seed carries it
  rather than re-testing crafting, which is S03/X02's own scope.
- Every flag through `mill_crossing_restored` set (the full opening ladder
  through the end of Band 3), positioned at the Band 3→4 crossing via a
  single DIAG teleport to `(-152, 4203)` — the exact coordinate S07's own
  `move_to` target uses (`tools/gate_f/segments/S07.json` step S07-76).
- A basic supply kit: tools, a handful of orbs/potions/revives, some coin
  and raw materials.

## What the isolated run actually drove

Production paths throughout except the one entry teleport and three more
DIAG teleports added mid-session to route around found navigation snags
(see below) — `tools/gate_f/operator_harness.gd` in logic mode, real title
Load, real movement, real interact/combat input.

1. Crossing → real walk into the Ironwood Grove, harvest ironwood.
2. Cycle the active creature to the seeded Meadowhart, mount it (interact),
   ride ~640 m to Captain Halder's site at sustained ~10 m/s (confirmed
   correct: Meadowhart's `ride_speed_multiplier` 2.0 × the 5.0 m/s
   `walk_speed`).
3. Dismount, challenge and defeat Captain Halder (Ground-focused).
4. Ride/walk to Captain Oreth (Water/Ground, deliberately balanced),
   challenge and defeat her.
5. Ride/walk to Captain Vess (Air-focused) on the ridgeline, challenge and
   defeat her.
6. Save out `saves/S08-exit.json` through the production Save tab.

**Final run: 140/141 steps PASS.** The one FAIL is a documented,
non-blocking navigation quirk (below). All three captain defeat flags set,
all three Sigil items confirmed present in the exit save's own inventory
(`field_sigil`, `ridge_sigil`, `river_sigil`, each `n:1`), `hall_approach_open`
correctly **not** set — opening the Sigil Gate is S09's own first beat, not
S08's (see the fix below for why that took several iterations to get right).

## What was fixed

### GAME-F4 — loaded creatures lost their base stats on the next level-up

`scripts/save/save_game.gd`'s `_array_to_party` never restored a loaded
creature's `base_hp`/`base_attack`/`base_defence`, leaving them at
`CreatureInstance`'s bare `1.0/1.0/1.0` defaults (`from_species` seeds real
values; a save/load round trip did not). `creature_instance.gd::_apply_level_stats`
recomputes `max_hp`/`attack`/`defence` from those three on every level-up,
elixir drink and evolution — so any loaded save's creature that leveled up
afterward had its stats silently collapse toward base=1.0's own numbers. A
`creature_instance.gd` comment already promised this exact repair
("repaired from species.json ... exactly like every other species-owned
field") for a sibling field (`secondary_type`); no such repair had ever
actually been wired for the base stats themselves.

Surfaced by a coordinator correction mid-session (a separate lane,
`GATE-F-FOUNDATION`, was diagnosing the same defect independently and never
landed) — independently verified by reading the code before applying
anything, not taken on trust. Fixed: the three fields now round-trip in the
save format, with a species.json fallback repair for saves written before
this field existed. Two new regression tests in `tests/test_save_format.gd`:
a round-trip check with non-default base stats, and a live post-load
level-up that asserts `max_hp` does not collapse. Both pass; the file's full
50-test suite passes at 0 failed.

### riding_controller.gd — a just-dismissed mount could steal a captain's challenge press

Found live: the isolated run's first attempt rode up to Captain Halder,
dismounted, and pressing `interact` to challenge him **remounted the
Meadowhart instead** — confirmed by camera distance round-tripping
6.8 → 5.2 → 6.8 across the dismount and the challenge press. Root cause:
`dismount()` always lands the mount within `dismount_distance` (1.6–2.0 m)
of the player, well inside `MOUNT_RADIUS`, and the mount resumes following
at roughly that distance indefinitely — so a rider who dismounts next to
whatever they actually came to interact with (this segment's own designed
sequence: ride up to a captain, dismount, challenge) has their own
just-dismissed mount sitting there as a second, tied-priority
`interaction_offer()`, and `prompt_arbiter.gd` breaks ties by nearest.

First fix attempt (a 1.5 s post-dismount cooldown on the re-offer) was not
robust — the follower keeps pace this close indefinitely, not just for the
first couple of seconds, so a later re-check with a longer real gap still
lost the tie. Replaced with a priority fix: a new `RIDE_PRIORITY` (-1) on
the not-yet-mounted "Ride" offer, sitting strictly between the ordinary
`interactable.gd` default (0, used by trainers/chests/harvest nodes) and
`encounter_director.gd`'s own -1 "Put X away"/"Call out X" non-actionable
status-line fallback (moved to -2 to make room — colliding the two at -1
made the status line win instead, which is worse, since pressing it does
nothing; this broke `tests/smoke_riding.gd`'s very first mount and was
caught before it shipped). Verified clean afterward:
`tests/smoke_riding.gd`, `tests/smoke_build_wins_while_hammer_is_out.gd`,
`tests/test_hammer_keeps_the_interact_button.gd`, `tests/test_recipes.gd`,
and 104 tests across tournament/band-content/wild-alphas/
input-owner-enforcement — all 0 failed. Confirmed fixed end-to-end: every
run since has opened the real challenge dialogue correctly.

## Findings recorded, not changed (working as designed or out of this leg's scope)

- **Two mount-collider navigation snags on the direct grove→captain_field
  line** (`~35,5447` and `~98,5512`, then a third residual one at
  `~4,5395` on the reroute) — the un-pathfound `stick_navigator` test
  helper oscillates in a tight loop against something the larger mount
  collider (species.json's own 0.74 m placeholder radius) cannot get past
  on a straight approach. Recorded as `defect` events (ISO-22a) and routed
  around via DIAG waypoints rather than fixed — this is plausibly a real
  terrain/prop snag worth a follow-up ground probe (`tools/_probe_band4_sites.gd`-style),
  but could also be specific to the harness's own straight-line steering;
  not chased further given the isolated scope of this leg.
- **No auto-switch-on-faint is intentional** (`combat_manager.gd`'s own D32
  comment: "a faint of the active creature still ends the fight exactly as
  it always has. This only ever fires from the player's own choice").
  Several tuning iterations of this segment's own fight-driving logic
  chased what looked like a bug before finding this — losing a fight with
  healthy party members still in reserve is correct, documented behavior;
  switching has to be pre-emptive, not reactive. Not a defect.
- **`hall_approach_open` is S09's flag to set, not S08's.**
  `item_gate.gd::try_open()` (the SigilGate's only path to that flag) runs
  only on interaction at the gate's own world position
  (`SIGIL_GATE_AT`, `(63.6,7400)`), which S08's own span never reaches —
  `ralph/GATE_F_MASTER_PROTOCOL.md` section B places "Sigil gate → outer
  watch → ..." as S09's first beat. This segment's own final assertions
  originally checked the wrong thing (copied from an assumption that
  proved wrong); corrected to check what S08's real boundary should show —
  the three Sigil items held, confirmed in the exit save's own inventory.

## Environment notes

Godot 4.7-stable (`4.7.stable.official.5b4e0cb0f`), downloaded fresh for
this session; import run twice per convention. `RUN_METADATA.json` is this
leg's own freeze record — the harness's capture pre-flight cross-checks a
run's freeze record and otherwise falls back to a stale, checked-in
`ralph/reports/gate-f-candidate/RUN_METADATA.json` claiming an X11 display
server, which blocks *any* plain-headless logic run (even one that plans no
captures at all) once that record exists; writing this leg's own record
avoided it rather than fixing the shared harness, which is out of this
leg's scope.
