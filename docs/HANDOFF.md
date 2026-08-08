# Tetherbound — where the project actually is

Written as a handoff: everything a fresh context needs to pick this up without
re-deriving it. Read `CLAUDE.md` first for the hard rules, then this.

**Last updated:** end of the session that produced the humanoids, recanonised
the wild roster, and built the menus, settings and opening sequence.

---

## 1. What the game is

A Godot 4 third-person survival/crafting creature-training game. Windows and
the ROG Ally, controller-first, solo. You own **five pals, ever** — no storage,
no boxes. Combat is real-time and **piloted**: you play as your creature while
your trainer stands behind it. The human never fights.

The current target is the **Meadows vertical slice**. Nothing from Biome 2
starts until Meadows passes its exit gate.

---

## 2. The Meadows roster — every creature and what it is

Canon lives in `docs/art/wild/` (owner-supplied pack) with production sheets in
`docs/art/reference/wild/`. **That pack wins over any older board or note.**
See `docs/decisions/D13`.

### The three starters — DONE, in the game

| # | Name | Type | Height | What it is |
|---|---|---|---|---|
| 1 | **Terrapup** | Ground | 1.70 m | Badger/canine cub. Warm brown fur, cream face stripe, **grey stone mantle plates over shoulders and back**, oversized digging paws, teal eyes. The quality benchmark — the only creature that passed its blind review outright. |
| 2 | **Ripplet** | Water | 1.60 m | Otter/newt. Turquoise skin, cream belly, translucent ear frills with pink inner membrane, broad fan tail fin. |
| 3 | **Galewisp** | Air | 1.55 m | Fox-bird glider. Cream down over layered blue/teal feathers, **enormous feathered ear tufts**, wing-membrane forelimbs. |

### The twelve wild species + one evolution

Only **one** creature evolves in this biome: **Mudsnout → Tuskroot**.

| # | Name | Type | Height | What it is | Status |
|---|---|---|---|---|---|
| 4 | **Bramblebun** | Ground | 1.35 m | Meadow rabbit. Long upright ears with pink inner cup, powerful hind legs, **living moss and purple meadow flowers growing along its back**. The tutorial creature — highest catch rate in the game so the first catch cannot fail twice. | **DONE** |
| 5 | **Mudsnout** | Ground | 1.40 m | Rooting piglet runt. Broad pink snout, small emerging tusks, bristly coat caked with soil. Young and round — **not armoured**. Pre-evolution of Tuskroot. | **DONE** |
| 6 | **Trailpup** | Ground | 1.55 m | Lean prairie canine, coyote-like. Sandy tan, cream underside, large upright ears, bushy dark-tipped tail. **No stone plates** — the mantle is Terrapup's, and these two must not be confused. | **DONE** |
| 7 | **Meadowhart** | Ground | ~1.95 m | Rideable meadow deer **with a leaf-and-leather saddle**. Tan hide, cream spots, modest antlers. Must NOT read as the legendary — lighter, friendlier, practical, not sacred. | in progress |
| 8 | **Burrowback** | Ground | ~1.70 m | Broad low badger. Black-and-white striped face, **enormous shovel claws**, loose rock nodules in clusters over the back — never one continuous shell. | in progress |
| 9 | **Paddlenewt** | Water | ~1.50 m | Small amphibious newt. **Translucent orange fin frills** from the head and down the spine, huge golden-orange eyes, teal spotted skin, webbed toes. | in progress |
| 10 | **Mosshell** | Water | ~1.62 m | Pond turtle. Broad domed shell of **mossy grey stone plates** with a cream rim, teal-green skin, very low centre of gravity. | in progress |
| 11 | **Brooktail** | Water | ~1.45 m | River otter. Sleek body, **broad flat scaled paddle tail**, webbed feet, chocolate fur with cream muzzle, blue eyes. | in progress |
| 12 | **Reedwing** | Water/Air | ~1.65 m | Waterfowl. Orange bill and webbed feet, teal and blue-grey layered flight feathers over a cream breast. Must read as at home on water **and** in the air. `species.json` takes one type — filed as `water`. | in progress |
| 13 | **Pipwing** | Air | ~1.20 m | Tiny round songbird. **Oversized teal eyes** taking up most of the face, small crest, slate-blue wings, cream chest. Smallest in the roster. | in progress |
| 14 | **Duskhush** | Air | ~1.55 m | Owl. Broad silent wings, **pronounced ear tufts**, large gold-ringed eyes in a pale facial disc. Serene, not spooky — no glowing eyes. | in progress |
| 15 | **Galecrest** | Air | ~2.00 m | Large hawk. **Enormous broad wings**, hooked beak, heavy talons, slate-blue and tan over a cream chest. A serious predator — must NOT read as Galewisp, the cute fox-eared glider. | in progress |
| 16 | **Tuskroot** | Ground | 2.00 m | Armoured boar, **evolved from Mudsnout**. Long curved ivory tusks, thick stone plates over shoulders and back, moss in the seams. Must read as Mudsnout grown up. | **STAND-IN — still `ollie-the-songbird.glb`** |

