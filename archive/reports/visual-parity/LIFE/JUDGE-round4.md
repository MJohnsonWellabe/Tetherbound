# VP9 World Life — Round 4 Judge Report

Blind review. Read only: `.claude/skills/visual-judge/SKILL.md`, `docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`, `site/img/page-board.jpg`, and the nine round4 frames + `_sheet.png`, compared against round3 for what changed. No code, config, or diffs read.

## Per-frame findings (round3 -> round4)

**1. `01-village-edge-day.png`** — Essentially unchanged. A grey boulder still fills the left ~40% of frame at point-blank range, and the same odd floating brown blob (canoe/leaf-shaped, unclear if creature or prop) still hangs mid-air over the trees where it did in round3. Two small piglet-like creatures are visible mid-ground — pink/white, spotted, with legible ears and snouts — this is the one part of the frame that reads as animals at native size. Camera occlusion is not fixed here. **Legible creature count: 2.**

**2. `01-village-edge-night.png`** — Same composition as round3, unchanged boulder occlusion. The two piglets are now rim-lit/brighter than their surroundings and read clearly as a pair of small animals against the dark grass; a tiny humanoid figure is visible far along the path on the right (barely resolvable, not a creature). **Legible creature count: 2**, readable but the rim-light treatment looks more like a debug/emissive artifact than intentional moonlight.

**3. `02-mill-pond-banks-day.png`** — The round3 "glowing blob" defect beside the turtles is gone: both turtles now read with natural grey-blue shell shading, clearly two turtles (shell + head visible), legible at native size. But camera occlusion has not improved — the right ~45% of the frame is now filled edge-to-edge by an enormous dark brown creature ear/fin pressed against the lens, arguably *larger* than the equivalent shape in round3. Net: one defect fixed, the frame's dominant problem (occlusion) is untouched. **Legible creature count: 2 (turtles); occluding body not identifiable as any specific creature from this framing.**

**4. `02-mill-pond-banks-night.png`** — Same occlusion persists (same dark shape, right side). Moon is now a clean, legible disc in the sky — good value anchor for the night frame. The two turtles are still visible bankside as small blue-tinted shapes, borderline legible (shell shape reads, head is a stretch at native size). Better than "nearly empty" as a description of *this* stand, though this wasn't the stand round3 called empty.

**5. `03-band1-open-meadow-day.png`** — Still the second-worst occlusion frame: a leathery brown ear/wing fills roughly 60% of the frame at extreme close range, texture and topology visible in ugly, unintended detail. On the visible right sliver, one small white/tan four-legged creature is visible far off in the meadow — too small and too far to resolve species or anatomy at native size; it reads as a moving colored dot, not confidently as "an animal, legibly." **Legible creature count: ~0–1 (charitable).** No material change from round3's version of this stand.

**6. `04-relay-camp-day.png`** — The clear improvement in this round, and the best frame in the set. Camera is clear of any creature body. A grove of trees now shows real light/shadow modeling (dappled sun through canopy, shadow-casting trunks), and the animal group has grown: two white bunny-type creatures huddled together (ears, legs, haunches all legible) plus a grey wolf-like creature standing apart from them. All three read unambiguously as animals — body, head, legs distinguishable — at native size without zooming. This is the one stand that demonstrates what VP9 is actually asking for.

**7. `04-relay-camp-night.png`** — Modest improvement over round3's "night nearly empty." A pair of pale creatures (ears and huddled body legible) is now visible mid-frame as a bright cluster against the dark grass, plus a second, fainter pale blob near the top-center background that is not confidently legible as an animal. Still, roughly 90% of the frame is undifferentiated black — tree canopy silhouettes swallow all midtone detail, so there is close to zero value structure supporting the scene outside the one lit cluster. Passes "does night show creatures" narrowly, on the strength of one legible pair.

**8. `05-ridge-camp-day.png`** — Completely unaddressed, and the worst frame here. 100% of the frame is an abstract, extreme-close-up mass of brown fur/rock texture with visible polygon facets — no sky, no ground, no horizon, nothing recognizable as a place or a creature. Identical in kind to round3's version of this stand. **Legible creature count: 0. Legible environment: 0.**

