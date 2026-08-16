# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

---

## ✅ RESOLVED, 2026-08-15 — `model: fable` dispatch is available again (was: out of usage credits)

`ralphKeyed-20260815-0251` held the Meshy key this firing and, per `PROMPT.md`'s
`model: fable` dispatch rule, tried to hand `SF33`'s pylon-generation slice to a
`model: fable` subagent rather than do the creative work itself. Two independent
dispatch attempts (a real task handoff, then a one-word capability probe) both
errored identically and immediately: *"Agent terminated early due to an API
error: You're out of usage credits. Switch to another model to continue."* This
is an account-level Claude API condition, not a bug in the dispatch mechanism or
a Meshy problem — the Meshy key itself was confirmed working (`meshy.py check`:
4790 credits) before this was hit.

**While this was open, every `model: fable` item was unpickable by any firing**
— `SF33` (parked, `art`/`assets` leases released, no code changed), and by the
same mechanism `SE23`, the Phase 8e Tether Chamber asset, `R8.3`, `SG40`,
`R8.4`, `R8.6`, `SE21`, `SE30`, `SF34`, `R4.10`, `EV10`. Per `PROMPT.md`, a
firing may not do a `model: fable` item's creative work at a lesser tier as a
workaround — so the loop skipped every `model: fable` item exactly as it would
skip a `lane: art` item with no key, and took the next item instead (fell
through to `R3.2`).

**Resolved, same day.** The owner confirmed the account's usage reset a few
hours later. A firing independently re-probed and confirmed fable dispatch
working again, then successfully dispatched and shipped `SF33` itself
(`a35f02d`, two of seven severed spokes) — real evidence, not just a probe.
All `model: fable` items above are pickable again.

---

## ✅ SUPERSEDED, 2026-08-13 — OF4 silhouette ceiling: owner chose a real rebuild over accepting the primitive ceiling