### The named characters

| Name | Status | Notes |
|---|---|---|
| **The trainer** (player) | DONE | Sheet 04. Teal jacket, cream shirt, green scarf, belt orb-holder, backpack. Body and head generated separately and grafted. |
| **Grandpa Elias** | DONE | Retired explorer. Green vest, cream rolled sleeves, white beard. Wired as an NPC in the opening. |
| **Warden of the Meadows** | DONE-ish | Biome boss. Green officer's greatcoat, cream fur ruff, **long cream cape**. **His face is painted, not modelled** — see §6. |
| **Veridian Stag** | DONE, but failed its gate | Ground legendary, 2.60 m. Leafy antlers, bark body with golden veins. See §6. |

**Deliberately NOT built: Sparkit**, an Electric fox kit the owner likes. The
Meadows has three types only — Ground, Water, Air. Recorded in
`docs/art/REFERENCE_CANON.md` as a future-biome candidate.

### Scale rule (D12) — do not "fix" this

Pals stand as **peers to the 1.8 m trainer**, 1.20–2.60 m. The concept sheets'
centimetre figures (a 0.45 m Terrapup) are the creature's *biology* and stay
true on the page; game scale is a separate question the owner has answered
twice. A blind reviewer will call this a 3–4× scale error — it is not.

---

## 3. What is built and working

- Movement, camera, sprint, jump, stamina, fall damage; terrain and vegetation.
- Wild pals that roam, notice you and can be aggressive.
- **Piloted combat** (D07) and **aimed orb catching** (D08) — the most complete
  systems in the project, both CI-tested.
- **Pause menu**: backpack, pals, build tabs; controller-navigable.
- **Settings**: full control remapping, persisted to `user://settings.json`.
- **Free-build toggle** (Settings → Gameplay), off by default. Everything must
  go through `GameState.build_cost_for(id)`; it returns empty while on.
- **`GameState` autoload** — the project's one singleton: party (max five),
  satchel, day counter.
- **Opening beats 1–6**: interact prompts with nearest-wins arbitration,
  dialogue, Grandpa as an NPC, pal naming, a following pal, starter choice.
- 247 unit tests. Smoke tests per feature. CI exports a Windows build and
  publishes it on every push to `main`.

---

## 4. What is NOT built

- **Gathering, camp building, sleep** — the rest of the first day.
- **The sequence director** that gates and advances the beats.
- **Placement** for buildables. The Build tab records intent; nothing is spent.
- **Save/load. There is not one write to `user://` outside settings.** The
  design locks 3–5 slots and frequent autosave; none of it exists.
- **The release ceremony** (M5). `party.add()` refuses a sixth pal; there is no
  ritual. The slice warns it must not be "a generic delete dialog".
- **Evolution.** `mudsnout → tuskroot` is recorded as data; no mechanic.
- **Riding**, weather, tools/durability, food buffs.

---

## 5. The open work, in priority order

1. **Finish the roster** — 9 species to build, Tuskroot to replace.
2. **Fix creature grading, then recolour** (§6). Highest leverage: it is a
   pipeline fix that every remaining creature benefits from.
3. **Finish the first day** — gathering, camp, sleep, director.
4. **Rework orb aiming** — trajectory preview, aim cone, catch sequence.
5. **Combat animation bug** (§6) — unexplained, owner-reported.
6. **Save/load** — the next structural gap after the above.

---

## 6. Known defects, honestly

**Creature grading is broken and it is self-inflicted.** Every creature is one
mesh, one material, one 2048² albedo — eyes are painted pixels. Terrapup's
grade guards its eye region; Ripplet's and Galewisp's do not, and their bodies
are the same hue as their eyes, so 80% and 33% of their textures get blended
toward one flat colour. The iris ring and catchlight are averaged away. A blind
reviewer called the result "a black almond with a smeared crescent". Separately
`ROUGHNESS_FLOOR` flattens the entire roughness map, there is no albedo
ceiling (46% and 54% of those two clip to white in engine), and **Ripplet is
self-illuminated** — every model ships `emissiveFactor = [1,1,1]` and its
emissive map is graded as if it were albedo.

