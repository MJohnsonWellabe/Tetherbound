# tools/

Scripts that are not part of the game build. Nothing here ships in the export.

## Layout

| Path | What it is | Referenced from |
|---|---|---|
| `ci/ship_branch.sh` | fast-forward landing script used by `ralph-merge.yml` / `ralph-sweep.yml` | CI |
| `verify_export.sh`, `stage_gdextension_libs.sh` | export verification and GDExtension staging | `ci.yml`, `release.yml` |
| `survey.sh`, `survey.gd`, `contact_sheet.gd` | the five fixed survey stands and their contact sheet (the visual-judge input) | `.claude/skills/visual-judge` |
| `vp_capture.sh`, `_capture_locations.gd`, `_capture_ground_and_sky.gd`, `perf_render_stats.gd` | the Visual Parity location/ground/sky capture set and the draw/primitive perf proxy | `docs/VISUAL_BIBLE.md` |
| `frame_stats.py`, `sheet.py` | measured axes for a critique round (saturation, luminance) and sheet assembly | `docs/AGENT_WORKFLOW.md` |
| `gate_f/` | the Gate F operator harness, segment step-scripts (`segments/*.json`), `run_segment.sh`, probes | `docs/acceptance/GATE_F_*.md`, `tests/test_gate_f_*.gd` |
| `art_pipeline/` | Meshy/Blender pipeline scripts (committed scripts, not MCP — D11); needs owner reference art before any generation | `docs/art/TETHERBOUND_3D_ART_PIPELINE.md` |
| `audio/` | bus layout and SFX generation | `data/config/audio.json` |
| `opening_fix/` | probes for the opening sequence | tests |
| `capture_*.gd`, `preview_creatures.gd`, `diagnose_frame.gd`, `capture_diag_minimal.gd` | purpose-built captures; `capture_diag_minimal.gd` is the 120-second "can this box write a PNG" check | `docs/AGENT_WORKFLOW.md` |

## Scratch convention

Files named `_*.gd`, `_*.py` are one-off probes and captures: run, read the result,
delete. `.gitignore` already ignores `tools/_scratch_*`; around 300 other `_`-prefixed
scripts were committed anyway before the 2026-09-02 reset and are listed for removal in
`docs/CLEANUP_MANIFEST.md`. Do not add to them. A probe worth keeping gets a
non-underscore name, a header saying what it measures, and a mention in the document
that relies on it.

## Invocation rules (paid for, more than once)

- Captures: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver
  opengl3 --resolution 1280x720 --script tools/<capture>.gd`. Never `--headless`
  together with a rendering driver: it hangs forever and leaves a zombie.
- Tests and bakes: `godot --headless --path . --script <file>`.
- Re-import after any asset or bake change before capturing, or the frames show the old
  asset out of `.godot/`.
- One Godot render at a time on a 4-core box; serialise with
  `while pgrep -x godot; do sleep 10; done`.
