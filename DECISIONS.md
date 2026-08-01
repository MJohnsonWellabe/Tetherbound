# DECISIONS

Choices made during the build that were not already settled by the spec docs.
Per `CLAUDE.md`: when a design decision is ambiguous and both options are
reasonable, pick one, write it down here, keep moving. Conflicts with the spec
docs are flagged rather than resolved silently, because the docs win.

Newest first within each section.

---

## Conflicts with the spec docs

These six override something a spec document says. Each names the document it
contradicts and why.

### D1. Renderer is Babylon.js, not Three.js

`ARCHITECTURE.md` lists Three.js with the justification "Requirement". Overridden.

The sibling GolfModel project is Babylon, and it contains a body of measured
mobile-performance work that solves precisely the problems milestones M0 to M2
hit: spatial-cell thin-instance batching (its header records 3.66 ms of a
13.4 ms frame recovered across ~3.8k instances), an adaptive quality governor
with demote-fast/promote-slow hysteresis, a glTF loader facade, a model cache
with rejected-promise eviction, time-sliced scene population, and a soak test
that asserts resource counts are stable across repeated scene rebuilds. On
Three.js all of that is a rewrite in which the same lessons get rediscovered on
this project's timeline.

Cost of the choice: the engine chunk measures 1.56 MB raw / 359 KB gzipped
against roughly 250 KB gzipped for an equivalent Three.js setup. That is inside
the 8 MB first-load budget with room to spare, and cheaper than the 682 KB
GolfModel needed, because Tetherbound uses fewer engine subsystems.

Guardrail that keeps this reversible: all game logic stays renderer-free.
`combat/`, `party/`, `survival/`, `save/` and `data/` may not import the engine
at all, enforced by `tests/bundle.test.ts`. Swapping renderers later is a
rendering-layer job rather than a rewrite.

### D2. Save has a backend

`ARCHITECTURE.md` Stack table says "Save: localStorage + base64 export" and
"No backend". Overridden: the game has Firebase accounts so a player can resume
on another device.

The base64 export string stays. It is cheap, it is the no-account escape hatch,
and it shares a codec with the cloud payload.

### D3. Cloud store is Firestore, not Realtime Database

GolfModel uses RTDB, so this diverges from the house pattern deliberately.

RTDB deletes empty arrays, empty objects and nulls on write and returns them as
`undefined` on read. A fresh Tetherbound save has ten fields where empty is the
normal, correct state: 24 null inventory slots, plus empty `party`,
`releasedLedger`, `structures`, `badges`, `flags`, `buffs`, `harvested` and
`bossesDown`. GolfModel's `migrateProfile` exists largely to backfill what RTDB
ate, and the one path where it did not, a throw inside the merge was swallowed
and reported to the player as "offline" while the write never happened.

Firestore preserves all of it, has a 1 MiB document ceiling that doubles as a
testable size budget, bills per operation (which suits one write per bed
sleep), and can express the party cap in its rules language.

### D4. Bed checkpoint replaces the 60 second autosave

`GAME_DESIGN.md` section 12 specifies autosave every 60 seconds. Amended.

Sleeping in a bed is the canonical save and writes the cloud checkpoint with a
visible confirmation. A local autosave still runs on a 60 second timer plus
`visibilitychange` and `pagehide`, as a crash net only. It never uploads.

That is also the quota design, not only a design preference: a 60 second cloud
write at 1,000 players is roughly 30,000 writes per day, over the Spark free
tier. Bed checkpoints leave about 6,600 sleeps per day of headroom.

Fainting is unchanged and still follows `GAME_DESIGN.md` section 4 exactly:
respawn at the bed, inventory drops to the satchel, pals are never dropped,
world and party and XP stay live. A faint is not a rollback to the checkpoint
blob. The checkpoint protects against a closed tab or a lost device; the
satchel rule handles death.

### D5. Dependency allowlist extended

