# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

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

### Does the hillside's rock ever read as stone, or is the procedural slope-blend a ceiling to accept on this landform?
Five real rounds now, across `EV4-hillside-seam` through `EV4-hillside-seam-remainder-4` (`ralph/DONE.md`), chasing one blind critic's repeated core verdict on `rises.peaks[0]` (`data/config/terrain_playground.json`, centre [140,-90], radius 78): "two materials, not three; rock reads as a stain/watermark/AO artefact, not stone." Three colour/value rounds (`remainder` through `remainder-3`) tried every lever in that layer — rock's own tint and photo brightness, soil's hue pushed both directions, `blend_deg`/`soil_slope_deg`/`rock_slope_deg` retuned four times — with real, measured movement on every axis and zero movement in the critic's verdict across all three. `remainder-4` tried a genuinely different class of lever: real height relief (`playground_heightfield.gd`'s new `_relief` noise, gated to each rise's flank so footprint and summit are untouched), not another tint. Two full attempts, 0.8m then 2.5m amplitude — the first confirmed active by direct height/slope probing but invisible at render distance; the second visibly broke the dome's silhouette in two of three frames. A fresh blind critic on the second attempt still delivered the same core verdict, near word-for-word: "still reads as a smooth green dome with grey patches added... the underlying mesh has no relief anywhere a material changes." The one thing that did move — a "slight ripple" now visible near the crest — sits away from where the actual grass/soil/rock transition happens on the flank, not on top of it.

**Why this stops here instead of a third geometry round.** Both classes of lever this landform's own bake can offer — colour/value (three rounds) and height/relief (two rounds, one order of magnitude apart in amplitude) — have now been tried with real, verified, measured movement and zero verdict movement in the critic across all five rounds combined. Retuning `relief_amplitude` a third time, or chasing the crest/flank misalignment the second attempt's own ripple hints at, is a plausible next lever but not a config-tuning task any more — it would mean either hand-placing relief precisely where each rise's own actual rock/soil band falls (a bespoke, per-rise authoring pass, not a procedural parameter) or accepting that a coarse-noise procedural blend on a single perfectly-round dome primitive has a real ceiling this landform's own shape imposes, the same class of ceiling `grandpas-house-route.png` (above) already hit for vegetation placement.

**Clears when:** the owner looks at `shots/hillside/dome-overview.png` (or a fresh render via `tools/capture_hillside.gd`) and either accepts the current read as-is, or says in their own words what's actually wrong with it — which, same caveat as `grandpas-house-route.png`, may not be "no third material" at all once someone who isn't comparing against reference photos frame-by-frame looks at it in the context of the rest of the meadow.

### Is grandpas-house-route.png's "flanking" read worth further iteration, or is it a placement-density limit to accept?
Five real, evidence-first rounds (`EV3-remainder` through `EV3-remainder-6`,
`BACKLOG.md`/`DONE.md`) chasing one blind critic's repeated complaint on one
specific frame — a hedge/flanking pattern near Grandpa's house's approach
route. Each round found and fixed a genuine mechanism: `flowers`' clump
straddling the path centreline, grass/drygrass strays landing near a path
by chance, `path_stones`' clump radius spreading stones twice the path's
own width. Two rounds tried the more direct lever of just adding ground-
cover density and made the SAME frame measurably worse, not better —
`EV3-remainder-2` bumping `path_bias` and `EV3-remainder-6` adding an
authored off-path clump both recreated the exact flanking read they were
meant to fix, for a now-understood reason: any concentrated addition near
this route, whichever side it lands on, pairs with whatever is already on
the far side and reads as a matched pair. The layers that could plausibly
be responsible (`flowers`, `bushes`, `grass`, `drygrass`, `trees`, `grove`,
`saplings`, `rocks`, `path_stones`) have all been dumped against this
frame's real placement data and are individually either fine or already
fixed.

**Why this stops here instead of another config tweak.** There is no
further `path_bias`/`path_avoid_radius`/`clump_radius`/`extra_clumps` lever
left untried for this specific frame that the diagnosis chain hasn't
already tried and either confirmed harmless or confirmed harmful. What's
left is either a genuinely different placement mechanism for this one route
specifically (a real scope question — how much bespoke authoring one
frame's approach earns, when the rest of the meadow is procedural by
design) or accepting the current state as the honest ceiling of a
procedural scatter system tuned this many times against one photograph.
Neither is a `vegetation`-scope config edit a firing should keep guessing
at.

**Clears when:** the owner looks at `grandpas-house-route.png` (`shots/
paths/`, or a fresh render via `tools/capture_paths.gd`) and either says
it's fine as-is, or says what's actually wrong with it in their own words —
which may not be "flanking" at all once a human who isn't a blind critic
comparing against reference photos looks at it in context with the rest of
the meadow.

