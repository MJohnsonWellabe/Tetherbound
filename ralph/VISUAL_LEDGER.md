# The whole-game visual ledger

**Owner directive, 2026-08-23:** the visual coordinator runs across the ENTIRE
game, not one corridor. Named in the directive: the ground, HUDs, every menu
screen, every build, every asset type, every region, every character, every
creature, every tool, every consumable and gatherable, every terrain, every
pre-built building. *"The whole game relies on all of this looking great. This
is the most important ongoing task."*

This file is that mandate's standing ledger: every visual domain, its capture
tool, its last blind verdict, and what is open. It is append-and-amend, not
append-only — a domain's row is updated in place when it is re-judged, because
the useful question is always "what does it look like NOW".

## The pipeline, as the owner set it

1. **Sonnet captures.** A worker authors the domain's capture tool and renders
   real in-game frames with it.
2. **Fable reviews.** A blind critic — no knowledge of what changed, no stake
   in the answer — produces notes and a plan against `docs/reference/`.
   `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 is binding here: blind visual
   review stays Fable-only, and must never judge evidence it produced.
3. **Sonnet executes** the plan.
4. Repeat until `ralph/conventions.md`'s convergence rule ends it: stop after
   two consecutive rounds that name no new defect and move no measured axis
   (`tools/frame_stats.py`). Convergence without a pass is a `BLOCKED.md`
   entry or a labelled `BACKLOG.md` remainder, never silent iteration.

## The one measurement that shapes every schedule here

This box renders in software (llvmpipe) on **four cores**. Measured on the
standing corridor world — 143,630 props — at 1280x800: **~2.4 seconds per
rendered frame**. Two consequences, both paid for once already:

- **A capture's cost is its awaited frame count, not its scene.** The first
  corridor survey budgeted 3,376 frames the way the single-region probes do
  and did not reach its first shutter in seventeen minutes. The world was
  never the problem; it stands up complete in under a minute.
- **Renders do not parallelise on this box.** llvmpipe takes every core, so a
  second Godot render does not halve the wall clock, it doubles both. Author
  capture tools in parallel — that is free — and run them one at a time.

## Domains

Status: `open` (never judged) · `in-flight` · `judged` (verdict recorded,
work open) · `converged` (two flat rounds, remainder recorded).

| # | Domain | Capture tool | Rounds | A (keyart) | B (Palworld) |
|---|---|---|---|---|---|
| D1 | Regions / corridor, bands 1-5 | `_probe_corridor_survey.gd` | 2 | no · no | yes-narrow · yes-"trying" |
| D2 | HUD + every menu screen | `_capture_ui_survey.gd` | 1 | no | no |
| D3 | Creatures — 17 species, shinies, alpha | `_capture_creature_roster.gd` | 3 | yes-narrow · no · **no** | no · no · **yes-"trying"** |
| D4 | Characters — 6 rigs, Team Tether ranks | `_capture_character_cast.gd` | 2 | no · **no** | no · **no** |
| D5 | Buildings — 18 prefabs + player builds | `_capture_structures.gd` | 1 | no | no |
| D6 | Items — 55 tools/consumables/gatherables | `_capture_item_art.gd` | 1 | no | no |
| D7 | Ground / terrain / water / weather | `_capture_ground_and_sky.gd` | 1 | no | no |
| D8 | Combat presentation | `_capture_combat_moments.gd` | 1 | no | no |

**Every domain in the game has now been judged blind at least once.** Reports:
`ralph/reports/VISUAL_*_2026-08-23.md`.

No domain has converged. Every round so far has named NEW defects, which is
`ralph/conventions.md`'s definition of a round that improved, so none is near
its stopping rule. D3 round 3 and D4 round 2 (`ralph/reports/
VISUAL_VIS_CAST_2026-08-23.md`) both named several, and D3 round 3 additionally
moved bar question B up to "yes, trying to be the same kind of game" while
keeping A at no.

## The pattern that explains four separate defects: metallic in this renderer

Named here because it has now been diagnosed from scratch four times, each time
as a colour problem, and each time it was the same thing.

**The Compatibility renderer has no reflection probe and, on a bare capture
stage, no sky. A metallic surface therefore has nothing to reflect. High
metallic suppresses the diffuse term and returns almost nothing.** It is never
a sheen here; it is either a mirror of whatever IS in the sky, or a hole.

- **Ice-blue foundations** under seven buildings: `MI_RockTrim` ships with no
  `metallicFactor`, so glTF's spec default of 1.0 applies — full metal,
  mirroring the sky, reading as chrome. Diagnosed as a colour choice twice
  before the third pass found the missing factor.
- **`MI_Plaster`** — the same missing-factor shape, found independently by two
  different headers in this codebase.
- **The Warden's badge became a literal black hole**: metallic 0.88 on the
  near-black reserved hex returns RGB 0,0,0. A blind critic called it "the
  loudest single defect in the survey" and correctly read it as a missing
  material. Metallic now 0.10-0.18; roughness alone gives the sheen that was
  actually wanted.

**Check for a metallic value before treating any "wrong colour" as a colour.**

## The oxblood story, third correction

`tether_oxblood` `#332228` has now failed legibility twice — once as a matte
near-black disc invisible on a dark green coat, once as a metallic black hole —
and preserving the hex exactly was the wrong instinct both times.