`CLAUDE.md` sets the approved runtime dependency list at three, howler and
simplex-noise, and requires a one-line justification for any addition.

- `@babylonjs/core`, `@babylonjs/loaders`: the renderer, per D1. Replaces `three`.
- `firebase`: accounts and cloud checkpoints, per D2. Dynamically imported in
  `src/cloud/`, so it lands in its own chunk and never loads for a signed-out or
  locally-configured player.

### D6. Pal models deferred to M5

`ASSETS.md` section "Pal model strategy" assumes six rigged Quaternius animal
base models are pulled and varied by tint, scale and accessory. Deferred, per
that same document's placeholder policy ("Do not spend a day sourcing models
before the character controller feels good on a phone").

The `baseModel + tint + scale + accessory` mapping still lives in
`species.json` from the first commit that creates it, so the M5 swap is a data
change with no gameplay code touched.

---

## Implementation decisions

### D7. Reconciliation chooses a winner; it never merges

GolfModel's `mergeProfiles` blends two copies of a profile field by field:
grow-only counters take `max`, collections union, coins derive from earned
minus spent. That is correct there because a golf profile is an accumulation of
independent facts.

A Tetherbound save is a world snapshot. Blending two divergent copies produces
a world that never existed: a house standing where the player never built, an
inventory holding wood they already spent. So `SaveReconcile.reconcile()` is a
pure, total function that picks a winner, and when it genuinely cannot tell, it
asks the player.

### D8. Save ordering is a revision counter, never a timestamp

`rev` increments only on a server-acknowledged write, which makes it a real
happens-before edge. `savedAt` is display only.

Phones cross timezones, get set by hand, and drift. Ordering two saves by wall
clock will eventually pick the wrong one, and the failure mode is silent data
loss.

### D9. Firestore runs with `memoryLocalCache`

Firestore's persistent cache resolves `setDoc()` locally while offline. With it
enabled, the bed ceremony would print "Saved to your account" for a write
sitting in a queue that may never land.

Offline coverage comes from the local checkpoint mirror instead. A failed write
is reported as a failed write. A save layer that lies about durability is worse
than one that has none.

### D10. Google sign-in popup only, with an email-link fallback. No redirect.

Since Firebase JS SDK v9.15, `signInWithRedirect` cannot complete on Safari or
iOS when `authDomain` is a different origin than the app. GitHub Pages serves
from `*.github.io` while `authDomain` is `*.firebaseapp.com`, so it is always
cross-origin, and Pages is static so the same-origin auth-helper fix is not
available. Storage partitioning drops the pending redirect state and the player
returns silently signed out. GolfModel shipped redirect as a fallback and
documented that it does not work.

Popup is the only Google path. A blocked popup falls through to a passwordless
email link, which navigates to our own origin and has nothing to partition.

Consequence to remember: adding a `Cross-Origin-Opener-Policy: same-origin`
header would break `signInWithPopup` outright. Pages does not set one.

### D11. No anonymous auth

It mints a document for every drive-by visitor, and it looks like a backup
while being unrecoverable the moment site data is cleared. An account the
player cannot recover is a worse promise than no account.

### D12. `worldDeltas.harvested` is a map, not an array

`ARCHITECTURE.md` types it `string[]`. Changed to `Record<string, number>`
mapping node key to the in-game day it was harvested.

Nodes respawn after 2 in-game days, so an array records every node ever
harvested for the life of the save and never shrinks. The map lets entries
older than the respawn window be pruned on serialize, which bounds the field
instead of letting a long save eventually trip the payload size guard.

### D13. `base: './'` rather than `/<repo-name>/`

`ARCHITECTURE.md` calls for the repo name so Pages can serve a project subpath.
Relative URLs do that without hard-coding the name, and they also survive
`vite preview`, a custom domain, and the LAN URL a phone hits during
`npm run dev --host`.

### D14. Firebase web config is committed, not injected from CI secrets

