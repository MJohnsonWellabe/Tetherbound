STATUS: ready (land; capture-only, no score claim; put F39#21 on the GPU list)
BRANCH: tb/item-f39-21
HEAD: see git log

# F39#21 P2-103 victory hierarchy capture fix (LANE-MESHY, 8 Nov)

- job.json F39#21's three repros (Venn win, Venn aftermath, Nerissa win) add the disclosed `--verified-victory-lifecycle --expected-resolution=1920x1080` and drop `--render-only-saves`. Without the flag, phase2_capture_tidewake_fights.gd never writes win/aftermath frames; the lifecycle mode also refuses `--render-only-saves` (it needs continuous rendering) and needs the expected resolution.
- Verified on CPU (llvmpipe, 1280x720, the other resolution the mode accepts): Venn fight won at 98 s, `tidewake__fight__venn__win.png` written and valid (the "Officer Venn defeated / reward" panel over the full exploration HUD, i.e. the row's defect). The aftermath phase was rejected on CPU only: one software frame took >3 s, so it was checked 4.3 s after the win, after the reward banner had naturally expired (the tool requires the same receipt still showing). On GPU the 1 s gap holds.
- CPU note: continuous rendering at 1080p reached only 75 s of fight in 28 min; use the GPU for this row.

# Ride-along: F41#16 frame id (coordinator 8 Nov)
- job.json F41#16: `stormwood__fight__hollows_long__hollows_alpha-i13` -> `...-i12`. On CPU the hollows_alpha fight writes i10-i17 (it runs longer), but on GPU it ends after i12, so i13 never exists there; i12 is the last in-fight frame on both. Nothing else in that row changed.
