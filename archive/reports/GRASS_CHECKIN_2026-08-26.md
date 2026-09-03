# GRASS — check-in

`2026-08-26` · branch `ralph/GRASS-FIELD` · tip `ec865e6` · **pushed, at a task
boundary.** Successor to `GRASS_HANDOVER_2026-08-26.md`; that file's §1-§8 all
still hold and are not repeated here.

**Branch state.** The coordinator rebased this branch onto `main` (`7c47b89`)
mid-session; the two commits below were replayed onto that rebase rather than
force-pushed over it, and both pushes were clean fast-forwards. CI has not been
read yet at the time of writing — see **What a successor should check first**.

---

## What shipped

**`3248e08` — the leaf outline, and the carpet's edge.**

The bushes had failed four rounds because every one of them reached for size,
count, tint or lighting. The defect was that each leaf was an opaque QUAD, and a
rectangle does not read as a leaf however it is lit. `cover_tier.gdshader` now
carves a leaf outline out of the quad in the fragment stage: a width profile
that is nothing at the stem, broadest a little under halfway and closed to a
point at the tip, with the two edges serrated at different phases so the outline
is not a mirror of itself. No asset — `CLAUDE.md`'s no-new-Meadows-art rule is
untouched, and the previous round's "needs a bush asset that is not loose quads"
was not an art gap.

The mask needs a leaf-local coordinate and UV was already spoken for (UV.y runs
up the whole BUSH, which the tint gradient and contact darken read), so every
cover mesh now writes UV2. Litter takes the same mask more gently. Flowers stay
at `leaf_cut` 0: their petals are shaped by their own geometry and that
silhouette is settled.

Grass blade height now multiplies by `pow(v_fade, 0.4)` so the carpet sinks into
the terrain rather than thinning at full height.

**`ec865e6` — branches, and per-leaf shading.**

The owner's live words on the cut-leaf state: *"the bushes are starting to look
better but they can't just be random leaves in the air. there needs to be some
sort of stick connecting the leaves something"*. Structural, not a tuning note —
the mesh placed leaves on concentric rings, so no leaf's stem end touched
anything. Rebuilt: a short trunk, eight branches arcing up and out, every leaf
built FROM a branch point rather than positioned near one. Wood carries
`UV2.y = 2.0`; the shader reads that flag to skip the alpha cut (which would eat
a twig from both ends) and the leaf tint.

Two rounds. Six branches of nine at 0.80m bought the stick and lost the mass —
a spindly sapling, where the tier's job is the knee-height band between 50cm
grass and 6m canopy. Eight of ten, shorter and broader, has both.

Also folded in from the blind pass: per-leaf base-to-tip shading with a jitter
decorrelated from the outline seed, and `contact_darken` 0.14 → 0.30. Both read
UV2 the mask already fetches. The leaf quad narrowed 0.78 → 0.56 of its length,
because near-square made the mask produce a rounded scallop rather than a leaf.

Cost: about 190 triangles a bush against 104. `count` is the dial. `enabled`
stays **false** — unchanged, and not a lane's decision.

---

## Findings that cost a cycle — do not re-derive

**The ring transition measures as a gradient, and the second half of the
prescribed fix was NOT spent.** Handover §9.2 called for tinting
`terrain_playground.json`'s grass colour map toward the tier's green. After the
height fade, mean value in 20-row bands down the ring-edge frames runs
0.529 0.511 0.504 0.506 0.517 0.530 0.548 out to 0.650 at far terrain, hue
drifting 74.5° → 67.5°: monotone, no step. That prescription was written for a
step. It costs a full terrain re-bake **plus** a full scatter re-bake (the
fingerprint covers that file) and would darken every grass surface in the world.
**Caveat, and it matters:** the blind pass still reports a hard full-width
boundary in four frames. Both can be true — I measured *colour*, the critic is
reading *detail density*. Before spending the bake, establish whether the line
they see is the 72m ring edge or the near hill's crest; past a crest there is no
ground to dress and no fix applies.

**A second instrument exists and the handover did not know about it.**
`terrain_playground.json`'s own `_comment_tint` forbids reintroducing a per-
texture tint and routes surface-colour corrections through
`tools/art_pipeline/stylised_ground_spec.py` and a regenerate. That path changes
no file in the scatter fingerprint, so it costs **no bake at all**. Note the two
sides currently disagree by more than the spec's own ±6° tolerance: terrain
`meadow_grass` albedo is hue 66, the blade tints are hue 77–82, and the owner
reference the blade tints cite is hue 68.4 — so the blades, not the terrain, are
the ones sitting away from the measured reference.

