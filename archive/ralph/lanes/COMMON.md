# Gate D lane — common setup and rules

Every `ralph/lanes/START_D<N>.md` assumes this file. Read your own START file
first; it tells you which parts of this matter for your region.

## 1. You are one lane of five

Gate D is the five regional Meadows packages, D1–D5, owned by prompts `62`–`66`
in `docs/ralph-prompts/`. They run **concurrently**, each in its own session on
its own branch. A coordinator session owns integration.

`ralph/GATE_D_LANE_CONTRACT.md` is the binding cross-lane contract: file
ownership, the shared files no lane may edit, the owner's density directive,
and a known defect every lane inherits. **Read it before editing anything.**

## 2. Set up before doing any work

This container has no Godot. Nothing — no test, no capture, no probe — works
until you do this:

```
cd /tmp && curl -sSL -o godot.zip \
  "https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip" \
  && unzip -o -q godot.zip \
  && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mv Godot_v4.7-stable_linux.x86_64 /usr/local/bin/godot \
  && godot --version

apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers \
  || (apt-get update && apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers)
```

`libEGL.so.1` missing breaks both Godot's renderer and Blender's EEVEE. If the
package index is stale you get 404s on `libegl-mesa0`/`mesa-vulkan-drivers`, and
a stale index aborts the WHOLE install transaction including packages that would
have worked — hence the `apt-get update` fallback. Verify with
`dpkg -l | grep libegl1` if captures keep aborting.

Then build the import cache, from the repo root:

```
godot --headless --path . --import
```

**This takes ~10 minutes and must finish first.** Without it, resources fail to
load and captures silently render flat or empty instead of erroring — which
looks exactly like a scene bug and is not one.

## 3. Running tests

```
godot --headless --path . --script tests/run_tests.gd          # full suite, ~4 min
godot --headless --path . --script tests/run_tests.gd -- --shard=1/12
godot --headless --path . --script tests/smoke_<name>.gd
```

Three things this run learned the hard way:

- **`run_tests.gd` supports `--shard=I/N` and nothing else.** `--filter=` and
  `--only=` are accepted and **silently ignored**, running all 1301 tests while
  you believe you ran one. Two lanes lost time to this.
- **Run tests in the foreground and block on them.** Four lanes stalled by
  backgrounding a test run and ending the turn to wait for it. There is nothing
  to wait for. If a tool timeout kills the command, re-run it.
- Run smoke tests headless. Under xvfb + software GL they take ~25× longer and
  flake under load.

## 4. Two known defects you inherit

**`smoke_art.gd` fails on your branch's base**, with eleven failures, and it is
not your content. Both broken checks looked for scattered props as named scene
children of the `Vegetation` node, and there have not been any since the scatter
moved onto `Terrain3DInstancer`. It is fixed on `ralph/integration-D` (per-layer
counts from `vegetation.gd::stats()`, and the LOD check asking
`registered_mesh()`). Ignore those eleven failures, or cherry-pick the fix if you
need a clean run — do not re-fix it, and do not treat it as caused by your work.

**Band clearings do not invalidate the scatter bake on your branch.**
`scatter_bake.gd::config_fingerprint()` on your base hashes only the two head
configs, not `data/config/bands/<band>/vegetation.json`, even though
`scatter_rules.gd` merges those files' `clearings`/`footprints` into placement.
So a clearing you add changes where scatter should go, the stale bake is served
anyway, and your camp stays buried in grass. Fixed on `ralph/integration-D`; the
coordinator runs the single re-bake at integration. **Add your clearings
normally and say in your report that you added them.**

## 5. Files no lane may edit

- `data/config/vegetation.json` (scatter rules, layers, `corridor_bands[].density_scale`)
- `data/config/terrain_playground.json` (heightfield, trail spine, crossings, river)
- `data/scatter/playground/**` (the baked scatter)
- `data/config/chapter_curve.json` — the authority for your band's levels.
  **Author to it; never edit it to fit content you wrote.**
- `data/config/chapter_rewards.json`, `progression.json`, and the *head*
  `spawns.json` / `trainers.json` / `harvest.json` / `props.json`

