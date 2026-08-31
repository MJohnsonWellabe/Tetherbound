# Gate F Capstone 2 — operator log

**Branch:** `ralph/GATE-F-CAPSTONE-2`
**Base:** `main` @ `721893a4` (contains CAP-1 fix `cf4c5ab1`)
**Operator:** agent, remote container. **Role:** tester only — no code, data or
config changes during the run (`GATE_F_MASTER_PROTOCOL.md` §J / `GATE_F_PROTOCOL.md` §13).
**Mandate:** one real, full, start-to-finish Meadows playthrough, every segment
entered through the production title-screen Load path from the previous
segment's real exit save. No hand-authored or synthetic seed saves.

---

## Setup

| step | outcome |
|---|---|
| Container start | empty `/home/user`; repo not cloned by the environment |
| Repo attached + cloned | `MJohnsonWellabe/Tetherbound` → `/home/user/tetherbound` (shallow) |
| Branch | `git checkout -B ralph/GATE-F-CAPSTONE-2 origin/main` → `721893a4` |
| CAP-1 fix present | yes — `cf4c5ab1` in `origin/main` history |
| Godot | 4.7.stable.official.5b4e0cb0f, linux editor binary |
| Mesa/EGL deps | installed after the documented `apt-get update` fallback (stale index → 404s) |
| Import cache | built, exit 0, 1750 files (the two `error` grep hits are a file named `ui_error.wav`) |

`.gitignore` re-checked against CD-2: `shots/` is root-anchored, so
`ralph/reports/gate-f-run-*/<segment>/shots/` is tracked. Verified with
`git check-ignore` before the run rather than after it.

---

## Section A preconditions

§A.4 requires both of these to hold **before** the run, so that a failure here
is a blocker rather than a finding of the run.

| precondition | result |
|---|---|
| Capture smoke writes a PNG (`tools/capture_diag_minimal.gd`) | **PASS at the requested 1920x1080** — no fallback substitution to record. `display_server=X11`, `adapter=llvmpipe (LLVM 20.1.2)`. Frame preserved as `precondition_capture_smoke.png`. |
| Full test suite green at the candidate SHA | (running) |

Audio drivers fail in this container and Godot falls back to the dummy driver
(`libpulse.so.0` absent, no ALSA card). Recorded, not worked around: §K.6
already declares audio [OWNER-ONLY] because no audio path exists in this
envelope at all. It is not a finding of this run.

---

## Run journal

(entries appended as the chain executes)

### S01 — Boot & front door
`exit 0 · 13 PASS · 0 FAIL · 0 SKIP · complete=true · 277 s wall`
14 steps ran, one prescribed frame (`GF-01-TITLE-01`) DELEGATED to S01C and
recorded as a debt. 362 route rows.

### S02 — Opening
`exit 0 · 78 PASS · 3 FAIL · 0 SKIP · complete=true · 8 delegated`
No derail, no harness errors.

**CAP-1 does not reproduce.** This is the segment that stranded capstone 1, and
the two things that made that unrecoverable are both absent here. From the
telemetry:

```
t=231.48 combat_start  my_hp 117.6   opponent bramblebun 106.2
t=256.07 catch_throw   my_hp  53.0   opponent  66.2   phase absorb
t=260.27 catch_result                                 phase verdict
t=262.82 combat_end
```

and from `saves/S02-exit.json`, which is what the rest of the chapter chains
from:

| | capstone 1 | this run |
|---|---|---|
| party | 1 creature, fainted | **2 creatures, both `fainted: false`** |
| inventory | `orb_basic x11`, nothing else | `orb_basic x12`, **`revive x2`** |

The restored `give:revive:2` (fix item 4) is present in a real production save
produced by real play, and the starter finished the tutorial fight up rather
than down. The wild catch succeeded.

#### The three FAILs, recorded not diagnosed

| step | expected | actual |
|---|---|---|
| `S02-43h` aim again (throw 4) | `input_context=combat_aim` before anything is thrown | `3 x interact did not reach it; last saw input_context=world` |
| `S02-59` the segment actually walked | `>= 150.0 m` | `147.2 m` |
| `S02-60` the 2 Hz trace ran throughout | `>= 900` rows | `574` rows |

One fact the operator can state without diagnosing, because it is a pair of
timestamps: `S02-43h` failed at **t=262.80** and `combat_end` fired at
**t=262.82** — the fight was over and the bramblebun already caught when the
step asked the aim to arm for a fourth throw. The last event of the segment is
at t=294.43 play seconds, and 294.43 s x 2 Hz is ~589 rows against the 574
recorded and the 900 asserted, so `S02-60`'s floor wants roughly 450 play
seconds of segment.

Whether the floors in `S02-59`/`S02-60` are calibrated against a longer
worst-case catch sequence than this run needed is **Fable's Phase B call**, not
the operator's. Severity candidate: QUALITY (rig-side), recorded for Phase B.
The three FAILs are carried as FAILs regardless — §J forbids skipping a failed
step silently, and none of them stopped the segment or corrupted the handoff.