### Does the creature roster clear a Palworld-level appeal bar, or does it need to?
Split out of `SA0-orbs-remainder` (2026-08-11): four blind-judge rounds on the
starter orb picker converged with the critic calling all three previewed
creatures — Terrapup, Ripplet, Galewisp alike, not one outlier — "an asset
preview, not a hero character portrait" next to the Palworld reference set.
This is broader than any single defect a scene tweak can fix, and broader than
`SA5`/`SA6`'s mandate, which is narrowly pairwise (stop two specific species
reading as palette swaps of each other, e.g. Burrowback/Terrapup,
Galecrest/Galewisp) — nothing in `SA5`/`SA6` asks whether the roster's overall
finish reaches a Palworld-quality bar, only whether look-alikes are told apart.

**Why this stops here instead of becoming a backlog item.** "Improve creature
appeal" is not an executable task the way `SA5`/`SA6` are — there is no
concrete done-when a firing could aim at without first deciding *how much*
rework is worth doing and on what lever. The only lever available at all is
material/lighting rework: `D23` §20 and `CLAUDE.md` forbid new creature meshes
or Meshy regeneration for the Meadows at any balance, reaffirmed with 5000
credits in the account specifically so a healthy balance would not be read as
license to reopen it. So the real question is a resourcing one — is a
roster-wide `grade.py`-style material/lighting pass (beyond the specific
species pairs `SA5`/`SA6` already own) worth a firing's time, given the
geometry itself is fixed and cannot close the gap on its own — and that is a
priority call, not a design-decision-in-CLAUDE.md's-flagged-list call, but it
still is not a firing's to make unilaterally: it commits real time against a
ceiling (material rework alone) that may or may not be enough to satisfy the
bar the owner set.

**Clears when:** the owner says whether a roster-wide material/lighting pass
is worth commissioning — and if so, whether it is scoped as its own backlog
item or folded into `SA5`/`SA6`'s existing remit — or accepts the geometry-era
finish as the cost of the no-new-mesh rule, the same trade `BLOCKED.md`'s
"creature and human art-pipeline cohesion" entry above already accepted for
the three toy-finish creatures it named.

---

### `NP1-geometry` — no real hair/accessory geometry exists anywhere, and generating one is foreclosed
`NP1-geometry` (`BACKLOG.md`, Phase -0.55) read as "blocked on `NP4` or
`EV1-remainder` supplying an actual modular mesh," and both of those shipped
since it was written — so this firing (2026-08-12) checked whether it had
genuinely unblocked, rather than trusting the premise.

**It hadn't.** Parsed `assets/characters/{villager_female,villager_male,
grunt}/*_lod0.glb`'s glTF JSON directly, the same way `NP1`'s own entry did
for the original three human rigs: each is **one fused mesh (`char1`), one
material (`Material_1`), no separate hair or accessory node** — byte-for-byte
the same limitation trainer/Grandpa/Warden already had. `NP4`'s pipeline is
Meshy image-to-3D from a turnaround sheet (`NP4`'s own `DONE.md` entry:
"57k-tri non-manifold triangle soup → clean 28k-tri manifolds" — one mesh,
cleaned once); it was never going to produce the NPC board's own brief —
quoted in `D24` — of "hide/show accessories via separate mesh parts, hair
variants sharing head topology." Checked `EV1-remainder`'s two Quaternius
kits too (`assets_raw/vendor/quaternius_medieval-village-megakit`,
`assets_raw/vendor/quaternius_fantasy-props-megakit`) rather than assume:
village architecture and props, nothing character-shaped, confirmed by a
`find -iname "*hair*" -o -iname "*accessor*"` turning up nothing but a false
positive on "Chair".

**Why this doesn't become a normal backlog remainder.** The only way to
supply real separable hair/accessory geometry now is another Meshy
generation, and that's foreclosed twice over: `D23` §20 forbids new creature
meshes at any balance, and `D24`'s own "What it does NOT change" section
extends the same rule to humans — "the three off-style creatures and the
trainer/Grandpa fidelity gap are permanently material-and-rework problems,"
reaffirmed with 5000 credits available specifically so a healthy balance
would not read as license to reopen it. So this is not "not built yet," it's
"the pipeline that would build it is the one thing the owner has closed off,"
and reopening that is exactly the kind of call `CLAUDE.md` reserves for the
owner, not a firing.

**Clears when:** the owner either accepts `NP1`'s placeholder-primitive
mechanism as the permanent look for hair/accessories (closing `NP1-geometry`
outright — the data/attachment system it built is real and already shipped,
only the geometry stays placeholder), or names a non-Meshy source for
modular human hair/accessory parts (a CC0 pack, same as `EV1-remainder`
supplied for the settlement) for a future firing to wire in through the
mechanism `NP1` already built.

---

### `ASSET_LEDGER.md` licence claim is false
The ledger states "Everything currently in the build is CC0 1.0." It is not: the
Meshy-generated creatures and the Plumberry Plains pack are not CC0. The correct
wording depends on the owner's Meshy plan terms, which no agent can verify.

**Clears when:** the owner supplies the licence wording.

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

**Both entries below are closed as of 2026-08-11.** Nothing in this section is
waiting on anybody. They are kept rather than deleted because each one records
*why* the answer is what it is, and both answers are the kind a later firing
would otherwise be tempted to relitigate. The live list is "Blocked on
reference art" above.

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