**The Veridian Stag failed its blind gate.** Off-style (0.66–0.73 saturation
against the starters' 0.12–0.51, plus black linework nothing else has),
hue-camouflaged against its own biome (36° from the grass, everything else
50–100°), and faceless. Rebuild it against a written spec rather than patch it.

**The Warden's face is painted, not modelled.** The head-graft technique that
gave the trainer and Grandpa faces failed on him: board 06 yields only a
~165 px head crop, and both head candidates came back as unreadable lumps.
**He needs a proper 01–04-quality reference sheet before he can be finished.**

**Pals are "static posed and sliding around" in combat.** Owner-reported,
**unexplained**. Ruled out by measurement: clips exist and drive real bone
motion; the animator is ticked every physics frame with real velocity; loops
are set at runtime. Best remaining lead: Terrapup's idle moves bones by 0.088
against 1.53 for walk, and a creature in combat is in idle almost always — an
idle that subtle is indistinguishable from a freeze. Next step is a recorded
fight logging the clip playing against the body's speed, not more reasoning.

**`smoke_traversal` is intermittent.** Same commit passes and fails. Every
failure has the player at `y = -0.4 m` — never falling through — so the old
message ("the ground is not continuous") was misdiagnosing. It now reports
where the run began and whether height was lost, and asserts on sinking below
the terrain surface. Still flaky. Related lead: `smoke_menu` was reported
failing with "the player moved while the menu was open" — **unverified**, and
the agent's explanation (missing Terrain3D addon) is wrong, since those
binaries are tracked and do reach worktrees.

**Trainer backpack** is undersized against sheet 04 and its hood geometry is
ragged. Deferred: a volume edit on a textured mesh costs a retexture.

---

## 7. Corrections — things previously asserted that are false

Recorded because they were written into commit messages and reports:

- **There is no stray Icosphere in any model.** Five reports claimed every
  shipped GLB carried a 42-vertex sphere. The GLB's JSON chunk lists one mesh;
  the sphere is invented by *Blender's glTF importer* on read. Real
  consequences while believed: `inspect_glb.py` measured creature heights as
  ~1.5× too tall, and a reviewer's "detached geometry floating free" was real
  **in the render** (`turntable.py` renders the Blender scene). Both fixed at
  source. `strip_strays.py` is now a container check, not a repair.
- **"10 species left" was wrong; it was 13.** That count treated a row in
  `species.json` as meaning art exists. Bramblebun was a duck and Tuskroot is
  still a songbird.
- **The traversal failure was called a flake from one run, then "isolated" to
  one file from one run per side.** Both conclusions were unfounded.

---

## 8. How the work is being done

**Parallel agents in isolated git worktrees**, each with an explicit
must-not-touch list, merged into `main` as they land. Branches are
`worktree-agent-*`; nothing is lost when an agent dies, because each commits
to its own branch.

The boundaries that matter:
- **One agent owns the grade scripts.** Roster agents must not create or modify
  `grade_*.py`; they use the shared `grade.py` if it exists or install ungraded
  and say so.
- `rig_bird.py` did not exist and both the Water (Reedwing) and Air agents need
  it. First to write it wins; it must be general enough for a duck.
- Creature agents cannot touch `scripts/**`; gameplay agents cannot touch
  `assets/pals/**` or `tools/**`.

**Godot's import cache does not travel between worktrees.** After merging any
branch that adds art, run an editor import pass, then `git checkout
project.godot` — that pass strips the file's documentation comments.

---

## 9. The art pipeline

`tools/art_pipeline/`. Governed by `docs/art/TETHERBOUND_3D_ART_PIPELINE.md`.

The loop, proven on nine characters: **crop the sheet → 3 cheap candidates →
blind critique → mesh fix → cleanup/remesh → retexture against the concept →
rig → procedural clips → grade → install → in-engine validate → blind gate.**

**The blind critique is the mechanism, not a formality.** A fresh subagent gets
only the renders and the concept art and is told nothing about what changed. It
has caught a real defect on every creature, and repeatedly caught bugs in the
tooling itself — a validation scene inventing its own lighting, contaminated
crops, unjudgeable renders, and the phantom sphere.

Two hard-won rules: **state the signature feature in capitals and first**, or
the generator drops it; and **generate heads separately** — a whole-figure pass
at 30k polys cannot resolve an eye socket, which is why nine humanoid
candidates came back faceless.

Meshy credits: **~1075** at last check. Preview 20/candidate, retexture 30, so
roughly 90 per species. The key lives in `MESHY_API_KEY` and **must never be
written to any file**.

---

## 10. Testing and shipping

- `godot --headless --path . --script tests/run_tests.gd` — 247 unit tests.
- `tests/smoke_*.gd` — one per feature, boots the real scene, injects input.
- **UI focus navigation cannot be tested with `Input.action_press`** — it needs
  `Input.parse_input_event`. A poll-only test reports a working menu while the
  stick moves nothing.
- **Run `smoke_traversal` headless.** Under xvfb + software GL it takes 25×
  longer and flakes under CPU load.
- Every push to `main` builds a Windows `.exe` and publishes it. The download
  link is `/releases/download/latest/Tetherbound-windows.zip` — **by tag**. The
  `/releases/latest/download/` form 404s because the release is a prerelease.
