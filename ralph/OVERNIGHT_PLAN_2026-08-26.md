# Overnight plan — 2026-08-26, from ~02:30Z

Owner directive, verbatim in substance: *"your whole goal overnight is getting
everything to main and making sure the gate f work continues. before it does any
visual judge, you should pick up everything else to main so it's judging the
right thing."*

## The ordering rule, which overrides lane convenience

**No visual judge, blind critic pass, or X07-style capture batch runs until
`main` carries every branch below.** A judge against today's `main` would grade a
build that is about to stop existing, and its findings would be stale by morning.
This project has already paid for that cycle more than once.

Verifying a single fix with a single still is NOT judging and stays allowed.

Sent to the Gate F fix lane (`session_01HZgCaFHAPjWzFkUJadAmgZ`) at 02:28Z via
`create_trigger` + `fire_trigger`; delivery confirmed by the returned session id.

## Landing order

1. `ralph/ARENA-CONTAIN-DETERMINISM` — the two `verify-owner-regressions-shard`
   races. **Land this first**: that job gates every other branch, so until it is
   on `main` every landing below is a coin flip.
2. `ralph/WORLD-GRASS` — grass scale, `groundmat` mid-layer, flower drifts.
3. `ralph/OPENING-STARTER-FOCUS` — the opening-blocker finding and its probes.
4. `ralph/GRASS-FIELD` — cover tiers, sky/clouds, stone and path grit, narrowed
   paths, plus the owner's last bush fix. 22 behind at time of writing; its lane
   merges `main` forward itself.
5. `ralph/GATE-F-INSTRUMENTATION` — run evidence. 22 behind; the run session
   merges it forward.
6. The Gate F fix lane's own branches as they appear.

**A branch more than 20 commits behind `main` is skipped by the sweep as stale**
(`ralph-sweep.yml:89`, `MAX_BEHIND=20`), and `MAX_BEHIND` is not exposed as a
dispatch input. Merge `main` forward before expecting a sweep to look at it.

Merge, do not rebase, when a lane is live on the branch: a merge needs no
force-push, keeps the lane's checkout valid, and still satisfies
`ship_branch.sh`'s fast-forward check (`git merge-base --is-ancestor origin/main
$SHA`).

## Then, and only then, the Gate F run

Freeze a fresh candidate **from `main`**, then one chain: S01–S10, then X01–X07.
X08 is dropped on owner instruction (it already ran clean at 62/0).

- **S01–S10 run in logic mode and produce no frames.** The Meadows renders at
  ~0.29 FPS here (llvmpipe, no GPU, 466,922 props); capture mode held one PNG at
  35 minutes on S01. Every planned shot becomes a manifest row with `file: null`.
- **X07 is the visual evidence** — 79 real 1920x1080 stills at ~50 s each. Its
  `arrival` / `gameplay` / `landmark` cameras are currently identical (0.1–2.3%
  pixel difference), so **the `X07.json` fix is a precondition**, not a
  nice-to-have.
- Wall clock: S01–S10 ~86 min including boots, X01–X07 ~180 min. ~4.5 hours.
- Save chain is **slot 4**. A fresh candidate restarts S01 clean rather than
  resuming `run://S06-exit.json`.

## Standing

- Never push `main`; ship via `ralph/**` and a dispatched `ralph-sweep.yml`.
- Confirm a landing by reading `git log origin/main`, never a workflow's tick.
- Confirm a release by the **asset timestamp and digest**, never the green tick.
- [OWNER-ONLY], never claimed from a Linux container: device frame rate, GPU,
  VRAM, thermals, controller feel, audio, Windows-export identity.