> *"A colour reserved for a faction has to be VISIBLE on that faction to mean
> anything; a black disc on a black coat reserves nothing."*

It lifts to `#5a3742`: the reserved colour's own hue and family, raised until it
reads. This supersedes both earlier entries here — the original "the discipline
holds" reading, and the VIS-SITES correction that the discipline holds while the
READ fails. The rule is not "reserve the hex", it is "reserve the identity, and
make it legible where it is worn."

## Corrections to this ledger from later rounds

Kept as corrections rather than edited away, because a ledger that quietly
rewrites itself cannot be trusted about what it got wrong.

- **The oxblood "pass" was half wrong.** Every report above records the oxblood
  discipline as holding. VIS-SITES' critic, not told the colour means anything,
  flagged the castle's nine banners as a friendly landmark wearing the danger
  colour. **The banners are correct — it IS the enemy stronghold — so the
  discipline holds and the READ fails**, because nothing else in frame says
  whose castle it is. Reserving a colour is not the same as making the reading
  land.
- **D3 round 1's scale numbers were measured against a broken ruler** and are
  superseded by round 2's (1.93x span over 17 species, not 1.6x). Two
  individual readings reversed outright: veridian is the largest species rather
  than common-deer-sized, and terrapup genuinely does out-mass the tank it
  shares a mesh with.
- **The buildable wall is not warped.** A critic's finding, disproven by raw
  vertex data; the "diagonal lift" is an intentional Tudor V-brace. No change
  made, and none wanted.

- **The grunt armband defect does not exist.** The corridor round-2 critic
  reported "a flat pure-red untextured rectangle that renders magenta at night"
  and this coordinator briefed VIS-CAST on it without checking. VIS-CAST found
  **no armband in code or data and zero saturated-red pixels in the grunt
  texture** — the description fits the captain's box badge, which was already
  fixed. A critic's misattribution, propagated into a lane brief. Verify a
  named part exists before handing it to a lane.
- **The villagers are not child-proportioned.** Head counts measured off the
  capture rather than asserted: villagers **4.9**, trainer **5.2**, grunt rig
  **6.5**. The "1.78 m children" reading is far smaller than stated, and the
  real outlier is the grunt rig — **a quarter longer-limbed than the game's own
  style anchor, and now the body of three antagonist ranks** because of this
  coordinator's own rank-ladder fix.
- **The missing small-creature tier must not be "fixed".** Its fix would
  reverse **D19**, an owner decision made at the controller after play, having
  found his creature felt small. Canon precedence puts owner-play evidence above
  a critic's reading. Recorded as blocked, not actioned.
- **Combat DOES have attack VFX — the capture was shooting between frames.**
  VIS-MAKE established the missing engagement/move/hit moments as **harness
  defect #7**, not a game defect, and proved the impact flash "was always
  there". The capture now photographs a moment that lasts less than a frame.
  This is why it was recorded as an open question rather than a finding.

## Findings from the parallel lanes that are NOT visual

- **Three of the chapter's four gates are decorative.** VIS-SITES measured every
  choke point across the corridor's full 2,048 m width at the player's 45 degree
  slope limit and at the 60 degrees a ridden legendary gets. The river holds —
  no 64 m window reaches the far bank anywhere, the cut is 11.4-21.1 m deep at
  65-80 degrees across 188 stations, and every baked depth is within a metre of
  the recipe, so the Old Mill Crossing is genuinely the only way over. But the
  **South Bridge gully and both Sigil Gate gorges are 90 m and 108 m bars in a
  2,048 m corridor** — authored correctly and walked around the end of in about
  a minute. Routed to gameplay, not art: it affects progression pacing.

## Mechanisms found that nobody had

- **The fires emit no light.** Both camp fire-detail night frames are lit by
  nothing. For a brief whose own words are "cozy and inviting", the cheapest
  instrument in the game is switched off.
- **There are two castles.** `landmark.gd` builds a 132-module castle with four
  corner towers, a two-module gate and nine oxblood banners at (229.8, -144.4)
  — **7,708 m from the stronghold the player reaches**, which is the untextured
  blockout three critics have called "the antagonist made of nothing". Shooting
  both in-world separates two fixes that one verdict was hiding: dressing at the
  wrong coordinates (a const the OW5D relocation left behind) versus materials
  not loading. A prefab survey on a bare stage cannot tell those apart.
