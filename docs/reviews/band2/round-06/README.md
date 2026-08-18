# Band 2 (Stone & Root) — round 6

**What changed since round 5.** Round 5 was flat (`HARVEST-ALL`'s density had
zero effect on these 8 viewpoints) and named two things holding convergence,
both outside the band lane: `MAT-BLOCKOUT` (landed) and `NIGHT-LIGHT` (landed
through 4 rounds, most recently `e250a2f7`, unjudged until now). Since then
`VEG-SITING` also landed (`5645a20`) — it re-sites corridor clump centres
along the trail by arc length instead of uniformly across the whole 2048m-wide
box, which is exactly the mechanism round 5's own writeup said was missing:
"retuning where clumps are *sited*... explicitly not something a band content
author edits." `HARVEST-ALL`'s density multiplier now has clumps near this
band's viewpoints to multiply, where round 5 found it had nothing.

This round did not touch band content, `data/config/art.json`'s night preset,
or any file held by another lane. It re-ran the identical 8 viewpoints against
current `main` (`dd410e7`) to see what those three landed fixes did.

**Torch check, per the coordinator's brief.** `tools/survey_band2.gd` does not
equip the torch for either night viewpoint (06, 07) — `RG22`'s new equip gate
in `torch.gd` is real, but it doesn't matter for these two frames: neither
viewpoint places the actor body in view (`_place_actor` parks it 5000m away
in XZ when a viewpoint has no `actor` key, and 06/07 both lack one), so the
torch's light was never going to be visible in these frames whether equipped
or not. Not a regression, not fixed — noted because the brief asked, and
because a future viewpoint that *does* place the actor at night would need
the survey tool to equip the torch first, which it still doesn't know how to
do.

## Measured (`tools/frame_stats.py`, round 4's committed frames vs round 6's)

Round 4 is the baseline, not round 5 — round 5 committed no new frames
(byte-identical to round 4, per its own README).

| frame | round-04 near_luma | round-06 near_luma | round-04 chrom% | round-06 chrom% |
|---|---|---|---|---|
| 01-early-forest-day | 0.168 | 0.213 | 1.22 | 16.04 |
| 02a-quarry-overlook-day | 0.266 | 0.266 | 48.83 | 47.76 |
| 02b-quarry-station-close-day | 0.246 | 0.230 | 66.41 | 71.76 |
| 03-ranger-camp-close-day | 0.156 | 0.156 | 10.92 | 10.54 |
| 04-warrens-mouth-day | 0.163 | 0.163 | 16.49 | 15.30 |
| 05-late-ridge-day | 0.181 | 0.180 | 1.27 | 3.11 |
| 06-quarry-overlook-night | 0.000 | 0.083 | 1.83 | 10.11 |
| 07-ranger-camp-close-night | 0.000 | 0.020 | 0.48 | 11.71 |

**Night: real, large movement, far past the <0.03 noise floor round 2→3
established.** `near_luma` moves from a literal 0.000 (pure black) to
0.083/0.020, `chroma%` moves 5.5x/24x, `mean_sat` moves 0.02→0.42 and
0.01→0.64, hue-family count moves 1→2 and 0→3. The compressor agrees: these
two frames' JPEGs are now ~18.6-18.7 KB against round 4's ~2 KB — an order of
magnitude more image content, closing most of the gap to the day frames'
~30-50 KB. This is the exact axis `NIGHT-LIGHT` targeted and the #1-ranked
complaint in rounds 1-4.

**Bare ground: real movement at the two viewpoints `VEG-SITING` actually
reaches.** `01-early-forest-day` chroma% moves 13x (1.22 → 16.04) and its
sky% drops 28.8 → 9.6 — more canopy/understory now occludes the horizon at
that exact spot. `05-late-ridge-day` chroma% moves 2.4x (1.27 → 3.11). These
are the two stretches round 4's berries nodes were placed at and that every
round from 1 has named as bare. The other five day frames (02a/02b/03/04) are
flat within noise — expected, since VEG-SITING only changed where new density
gets *sited*, not those already-dressed spots.

## Critic's verdict (blind, told nothing about what changed or why)

Full text kept in this round's own record; summarised here.

**Bar A (belongs in the key-art world): No.** Carried by: no dappled canopy
light, no wildflower colour, no sky gradient/clouds, no genuine value range
between shadow and highlight in any day frame.

