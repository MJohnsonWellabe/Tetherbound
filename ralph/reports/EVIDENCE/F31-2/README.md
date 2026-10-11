# F31#2 — Meadows (tier 1) attachments from the start; hanging a biome relic in the Shrine Room unlocks the next tier; one chosen relic power

Lane: systems-a (`tb/ev-systems-a`). Sun 11 Oct 2026, Godot 4.7-stable headless, Linux, solo host path.

| Part | Proof | Result |
|---|---|---|
| Meadows tier-1 attachments from the start | `tests/smoke_f31_station_paid_path.gd` on `228203a2` (10:43–10:44 CT): fresh world, no relic hung | PASS: `forge_meadows snapped to slot 1 of b1; Forge effective tier 1`, paid through build_place, dismantle refund, forged-intent refusal (`smoke_f31_station_paid_path.txt`) |
| Pure rules | `run_tests.gd -- --only=test_relic_hang_attachment_blueprints.gd,test_relic_power_selection.gd,test_station_attachment_gates.gd,test_crossing_hall_relic_hang.gd,...` | 95 tests / 2566 assertions, 0 failed (`units.txt`) |
| Shrine Room hang → next tier, one power, save/load | `tests/smoke_f31_relic_hang_power.gd` on `22878bca` (11:50–11:53 CT) | PASS, all 17 checks, exit 0 (`smoke_f31_relic_hang_power.txt`) |

`smoke_f31_relic_hang_power` uses only ordinary inputs after a disclosed generated start: Home Key, capsule walk, `interact` at the pedestal, and `ui_down`/`ui_accept`/`menu_cancel` in the chooser.
1. Hang the Meadows relic at its Shrine Room pedestal and choose its power in the chooser:
   - `relics_hung ["meadows"]`, and the relic left the satchel;
   - `attachment_recipes` = exactly the four Tidewake attachments;
   - the `relic_hang:meadows:<cid>` receipt is held;
   - one active power: `meadows`.
2. Re-open the chooser at the pedestal and choose the same power: still the same four recipes and one power.
3. Hang the Tidewake relic and defer the choice:
   - the Cloudreach column is added with no duplicates (8 recipes);
   - Meadows stays the only power.

   Then choose the Tidewake (`water`) power: it REPLACES Meadows, and exactly one is active (`{"active_id":"water"}`).
4. Production `save_game(0)` → `load_game(0)` → world rebuild (runner `_reload_transition`): relics_hung, all 8 recipes and the single `water` power survive. No flags, party or items are lost.

## Test changes (coordinator-approved 11:16 AM CT)
- `tests/helpers/f49_portal_travel.gd::hang_relic(biome, power="")` + `settle_power_chooser()`. After a hang the Shrine Room deliberately opens its one-power chooser (`crossing_hall.gd` ~740–760), and the helper never closed it. Every `--enter` boundary generation therefore failed (`generator_before_helper_fix.txt`: input owner RelicPowerPanel). Default: defer with `menu_cancel`, wait ≤300 frames, `_fail` if it doesn't close. With a power: choose it with `ui_down`/`ui_accept` and require `active_id == power`.
- New smoke `tests/smoke_f31_relic_hang_power.gd`. Coordinator-requested scope; a new harness disclosed as part of this criterion, because no existing test chose a power through the chooser.
- New generated profile `f31_relic_power` in `tests/fixtures/earned_saves/generated_boundary_profiles.json`: the `tidewake` profile plus the Tidewake relic held, disclosed in the profile itself. No hang, power or attachment receipt is fabricated.
- The smoke approaches the Tidewake pedestal from the room's centre (`activate(..., via)`). From the Meadows pedestal next to it, the helper's 2.5 m stop left Meadows the winning provider.

## Not proven here
- **Rejoin:** the existing two-peer smoke `smoke_net_homestead_station_craft` (F31#5) seeds `relics_hung` and chooses the guest's power AFTER its rejoin. It does not show a hung relic or a chosen power surviving a rejoin. Units `test_relic_power_selection` cover save/reload and title load; this smoke covers the production save/load.
- `generate_boundary_save --enter=...` was not re-run after the helper fix. Its default deferral path is the same `settle_power_chooser()` this smoke's step 3 exercised.
- Earned campaign route, visuals.

Verdict: PASS (rejoin of the power not covered by an existing net smoke; reported).