**The owner's call, when asked:** build a real interactive grid/rotate/snap
placement system and construct OF4 as an actual assembled castle with it —
"then don't worry about it being a silhouette. just make it render the
actual built castle." Recorded in
`docs/decisions/D28-of4-real-castle-and-build-grid.md`, which also notes
`OF13` (shipped after this entry was written) already moved the fortress
off the 170m from-square frame this history was scored against. Carried
forward as `ralph/BACKLOG.md`'s `BG1` (the placement system, which does not
exist yet), `BG2` (a real castle/fortress CC0 kit — neither staged
Quaternius kit has any fortification module), and `OF4-rebuild` (retiring
`landmark.gd`'s primitives once both land). The history below is preserved
as the evidence that led to asking, not as the current plan.

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

### ✅ RESOLVED — hillside rock ceiling, round 2: the owner accepted the current read (2026-08-13)

**Closed 2026-08-13.** Asked directly in an interactive session; the owner
chose path 1 below — accept the current state. "Good enough for a hillside
the player climbs past, not stares at" is now the recorded call. No round 8
ran, no reference board is needed, and `BACKLOG.md`'s `OF11-remainder` is
closed on this decision. The analysis below stays as the record of why the
question was asked.
`OF11`'s from-scratch redo (see `DONE.md`) ran 6 real rounds and fixed the
literal root cause behind every prior round's "smooth grey wash" complaint
(the rock photo was tiled at 8.3m per tile — one 1024px image blown up to
house-sized — retiled to 2.2m plus a contrast-restoration pass), replaced
the geometry mechanism entirely (ridged/domain-warped fractal with tilted
terrace bedding, not the old smooth-noise bump), and fixed a resulting
hard-edge material-boundary defect. Round 6's blind critic confirmed the
old defect is gone: rock "reads reasonably as rock up close... real
bump/crag detail," the landform gives "a real geological silhouette."

**Round 7, one more independent blind pass after the boundary-edge fix,
came back split rather than confirming:** rock is "one grey noise texture
at one UV scale... reads as poured concrete at distance and stretched
sandpaper up close," and names the ceiling explicitly: "a tiled grey noise
texture on a heightmap won't reach Palworld's rock read at any lighting
setting." That is a *different* kind of gap than the one 11 total rounds
(5 pre-`OF11`, 6 within it) have been closing — not a tuning defect this
project's own procedural pipeline can reach, per round 7's own critic, but
a texture-resolution/geometry-detail ceiling that a single 2K tiled photo
on a heightmap may not clear regardless of how it's tuned.

**This needs the owner's read, not another round.** Two independent
critics disagreeing on the same acceptance question at round 6-7 is the
signal this rubric's own stopping rule exists for. Two paths forward,
neither of which this session should pick alone:
1. **Accept the current state** — genuinely, measurably better than
   every prior attempt (see `DONE.md`'s round-by-round history), and
   round 6's independent critic did call it working. A "good enough for
   a hillside the player climbs past, not stares at" call is legitimate.
2. **Commission real rock geometry** — hand-modelled rock formations
   (not a tiled photo) for this landform, which is new-asset territory:
   needs an owner-supplied reference board first, same as any other
   Meshy generation under `CLAUDE.md`/`D24`. No board exists yet.

Renders for the owner to judge: `shots/hillside/*.png`,
`shots/rise-approach/*.png` (both gitignored — re-render with
`tools/capture_hillside.gd`/`tools/capture_rise_approach.gd` if they've
aged out).

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

**Superseded 2026-08-13**: the owner redirected `NP7` away from a new
Meshy generation entirely — "use the already existing art for NPCs but
make them modular this time." The reference-art gate above no longer
applies to `NP7` (the input is the shipped NP4 mesh, not new concept art);
see `ralph/BACKLOG.md`'s current `NP7` entry for the Blender split/re-skin
scope this became instead. This entry stays as the record of why modular
geometry was worth pursuing at all.

**`NP7` shipped 2026-08-13 — see `DONE.md`.** villager_female's twin
ponytail is now a real separated, re-skinned mesh, cut in Blender from the
existing shipped .glb with no new generation, wired into
`character_model.gd`'s existing hide/show/recolour mechanism. One real,
honest remainder (a small residual scalp seam, invisible at normal camera
distance) — see `DONE.md`'s entry for the full technical account.
`villager_male`/`grunt` deliberately not attempted this pass; `NP7`'s
`BACKLOG.md` entry carries the reasoning forward.

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

## Play gates — retired 2026-08-16

The owner removed every `▶` play gate from `BACKLOG.md` on 2026-08-16,
including `R9.5`, the exit gate. Nothing is listed here any more and nothing
should be added. `docs/decisions/D21` stays as history and reads as
superseded, not violated — do not re-create a gate because D21 describes one.

**`EV2-landmark-ceiling` lives here** (moved out of `BACKLOG.md` in the same
pass, per `DONE.md`'s own note that the item moved to `BLOCKED.md` rather than
closing): the hero-tree asset cannot reach the key art's broad-canopy oak
silhouette by rescaling or re-curating what is installed. It needs an asset
the project does not own, so it is an owner purchase decision, not work.
## Design questions awaiting the owner

### OPEN — EV2-landmark-ceiling: `CherryBlossom_3` is the pack's ceiling, confirmed by render, not a placement lever

**2026-08-14.** `CherryBlossom_3` was already established as the only tree
in the full 270-file Stylized Nature MegaKit measured genuinely wider than
tall (16.59w × 14.49h glTF bounds). A real config bug kept it rendering in
its native pink/purple blossom colour instead of the intended green — found
and fixed (`data/config/vegetation.json`'s `grove` layer never keyed
`Leaves_CherryBlossom`, only `Leaves_TwistedTree`) — and a fresh blind
close-up render (trainer parked alongside for scale) confirms the fix: green
canopy, a real leaning/curving trunk. But the same blind pass's direct
verdict on the item's own question is **"not yet" a landmark specimen** —
canopy reads roughly 1.5:1 wide, not the reference's 2.5-3:1 flat-topped,
multi-lobed spread, and the trunk leans but does not fork (no candidate in
the whole pack has separate trunk/branch nodes to produce one).

This is not a curation problem — `CherryBlossom_3` is already the pack's
best available option and nothing else in it is wider than tall at all.
Two paths, neither a firing's call:
1. **Accept it.** Real, confirmed improvement over every `TwistedTree` form
   tried before it — green, leaning, modestly wide — even if it stops short
   of "landmark."
2. **Treat true landmark-oak geometry (a genuinely broad, multi-lobed,
   forking-trunk canopy) as content this pack doesn't have.** `CLAUDE.md`/
   `D24` forbid a new creature/nature-hero Meshy generation for the
   Meadows regardless of credit balance — so if the owner wants this
   pushed further, it needs to be named explicitly as an exception to that
   rule, not assumed.

Evidence: `shots/grove/cherryblossom-closeup.png` (gitignored; re-render
with `tools/_capture_grove_closeup.gd` if it's aged out).

---

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