The web API key is a public project identifier. It names a project and
authorizes nothing; security lives entirely in `firestore.rules` and the
authorized-domains allowlist.

Vite inlines `import.meta.env` at build time regardless, so a key "protected"
as a CI secret still ships as a plaintext literal in the bundle. Treating it as
secret would only break local dev, break `npm run preview`, and break the LAN
host a phone connects to, while protecting nothing.

Resolution is keyed on hostname. Any host not on the production allowlist
resolves to `dev`, which runs local-only with the cloud layer fully dormant and
the Firebase SDK never imported at all.

### D15. The save payload is one opaque compressed string

The checkpoint document carries a single gzip plus base64 string rather than
mirroring `SaveV1` field by field.

Four reasons: the round trip is byte-identical with no SDK type coercion; one
codec serves localStorage, the cloud and the section 12 export string, so the
required round-trip test covers all three at once; a 30 KB string does not
generate index entries on every write; and the compression puts the 1 MiB
ceiling out of reach.

Accepted limit: the rules cannot inspect a compressed payload, so a hand-built
document could claim a party of 5 in its header and hold 6 in the blob. That is
acceptable in a single-player game with no leaderboard and no economy, and
`parseSave()` clamps to 5 on every load path regardless. `Party.add()` remains
the sole enforcement point per `CLAUDE.md`; the rules and the parser are
rejection points for corrupt data, not a second enforcement path.

### D16. Bundle discipline test reads code, not comments

`tests/bundle.test.ts` strips comments before scanning for engine imports.

The first run failed on `src/core/babylon.ts` itself, because that file's doc
comment quotes the barrel import it exists to prevent. A rule that cannot be
explained in prose beside the code it governs is a bad rule, so the scanner
learned to read code instead of the documentation learning to avoid words.

### D26. The input layers own separate vectors; Input sums them

`DesktopLayer.poll()` used to assign `intent.move` directly, every frame, from
held keys. Both layers mount whenever the hardware reports touch points, so on a
phone with no keyboard that assignment was always zero and it erased whatever
the touch stick had written microseconds earlier.

The symptom reported by the owner was exact: "all I can do is look around."
`look` accumulates with `+=` and nothing overwrote it, so looking worked while
moving did not. The game was unplayable on its primary target platform and every
unit test, the typechecker and six browser smoke specs all passed.

Each layer now owns a `move` vector and `Input.beginFrame()` sums and clamps
them. `tests/intent.test.ts` covers the contract, including the specific case of
an idle keyboard not erasing an active stick.

The wider lesson, worth remembering before writing the next input feature: the
existing smoke specs boot the game and check that it renders. None of them
*play* it. A spec that presses a key and asserts the player moved would have
caught this on the first run.

### D25. Verification tooling borrowed from TheLongSilence

`tools/` now holds the survey, contact sheet, hole detector and draw-cost probe,
adapted from `achimala/TheLongSilence`. That project's real contribution is not
its renderer, it is a battery of small single-purpose diagnostics that each
answer one question about the built game.

- `tools/holes.mjs` sets the clear colour to magenta and points the camera at
  the ground. Terrain is opaque, so any magenta pixel is a gap. **This is the
  check that would have caught the inside-out terrain instantly**, a bug that
  passed a typecheck, 99 unit tests and five smoke specs and was only found by a
  human squinting at a screenshot.
- `tools/sheet.mjs` tiles a survey into one labelled image. Built by rendering
  HTML and screenshotting it rather than shelling out to ffmpeg: no ffmpeg here,
  no new dependency, and the tiles get real labels and per-shot stats, which an
  ffmpeg tile filter cannot do without a freetype build.
- `--selftest` on the hole detector hides the terrain and asserts that every
  spot then reports a hole. It earned its place immediately by failing twice:
  first because `place()` streams fresh chunks in after the hide, then because
  `TimeOfDay.apply()` repaints `scene.clearColor` every tick and the frame was
  never actually magenta at capture. The detector had been passing vacuously.
