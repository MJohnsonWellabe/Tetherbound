# Archived assets

Owner, 4 Nov 2026: "Don't get rid of meshy models but you could move them off main or something."

116 Meshy and generated asset files (0.93 GB) that nothing in the shipped game, CI, tests or capture tools loads were removed from `main`. **Nothing was deleted from history.** Every file is still on:

- branch **`tb/meshy-archive`**, commit `98879e2e13da4e310811e92f7cb1c62a424590a0` (main as it stood on 4 Nov 2026), and
- every earlier commit of `main`.

## Restore one file

```
git fetch origin tb/meshy-archive
git checkout origin/tb/meshy-archive -- <path>
```

Restore its `.import` twin the same way when the file has one. To restore a whole folder, pass the folder path.

## What was archived

The list, with each file's size and reason, is the manifest:
[`ralph/reports/LANES/REPO-SLIM/manifest.json`](../ralph/reports/LANES/REPO-SLIM/manifest.json) (entries with `"class": "UNREFERENCED"`). Most of it is the raw Meshy downloads under `assets/creatures/tetherbound/<species>/candidate_owner1101/source/` (the processed remake models in `candidate_owner1101/models/` stay on main and ship). The rest is older creature candidates, `source-v2` hero sources and props that no data file names.

Kept on main regardless: every provenance record, drafted reference, scale check, preview image, prompt, prep script and Blender source, and every flag-OFF candidate a `data/` file names. A provenance record that names an archived file has an `"archived"` block listing those paths.

The reference graph that produced the manifest is `ralph/reports/LANES/REPO-SLIM/asset_reference_graph.py` (`--rev <commit> --out manifest.json`).
