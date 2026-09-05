# N12-REPO-HYGIENE

**Source:** flagged independently by at least six lanes today (W03, W07, W12, W17, W18, W20)
— all found the same class of gap and correctly left it since it crosses ownership.

## Why
Several assets and scripts landed on `main` today without the sidecar files Godot's importer
generates for them, and the repo's own convention (904 `.import` files, 969+ `.gd.uid` files
already tracked) says these should be committed. Every lane that runs `godot --import` keeps
regenerating the same ~50-60 files and seeing a dirty tree, which wastes time and obscures
real diffs.

## Owns
Only `.import` sidecar files, `.gd.uid` files, and Godot-extracted texture files (`.png`/`.jpg`
sitting beside an already-committed `.glb` of the same name) — nothing else. Do not touch any
source `.gd`, `.glb`, `.json`, or scene file.

## Do
1. `git fetch origin main && git checkout -B ralph/N12-REPO-HYGIENE-0905 origin/main`.
2. Run `godot --headless --path . --import` on a completely fresh checkout (delete any local
   `.godot/` cache first to force full regeneration) and capture `git status --short` — this
   lists every untracked artefact the current tree is missing.
3. For each untracked file, confirm it is genuinely a deterministic import artefact (its
   source asset is already tracked on `main`) before committing — do not commit anything that
   looks like new content rather than a regenerated sidecar.
4. Specifically expected, per today's lane reports: `.import` sidecars and extracted textures
   for `assets/props/candy_pickup/`, `assets/props/mushroom_pickup/`, `assets/props/potion_plant/`,
   `assets/props/revive_flower/`, `assets/props/riding_saddle/`,
   `assets/environment/team_tether/south_bridge_gate_0.jpg`, and `.gd.uid` files for test/tool
   scripts added by today's lanes that didn't commit their own sidecar.
5. Commit all of them in one commit with a clear message (e.g. "chore: commit missing import
   sidecars for pickup/saddle/bridge assets and today's new scripts").
6. Re-run the same `godot --import` on the result and confirm `git status --short` now comes
   back clean (or only shows a genuinely new gap, which you should investigate rather than
   commit blindly).

## Verify
- `git status --short` is clean after a fresh import on the final commit.
- No source file (`.gd`, `.glb`, `.json`, scene) appears in your diff — only sidecar/derived
  artefacts.
- Run the full test suite once to confirm nothing regressed (this should be a no-op change to
  game behaviour by construction, but verify rather than assume).

## Acceptance
A fresh `godot --import` on your branch produces zero untracked files. The diff contains only
`.import`, `.uid`, and importer-extracted texture files — nothing else.