- `tools/drawcost.mjs` refuses to draw a conclusion when its own data is
  incoherent. Its draw-call source (`engine._drawCalls`) accumulates instead of
  resetting per frame, so the numbers climb as resolution falls, which is
  impossible. Announcing "draw bound" from that would send the next person
  optimising the wrong half of the renderer.

Deliberately NOT borrowed: Blender MCP. Blender is not installed here, and the
skill states plainly that the addon cannot run headless, so it needs a GUI and a
human toggling a connection. It is also a hard-surface skill (lofted hulls,
greebles) and Tetherbound needs rigged organic creatures, which is a different
and harder discipline.

### D24. The visual target is Palworld and Pokemon, not photorealism

Written into `ASSETS.md` rather than left as a conversation, because "make it
look good" resolves differently for everyone who reads it.

The reference set is Palworld and Pokemon Scarlet/Violet / Legends: Arceus.
Those games are not technically impressive; they are legible and appealing, and
legibility at 390 pixels is a higher bar than fidelity. A judge or a contributor
aiming at photorealism would break the perf budget in `ARCHITECTURE.md` (60fps
on an iPhone 12, under 150 draw calls, no post-processing) and the stated style
in `ASSETS.md` at the same time.

`.claude/skills/visual-judge/SKILL.md` carries the rubric, and says explicitly
that the rubric may not be softened to obtain a pass.

### D23. The interface palette does not follow ASSETS.md

`ASSETS.md` art direction says "warm meadow greens and golds ... a single hot
accent (Tether iron-orange)". The first UI followed it literally and landed
close enough to the studio's golf game that the owner called it out.

That guidance governs WORLD art, where warm daylight grassland is correct, and
the world keeps it. The interface is a separate surface and now runs on its own
system: near-black green base, accents that read as glowing moss, spores and
night-blooming flowers.

Accents carry meaning rather than decoration, which is the part worth
protecting in review:

- lime `--spore` means "you can act on this"
- magenta `--bloom` means party, pals, affinity
- cyan `--dew` means orbs, capture, the throw
- gold `--sigil` is badges and rewards only, so it stays special
- orange `--tether` is Team Tether, enemies and danger, and nothing friendly
  may ever borrow it

Tokens live in `src/ui/styles/tokens.css` and no component may write a raw hex
value, so a retheme is one file. `styleguide.html` is a second Vite entry
rendering the real shipping `components.css`, because a style guide maintained
separately from the stylesheet drifts within a week and then misleads.

### D22. Browser smoke specs, separate from `npm run test`

`tests/smoke/` runs Playwright against a real build: does it boot, does it
render, does the player stand on the ground, does the same seed rebuild the
same world, does everything dispose.

Kept out of `npm run test` and out of the deploy workflow deliberately. A
headless WebGL render under SwiftShader is flakier than any pure test, and a
flaky render must never be able to block a deploy. `npm run smoke` is a thing
you run and read.

It paid for itself immediately, catching three bugs that every unit test and
the typechecker were blind to. All three are in D21.

Note that timing assertions are meaningless here: software rendering runs at a
few frames per second, so the streaming spec asserts forward progress rather
than a drained queue.

### D21. Three rendering bugs the smoke specs caught

Recorded because each was invisible to typechecking, invisible to unit tests,
and would have shipped.

**The error screen was always on.** `.fatal { display: flex }` is an author
rule, and any author rule beats the browser's own `[hidden] { display: none }`.
So the fatal-error overlay sat on top of a perfectly working game from the
first load, showing an empty message because nothing had actually failed. Fixed
with an explicit `.fatal[hidden] { display: none }`. Anything that sets
`display` now has to restate `[hidden]`.

**The ground rendered inside-out.** Babylon is left-handed by default, so the
triangle winding that looks correct under the right-hand rule produces a
surface facing down. The terrain was culled from above: the player floated over
a grey void with a distant horizon band, which looks far more like a camera bug
than a winding bug and cost the most time to find. Diagnosed by toggling
`backFaceCulling` at runtime in a browser session.

