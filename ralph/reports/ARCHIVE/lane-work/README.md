# Lane work archive (27 Oct 2026)

Owner, 27 Oct: put all branch work on main so the branches can be deleted, and so the next agents can work from it.

This folder holds every lane's unshipped work as files. It sits under `ralph/`, which Godot ignores, so none of it is in the game. What ships on main is unchanged: experiments that are off, GPU-rejected and unjudged all stay out until judged.

## Layout

- **`<lane>/files/<original path>`:** that lane's version of every code, config, shader, test and tool file that differs from main. The path under `files/` is the file's real path in the repo.
- **`<lane>/<lane>.patch`:** the lane's own changes to those files, as a git patch from where the lane branched. Apply it with `git apply --3way ralph/reports/ARCHIVE/lane-work/<lane>/<lane>.patch`, then resolve anything main has since changed.
- **`ASSETS.tsv` and `restore_assets.sh`:** the lanes' binary assets, 808 files and about 1.1 GB: Meshy models, creature remakes, textures and references. They are listed here rather than copied, to keep every checkout and CI run small. `restore_assets.sh [lane] [path-substring]` writes them back to their original paths from main's history.
- **Lane evidence:** notes, round verdicts and judge files sit at their normal `ralph/reports/...` paths. Where main already had a newer copy, the lane's copy is under `<lane>/files/`.

## Lanes

| Folder | What it holds |
|---|---|
| `meadows` | Candidates that are off: ground cover, grass carpet, stronghold sightline, burrow, quarry, lock paving, grove oaks, village path r3, catch kit framing, capture-readout plate. Also the trainer aftermath heroes. |
| `stormwood` | Candidates that are off: storm sky form, storm grade, ground zones, Ashfoot polish (m51), Crown Overlook rim, Meshy Ashfoot shell. |
| `stormwood-m52-on` | The Crown Arch fix (P2-041), switched on in its arm. Never judged on the GPU. |
| `creatures-land`, `creatures` | Candidate remakes and pose work: Mirejaw olive fill, dog3 Terrapup r7, Breezetail harness, Thundertunnel value lift, Cliffspike, Voltwig, Nightburrow. Also the hit-flash, ON in the lane only: GPU G6 +0.10 / +0.15, under the bar. |
| `co12-on`, `co14-on` | Unjudged close-out arms: Cliffspike, Voltwig, Nightburrow and Thundertunnel (`co12`), and `co14`. |
| `meshy-1024` | Assets only (see `ASSETS.tsv`): every Meshy generation not yet wired into the game. |

The full branch list with each head commit is `ralph/reports/COORDINATOR/BRANCH_ARCHIVE.md`. Any file of any branch can also be read with `git show <head>:<path>`.
