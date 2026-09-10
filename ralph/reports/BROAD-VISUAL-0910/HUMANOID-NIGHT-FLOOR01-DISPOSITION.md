# Humanoid night readability — floor01 disposition

## Result

Hold and withdraw. The `0.04` playable-character additive floor reached the
production material pipeline exactly as intended, but fresh production frames at
First Shore and Gull Rest show no meaningful improvement to the trainer's lower
body at night. Raising the same constant floor would repeat the failed mechanism
and increase the established risk of a self-lit actor.

The candidate made no global exposure, contrast, environment, camera, mesh or
scale change. Its exact production patch is retained at
`.artifacts/broad-visual-0910/humanoid-night-floor01-held.patch` (SHA-256
`99800DCD893D3E332C8194321BE43EDDE2034A8DB893F187B8A73A11943A30EF`).
`git apply --check` succeeds against the withdrawn tree.

## Production source finding

The production local player resolves `appearance_id` in
`scripts/player/trainer_model.gd::_ready()` and builds that config through
`scripts/characters/character_model.gd::build_from_config()`. The default
`trainer` and selectable `kael`, `sera` and `lyra` blocks had no
`emission_floor`. `character_model.gd` therefore resolved `0.0`, left their
plain-PBR body materials outside the additive-floor path, and gave
`world_look.gd` no opted-in player material to update. Ranked Team Tether NPCs
are different: `npc_ranks.gd::config_for()` supplies their existing `0.18`
floor.

Floor01 added `0.04` to each playable block and included the floor in the shared
material cache identity. The existing night environment scales a character floor
to `0.5`, so the player's effective night add was `0.02`, versus `0.09` for a
ranked NPC. The value was deliberately small because the earlier night-grade
record already rejects bright, daylit-looking actors in a dark world.

## Pipeline evidence

The local assistant launched the probe once outside the coordinator's exclusive
Godot guard. That run exited `0` and printed `41 failures=0`, but wrote no receipt;
it is recorded only as a process mistake and is not acceptance evidence. Its
approximate interval was `2026-09-10T02:33:12Z` to `02:33:14Z`.

The coordinator reran the same tool under the guard and retained the authoritative
receipt at
`.artifacts/broad-visual-0910/runs/character-night-pipeline-root-first/result.json`:

- started `2026-09-10T02:39:05.9745282Z`;
- ended `2026-09-10T02:39:09.6947755Z`;
- exit code `0`, no recorded errors;
- console: `CHARACTER_NIGHT_READABILITY checks=41 failures=0`.

The probe builds all four installed playable rigs and inspects their actual body
materials. It proved additive operator and `0.04` colour, day scale `1.0`, night
scale `0.5`, already-built material propagation, distinct cache entries for
different floor values, unchanged non-emissive Grandpa, and the unchanged ranked
NPC `0.18` floor. The diagnostic remains local and untracked at
`tools/probe_character_night_readability.gd`; it is not production source.

## Visual evidence

The candidate production Water catalogue is
`shots/catalogue/water/broad-clump-candidate03/`: 12/12 frames, capture
`2026-09-10T02:36:51Z` to `02:37:48Z`, NVIDIA Compatibility renderer, no manifest
failures. In both neutral reviews F01/F02 are candidate day/night and F03/F04 are
the earlier comparison day/night. Other concurrent ground/HUD work is visible,
so the reviews separately state their humanoid finding rather than treating the
whole pair as an isolated material A/B.

- `JUDGE-FIRSTSHORE-GRASS03.md`: no meaningful character-legibility preference.
  Both nights retain the pale collar and forearms while the dark head, trousers
  and feet blend into terrain.
- `JUDGE-GULLREST-NIGHT01.md`: no meaningful humanoid-readability preference.
  The night frames preserve essentially the same dark outline and loss of garment
  detail. The judge explicitly asks for selective readable planes on the pack,
  head and legs rather than a brighter night.

The candidate also produced the complete 20/20 Meadows catalogue at
`shots/catalogue/meadows/broad-clump03-night-floor/`. That breadth does not
override the two fresh blind no-change findings and does not earn an acceptance
claim.

## Disposition and next mechanism

The four playable `emission_floor` entries, their explanatory config comment and
the cache-key change are withdrawn. `data/config/art.json` and
`scripts/characters/character_model.gd` have no remaining diff from this lane.
The diagnostic tool remains untracked as requested.

The Gull Rest failure frames make one materially different follow-up worth an
isolated probe: a player-only, cool rim term using the existing
`StandardMaterial3D` rim properties, with its own time curve (`0` by day, bounded
on at night). The visible defect is the loss of trouser and boot contour against
dark ground. A view-angle rim can put signal on the mesh boundary without lifting
the world grade or adding constant light across every texel. It must be tested
first under the shipped Compatibility renderer on the default trainer and one
alternate playable body; the useful bar is separated legs and boots in the Gull
Rest/Meadows crops with no bright halo or flattened torso. No new round is
implemented here, and a higher additive floor is not proposed.
