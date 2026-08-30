# T1-VILLAGERS — audit verification (in progress)

Verifying the reported body-allocation inversion against `ralph/LAND-0830I`.

## Resolution path, traced

`trainer_npc.gd::model_config(spec)`:

- `spec.rank` non-empty -> `npc_ranks.gd::config_for(rank, spec.base)`
- else -> `character_model.gd::config_for(spec.config_key)` -> `data/config/art.json`

then `hair`/`accessories`/`tint`/`height` REPLACE, and `palette` merges per surface.

So there are exactly two body sources: an `art.json` `config_key`, or a rank
default with an optional per-trainer `base` override.

## Claim 1 — core cast shares two meshes: CONFIRMED

`data/config/village_npcs.json` + `data/config/bands/*/trainers.json`:

| Character | config_key | resolves to |
|---|---|---|
| Mira | `villager_farmer` | `villager_female_lod0.glb` |
| Oskar | `villager_keeper` | `villager_male_lod0.glb` |
| Tam | `villager_smith` | `villager_female_lod0.glb` |
| Bram (village) | `villager_keeper` | `villager_male_lod0.glb` |
| Old Bram (tournament) | `villager_farmer` | `villager_female_lod0.glb` |
| Quarry Foreman | `villager_quarryman` | `villager_male_lod0.glb` |
| Sela | `villager_ranger` | `villager_female_lod0.glb` |
| Kell | `villager_keeper` | `villager_male_lod0.glb` |
| Halda | `villager_ranger` | `villager_female_lod0.glb` |
| Rae | `villager_farmer` | `villager_female_lod0.glb` |
| Bryn | `villager_farmer` | `villager_female_lod0.glb` |
| Juno | `villager_ranger` | `villager_female_lod0.glb` |

Twelve named characters on two meshes. No third resolution path exists.

Extra finding not in the report: **Bram is two different bodies.** The village
Bram is `villager_keeper` (male base); the tournament's `old_champion_bram`
is `villager_farmer` (female base) with white hair. Same character, two sexes.

## Claim 2 — twelve bespoke bodies on walk-ons: CONFIRMED

Wilhelm/innkeeper, Nessa/inn_helper, Corin/trader, Ada/craftsperson,
Fenn/creature_caretaker, Garrick/farmer, Old Perrin/local_historian,
Tobin/lost_traveler, Maren/field_researcher, Sorrel/alpha_tracker,
Lark/courier, Ren/former_tether_member — each its own `.glb`.

## Claim 4 — `officer_b` unreferenced: PARTLY WRONG

`officer_b` IS in `art.json` and WAS wired to `stronghold_courtyard`
(Warder Solene). `T1-HALL-3` (2026-08-30, this branch's history) deliberately
removed that override along with `grunt_c` and `captain_a` inside the Hall,
because JUDGE-5 read the officer_b body blind and called it "from a different
game". So it is currently unreferenced by placement, but by a recorded
decision, not by oversight. `officer_a` doing double duty (Dell + Ness) is
confirmed.

`captain_accessory` holds no mesh at all — only two reference turnarounds
(`board_captain_a_turnaround.png`, `board_captain_b_turnaround.png`) under a
`.gdignore`. It is a reference folder, not a body.

## Open — does the swap actually improve the frames?

JUDGE-5's finding is the live risk: the generated cast may share a
cel-shaded idiom that is wrong for the four characters with the most screen
time. Measuring textures and rendering before deciding.
