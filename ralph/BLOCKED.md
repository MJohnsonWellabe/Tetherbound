# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

---

## OF4 silhouette ceiling — primitives + unshaded have a measured limit on "gravitas," and the last step needs the Phase 8e asset or an owner call

`OF4` (2026-08-12, six blind rounds, shipped on `ralph/OF4`) moved the ridge
silhouette from "witch's hat / chess rooks / standing stones" to a shape
every critic now parses in fortress vocabulary — but the 170m from-square
frame still drew "sandcastle," and rounds 5-6 converged with nothing
addressable left in `landmark.gd`'s toolkit. Three walls, with evidence:

1. **The rise, not the landmark** — 4 of 6 critics' single biggest
   from-square fix was the bare dune-like mound. That half is actionable
   now and became `BACKLOG.md`'s `OF4-remainder-mound` (terrain scope).
2. **Flat-fill fusion** — from the path's low eye, terrain hides
   everything below ~23m local (ray-marched, not guessed), and an
   `unshaded` silhouette fuses whatever overlaps. Critics alternately
   asked for sky gaps between towers (reads "standing stones" — R7.1's
   settled finding) and for connected wall bulk (reads "one fused crag").
   Both cannot hold from every bearing with a flat fill; rounds 2 and 6
   literally prescribed opposite fixes for the close frame.
3. **Silhouette language vs the key art** — one critic observed the
   keyart's Meadows Hall is wide/low/sprawling while a wayfinding
   landmark on this crest must be tall to survive the crest cut, so the
   170m promise and the direction-board destination don't share a
   language. That is a real design question, and it lands exactly where
   the standing gate already is: the "iconic Stronghold centerpiece" is a
   Phase 8e Meshy hero asset (`15_Legendary_Tether_Machine.png` board,
   gated in this file), and `landmark.gd`'s own header has always said
   the stronghold's real presentation is judged on real art, not this
   placeholder.

