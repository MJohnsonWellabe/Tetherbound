# HANDOVER — T1-HALL-4, 2026-08-30

**Branch:** `ralph/T1-HALL-4`, off `origin/ralph/T1-HALL-3`.
**Brief:** the fifteen scene fixes in `ralph/reports/JUDGE-6-2026-08-30.md`, which
answered both bar questions **No**. The second list in that report — the one that
needs art nobody has built — went to the owner and is deliberately untouched here.

**Headline, the number the lane was asked for:**

> *(filled in from the rendered frames — see §1)*

---

## 0. Read this first if you are the next lane

Four things worth more than the defect list, because each one changes what you
would otherwise do:

1. **JUDGE-6's silhouette number needs restating before you can act on it, and
   the restatement is harsher, not softer.** Its table gives the fortress three
   neighbours and its verdict sentence uses two at once: "within 5 luminance
   points of the ground beside it *and* darker than the hill to its right". On
   the shipped frames the fortress is already **25 points below the hill** — so a
   lane reporting "fortress vs hill" could have claimed victory on day one
   without touching anything. The defect is the other pair: mid-ground 136.3
   against the fortress's 133.4. `tools/_t1hall4_measure.py` therefore reports
   `min(hill, midground) - fortress`, which reads **+2.9** on the frames JUDGE-6
   read and is exactly the "no figure/ground separation at all" it describes.
2. **`ssao_enabled` in `art.json` has been decorative since it was written.**
   Compatibility does not implement SSAO, and `project.godot` ships
   `gl_compatibility` (D01, locked). So *no frame any judge has ever seen had
   ambient occlusion*, and defect 4's "enable or repair contact shadows and AO
   globally" cannot be answered from config. Under this renderer **sun shadows
   are the contact shadows**, which is why the actionable half of that defect
   turned out to be a layer with `casts_shadow: false`. Do not read the `true` in
   that file as evidence AO is on.
3. **The bench is not undersized. JUDGE-6 mis-measured it, and obeying that
   finding would have introduced a real defect.** See §2 — the arithmetic
   reproduces the judge's own pixel numbers to within 1%.
4. **Any edit to `vegetation.json` forces a full scatter re-bake**, including a
   one-character change to a `lod_range`. `scatter_bake.config_fingerprint()`
   hashes the whole file text, so `test_scatter_perf_budget.gd`'s freshness
   assertion fails until you re-run `scripts/world/bake_playground_scatter.gd`.
   Budget the ~10 minutes.

---

## 1. The headline defect: silhouette contrast

*(filled in from the rendered frames)*

## 2. Where JUDGE-6 is wrong, with the measurement

**The courtyard bench (defect 8) is correctly scaled and was not changed.**

The judge's reasoning: "Its seat is at y ≈ 497 and its feet at y ≈ 550 — 53 px
for a seat height. At that depth 0.45 m ≈ 53 px would make 1 m ≈ 118 px. The
grunt … measures roughly 470 px head to foot. Even on the most generous reading
of the depth difference that puts the grunt at 3 m and more likely near 5 m — or
… puts the bench's seat somewhere below the grunt's ankle."

Measured rather than inferred:

- `assets/props/quaternius_fantasy/Bench.gltf`, read straight out of the glTF
  accessor bounds, is **2.78 m long and 0.53 m tall** at the `scale: 1.0` the
  config gives it. That is a real bench. It is not a fifth of the size it should
  be; it is the size it should be.
- The H-07 rig is fully specified in `tools/_judge_capture_hall.gd`: eye at
  `trainer + (0, 1.7, -2.0)`, `fov = 70` (vertical, Godot's `KEEP_HEIGHT`
  default), 800 px tall. Focal length is therefore `800 / (2·tan 35°) = 571 px`.
- The grunt stands ~2.2 m from that camera: `1.80 × 571 / 2.2 = **467 px**`.
  The judge measured ~470.
- The bench sits at local `(-8.6, 41.0)` against a camera at z ≈ 34 — **7 m**
  away, not 2.2: `0.53 × 571 / 7 = **43 px**`. The judge measured 53.

Both of the judge's own numbers fall out of a scene where the bench is correct.
What the judge got wrong is the *depth ratio*: it derived 2.2× from the pixel
densities and called that "the most generous reading", where the actual ratio in
the scene is **3.2×**. The bench is simply further away than it looks in a frame
with no other depth cue on that side of the room.

Scaling it to satisfy the finding would have produced a 2.6 m-tall bench — a
defect an owner spots instantly, which is precisely the sentence the judge used
about the bench in the first place.

**Contact shadows are not universally absent either.** The same frame, magnified,
shows the bench casting a clear directional shadow with contact at both feet. The
defect-5 list is right about the *scatter* (§4) and wrong as a global claim.

**Defect 9's chroma half measures as already satisfied.** JUDGE-6: "the most
saturated, highest-chroma objects in the entire frame are the cyan tether
pylons". Re-measured on `H-02b` with the sky excluded — and the sky *must* be
excluded, since a naive blue-dominance test flags a third of an exterior frame —
oxblood leads on chroma (70.2) over cyan (59.3). Team Tether's teal is also a
**palette-reserved** colour (`palette.json`, enforced through
`severed_spokes.gd`); re-tinting it is a faction-wide decision touching the
quarry, the relay and the spokes, which `CLAUDE.md` puts in the "ask, do not
invent" list. Left alone, and flagged rather than quietly skipped.

---

## 3. What changed, by defect

*(filled in)*

## 4. What this lane did NOT fix

*(filled in)*
