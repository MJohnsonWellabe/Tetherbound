You are the Tetherbound REPO-SLIM lane (4 Nov 2026). Your branch: tb/repo-slim-1104. Create it from origin/main, work and push only there. Lane folder: ralph/reports/LANES/REPO-SLIM/.

Read CLAUDE.md first; it is binding. The coordinator is session session_01CfKRDSan7LUFmNAx6VWNUy. It lands your work in a PR with full-ci; never push to main.

The problem: every CI engine job checks out about 7.1 GB, 16,842 files, because of the sparse checkout in .github/workflows/ci.yml. Most of it is:
- assets/creatures/tetherbound: 2.9 GB
- assets/props/meshy-1020, -1024, -1031, -1022 and -1101: about 2.2 GB
- assets/props/crossing_hall_hero and others

On 3 Nov, checkouts took 20–60 minutes and one runner ran out of disk.

OWNER (4 Nov 2026, verbatim): "Don't get rid of meshy models but you could move them off main or something."

Task: move Meshy and generated asset files that the shipped game does not reference off main, onto an archive branch, without losing a single file.
1. **Build a reference graph.** Start from every res:// path reachable from: project.godot, every .tscn/.tres/.gd under scripts/ scenes/ autoload/ addons/ tools/ tests/, and every data/ file (including flag-OFF candidate entries in data/config: those count as referenced; keep them). Follow .import, .glb and .tscn dependencies, so an extracted texture referenced by a referenced .glb counts as referenced. Also treat as referenced anything a CI step, a test or a capture tool loads by building a path string, and grep for those patterns.
2. **Classify every file** under assets/creatures/tetherbound and assets/props/meshy-*, crossing_hall_hero, generated_camp and realm_gate_meshy, plus any other large asset folders you find (list the top 30 by size). Each file is REFERENCED or UNREFERENCED. Write a manifest JSON with path, size, class and why, and commit it under the lane folder.
3. **Archive.** Create the branch tb/meshy-archive from origin/main as it stands; it keeps everything. On tb/repo-slim-1104, git rm ONLY the UNREFERENCED files, and add assets/ARCHIVED_ASSETS.md. That file names the archive branch and commit, explains how to restore one file (`git checkout tb/meshy-archive -- <path>`), and links the manifest. Never touch provenance.json, references, or Blender sources that the art rules require. If a provenance record names an archived asset, keep the record and note "archived" in it.
4. **Prove it.**
   - `godot --headless --path . --import` is clean.
   - The touched and representative tests pass: test_texture_import_policy, creature remake flag tests, hero landmark tests, and a creature-stage capture smoke.
   - The new sparse-checkout size, computed from the tree with ci.yml's patterns, is recorded in READY.md.
   - Spot-check five archived files with a grep showing zero references.
5. **Report the measurement.** Record before and after checkout sizes in READY.md.

If something is ambiguous, keep it on main. A smaller saving with zero risk beats a bigger one that breaks a scene. Do not rewrite history.

Setup:
1. Get the full working tree. It is about 7 GB, so mind your disk.
2. Use Godot 4.7 headless, at /usr/local/bin/godot or by installing 4.7-stable.

Cadence:
- Push hourly.
- When ready, message the coordinator: send_message to session_01CfKRDSan7LUFmNAx6VWNUy with the commit and the sizes.
- Never sit idle. Arm send_later 20–30 minutes out before ending any turn.
