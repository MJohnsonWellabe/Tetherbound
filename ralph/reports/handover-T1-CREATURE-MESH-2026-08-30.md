# Handover — T1-CREATURE-MESH, 2026-08-30

Branch `ralph/T1-CREATURE-MESH`, checked out from
`claude/tetherbound-coordinator-onboard-7pz3ah` (which carries the owner's
brief and the ten reference boards, committed already). This lane holds no
Meshy API key and generated no mesh — everything below is reference crops,
`views.json` entries, and prompts for the coordinator to run.

## What I was asked to do

Prepare everything Meshy needs for five new Meadows creature meshes —
Sparkit, Cindercub, Shadelet, Bramblebun (redesign), Frostclaw — from
`docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` and its ten
boards under `docs/art/reference/creature-expansion-2026-08-30/`. Explicitly
NOT asked to run Meshy myself (the key stays with the coordinator).
Deliverables named in the brief: correct crops, correct `views.json`
entries, a well-argued prompt per creature, a generation plan, an asset
ledger row, and this handover.

## What I prepared, per creature

All five share one source file, the 1536×1024 master sheet
(`00_MASTER_SHEET_creature_expansion.png`), which draws all nine expansion
creatures on a 3×3 grid of identical per-species panels. For each of the
five NEW-MESH creatures I added a `views.json` entry (band + centres for a
front/side/back turnaround, `extra_boxes` for a `top` view, and — for four
of five — a `mask` to remove a per-cell divider-rule defect described
below), a `SPECIES_PROMPTS` entry in `meshy.py`, and ran
`crop_views.py --check` repeatedly until the contact sheet showed clean
output. Bramblebun is keyed `bramblebun_redesign`, not `bramblebun` — see
below.

Done and verified (crops exist, contact sheet inspected, prompt written):
Sparkit, Cindercub, Shadelet, Bramblebun-redesign, Frostclaw. All five
resolve through `meshy.py`'s `reference_views()` with exactly
`front/side/back/top`, confirmed by running it directly. Still open:
everything past this point is the coordinator's — no generation has
happened.

**Bramblebun's crops are pushed and verified** — it is the one the owner
most wants moving, so start there.

## The three_quarter question — my answer is NO, with evidence

The brief asked me to work out whether the per-creature sheets' hero pose
should stand in as a fourth `three_quarter` view, the way the wild sheets'
`extra_boxes` already do for their own hero panels, and to say what I find
rather than assume.

**I did not add it, and I don't think it should be added.** The wild-sheet
precedent (`bramblebun`, `mudsnout`, `trailpup`, etc. in `views.json`)
works because the hero pose, despite being drawn at a different scale, is
still a **neutral standing pose** — the same thing the turnaround shows,
just bigger. I checked this sheet's hero panels against that assumption and
it does not hold: every hero pose I looked at (the master sheet's own hero
panel, and the individual per-creature sheets' hero art, e.g.
`06_Bramblebun_redesign.png`'s crouched, weight-forward pose with front
paws planted) is a **crouched or prowling action pose**, not neutral. The
front/side/back turnaround, by contrast, is uniformly neutral standing
across all five creatures.

Multi-image-to-3D reconciles what a subject IS across its input images —
not just its apparent size. A scale mismatch (which the wild-sheet
precedent already tolerates) is a much smaller ask than a **pose**
mismatch: three images agreeing "this animal stands like X" and a fourth
insisting "no, it's crouched with its weight forward" is not extra signal,
it's a contradiction, and I'd expect it to show up as a generator
compromise — a mesh with the wrong stance, or the crouch pose only fixed
into a subset of anatomy. I did not spend a credit to confirm this
empirically (that would have meant generating with and without the fourth
view, twice, for one creature, to compare — a defensible next experiment,
but not something to spend on speculatively when the pose evidence already
points one way). Front/side/back only, for all five.

## The top view — I think this is a real improvement, not just a formality

