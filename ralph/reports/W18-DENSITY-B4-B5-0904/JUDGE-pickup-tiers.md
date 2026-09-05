# Code-blind visual verdict — candy tier legibility (W18-DENSITY-B4-B5, round 1)

**Method.** A sub-agent (model `opus`) was given only `_sheet_tiers.png`, the three
individual frames, `docs/reference/` and `.claude/skills/visual-judge/SKILL.md`. It was told
nothing about what changed, what the objects were, or what answer was wanted — the prompt
asked it to find "a small collectable object a player is meant to walk over and pick up" and
to say plainly if it could not find one. It did not see the source, this lane, or the data.

**Frames.** Real in-game frames, Compatibility renderer under software GL, camera at player
eye height (1.7 m) 7 m from the pickup the loader actually placed:
`b4-rare-herd-bull-7m` (Rare, the Highfield herd bull), `b4-great-wind-ridge-7m` (Great, the
wind ridge crest), `b4-good-south-paddock-7m` (Good, the Highfield south paddock).

## The verdict, verbatim in substance

**1. Can it find a collectable?**

- **Great (mint):** yes — the only one it found unaided. Frame centre-left, "a mint/aqua
  translucent rounded mass with three lobes… with a faint pale rim glow along its top edge",
  on a lit grass slope in front of a dark trunk.
- **Rare (cream):** "technically yes, but I only found it by scanning for it." Same geometry,
  "pale butter-cream instead of mint, and with no glow", with a dark leafy shrub growing
  through it: "only about **14% of its own bounding box is actually the object's colour**…
  On first look I read it as a sun-bleached fern."
- **Good:** **"no. I cannot find a collectable in this frame."** The centre of the frame is
  one large trunk occupying where the subject should be. It scanned for both colour
  signatures and found neither, only "the same white/lavender cup flower repeated at least a
  dozen times" — "identical asset at different distances".

**2. Does it read as a pickup?** No. The three-lobed soft organic body "is the silhouette
language of a small animal, and there is nothing that says 'item': no float, no hover offset,
no spin, no base ring, no contact shadow, no rim outline". Grass renders in front of it and
the object is the same height as the grass, "so the grass wins the silhouette". A player at
speed "would most likely read it as a critter". The cream Rare "does not read" at all —
cream collides with the frame's existing white cup flowers and pale shrubs.

**3. Is there a value hierarchy?** "The only difference between the two objects I can find is
hue." No size step, no added shape, no particle, no decal. "Far too subtle to tell apart in
play" — and **inverted**: "'Rare' should be the loudest thing on the ground and it is the
quietest", while Great pops only because mint is the one cool hue in a warm olive frame.

**4. Ranking by apparent value:** great > rare > good. Confident a player would rank them
this way; explicitly not confident that is the intended order.

**5. Also named:** pickups sit at grass height and should be above the grass line or have a
clearing under them; no ground contact shadow; the `b4-good` camera is behind a trunk and "as
shot it proves nothing"; fern saturation and terracotta trunks out-shout the pickups; the
`b4-rare` tree line reads procedural and its ground is one flat mid-tone; a stag at the right
edge of `b4-rare` has its haunch and hind legs inside the terrain and its antlers merged with
a canopy.

**Its own separation of fixable-in-scene from needs-new-art:** placement, clearings, ground
decals, hue choice and camera are scene work; **the pickup mesh itself is not** — "a
featureless three-lobed rounded blob that reads as a creature — no amount of lighting,
placement or tinting will make it read as an item you walk over."

## What this lane does with it

**Nothing in this verdict is fixable inside this lane's ownership, and that is the honest
outcome of round 1 rather than a reason to run round 2.**

- **The tier look is `scripts/world/band_pickups.gd`** — the tint, the emissive medallion and
  the Rare's wings are all applied at instancing there. That file is W17's and the W18 brief
  says explicitly: *"Do NOT write your own… do not touch the loader."* The finding that
  matters most — cream is the wrong hue for Rare because the meadow is already full of white
  and cream flowers, and hue alone is not a hierarchy — is a change to `CANDY_LOOK` and the
  badge/wing geometry in that file. **Routed to the coordinator for W17 or a pickup-visual
  lane.** Concretely: give Rare a hue that does not collide with the flower palette, and make
  the tiers differ by *size or added shape* as well as hue, since the judge could not
  separate them by tint at 7 m.
- **The mesh's own silhouette** (`candy_pickup.glb`) is an asset question and
  `docs/prompts/75` §4.2 / the ASSET_LEDGER already own it. No generation was spent here and
  none should be on this finding alone.
- **The grass-height and contact-shadow points** belong to whoever owns pickup presentation
  (`pickup_glow.gd` and the loader), not to a data lane.
- **The world findings** (procedural tree line, flat ground value, trunk saturation, the stag
  intersecting terrain at roughly (1130–1240, 200–280) in `b4-rare`) are for the visual
  lanes; they are recorded here because a blind pass found them, not because this lane
  touched them.
- **What is genuinely this lane's:** the Rare at the herd bull landed with a shrub through it.
  The site validator this lane wrote checks `vegetation.gd::has_solid_scatter_near`, which
  only sees the **collision batches** — trunks and boulders. Non-colliding scatter (bushes,
  ferns, tall grass) passes that check and can still occlude a pickup completely. That is a
  real gap in the validator and it is written down here rather than papered over; closing it
  means asking the scatter for *visual* occupancy, not collision, which is a change to
  `vegetation.gd`'s query surface and outside this lane's file list.

**Rounds run: 1. Stopped deliberately.** A second render round would cost ~40 minutes per
boot under software GL and could not move any of the findings above, because every lever they
name lives in a file this lane does not own. The ceiling is recorded here per
`docs/AGENT_WORKFLOW.md` §7.