**Thin-instance batches inherited the wrong bounds.** A clone takes the
prototype's bounding box, which describes one small prop at the origin, so
every prop batch would be frustum-culled as soon as the camera looked away from
world zero. Bounds are now built explicitly from the chunk footprint, which is
also much cheaper than `thinInstanceRefreshBoundingInfo` walking every matrix.

Related, and worth stating because it looks like free performance:
`doNotSyncBoundingInfo` on static terrain chunks is not safe. It leaves bounds
that do not describe where the vertices are, and the chunks nearest the camera
get culled.

### D20. Scatter separates `mask` from `density`

Two parameters that sound like one, doing genuinely different jobs at
different points in the pipeline.

`mask` is hard exclusion (water, cliffs, the village footprint) and applies
BEFORE the spacing pass, so an excluded candidate never suppresses a valid
neighbour. Filtering it afterwards instead would let a candidate standing in a
river suppress the tree on the bank, leaving a bald ring around every
shoreline.

`density` is thinning and applies AFTER the spacing pass, which is the only
place it can control the count. This was caught by a test rather than
reasoned out in advance: thinning candidates beforehand took a 300x300m plot
from 837 points to 830, a 1% reduction from a parameter set to 0.5. Minimum
spacing is the binding constraint, so removing half the candidates just lets
the survivors close ranks. Post-filtering also leaves irregular gaps, which is
what a thinner stand of trees should look like anyway.

### D19. Scatter uses a global jittered grid, not per-chunk Poisson-disk

`ARCHITECTURE.md` asks for "Poisson-disk scatter ... from a deterministic
per-chunk RNG". Implemented as a global jittered grid with priority-based
suppression instead, which satisfies the intent and fixes a flaw in the letter
of it.

Running Bridson's algorithm inside each chunk spaces samples only against
others in the same chunk, so props clump along every chunk seam. Worse, the
result depends on which chunks happen to be resident, so walking away and back
regenerates a different layout, and a save that recorded "harvested node #7"
would point at a different bush.

Instead every cell of a global grid derives one candidate and one priority from
`hash(seed, cellX, cellZ)`, and a candidate survives if no higher-priority
candidate within `minDistance` exists nearby. Because acceptance compares
against a fixed neighbourhood using a deterministic priority, it is
order-independent: a cell resolves identically whether evaluated first, last,
or in a chunk loaded alone. Chunk seams stop existing as a concept, and every
point carries a stable key that `worldDeltas` can reference across sessions.

`tests/scatter.test.ts` asserts the property directly: sampling a region whole
equals sampling it in quarters, and equals sampling it on a different grid
offset.

### D18. The glTF parser is a separate on-demand chunk

There are two engine facades, not one. `src/core/babylon.ts` holds the engine
symbols; `src/core/babylonLoaders.ts` holds the glTF loader and its extensions,
and is reached only through a dynamic import inside `AssetLoader.ts`.

Measured: folding the loaders into the main facade grew the engine chunk from
1.56 MB raw / 359 KB gzipped to 2.51 MB / 566 KB. That is 207 KB gzipped of
parser on the boot path for something no milestone before M5 touches, because
`ASSETS.md` puts every real model behind M5 and everything before it is colored
primitives.

`tests/bundle.test.ts` enforces both halves: no file outside the two facades may
import `@babylonjs`, and no file may import `babylonLoaders` statically, since a
static import would quietly pull the parser back into the boot chunk.

### D17. Frame delta is clamped at 250 ms

A tab restored after five minutes in the background reports a 300 second delta.
Unclamped, the accumulator owes 18,000 fixed steps in one frame, the page
locks, the next delta is larger still, and the loop never recovers.

Clamping means a backgrounded tab resumes with a small time skip rather than a
hang. Covered by `tests/loop.test.ts`.
