# Handoff — 2026-08-16: playtest round 3, all of Phase 8, and the three hero assets

**Everything below is on `main` at `5458d520`.** Written as an exit document for
a fresh context. Read `CLAUDE.md` first, then `docs/HANDOFF.md` for the older
standing state; this file covers one long session and supersedes that file
wherever they disagree about the Meadows chapter, the hero assets or the Warden.

---

## 1. The headline

**The Meadows chapter is content-complete.** Bands 0–5, the stronghold, the
Warden, the reveal, freeing the legendary, the Rift collapse, the world
answering afterwards, the legendary ride and the mystery hook are all built and
on `main`. All three of `D24`'s reserved Meshy hero objects now exist. The
Warden has been rebuilt from the owner's own character sheet and his face is
modelled rather than painted.

**953 unit tests, 0 failed.** `smoke_art`, `smoke_boss`, `smoke_stronghold`,
`smoke_relay_station`, `smoke_riding`, `smoke_warrens`, `smoke_trainer_battle`
all green locally.

**CI on `5458d520` was still pending when this was written.** Check it before
trusting the build — and read §5 first, because CI silently stopped running for
five hours today and the failure mode is easy to misread.

---

## 2. What shipped

**Owner playtest round 3 (`OF20`–`OF33`, Phase -1.3).** Gathering was broken at
the root — `harvest_node.gd` loaded a `.gltf` (a PackedScene) into
`MeshInstance3D.mesh`, so all twelve authored nodes were invisible and fibre and
berries were unobtainable. Also: the potion picker, the build menu, a carried
torch you can actually see, the real keyboard for naming, debug teleport, TMs as
inventory items, the blacksmith and merchant, creature trading, revives, and the
shiny system.

**Shinies are repaints, not tints** (owner's words: *"if our newt is blue, I
want red. not blue with a red shade over it"*). `tools/repaint_creature_textures.py`
remaps HSV *regions* per species into `*_shiny.png` and `*_vivid.png` siblings;
17 species have both. The trap that ate a day: these assets ship
`emission_enabled` with the albedo bound as emission, so an albedo-only tint is
invisible — swap **both**.

**Phase 8 in full** — 8a trainers and the South Bridge, 8b the Old Quarry, the
Burrow Warrens and the Rootstone tier, 8c the river, the mill and the Tether
Relay Station, 8d riding, Ironwood and the three captains, 8e the stronghold
route, the gauntlet, the Warden, the reveal, the legendary and the world event.

**`SH47` pacing.** See §3 — it is the item most likely to need your judgement.

---

## 3. `SH47`: the numbers, and the one thing only the owner can settle

`tools/_probe_pacing.py` walks the shipped critical path and prices it.

| | before | after |
|---|---|---|
| floor | 6.22 h | **1.51 h** |
| projected first completion | 12.45 h | **3.02 h** |
| forced wild grinding | 4.76 h / 381 fights | **0.07 h / 6 fights** |

The overshoot *was* the grind. Four data levers, all documented in place beside
the numbers they changed: the XP curve (exponent 1.6 → 1.15 — at 1.6 a level
cost 33 level-matched fights by L19 and the chapter does not contain them), the
stronghold gauntlet (21/22/22 → 18/19/19 — **the elite out-levelled the Warden
it guarded**), the Burrow Warrens (guardian 18 → 14 against a Band 1 gate that
fields level 7), and a second Meadowhart cluster on a route the player already
walks (the only rideable creature lived a 624 m round trip off every path).

Six assertions in `tests/test_trainers_data.gd` fail the build if this
regresses.

**The honest limit: 3.02 h sits at the bottom of the 3–4 h band, and the
projection is a model (`floor × 2.0`), not a stopwatch.** `SH47`'s own done-when
asks for a timed end-to-end run. Every remaining minute is content rather than
grind, so the levers left would mean cutting content, which `D42` forbids. **This
needs the owner to play it.**

---

## 4. The three hero assets, and the rule that shaped them

All of `D24`'s reserved generations are spent: the Tether Energy Pylon (`SF33`,
earlier), the Relay Apparatus (`SE23`) and the Legendary Tether Machine
(`R8.2`). `D49` carries the method and the dead ends.