**9. `06-starter-beside-trainer-day.png`** — Regressed, not improved. Round3 had the starter filling most of the frame with the trainer cropped into a corner but still visible. Round4's version is a low-angle creature portrait — the starter (a bear/panda-like creature, decently modeled: clear face, paw pads, fur texture, legible anatomy) fills the frame against sky and cloud, and **the trainer is entirely absent from the shot.** This is the hero pairing frame and it now contains no human at all.

## Answers to the four scene questions

**(A) Pairing frame — trainer + starter side by side, both fully in frame?**
No. The trainer is not in the frame at all (round3 at least had them cropped into a corner). This is a regression against the keyart's "DAY" panel and the page-board hero shot, both of which place trainer and starter side-by-side, comparable scale, both fully visible, facing the vista together.

**(B) Which stands show a legible living group at native size?**
- `04-relay-camp-day` — yes, clearly (3 creatures: 2 bunnies + 1 wolf, all legible).
- `01-village-edge-day` / `01-village-edge-night` — yes, marginally (2 piglets, small but legible pair).
- `02-mill-pond-banks-day` / `02-mill-pond-banks-night` — yes, marginally (2 turtles, legible pair, day cleaner than night).
- `04-relay-camp-night` — borderline yes (1 clearly legible pair, rest of frame black).
- `03-band1-open-meadow-day` — no (single distant, unresolvable creature).
- `05-ridge-camp-day` — no (zero legible anything).
- `06-starter-beside-trainer-day` — not applicable as a "group" (single creature, no trainer).

**(C) Does night show creatures?**
Partially. Village-edge-night and relay-camp-night each show one legible creature/pair; mill-pond-night shows a legible pair. This is a real improvement over round3's "night nearly empty" verdict — night is no longer uniformly empty. But value structure at night is still poor: outside the one lit cluster per frame, everything is near-pure black with no midtone terrain or foliage detail, so "night shows creatures" is true only in a narrow spotlight sense, not as a readable nocturnal scene.

**(D) Is the mill-pond blob gone, and is the frame clean?**
The blob is gone — turtles now read with natural, non-emissive shading. The frame is **not** clean: it trades the blob for a different, larger problem — a giant creature body occluding ~45% of the frame at point-blank range, which was already present in round3 and has not been reduced.

## Ranked: three biggest remaining gaps

1. **Camera occlusion by creature bodies, six of nine frames.** `01-village-edge-day/night`, `02-mill-pond-banks-day/night`, `03-band1-open-meadow-day`, and totally in `05-ridge-camp-day`, the evidence camera is placed inside or immediately behind a creature's collision volume, filling 40–100% of frame with unlit/backlit anatomy at a distance where it reads as abstract texture, not an animal. Palworld's references (`palworld-02-open-field-path.jpg`, `palworld-03-field-boss-meadow.jpg`) show wide, uncluttered frames where player, multiple creatures, and terrain are all legible simultaneously — none of these six frames achieve that framing, and `05-ridge-camp-day` achieves *no* legible content of any kind. This is the largest single defect because it makes "is there a living world here" unanswerable in most of the survey.

2. **Hero pairing frame has no trainer.** `06-starter-beside-trainer-day` is meant to mirror the keyart's "DAY" panel and the page-board hero shot — trainer and starter side by side, comparable scale, both facing the vista. Round4 delivers a solo creature close-up with no human in frame at all, which is worse than round3 (trainer at least visible, cropped). This directly fails the one frame this round explicitly exists to prove.

3. **World geometry/foliage fidelity, visible wherever the camera clears a creature body.** In the one clean frame (`04-relay-camp-day`) and the visible slivers of `01`/`02`, trees are flat, two-tone cutout shapes and rocks are low-facet blobs with no layered canopy or ground-cover density. Compared to `palworld-01-boss-fight-forest.jpg` and `palworld-04-plateau-landmark.jpg` (dense grass, layered foliage, volumetric-reading creature shading) and to the keyart's oak-grove panels, the vegetation here reads sparse and flat even in its best moments. This is a style/asset gap independent of the occlusion problem.

