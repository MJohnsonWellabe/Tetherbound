# LANE-CIFIX: ready to land

Branch `tb/cifix` (from main `f5263ebc7`), head `8d4d0804`. Four commits. All
repros were run locally on the pinned engine (Godot 4.7.stable, `tools/cloud_setup.sh`).

| # | CI failure | Verdict | Fix type |
|---|---|---|---|
| 1 | verify-regions-relay (meadows) / Verify art, `smoke_art.gd` | Fixed: one real game bug, plus test expectations that were outdated against the 1 Nov owner direction | game + test |
| 2 | verify-regions-relay (tidewake) / return shortcuts | Fixed: game-side catalogue idempotence | game |
| 3 | verify-multiplayer-shard (9), `smoke_net_stormwood_livewire.gd` | Root cause fixed. The timing window is still marginal on a loaded runner (see below) | harness |
| 4 | verify-multiplayer-shard (12), `smoke_net_shared_boss.gd` | Not chased: it passed on the coordinator's re-run (job 131401459559, attempt 2) | none |

## 1. smoke_art: shiny, alpha and rarity checks

**Real bug (game fix, `scripts/creatures/creature_body.gd`).**
- `_night_floor_material` shared one floored material per `species|resource_name`.
- Every tier rim copy is named `*_field_rim`, whatever its strength. So the first body of a species fixed the rim for every later body of that species: a rare spawn re-rimmed every uncommon, and an uncommon spawn made rares read as uncommon.
- It hits the non-self-lit remakes (trailpup, mudsnout and others).
- The fix adds the rim state to the cache key.
- Evidence: with the fix reverted, the updated smoke fails with `rarity tier check: rim strength is not a monotonic ladder (common 0.00, uncommon 0.14, rare 0.14)`. With the fix it passes with `common 0.00, uncommon 0.14, rare 0.26`.

**Test expectations that were wrong against current owner direction** (stated explicitly, as the brief asked). The owner turned all 49 remakes ON on 1 Nov 2026.
- **Terrapup shiny.** The owner1101 remake has no shiny repaint on its own UVs; the old mesh's repaint uses different UVs. Its shiny wears the P2-030 surface-finish hue-shift pass (`creature_surface_finish.gdshader`, `shift_enabled`), which is the designed fallback. The check now accepts that pass as the shiny tell, but only when the plain body does not wear it.
- **Paddlenewt repaint and burrowback alpha.** Neither remake carries a repaint. The checks move to bramblebun, whose owner1101 remake ships authored `_shiny.png` and `_alpha.png` repaints, and the swaps are verified to happen (`*_Image_0_shiny.png`, `*_Image_0_alpha.png`, rim and aura).
- **Rarity ladder subject.** #878 gave terrapup `field_rim 0.25`. By design (`max(field, tier)`) that outranks the uncommon rung. The subject moves to trailpup, which has no field rim. Trailpup also goes through the night floor, so this check now guards the bug above.

Before: 4 `art FAIL` lines, exit 1. After: exit 0, with these lines:
`shiny … (surface-finish hue shift)`, `shiny repaint … bramblebun swaps to *_shiny.png (albedo + emission)`, `alpha presence bramblebun alpha: *_alpha.png + rim 1.00 + idle aura`, `rarity tiers trailpup … 0.00/0.14/0.26`.

**Follow-up for a visual lane (not an owner decision):** most remakes, including terrapup, paddlenewt and burrowback, have no authored shiny or alpha repaint. Their shinies use the hue shift and their alphas use rim, aura and size only.

## 2. Tidewake: "Water species catalogue accepts the Aquaryn fixture"

- **Cause.** `CreatureSpecies.table()` registers the Water roster and then applies model and scale flags to the borrowed source species (paddlenewt, ripplet). Re-merging the finished table (the smoke does `CATALOG.merge_catalogue(SPECIES.table())`, as five other smokes and a probe do) re-derives `water_tidecoil` and `water_torrentoad` from the flag-mutated sources. It then refuses them as overwrites: `Refusing to overwrite existing species: water_tidecoil, water_torrentoad`.
- **Fix (`scripts/creatures/water_species_catalog.gd`).** An entry this catalogue already registered for the same board id (`water_board_id == id`) is kept. Any other occupant is still refused, and the unit test for that case still passes.
- **Before:** `FAIL: Water species catalogue accepts the Aquaryn fixture`, exit 1.
- **After:** the full CI step (`--case=reedhaven_maintenance_ramp,shellwatch_pump_return_channel,deep_watch_current_cut`) exits 0. `test_water_species_catalog` passes (8 tests, 364 assertions).

## 3. Stormwood Livewire net smoke

**Cause.** #878 (land-batch-32, 9 Nov) changed two things the smoke relied on:
1. Charged moves cost a full Energy bar, and Energy comes only from landed quick hits. The smoke fired charged moves with zero Energy, so every move_start was refused (`insufficient_energy`, visible in peer-1.log) and nothing ever landed. Every failure in CI run 43270882948 follows from this; CI's log matches my local "before" run exactly.
2. Under move_start authority, the host anchors the lock at the move start: wind-up plus recovery, 0.9 s. The 1.2 s cooldown that Livewire scales is the per-slot cooldown. The fixture also waited 66 frames (about 1.1 s) between start and strike, so the deadline had passed before any sample.

**Game behaviour is correct:** Livewire's 0.75 still applies, through the per-slot cooldown. Harness and test changes:
- **New host-only fixture `stormwood_hosted_fixture_energy` (disclosed).** It banks Energy and refills Wind, and is applied outside the timing windows.
- **Probe `deadline_ms`** is now the later of the hosted lock and the per-slot cooldown. The probe also exposes `last_started_action`.
- **Start→strike wait:** 38 frames, which covers the 0.45 s wind-up.
- **Late detection and refusal witness.** "Was the early action late?" now keys on the admitted start. The refusal is witnessed by HP plus the admitted start, against the sample taken just before the send. `seq` also ticks on unrelated host bookkeeping.
- **Missed samples.** A missed window sample is never sent against. It re-arms on a fresh baseline. Attempts go from 3 to 6; the 180–350 ms window is unchanged.

**Evidence.** Before: 11 failures in the same pattern as CI. After, on this 4-core container:
- 2 of 5 runs pass every check (logs `livewire_r6_2`, `livewire_final_1`).
- The other 3 pass every functional check: Energy, Livewire 0.75 accepted after its deadline, the release restoring the authored multiplier, refusal codes `cooldown` and `recovering`.
- Those 3 fail only because in 6 attempts no early action landed inside 180–350 ms before the deadline. Here the sample→arrival latency is 200–500 ms, and the host runs at about 10–15 physics fps.

**Open item for the coordinator:** this shard needs its landing CI run as the real verdict. If CI also misses the window, the options are:
- widen the window, which weakens what the release block proves; or
- add a host-side scheduling hook.

I tried a client-scheduled early send, then reverted it. The host processed the early start 500–700 ms after the client spacing implied, so it did not help. That suggests a host-side delay right after a landed charged hit, worth a look if this stays red. Neither option needs an owner decision unless the window semantics change.

## Checks run
- `tests/smoke_art.gd`: exit 0, plus the negative control above.
- `tests/smoke_water_loops_shortcuts.gd` with the CI step's three cases: exit 0.
- `run_tests.gd --only=test_water_species_catalog,test_meadows_cause_flags,test_creature_coat_flags`: 20 tests, 0 failed.
- `tools/net/run_net_smoke.sh stormwood_livewire`: see §3.
