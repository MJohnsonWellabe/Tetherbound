# D11 — The art pipeline is committed scripts, not MCP servers

**Status:** accepted
**Found during:** setting up `TETHERBOUND_3D_ART_PIPELINE.md`

## The decision

`TETHERBOUND_3D_ART_PIPELINE.md` §3.2 names Meshy's MCP server as the preferred
generator interface, and Tier B asks for one of three Blender MCP bridges to be
installed and chosen between.

Neither is used. The pipeline is **plain scripts in `tools/art_pipeline/`**,
driving Blender through `--background --python` and Meshy through its REST API.

## Why

**1. An MCP server cannot be added to a session that is already running.** The
tool list is fixed when a session starts. Every hour of art work would begin
with a restart, and any agent that discovered mid-task that it needed Blender
would have to stop.

**2. This project is built in ephemeral containers.** The machine is reclaimed
after a period of inactivity and the repository is re-cloned on the next start.
An MCP configuration lives in the session; a script lives in Git. The thing that
survives is the thing worth writing.

**3. The REST API is the same API.** Meshy's MCP server is a wrapper over the
HTTP endpoints. Calling them directly costs a `requests` call and buys exact
control over polling, retries, cost accounting and where files land.

**4. `blender --background --python` does the whole §11 cleanup pass.** Topology
inspection, normals, UVs, remesh, material edits, armature checks, rendering and
GLB export are all `bpy`. The MCP bridges add an agent-facing conversation layer
over that, which is worth something interactively and nothing in a batch.

**5. §24 asks for the security review a bridge would need anyway.** All three
candidate bridges execute arbitrary local code on request. Reviewing one, pinning
it and documenting the choice is real work, and it buys a capability we do not
need.

## What is given up

Interactive Blender. An agent cannot look at a viewport, nudge a vertex and look
again; it writes a script, runs it, and looks at a render. For the operations
this pipeline actually performs — inspect, measure, remesh, retopologise,
re-material, render, export — that is a fair trade, and every step leaves a
re-runnable artefact behind.

If a later stage genuinely needs interactive sculpting, that is the owner in
Blender on the Windows machine, not an agent through a bridge.

## What this looks like in the repo

```
tools/art_pipeline/
  setup.sh              fetch portable Blender + Godot, no root, nothing committed
  crop_views.py         reference sheets -> clean multi-view generator inputs
  compare_sheet.py      candidate renders beside concept art, plus the §9 scorecard
  views.json            where the turnaround sits on each sheet
  blender/
    inspect_glb.py      the §11 checklist, as JSON
    turntable.py        the §9 fixed-camera comparison renders
tools/
  validate_asset.gd     the §15/§16 in-engine review, at four gameplay distances
```

Tool binaries live in `~/.cache/tetherbound-art/`, are never committed, and are
re-fetched by `setup.sh` on a fresh machine.

## Versions, pinned

- **Blender 4.2.9 LTS.** A pipeline that silently changes Blender version
  produces different geometry from the same inputs.
- **Godot 4.7-stable**, matching `.github/workflows/ci.yml` and D01. Validation
  renders only mean something if they come from the engine the game ships on.

## Consequence for §30

§30 asks for the successful process to become a reusable skill once Terrapup
passes. That skill will describe running these scripts. It is a better artefact
for it: a skill that says "run `crop_views.py`" is checkable, and one that says
"ask the Blender MCP to clean up the mesh" is not.
