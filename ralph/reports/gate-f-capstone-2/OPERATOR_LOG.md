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
| Import cache | in progress |

`.gitignore` re-checked against CD-2: `shots/` is root-anchored, so
`ralph/reports/gate-f-run-*/<segment>/shots/` is tracked. Verified with
`git check-ignore` before the run rather than after it.

---

## Run journal

(entries appended as the chain executes)
