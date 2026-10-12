# F25#0 — about 24 effect archetypes, each with a real mesh or particle body, trail, impact and sound — CAPTURE-READY (v2 after judge FAIL r1)

systems-b, Sun 11 Oct 2026 (CT), on 66cb1f85e (tb/ev-coordinator merged). Taken over from the fights/ultimates lanes.
Data: `data/config/vfx.json` move_library.enabled = true; 24 archetypes, and every one declares body, trail, impact and sound (checked by script: no archetype is missing any of them).
Capture: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tests/smoke_move_effects_library.gd -- --batch=mastery --ranks=1 --out=<dir>`. Result: 38 cases, 0 failures, renderer gl_compatibility (llvmpipe), scope synthetic_no_combat.
Judge inputs: `sheets/sequence-NN.jpg` (24 generic archetypes) and `sheets/ultimate-NN.jpg` (7 ultimates × 2). Each sheet tiles the phases left→right, top→bottom: launch, flight, contact, impact, aftermath (ultimates: windup, travel, contact, peak, late). Each tile is 960×540, downscaled from the 1920×1080 frames to keep the repo small.
Filenames are neutral; the case → archetype mapping is in `private/results.json` (cases[] in sheet order). Do not show it to the judge.
Not covered here: the F25#4 frame-time half (needs a real GPU, Medium preset); this host is llvmpipe.

## r1 judge FAIL (coordinator 8:40 PM CT, 12/24) → fixes → v2 capture
Fixes: 05aa58331 and aaa271a8a (vfx.json and per-move vfx sizes in moves.json; per-move size overrides the archetype size).
- 14 psychic_pulse and 21 debuff_hex now travel as authored shadow-shader orbs. The hex sigil is kept on impact.
- 16 quake_ring is a low stone volley with a dust trail and impact; the move size drops 3.0 → 0.6.
- 15 root spikes, 17 slash, 18 dash and 09 wind/shove are larger. The slash uses the air-surface crescent; the dash is a shaded dust orb.
- 04, 05, 07, 17 and 18 have no flash streaks (the rejected speed lines); they now use ember, foam, debris and dust puffs.
- 22 guard_flash is a translucent shield bubble round the caster; 20 buff_aura is a large aura spiral. Both are self-targeted by design (no travel), as is 19 heal_pulse.
- 23 tether beam: thicker, with a longer gold contact glow (no_damage arrival has zero travel).
- 03 and 12 are less faint.
Effects/moves units: 34 tests, 0 failed. v2: same command at aaa271a8a, 38 cases, 0 failures. sheets/ is replaced; r1 sheets are in git history (20d194139).