**Bar B (same kind of game as Palworld): No.** Sunk by two things, ranked
first and second of three: **zero creatures appear in any of the 8 frames**
(named in every round since round 1, still true — this survey does not walk
past a spawn point, so it cannot show one), and a **new defect this round did
not exist to catch before**: flat, blank white rectangular cards planted in
the ground or floating in air, in four of eight day frames (01, 02a, 02b, 04).

**The white-card defect is new, not a re-statement.** Grepped every prior
round's README for "white/billboard/impostor/blank" — nothing. It reads as a
cross-quad billboard (two intersecting planes, the same silhouette
`grass`/`bushes`/`flowers` cross-card meshes use) rendering with no texture
bound: solid flat white, no alpha-cutout leaf/blade detail at all. Two
different distributions in the frames: one large card in the immediate
foreground of `01`, and several small ones strung along the tree line at
range in `02a`/`02b`/`04`.

**Not fixed this round, and not blindly guessed at.** Checked the obvious
hypothesis — a broken source asset — and ruled it out: `Grass_Wide_Short.gltf`
/`Grass_Wide_Tall.gltf` (the newest species added to the `grass` layer) both
correctly reference `Grass.png`, and the file exists on disk with a valid
`.import`. So this is not a missing/renamed texture at the asset level; it is
either a runtime material-binding issue (the same "shared model, silently
last-writer-wins" class of bug `vegetation.gd`'s own `_warn_about_shared_models`
comment already flags, though that produces a wrong *tint*, not a blank
white — worth checking anyway) or a Godot-generated-LOD issue where an
auto-generated LOD level drops the alpha-cutout material and falls back to
default white (the close-range instance in `01` argues against a pure
distance-LOD explanation, since it's a few metres from camera, not at LOD
range — so if it is LOD-related, more than one LOD tier is affected, or it
isn't LOD at all). Root-causing this needs in-engine node inspection
(`get_surface_override_material`/checking which layer's MultiMesh the
offending instance belongs to), which is out of a content round's scope and
risks a wrong fix to a shared vegetation system on a guess — the same
restraint that kept `MAT-BLOCKOUT` and `NIGHT-LIGHT` out of the band lane's
own diff. **Filing this as a new defect for its own lane, not attempting a
fix here.**

**One more thing worth separating out, so it isn't mistaken for a regression:**
the critic also called `04`'s Warrens wall "flat-shaded... un-skinned
blockout... breaks the 'same place' read." Checked directly against
`MAT-BLOCKOUT`'s own fix (`7fa9735e`, landed and confirmed present in this
build's history) by cropping the full-resolution capture at 2x: a real stone
texture **is** there. It just doesn't read at the 640x360/40%-downscale
handheld proxy this whole loop judges at (`ralph/conventions.md`) — low
contrast, low frequency, close to a flat grey at that size and this
viewpoint's distance/lighting. So `MAT-BLOCKOUT` did land; what's left is a
legibility-at-distance question for that one wall, not a missing fix. Noting
it rather than re-opening a closed item on a misread.

## Where this leaves the loop

**Not flat — two real, independent things moved, and one new defect
appeared.** Per the stopping rule (new defect **or** measured movement counts
as a round of improvement, not both required), round 6 clears the bar on
both counts at once. `MQ2B` does not converge this round: night and the two
`VEG-SITING`-reachable bare stretches are resolved on the evidence above, but
the white-card rendering defect is a new, real, code-visible failure that
neither of those two fixes could have caught (it wasn't visible until this
round's frames existed) and blind-judge Bar B named it second only to "no
creatures at all." The band cannot be called converged while a frame in the
survey has a rendering bug that reads, in the critic's own words, as "not a
style or mood problem, it's a rendering defect."

**Recommended next step, for the coordinator:** a lane to root-cause the
white-card defect (a `vegetation.gd`/MultiMesh material investigation, likely
one line once found — this class of bug always has been in this project's
history), then a round 7 re-render limited to confirming that fix, since
everything else measured in this round is real and should not need
re-litigating. The "zero creatures in frame" gap is a separate, larger,
known issue (every round since 1) that is not this survey's to solve — no
creature spawn sits on any of these 8 viewpoints' paths, and CLAUDE.md's
five-creature/no-new-meshes rules bound what could be done about it even if
it did.