**The load-bearing lesson, and it generalises: image-to-3D follows its pictures
far more than its words.** Board 15 draws the machine *with a bound legendary in
the cage*, and `D24` licenses the machine alone. A negative prompt was written
and is *not* sufficient insurance. The occupant is removed from the **input
images** instead —
`tools/art_pipeline/crop_prop_views.py::lift_occupant` colour-keys it out of the
cage interior and morphologically closes the speckle, leaving the rings and
clamp arms intact. Every candidate was checked by eye; none contains a creature.

The same lesson bit twice more: the machine's first attempt used only the two
creature-free views (rear + one orthographic plan) and returned shattered
spires — one elevation plus a plan is not enough to reconstruct from. And the
Warden's head came back as three whole standing figures because the crops still
included shoulders, with "HEAD AND NECK ONLY" in capitals losing to four
pictures containing a fur mantle. **If the image must not show it, crop it out
rather than ask for it to be ignored.**

### Bugs found only because a seam was finally used

Every one of these lived in a branch that could not run until the placeholder
stopped being watched:

1. `stronghold.gd::_build_machine` returned early on the model path, skipping
   the base collider, the core light and `_markers["machine"]` — a 15 m machine
   you walk through, in an unlit chamber, with the marker `R8.4` reads its
   position from simply absent.
