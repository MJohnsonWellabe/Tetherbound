# Gate F — operator stand-down, 2026-08-27

**Written for the rig lane.** Stood down on the coordinator's stop order of
2026-08-27 13:43Z. No segments started after it. Everything is on
`ralph/GATE-F-RUN-20260827`, pushed through `89c87b56`.

---

## 1. READ THIS FIRST — Phase B's CD-2 is factually wrong, and it matters

CD-2 says *"no `shots/` directory exists anywhere in the run, and git has never
carried one"*, and concludes X07's 79 named artefacts *"do not exist on disk"*.

**The second clause is right. The first is wrong, and the conclusion drawn from
it is wrong.**

| claim | reality |
|---|---|
| no `shots/` exists | **False.** Every segment has one. X07's held **79 real 1920×1080 PNGs, ~1.5 MB each, 134 MB total** |
| git never carried one | **True** — and here is why |
| the artefacts don't exist | **False.** They existed the whole time, in the container |

**Cause, confirmed mechanically:**

```
$ git check-ignore -v ralph/reports/gate-f-run-.../X07/shots/GF-14-COMBAT-13b.png
.gitignore:34:shots/	ralph/reports/.../X07/shots/GF-14-COMBAT-13b.png
```

`.gitignore:34` is a bare **`shots/`**, written for survey output — the comment
above it reads *"# Survey output. Regenerate with tools/survey.sh +
tools/contact_sheet.gd."* **A bare directory pattern matches at any depth**, so
it silently swallows every Gate F segment's `shots/`, in this run and in every
previous one.

`git add <dir>` skips ignored contents **without warning**, which is why fourteen
per-segment commits looked clean while the frames stayed behind.

**They are now recovered** — force-added in `89c87b56`. Anyone can open them.

**Consequences for the rig lane:**

1. **Do not rebuild the capture path on the premise that it never captured.** In
   capture mode it worked: 79 of 80 planned frames, at the requested
   1920×1080, no fallback.
2. **The colour verification in check-in 28 stands.** It was computed from those
   files' actual pixels — a from-scratch PNG decoder over all 79 — not from a
   manifest. Result: **the hue-rotation artefact does not affect X07's batch**
   (no step change after frame 1; nothing in the 2.9–3.9 band; max 2.154, median
   1.044). That closes the question the 2026-08-26 handover §5 left open.
3. **The real defect here is a repo-hygiene one, not a harness one**, and it is
   one line. I did **not** fix it: `.gitignore` is a repo change and §13 keeps
   the operator out of it. It is yours.
4. **CD-2's "23 of 79 timestamps have no background frame within 3 s" is
   consistent with the files being real.** Captures are step-driven; the
   background recorder runs on its own timer at 0.1 Hz default. They are not
   expected to align.

---

## 2. What ran, and what never started

**Candidate `f082bdf6`.** Run dir `ralph/reports/gate-f-run-20260827T025303Z/`.

| segment | verdicts | mode | note |
|---|---|---|---|
| S01 | 13 P / 1 F | logic | |
| S02 | 68 P / 7 F | logic | |
| S03 | 210 P / 64 F | logic | |
| S04 | 54 P / 18 F | logic | |
| S05 | 69 P / 7 F | logic | only segment with usable §D pacing data |
| S06 | 86 P / 17 F | logic | |
| S07 | 75 P / 23 F | logic | |
| S08 | 112 P / 22 F | logic | |
| S09 | 63 P / 12 F | logic | |
| S10 | 89 P / 31 F | logic | |
| X01 | 1085 P / 118 F | logic | 975 `input_probe` cells |
| X02 | 149 P / 21 F | logic | |
| X03 | 132 P / 32 F | logic | **completed before the stop reached this lane** |
| X07 | **no notes** | **capture** | stopped at step 184/266; 79/80 frames; see `X07/WHY_INCOMPLETE.md` |
| | **2205 PASS / 373 FAIL** | | across the 13 segments that wrote verdicts |

**Never started: X04, X05, X06, X08.** X08 had been dropped by owner decision,
then reinstated by the owner on 2026-08-27 (check-in 27, and the freeze record
was updated), then overtaken by the stop order. It never ran.