- **Sites need wear, not density.** "Nothing organises the ground plane...
  until a path enters a site and the grass dies where feet go, no site will read
  as a place." A different lever from the scatter density the corridor lane is
  tuning.

## What recurs across independent critics

The strongest signal in the sweep is agreement between critics who could not
see each other's work.

- **The oxblood danger colour has leaked twice** — onto the player's buildable
  roof (D5) and onto the ironwood gatherable's canopy (D6). Neither critic was
  told the colour meant anything. The roof is fixed; the canopy is not.
- **The Team Tether badge floated** — reported by three critics in three
  surveys, including the ground survey, which mentioned "a detached orange
  sphere floating beside the Warden's face" without being asked about
  characters at all. Fixed.
- **The trainer is the game's best asset and its style anchor** — said
  independently by five critics. D3 round 2: "the toon family's material
  quality is honestly competitive". D1 round 2: "keep this as the style anchor
  — because almost nothing else matches it."
- **Night is an absence, not a mood** — every survey that shot night said so,
  and each added that the CHARACTER stays lit while the world goes black.
- **No clouds anywhere** — D1 and D7 both counted every day frame and found none.

## This sweep's own harness defects, and what they cost

Recorded because it is the single biggest process lesson here: **six times, a
survey photographed something other than its subject**, and a critic spent
findings on it each time.

1. Corridor: the player seated inside two captains' colliders, rendering as a
   3.5 m totem pole in three frames. Fixed; round 2 does not mention it.
2. Creatures: no contact shadows (the stage never enabled them; the shipped
   world always had them) and every creature seated on its own pivot rather
   than the ground line, so **the 1.80 m ruler lied**. Fixed; round 2 confirms.
3. Ground: the same captain-collider bug, because the corridor's fix lived in
   one tool and was not ported. Fixed.
4. Ground: band 3 photographed a Team Tether checkpoint under the label
   "river-lock"; the river picker landed on index 9 of 19 — dead centre of the
   narrows its own comment warned against; grazing shots rotated a fixed 90°
   with no idea which side was wet, so several faced inland. Fixed.
5. Items: the icon sheet was clipped, hiding the TMs and key items; every
   held-tool frame shows the tool STOWED rather than in hand.
6. UI: two element frames came back blank, and the survey wrote zero frames on
   its first run because it read the `Game` autoload before the tree mounted it.

7. **Characters: the cast stage had no ground plane and no shadows at all**, and
   the creature tool's own fix for exactly that (#2 above) was never ported. Sole
   lines disagreed by 24px under a camera the tool's header calls identical, so
   every height a critic derived from those frames carried that error. Also: the
   heights the tool measures were printed to STDOUT and never into the frame,
   leaving the rubric's whole scale criterion as the critic's arithmetic problem;
   and the line-up frame rendered the entire cast as a 58-pixel strip in an 800px
   plate. All fixed by VIS-CAST.
8. **Creatures: one front-on camera**, while several species carry their board
   signature on the BACK — and every `overlays` entry selecting on `up_min` puts
   growth on upward-facing surfaces by definition. Raising terrapup's leaf
   coverage tripled its green texels (3.8% -> 11.3%) and barely moved the
   front-on frame. A rear three-quarter view is now shot for every species.
9. **THE EXPENSIVE ONE. Both stages were over-exposing every lit subject, the
   creature stage by a measured 2.3x**, and THREE consecutive blind creature
   rounds spent their top-ranked finding on the result -- "the roster floats in
   high-key pastel", "25-50% of body highlight regions clipped to pure white",
   a duskhush called "candy lavender" whose own texture measures mean 65.6.

   The art was never pastel; the photograph was. The proof is inside every frame
   and costs one line to check: the BACKDROP is `BG_COLOR` and unlit and rendered
   at exactly its authored (51,56,61), while the FLOOR carries albedo
   (0.30,0.33,0.30), should land near (77,84,77), and rendered at (174,200,184).
   Unlit exact, lit 2.3x out. Cause was addition: ambient 1.5 at a near-white
   colour is ~1.17 before a 1.6 key adds ~0.91, and creature materials are
   self-lit on top of that.

   **Every capture stage in this sweep contains a known-albedo surface. Measure
   it before trusting a single colour verdict taken off that stage.** Both cast
   and roster tools now document their floor as the calibration target.

The pattern: **a fix that lives in one tool does not protect the next tool that
does the same thing.** Ported helpers, not per-tool patches. And the newer
pattern #9 adds: a survey that is not exposure-calibrated is not photographing
the wrong subject, it is photographing the right subject wrongly, which is
harder to notice and costs whole rounds.

## Findings the capture pass has already produced

These came out of authoring the tools — reading what the game actually
references — and none of them needed a critic to see. Each is a defect a
player meets, recorded here so a blind round is not spent rediscovering it.