## Fixable by changing the scene vs. needs new art

**Fixable by scene (composition, spawn points, camera, lighting):**
- All six occlusion frames — creature spawn points and/or evidence-camera placement need a minimum standoff distance so no creature collider sits inside or against the camera frustum. This is data/placement, not new geometry.
- The pairing frame — trainer's spawn/camera framing needs to be corrected to put both figures in frame at comparable scale, matching the keyart/page-board composition. Pure scene/camera work.
- Night value structure (relay-camp-night, mill-pond-night) — near-total black outside one lit cluster is a lighting/ambient-fill tuning problem (add moon bounce/fill or rim light broadly rather than on one creature), fixable without new assets.
- Group size/density at several stands (2 creatures reads as a minimal pair, not a lived-in group) — can likely be improved by spawning more instances, still using existing creature assets.

**Needs new art / asset work (not scene-fixable):**
- Tree and foliage fidelity: the flat cutout tree look and low-facet rocks are a modeling/shader ceiling, not a placement problem — matching the Palworld/keyart canopy density and layered form needs better foliage assets or a material/shader pass, which the flat MultiMeshy trees seen here cannot deliver through repositioning alone.
- Creature surface quality at close range: `05-ridge-camp-day`'s abstract polygon-faceted texture and the visibly blocky fur geometry on the occluding bodies in frames 1/2/3 suggest under-resolved geometry/normal maps that will still look wrong even once the camera is pulled back to a sane distance — that is a modeling/texture issue on the creature asset itself.
- Creature design simplicity: the piglets and turtles read as legible but visually plain silhouettes (a blob with two ears; a shell with a head) — functional at this population tier, but a long way from the "bespoke and expressive" character-art bar Palworld's own fauna sets, and no scene change fixes that.

## The two bar questions

**A. Do these frames read as belonging to the world in `docs/reference/tetherbound-meadows-keyart.png`?**
**No.** Where the camera is clear (`04-relay-camp-day`, the visible slivers of `01`/`02`), the palette (green grass, blue sky, brown oak trunks) and subject language (grove, pond, meadow with a hill landmark) are recognizably drawn from the same idea as the keyart. But six of nine frames are majority- or entirely-consumed by out-of-focus creature anatomy, which means most of the survey cannot be judged against the keyart's world language at all — it simply isn't shown. A "yes" cannot be given when the world itself is invisible in most of the evidence.

**B. Shown beside `docs/reference/palworld-0*.jpg`, would someone say these are trying to be the same kind of game?**
**No.** The Palworld shots are wide, legible, in-action frames: player, HUD, multiple creatures, and terrain all visible together, mid-fight or mid-traversal. Most of these nine frames instead show either an accidental close-up of a creature's own body (six frames) or a static creature portrait with no player and no action (`06`). Even the one genuinely good frame (`04-relay-camp-day`) is a calm nature-documentary shot — grazing animals in a grove, no player, no UI, no event — rather than anything resembling gameplay. The flat, low-poly foliage style is also a visible step below Palworld's volumetric, painterly-anime look wherever it's on screen. What carried the little credit there is: this one frame shows real light/shadow modeling and a legible three-creature group. What sank it: camera occlusion in the majority of the survey, a hero-pairing frame with no human in it, and a foliage/geometry style that reads more primitive than the bar even in its best moment.

## Summary of movement since round3

- Fixed: the mill-pond glow artifact on the turtles (now natural shading).
- Fixed (partially): night is no longer uniformly empty — three of the four night-adjacent stands now show at least one legible creature/pair.
- Improved: relay-camp-day gained a third creature (the wolf) and now shows real canopy light/shadow.
- Unchanged: camera occlusion at village-edge (day/night), mill-pond (day/night), band1-open-meadow-day, and ridge-camp-day — five to six of nine frames, the survey's core recurring defect, is untouched.
- Regressed: the hero pairing frame went from "trainer cropped but present" to "trainer entirely absent."