`overhead/` also exists — the §I.7 self-measurement, run pre-freeze.

---

## 3. How the rig is invoked — the part you asked for

### 3.1 Two modes, and `run_segment.sh` owns both

```
tools/gate_f/run_segment.sh S01              # logic mode
tools/gate_f/run_segment.sh --capture X07    # capture mode
tools/gate_f/run_segment.sh --overhead       # §I.7 self-measurement
```

Environment: `GODOT` (default `$HOME/.cache/tetherbound-art/godot`),
`GATE_F_RUN_DIR` or `--run-dir` to keep a batch in one run directory.

### 3.2 Where xvfb IS and IS NOT applied — the CD-1 question

**`run_segment.sh` applies xvfb in exactly two places, both inside capture mode**
(`run_segment.sh:192` and `:241`):

- `:192` — the capture **smoke gate** (`tools/capture_diag_minimal.gd`)
- `:241` — the **segment itself**

```bash
xvfb-run -a -s "-screen 0 ${w}x${h}x24" \
  "$GODOT" --path . --rendering-driver opengl3 --resolution "${w}x${h}" \
  --script "$HARNESS" -- "${HARNESS_ARGS[@]}" --gatef-capture
```

**Logic mode (`run_logic`) deliberately has no display server and no rendering
driver:**

```bash
"$GODOT" --headless --path . --script "$HARNESS" -- "${HARNESS_ARGS[@]}"
```

That is correct, not a bug: `--headless` **with** a rendering driver hangs
forever, which `ralph/conventions.md` calls the single most expensive trap in the
repo, and `run_segment.sh`'s header documents at length.

**So CD-1's mechanism is real but its framing needs care.** The journey segments
ran logic mode *by an operator decision recorded in advance* (check-in 8, and
restated in check-in 16 and 26 of the lane log), because capture mode on the
journey was measured as unaffordable — see §3.4. In that mode the harness does
not silently swallow the capture; it writes

```
capture GF-01-TITLE-01 skipped (headless run); manifest row written with file:null
```

and the step returns **PASS**. **That a step which cannot produce its evidence
returns PASS is a genuine protocol defect and CD-1 is right to name it.** The
`file: null` row is §C.4-compliant ("an absent frame is evidence too"); the
**PASS verdict on top of it** is the part that misleads. A `SKIPPED` or `N/A`
verdict would carry the same information without asserting success.

**`--gatef-capture` is the flag that distinguishes them**, passed only by
`run_capture`.

### 3.3 Where `shots/` comes from

`operator_harness.gd` writes captures to `<out>/shots/<id>.png` and the row to
`<out>/shots/manifest.json`. In logic mode the PNG is skipped and only the
manifest row is written, with `file: null`.

Both paths worked. **The files were produced and then hidden by `.gitignore:34`
(§1).**

### 3.4 The cost model, measured on this container

This is the number that decides what can run here.

| mode | ms/frame | source |
|---|---|---|
| logic (`--headless`) | ~5 | check-in 8 |
| capture, 466,922 props | ~3,400 | check-in 8, 2026-08-25 |
| **capture, 762,058 props (this candidate)** | **mean 9,416, max 21,714** | **X07's own `route.csv`, 1,194 rows** |

**~0.095 FPS.** None of this is a game performance number — llvmpipe, no GPU.
Device frame rate stays **[OWNER-ONLY]** (§K.1).

**The trap that stopped X07**, and the single most useful thing in this document
after §1: `operator_harness.gd:622` prices `wait` in **physics frames**.

```gdscript
frames = maxi(frames, int(seconds * float(Engine.physics_ticks_per_second)))
```

So `{"seconds": 90}` is **5,400 frames**, and in capture mode each is a rendered
1920×1080 llvmpipe frame — **≈15.75 hours for one step.** X07 had two such steps
left (`X07-184`, `X07-188`): **≈31 hours** to gain one frame and the verdict
file. Stopped under §A with all evidence preserved.

**Any capture-mode segment carrying `wait` steps measured in tens of seconds
cannot finish on this box.** Do not shorten the waits — they exist so fights
resolve. Price them against the renderer before launching, or run capture batches
on hardware with a GPU.

