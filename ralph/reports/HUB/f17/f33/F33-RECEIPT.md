# F33 Creature gear and trainer gear — lane A receipt (tb/f17)

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 0 | Harness and Charm in four tiers, +1..+3 | PASS (unit) | `test_creature_gear` 7/297: tiers, slots and +0..+3 chains; real `stage_core` equip/upgrade; refusals; prepare applies gear once |
| 1 | Gear shows as a trim/glow accent | PASS (code-blind judge, r4) | `f33-accent-r4/judge.md`: by day and night, front and side, a bare creature is distinct from the four tiers (gold/green/blue/violet straps); reads as harness trim; face clear; no red. Path: r1 slab (PARTIAL) -> narrow trim with tier-scaled glow -> bands moved off the face -> side recapture. Bound to the local deployed body (`companion_presence`); `gear.json` `visual_enabled` now true. Not shown: other players' creatures (no record held), the charm as a separate visible piece. |
| 2 | Boss sims per tier pass C2 | Open | Next after the landmark follow-up (coordinator order) |
| 3 | Trainer gear mitigates real hazards, each tested | PASS | See "Hazards" below |
| 4 | Pouch tiers extend Tether Commands; gear persists, personal in co-op | BLOCKED on F24 | `tether_commands.json` `runtime_enabled` is F24's flag (coordinator ruling). Gear persistence is on the character record; two-peer gear smoke pending |

## Combat hooks (coordinator scope a)

- **Charm (0b59046f):** the Charm is frozen into the host-accepted action from the admitted record.
  - Move power is scaled once.
  - Ultimate gain is credited by the host and capped at 1.52.
  - Tests: `test_move_commit_runtime` 10/72; `test_creature_gear` (real freeze → `host_move_profile`).
- **Harness defence (45cc5c3b):**
  - Guests: the host card reads the admitted record.
  - Solo and host-own creature: reads the owner's own record.
- **Harness max HP:** not yet applied, because the portable HP must stay intrinsic.

## Hazards (coordinator scope c; independent review `../review-f33-hazards.md` APPROVE-WITH-NITS, nits fixed)

| Hazard | Production caller | Bare → with matching set | Proof |
|---|---|---|---|
| Falls | `player_controller._armor_defense` → `apply_landing` | (pre-existing) | `test_player_hp` |
| Storm (lightning) | `stormwood_lightning._receive` | (pre-existing) | `stormwood_lightning_cases` |
| Storm static (Dynamo) | `stormwood_dynamo._apply_local_hazard` | 8 s → 5.78 s (2 pieces) → immune (full set, as lightning) | `smoke_f33_trainer_hazards` |
| Cold heights | `player_controller._cold_regen_scale` → `vitals.tick` | regen ×0.65 → ×0.82 (Skyglass) | `smoke_f33_trainer_hazards` (real physics frames; mutation-checked) |
| Drowning (pond submersion, `water_hazard.json`) | `water.gd _apply_hazard_damage` | 10 → 6.8 (Tidesteel) | `smoke_f33_trainer_hazards` |
| Drowning (swim) | `swim_controller.physics_step` | 4.00 → 2.72 hp | `smoke_f33_swim_hazards` |
| Currents | `swim_controller.physics_step` | 6.00 → 4.08 m/s | `smoke_f33_swim_hazards` |
| Hazard terrain (Stormwood charged ground; owner RD-14) | host `stormwood_lightning._tick_charged_ground` → receiver `_receive_charged_ground` (`stormwood_charged_ground.gd`) | 2 hp per 1 s tick; never below a 30% floor; Stormglass 2.00 → 1.20 per hit; Rootiron reduces it too | `test_stormwood_charged_ground` 2/7; lightning fixture 54/54; **two-peer ENet** `smoke_net_stormwood_charged_ground` (render 37325105092, 46/46): guest −12.0 over 6 hits, host 0; Stormglass −1.20 vs −2.00 per hit; 32 → 30.00 at the floor; swapped: host −12.0, guest 0 |

**Player-visible effect.** Enabling hazard mitigation (`gear.json` `hazards_enabled`) also activates the authored Upper Cloudreach cold zone. Stamina regenerates at ×0.65 there. It has no meter and never drains, and Skyglass travel gear eases it. The coordinator confirmed this matches the spec ("cold heights" is a zone effect, never a meter).

Recorded review items, not done:
- No in-world cue for the cold zone.
- The zone bounds have not been walked in Cloudreach.
- Tidesteel's `swim_stamina_reduction` stat is unused.