2. Neither seam scaled anything. A Meshy GLB arrives in the generator's units
   (the machine's raw export is 1.7 m tall). Both seams now fit to the authored
   height by the mesh's own visual bounds.
3. `smoke_stronghold::_aabb_of` was scale-blind — it read `mesh.mesh.get_aabb()`
   and only translated it, so it measured the correctly-sized 15 m machine at
   1.7 m and **failed the build over honest work**.

---

## 5. CI stopped running for five hours, and it looked like ordinary failure

**Read this before trusting any green tick from today.**

Two jobs — `verify-riding` and `verify-relay` — were left as bare job headers
with no `steps:` when this session merged parallel agents' work. A job with no
steps is not a failing job, it is an **invalid workflow**: GitHub rejects the
file before scheduling anything, so the run completes as `failure` in zero
seconds with **zero jobs**. In every UI that only counts red, that is
indistinguishable from a normal failure.

Nothing was verified between `fa178efb` (07:09Z) and the fix — including four
commits reported as green at the time. The last genuinely-executing run before
the fix was `deabf014` at 06:40Z.

**The tell is `total_jobs: 0` on a run that completed in zero seconds.** Worth a
guard if anyone wants to write one.

Once running again it immediately earned its keep, catching a real `SH47`
regression (`smoke_warrens` asserted a hard-coded `level < 15` against a
retuned guardian) and an intermittent riding failure (a wild creature roaming
out of interact range between teleport and keypress).

---

## 6. The Warden, rebuilt

The owner supplied `docs/art/reference/16_Warden_Aldis_Character.png` mid-session.
**It supersedes board 06 for this character**: board 06 draws a masked soldier
behind a visor and a nose-and-mouth plate; board 16 draws a bare bearded face
with a green marking *painted* across the eyes, level with the skin. The prompts
in `meshy.py` were tuned hard against 06 — they demanded the mask as raised
geometry in capitals — and are rewritten.

Body generated from board 16's own front/back turnaround; head generated
separately from its four head views and grafted on; textured, auto-rigged at
1.85 m, animated with the five clips `data/config/art.json` already asked for.
**His face is modelled now**, which was the entire point.

Body candidate `b` won on one specific thing worth remembering: `NEGATIVE_HUMAN`
bans `staff`, the board draws him holding one, and `b` is the candidate where
the ban took. That ban is deliberate and is the **opposite** of the
`DROP_FOR_SPECIES` case — there a shared negative fought a creature's own
signature; here it removes an accessory the game has no use for.

### Recipe, if he is ever rebuilt

```
graft_head.py   --head-fraction 0.18 --overlap 0.15 --drop 0.45
cleanup_mesh.py --target-tris 30000 --skip-voxel
meshy.py texture warden <mesh> --style-from warden_body --resolution 2k
meshy.py rig <textured> --height 1.85
animate_humanoid.py
```

Two flags were added for him, each earned by a defect that was **rendered and
looked at** rather than reasoned about:

- **`cleanup_mesh.py --skip-voxel`.** The voxel remesh turned his coat, cape and
  mantle into lace at every voxel size tried, and *finer voxels made it worse* —
  which is what finally pinned it on the remesh rather than on thin walls.
  Rendering the intermediate settled it: the graft is perfect, the remesh is
  holed. That remesh exists to weld loose parts for **Blender's bone-heat
  weighting**, and humanoids here do not use bone heat — they go to Meshy's
  auto-rigger, which takes loose parts happily. All cost, no benefit, for this
  kind.
- **`graft_head.py --drop`.** The first install had a neck the owner called
  *"comically long"*. Neither existing lever shortens it: `--overlap` moves the
  CUT, so raising it keeps **more** neck, and negative values lift the head clean
  off the shoulders. `--drop` sinks the placed head into the collar. **0.45
  head-heights** put his jaw on the fur.

Two routes that did **not** work, kept so nobody repeats them: retexturing the
shipped body against board 16 (colour drained, gold trim gone, face no better),
and grafting onto the shipped rigged body (its thin-walled cape does not survive
any remesh).

---

## 7. Tools added this session

| Tool | What it is for |
|---|---|
| `tools/art_pipeline/crop_prop_views.py` + `prop_views.json` | The object-board sibling of `crop_views.py`. Explicit per-view boxes, because prop and character boards are not laid out as a creature turnaround row. Also carries `lift_occupant`. |
| `tools/capture_hero_asset.gd` | Renders an installed asset through **the game's own renderer** in seconds. Not a replacement for the Blender turntable (that is the candidate-judging tool); it answers what the asset looks like under `gl_compatibility`, which is where the pylon's emission bug hid. |
| `tools/_probe_pacing.py` | Walks the shipped critical path and prices it. Re-run after any tuning. |
| `tools/capture_rift_before_after.gd` | Committed **unrun** — booting the full world under software GL exceeds every timeout on this box. Reason is in its header. |

---

## 8. What is outstanding

**Needs the owner, not an agent:**

- **Does the chapter feel like 3–4 hours?** `SH47`'s done-when is a timed run.
  See §3 — 3.02 h is a model, at the bottom of the band.
- **`OF15`** — stuck-geometry locations, which only come from a playthrough.

**Known limits, recorded honestly and not hidden:**

- `SG44`'s visual judge — the tool is committed but has never rendered here.
- The quarry's baked drained ground cannot heal at runtime (`D45`); the Quarry
  Foreman says so out loud rather than the game pretending otherwise.
- The Warrens guardian respawns on the ordinary wild timer.
- `OF18` website screenshots.

**Environment gotchas for the next session:**

- **Blender is not in the container image.** It was installed ad hoc
  (`apt-get update && apt-get install -y --no-install-recommends blender`, then
  `pip install --break-system-packages numpy` for the system Python Blender
  uses). Any further character work needs it again.
- **`MESHY_API_KEY` is not in the environment.** It lives in the Ralph art-lane
  Routine's stored prompt (`ralph/KEYED_PROMPT.md` documents that this is by
  design — a committed key would be revoked by secret scanning). ~620 credits
  were spent today; balance ~4,100.
- **No further Meshy generation is licensed for the Meadows.** All three hero
  objects are done, `D23` §20 forbids creature meshes at any balance, and
  `CLAUDE.md` forbids generating anything without an owner-supplied board.

**Ralph:** paused all session. Every `ralph-status` lease this session held has
been released; `ralph/STATUS.md` has zero live blocks.

---

## 9. Decisions minted or corrected today

`D41` (the stations drain the land), `D42` (3–4 hours; terrain explicitly
carved out), `D43`, `D44`, `D45` (drained-ground grammar), `D46` (the river),
`D47` (elixirs), `D48` (riding), **`D49`** (the machine without its prisoner,
plus the Warden rebuild).

`D45`/`D46` had each been minted **twice** by parallel agents on the same day.
First to land keeps the number; elixirs became `D47` and riding `D48`, with
every inbound reference retargeted by topic.