**What would clear it:** `OF4-remainder-mound` landing (cheap, now), and
either the owner accepting the current placeholder read until Phase 8e
replaces it with the real asset, or an owner call to trade wayfinding
consistency for atmosphere (the settled `unshaded`/`fog_disabled` opt-out
is the other lever critics keep reaching for — "hazed into the distance"
— and reversing it was already tried and reverted twice; see
`landmark.gd`'s TOWER_COLOUR history).

---

## ✅ RESOLVED — the loop can push again

**This entry is retracted as of the R0.3.5 fix.** The two earlier firings that
diagnosed read-only access were correct about what they saw, but the
environment has since been reattached with **write/push** access via a
persistent host session: `git push` to a new branch, and to `ralph-status`,
both succeeded and were verified (`ralph/R0.3.5` merged through the normal
CI → `ralph-merge.yml` path).

One residual gap: `git push --delete` (and the GitHub API's branch-delete)
still returns HTTP 403 at the proxy level, even though creating and pushing
branches works. Probe branches from the reattachment check could not be
deleted and, being plain docs commits, one of them (`ralph/PUSH_TEST.md`) went
green on CI and got auto-merged into `main` before this was noticed — cleaned
up in the same commit as this entry. **Future firings: do not create
throwaway probe branches** unless you also plan to leave them merged; there is
currently no way to delete a remote branch from a fired session.

**What the wall cost while it stood:** the first firing to hit it solved
`R0.3.5` — three real bugs found and fixed, verified 10/10 green — and the
commits died with the container. The diagnosis was recovered into
`BACKLOG.md`; the code was not, and was redone from that diagnosis once push
access returned.

---

## ✅ RESOLVED — the two Quaternius MegaKits are staged

**This entry is retracted as of 2026-08-11.** The owner downloaded both zips
by hand and supplied them via Google Drive (the first link required a
sign-in — sharing was set to restricted rather than "anyone with the link";
the owner fixed it and the second attempt worked with a plain anonymous
`curl`, using the confirm-token URL Drive's own "can't scan for viruses"
interstitial page provides for files this size).

Staged as `assets_raw/vendor/quaternius_medieval-village-megakit/` (176
models) and `assets_raw/vendor/quaternius_fantasy-props-megakit/` (94
models) — glTF export only, not the full zips: each pack ships the same
models three times (`FBX/`, `OBJ/`, `glTF/`) plus a separate `Textures/`
folder for the non-glTF formats, and only `glTF/` is self-contained
(`.gltf`+`.bin`+its own textures). Same format `EV2`'s Stylized Nature
MegaKit already uses. Both packs ledgered in `docs/ASSET_LEDGER.md`.

**This unblocks `EV6`, `EV7`, and `EV2-landmark-ceiling`** (the last of
which should now also check this Village kit and the fuller Nature MegaKit
before accepting the hero-tree ceiling). Choosing which specific
buildings/props to actually use is still `EV6`/`EV7`'s own work — this only
acquired the raw packs, the same split `EV1` drew for the Kenney packs.

### Original entry, kept for the record — the itch.io click-through problem

`EV6` (settlement, `D24`-settled to Medieval Village MegaKit — no substitute
kit) and `EV7` (prop clusters) both need packs that live behind itch.io's
anonymous-claim flow, and that flow could not be automated from this session.

What was actually tried, in order:

1. **`curl` on the vendor page and the itch game page.** Both are static HTML;
   the real per-file download URL needs a numeric `upload_id` that itch only
   discloses after a client-side "Download Now" click completes a
   purchase/claim POST round-trip. It is not present in the page source
   before or after that click, logged-in or not — confirmed on the Medieval
   Village MegaKit page (`Medieval Village MegaKit[Standard].zip`, 153 MB,
   `price: "$0.00"` from the embed widget's own JSON, so this is not even a
   pay-what-you-want gate, just a JS one).
2. **Headless Chromium via Playwright**, already installed in this
   environment for exactly this kind of task. Ruled out for a more basic
   reason than itch.io's flow: it cannot open **any** HTTPS site through this
   session's proxy — `net::ERR_CONNECTION_RESET` on `page.goto()` against
   `example.com` and `kenney.nl` (a host `curl` reaches fine, seconds
   earlier, in the same container), with the proxy passed to `launch()`
   explicitly. This is a Chromium-vs-this-proxy problem, not an itch.io
   block, and it would stop any browser-automation approach to this task, not
   just this one pack.

The four Kenney packs `EV1` also needed (UI Pack, RPG Expansion, Input
Prompts, Game Icons + Expansion) downloaded and shipped fine — kenney.nl's
own "Download Now" popup resolves straight to a `.zip` on their CDN, no claim
step. This is specifically an itch.io gate, not a general download-access
problem.

~~**Clears when:** either the owner downloads
`Medieval Village MegaKit[Standard].zip` and
`Fantasy Props MegaKit[Standard].zip` from the itch.io pages linked in
`docs/ENVIRONMENT_AND_UI_BIBLE.md` and supplies them (a repo upload, a
reachable URL, anything a firing can `curl`), or a future firing has a working
itch.io session (a stored API key, or a proxy that can pass a real browser
session through cleanly) to complete the claim itself.~~ Cleared as above —
the owner supplied them directly, so the itch.io flow was never actually
needed.

---

## Blocked on the owner

### ✅ RESOLVED — hillside rock and Grandpa's house route: not tuning again, redone from scratch

**Both original entries (hillside rock, Grandpa's house route) are retracted
as of 2026-08-12.** The owner looked at
both and confirmed the reads still don't work — the hillside rock still
doesn't read as stone, and the house route is still bothered by the
matched-border "flanking" look, even once "flanking" was explained plainly
(plants on either side of the path pairing into a symmetric, deliberately-
landscaped-looking border). Neither round of blind-tuning evidence changed
that verdict, so the owner's direction is to stop tuning and **redo both
from scratch** rather than keep layering rounds onto the same approach.

Two fresh backlog items carry this forward: `OF11` (hillside rock material/
relief, dispatched at `model: fable`, explicitly told not to start from the
five prior tuning rounds) and `OF12` (Grandpa's house route vegetation
placement, same treatment). See `BACKLOG.md`'s `Phase -1.1`. The evidence
in `DONE.md` for the prior attempts (`EV4-hillside-seam` through
`-remainder-4`, `EV3-remainder` through `-remainder-6`) stays as a record of
what was tried and ruled out — it should inform the redo's judgment, not
constrain its starting point.

### ✅ RESOLVED — the `square-convergence`/`the-rise-route` "unmotivated dark patch" is accepted as ordinary material contrast

**Closed 2026-08-12.** `EV4-textures-lighting-remainder` (`DONE.md`) tested
ten mechanisms across its full history and ruled all of them out one by
one — shadow toggle, SSAO, normal-map depth/AO, ambient energy, baked
vertex colour, photo albedo content, PSSM cascade splits, shadow bias.
What finally explained it was direct pixel measurement under the dark-
patch's own mask: pure-path control-map pixels average luma 130, pure-
grass-dominant pixels average luma 67 — a real, ordinary material
contrast, not a rendering defect. The "patch" is
`build_playground_terrain.gd::_path_control()`'s own documented design
working as intended: the outer half of every path's feathered shoulder
deliberately blends toward the natural (grass/soil) texture, and ordinary
grass sitting next to a brighter path reads as "a shadow with no caster"
purely by contrast.

The owner looked at `shots/_diag/square-convergence-normal.png` and
**accepted the current read** — no fix needed, the feathered-edge path
design stays as-is. Nothing left waiting here.

### ✅ RESOLVED — the appeal gap is the starter orb-picker screen, not the roster

**Closed and narrowed 2026-08-12.** Split out of `SA0-orbs-remainder`
(2026-08-11): four blind-judge rounds on the starter orb picker converged
with the critic calling all three previewed creatures — Terrapup, Ripplet,
Galewisp alike, not one outlier — "an asset preview, not a hero character
portrait" next to the Palworld reference set.

The owner confirmed the scope directly: the in-game creatures already look
great; this was always about the **orb-picker/starter-selection screen's
own staging** — lighting, material presentation, framing — not the
roster's in-game presentation, and not a `SA5`/`SA6`-style pairwise
look-alike fix either. Approved: make the orb-picker's presentation
better. A new backlog item carries this forward, scoped narrowly to that
screen — see `BACKLOG.md`.

---

### ✅ RESOLVED — NP1-geometry: owner approved a new Meshy generation, gated on a reference board

**Closed 2026-08-12.** `NP1-geometry` read as "blocked on `NP4` or
`EV1-remainder` supplying an actual modular mesh," and both of those
shipped — checking confirmed it hadn't genuinely unblocked:
`assets/characters/{villager_female,villager_male,grunt}/*_lod0.glb` are
each still one fused mesh, one material, no separable hair/accessory node,
same limitation trainer/Grandpa/Warden already had.

This entry previously foreclosed the fix as permanently material-and-
rework-only, reading `D24`'s "what it does NOT change" section as covering
this case. **The owner's answer clarifies it doesn't**: `CLAUDE.md`'s own
rule already carves out "at most one or two new human generations, owner-
supplied only, and only for reusable archetypes" — and the villager bases
are exactly that, reused across the whole NPC cast. The owner approved a
new Meshy generation to make them modular, and will supply reference art
(or existing NPC art can be reused as reference).

**This does not lift the reference-art gate** — `CLAUDE.md`/`D24` still
forbid generating without a board in `docs/art/reference/` first, unchanged
by this approval. A new backlog item (`NP7`, `BACKLOG.md`) carries this
forward, blocked on that board landing before any credit is spent.

---

### ✅ RESOLVED — `ASSET_LEDGER.md` licence claim

**Closed 2026-08-12.** The ledger stated "Everything currently in the build
is CC0 1.0." It was not: the Meshy-generated creatures and the Plumberry
Plains pack are not CC0. The owner supplied the correct wording: **All
Rights Reserved / proprietary**, owner-licensed. `docs/ASSET_LEDGER.md`
updated to mark those two sources accordingly; everything else keeps its
real, already-correct licence.

---

## Reference art — the rule stands; the list is EMPTY

**Credits stopped being the constraint on 2026-08-11.** The owner topped the
Meshy account to **5000**, and in the same message set the rule that replaced
it: *"we should never render without me loading art first."* So a firing may
not generate anything the owner has not supplied a reference board for, the
way `docs/art/reference/12_NPC_Bases_Reusable.png` was supplied. In-engine
survey and screenshot renders are unaffected — they are how anything gets
verified at all.

**That rule is still live. What is no longer live is the list.**

### ✅ Waiting on a reference board — nothing

All three arrived on 2026-08-11, the same day they were asked for:

| Board | Object |
|---|---|
| `docs/art/reference/13_Tether_Energy_Pylon.png` | Team Tether energy pylon |
| `docs/art/reference/14_Relay_Apparatus.png` | Team Tether relay apparatus |
| `docs/art/reference/15_Legendary_Tether_Machine.png` | The legendary tether machine |

These are the three places `docs/ENVIRONMENT_AND_UI_BIBLE.md` §13 endorses
Meshy at all, and D24 confirms it: hero objects only. **Nothing on the
authorised programme is blocked on a drawing any more.** They are still gated
on their bands arriving — the relay is Band 3 (`SE23`), the pylons are `SF33`'s
severed roads, the machine is the Warden stronghold in Phase 8e — so this is
"buildable when you get there", not "build it now".

**Read the board before generating; each carries real constraints.** The pylon
names a **2K–3K triangle** target and a five-part modular build (base + core
module + supports ×4 + top frame + tether crystal). The relay is
*"modular construction, core and rings serviceable, conductor arms and
manifolds replaceable"*. The machine stands ~15 m against its own 0–20 m scale
bar. Those are production briefs, not mood art.

### ⚠ The machine board contains a creature. Do NOT generate it.

`15_Legendary_Tether_Machine.png` shows a legendary bound inside the
containment ring, because that is what the machine does. **The board licenses
the machine, not its occupant.** `D23` §20 forbids new creature meshes for the
Meadows at any credit balance — reaffirmed *with* 5000 available — so the bound
legendary must be an existing roster creature or VFX. A firing that generates
the whole board as one asset breaks a hard rule while believing it is following
one, which is exactly why this warning is here and not left to inference.

**Explicitly NOT on this list**, by the owner's decision: creatures, the
trainer, Grandpa and the Warden. D23 §20 forbids creature regeneration at any
balance — reaffirmed with 5000 credits available, so it was never a budget
rule — and D24 resolves the humans to rework as well. Those are
material-and-rework problems permanently.

Anything else a firing believes needs generating stops and adds a line here,
rather than spending.

---

## Resolved — the four bird species do not need `animate_bird.py`

**This entry is retracted.** The premise — "no `animate_bird.py` exists" —
was true but the conclusion drawn from it was wrong. `rig_bird.py`
(1546 lines) is not a bare rigging script the way
`rig_quadruped.py`/`rig_glider.py`/`rig_sitter.py` are: it authors all six
standard clips itself (`author_all()`), already proved end-to-end on
three winged test meshes per its own docstring, and its bone names
deliberately overlap `animate_quadruped.py`'s glider layout "so that
script still produces something sane if it is ever pointed at a bird."

The real bug was in `finish.py`'s `rig` subcommand: it called
`animate_quadruped.py` unconditionally after rigging, regardless of
`--kind`. For a bird this didn't just duplicate work — it would silently
re-detect the already-animated bird rig as a glider and overwrite
`rig_bird.py`'s bird-specific animation with generic glider animation,
including `animate_quadruped.py`'s documented faint-spin bug (root bone
yaw applied where the rig's local Y is world-up, so the creature spins on
the spot instead of toppling).

Fixed: `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`, since `rig_bird.py` already produced the finished,
animated output. Proved on Galecrest, the first bird species shipped —
see `DONE.md`. **No further code work is needed for Duskhush, Pipwing, or
Reedwing** — the same `clean → texture → rig --kind bird → grade →
install` sequence used for every quadruped now works for birds too.

---

## Resolved — the key reaches a CRON firing, not a self-scheduled resume

The Meshy key is **carried in the cron Routine's own prompt**, so every
hourly-fired session has it without the owner doing anything. There is no
tool to set an environment variable on this environment, and the repository
is the one place the key must never go: GitHub history is permanent and
secret scanning would likely revoke the key on push. **A firing's own
`send_later` self-resume is not the cron Routine** — see the entry above,
found twice now — so do not expect the key there.

Use it by prefixing the one command that needs it. Never write it to a file,
never echo it, never put it in a commit message, a manifest or a report.

If `meshy.py check` fails to authenticate on a firing that SHOULD have the
key (i.e. a cron firing), the key has been rotated — say so here and stop the
art tasks rather than guessing.

---

## Play gates awaiting the owner — the loop does NOT wait here (D21)

The owner plays these whenever they can; their feedback comes back as new
backlog items. The loop keeps building past them.

- **R0.11** — play the NEW first day end to end (wake upstairs → Grandpa's
  gifts → choose and name a starter → the paths → harvest → a fight and a
  catch → camp before dark → day 2).
- **`SA0` / `SA1`** — the two P0 fixes shipped 2026-08-11 (`6dffa21`,
  `28af489`; Windows build published 13:09 UTC). Two questions only the
  owner's device can answer:
  1. **Can you talk to Grandpa now?** Walk off the bed *without* pressing it,
     then go downstairs. `tests/smoke_wake_softlock.gd` proves this headless
     and was verified to fail against the unfixed build first, but the report
     came from the device.
  2. **Is the choppiness gone?** CI cannot measure VRAM — the device is the
     instrument, exactly as with RB4. If it is better but not fixed, the next
     suspect is already written down: `vegetation.gd::_retint()` rebuilds an
     `ArrayMesh` and discards the importer's LOD chain, so every tree and tuft
     draws at LOD0 at every distance. That is `SA1-lod`, already queued.
- **`EV10`** — bible §22 Phase G's cohesion pass. Marked `▶` because it is a
  re-shoot-and-judge-against-both-reference-sets checkpoint that only
  converges once `EV2`–`EV9` (the look, the cast) are actually shipped — doing
  it earlier just re-measures gaps those items already own. Per D21 the loop
  does not wait on it; noting it here each time it is the topmost unblocked
  item and getting skipped (2026-08-11, `EV8` firing) so it does not silently
  fall off the list.

---

## Design questions awaiting the owner

**All entries below are closed.** They are kept rather than deleted because
each one records *why* the answer is what it is, and every answer is the kind
a later firing would otherwise be tempted to relitigate.

### ✅ CLOSED — should the stronghold be visible from the start? (`OF9`)

**Closed 2026-08-12 by direct owner answer:** hidden, and moved farther from
the village — the player should not be able to see it from the beginning.

This reverses the lean of the evidence gathered when the question was raised
(the distant view was planned from `MEADOWS_VERTICAL_SLICE.md` M7 onward, and
`R7.1`/`R9.4`/`OF4` had all spent real effort making that distant silhouette
read better) — worth stating plainly since a later firing skimming that
history could otherwise assume "visible" was the settled direction. It was
evidence about what had been *built*, not about what the owner *wanted*; the
direct answer supersedes it.

**Carried forward as `OF13`** in `BACKLOG.md` — relocate the landmark farther
out and occlude/hide it from the village and the early routes, rather than
just nudging it. Not a `model: fable` item: the "does this look right"
judgment call is already made (hidden, farther away); what's left is
mechanical placement and occlusion work.

**Note for whoever picks up `OF13`:** `OF4`'s silhouette rework (`ralph/OF4`,
PR #14) touches the same `landmark.gd` the relocation needs — land that
first, or rebase carefully, rather than duplicating the conflict.

### ✅ CLOSED — creature and human art-pipeline cohesion: rework, both halves

**Closed by `docs/decisions/D24` (2026-08-11).** The owner reaffirmed D23 §20
*with 5000 credits in the account*, which settles the one thing this entry was
still asking. §20 was never a budget rule, so a healthy balance does not lift
it — and D24 extends the same logic to the humans by reserving Meshy for Team
Tether hero objects only.

**The answer is rework, on both halves.** Paddlenewt, Pipwing and Ripplet get
`grade.py`'s palette path (`SA5`, `SA6` apply the same lever elsewhere). The
trainer and Grandpa get material work and `NP1`'s modular system, not a
replacement generation. Nothing below is waiting on the owner any more.

The budget arithmetic in the original entry is obsolete — it reasoned from 175
credits, and the balance is 5000. It is left in place only because the
*evidence* it cites is still the evidence.

The consequence is worth stating plainly, because it is permanent and someone
will want to reopen it: the fidelity gap a blind critic called *"the loudest
single problem in the whole review"* is now a material problem forever. That
is the accepted trade, not an oversight.

Original narrowing, kept for its reasoning:

**Narrowed by `docs/decisions/D23` (owner spec §20–§22, 2026-08-11).** This
entry used to ask one question about two things. It is now one question about
one thing.

- **Creatures — answered, by removing an option.** §20 forbids new creature
  meshes and Meshy generations for the Meadows outright. Replacement is off the
  table, so the only remaining answer for Paddlenewt, Pipwing and Ripplet is
  **rework in place**, through `grade.py`'s repair path (numpy and Pillow, no
  Blender, no credits). That is effectively the decision; no owner input is
  needed to proceed on it. `SA5` and `SA6` in `BACKLOG.md` are the same lever
  applied to Burrowback and the bird roster.
- **Humans — still open, and §21 raises the stakes.** §20 says *creature*; it
  does not touch the flat-shaded trainer and Grandpa standing next to the
  Warden's painted finish, which the blind review called "the loudest single
  problem in the whole review". §21 makes it worse rather than better by
  promoting those exact two rigs to base bodies for the entire NPC cast.
  §22's one-or-two optional generations are a partial lever but do not answer
  *which* assets get the treatment.
- **Not part of this question:** `R3.0`, re-running the three humanoid GLBs
  through the fixed `animate_humanoid.py`, is a pipeline re-run rather than a
  generation. It costs no credits and is compatible with §20 and §22.
- **Budget arithmetic the owner should see before deciding.** 175 credits
  remain at roughly 90 per species. "One or two" generations is realistically
  *one comfortably, two only if a human costs less than a creature*. Spending
  it on a Team Tether grunt base leaves nothing for the Warden's face, which is
  still painted rather than modelled (HANDOFF §6).

~~**Clears when:** the owner decides what happens to the trainer and Grandpa —
regrade in place, one §22 generation, or accept the gap for now.~~
Answered above: regrade in place, and accept the gap as the cost.

Original entry, kept because its evidence is still the evidence:

Raised by the 2026-08-09 site-frames critique for the three starters alone
("three assets from three different store packs"); **R0.8.5's full blind
review of the whole roster confirms it's bigger than the starters** and adds
a second axis the earlier pass never saw because it had no frame with the
Warden and the trainer together:

- **Creatures**: Paddlenewt, Pipwing and Ripplet render in a glossier,
  big-eyed toy/gacha finish that doesn't match the painted-matte naturalism
  the rest of the roster shares (the moss-and-stone material language on
  Burrowback, Mosshell, Tuskroot and Terrapup is, per the blind critic,
  "the single best piece of cohesive art direction anywhere in this set" —
  which makes the mismatch on the other three more visible, not less).
- **Humans**: the trainer and Grandpa are flat-shaded and low-detail next
  to the Warden's fully painted, richly textured finish — called out as
  "the loudest single problem in the whole review" because the trainer is
  who the player looks at for the entire game, unlike a boss seen once.

Full record: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`. Whether
to rework the mismatched assets or replace them is an art-direction call
this evidence is for, not a call to make silently.

~~**Clears when:** the owner decides rework vs. replace (and for which
assets — the three creatures, the trainer/Grandpa pair, or both).~~
Superseded by the narrowed question above: §20 answers "rework" for the
creatures; only the trainer/Grandpa pair is still a live decision.

### ✅ CLOSED — the settlement's vernacular: Medieval Village MegaKit

**Closed by `docs/decisions/D24` (2026-08-11).** The critic asked the owner to
pick one tradition and not split the difference. The owner supplied
`docs/ENVIRONMENT_AND_UI_BIBLE.md`, which picks **the Medieval Village
MegaKit** as the Meadows civilian architecture — the Northern European branch
of the choice below, and the one the key art board's own thatch-plaster-timber
settlement panel already leaned toward.

So the answer is the critic's first option: *keep the mill and shift the whole
settlement toward a Northern European vernacular.* The red gambrel barn, the
barn-house, the shed and the coop are the assets that move; the windmill was
never the outlier once the family changed underneath it. `EV6` in
`BACKLOG.md` is that rebuild, and it is a rebuild on one kit rather than the
retint this entry assumed would be enough.

One thing the closure does **not** buy: the owner chose free Standard tiers
only, so the Source editions' Godot wind shaders and optimised collisions are
not available and `EV3` has to build that work itself.

The original question, kept because every later structure still has to join
whichever family was named:

Raised by R9.4's blind buildings critique (2026-08-11,
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`). The critic identified three
unrelated building families standing in one field and was explicit that this is
a decision rather than a defect:

