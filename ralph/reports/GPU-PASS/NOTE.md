# GPU-PASS lane note (owner's Windows desktop, GTX 1060 3GB; 21–22 Oct 2026)

## TO COORDINATOR: FINAL READY tb/gpu-pass (the commit that adds this note; its SHA is in my last message)

Land on main only the files in `LANDABLE.txt`: verdict .md, key and score .json, and one `_sheet` per row, nothing over about 200 KB (owner size rule). Everything else stays on tb/gpu-pass.

**Fix branch:** `tb/vfx-launch` at **b175bda5c** is pushed, with the owner's approval in this chat. It holds the F25#4 launch-stall fix and its hardened test. It is not landed; that is yours.

### Results by row (yardstick-mapped, confirming batches unless noted; bar 7.5)

| Row | GPU result | Verdict |
|---|---|---|
| F25#4 four-creature frame rate (Medium) | Before the fix: launch frame 155–350 ms. **tb/vfx-launch:** launch 16–30 ms cold, 10–23 ms warm, **0 frames over 33 ms in 24 volleys**; budget caps at 384 under over-cap load. `F25-4/FIX.md` | **Meets the line once tb/vfx-launch lands.** Low's cold launch is still 64–78 ms. |
| Forward+ grade (Medium/High darker and greyer than Low) | Cause: depth fog plus exposure 0.60 under ACES. Recipe: fog ×0.5, exposure ×1.333, saturation ×1.2. **tb/fplus-grade cff972b7e** reproduces it on GPU; factors are applied exactly once and Low is untouched. `forward-plus-grade/`, `forward-plus-grade/branch/` | Verified. The Meadows re-measure at fog 0.001 waits for #712. |
| F08#3 Cloudreach settlements | c14/a14 at ff3cc7cfa: 5.75 vs 5.72 (weather-confounded). **r17 at ef2db84c, weather pinned clear:** candidate **6.57** vs control 5.20, at Medium and High | REOPENED |
| F22#4 Riverwatch r13 | Low **6.71** (control 5.11); Medium **5.85** (control 4.83). The Medium "ghost" boss is the boss-aura cue (an additive rim overlay plus a 3.0-energy cyan omni light) on Forward+. `F22-4/ghost-split/GHOST.md` | REOPENED |
| F36#0 creature roster | Owner-style prompt (e188bc862): installed mean 6.27 → **6.75**, recipe mean 6.55 → **6.96**. Best: Meadowhart recipe 7.49, Ripplet recipe 7.46 (its old 7.89 confirmation does not hold under the new prompt). r3 candidates: Riverdrake 7.39, Meadowhart 7.22–7.28 | REOPENED (none at 7.5) |
| F10#2 Stormwood named-fight camera | Medium 5.52, Low 5.39; occlusion FIXED ×15 at Medium | REOPENED |
| F04#6 Meadows trainer aftermath | 5.92 | REOPENED |
| F29#3 Stormursa | 7.00; the torn faint mesh is fixed | REOPENED |
| P2-095/096 craft text and hints | Both defects FIXED; Bar A 6.72 | REOPENED (Bar A) |
| P2-018 shiny distinction | 5.88 / 5.94 | REOPENED |
| P2-094 homestead wall | 5.96 / 5.94 | REOPENED |
| F39#0 Tidewake recapture | 240/240 frames delivered at Medium; no landscape row at 7.5 | Recapture delivered; rows REOPENED |
| Meshy/GLB metallic audit | The file-level metallic 1.0 default is already corrected at load (`character_model.gd`, `imported_materials.make_dielectric`). Nothing renders as metal. `meshy-metallic-audit*.{txt,md}` | Closed, no issue |

### Pipeline notes for other lanes

- **Line endings break overlays:** on this machine `core.autocrlf=true` checks `.patch.txt` files out with CRLF, and `git apply` then refuses them. Apply overlays from an LF copy.
- **Timing artefacts:** 1080p PNG captures and node censuses inside a timed window show up as 0.6 s "hitches". Printing, or measuring viewport render time on the launch frame, adds about 300 ms.
- **Comparing fights:** fight timelines vary between runs. Compare fight frames by state (tell or no tell), not by frame number.

## RESUME

**State at stop (22 Oct, evening):** every result above is pushed to tb/gpu-pass; tb/vfx-launch is pushed; no GPU process is running.

**Local layout:**
- `D:\tb-gpu-pass`: the sparse working checkout on tb/gpu-pass.
- `D:\tb-gpu-runs\tools\`: local runners and wrappers, never committed. Copies of the important ones are in each row folder as `.txt`.
- `D:\tb-gpu-runs\appdata-{Low,Medium,High}`: isolated preset configs.
- Per-frame outputs and judge folders were deleted after their evidence was committed.

**Open follow-ups, if a GPU lane resumes:**
1. Re-measure the Forward+ grade on Meadows Medium once #712 (Meadows fog 0.001) is on main, with tb/fplus-grade merged.
2. Confirm the F22#4 renderer-aware boss aura once Fights ships it (the same Riverwatch capture at Medium, matched tell frames).
3. Re-confirm F25#4 on main after tb/vfx-launch lands (`F25-4/f25_fix_queue.ps1.txt`, about 12 minutes).
4. F08#3: judges ask for foreground dressing, a night lighting pass and varied islets (scene work for the Cloudreach lane).

**Rules this lane ran under:**
- Push only tb/gpu-pass.
- Ask the owner before any other push, any deletion of things that are not mine, and any spending.
- Never modify or delete the old D: checkouts.
- One GPU process at a time.
- Keep at least 5 GiB (target 10 GB) free on D:.