**`ambient_energy`: the raise 1.5 → 2.1 was aimed at something it cannot reach,
and overshoots at the other end.** Ground floor measured on the bottom 60% of
frame, sky excluded (script: percentiles of Rec.709 luma):

| | p1 | p5 | p25 | literal black |
|---|---|---|---|---|
| Palworld ×5 | 5.9–33.3 | 15.1–59.3 | 55.7–127.5 | 0.000–0.045% |
| moong ×2, keyart | 4.8–9.1 | 14.6–54.0 | 26.0–83.6 | 0.148–0.307% |
| ours @ 2.1 | 28.5–34.4 | 52.9–67.6 | 94.0–107.0 | ~0% |
| ours @ 1.5 | 24.7–31.2 | 44.8–60.1 | 84.9–98.3 | ~0% |

The premise behind the raise — "clipping to literal 0.0 against a Palworld floor
near 30" — is not supported: the project's own key art has p1 4.8 and 0.31%
literal black. At 2.1 one open-terrain frame is **above the entire Palworld
range** on both p1 and p5. And the literal-black fraction was **identical** at
both values (1.565% vs 1.566%) — that black is the grass carpet's own dark base
and the trainer, not a shadow ambient reaches. **On this evidence 1.5 is the
supported value and 2.1 is not.** NOT LANDED, deliberately: this is open-meadow
evidence only, the original critic measured forest interiors, and a blind pass
on band 2 does call its shadows crushed. The two ends genuinely disagree. The
run that would settle it is `_probe_grass_field.gd` at both values in one
uninterrupted pair — mine was killed after I edited a shader mid-sweep and
confounded it.

**A probe artefact a critic will re-file if the source comment is removed.**
`_probe_leaf_cut.gd`'s close view was at 0.55m, inside the understorey. A blind
critic read the result as "unlit flat leaf cards floating in the sky" and ranked
it shipping-blocking. It is not: the game's camera rides a SpringArm well above
bush height. Eye is now 1.00m with the reason in the source.

---

## The blind pass, and what it found that is NOT this lane's

One round on the cut-leaf state (6 frames, band 1 + band 2). It moved the bush
complaint from *"a heap of large untextured flat quads... hard-edged, many
detached and floating with no stem"* to *"flat clipart... zero shading
gradient"* — a **new defect**, so the round counts as improvement under
`conventions.md`'s stopping rule, and it was acted on in `ec865e6`.

Its ranked #1 and #2 are both out of this lane and both outrank more bush work:

1. **Nothing on any horizon.** Two isolated trees, same asset, same size; the
   one outcrop landmark is half-cropped in a corner. The board's four defining
   nouns are oak groves, clear streams, small settlements and a distant
   landmark; the survey has zero of each.
2. **No value range, and no cast shadows at all** in five of six frames — no
   readable sun direction, no contact shadow under either character, terrain
   flat-lit with silhouette but no form.

Confirming or sharpening handover §5, and worth filing:

- **The oxblood has leaked**, and worse than §5 recorded: every trunk in band 2
  is flat deep maroon, so the reserved faction red is the dominant colour of a
  friendly forest; the trainer's backpack also reads oxblood in shadow. The
  critic called retinting the trunks "the single highest-value colour fix in the
  set". Material swap, no geometry.
- **No creature in any frame** of a creature-training game, unchanged from §5.
- New, and checkable: repeated pebble decal stamped four times at one rotation;
  rectangular unblended terrain-paint patches (band 1 and 2); vertically
  stretched cliff texture with no triplanar; full-saturation aqua objects at
  extreme distance with no LOD fade; band-2 signpost 2.6–2.8m tall (a trail
  marker is 1.6–2.0m), unshaded, board text illegible.
- Bar questions: **A (key art) no** — palette family right, the board's four
  nouns absent. **B (Palworld) yes**, with the critic's own qualifier: "yes, and
  losing", because the reference frames are full and four of six of ours are an
  empty field.

---

## What a successor should check first

1. **CI on `ec865e6`.** Not read at stand-down. If it is red ONLY on
   `verify-owner-regressions-shard`, that job is intermittently red for reasons
   unrelated to any branch (`smoke_arena_contain.gd`, a warrens fight opening in
   solid rock) — say so rather than chasing it.
2. **Consolidation still needs `"groundmat"` added to `suppress_scatter_layers`**
   when this lands beside `ralph/WORLD-GRASS`. Handover §1. Unchanged.
3. Nothing in `vegetation.json` / `terrain_playground.json` / band vegetation
   was touched, so `data/scatter/manifest.json`'s fingerprint is intact and no
   re-bake is owed.