- **North American farm vernacular** — the red gambrel barn, the barn-house, the
  small shed, the chicken coop. Red board-and-batten, white cased trim, X-braced
  doors. This is the majority and it is internally consistent.
- **Northern European tower mill** — the windmill. Grey stone drum, timber
  gallery, mullioned sashes, arched door. "A completely different building
  tradition, different material palette, different era… the clearest 'asset
  from a different pack' in the set."
- **The well** is a third outlier on materials specifically: a terracotta
  pantile roof, the only tiled roof in the build, over cold blue-grey stone
  against the barn's warm maroon.

The critic's own instruction: *"keep the mill and shift the whole settlement
toward a Northern European vernacular, or keep the American farm family and swap
the mill for a timber post-mill. **Do not split the difference.**"*

This matters beyond the Meadows: `MEADOWS_PROGRESSION_SPEC.md` adds a quarry, a
relay station, a mill crossing and a stronghold approach, all of which need
buildings, and whichever family is chosen now is the one every later structure
has to join. Retinting either way is cheap; choosing is not a firing's call.

~~**Clears when:** the owner names the vernacular. Note that the key art board's
own settlement panel leans European — thatch, plaster, timber framing — which
is an argument, not a decision.~~ Named: Medieval Village MegaKit, per D24.

---

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
