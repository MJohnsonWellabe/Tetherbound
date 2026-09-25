# F12 clause 1: every mandatory Tidewake hop, with the original five

Clause (ACCEPTANCE §6.1 F12): "With the original five and no owned swimmer, level-0 human
swimming finishes every mandatory Tidewake hop with at least 20% stamina after 15% steering
deviation."

Result: **PASS.** All 7 mandatory routes (24 hops) passed with the original five in the real
`Game.party`. Worst hop: 30.14% minimum stamina (`sluice_isle_to_veilfall_sheltered` hop 1).

- Code under test: commit `d64ad8f53` on `ralph/water-f12-swim-proof-five`. This is
  `origin/ralph/water-f12-swim-proof` merged with `origin/main` (a3ff511e7), plus the
  `--original-five` fixture in `tests/smoke_water_swimming.gd`.
- Nothing under `scripts/**` or `data/**` was changed.
- Engine: Godot v4.7.stable.official.5b4e0cb0f, headless, Linux container.
- The earlier empty-party evidence is `ralph/reports/WATER-HUMAN-ROUTE/f12_every_hop.txt`.

## Commands

Each command was run from the repository root. Each one exited 0.

```
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=first_shore_to_reedhaven_sheltered   --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=reedhaven_to_brine_steps_sheltered   --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=brine_steps_to_shellwatch_sheltered  --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=shellwatch_to_tidal_cradle_sheltered --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=tidal_cradle_to_salt_crown_sheltered --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=salt_crown_to_sluice_isle_sheltered  --every-hop --original-five
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=sluice_isle_to_veilfall_sheltered    --every-hop --original-five
```

The unchanged CI forms were also run on the same commit, as a regression check. Both exited 0.

```
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd -- --rest-route=sluice_isle_to_veilfall_sheltered
  WATER REST ROUTE OK id=sluice_isle_to_veilfall_sheltered assertions=18 actual_swim_m=84.147 elapsed_s=37.344 minimum_stamina_before_regen=33.750 max_stamina_gain_per_frame=0.3000 final_health=100.000 commanded_steering_ratio=1.153
/root/godot-bin/godot --headless --path . --script tests/smoke_water_swimming.gd
  WATER SWIMMING OK assertions=22 actual_lesson_swim_m=60.142 final_health=91.200
```

In the lesson run, `final_health=91.2` is expected. That run includes its own exhaustion
fixture, which drowns the player on purpose.

## The party ("the original five")

| # | species | level | type | role |
|---|---|---|---|---|
| 1 | terrapup | 44 | ground | starter (Grandpa's Ground choice, `opening.json` starters) |
| 2 | bramblebun | 43 | ground | Meadows Band 1 catch |
| 3 | mudsnout | 42 | ground | Meadows Band 1 catch |
| 4 | pipwing | 42 | air | Meadows Band 1 catch |
| 5 | trailpup | 41 | ground | Meadows Band 1 catch |

**Why this is "the original five":**

- **The docs never name species.**
  - GAME_BIBLE §1: "Keeping the same beloved five through the ending is success."
  - ACCEPTANCE M-row S4 and T1: "the retained five ... without requiring a new catch or
    swim mount".
  - PROGRESSION §99 and WORLD §341 say the same thing: the same five the player has carried
    since Meadows.
  - I found no species list for them in GAME_BIBLE, ACCEPTANCE, CREATURES, WORLD or
    PROGRESSION.
- **Species: the project's own declared "typical five".**
  - The species come from `data/config/chapter_curve.json` `difficulty.party`.
  - Its comment says: "the typical five the pilot brings (the starter plus the four
    most-fielded Band 1 species)". `tests/smoke_combat_baseline.gd` uses that party.
  - I chose this over inventing a party. It is data, not an ad-hoc list.
  - A similar Meadows fixture exists in `tests/smoke_net_gate_opens_for_both.gd`
    ("retained-team fixture": bramblebun, trailpup, burrowback, meadowhart, terrapup).
- **Levels: the Tidewake arrival band from PROGRESSION.md §2's table.**
  - Stormwood runs L33 → L44. Tidewake runs "L43 overlap → L55".
  - Meadows keeps the other retained members "within 3 levels" of the lead.
  - So the lead is L44 and the others are L43–L41.
  - Levels do not affect human swim drain. They are here for plausibility, not as a lever.
- **Base forms.** All five are kept in base form. Mudsnout's evolution is optional and
  stone-gated, and an evolved form would not be a swim mount either.