### 3.5 Verdicts are written only at segment end

`notes/<segment>.md` appears **only when a segment completes**. Kill it early and
you lose every step verdict — which is why `X07/notes/` is empty here, and why
`gate-f-run-20260825T201354Z/S01-superseded-1/notes/` is empty too. Telemetry,
frames and shots survive; verdicts do not.

### 3.6 Two container traps that cost time

1. **`godot --headless --path . --import` exits partway through each pass and
   still returns `rc=0`.** First pass stopped at 38 files, second reached 2,513.
   A half-built cache makes resources fail to load and **viewpoints render empty
   instead of erroring** — silent poison for any visual verdict. Loop the import
   until the file count stops growing. CI hides this behind a two-pass `|| true`.
2. **`nohup … &` inside a backgrounded tool call gets reaped** when the outer
   call returns — exit 144, truncated logs, no error. Run the command directly.

### 3.7 `SHA_PROVENANCE.md`

`run_segment.sh` stamps `git rev-parse HEAD` at each segment's launch, and this
run committed evidence per segment, so the telemetry `sha` field **drifts** and
is never the candidate after `overhead`. Verified that every commit between
`f082bdf6` and HEAD touches only `ralph/reports/`, so the build behind every
observation is the candidate. Details in the run directory.

---

## 4. What the evidence says about the game, kept separate from the rig

Recorded so it is not lost while the rig is rebuilt. **All severity candidates
only; Phase B rules.**

1. **Input ownership is taken and not passed on.** X01 is the characterisation:
   **118 failures over 975 probed cells — 87.9% of the matrix behaves**, so this
   is concentrated, not general. **30 distinct failing (from → wanted)
   transitions.** Three families: exits to `world` fail (16); `narrative_modal →
   anything` fails (19, with 10 shell-open refusals naming `owner=DialoguePanel`);
   and tab-to-tab inside the pause shell — **which must be read against the
   harness's own `S03-109` note that "the pause shell REOPENS ON THE LAST TAB
   USED", or it will be over-counted.**
2. **No fight ever stages.** Zero `combat_*` events in **all ten** journey
   segments; party never exceeds 1. `world → combat` failing 4× in X01 is the
   matrix view of the same thing.
3. **Focus does not move.** `ui_down`/`ui_up`/`ui_right` across S04, S06, S09,
   X01, X02 — X02 alone has seven buttons where escalating presses (2→6) never
   move focus, and X01 has a cell that took **130**. Not the poll-only mistake
   §8 warns about: the harness sends the parsed event **and** the action press,
   per §0.1.
4. **The South Bridge never opens**, and from S06 the chain re-runs that one
   blocked crossing at successive band targets.
5. **The objective-id question** — ~20 failures, all reading `opening:beat:road`
   where §E.5 names ids like `opening_first_catch`. **One question, not twenty.**

**§D honesty, which survives the rig verdict:** only **S05** produced usable
pacing evidence. S06–S10 walked **115 km between them** across 164–703 distinct
positions, with peak dead-travel of 0.0–0.6 m in three of them — **retry churn
against a blocked crossing, not travel.** No §D chapter total and no 3–4 h D42
projection may be built from this run. And S05's one finding (329.8 m) carries
its own caveat: **all four over-threshold intervals in S05+S06 had nearest-POI
minima of 30.2–31.7 m against a 30 m reset radius — a 32 m radius erases all
four.**

---

## 5. What I did not do

- **Did not modify `tools/gate_f/**` or `scripts/debug/gate_f_probe.gd`.** Frozen
  (§13). X07's blocker was recorded, not patched.
- **Did not fix `.gitignore:34`**, though it is the cause of §1. Repo change,
  rig lane's call.
- **Did not diagnose or fix during the run** (§13). Groupings are labelled
  observations throughout.
- **Did not fabricate an [OWNER-ONLY] number.** No device frame rate, GPU time,
  VRAM, thermals, controller feel, audio or Windows-export identity is asserted
  anywhere in this run. Audio absence was *measured* (all ALSA drivers failed,
  dummy driver) rather than assumed.
- **Did not run X04, X05, X06 or X08.**
