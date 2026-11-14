# LAND-MT-BROKENHILL: Burrow Warrens hillside, broken and rocky

**Row.** F38#30 Burrow Warrens hillside: board 6.02; G-things-redleaf on main 4.99. No-loss: F38#24 (shares walk_02 / walk_03).

**Defect (G-things-redleaf, 3/3, both sides).** "A straight-edged slab with a ruler-straight lower edge and a dark cut", and a smeared low-resolution grass texture. Ask: "a sculpted, broken hillside with rock outcrops and edge vegetation". G-floor2 follow-ups: "the straight diagonal hill-base edge and stretched grass on the steep face in walk_02, the brown slab on the left hill in route_day".

**Cause, and how I know.**
- The hill is the Meshy mound shell (`bank.hill_shell`), one smooth dome scaled to about 260 m. LANE-FLOOR2's false-colour capture (11 Nov) already showed the smooth wall in walk_02 / walk_03 is this shell, not the foundation.
- A smooth dome at that scale has near-planar flanks, so the flank meets the meadow along a straight line: that is the "ruler-straight lower edge".
- The brown slabs and stripes are the shell's own baked earth texture showing wherever a face is too steep for the meadow grass blend.
- Check: with the arm on, the same shell (no new mesh) loses the straight edge and the brown slabs in all four day frames, so both come from the shell's shape and texture.

**Change (`bank.hill_shell.broken`, flag-off code; overlay turns it on).**
1. Relief: the shell's vertices lift and drop by a world-space noise field (2.4 m, 26 m and 8 m waves). Nothing moves within 9 m of the mouth. The grass cover tufts follow the lifted surface.
2. Rock: steep faces and noise-picked patches become bedded Rock030 (installed texture, world-space triplanar, strata bands) instead of stretched earth.
3. Base line: 200 bushes, ferns and tall grass from the installed nature pack on the line where the hill meets the meadow.
- Presentation only. The shell has no collider and gains none. No Meshy credits. No red.

**CPU before / after.** `_sheet_brokenhill_off_vs_on_cpu.jpg` (left base, right arm; rows walk_02, walk_03, route_day, walk_01). 0 script errors on both sides.

**By-eye line for the GPU lane.**
- route_day: the hill shows grey rock outcrops between grass, and the two brown slabs (upper left, and the arch surround) are gone.
- walk_03: the hill's lower edge is no longer one straight diagonal; ferns and a bush stand on it.
- If the hill is still all-green with brown stripes, the overlay did not apply: hold.

**Risks and no-loss frames.**
- The mouth arch surround turns from brown earth to grey rock in route_day and walk_01. If judges prefer the earth arch, `rock.slope_up` can exclude it.
- walk_03's large near flank still carries the stretched grass texture; the relief is subtle there on CPU.
- No-loss: F38#24 on walk_02 / walk_03, and Warrens vista_dusk.
- First CPU try (rock on most faces, loose Rock_Medium boulders) read as a grey quarry with pale plastic boulders; boulders are dropped and rock is limited to steep faces and patches.