Unlike every prior sheet in this pipeline, these boards draw a genuine
orthographic top-down view per creature (plus a bottom, which I did not
crop — `meshy.py`'s `VIEWS` list has no `bottom`, so `reference_views()`
would never read it; cropping it would be pure overhead). `top` was already
in `VIEWS` — added earlier for props, specifically because no creature
board had ever carried one — so this needed no code change to start
mattering for a creature. I cut it via `extra_boxes` at its own scale,
matching how the wild sheets already handle their hero panel. This gives
each of these five creatures a fourth, genuinely informative reference image
instead of the omitted `three_quarter`, which I think nets out ahead of the
old four-view convention for creatures whose sheet actually draws a usable
top-down.

Two of the five (Cindercub, Frostclaw) needed their `top` box widened after
a first `--check` pass showed the creature clipped — the sheet's own drawn
box outline around the top figure is **narrower than what's actually
painted inside it** on at least these two panels (nose or tail extending
past the box's own border). Bramblebun's top view has the same problem far
more severely — its antler-branch ears and root/leg tendrils extend well
above and below the box outline — so I read its true extent off a wider
source crop rather than trusting the box, and I'd recommend that as the
default approach rather than the box outline if this ever needs retuning.

## Fidelity — a real concern, not a formality, especially for Bramblebun

`views.json`'s own `_comment_output` documents 180–450px source figures as
this pipeline's established range and calls that the real ceiling no amount
of upscaling moves. **Measured off this master sheet: every front/side/back
figure is roughly 70–190px on its longest side** — at or below the bottom of
that range, not within it. Bramblebun's own turnaround figures measure
roughly 90–100px wide, among the smaller ones. This isn't disqualifying on
its own — Grandpa and the Warden both shipped from ~150px crops with the
prompt text carrying more of the load, which is the same move I made here
(every prompt states its signature feature in capitals, per this file's own
established convention) — but it is a real, measured finding, not a
formality to wave past, and I'd flag it especially hard for Bramblebun:
it's the one creature where the owner has said a soft result is not
acceptable, and it's also sitting on the smaller end of an already-small
range. If the preview round comes back generic or melted, my honest
expectation is that another prompt rewrite will not fix it — the source
resolution is what it is — and the right next step is telling the owner the
per-creature panels are too small to drive a confident final asset, per the
brief's own instruction. I did not reach that conclusion definitively
myself (I have not seen a generated candidate to confirm it), so treat this
as a flagged risk for the first preview round to either confirm or put to
rest, not a verdict.

## What I learned that is not visible in the diff

**Every one of these five panels draws a hairline box-border rule around
each FRONT/SIDE/BACK cell, and it is not faint enough for this pipeline's
existing `erase_dividers()` to catch.** That function's own thresholds
(`DIVIDER_MIN_DISTANCE`/`DIVIDER_MAX_DISTANCE` = 15–105) were tuned against
the pale rules on sheets 01–04; these sheets' rules read past 105 in my own
measurement, so `erase_dividers()` silently leaves them alone. Left
unmasked, the first `--check` contact sheet showed exactly the failure this
pipeline's own history already warns about (Grandpa's "floating dagger",
Mudsnout's "flat vertical PLANK"): a hairline cutting straight through
Cindercub's own body in the `front.png` crop, plus a sliver of the
neighbouring figure bleeding through where the line had widened the snapped
edge. I did not touch `erase_dividers()`'s shared thresholds (retuning a
constant used by every other sheet in the file to fix one new sheet is
exactly the kind of change that quietly breaks something else three sheets
away) — instead each of Cindercub/Shadelet/Bramblebun-redesign/Frostclaw
carries an explicit `mask` entry for its own rule-line coordinates,
Sparkit's row happening to have its rules fall inside the natural
figure-to-figure gaps already. This cost two full `--check` iterations to
find and fix — worth knowing if a sixth creature is ever added from this
same master sheet, since the same defect will recur at whatever x-position
that creature's own cell rules sit.

**A small residual I chose not to keep chasing:** Cindercub's `front.png`
still carries a single tiny (a few px) dark fleck near its right edge, from
the fixed 8px `MARGIN` the crop pipeline always adds around a snapped edge
landing right at the boundary of the masked-out divider line and the
neighbouring figure's own snapped start. I judged this below the bar of
"floating dagger"-class defects worth an unusual fix (shrinking the global
`MARGIN` constant, or clipping into the neighbour's own real content to
close an 8px gap) — it's a few background-adjacent pixels, not a shape.
Flagging it here rather than silently living with an unexamined artifact.

