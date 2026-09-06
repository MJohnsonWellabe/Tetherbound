# Water runtime wave 1 — branch evidence, chapter incomplete

Owner shipping update: remain on `ralph/water-foundation-0906`; PR69 is a draft and must not merge automatically. Main remains untouched by Water implementation. This report does not close a phase.

Parent-run evidence on the working branch, 2026-09-06 before the first checkpoint:

- `smoke_water_swimming.gd`: 16 assertions, actual 60.143 m lesson swim, exhaustion health 91.2, combat locomotion pause and dry landing. Explicit Water realm/start/resource fixtures; no key transition or complete combat claimed. Replayed after the shell-readiness API correction with the same passing result.
- `smoke_player_skills_menu.gd`: 44 checks, zero failures. Physical controller navigation and Candy consumption, whole-tier cap refusal, separate character ownership, actual CharacterSave disk roundtrip and legacy files without Skills. Biome 2 reveal is a fixture, not an ordinary gate crossing.
- Combined map/Skills/player/save checks: 37 tests, 209 assertions, zero failures; expanded Skills/catch checks: 44 tests, 236 assertions, zero failures.
- Catch math/arbitration, riding, flight and Water species adapter checks: 62 tests, 508 assertions, zero failures. These do not prove real peer transport for the new fields.
- Saved Terrain3D collision probe: two bodies 3663.618 m apart remained supported after the camera moved outside the world; maximum height error 0.000031 m. This is a physics probe, not multiplayer transport.

Terrain is thirty committed-candidate 512 m regions, one metre spacing, FULL_GAME collision. The surface is a separate shader plane with a baked height texture. Interior routes remain ungraded and cannot be credited as traversable. NPCs, encounters, pickups and harvesting remain authored data rather than live chapter content.

Skills now accumulate during voluntary running, riding, swimming and flying; successful owned catches award Catching XP. Running, Swimming and Flying affect stamina; Riding affects one movement step's turn rate; Catching affects the displayed/rolled chance. The host derives the Catching bonus from the owning trainer proxy's typed, on-change level rather than a throw-intent bonus. Live networking, handling feel and ordinary cross-biome reveal remain unproven.

Foundation CI run 34066511921: code jobs completed, with one unit shard failing because Water flag IDs had no scope declaration. Explicit world/personal declarations now pass the focused scope check locally. Other unit shards and all five existing multiplayer shards passed that foundation head. The local full foundation suite is still running; no full current-wave pass is claimed.

Six 1280×720 frames were captured through `tools/survey.sh --water` on the native GTX1060 GPU, Compatibility renderer, exit zero and no runtime errors. Metadata and frames are in `shots/water/`. No frame has passed blind visual acceptance. No Meshy mesh has been generated. Alpha, mounted swimming, docks, Veilfall, Water combat, recovery/reconnect and the relic remain incomplete.