Editing the first three forces a ~60s single-threaded re-bake that cannot be run
concurrently without producing conflicting output. If your region needs more
scatter, **report a requested `density_scale`** with reasoning; the coordinator
applies all five in one edit and one bake.

Append-only, expect a trivial conflict the coordinator resolves:
`data/config/map_landmarks.json` and `data/progression/objectives.json`'s `local`.

Yours exclusively: `data/config/bands/<your band>/` whole, plus the site configs
named in your START file. New `order` values come from your band's reserved
range and **you never renumber an existing entry** — that is the mechanism that
makes five concurrent authors safe.

## 6. Hard rules content authoring tends to break

Five creatures ever, no storage, no sixth slot. The human never fights. Combat
is real-time and piloted — no shields, no dodge. **Trainer-owned creatures
cannot be caught**, so a catchable special encounter must be a wild. No hunting
or butchering; food buffs and there is no starvation death.

**No new creature meshes and no Meshy generations**, and never any generation
without owner-supplied reference art. Differentiate with materials, textures,
modest scale, animation, VFX, habitat, behaviour, traits and encounter context.

**Reuse the six installed humanoid rigs** — trainer, Grandpa, Warden, villager
male, villager female, Team Tether grunt. `docs/art/HUMANOID_ASSET_INVENTORY.md`
is authoritative; rank presentation lives in `data/config/npc_ranks.json`. A new
named trainer is a per-material variant, never a new mesh.

One nature family, one village family, one prop family. **No Biome 2** — a
distant view across a seam is allowed, a place you can walk into is not.

**Do not author a wild Tuskroot.** It is Mudsnout's evolved form behind the
Heartstone bond gate, and `test_no_evolved_form_spawns_wild` will refuse it. One
lane lost work to this.

## 7. Do not silently invent

Siting a picket, a camp, a herd, a gatherable, a detour built from existing
systems is ordinary work. A new named character with real story weight, a new
mechanic, a change to the cap, the type system or the evolution rules is not —
flag it per `CLAUDE.md`'s "Ask instead of inventing" list and author around it.
Do not stop working while you wait; deliver everything that does not depend on
the answer.

## 8. Visual work

Anything visually load-bearing needs the blind pass in `ralph/conventions.md`:
render real frames, have an **independent critic** judge them, fix the named
defects, re-render, re-judge. Iterate while it is still improving; stop after
two consecutive rounds that name no new defect and move no measured axis, and
record the round count and what the last two rounds failed to move.

**Do not grade your own frames.** Two lanes did, and both produced verdicts that
an independent critic then contradicted in the parts that mattered. Produce the
captures, then ask the coordinator to dispatch the critic.

## 9. Ship protocol

Commit early and often. Push only your own `ralph/gate-d-band<N>-*` branch:

```
git push -u origin ralph/gate-d-band<N>-<slug>
```

Retry network failures up to 4 times with exponential backoff (2s, 4s, 8s, 16s).

**Never push to `main`. Never open a pull request. Never dispatch
`ralph-merge.yml` or `ralph-sweep.yml`** — integration is the coordinator's job,
and pushing is not shipping: both workflows are `workflow_dispatch` only, so
nothing lands on `main` by itself.

`ralph/DONE.md` has a single insertion point right after its header and is a
known concurrent-rebase conflict. Keep your entry small and expect to resolve
it; keep both `##` entries, yours after the one already there.

## 10. What every lane owes

1. `python3 tools/_probe_chapter_map.py` before and after, both in your report.
2. The data tests your change touches, green, plus the full suite before you push.
3. **A real driven run through your region**, not only unit tests — the smoke
   test that covers it, or a purpose-built probe under `tools/` following the
   existing `_probe_*.gd` pattern. Record encounter cadence, the longest
   dead-travel interval **in metres**, and whether the region's objective is
   legible while playing it.
4. The blind visual pass, per §8.
5. A written record in the repo, in the voice the codebase already uses:
   explain *why*, name the failure it prevents, be honest about what is not
   built. Plus a `ralph/DONE.md` entry.

Report honestly. A half-finished pass reported accurately is useful. A green
claim that is not true is not — and on this project it has cost real hours.