- **Every Team Tether character is a repainted Warden.** `npc_ranks.gd`
  hardcodes his rig as the base body for grunt, officer, captain and Warden
  alike, and `npc_ranks.json`'s own comment says that was a stopgap "until the
  only faction-appropriate rig actually installed is the Warden's". One IS
  installed: `assets/characters/grunt/grunt_lod0.glb` is imported, sits on
  disk, and is listed by `docs/art/HUMANOID_ASSET_INVENTORY.md` — which
  CLAUDE.md makes authoritative — as a "reusable Team Tether rank-and-file
  archetype", under a rule that says to use the grunt family for ordinary
  Team Tether personnel "rather than repainting a civilian and calling it a
  grunt". Nothing in `data/config/` or `scripts/` references it. This is the
  root of a defect two blind rounds have already circled in other words: the
  rank ladder reads as "someone duplicated a mesh four times and nudged an
  exposure value", and no palette tuning fixes four copies of one body. The
  antagonist faction the player fights for a whole chapter has one silhouette.
- **The hammer is an axe.** `items.json` gives `hammer` a `held_model` of
  `quaternius_survival/Axe.obj`. The player swings a visible axe to build.
- **The hoe is a pickaxe, twice over.** `hoe` draws `Pickaxe_Bronze.gltf`, the
  same mesh as `pickaxe`, AND uses `pickaxe.png` as its icon — indistinguishable
  in the hand and in the backpack. The fishing rod equips nothing at all.
  (`hoe`'s mesh reuse is a documented D24 stand-in; the icon collision and the
  hammer are not flagged anywhere as deliberate, and both are visible during
  the game's core verbs.)
- **Half the inventory is visually duplicated.** 28 of 55 items share an icon
  with at least one other item. `potion_small.png` covers 7 (the small potion,
  three elixirs, three tonics), `tm_charged.png` covers 9 TMs, `stone.png`
  covers stone/rootstone/heartstone. Rubric criterion 1 asks what is still
  identifiable at 30%; for half the inventory the answer is "the wrong item".
- **There is no alpha creature ART.** "Alpha" is purely
  `creature_body.apply_size_multiplier()` — a scale field. No elite creature
  material exists anywhere in `scripts/creatures/` or the band spawn tables.
  An alpha is a normal creature that is bigger.
- **The chapter has one colour.** Measured across the 12-frame day corridor:
  eleven of twelve frames carry exactly three hue families, and the same three
  every time — blue, chartreuse, yellow. That is the numeric form of the
  standing "palette incoherence" finding, and the baseline any groundcover or
  lighting change has to move.

## Standing facts a round should not re-derive

- **The bar is Palworld** (`docs/reference/palworld-0*.jpg`) and the project's
  own keyart (`docs/reference/tetherbound-meadows-keyart.png`). Both bar
  questions have historically answered **NO**.
- **Creatures and characters are the point**, not a footnote — the rubric says
  to say so first and plainly when they do not hold up.
- **No new creature meshes for the Meadows, ever** (CLAUDE.md). Differentiate
  with materials, textures, scale, animation, VFX, habitat, behaviour.
- **The 1.80 m trainer is the ruler.** A survey with no character in it cannot
  be asked the scale question at all — that invalidated a whole D5 round.
- **A capture with the player parked away from the shot photographs an empty
  world**, because creature spawning is driven off the player, and Terrain3D
  streams around whichever camera it was handed.
- **Pin the clock AND freeze it.** A pin that is not frozen wears off across a
  multi-viewpoint pass and the late frames come back in a dusk wash.
- **Never `--headless` with a real rendering driver.** It hangs forever with no
  error, and leaves zombie processes that then cause real contention.
- **A capture stage must be exposure-calibrated against a known-albedo surface
  before it is asked a colour question.** Three creature rounds were spent on a
  2.3x over-exposure. One line of arithmetic against the stage's own floor
  detects it.
- **`character_model.gd`'s emission floor is ADDITIVE now and was not before.**
  It lerped the emission COLOUR, which Godot uses as a multiplier over
  `emission_texture` while `emission_operator` is MULTIPLY -- so it could only
  darken, the exact law it was written to escape. Team Tether rendered at
  0.11-0.18 lightness because of it.
- **Terrapup and burrowback do NOT share a mesh** (a round-2 finding, checked and
  false: 15,616 vs 17,204 verts, different bounds and POSITION bytes; no two
  species in the roster share a mesh file). They share an ARCHETYPE, which is a
  casting problem and not beyond paint.
- **The owner's creature board is a COLOUR AND MATERIAL REFRESH**, not a
  commission. Its own header says "Use existing meshes/rigs/animations" and its
  implementation notes say "Keep silhouettes and anatomy the same". Read every
  "the board paints a different animal" finding against that.
