# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play checkpoint. **Gates no longer stop the loop** (owner
directive 2026-08-09, D21): the loop lists them in `BLOCKED.md`'s play-gate
section for the owner and keeps building past them. `🔒` needs Meshy credits.
`model:` the cheapest tier that can do the job. `tests:` exactly what to run.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks (this rewrite, D18/D19's
overhaul, is the precedent — the site had claimed "sourced stand-ins" months
after the roster was real). `model: haiku` when it is just screenshots.

---

## Phase 0 — the owner played. This is the response.

**R0.10's play gate fired on 2026-08-09: the owner played the first build,
and the overhaul session that followed absorbed the entire feedback loop.**
What shipped (see `docs/HANDOFF.md` §3 and `docs/decisions/D18`–`D20` for the
full record): the giant-player fix with render-space measurement
(`render_bounds.gd`, `smoke_art`'s new [0.1,10] fit-factor trip), the combat
feel pass (auto-face on windup, lunge at windup start, 0.3s input buffer, new
speeds), orbs and potions as real items granted by Grandpa's `give:` dialogue
effects, the throw trajectory preview and the finally-wired aim profile, the
D19 roster resize, `spawns.json` replacing `WILD_SPAWNS` (D20), the indoor
opening in Grandpa's farmhouse (D18), the village and baked dirt paths, and
the website redesign.

**It also absorbed much of Phase 2's first-day scope**: ~10 authored harvest
nodes for wood/stone/fiber/berries (part of old R2.1), camp placement with
ghost preview and real material costs (old R2.4's core, proving the
`build_cost_for` path D16 demanded), campfire + bedroll (part of old R2.6),
and rest-until-morning advancing the day counter and healing (old R2.8's
core). What those items still owe is listed under Phase 2 below.

### R0.11 ▶ Play gate — the owner plays the NEW first day, end to end
Wake in bed upstairs → downstairs to Grandpa, the belt, orbs and potions →
out the door to the three starters → choose and name → the village square and
the paths → harvest along the tutorial route → a fight and a catch → make
camp before dark → rest to morning, day counter ticks. `GAME_DESIGN.md` §33
criteria 1, 3, 6 and 11 — plus the two things D19 flagged for exactly this
playtest: does the combat camera crowd at the new sizes, and does the arena
still feel roomy.

---

## Phase -1 — urgent PC bugs (owner-reported, 2026-08-10)

The owner played the published Windows build. One bug left, ahead of
everything else in this file — **do this first, then Phase -0.5, then
Phase 1 onward.**

**RB1 (mouse look) — the first fix was WRONG. The real cause is found and fixed;
see `RB1-actual` in `DONE.md`.** The owner reported on 2026-08-11 that mouse look
*still* did not work after RB1 shipped, which is the on-device confirmation that
entry was waiting for and it came back negative.

RB1 blamed a mouse capture dropped before the window had OS focus and
re-asserted capture on `focus_entered`. That was diagnosed by reading code and
never reproduced, and it was the wrong cause. The real one:
`scenes/ui/playground_hud.tscn`'s `Root` is a **full-rect `Control` with no
`mouse_filter` line**, so it took Godot's default of `MOUSE_FILTER_STOP` and
consumed every `InputEventMouseMotion` during GUI handling — which runs *before*
`_unhandled_input`, where `camera_rig.gd` accumulates look. Every other UI scene
in the project already sets `mouse_filter = 2`; this one missed it.

**RB1's fix is kept.** Re-asserting capture on focus gain is correct behaviour
and `SH53` still wants it. It simply was not this bug.

Note also that RB1's entry contains a **disproven guess**: it suggested the
owner could not reach Grandpa because they could not turn toward him, "a symptom
of RB1, not a second bug." That was wrong — `SA0` later root-caused the Grandpa
report to a one-way beat machine. Two separate real bugs, and the guess linking
them cost time.

**RB2 (walk/run animation) fixed — see `DONE.md`.** Real bug, found after
the owner corrected an earlier wrong "already fixed" pass this same firing:
every baked humanoid clip shipped `Animation.loop_mode = LOOP_NONE`, so
`character_model.play()` played walk/sprint once and froze for as long as
the state held — creatures already avoided this (`pal_animator.gd`), humans
never did. Fixed in `character_model.gd`/`trainer_model.gd`, verified by
`tests/smoke_input.gd` reading `loop_mode` directly and by real rendered
screenshots. Real on-device confirmation by the owner is still worth having,
same as RB1, but this one no longer needs it to know the bug was real.

---

**RB3 (smoke_aggression flake) fixed — see `DONE.md`.**

**RB4-diagnostics (startup boot log) shipped — see `DONE.md`.** **RB4
(Ally freeze root cause + fix: switched to the Compatibility renderer)
shipped — see `DONE.md`.** Real on-device confirmation that the freeze is
actually gone on the Ally is still worth having, same as RB1/RB2, but the
diagnosis and fix no longer need it to know the bug was real.

---

## Phase -0.95 — the loop itself (`D25`)

One item, above everything, because it is upstream of everything: a flaky test
does not fail *its own* task, it fails whatever healthy branch happens to be in
flight when it flakes, and `ralph-merge.yml` only ships green.

**`LP1` (the `smoke_traversal`/`smoke_combat` flakes) fixed — see `DONE.md`.**

**`LP2` (the `smoke_opening` beat-3 press-count flake) — a pattern-matched fix
shipped, the underlying race not directly reproduced. See `DONE.md` for the
full elimination trail and what would still confirm it.**

---

## Phase -0.9 — the two blockers from the published build (owner, 2026-08-11)

**`SA0` (the opening soft-lock) shipped — see `DONE.md`.** The owner could not
interact with Grandpa at all and left the house with no starter. Root cause was
not the interaction system: the beat machine started at `wake`, `wake` had
exactly one exit (pressing the bed), and nothing forced it — so walking off the
bed pinned the beat forever, which keeps Grandpa's interactable disabled by
design. Fixed, plus the second route in (a houseless world had no exit at all),
plus a falsifying test (`tests/smoke_wake_softlock.gd`).

**`SA1` (Ally VRAM) shipped — see `DONE.md`.** ~630 MB reclaimed: 91 textures
moved off Lossless RGBA8 to S3TC, twelve 2048² all-black emissive maps shrunk to
4×4, foliage mipmaps enabled, both shadow atlases off the 4096 desktop default,
MSAA 4×→2×. **On-device confirmation is still open** — CI cannot measure VRAM,
same as `RB4`.

**`SA0-orbs` (starter choice moves into Grandpa's conversation) shipped — see
`DONE.md`.**

**`SA0-orbs-remainder` (lighting depth, UI chrome ownership, creature appeal)
shipped/resolved — see `DONE.md`.** All three sub-questions closed: a rim light
plus a selected-label treatment shipped (round 5 and 6 of the blind-judge pass,
five rounds total), `EV9`'s own scope note now names the narrative panels
explicitly, and the roster-wide creature-appeal question moved to `BLOCKED.md`
for the owner rather than staying stranded in a backlog item nobody could
execute.

**`SA1-lod` (vegetation discarding the importer's LOD chain) shipped — see
`DONE.md`.**

---

## Phase -0.6 — the look (owner's art bible, `D24`)

`docs/ENVIRONMENT_AND_UI_BIBLE.md`, made canon by `docs/decisions/D24`. This is
the answer to *"the visuals is the most important part… and it's not getting
fixed"* — and R9.4's own evidence agrees: both blind critics ranked **"needs art
that is not in the build"** first, and scene tuning had genuinely run out of
road. The repo has 42 of 116 nature models, **no** village kit, **no** props
kit and **no** UI assets beyond two portraits.

**Free Standard tiers only** — the owner declined the Source editions, so their
foliage shaders and optimised collisions are not available and nothing may
assume them. Ledger every pack **before** its commit; the ledger's own rules
require it.

### EV1-remainder — Acquire the two Quaternius MegaKits itch.io is blocking
`model: haiku` · `tests: none` · `area: assets`
**The Kenney half of EV1 shipped — see `DONE.md`.** All four HUD/icon packs
(UI Pack, RPG Expansion, Input Prompts, Game Icons + Expansion) are ledgered
and staged under `assets_raw/vendor/`, downloaded straight off `kenney.nl`'s
own CDN, no gate. What is left is the Medieval Village MegaKit (`EV6`'s
settlement family, settled by `D24` — no substitute kit) and the Fantasy Props
MegaKit (`EV7`), plus the fuller Stylized Nature MegaKit if `EV2`/`EV3` end up
wanting more than the 42 models already present.

**Both are blocked on itch.io's anonymous-claim flow, not on a design
question.** `quaternius.com`'s own download button is itch.io's embedded
widget; the itch game page it opens serves the file list (`Medieval Village
MegaKit[Standard].zip`, confirmed 153 MB, genuinely $0 not just
pay-what-you-want) only *after* a client-side "Download Now" click completes
a purchase/claim round-trip — the per-file `upload_id` a direct download URL
needs is never present in the page's static HTML, before or after that click,
so `curl` cannot reach it no matter how the request is shaped. Headless
Chromium was tried next (Playwright, browser already installed in this
environment) and ruled out for a more basic reason: it cannot open **any**
HTTPS site through this session's proxy, including unrelated control domains
(`example.com`, `kenney.nl` itself) — `net::ERR_CONNECTION_RESET` on every
`page.goto()`, launched with the proxy passed explicitly. `curl` reaches all
of the same hosts fine, so this is specific to Chromium's proxy handling in
this sandbox, not a site block. See the `BLOCKED.md` entry for what would
clear it. Done when: both zips are staged under `assets_raw/vendor/` and
ledgered, same as the Kenney four.

**`EV2` (an approved Meadows nature subset) shipped — see `DONE.md`.** Hero
trees and standard canopy curated to the bible's counts with controlled
material variants; wetland forms and a distinct rock large-tier are honest
remainders, not done. Two new findings opened below: `EV2-trunk-colour` and
`EV2-landmark-ceiling`.

### EV2-trunk-colour — Tree trunks render pale salmon/pink instead of brown bark
`model: sonnet` · `tests: none` · `area: vegetation`
Found by two independent blind critics during `EV2`'s rounds 1 and 2, both
unprompted and specific: "trunk color reads unnaturally pale pink/salmon,"
"every tree trunk in every frame is an unusual pale salmon/pink-tan color
rather than brown bark... more visually odd than anything in the canopies."
Not a texture bug — `Bark_NormalTree.png` and `Bark_TwistedTree.png` measure
RGB(140,88,67) and RGB(84,76,72) respectively, both ordinary warm/neutral
browns, and no layer in `vegetation.json` retints `Bark_NormalTree` or
`Bark_TwistedTree` at all. The likely cause is thin trunk geometry (a few
pixels wide at typical survey distance) combined with strong directional sun
and texture minification washing the brown toward a pale warm tone under the
Compatibility renderer — but this is a guess, not root-caused. Not chased
under `EV2` because it isn't a model-selection or retint-config question, the
tools for it are lighting/material, and `lighting` is a currently-contested
area. Done when: the mechanism is found (screenshot comparison of the same
trunk at different distances/angles would confirm or rule out the
minification theory) and either fixed or shown to be a Compatibility-
renderer-only artifact that doesn't affect the shipped Forward+ build.

### EV2-landmark-ceiling — Hero trees don't read as landmark specimens even at the best 3-of-5 subset
`model: sonnet` · `tests: none` · `area: vegetation`
`EV2` curated `grove` to the 3 TwistedTree forms with the widest footprint,
tallest height and most asymmetric silhouette (measured, not guessed). A
blind critic still ranked this the #1 gap against the key art: "nothing in
these five frames comes close to the key art's oaks, whose canopies are
wider than they are tall and whose trunks visibly fork and lean... the
current asset's silhouette ceiling won't get there just by rescaling."
This is a real asset ceiling, not a placement/curation problem `EV2`'s own
lever (which models, what tint) can solve — the fuller Stylized Nature
MegaKit that might carry a genuinely broader-canopy hero form is itch.io-
blocked (`EV1-remainder`), and `CLAUDE.md`/`D24` forbid a Meshy generation
for a routine nature asset regardless. Not a `BLOCKED.md` design question —
there's no decision to make, just an asset gap with a known unblock path.
Done when: `EV1-remainder`'s itch.io block clears and the fuller pack is
searched for a broader-canopy hero form, or the owner accepts the current
ceiling.

### EV3 — Rebuild the scatter around clusters, clearings and layered bands
`model: opus` · `tests: smoke_art` · `area: vegetation`
Bible §7B/§7C/§9. Seven vegetation bands from ground grass to distant tree mass;
placement driven by slope, elevation, path distance and landmark distance rather
than uniform noise. Absorbs `SA1-lod` if not already done, and `R7.1-remainder-2`
(ground cover reads procedural) outright. Done when: a blind critic stops
calling the scatter generator output.

**EV4's mechanism (paths as a real control-map material, not a colour-map
tint) shipped — see `DONE.md`.** Five blind-judge rounds; the first four
tuned the wrong texture, round 5 wired in `Ground030` (sourced independently
by another lane specifically for this, credited in `DONE.md`) as a dedicated
`path` texture and the material genuinely improved — a fresh critic called it
"real progress... works as a navigational read." Two narrower remainders
opened below from round 5's own honest read of what is still wrong.

**`EV4-textures` (moss-blotch saturation, and the slope-specific edge stepping) shipped — see `DONE.md`.** Three local blind-judge rounds, both original complaints converged: edge-stepping never reproduced past a mild, ambiguous waviness and a third critic called it "largely resolved... no rectangular notches"; moss saturation measurably dropped (0.36 -> 0.09, at/below the texture's own baseline) via a direct, feathered-mask edit to the CC0 source photo rather than fighting it through a tint multiply. **Two new findings from round 3, out of this item's scope, opened below**: the path reads paler than the references even where moss is fully resolved, and an unmotivated hard-edged shadow crosses sunlit path frames.

### EV4-textures-remainder — Moss blobs still read as a "stamped decal," a content limit not a tunable value
`model: sonnet` · `tests: none (visual)` · `area: terrain`
`EV4-textures`' third round confirmed real, described saturation improvement
("no longer hard flat circles... softer-edged") but the critic's complaint
shifted rather than closing: the moss patches' own roughly-circular,
similarly-sized SHAPE and semi-regular scattering — real content in
`Ground030_Color.jpg`'s source photo, not a saturation or blend bug — still
reads as "a repeated stamped-decal layer" at close range. No colour/tint/
normal_depth lever reaches this; it would need either a different or
re-worked moss layer (irregular, elongated along wear lines, varying
density) painted into the texture, or a second, sparser decal-style overlay
rather than one uniform photo tile. Low priority — genuinely a finish
question, not a bug, and the underlying saturation defect that made it read
as broken is gone. Done when: a blind critic stops calling the moss pattern
a decal/stamp.

### EV4-textures-lighting — An unmotivated shadow band and blown-out highlights on sunlit ground, reproduced across three independent blind critiques
`model: sonnet` · `tests: none (visual)` · `area: lighting`
Found while judging `EV4-textures`, and named independently by all three
critic rounds in some form ("hard-edged, blob-shaped shadow," "hard-edged
sunbeam/light overlay," "unmotivated shadow band... no caster visible in
frame") — not a path-texture defect, a lighting one, so it stayed unfixed
through three rounds of path-only tuning while showing up in every one.
`square-convergence.png` and `grandpas-house-route.png` both show a large,
soft-edged but tonally abrupt dark diagonal shape crossing open ground with
nothing in frame tall enough to cast it, and the LIT two-thirds of the same
frames blow out to near-white with almost no value modulation — Palworld and
the key art hold a warm mid-value ochre even in full sun. `SA1` shrank both
shadow atlases off the 4096 desktop default for VRAM; a low-resolution
shadow atlas under a single directional light over open, largely flat
ground is a plausible cause of exactly this symptom (soft-edged but
tonally-hard shadow blobs) and is the first thing whoever takes this should
check before assuming it is a `world_look`/time-of-day config problem.
`EV8` (lighting, in flight elsewhere in this backlog) may already cover
this — check its outcome before duplicating work. Done when: a blind critic
given a sunlit ground frame stops naming an unexplained shadow or blown
highlight.

### EV4-hillside-seam — Blotchy hillside slope material, confirmed pre-existing
`model: sonnet` · `tests: none (visual)` · `area: terrain`
Found by `EV4`'s round-3 blind critique as a hard zigzag; round 5 gives the
attribution question that entry left open a real answer. `EV4` reverted
`soil` to its exact original R9.4 values once paths got their own dedicated
texture (round 5), so the hillside band is now byte-for-byte the same
configuration that shipped before `EV4` touched anything — and a fresh blind
critic, seeing only round-5 frames, still called the hillside "mottled...
blotchy all over the dome... more like camouflage or a poorly blended
multi-layer texture than a natural grass→dirt→rock transition," plus a hard,
unblended seam where grey rock cuts in at the hill's base. **This settles it:
pre-existing, not introduced by `EV4`.** Whoever takes this should treat it
as an independent slope-material defect — `blend_deg`/`blend_sharpness`
tuning, or the "collapse to one dominant texture" approximation showing
through on a genuinely three-way grass/soil/rock band — not as unfinished
`EV4` work. Done when: the grass/soil/rock slope boundary on a steep rise
reads as a coherent material transition rather than a patchwork.

**`Ground037` (mossy forest floor, ambientCG, also pre-sourced and ledgered
alongside `Ground030`) is still unused.** Bible sec8 item 5, Deep Grass/
Forest Floor, painted near the valley basin or under tree canopy once `EV3`
gives the bake real tree-placement data to key off. Whoever picks up that
layer should reach for it directly rather than re-sourcing.

### EV5 — Water
`model: opus` · `tests: smoke_traversal` · `area: terrain`
Bible §15. A pond and stream: readable stylised surface, shallow-edge colour
shift, reeds at the banks, no expensive simulation. Answers the open question in
`R7.1-remainder-2` and gives Band 3's river somewhere to start.

### EV6 — Rebuild the settlement on one architectural family
`model: opus` · `tests: smoke_opening, smoke_traversal` · `area: village`
Bible §12. Medieval Village MegaKit as the one civilian vocabulary; prefabs
built once from modules, not assembled from loose pieces at runtime. Every
building grounded — flattened terrain only where needed, grass transitions,
footpaths, a foundation. Absorbs `R9.4-remainder-3` (no material override path)
and half of `-5`. Grandpa's house was rebuilt by R9.4 and may or may not survive
the kit; judge it against the family rather than preserving it out of sentiment.

### EV7 — Prop clusters that imply a purpose
`model: sonnet` · `tests: none` · `area: village`
Bible §2 P3: *do not* dump props everywhere. Authored clusters — work area,
farmhouse yard, bridge repair site, quarry station, trainer camp. Absorbs the
rest of `R9.4-remainder-5`.

**`EV8` (lighting and atmosphere) shipped — see `DONE.md`.** Two rounds of the
blind pass. Warm sun and cool fill were already correct and are unchanged;
the pale-horizon and sky-inconsistency defects (`R9.4-remainder-2`) are fixed.
A parallel lane independently fixed a narrower instance of the same
sky-inconsistency class in `tools/capture_site_shots.gd` (a website capture
tool, not the exploration survey) — see `DONE.md`'s follow-on entry.

### EV9 — Rebuild the HUD
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Native `Control` nodes over Kenney UI + Input Prompts. Dark
translucent panels, teal accent, warm gold for progression, no fantasy scroll
frames. Inventory grid, crafting panel, one tracked objective, contextual
prompt. **Tested at physical 7-inch scale, not on a desktop monitor** — §17 is
explicit. Input glyphs follow the last-used device.

**First slice shipped 2026-08-11 (`eea16a9`): the exploration HUD only.**
`scripts/ui/playground_hud.gd`/`scenes/ui/playground_hud.tscn` rebuilt —
styled health/stamina bars (dark translucent panel, teal border, rounded
corners, labeled "HP"/"STA") that fade to a low-emphasis state when full and
idle, a party/orb count panel, and the contextual interact prompt read live
from `InteractionArbiter`. The old always-on debug telemetry dump still
exists but is now F3-toggled instead of covering a third of the screen.
Blind visual-judge (3 rounds, `tools/capture_exploration_hud.gd`) converged
on "coherent, intentional HUD"; remaining gaps were named explicitly as
needing new assets rather than more scene tuning.

**Still open — do NOT re-scope these as a separate item, they are this
item's remainder:**
- Inventory grid (`tab_backpack.gd`) and crafting panel (`tab_build.gd`)
  re-skin onto the same dark/teal panel language. Both are fully functional
  today, just unstyled — see the survey any EV9 firing should re-read before
  starting (search `ralph/DONE.md` for "EV9" or read this entry's own
  history) for the exact API surface (`Game.inventory`, `Game.items`,
  `revision` polling, `menu_tab.gd` contract) `smoke_menu.gd` depends on.
- ~~The "[X] / [E]" input-glyph replacement...~~ **Promoted to `HD1`,
  Phase -0.85, 2026-08-11 — owner hit this directly** (mouse sees gamepad
  letters; gamepad is told to press "F" for a bind that's actually RB).
  Scope unchanged, just moved so it's not buried in a remainder list: still
  needs a last-used-input-device tracker, still touches `dialogue_panel.gd`,
  `name_prompt.gd`, `starter_picker.gd` and now also `combat_hud.gd` (checked
  2026-08-11: it hardcodes "A"/"X"/"B" too). Kenney Input Prompts already
  staged at `assets_raw/vendor/kenney_input-prompts/` via `EV1`.
- The "one tracked objective" line has nothing to read yet — `SB9`/`SB11`
  (progression-state system, quest log) are still open. Wire the label once
  that state exists; a label bound to nothing is a permanent blank box, the
  opposite of §16's "hide/fade what's not relevant."
- Compass — bible says "if it exists"; it doesn't yet, not this item's job to
  invent one.
- Icon glyphs for HP/STA/Pals/Orbs, a branded display font matching the
  "TETHERBOUND" key-art logotype, and gradient/beveled bar fills — all named
  explicitly by the round-3 blind critic as needing new assets, not scene
  tuning. No board exists for a display font; flag to the owner before
  picking one, per `CLAUDE.md`'s asset-generation rule.

### EV10 ▶ — Cohesion pass
`model: sonnet` · `tests: none` · `area: visual`
Bible §22 Phase G and §23's metrics. Re-shoot the same viewpoints, blind-judge
against both reference sets, fix the three biggest gaps, repeat until further
improvement is asset-quality-limited rather than composition-limited.

---

## Phase -0.55 — the cast (owner's NPC board)

`docs/art/reference/12_NPC_Bases_Reusable.png`, and spec §21/§22/§35/§36.
The board specifies **three** base bodies at player height — Female Villager,
Male Villager, Team Tether Grunt — each with hair/head variants, outfit
variants, palette rows and accessories, and it **supersedes §22's "one or two"**.

Its own implementation notes are the technical brief: *material/texture swap for
colour variants, hide/show accessories via separate mesh parts, hair variants
sharing head topology, keep colour calls low by using shared materials.*

**`NP1` (the modular NPC variant system: per-material palette, hair,
accessories, all data) shipped — see `DONE.md`.** The hair/accessory shapes
are placeholder primitives, not real geometry — none of the three rigs has a
separable hair or accessory mesh yet. **`NP1-geometry`** (new, `area: npc`,
blocked on `NP4` or `EV1-remainder` supplying an actual modular mesh) is the
follow-on: wire real hair/accessory geometry into an actual NPC and run it
through the blind-visual-judge pass, which this ship did not need — nothing
in the live village's own config changed, so nothing a player sees changed.
**Trap for whoever takes it:** `_attach_part()` sets a placeholder's
`offset`/mesh size as a *local* child of a `BoneAttachment3D` inside the
same 0.01-scale Armature chain `docs/HANDOFF.md` §6 documents for the
giant-player bug — `NP2` measured it directly, a "size 13" primitive
renders as 0.13m, a factor of 100. `_apply_hair()`'s own `0.08` offset is
almost certainly landing at ~0.0008m in the live game, effectively at the
bone origin rather than actually offset. Real geometry from a modular mesh
may sidestep this by not needing a manual offset at all — but if this item
still calls `_attach_part()` for anything, budget time to fix the scale
compensation there rather than rediscovering the same trap `NP2` did.

**Correction, found by `NP2`: the palette mechanism itself was invisible.**
All three human rigs' materials carry `emission_enabled = true` with
`emission_texture` set to the same painted albedo texture at a full-white
multiplier. Emission is additive and independent of lighting, so it swamped
any `_apply_palette()` tint completely — proven with a diagnostic that
tinted the Warden pure red and rendered him fully green, unchanged.
`character_model.gd`'s `_shared_variant_material()` now tints emission the
same way, so this is fixed for every caller, not just `NP2`'s — but it means
R7.2's three villagers, believed visibly tinted since `NP1` shipped, have
never actually looked different from each other in a rendered frame. Worth
a look next time anyone is near `village_npcs.gd`.

**`NP2` (Team Tether rank palettes) shipped — see `DONE.md`.** Grunt,
officer, captain and Warden, all on the Warden's rig (the only faction-
appropriate body installed; `NP4`'s Grunt has no game path yet, see
`NP4-rig`). A body-tint-only ladder failed blind review outright ("a
lighting gradient, not a rank system"); the real rank marker that shipped
is a chest badge using `NP1`'s own accessory mechanism, escalating in both
colour and size, converged after 3 rounds.

### NP3 — The named Meadows cast
`model: sonnet` · `tests: test_dialogue_runner` · `area: npc`
Spec §35. Mira, Oskar and Tam get their trainer identities — **they already
exist** in `village_npcs.json`, do not add three more bodies — plus the quarry
foreman and the rescued ranger/researcher. Done when: every named NPC the
chapter needs exists on a reused rig.

**`NP4` (generate the three bases) shipped — see `DONE.md`.** Two of three
(villager_female, grunt) passed a two-round blind critique; villager_male's
trousers render darker/colder than the reference after three texture
attempts and villager_female has a persistent UV-seam texture blotch on one
shin — both recorded there as an honest remainder, not chased further after
two flat attempts each per `conventions.md`'s stopping rule.

**`NP4-rig` (rig, animate and install the three NP4 bases) shipped — see
`DONE.md`.**

---

## Phase -0.75 — the owner's Meadows spec, P0 (owner directive, 2026-08-11)

`docs/MEADOWS_PROGRESSION_SPEC.md` §1 and §38 Phase A, made canon by
`docs/decisions/D23-the-meadows-is-the-first-game.md`. Owner-reported from a
real playtest of the published build, the same way Phase -1 was — **above the
rest of Phase -0.5**, because three of the five change what a survey frame
contains and judging a build that is about to change wastes a render pass.

Step 1 of the spec's Phase A — the PC mouse-capture lifecycle (spec §1C) —
**already shipped as `RB1`; do not rebuild it.** `playground_world.gd`
re-asserts capture on `Window.focus_entered` and backs off through
`_mouse_wanted_elsewhere()` for menu, dialogue and the name prompt, which is
the same mechanism §1C's Escape / menu-restore / Alt-Tab clauses describe. The
spec's ten-minute acceptance test is on-device work and is tracked as `SH53`,
not as a reopening of RB1.

### SA2 — Grandpa's door cannot be crossed until the opening beat is done
`model: sonnet` · `tests: smoke_opening`
Spec §1D. The owner walked straight out of the farmhouse and skipped the man
who gives you the belt, the orbs and the potions — the whole of
`OPENING_SEQUENCE.md` beat 3. Canon rule: **the player cannot leave the house
until the required Grandpa interaction is complete.** Not a "Talk to Grandpa
first" toast — §1D asks for the in-world form: crossing is stopped, Grandpa
calls out ("Hold on. You're not walking out there empty-handed."), attention
redirects, and the conversation starts itself. The gate reads
`sequence_director.gd`'s current beat against `opening.json`'s beat order and
lifts for good once the briefing is done; `grandpa_house.gd` owns the doorway.
Once lifted it never re-arms. Done when: `smoke_opening` walks the player at
the exterior doorway *before* talking to Grandpa, is stopped, and the briefing
conversation is running without the test having pressed interact.

### SA3 — A believable physical perimeter, and a failsafe under it
`model: sonnet` · `tests: smoke_traversal`
Spec §1E. `terrain_playground.json`'s `world_size` is 512 m and everything past
the bake is Terrain3D's `world_background` — drawn, never collided. The Meadows
currently ends in the one way §1E says it must not: like a floating level.
Build the edge out of things you can see — fieldstone walls, ranch fencing,
hedgerows, terrain ridges, rock formations, dense impassable growth. Invisible
collision *supports* a visible boundary and is never the boundary by itself. A
kill/respawn volume below the world is a failsafe, not the design. Done when: a
headless walk on eight compass bearings from spawn is stopped by something the
player can see at every bearing, and a teleport below the terrain returns the
player to safety instead of falling forever.

### SA4 — Seven outward spokes, each believably severed
`model: sonnet` · `tests: smoke_traversal`
Spec §1E and §29. Seven routes leave the perimeter — river gorge (Water), old
storm road (Electric), mountain trail (Fire), high pass (Ice), cliff road
(Air), ancient stone gate (Psychic), sealed blighted road (Dark) — each blocked
by something physical: collapsed bridge, rockslide, flood, damaged lift, Tether
blockade, sealed gate. **No "Biome Locked" messaging, ever** (spec §19, and
`GAME_DESIGN.md`'s traversal pillar). §29 is what gives them meaning: these are
severed old roads, not seven dead ends someone built — broken roadbed, old
signage, abandoned trade infrastructure, land visible on the far side. This is
the seed `R8.6` pays off and the geometry `SF33` later dresses. Done when: all
seven are reachable on foot from the village, each is visibly and physically
impassable, and none of them explains itself with UI text.

### SA5 — Recolour Burrowback away from Terrapup
`model: sonnet` · `tests: smoke_art`
Spec §1A and §20. The owner cannot tell the Ground starter from the wild
badger, and they are genuinely close: `HANDOFF.md` §2 has Terrapup as
"badger/canine cub, warm brown fur, cream face stripe" and Burrowback as a
"broad low badger". D13 already carries distinction rules for Trailpup and
Galecrest; this is the fourth and it was missed. **Geometry is frozen (§20) —
no Meshy spend, no regeneration.** The lever is `grade.py`'s repair path
(`python3 tools/art_pipeline/blender/grade.py --species burrowback --textures
assets/pals/tetherbound/burrowback/models` — plain numpy and Pillow, no
Blender): `SPECIES["burrowback"]` today carries structural fixes and no
`palette` block. Add one, toward charcoal/near-black coat, cool pale-grey face
stripe, slate nodules, restrained rust-brown belly, minimal green. Terrapup is
not touched. Visual-affecting, so `conventions.md`'s blind pass binds — and ask
the critic the silhouette question specifically. Done when: a blind critic
given both turntables side by side, told nothing, does not call them the same
creature.

**The owner's report is confirmed by a render.** R9.4 re-ran
`preview_creatures.gd` (2026-08-11): Burrowback comes out a warm mid-brown
badger with a broad **cream face stripe** and a moss-and-stone mantle over its
back — which is Terrapup's own material language, item for item, at a similar
value. Nothing about the colour currently separates them; only the body shape
does, and §1A says that is not enough at gameplay distance.

### SA6 — Separate the five birds by palette
`model: sonnet` · `tests: smoke_art`
Spec §1B and §20. Pipwing, Duskhush, Galecrest, Reedwing and Galewisp must not
read as palette swaps of one another. Same constraint and same mechanism as
`SA5` — `grade.py` `palette` blocks, no regeneration — with the palettes §20
names: Pipwing ochre/gold + cream + charcoal; Duskhush slate/lavender-grey +
muted cream + amber eyes; Galecrest rust/chestnut + charcoal + pale sand;
Reedwing deep teal + cream + copper/tan + orange bill and feet. **Galewisp
keeps its established palette and is not touched.** §20 says to push the
separation harder than would normally be necessary, because the meshes overlap
more than ideal and colour is the only lever left. Two traps already paid for
in `conventions.md`: `grade.py`'s eye guard is mandatory, and Ripplet's eyes
were destroyed once by a hue-band guard on a body of the same hue. Done when: a
blind critic shown all five as black silhouettes *and* as colour turntables can
name five distinct creatures.

**Start here, from R9.4's roster render (2026-08-11).** The worst pair is not
the one §1B leads with. **Galecrest currently reads blue-grey and white with
blue wings — very close to Galewisp**, the Air starter it is explicitly
forbidden to resemble (D13 already carries that rule and it is being broken
today). §1B wants it rust/chestnut with charcoal flight feathers and a pale
sand underside, which is as far from Galewisp as the palette gets, so this pair
is both the most broken and the easiest to fix. Duskhush renders pale
cream-and-brown rather than §1B's slate and lavender-grey. Re-run
`preview_creatures.gd` before starting — and note it lays all seventeen species
in one 1280px row, about fifty pixels each, which is too small to judge colour
by; crop, or give the tool a per-species tile mode first.

---

## Phase -0.85 — HUD and item access (owner's third pass, 2026-08-11)

The owner played again and reported a long list of usability gaps. Checked
against the actual code before touching the backlog, because several of them
turned out to already be built:

**Already shipped, not backlog items — verify on-device before anyone rebuilds
them.** The active pal already follows the player automatically once adopted
(`follower_pal.gd` + `encounter_director.gd::adopt_starter()`, wired into the
live `meadows_playground.tscn`). The orb throw already shows a glowing sphere
with a halo and a trail, plus a trajectory arc while aiming (`orb.gd`,
`throw_preview.gd`) — the code comments describe this as a deliberate fix from
an earlier visual pass for this exact symptom. If either is still missing on
the owner's device, that's a bug report against a specific build, not a gap to
plan for here — check the build timestamp first.

**Genuinely new work below.** `HD1`/`HD2` are new; `R7.4` (minimap) is
promoted from Phase 7 by pointer, not duplicated; `CO1` extends the existing
follow system rather than replacing it; `SA7`/`SA8` are explicit owner
directives (`CLAUDE.md`'s carve-out applies — implementing these is not a
firing inventing a story beat).

### HD1 — Device-aware input glyphs
`model: sonnet` · `tests: none` · `area: ui`
Reproduces the owner's exact report: `combat_throw` is bound to keyboard **F**
or gamepad **RB** (button 10), but `combat_hud.gd` always prints "F"
regardless of device, and always shows Xbox-style "A"/"X"/"B" for the other
verbs even on mouse and keyboard. `dialogue_panel.gd`, `name_prompt.gd` and
`starter_picker.gd` all hardcode the same kind of bracket text. No last-used-
input-device tracker exists anywhere in the codebase — this item builds one
and wires every prompt above through it. Kenney Input Prompts are already
staged (`EV1`, `assets_raw/vendor/kenney_input-prompts/`). Absorbs the glyph
work formerly sitting in `EV9`'s remainder list — see that entry, now a
pointer here. Done when: every on-screen prompt matches the device that
produced the last input, mouse included, and nothing shows a gamepad letter
to a keyboard player or vice versa.

### HD2 — A real quick-access item hotbar
`model: sonnet` · `tests: none` · `area: ui`
Five slots, usable directly without opening the full backpack — berries,
potions, orbs. `hotbar_columns` exists in `menu.json` today but was only ever
scoped for *tool* cycling (`R2.1`, §19); this is the first item asking for a
general consumable band. Wires into the use verb that already exists in
`tab_backpack.gd::_read_use()` rather than building a second one — see the
correction on `R2.5` and the "Found along the way" entry above for what that
verb already does. Done when: a potion can be used without opening a menu,
with the correct `HD1` prompt shown next to the slot.

### CO1 — Manual pal summon, dismiss and swap
`model: sonnet` · `tests: none` · `area: story`
The owner wants a Palworld-style button to bring a pal out. The game currently
has the opposite: `encounter_director.gd::adopt_starter()` calls
`set_following(true)` unconditionally and there's no path to disable it or
choose a different one of the five belt pals for the role. This item adds a
bound action to call the active pal out or send it back, and lets the player
pick which pal is out — built on top of the existing `follower_pal.gd`
machinery, not a replacement for it. Done when: the pal can be dismissed,
recalled and swapped outside combat, with the correct `HD1` prompt for the
action.

### SA7 — A gated road out of the village, with a key nearby
`model: sonnet` · `tests: smoke_opening` · `area: story`
Owner directive, 2026-08-11: *"the castle road should be gated and it should
tell you to go find the key for something first, so then you understand what
you're doing."* New and deliberately early — separate from `SC14`'s South
Bridge, which stays as the first *real* combat-gated crossing, hours in, after
the player's first trainer battle. This one is near-field and low-stakes: a
simple physical gate on the road out of the starting village, an easy nearby
key, no real obstacle. `landmark.gd`'s distant stronghold silhouette already
gives the player something to look toward; this gives them something to
*understand* early — that the road leads somewhere gated, and gated things
have keys. Done when: a new player is stopped once, finds the key without
real difficulty, and can say in their own words why the gate was there.

### SA8 — Grandpa's opening dialogue: the Team Tether urgency beat
`model: sonnet` · `tests: smoke_opening` · `area: story`
Owner directive, 2026-08-11, close to verbatim: *someone has to stop Team
Tether; I've waited because you were too young, but they're only getting
stronger.* Write it in the existing `grandpa_house` voice
(`data/dialogue/opening.json`) as an addition, not a replacement — the
current dialogue only explains Grandpa's absence physically ("I get winded
crossing my own meadow. I'm not walking anywhere"), with no stated urgency or
motivation beyond that. **Leave the belt-limit and camp/gather lines exactly
as they are** — both already say what the owner separately asked for
verbatim (`grandpa_house`'s belt line, `grandpa_road`'s "stoop for what the
verges offer — wood, stone... make camp before dark"), and this item is only
the missing motivational beat.

**Flag for whoever picks this up:** the "too young," "waited," and "only
getting stronger" framing is not in `MEADOWS_PROGRESSION_SPEC.md` or `D23` —
checked, zero hits. It doesn't contradict canon, but it is new backstory
beyond what's specified, which is ordinarily exactly what `CLAUDE.md` asks a
firing to flag rather than invent. It's being written here anyway because the
owner supplied the actual line in this conversation — implementing a
directive is not inventing one — but this note stays so nobody mistakes it for
a firing's own addition later.

---

## Phase -0.5 — Visual pass (owner directive: finish this before R1–R8)

Everything the two 2026-08-09 blind reviews (`docs/reviews/2026-08-09-site-
frames-blind-critique.md`, `docs/reviews/2026-08-09-r0.8.5-full-blind-
review.md`) found that is fixable by changing the scene, gathered here and
worked in this order. The one finding that is NOT here on purpose: the
creature/human art-pipeline style mismatch is a design decision (rework vs.
replace assets) parked in `BLOCKED.md` for the owner — `CLAUDE.md` forbids
inventing that call, gate or no gate.

**VP2 (preview_creatures.gd rendering zero creatures) fixed — see `DONE.md`.**

**R5.1 (day/night cycle) shipped — see `DONE.md`.**

**R7.1's signposts and stronghold silhouette shipped — see `DONE.md`.** Three
bullets of the original five are still open:

**R7.1-visual (blind-reviewed the signposts and stronghold silhouette, three
rounds) shipped — see `DONE.md`.** One remainder opened below.

**R7.1-visual-remainder (new wall/roofline/crenellation geometry, blind-
reviewed over three rounds) shipped — see `DONE.md`.** Close and mid range
now genuinely read as fortified architecture; a narrower long-range
remainder is opened below.

**R7.1-visual-remainder-2 (long-range fortress read) CLOSED by R9.4 — see
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** The shape was never the
problem. Its own third round had suspected as much ("a placeholder-primitive
fortress cannot clinch this distance") and it was wrong: R9.4 rendered the same
geometry at all three ranges with a corrected material and it reads as a
fortified silhouette at every one, crenellations and varied massing included.
What was actually wrong was the COLOUR — `unshaded` at `#2a2630` is so dark a
fresh critic called it "a hole punched in the image rather than a stone ruin".
Now `unshaded` at a dark slate stone value. The two smaller findings that entry
carried are still live: the north tower's cap reads as a chimney, and the
ridge's hard-edged tan mound cap is terrain material, which `R7.1-remainder-2`
below already owns.

**The olive/lime ground seam is fixed — see `DONE.md`.**

**R7.1-remainder (ridge-bias clump placement + ground-cover clustering, three
rounds) shipped — see `DONE.md`.** Genuine, visible improvement over the
pre-fix state, but neither bullet fully passes the blind critic yet; a
narrower remainder is opened below.

**R7.1-remainder-2 COLLAPSED into `EV3` (ground cover) and `EV5` (the water
question it raised).** Not closed — superseded. It spent three rounds
redistributing a fixed instance count and the critic kept saying the same
thing, which is the signal that the lever was wrong: `EV3` rebuilds placement
around clusters, clearings and seven layered bands instead of tuning noise, and
`EV5` answers the "would water do more for depth than more vegetation?"
question it ended on by just building the pond. Its evidence is kept below
because `EV3` inherits it as the bar to clear.

Original entry — Ground cover still reads procedural, horizon mid-ground still sparse:

R7.1-remainder's third and final blind-critic round, on the post-fix survey
(owner-directed interactive session, 2026-08-10/11): the field still "reads
underpopulated" against both references (its #2 ranked gap, right behind
sky/fog consistency), and names both original bullets specifically —

- **Continuous ground cover, still not clearing.** Despite three rounds of
  tuning (bigger tufts, per-instance colour jitter, cut `strays` grass
  2000→500 / drygrass 700→200 for tighter clumping — see `DONE.md`), the
  critic still calls the scatter "roughly even spacing and uniform scale in
  02, 03, and the open ground of 01 and 05... no clearings, no clustering
  around features, and no scale variety within a prop type." The clump
  structure that IS there (visible in 03, 04) isn't enough density to read
  as continuous cover rather than isolated groups. Next attempt should try
  a genuine density lever inside the clumps themselves (more `per_clump`,
  smaller `clump_radius` for tighter packing) rather than further
  redistributing the same instance count, and re-judge against Palworld's
  own field shots specifically for how many blades are actually on screen
  at once.
- **Horizon/mid-ground, partly the known unfixable limit, partly not.**
  "No middle-distance layering anywhere in the set (no tree lines,
  ridgelines, or water)... the single biggest reason these frames feel
  empty." Some of this is `world_background = NOISE` (Terrain3D's
  procedural continuation past the 512m bake, genuinely can't hold props —
  see the original `R7.1-remainder` entry in `DONE.md`), but the finding
  reads as broader than just the unreachable far band — the near/mid
  ground inside the bake is also thin. Worth investigating whether a
  water feature (a pond/stream, named as a biome pillar in `GAME_DESIGN.md`
  but absent from every survey frame) would do more for depth-reading than
  further vegetation tuning.

Two smaller findings from the same round, not chased further to stay
inside the three-round cap **that no longer exists** — it was replaced on
2026-08-11 by a convergence test, so whoever takes `EV3`/`EV8` should not
inherit this entry's reason for stopping: sky/fog treatment is inconsistent between
frames (01/05 show a blue gradient sky, 02 a dark navy sky with hard-edged
cloud shapes, 03/04 a flat cream band) — likely a lighting/environment
config difference between survey viewpoints rather than a scatter issue,
worth its own investigation; and a small aliased red-maroon shape in 03
that the critic couldn't resolve into a legible object, possibly a
retint/LOD edge case on a single tree instance.

**R7.1-found (rise-overlook eye moved off the tower cluster) fixed — see `DONE.md`.**

**R7.1-found-2 (near-vertical bank near spawn, root-caused to overlapping
building-pad flattening, not a path or texture bug) fixed — see `DONE.md`.**

**R7.1-found-3 COLLAPSED into `EV4`.** The stripe is a colour/blend-map
artefact, and `EV4` replaces that whole painting approach with the control map
and eight authored layers — fixing it under the old scheme would be work thrown
away. Evidence kept:

Original entry — a flat texture-splat stripe on the hillside behind the spawn crate:

Found running the confirmation visual-judge pass for R7.1-found-2 (frames
01, 05): a diagonal tan/khaki stripe on the hillside behind the wooden
crate, "crisp and uniform-width rather than irregular or grass-feathered,"
and not picking up raking-light shading in the low-sun frame the way real
terrain relief would — reads as an unintentional texture-blend artefact,
not an authored dirt trail or any part of R7.1-found-2's fix (that fix
touched height/geometry only, not the colour/blend map). Needs its own
look at whatever paints dirt/soil blends onto slope near the spawn pad in
`build_playground_terrain.gd`. Not chased here — out of scope for the
near-vertical-bank defect this pass was confirming.

**R7.2 (NPC villagers and interior polish) shipped — see `DONE.md`.** The
sub-agent that built it disclosed a real process gap (no way to spawn a
genuinely blind critic and read back its verdict from its own toolset) and
self-graded instead. The owning interactive session had that capability and
used it afterward — a real blind critique ran against a confirmed-on-`main`
render; see `DONE.md` for the verdict and why none of its findings needed
an R7.2-specific fix.

**R9.4 (full visual pass) ran — see `DONE.md` and
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** Two blind critics, three
render rounds, real measured movement on every axis, and a lot fixed —
including four defects no test could see (mirrored signpost text, a creature
embedded in a roof, a magenta placeholder cube, and a plinth regression the
same pass introduced and caught). It did **not** reach the bar, and the
remainders below are the honest split rather than a pass. The original item is
kept beneath them because its instruction — re-run and compare sheets, never
assert the fix landed — is the standing rule.

**R9.4-remainder-1 COLLAPSED into `EV4`.** Same file, same bake, same command.
`EV4` rewrites `terrain_playground.json`'s material set and re-runs
`build_playground_terrain.gd`; re-solving `colour.grass_low` / `grass_high`
toward neutral is one field of that edit, and doing it first would mean baking
the `.res` files twice for one large binary diff each. **`EV4` inherits the
acceptance number**: `frame_stats` mean saturation inside 0.40–0.50 on frame 01
without the ground going grey. The diagnosis below is why, and it is the part
worth carrying forward:

Original entry — Ground saturation still above the bar, and the rest of it is baked:

`tools/frame_stats.py` after three rounds: mean saturation 0.59 on frame 01
against 0.40–0.46 for the Palworld references and 0.39 for the key art. Round 1
found the cause and it is structural, not taste — `albedo_color` multiplies, so
every tinted multiplier RAISES saturation, and the ground had three stacked
(texture tint 0.675→0.796, baked colour map →0.859, macro variation →0.873).
Two of the three are now solved or neutralised. **The third is the baked colour
map** (`terrain_playground.json` `colour.grass_low` `#c2d492` / `grass_high`
`#d8dc9c`), and it cannot be changed at runtime: it is written into
`data/terrain/playground/*.res` at bake time. That file's own comment sets a
floor of `#c0` on every channel so the map "modulates rather than paints", and
`#c2d492`'s blue is `0x92` = 146 — it has been violating its own stated rule
since it was written. Done when: the map is re-solved toward neutral, the
terrain rebaked (`godot --headless --path . --script
scripts/world/build_playground_terrain.gd`), and `frame_stats` puts mean
saturation inside 0.40–0.50 without the ground going grey. Expect a large
binary diff on the `.res` files; that is the cost of the fix, not a mistake.

**R9.4-remainder-2 CLOSED by `EV8` — see `DONE.md`.** Neither of the costed
options fired: not a bigger bake, not authored distant geometry. The actual
fix was a third Terrain3D setting nobody had tried — `world_background = 0`
(NONE) draws nothing past the bake instead of NOISE's dune-shaped continuation
or FLAT's hard seam — paired with dropping the photographic sky panoramas,
whose baked-in sun position doesn't track this file's own sun angle and was
the real cause of the sky-treatment inconsistency. Evidence kept:

Original entry — The world past 512m draws pale and colourless:

The single largest contributor to the compressed value range, and it appears in
every outdoor frame as a near-white band along the horizon. Past the baked
512 m, `shader.world_background = 2` (NOISE) continues the terrain
procedurally — and that continuation has no colour map and no texture control,
so it draws in a flat pale default. Two critics independently read it as fog
"eating the world" and as distant hills "washed to 219,226,205, nearly white,
so the far ground has no form left"; both are describing this. It is the same
limit `R7.1-remainder` hit from the other side (the continuation cannot hold
props either), and `world_background = 1` (FLAT) was already tried and produced
a measured 0.146 luminance step across the whole frame. Options worth costing
before picking one: grow the bake (which `R7.3` has to do anyway for the
chapter), fake the far band with authored distant geometry, or lean into it
with a deliberate haze that reads as atmosphere rather than as absence. Done
when: a critic given the frames stops naming the horizon as the reason they
feel empty.

**R9.4-remainder-3 COLLAPSED into `EV6`**, which already names it. Building a
`retint` hook for the Quaternius structures that `EV6` then replaces wholesale
is the definition of wasted work — but the *requirement* survives the swap and
`EV6` owns it: `village.json` must be able to lift a structure's roof the way a
vegetation layer retints a leaf, whatever kit is underneath. Acceptance carries
over too: roofs in the reference's warm 35–65% band, not the 11–16% measured
here. Evidence kept:

Original entry — The pack buildings have no material override path:

Every roof in the settlement measures 11–16% luminance in direct midday sun
against a reference board that keeps its roofs in the warm 35–65% band and
spends its darks on tree canopy. The windmill's tower reads as a black cutout
in two frames, taking its own modelled mullions, gallery and arch down with it,
and the fences are solid black with no rail-vs-post break. `village.gd` places
Quaternius structures and never touches their materials — there is no `retint`
hook at all, unlike `vegetation.gd`, which has had one since the crimson-bush
fix. Done when: `village.json` can lift a structure's roof the way a vegetation
layer can retint a leaf, and the settlement's roofs sit in the reference band.

**R9.4-remainder-4 COLLAPSED into `EV4`**, which already names it and states the
same fix — the control map, not the colour map. Evidence kept, including the one
fact worth knowing before anyone re-tunes it: round 3 made the existing tint
visible for the first time, because desaturating the grass stopped drowning it.

Original entry — Paths are a colour-map tint, not a material:

`build_playground_terrain.gd` paints paths by lerping the COLOUR map toward
`#c8a874`, and its own comment already calls a real material "queued as
polish". Because the colour map multiplies the grass albedo, a path is
grass-coloured grass with a tan cast rather than bare earth — which is why both
critics reported "no worked ground anywhere in the settlement" and "stepping
stones scattered in loose clumps that don't form a path". The fix is the
CONTROL map, not the colour map: paint the soil texture along the route so a
path is a different material. Round 3 made the existing tint visible for the
first time (desaturating the grass stopped drowning it), which is worth knowing
before anyone re-tunes it. Done when: a path reads as trodden earth from
standing height, and the path stones sit in it rather than on grass.

**R9.4-remainder-5 COLLAPSED, split across `EV6` (the site plan and the trees)
and `EV7` (the props).** Both already name it. This is the item that most
justifies the whole of Phase -0.6: it is the one both critics ranked first or
second independently, and it was never fixable by tuning — the props it asks for
are in a pack the repo does not have. `EV1` acquires them, `EV7` places them in
authored clusters rather than scattering them. Evidence kept, especially the
critic's own shopping list:

Original entry — The settlement has no trees, no props and no site plan:

Both blind critics ranked this first or second, independently. The key art's
own STARTING SETTLEMENT panel is organised around oak canopy framing a worn
dirt square, rail fences leading the eye in, and garden beds against the walls;
the build has buildings standing on open ground, fence stubs that enclose
nothing, and **not one tree anywhere in the settlement** (`vegetation.json`'s
`clearings` hold vegetation off the square by design, and nothing was ever
authored back in). The critic's list of what would fix it: woodpile, barrels,
crates, a cart, a hand-pump, hitching rail, garden beds, a washing line.
Content, not tuning — and it belongs with `R7.3`'s authored-space work rather
than in a palette pass. Done when: the square reads as a place people use.

**R9.4-remainder-7 COLLAPSED into `SA1-lod` (the mechanism) and `EV3` (the
judgement).** Read the entry below knowing it names the wrong cause. It blames
the hard alpha scissor and R9.4 shipped alpha-to-coverage against that theory;
`SA1` then measured the actual problem, which is that the foliage pack imports
with `mipmaps/generate=false` on all 14 textures **and** `vegetation.gd`
rebuilds an `ArrayMesh` that discards the importer's LOD chain. So 28,732
instances draw at LOD0 at every distance, sampling un-mipmapped 512² textures at
roughly 50:1 minification — which is aliasing by construction, and also the best
explanation of the owner's "high memory, 25% GPU" profile. The mipmap half
shipped in `28af489`; `SA1-lod` is the LOD half. Alpha-to-coverage stays and is
still unverified on the Ally, but it was never going to be sufficient. Evidence
kept — the entry's *observation* was right even though its diagnosis was not:

Original entry — Foliage aliases into confetti at distance:

**Two independent blind critics, on different frame sets, both named this the
most bug-like thing in the build** — "blue, magenta and cyan speckle… reads as
compression noise, not foliage" and "blue/green/white confetti speckle".
Confirmed by crop: a distant tree resolves to a scatter of unrelated pixels.
Root cause is a hard alpha scissor, which has no partial coverage — every texel
is fully in or fully out, so a ten-pixel tree is a handful of disconnected leaf
texels with background between them. R9.4 turned on alpha-to-coverage in
`vegetation.gd`'s `_retint()` so the project's existing 4× MSAA
(`project.godot` `anti_aliasing/quality/msaa_3d=2`) can finally act on foliage
edges — **but that is unverified**: llvmpipe's MSAA is not something these
survey frames can honestly test, so this needs judging on the Ally. And it is
only half the problem: a ten-pixel tree carries almost no information whatever
the sampling, which is an LOD or impostor question this item does not answer.
Done when: a critic looking at the mid-distance stops calling the trees noise.

**R9.4-remainder-8 (three of its findings) fixed — see `DONE.md`.** The other
five did not reproduce, were out of this item's scope, or were not chased —
see the remainder below.

### R9.4-remainder-8-followup — the two findings nobody has checked yet
`model: haiku` · `tests: none` · `area: village`
Genuinely unresolved, unlike the rest of the original list (see `DONE.md` for
why each of those closed the way it did):

- **Foliage clips the farmhouse roof ridge** in `buildings/04`, `05` and `06`
  — not investigated this pass. Given `EV6` replaces the whole settlement kit
  these trees stand near, check whether it still reproduces on the new kit
  before spending a firing on the old one.
- **Boulders sit fully proud of the ground** with no bedding at 4–6 m across,
  generally (not the one windmill-adjacent instance already investigated and
  closed as a camera-angle artefact — see `DONE.md`). Needs its own look at
  a genuinely embedded boulder, not the one already ruled out.

Both are low-value to chase before `EV6` lands, since it places new structures
in the same clearings and may change what is nearby. Whoever takes this should
re-survey first rather than trust either bullet is still current.

### R9.4-remainder-6 — `survey_combat.sh` did not complete, and nobody knows why
`model: sonnet` · `tests: none`
It ran ~50 minutes under llvmpipe and wrote zero frames while the seven-frame
buildings pass beside it finished; it was killed to give the box back. **The
arena has therefore not been visually reviewed at all this pass**, and that gap
is real regardless of the cause. What is NOT established: whether this is a
defect in `survey_combat.gd` (its `_approach()` walks the player to a wild
creature and could plausibly never arrive) or simply the cost of 240 settle
frames plus a whole fight under software rendering with another Godot process
competing for four cores. Do not guess — run it alone with a frame counter or a
timeout per phase, the way `R4.11` and `RB3` both had to. Done when: either it
produces frames, or its hang is root-caused and named.

**The original R9.4 brief is NOT repeated here as an open item** — it ran, and
an identical heading below its own remainders is how a task gets done twice.
Its standing instruction outlives it and is quoted here because every
`-remainder` above inherits it: *confirm the findings actually moved, the way
`docs/reviews/2026-08-09-site-frames-blind-critique.md`'s own "after judging"
section requires — re-running and comparing sheets, not just asserting the fix
landed.* The one part of the original brief the 2026-08-11 pass did NOT
discharge is the **full-roster creature sheet**: `preview_creatures.gd` ran,
but the sheet was destroyed before any critic saw it, and the roster has not
been blind-judged since R0.8.5. `SA5` and `SA6` in Phase -0.75 both need that
sheet as their starting evidence, so whoever takes them should re-run it first
and can close this gap in passing.

---

## Phase 1 — vocabulary, before the codebase grows

### R1.1 — Rename `pal` → `creature` everywhere
`model: haiku` · `tests: FULL SUITE`

~446 occurrences across 52 code files at last count (the overhaul will have
moved it — recount, don't trust it), plus `scripts/pals/` →
`scripts/creatures/`, `assets/pals/` → `assets/creatures/`, `data/pals/` →
`data/creatures/`, scene node names, class names, signals, UI strings,
dialogue, and every doc including `CLAUDE.md` and `GAME_DESIGN.md`.

Mechanical but wide. Godot resource paths (`res://`) live in `.tscn`, `.tres`
and `.import` files as well as `.gd` — a rename that misses those breaks the
project silently at load. Do it in one commit so no intermediate state is half
renamed.

Leave `docs/decisions/D01`–`D20` on the old vocabulary: they are a historical
record of decisions made when the word was "pal", and rewriting history to
match present vocabulary is how a decision log stops being trustworthy. Add
one line to each affected decision noting the rename instead.

Done when: no `\bpals?\b` outside `docs/decisions/`, full suite green, Windows
export succeeds.

### R1.2 — Vocabulary sweep of the handoff and decision index
`model: haiku` · `tests: none`

---

## Phase 2 — the first day, remainder

The session shipped harvest nodes, camp placement, campfire/bedroll and rest
(see Phase 0's note). What is left is the part that makes them an *economy*
rather than a scripted route.

### R2.1 — Tools
`model: sonnet` · `tests: test_inventory`
Axe, pickaxe, hammer, knife, fishing rod as items in `data/items.json`.
Gathering gated on the right tool: bare hands get less, the wrong tool gets
nothing. Done when: the same harvest node yields differently by held tool.
Spec §10: a Rootstone-tier tool (`SD18`) is the ladder's second rung — build
the rung here, not a second tool system there.

### R2.2 — Tool durability and free repair
`model: sonnet` · `tests: test_durability` (new)
`GAME_DESIGN.md` §19. Repair is free at the workbench — no repair-material
economy.

### R2.3 — Real tree/rock harvesting on the vegetation
`model: sonnet` · `tests: test_harvest`
The ~10 authored nodes were the tutorial route; this makes the *world*
harvestable — the scattered Terrain3D trees and rock outcrops themselves,
reusing `interactable.gd` and the nearest-wins arbitration, respecting the
path keep-clear. Done when: walking up to any ordinary tree and holding the
button puts wood in the satchel.

**Owner feedback, 2026-08-11: gathering "seems to randomly pop up."** Checked
against the code — it isn't random. The ~10 nodes are real placed props with
real models (`harvest_node.gd`, `data/config/harvest.json`), not invisible
triggers. The actual cause is that they're visually **identical** to the
hundreds of decorative trees/rocks scattered by `vegetation.gd` around them —
nothing distinguishes a gatherable stump from an inert one until the prompt
appears at close range, which is what reads as arbitrary. **Add to this
item's done-when**: a harvestable prop must read as harvestable from a
distance a player would actually approach from — a distinct material, a
glint, a marker, whatever `EV`'s art pass makes available — not just a prompt
on arrival.

### R2.4 — Orb and potion crafting
`model: sonnet` · `tests: test_recipes` (new)
Recipes for `orb_basic` and `potion_small` from gathered materials, at the
campfire or workbench. Grandpa's `give:` gift (D18) stops being the only
source — which matters because `throw_aim` now genuinely spends orbs. Costs
in `data/recipes/`, tunable, labelled. These are the **base** tier; `SD18` adds
the Rootstone tier above them (spec §10). Baseline materials are wood, stone,
fiber and berries and nothing else — §10 is a short list on purpose.

### R2.5 — REMOVE the post-fight auto-heal
`model: sonnet` · `tests: smoke_combat, smoke_catching`
`encounter_director.gd` still calls `_ally.heal_fully()` after every fight —
an M2 crutch ("no healing system, no camp" said the comment, and both now
exist). Deliberately sequenced *after* R2.4: taking the crutch away before
potions are craftable would make the first day punishing for the wrong
reason.

**Corrected 2026-08-11 — the use verb this item said was missing already
exists.** `tab_backpack.gd::_read_use()` heals the party from a focused slot
on interact, and `potion_small` already carries `heal: 35`, so potions are
already drinkable today. The stale "needs a use/consume verb" line (and the
matching one under "Found along the way" below) is corrected rather than
still claiming the gap. What's actually still missing: it's undiscoverable
without opening the full backpack menu (`HD2`, Phase -0.85, fixes that), and
berries specifically still can't be used because `berries` carries no `heal`
value (`R7.5` owns that). Done when: HP persists after a fight and is
restored only by potion or camp rest.

### R2.6 — Build pieces: floor, wall, doorway/door, roof, fence
`model: sonnet` · `tests: test_build_catalogue` (new)
Placement itself shipped with the camp (ghost → snap → confirm → spend
through `GameState.build_cost_for`, D16 intact); this is catalogue content.

### R2.7 — Workbench and storage container
`model: sonnet` · `tests: test_storage` (new)
Storage holds **items**. It is never creature storage. Five, ever.
The workbench upgrade is a Rootstone sink (spec §3 Band 2, `SD18`).

### R2.8 — Creature bed
`model: sonnet` · `tests: test_build_catalogue`

### R2.9 ▶ Play gate — does building a small home feel useful and enjoyable?
§33 criteria 6 and 7.

---

## Phase 3 — art debt and persistence

### R3.0 — Re-process the three humanoid GLBs through the fixed pipeline
`model: sonnet` · `tests: smoke_art`
**Renamed from "Regenerate" 2026-08-11 — same item, same scope, wording only.**
"Regenerate" kept reading as a new Meshy spend; it isn't one. This re-runs
files that already exist through a bug-fixed *local* script. No generation,
no credits, and `D23`/`BLOCKED.md` already say so explicitly — this rename
just stops the question from being asked again by the title alone.

The trainer, Grandpa and the Warden still carry cm-unit skeletons under a
0.01 Armature with ×100 inverse binds — the malformed source of the giant-
player bug. The runtime now compensates (render-space fit via
`render_bounds.gd`), but compensating for broken files is a debt, not a fix.
Re-run each through the fixed `animate_humanoid.py` (it now applies scale the
way the creature pipeline always did) and **verify with `smoke_art`'s
render-space check** — all three humans measured in render space, fit factors
inside [0.1, 10]. If the trainer's undersized backpack (HANDOFF §6) is cheap
to fix in the same pass, take it; do not let it grow the task.

### R3.1 — Save and load
`model: opus` · `tests: test_save_format` (new), FULL SUITE
3–5 slots, frequent autosave, versioned from the first write. **There is
still not one write to `user://` outside settings.** Follow the precedent in
`scripts/ui/key_bindings.gd`: versioned, never fatal on load.
**Carry `SB9`'s progression flags in version 1** — Phase 3.5 is sequenced right
after this item precisely so the chapter's state does not cost a format bump
later.
Done when: quit mid-Meadows, reload, and party, satchel, day counter and
placed buildings are all intact.

### R3.2 — Death satchels persist across save/load
`model: sonnet` · `tests: test_satchel` (new)

### R3.3 — Player death and respawn
`model: sonnet` · `tests: test_player_death` (new) · §22

---

## Phase 3.5 — reusable progression infrastructure (spec Phase B)

`docs/MEADOWS_PROGRESSION_SPEC.md` §15, §16, §35. Everything in the Meadows
chapter (Phase 8) stands on what this phase builds.

**The two NPC items that used to live here moved.** `SB7` and `SB8` are now
`NP1` and `NP2` in Phase -0.55, because the owner's NPC board arrived and made
them art-direction work that the whole cast waits on, not progression plumbing.
Their headings below are collapsed, not open. What is left here is state:
`SB9`, `SB10`, `SB11`.

Placed *after* Phase 3 on purpose: `R3.1` writes the first save format and it
is "versioned from the first write". `SB9`'s flags belong in version 1, or
adding them later costs a format bump for nothing.

**SB7 COLLAPSED into `NP1`, which supersedes it and now runs far earlier
(Phase -0.55).** They are the same work, but the owner's NPC board asks for more
than this entry did: per-material overrides are necessary and not sufficient,
because the board specifies **hair variants sharing head topology and
accessories as separate toggleable mesh parts**. Colours alone cannot express
that. `NP1` carries this entry's acceptance test forward unchanged and adds
visible accessories to it. Evidence kept:

Original entry — Per-material NPC variants, not one global tint:

Spec §21. R7.2 already proved the idea — Mira, Oskar and Tam in the square are
Grandpa's and the trainer's rigs with a `tint` in `art.json` — but `tint` is a
single multiply over every surface (`character_model.gd::_apply_tint`), and §21
names that exact failure: "do not recolor everything with one global tint if it
destroys material separation." Grow the `art.json` block into per-material
overrides (hair, jacket, trousers, boots, belt, pack visibility) keyed by
surface or material name, with the existing single `tint` still honoured so
nothing already placed breaks. Done when: two NPCs on the same rig differ in
jacket and hair colour independently, and neither is a flat wash of one hue.

**SB8 COLLAPSED into `NP2`.** Identical work, moved to Phase -0.55 with `NP1`
underneath it. One thing changed since this was written and `NP2` records it:
the board's Team Tether Grunt base means the "keep the main-character base for
civilians until §22's optional grunt base exists" hedge below now has an end
date — `NP4` generates that base. Until then this entry's advice stands, and
`NP2` repeats it. Evidence kept:

Original entry — Team Tether rank palettes on the Warden rig:

Spec §21, §35, §36. The Warden's rig is the faction's base body. Four rank
tiers as data on top of `SB7`: grunt (charcoal, muted forest green, minimal
gold), relay/field officer (deeper green, bronze trim), captain (dark green,
brass, one regional accent), Warden (richest materials, cream fur mantle,
strongest gold — unchanged). Rank has to be readable at gameplay distance
without a nameplate, because the geometry repeats. One caution the spec hedges
on and this item should not: §21 offers the **main-character** base for "junior
Team Tether personnel", but that rig is the player's own body and enemies
wearing it will read as clones of the player. Prefer the Warden base for every
faction NPC; keep the main-character base for civilians until §22's optional
grunt base exists. Done when: the relay captain, a regional captain and the
Warden stand in one frame and a blind critic ranks them correctly by seniority.

### SB9 — The smallest progression-state system that survives the chapter
`model: opus` · `tests: test_progression_state` (new), FULL SUITE
Spec §15. Objective flags, completion flags, trainer-defeated state, keys and
tokens, bridge-unlocked, dungeon-cleared, captive-rescued, Sigils 0/3,
stronghold-unlocked, Warden-defeated, post-Warden world state. Lives on the
`Game` autoload beside the party and the satchel — D14 is explicit that one
autoload is the design and a second is not. Objectives are data
(`data/progression/`); the code is a flag store plus a has/set/completed API.
**Spec §19 bans a "giant generic quest engine" and §15 says the same thing
twice; this is the item on the whole backlog most likely to become one.** If it
starts wanting branching, timers, prerequisites-of-prerequisites or a scripting
language, stop and split it. Done when: a flag set in one scene is readable in
another, survives save/load (R3.1), and no gameplay script hardcodes a story
boolean.

### SB10 — Physical keys, gears and Sigils that open real things
`model: sonnet` · `tests: test_progression_state`
Spec §3 Gate 1, §15, §19. A gate is a mechanism in the world that a carried
item operates — the South Bridge Key, the Mill Bridge Gear, three Sigils —
never a level check and never a UI lock. The player may walk to a closed gate
at any level and be refused by the gate, not by a dialog. Done when: holding
the right item and interacting opens the crossing, and not holding it produces
an in-world response.

### SB11 — One tracked objective, and a two-list quest log
`model: sonnet` · `tests: smoke_menu`
Spec §16. One concise line on the HUD ("Earn access to the South Bridge",
"Defeat the Upper Meadows captains. 2/3") and a log with exactly two lists,
Main Story and Local Requests. `playground_hud.gd` owns the line, `game_menu.gd`
gains the tab. Reads `SB9` and invents no state of its own. Done when:
completing an objective changes the HUD line without a scene reload.

---

## Phase 4 — combat, progression, the team

### R4.1 — Levels and XP · `model: sonnet` · `tests: test_progression` (new) · §11
### R4.2 — Core stats and per-instance individuality · `model: sonnet` · `tests: test_progression` · §11
### R4.3 — Moves · `model: sonnet` · `tests: test_moves` (new) · §13. `data/moves/` is **empty**.
### R4.4 — TMs and teaching moves · `model: sonnet` · `tests: test_moves` · §13

### R4.5 — Tuskroot's REAL model 🔒 — LIKELY ALREADY DONE, needs verification
`model: sonnet` · `tests: smoke_art`
**R0.8.5's full blind review (2026-08-09) found this is probably no longer
true.** `assets/pals/tetherbound/tuskroot/models/pal_tuskroot_lod0.glb` has
a different file hash from `ollie-the-songbird.glb`, and a fresh turntable
render (`docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`) shows a real
tusked boar carrying the same moss-and-stone material language as Mudsnout —
exactly the "must read as Mudsnout grown up" brief below. `species.json`
already has it at height 2.15 against Mudsnout's 1.55, matching D17/D19's
numbers. What that review did NOT do: run `smoke_art` or check the rig/clip
wiring, which is what this item's own `tests:` field names. Next firing on
this item: run `smoke_art`, confirm the model is properly rigged and
animated (not just present), and if it passes, close this as done instead
of doing the generation work described below — do not silently invent a
replacement model over a real one already installed.

**Constraint change, spec §20 / D23: the "fresh generation from the sheet"
fallback below is now illegal.** No new creature Meshy generations for the
Meadows, at all. The remaining paths are (1) verify the installed model, which
R0.8.5's review suggests will pass, or (2) graft off Mudsnout's finished model,
which costs no credits either way. If both fail this becomes a `BLOCKED.md`
question for the owner — **not** a credit spend. The `🔒` marker above is
therefore misleading and should go when this item is next touched.

Original brief, kept for whoever verifies: the last stand-in was
`ollie-the-songbird.glb`. Since D20 it never spawns wild, so the only place
it will ever be seen is the evolution ceremony: the single most emotionally
loaded reveal a creature model gets. `CLAUDE.md`'s prototyping rule applies
with full force — the ceremony may not be judged with a songbird wearing a
boar's name. If verification finds it's NOT actually done: needs its own
call first, fresh generation from the sheet, or a graft off Mudsnout's
finished model (try the graft first, it costs no credits). Height 2.15 per
D19; strictly larger than Mudsnout per D17.

### R4.6 — Evolution mechanic and ceremony
`model: opus` · `tests: test_evolution_links, smoke_evolution` (new)
Mudsnout → Tuskroot gets a rope pulled at last. D20 fixed the intent: the
first evolution the owner sees will be a creature they caught as a piglet and
have carried since — build the ceremony knowing that. Honour D17 (the evolved
form is always larger — at D19 scale that is 1.55 → 2.15). Blocked on R4.5:
no ceremony with the stand-in.

**Spec §4 (D23) fixes the shape.** Mudsnout → Tuskroot is **the** Meadows
evolution line and no other normal species evolves — it exists to teach the
limited evolution system. Recommended: a level requirement (~15), a bond
requirement, and one Heartstone-type item from the Burrow Warrens' optional
deep branch (`SD17`). All three numbers and the item name are tunable per
`CLAUDE.md`; do not let a working name become a permanent mechanic.

### R4.7 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12
### R4.8 — Fainting and home recovery · `model: sonnet` · `tests: test_fainting` (new) · M6

### R4.9 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
Spec §3 Band 2: the improved orb tier is the **first** thing Rootstone
(`SD18`) buys. Build the tier ladder here; `SD18` supplies the material.
Note: the old "rework orb aiming" item that sat beside this was **absorbed by
the overhaul** — trajectory preview sharing `_release()`'s math, wired
sensitivity, fine-aim exponent, piecewise snap assist, cancel during windup.
Whether it now *feels* satisfying (§33 criterion 3) is R0.11's and R4.12's
question, not a build task.

### R4.10 — The release ceremony · `model: opus` · `tests: test_party, smoke_release` (new)
`party.add()` refuses a sixth creature and there is no ritual. The slice
warns it must not be "a generic delete dialog" — it is the emotional payload
of the five-creature rule, and since D18 the five-cap has a physical body in
the world: the belt Grandpa gave you has five holders.

**Spec §5 states the precondition, and it is not work on this item.** The
ceremony only lands if the Meadows has already produced more creatures worth
keeping than five slots — a Ground tank, a Water counter, an Air attacker, a
rideable Meadowhart, a rare-trait catch, the Mudsnout line, a favourite first
catch. That is a content requirement on Phase 8's bands, not on R4.10, and the
first biome must not be allowed to dodge the tension.

### R4.11 — Combat animation bug · `model: sonnet` · `tests: smoke_combat`
Owner-reported: creatures "static posed and sliding around". Ruled out by
measurement — clips exist, drive real bone motion, the animator is ticked
every physics frame with real velocity, loops are set at runtime. Best
remaining lead: Terrapup's idle moves bones by 0.088 against 1.53 for walk,
and a creature in combat is in idle almost always. **Next step is a recorded
fight logging the clip playing against the body's speed — not more
reasoning.** Re-check against the owner's R0.11 impressions first; the feel
pass (auto-face, lunge timing) may have changed the report.

### R4.12 ▶ Play gate — is repeated combat enjoyable, not merely functional? §33 criterion 2.

---

## Phase 5 — the living world

**R5.1 (day/night cycle) relocated to Phase -0.5** — owner directive,
2026-08-10: visual-pass work runs before Phase 1 onward.

### R5.2 — Rain, fog and cloud variants · `model: sonnet` · `tests: none`

### R5.3 — Spawn conditions · `model: sonnet` · `tests: test_spawns`
At least one nocturnal (Duskhush) and one weather-gated, per M10. Extend
`spawns.json`'s schema per D20 — this is the task that decision deliberately
deferred the fields for. Tests keep addressing species through the `roles`
block, never ids.

**Spec §13 supplies the area table**, which is what makes deeper regions change
the team you can build: lower fields Bramblebun / Mudsnout / Pipwing; grove
Trailpup / Duskhush at night / Burrowback; quarry and warrens Burrowback /
Mudsnout / strong Ground spawns; river Paddlenewt / Mosshell / Brooktail /
Reedwing; upper ridge Galecrest / Meadowhart / stronger Trailpup. Duskhush is
already the nocturnal example above. No random battle screens, ever (§13).

---

## Phase 6 — riding

**R6.1 and R6.2 are worked inside Phase 8's section 8d** — spec §3 Band 4 (D23)
makes riding a Band 3 / early Band 4 unlock gated on a Riding Saddle whose
components cost Rootstone and Ironwood, which is a progression step rather than
a free-standing milestone. Their briefs are kept here; the ordering is there.
R6.3's play gate stays where it is.

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over
running, and no species-specific saddle clutter.

### R6.2 — Meadowhart as the rideable creature; craftable generic saddle
`model: sonnet` · `tests: test_build_catalogue`
Spec §3 Band 4 confirms Meadowhart as the rideable Meadows creature and prices
the saddle in Rootstone/Ironwood components (`SD18`, `SF31`). Riding should
dramatically improve *revisiting* known areas — that is the value it is being
sold on, not raw speed.

### R6.3 ▶ Play gate — does riding make exploring better?

---

## Phase 7 — the village lives, the meadow reads

**R7.1 (wayfinding polish) and R7.2 (villagers and interior polish)
relocated to Phase -0.5** — owner directive, 2026-08-10: visual-pass work
runs before Phase 1 onward.

### R7.3 — Grow the authored space toward the 4–8 hour arc · `model: opus` · `tests: smoke_traversal` · M7, §30
The village and paths were the seed; §30 is explicit — dense rather than
empty, and do not pick a kilometre count before movement is fun (R0.11 and
R6.3 answer that).

**This is now the chapter's capacity item, and the single largest unpriced
piece of D23.** `terrain_playground.json`'s own first line says it is *a test
area, not the Meadows*, and 512 m on a side cannot hold spec §3's five bands, a
quarry, a dungeon, a major river, a mini-stronghold, an upper region and seven
perimeter spokes. Growing it costs a terrain rebake, more Terrain3D regions and
a real performance question on the Ally — none of which is budgeted anywhere.
R7.3 owns the *space and the bake*; the individual areas belong to `SD16`,
`SD17`, `SE21`, `SE23` and `SF31`. §30's rule still governs the number: prove
movement and riding are fun first, then size it.

### R7.4 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.
Spec §16 adds the rule: the map reveals explored areas and landmarks and never
reveals everything automatically. The tracked-objective line and the two-list
quest log are `SB11`, not this item — R7.4 owns the map itself.

**Promoted, 2026-08-11 — see Phase -0.85 for why.** This item's text stays
here; Phase -0.85 only points at it. The minimap is unblocked and can be
picked up from either location.

### R7.5 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.

### R7.6 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 8 — the Meadows chapter (spec Phases C–G)

This was five items called "Team Tether and the culmination". `D23` turns it
into the chapter: five bands, two material tiers, physical gates, roughly
12–17 trainer battles, a dungeon, a mini-stronghold, a rescue, and a world
event. The `S<letter><number>` ids trace straight back to a numbered step in
`docs/MEADOWS_PROGRESSION_SPEC.md` §38, so a branch name carries its own
provenance.

**Why the whole chapter sits this late:** it consumes levels and XP (R4.1),
moves (R4.3), riding (R6.1) and trainer combat (R8.1). That is build order, not
play order. The honest cost is that the owner will not play a Band 1 trainer
battle for a long time — if that is the wrong trade, the cheap thing to hoist
is `R8.1` + `SC12` + `SC13` once R4.1/R4.3 exist. **That is an owner call, not
a firing's.**

### 8a — Lower Meadows (spec Phase C)

### R8.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught. Spec §12 sizes what this has to
carry: 12–17 battles across the chapter, spread over meaningful locations
rather than one long trainer tunnel. It is the substrate for everything in 8a
through 8e, not a single encounter.

### SC12 — Mira, Oskar and Tam become the three Band 1 trainers
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 1 and §35. **These three already exist** —
`data/config/village_npcs.json` places Mira, Oskar and Tam around the well with
greetings in `data/dialogue/village.json`, and the spec names the same three
("possible existing village NPCs can fill these roles if their existing
characterization fits"). Do not add three more people to the square. Mira
becomes the Meadow Keeper, Oskar the Bridgehand who holds the South Bridge
mechanism (he is already `villager_keeper`), Tam the Field Scout. Repalette
through `SB7`, extend their conversations, give each a battle offer. Done when:
all three are challengeable and none of them is a newly-placed body.

### SC13 — The three Band 1 trainer battles, each with a distinct lesson
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 1, §12. Mira is the introduction, Oskar is the gate, Tam teaches
switching and type awareness. Uses R8.1's system, `SB9`'s defeated flags and
`SC15`'s rewards. Recommended natural team level by the time the bridge opens
is roughly 5–8 — **guidance for tuning, never a check the game performs**
(§3, §19). Done when: each can be beaten once, sets its flag, and cannot be
re-fought into an XP faucet.

### SC14 — The South Bridge, and the key that opens it
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Gate 1. The deeper Meadows is visible across an old bridge the player
can walk to at any level and cannot cross. Beating Oskar yields the South
Bridge Key (`SB10`); the bridge is a mechanism, not a message. Done when: the
crossing is visible from the village, blocked without the key, open with it,
and never explains itself with UI text.

### SC15 — Trainer battles pay out
`model: sonnet` · `tests: test_progression_state`
Spec §17 P1 step 9. A defeated trainer grants XP plus one authored reward — an
item, a TM, a recipe or a key — recorded against `SB9`'s flag so it cannot be
farmed. Done when: beating a trainer twice pays once.

### 8b — Rootstone (spec Phase D)

### SD16 — The Old Quarry
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 2, §32. Rootstone deposits, old foundations, and the first
physical evidence Team Tether is routing something beneath the region —
conduits, excavation, energy-routing hardware, material moving toward the
stronghold. Evidence, not an explanation: §32's reveal ladder is explicit that
nobody here knows about the legendary. Done when: the quarry is reachable past
the South Bridge and yields Rootstone.

### SD17 — Burrow Warrens, the required dungeon
`model: opus` · `tests: smoke_traversal, smoke_combat`
Spec §3 Band 2. A compact cave: aggressive Ground creatures, Rootstone
deposits, chamber navigation, a guardian fight, one rare side branch. **The
guardian is a strong normal species — the spec says outright not to invent
another legendary**, and §20 forbids the model anyway. The optional deep branch
is where the Mudsnout evolution item lives (R4.6). Done when: it can be
entered, cleared, and cleared only once for its story reward.

### SD18 — Rootstone, the first progression tier material
`model: sonnet` · `tests: test_recipes`
Spec §10. Two tier materials in the entire biome — Rootstone then Ironwood — on
top of wood, stone, fiber and berries. Rootstone **upgrades what already
exists** rather than opening ten new systems: better orb tier (R4.9), workbench
upgrade (R2.7), better gathering tool (R2.1), the saddle component (R6.2), a TM
component, a modest camp/storage improvement. §32's ban on a large crafting
tree is the boundary. Done when: every recipe that consumes Rootstone improves
something the player already owns.

### 8c — the river and the relay (spec Phase E)

### SE21 — A real river divides the deeper Meadows
`model: opus` · `tests: smoke_traversal`
Spec §3 Band 3. Also closes a question the visual pass left open:
`R7.1-remainder-2`'s second bullet found "no middle-distance layering anywhere
in the set (no tree lines, ridgelines, or water)" and asked outright whether a
water feature would do more for depth-reading than more vegetation tuning. This
is that feature, and it is load-bearing for the story too. Done when: the river
reads as a landmark from the ridge and cannot be crossed except at authored
points.

### SE22 — Old Mill Crossing, seized and then restored
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 3. Team Tether has disabled the crossing and taken the person who
knows the mechanism. Freeing them (`SE27`) yields the Mill Bridge Gear
(`SB10`) and the crossing opens for good. Done when: the same bridge is
impassable before the rescue and passable after, with no menu in between.

### SE23 — The Tether Relay Station
`model: opus` · `tests: smoke_traversal`
Spec §3 Band 3. The first mini-stronghold: a natural site partly
industrialised, a compact traversal and environment challenge, and the moment
Team Tether stops being something Grandpa described and becomes a threat the
player has personally confronted. R8.2's visual-language brief is used here
first, at small scale. Done when: it can be entered, fought through, and its
local tether/control equipment disabled.

**The "local tether/control equipment" now has a board** —
`docs/art/reference/14_Relay_Apparatus.png`, owner-supplied 2026-08-11 and
labelled Band 3, so it is drawn for exactly this item. It is one of the three
hero objects D24 reserves Meshy for, and it is `lane: art`. Its artist note is
the build spec rather than flavour: *modular construction, core and rings
serviceable, conductor arms and manifolds replaceable*, with five labelled
subassemblies (tether core, conductor ring, control console, output manifolds,
grounding base). The console is the thing the player disables, and the board
details it down to individual routing levers.

### SE25 — Relay trainers and the relay captain
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 3, §12: two or three Team Tether trainers and a relay captain, all
on `SB8`'s rank palettes — the captain visibly outranking the trainers and
visibly below the Warden. Done when: the captain's defeat sets the flag `SE27`
waits on.

### SE27 — Free the captive
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 3, §35. The captive ranger/researcher is built on the civilian or
main-character base — **not a new model** (§20/§21 apply to the whole cast).
Rescue scene, the Gear, and the first testimony that the region's isolation is
made rather than natural. They return to the settlement afterward (`SG46`,
§14). Done when: rescued, the NPC exists in the village and their dialogue has
changed.

### SE30 — The reveal ladder, laid in
`model: sonnet` · `tests: test_dialogue_runner`
Spec §32. Villagers know travel is controlled and trade restricted, and no
more. The quarry shows conduits. The relay shows energy routing and a captured
investigator. The captive knows the separation is artificial but **not** that a
legendary is the source. Grandpa's opening must not spoil any of it — §32 and
§1's "do not dump the entire plot in one speech" are the same instruction.
Done when: no line of dialogue before the stronghold names the legendary as the
power source.

### 8d — Upper Meadows (spec Phase F)

**R6.1 and R6.2 (riding, Meadowhart, the generic saddle) are worked here** —
spec §3 makes riding a Band 3 / early Band 4 unlock priced in Rootstone and
Ironwood. Their briefs stay in Phase 6; the ordering is this.

### SF31 — Ironwood, the second preparation tier
`model: sonnet` · `tests: test_recipes`
Spec §3 Band 4, §10. Supports stronger crafting, riding equipment, better
utility and final-stronghold preparation. It does not need to literally be
iron. Keep the economy small and readable. Done when: nothing needed for the
stronghold requires a third new material.

### SF33 — Standing at a Rift and seeing the next region
`model: sonnet` · `tests: none`
Spec §29, §34 Act V. `SA4` built the seven spokes; this makes the Upper Meadows
ones legible as **severed roads**: major conduits and pylons, roadbed
continuing on the far side of an unnatural seam, land visible across it, old
trade infrastructure abandoned mid-use. **The far side is a view, never a
place** — `CLAUDE.md`'s Biome 2 rule stands, and D23 says so explicitly.
Visual-affecting: blind pass required. Done when: a blind critic looking at the
seam says the two sides used to be joined.

**The pylons have a board** — `docs/art/reference/13_Tether_Energy_Pylon.png`,
owner-supplied 2026-08-11, and it is the cheapest of the three hero objects to
build: a **2K–3K triangle** target and a five-part modular kit (base + core
module + supports ×4 + top frame + tether crystal) that is meant to be
repeated along a line. That repetition is what sells "severed road" — one
pylon is a prop, a receding row of them is infrastructure. `lane: art`.

### SF34 — Three regional captains, three Sigils
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 4. Field Captain (Ground team, Field Sigil), Ridge Captain (Air,
Ridge Sigil), Riverwatch Captain (Water/balanced, River Sigil), all on `SB8`'s
captain palette with one regional accent each. The three physical Sigils open
the Hall approach through `SB10`. This is what gives trainer battles direct
progression meaning. Natural team expectation entering this band is roughly
10–16 — **tunable, and never player-scaled** (§3). Done when: the approach is
sealed at 2/3 and open at 3/3, and the count is visible on `SB11`'s tracker.

### 8e — the stronghold and the first reconnection (spec Phase G)

**The Tether Chamber's centrepiece has a board.**
`docs/art/reference/15_Legendary_Tether_Machine.png`, owner-supplied
2026-08-11, headed WARDEN STRONGHOLD — it is drawn for this section. ~15 m
against its own 0–20 m scale bar, so it is architecture rather than a prop and
the chamber has to be built around it. It is `lane: art` and one of the three
hero objects D24 reserves Meshy for.

**Read this before generating it.** The board shows a legendary bound inside
the containment ring, because that is what the machine does to legendaries —
it is the D23 macro-story drawn. **The board licenses the machine, not its
occupant.** `D23` §20 forbids new creature meshes at any credit balance, so
the bound creature is an existing roster asset or VFX. Generating the whole
board as one asset breaks a hard rule while appearing to follow one.

### R8.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether. R7.1's ridge
silhouette is the promise this pays off. Spec §8 gives the interior: Outer
Works → Courtyard / Hall Approach → Tether Chamber Approach → Warden Arena →
Legendary Chamber, target first clear 30–60 minutes. **Not a giant puzzle
dungeon** — §8 rules that out unless separately decided. Note the same
industrialised-sacred-site language is used twice: first at `SE23`, then here at
full scale.

### SG38 — The stronghold trainer gauntlet
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §8, §12: a patrol trainer at the Outer Works, a courtyard fight, an elite
before the Tether Chamber, and a recovery opportunity before the Warden. Two to
four battles across the five named spaces. Done when: a prepared team clears it
inside an hour and an unprepared one does not.

### R8.3 — The Warden boss fight · `model: sonnet` · `tests: smoke_boss` (new) · M14
His face is still painted, not modelled — needs a real sheet before this is
judged (HANDOFF §6). Note §20 covers *creatures*; a Warden face pass is still
legal under §22's budget. Spec §33 gives the character: he sincerely believes
separation prevents chaos and that ordinary people do not understand the risks.
Not a moustache-twirler. His line is closer to "You don't understand what these
barriers are holding apart" than "You cannot stop me."

### SG40 — The reveal: the legendary is the power source
`model: sonnet` · `tests: test_dialogue_runner`
Spec §28, §32, §33. Inside the stronghold and nowhere earlier — `SE30` holds
the rest of the ladder. The Warden warns rather than gloats, and genuinely
believes freeing it is reckless. Done when: the reveal happens in the
stronghold and the player makes the choice knowing what it costs.

### R8.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: sonnet` · `tests: smoke_boss`
Spec §28's order, which is not optional: reach the chamber → the legendary is
freed → it **voluntarily** offers to join → the five-creature decision if the
roster is full (R4.10) → the tether machinery fails → `SG44`'s world event.

### SG44 — The first Tether Rift collapses and the world gets bigger
`model: opus` · `tests: smoke_boss`
Spec §27, §28, §30. The machinery fails, the exterior event runs, and one
severed spoke visibly reconnects — a distant landmass moving closer, a ravine
contracting, roots bridging a gap, a storm wall dissipating. **The carve-out is
not negotiable: this is a distant, non-enterable view.** `CLAUDE.md` forbids
Biome 2 work until the Meadows exit gate and D23 holds that rule over this
step; the spec's own §19 non-goals ("all seven future biomes") agree. No second
biome's terrain, spawns or species — the reconnected road still ends at a
believable barrier. If that reads as an unsatisfying payoff, it is a
`BLOCKED.md` question for the owner, not a licence. Done when: standing where
`SF33` put the seam, before and after the Warden, gives two visibly different
horizons — and the player still cannot walk into the next region.

### SG46 — The Meadows answers
`model: sonnet` · `tests: test_progression_state`
Spec §9. Barriers deactivate, patrol density drops, the rescued NPC is back in
the settlement, villagers acknowledge the victory, stronghold effects change,
the legendary is no longer tethered, and at least one outward spoke gains new
dialogue. Done when: no part of the region is visually or conversationally
identical to how it was before the Warden.

### R8.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
The tier above Meadowhart's (R6.2), not a parallel system.

### R8.6 — The larger mystery and future-biome hook · `model: sonnet` · `tests: test_dialogue_runner`
No longer open-ended: the mystery is spec §23–§31, and `SA4`'s seven spokes are
its physical hook. `GAME_DESIGN.md` §3's "the exact endgame motive remains
intentionally open" is false as of D23 and is amended there.

---

## Phase 8.5 — pacing and the chapter's own gate (spec Phase H)

### SH47 — Tune the chapter to 4–7 hours
`model: sonnet` · `tests: none`
Spec §17 P7, §38 Phase H. XP curve, trainer levels, material costs, travel
time, spawn density, and the specific instruction to **remove dead walking**.
Distinct from R9.1 (input feel and combat cadence) and R9.3 (performance on
hardware): this is arc pacing, and it can only be judged once 8a–8e exist.
§11's test of a good grind is the standard — "I know a harder challenge is
ahead, so I am deliberately improving my five", never walking in circles
killing identical weak enemies to inflate a number. Done when: a full run is
timed end to end and lands inside 4–7 hours.

### SH53 ▶ Play gate — the P0 fixes are actually gone on real hardware
`model: haiku`
Spec §38 step 53, §18. Ten minutes of a fresh Windows launch with mouse and
keyboard, never once having to think about cursor capture — through a menu
open and close, the name-entry screen, and an Alt-Tab. Then: the door cannot be
crossed before Grandpa, and no bearing walked from spawn falls off the world.
**This is the on-device confirmation `RB1`, `RB2` and `RB4` all still owe** —
each is closed on diagnosis and a real fix, none on the owner's own hands.

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm
none of them installed, requested or planned a new creature mesh. Cheap, and
worth doing once at the end, because the constraint is a budget the owner holds
and a single quiet violation spends it.

---

## Phase 9 — polish gate (M15)

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet` ▶
### R9.2 — Controller UI readability on the Ally · `model: sonnet` ▶
### R9.3 — Performance on target hardware · `model: sonnet` ▶

**R9.4 (visual cohesion pass) relocated to Phase -0.5** — owner directive,
2026-08-10: it now serves as that phase's own checkpoint, run before
Phase 1 onward rather than at the end.

### R9.5 ▶ **The exit gate.** All twelve of `GAME_DESIGN.md` §33. Only the owner can call it.

---

## Found along the way — small, unscheduled

- `docs/ASSET_LEDGER.md` claims "everything currently in the build is CC0
  1.0". False (Meshy creatures, Plumberry pack). **Blocked on the owner** for
  the correct wording. The website's parallel stale claim was fixed in the
  overhaul; the ledger's was not.
- ~~Backpack has no use/consume/equip/drop/split verb; the only action is
  moving an item.~~ **Corrected 2026-08-11: this was stale.** A use verb
  already exists (`tab_backpack.gd::_read_use()`) and already heals from
  `heal`-tagged items — `potion_small` (`heal: 35`) is usable today. The real
  remaining gaps are narrower: `berries` carries no `heal` value (`R7.5`
  owns giving it one), the verb has no equip/drop/split siblings (still
  genuinely missing, small, `model: sonnet` if anyone wants it), and using
  any of it requires the full backpack menu with no quick path (`HD2`,
  Phase -0.85, fixes that).
- `data/config/menu.json` twice cites `tests/test_menu_config.gd`, which does
  not exist. The file is `tests/test_menu_data.gd`. `model: haiku`
- `menu.json` documents `hotbar_columns`, absent from the backpack block and
  read by nobody. Either build the hotbar (§19 wants quick tool select — R2.1
  makes this real) or delete the comment. `model: haiku`
- Opening the menu mid-fight is silently refused with no on-screen
  explanation. `model: haiku`
- **`smoke_traversal` / `smoke_combat` flakes — PROMOTED to `LP1` in
  Phase -0.95.** Batched pushes make a random red cost up to four finished
  items instead of one, so this stopped being a small item.
- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what
  they know, the rescued NPC returning, story check-ins. The farmhouse should
  not become a room you never re-enter after the first twenty minutes.
  `model: sonnet`
- **`tools/survey.gd` and `tools/preview_creatures.gd`, both found broken by
  R0.8.5, relocated to Phase -0.5 as VP1/VP2** — owner directive,
  2026-08-10: visual-pass work runs before Phase 1 onward, and both tools
  are needed to verify that phase's own work.
