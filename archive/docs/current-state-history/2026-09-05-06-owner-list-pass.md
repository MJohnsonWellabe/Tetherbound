# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Owner-list pass — 2026-09-05/06 (`claude/second-biome-completion-n1deay`)

The owner's 2026-09-05 list (`docs/owner/OWNER_PLAYTEST_2026-09-05.md`, 28 items plus
the 2026-09-06 addendum) worked on one branch; every row below was verified by the
named smoke on this box (Godot 4.7-stable headless) before its commit. "Landed" means
on the branch with a green named test; nothing here is an Ally reproduction.

| Item | Status | Evidence |
|---|---|---|
| CI on the final merged head | **green** (run 4450 on a1842cf9, the Cloudreach lane close-out merge: unit shards 1-4 and every verify shard green; only the two KNOWN RED jobs red) | https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34026997741 |
| CI on the merged branch | **green** (run 4449 on 9ca36cd2: unit shards 1-4, every verify shard incl. stronghold, warrens, cloudreach_arrival_walk, gate_e_finale; only the two KNOWN RED jobs red) | https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34021074221 |
| Cloudreach did not build on `main` (typed loop over `times` threw in `_ready`) | **fixed** (ported from the multiplayer lane, 18ea9410) | `smoke_cloudreach_foundation` OK (was SCRIPT ERROR at cloudreach_world.gd:138) |
| OP-0905-14 stronghold: fight every NPC to advance | landed | `smoke_stronghold` gates all four passages blocked→open; red on old data |
| OP-0905-17 combat camera too zoomed in | landed | `smoke_combat_camera` near=6.00 far=8.75 m; base 4.6→6.0, fov 62→68 |
| OP-0905-12/-26 ride Terrapup; stag offer vanished | landed | `test_rideable_roster` 8/8, `smoke_riding` incl. build-ghost interruption (seen red) |
| OP-0905-22 fall forever (Cloudreach) | landed | `smoke_cloudreach_fall_recovery` (seen red without the mount) |
| OP-0905-08/-10/-11 Gil's camp rest; Warrens 2–3 then guardian then alpha; alpha looked plain | landed | `smoke_authored_camps`, `smoke_warrens` (alpha 1.30x, tinted coat, den holds only the guardian) |
| OP-0905-13 bridge: guardian walks up and challenges | landed | `smoke_south_bridge_challenge` (seen red), `smoke_traversal` OK |
| OP-0905-20/-21 loading indication; menu teleport to Cloudreach | landed | `smoke_realm_teleport`, `smoke_settings` 34 destinations, `smoke_cloudreach_transition` |
| OP-0905-15 no portal; rift collapse is the crossing | landed, **D110** | `smoke_boss` SG44 probe crosses 54.5 m after the flag, blocked before; `smoke_cloudreach_transition` walks the span |
| OP-0905-04/-05/-06 band 1 findables; roadside life; pond alpha | landed | 26 pickups (`_probe_band_density` 26/26 sites OK, worst gap 72 m); road gap 119→91 m; `test_alpha_pins`, `test_spawns_data` |
| OP-0905-18 when/how the pig evolves | landed | `test_evolution_discoverability` 15/15; `smoke_evolution` |
| OP-0905-27 map shows both realms | landed | `test_map_realm_view` 7/7; map suites 109/109 |
| OP-0905-01 inputs/keyboard at the beginning | **partly**: name prompt dropped the first keystroke with a joypad connected — fixed; HUD buff chips were back in the mouse path (`smoke_mouse_look` red on main) — fixed | `smoke_early_input`, `smoke_mouse_look` PASS |
| OP-0905-02 direct build route cannot place | **not reproduced headless** | `smoke_build_direct_routes` drives LT, keyboard B, hammer+interact with real events: all place. Headless cannot hit-test a real mouse click on a catalogue cell. Open for the Ally |
| OP-0905-03 Bramblebun colour | landed, render-judge pending | soft-knee ceiling 1.75: rendered mean 1.73→0.85; `smoke_creature_field_brightness` |
| OP-0905-07 Gil's face | **asset limit**, recorded | `docs/art/HUMANOID_ASSET_INVENTORY.md` §Known limit; needs owner reference art |
| OP-0905-16/-19 machine turned; Hall torches | landed; six judged interior rounds (`ralph/reports/HALL-STAGING-0906/`, verdicts 2/3/5) | `smoke_stronghold`: facing -101.2°, doorway sightline 13.6 m clear; 16 wall torches + 2 arena-door baskets. Root causes found by the judge loop: the Compatibility caps (8 lights per object, 32 renderable) were dropping the torches on the one-slab-per-chamber floors → 16 / 64 in project.godot; ACES' toe at night swallowed 6.5-energy torches → 12; flames 0.15 m proud sat behind 0.36 m pilasters → 0.6 m proud, 1.6 scale; warm-on-warm fill → slate ambients. Floor-band medians (Rec.709) approach 4.5→21, arena 0.6→19, chamber 3.8→12; round-5 verdict passes the key-art question for approach and arena, chamber still teal-keyed (installed machine GLB emissive, art). `test_stronghold_warden_arena` 35/35 |
| OP-0905-09 Warrens exterior | lane `claude/warrens-exterior-0906` closed out and merged (rounds 4–6 + dome closure; `REPORT.md`), then the earth-clad first bay (4e90b7e3): the mouth chamber wears the bank's earth on its inner walls, ceiling and floor and carries no masonry, answering the last exterior read the judge kept naming (grey jambs and a pale slab through the arch). Round-6 verdict still "no" on the bar questions, resting on the Meadows-wide ground palette and the interior's stone-box vocabulary (out of this item) | `smoke_warrens_fixture` OK; `smoke_warrens` green (CI 4446 regions shard); `ralph/reports/WARRENS-EXT-0906/` incl. `_sheet_earth_clad_mouth.png` |
| OP-0905-24/-25 Cloudreach holes, sinking | landed (lane `claude/cloudreach-ground-0906` merged at 9137ef5c; ground truth re-run green on the merge) | `smoke_cloudreach_ground_truth`: 0 holes, 26 sinks/floats of 30,922 samples (0.08 %; was 0 / 819 of 3,782 = 21.7 % on the WIP); `smoke_cloudreach_arrival_walk` OK, `smoke_cloudreach_summit_road` PASS, `smoke_cloudreach_causeway_crossing` PASS; `ralph/reports/CLOUDREACH-GROUND-0906/REPORT.md` |
| OP-0905-23 / OP-0906-01..04 Cloudreach look | lane closed out (rounds 1-2 judged); **bar questions still "no, narrowly" / "no"** | `ralph/reports/CLOUDREACH-GROUND-0906/REPORT.md`, `JUDGE-after.md`, `JUDGE-after2.md`. Landed: rope rails, moorings, strata shader, settlement recolour, roadside rock retint, near-square crown rings, shoulders 2 cm under crowns. Open (art/atmosphere, not scene tweaks): altitude/horizon/haze/cloud-sea below the cliff edge, the tan hoodoo rock kit vs the board's grey-green granite and 8 m "cliffs", the dome reading as scaffold (owner design call: dressing vs translucent membrane) |
| OP-0906-05 aviary stronghold | landed in the world (D111 hookup) | `smoke_cloudreach_finale` PASS, `smoke_cloudreach_production_integration` PASS, `smoke_cloudreach_summit_road` PASS, `smoke_cloudreach_aviary` PASS |

Process finding (OP-0906-06): a Meadows world boot is ~3.3 GB and 100 s uncontended; four
at once OOM-kill each other on a 15 GB box. A 3-slot throttle now wraps `godot` here, and
lanes iterate with `--check-only` parse checks (2 s), flat-world fixtures (seconds) and
Cloudreach's own scene (~36 s), booting the Meadows once at the end.