- **No owned swimmer.**
  - None of the five is a Water-roster species (`water_*`). The fixture asserts this.
  - For each one, the game's own compatibility check returns false. That check is
    `CreatureSpecies.definition(id).swim_mount.compatible`, the same lookup
    `scripts/world/water_mounted_swim.gd` uses on the merged table that
    `data/config/water_roster.json` registers into.
  - The only swim mounts are cannonback, aquaryn, riverdrake, sirenseal and mosshell. None
    is in the party.
- **Water starter excluded on purpose.** A player who took the Water starter (ripplet)
  would carry a Water creature. Its `swim_mount` does not appear in water_roster.json, so it
  is not a swim mount under the current check. I did not use it because the clause's intent
  is "no owned swimmer", and the Ground starter is the one the project's typical five uses.

## Per-route results (with the original five)

| route | hops | worst min stamina % | all hops PASS | assertions | party_size |
|---|---|---|---|---|---|
| first_shore_to_reedhaven_sheltered | 1 | 31.35 | yes | 68 | 5 |
| reedhaven_to_brine_steps_sheltered | 2 | 75.59 | yes | 98 | 5 |
| brine_steps_to_shellwatch_sheltered | 2 | 81.89 | yes | 98 | 5 |
| shellwatch_to_tidal_cradle_sheltered | 2 | 73.03 | yes | 98 | 5 |
| tidal_cradle_to_salt_crown_sheltered | 5 | 38.54 | yes | 192 | 5 |
| salt_crown_to_sluice_isle_sheltered | 5 | 44.09 | yes | 192 | 5 |
| sluice_isle_to_veilfall_sheltered | 7 | 30.14 | yes | 254 | 5 |

Per-hop lines (min stamina %):

- first_shore_to_reedhaven: 31.35
- reedhaven_to_brine_steps: 75.83 / 75.59
- brine_steps_to_shellwatch: 82.03 / 81.89
- shellwatch_to_tidal_cradle: 73.31 / 73.03
- tidal_cradle_to_salt_crown: 38.54 / 57.25 / 57.95 / 57.25 / 38.59
- salt_crown_to_sluice_isle: 44.09 / 63.09 / 63.88 / 63.09 / 44.14
- sluice_isle_to_veilfall: 30.14 / 49.32 / 49.32 / 50.02 / 48.81 / 49.27 / 30.37

On every hop, pinned_min_efficiency was 1.0000 and final_health was 100.000.

These numbers are identical to the empty-party run. That is expected: human swim drain
(`swim_controller.gd` / `swim_state.advance`) does not read party composition. This run shows
that directly, with the five present, instead of arguing it.

## Fixtures, stated honestly

**Party.**
- `ORIGINAL_FIVE` is granted into the fresh game's real `Game.party` through
  `PartySeam.add()`. Each creature is built with `CreatureSpecies.spawn()` + `set_level()`,
  the same path `adopt_starter` and `peer_runner.gd` `party_grant` use.
- The party was not earned through play. It is not loaded from an S3 save. The committed S3
  proof save (`tools/net/proof_saves/host_meadows_stormwood_route_open`) has an empty party,
  so it could not supply one.

**Assertions at setup.**
- The real party is bound and empty before the grant.
- Every player skill (running, catching, riding, swimming, flying) is level 0.
- Each species is installed and is not `water_*`.
- Size is 5, `members().size()` is 5, and `is_full()`.
- Each member's species and level match the fixture.
- No member is a compatible swim mount.
- The production `RidingController` and `MountedSwimming` nodes exist, so the unmounted
  checks cannot pass vacuously.

**Assertions at every hop start and every hop arrival.**
- The party is still exactly the same five species in order.
- No member is a compatible swim mount.
- `RidingController.is_mounted()` is false and `mount_body()` is null.
- Any deployed ally is not a compatible swim mount.
- `MountedSwimming.body` is null, meaning no active swim-mount body.

**Unchanged from the existing every-hop mode.** All of its assertions still run.
- One position write per hop, onto the hop's dry start anchor. Later hops' real arrivals
  were 0.35–0.43 m from that anchor, and the limit is 1.0 m.
- The player stands on dry land until stamina is full. regen_frames was 0 on every hop.
- `max_stamina` is 100.
- Swimming XP is cleared after each movement frame, so drain stays at level-0 efficiency.
  The minimum efficiency is asserted to be 1.0.
- The route's `required_departure_flag` is set as a fixture. This does not prove the story
  objective was earned.
- Steering: a zigzag commanded to 1.155× the authored hop path, asserted to be between 1.14
  and 1.17 of the path. Against the straight chord it reaches up to 1.228×.
- Movement uses real `move_forward` input.

**Not covered here:**
- The optional routes (lantern_cove, gull_rest). See the earlier report; both fail for an
  unprepared level-0 human, and they are labelled optional.
- Combat pause, reload and co-op state across hops. Those belong to other F12 clauses.
