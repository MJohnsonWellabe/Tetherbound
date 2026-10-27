# b63: Thundertunnel fur value lift vs main (CPU, three judges)

On GPU F36#1 main-1024 Thundertunnel scored 6.91 with "near-black values". In CPU b62 all three judges read it as a near-black body that merges with the backdrop, with no visible eyes, and its flinch gained only +0.09.

Candidate 613b53e0f, `thundertunnel/retex/grade_value.py`:
- The game renders the ordinary vivid colourway, not the GLB's embedded albedo, so the grade works on main's vivid map (kept as `retex/main_vivid.png`).
- An earlier pass on the embedded albedo made no visible difference, which is how this was found.
- Dark, low-saturation fur gains value (x1.55, +0.03) and eases its saturation toward slate-violet.
- The blue quills, the pink snout and paws, and the storm arc emission map are untouched.

Tiles: standing, hit 050, faint 050, faint 100. Anchors: f36_0_npc:C2, f36_0_gap:C4, craft. Fit: slope 1.38, r 0.91, RMSE 0.34, **confirming**.

| | main | value lift | gain |
|---|---|---|---|
| Thundertunnel (mapped) | 5.33 | **6.43** | **+1.10** |

The defect went from PRESENT x3 to PARTIAL x3. All three judges prefer the lift.

Remaining reads, not from this change:
- The eyes are still not visible. They are a mole's tiny eyes.
- The lilac reads "a little washed and plasticky".
- The back sits about level with the trainer's head, which is borderline on the scale rule.
- The hurt and faint poses barely change the silhouette.

Call: **GPU READY** (added to CO14). The next swing for Thundertunnel is scale: grow it so it clearly stands taller than the trainer, as the scale rule requires.

Checks: `run_tests --only=colourway,shiny,vivid,thundertunnel,texture_for,storm_arc,aspect`: 26 tests, 0 failed.
