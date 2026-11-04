# Visual lane CPU capture and judging scripts (3 Nov 2026)

These are the scripts the creatures-ralph visual lane used to raise items to a CPU mapped score of 6.0 or above. They are shared so parallel lanes reuse them instead of rebuilding them (TECHNICAL §8.1).

**Setup in a fresh session:**

```
mkdir -p /tmp/claude-0/work/bin
cp tools/visual_judge/lane_bin/* /tmp/claude-0/work/bin/
```

The scripts call each other at that path. The repo root is assumed to be `/home/user/Tetherbound`.

**Capture an item set:**

1. `run_group.sh <arm> "<F rows>"` captures every launch for those board rows from `ralph/reports/VISUAL/item-scores/job.json` into `.artifacts/vl/<arm>/<n>/`. Captures use CPU, `xvfb-run`, and Compatibility.
2. `chain.sh <base_arm> <cand_arm> "<rows>" <overlay.txt>` waits for the base, turns ON the flags listed in `overlay.txt`, captures the candidate and reverts the flags. `overlay.txt` holds space-separated `file:dotted.key` specs, and `overlay.py` turns each one ON.

All Godot runs take `godot.lock`, one at a time.

**Rules learned the hard way:**
- Capture the base and the candidate in the same session, on the same branch head. A base kept from an earlier run is stale (see v1/b13).
- `chain.sh` holds `scene.lock` from overlay to revert, and base launches take the same lock. Never run tests or another capture while an overlay is applied: tests read `data/config` from the working tree.
- `overlay.py` refuses a flag that is already ON, so remove shipped flags from overlay lists.

**Judge:**

1. `mkjudge.sh <batch> <base_arm> <cand_arm> "<rows>" <seed>` builds per-row base/cand sheets, adds 3 anchor pairs (`anchor_tiles.py`) and writes `/tmp/claude-0/work/judge/<batch>/folder/JUDGE_INSTRUCTIONS.txt` (JUDGE_PROMPT verbatim).
2. For neutral-stage creature sets (`capture_f36_poses.gd` output), use `mkstage.py`.
3. Give three fresh general-purpose agents the prompt "Read <folder>/JUDGE_INSTRUCTIONS.txt and follow it exactly; look only inside <folder>".
4. Save each judge's `{"sets": {code: {"A": {"bar_a": x}, "B": {...}}}}` as `j/j1..3.json`.
5. Run `python3 assemble.py k/key.json j/j1.json j/j2.json j/j3.json batch.json`, then `python3 tools/visual_judge/calibrate.py batch.json --out mapped.json`.

**Decision:** ship a flag ON only when its row gains (CPU mapped). Record the score in the flag's `_why`/`_why_on`, and add a test that asserts ON and the score. Keep the verdict, the JSONs and one `_sheet` under 1.5 MB in your lane's `ralph/reports/LANES/<LANE>/`.
