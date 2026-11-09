# Nerissa's second creature cannot be admitted (GPU F39#21 "no clear seat after 395 attempts") — LANE-MESHY, 9 Nov

## Reproduced on CPU, so it is a game bug, not a capture-stand issue
- `tools/phase2_capture_tidewake_fights.gd --trainer=water_trainer_nerissa --verified-victory-lifecycle --expected-resolution=1280x720` (Compatibility, 1280x720, seed 2042): after Cannonback falls, the send-out of creature 2 (Mirejaw) is refused at 34.4 s, exactly as on GPU (33.3 s):
  `Combat admission refused: { body: TrainerCreature_water_trainer_nerissa_2, spot: (1807.0, 40.0, 4254.98), corner: (1810.74, 40.0, 4260.39), reach: 11.38, clearance: 0.6, radius: 10.2, stage: rendered_radius, clear_seat_search_exhausted: true, clear_seat_attempts: 395, last_candidate_failure: { body: AllyCreature, shape: oriented_render_box, collider: WaterVeilfall/VeilfallInterior/@StaticBody3D@3187, stage: solid_overlap } }`
- Every player who fights Nerissa reaches this: the next creature always spawns 3 m from her toward the player (encounter_director.gd `_send_out_spot`) after the player is reset to the battle anchor, so the arena always opens at the same place in the Heart Chamber.

## Why it cannot fit
- The ring there is capped by `water_veilfall.json arena_bounds` (heart_chamber, `side_margin_m` 5.0 inside the side walls) to about 10.2 m. Mirejaw's rendered body reaches 11.38 m from the centre (it needs about 12.0 m with the 0.6 m visible clearance).
- The seat search (combat_manager.gd `_find_clear_formation`) deliberately never enlarges the ring or moves its centre; all 33 offsets x 12 turns fail (rendered radius, and once turned, the ally box overlapping the interior walls).
- The two fallbacks do not apply: the open-ground ring growth (F10#2) runs only off any bounded room, and the capped slide (CARD:M2, up to 8 m) slides along the chamber, where the side walls bound the ring the same everywhere.
- Cannonback (creature 1) fits; Mirejaw (a long crocodile) does not; Riverdrake and Riptusk were never reached.
- Nerissa's position is already a four-way compromise (water_veilfall.json `_why_captain_position`): clear of the Sluice Crossing channel (z), of the central crystal occluding the camera (x 0-3 failed 8/53 frames), of the Guardian (z 108), and of the banner liners (x 17-21, `arena_bounds` r13).

## Options (coordinator or owner decision; none built)
1. **`arena_bounds.side_margin_m` 5.0 -> about 3.2 for heart_chamber** (config only): the ring becomes about 12 m and holds Mirejaw. Risk: r13's problem returns, a READER stepping toward the east wall can put the camera pivot into the camera-only banner liner. Could be paired with moving the banner liner a metre outward.
2. **Room-aware growth (code):** inside a bounded room, when every seat fails on `rendered_radius` only, grow the ring to the rendered need if the grown ring still clears the room's walls by the visible clearance (measured, not the margin). Keeps the authored margin where it is not needed.
3. **Re-seat the send-out spot for big creatures (code or config):** use the room's centred formation (`_room_centred_formation`) for trainer send-outs that fail, instead of the trainer-relative spot; the chamber's centre line has more width than Nerissa's x 7.
4. **Content:** swap Mirejaw's slot order or species for this fight (design decision).
- Recommendation: option 2 (it fixes the class of bug for every bounded room and leaves Nerissa's tuned stand alone), then re-run this repro and the Nerissa smokes.
