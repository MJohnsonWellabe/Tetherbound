# F04#0 Warrens guardian: code-blind judge (local xvfb render at 03b7a17b)

**Judge.** A code-blind subagent that saw these six frames only (agent `adf7405e3950dfa1c`, sonnet).

**Render.** `xvfb-run` + `godot --rendering-driver opengl3 --resolution 1280x720 --script tests/smoke_warrens.gd -- --guardian-attacks --guardian-settled-approach --capture-dir=...` (llvmpipe), with RENDER details in `run_log_excerpt.txt`.

**Path.** The player starts at the supported hall, outside the guardian's notice range (fixture teleport). A 19.0 m input walk leads to the guardian's natural admission, then real CombatManager resolution: 3 hits and 1 miss, `warrens guardian attack witness passed`.

| Question | Verdict |
|---|---|
| Readable opponent and named question at normal distance | **PASS.** The badger face and stripes are clear. The heavy Earth Fist has its own `!! HEAVY — get clear` banner and ground marker, which the quick lacks. |
| Tell and outcome | **PARTLY.** The heavy miss is unambiguous ("it missed you"). The quick hit relies on the impact burst. |
| Framing at actual scale | **PASS**, with a minor note: the engage and quick-tell-mid frames crop the guardian's shell at the top right before its face shows. |

**Overall: G PASS.**

**Disclosed shortcuts:**
- Fixture teleport to the hall start.
- A fixture Terrapup at L12, held at full HP (survival staging; it cannot defeat or reward the guardian).
- Before an Earth Fist, the witness moves the ally sideways by position write, to exercise the heading lock. This is existing smoke_warrens behaviour.

**What changed since the earlier "partly" verdict:**
- The fight-open camera cut and faster arm extension (7e6f7627).
- The HEAVY banner for tells of 1.1 s or more (7e6f7627).