**`write_grid()` (the `--grid` overlay command) was broken for any sheet
whose `file` path includes a subdirectory** — which is every wild-sheet
entry already in the file (`wild/02_...`), not just my new
`creature-expansion-2026-08-30/...` entries, though I only discovered it
because I needed it for these five. It built an output path with the
subdirectory baked into the filename portion
(`grid_wild/02_Meadows_Wild_Ground_Sheet.png`) whose parent directory was
never created, so `Image.save` would raise. Fixed with a one-line change to
take just the basename. I did not verify whether anyone has actually run
`--grid` against a wild-sheet entry since it was added — if not, this was a
latent bug rather than a regression I introduced, but it's fixed either way
and the fix is in this branch's diff.

**Shadelet's `side.png` has a tail that looks disconnected — it isn't, it's
the source art.** The reference draws the tail's spiral curl with a visible
gap between the near coil and the tip, which reads at a glance like two
separate floating pieces. I checked this against the original master sheet
(not just my crop) and confirmed the gap is in the artist's own
illustration, not a cropping artifact. Recorded in both `views.json`'s
comment and the generation plan, since whoever reviews the first generated
candidate should know to judge that feature against the source, not assume
the crop broke it — and should still watch for the generator reproducing
it as a literal mesh disconnection, which the plan document flags as a
reject condition.

## Disagreements / things I'd push back on if asked

1. **The 3/4-view omission** (above) is the one place I diverged from what
   the brief suggested trying. I think the evidence (pose mismatch, not
   just scale) supports skipping it, but I'd genuinely welcome someone
   generating one A/B test (with vs. without a hero-pose 3/4) on the
   cheapest species before treating this as fully settled — I did not
   spend the credits to confirm it empirically myself, on the reasoning
   that a clear pose contradiction is not a promising thing to spend on
   testing first.
2. **The fidelity concern is a flag, not a stop.** I did not halt work or
   refuse to write prompts over it — the brief's own framing is "say so
   before anyone spends credits," which I've done in the plan and here,
   rather than "don't prepare a plan." If the owner would rather supply
   larger art for Bramblebun specifically before any credit is spent on it,
   that's a call above this lane's pay grade, but the option is worth
   surfacing given how much the brief itself weights Bramblebun's outcome.

## Full file footprint

- `tools/art_pipeline/views.json` — five new entries (`sparkit`, `cindercub`,
  `shadelet`, `bramblebun_redesign`, `frostclaw`) plus one new `_comment_expansion`
  prose block.
- `tools/art_pipeline/crop_views.py` — one-line fix to `write_grid()`'s
  output path (basename instead of the full `spec["file"]`, which could
  carry a subdirectory).
- `tools/art_pipeline/meshy.py` — five new `SPECIES_PROMPTS` entries, one
  new `DROP_FOR_SPECIES["sparkit"]` entry (removes `NEGATIVE_CREATURE`'s
  "fox proportions" ban, which fights Sparkit's own canon fox-coyote build —
  the same mistake `DROP_FOR_SPECIES["trailpup"]` already exists to
  prevent, one creature later).
- `assets/creatures/tetherbound/{sparkit,cindercub,shadelet,bramblebun_redesign,frostclaw}/reference/{front,side,back,top}.png`
  plus each directory's `.gdignore` — the generator-input crops themselves.
- `docs/art/reference_views.png` — regenerated contact sheet (now includes
  all five new rows; this file is already tracked in git, not new).
- `docs/ASSET_LEDGER.md` — one new row recording the crops' provenance
  (straight crop, no generation, no credits spent) ahead of the coordinator
  spending any.
- `ralph/reports/CREATURE_MESH_PLAN_2026-08-30.md` — the generation plan:
  exact commands, candidate counts, expected costs, prompts, and
  what a good result looks like per creature, Bramblebun first.
- `ralph/reports/handover-T1-CREATURE-MESH-2026-08-30.md` — this file.

Not touched, per the brief's file-ownership section: `data/creatures/species.json`
or any typing/rarity/spawn data (T3-CREATURES lane), creature materials/VFX
for the four variant creatures (T1-CREATURE-ART lane), the existing
`bramblebun/reference/` crops or its shipped mesh, anything in `scripts/`.
