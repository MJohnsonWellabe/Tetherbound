# Handoff — the owner-authorized blind playtest, the repairs, and the backlog prune

**2026-08-16.** Written for a fresh context picking this up cold. `docs/HANDOFF.md` is the
project's standing state document; this one covers what changed in this session and, more
importantly, **what changed about how the loop itself runs**.

---

## 1. Read this first: the loop no longer parks

**Every `▶` owner play gate is retired**, by owner directive on 2026-08-16 — `R2.9`, `R4.12`,
`R6.3`, `MQ1-gate`, `SH53`, and `R9.5`.

`R9.5` was the exit gate, and it was **the loop's only parking point**. `ralph/PROMPT.md` used to
say "when nothing remains but R9.5, the loop is correctly done and parks." There is no such item
now. The terminal condition is an **empty backlog**: report and stop. Do not invent work, do not
promote items out of "Found along the way" on your own authority, and do not start Biome 2 —
`CLAUDE.md`'s rule stands on `GAME_DESIGN.md` §33 whether or not an item points at it.

This is already reflected in `ralph/PROMPT.md`, `LANE_PROMPT.md`, `KEYED_PROMPT.md`, `MANUAL.md`,
`BLOCKED.md` and `BACKLOG.md`'s legend. All four prompt files were updated in the same pass,
because two of them are the verbatim text that seeds the Routines — a firing started from a stale
copy would hunt for an item that no longer exists.

**`docs/decisions/D21` still describes play gates. It is history and reads as superseded, not
violated.** Do not re-create a gate because D21 mentions one.

## 2. The backlog is a different shape

**2,173 → ~680 lines.** It had become an archive: roughly two days of shipped work was still
sitting in it as open `###` items, because `DONE.md` bookkeeping fell behind and the loop's
"move it when you ship" contract quietly broke.

- A finished item is now **one line**: `- OF24 — done`. Nothing else — no SHA, no "see DONE.md",
  no post-mortem. There are 159 of them in a `## Done` list at the bottom. `git log` and
  `ralph/DONE.md` are the record; the backlog stopped being an archive.
- Two owner-feedback phases sit at the top, and they are where work should start:
  **Phase -1.5** (`OW1`–`OW9`, the owner's 2026-08-16 ROG playtest) and **Phase -1.4**
  (`PT-03`…`PT-19`, the blind playtest's open findings).
- Stale cross-references inside live items were deleted rather than rewritten (eight of them —
  "a TM is never consumed", "no Heartstone/SD17 yet", "no workbench station", and so on; all false
  as of shipped work). `R7.3` and `R7.4` were re-scoped because their premises were simply untrue.

**`OPS1` is the item that keeps this from happening again.** `DONE.md` is missing ~25 entries for
work that shipped (OF19–OF33, SC12–SC15, SD16–SD18, SE21–SE30, R8.1–R8.4, SH47, the playtest
repairs). That broken bookkeeping is the root cause of the whole prune. It is `model: haiku` and
cheap.

## 3. The playtest: what it found and what shipped

Full record in `docs/reviews/2026-08-15-full-blind-playtest/` — four documents:
`BLIND_PLAYTEST_FINDINGS.md` (frozen), `POST_BLIND_CORRECTIONS.md`, `PLAYER_LOG.md`,
`FINAL_PLAYTEST_REPORT.md`. 262 evidence frames live on
`claude/blind-playtest-planning-g371qr`, deliberately not on `main` (this repo does not commit
frames; `shots/` is gitignored).

**The headline finding was a test, not a bug.** `scripts/ui/starter_picker.gd` read its inputs as
a polled `if/elif` chain with `menu_confirm` last. `Input.is_action_just_pressed()` is true for
exactly one physics frame, so a confirm landing on the same frame as a direction press was
**dropped permanently** — and because `_move()` returns early at the ends of the row, the press
that ate it changed nothing on screen. Arrows appear to work while confirm silently does nothing,
on the one screen a player cannot skip.

`tests/smoke_opening.gd` contained a comment describing that exact failure — "present on
unmodified `main`" — and the test was written to **step around it rather than fail on it**. A known
defect had been encoded as expected behaviour. That comment is corrected and points at the
regression test now.

Six repairs shipped: the picker input order, the pause shell refusing to open over mandatory story
modals, interact prompts stopping at walls (they reached ~2.9 m through a solid floor, which is why
the whole opening could be completed without ever seeing Grandpa), a collision shape on the camera
spring arm (it had none, so Godot fell back to a hairline raycast — that is both the clipping *and*
the collapse into the player's head), the footer legend naming keyboard keys, and combat buttons
explaining themselves outside a fight. Three new regression tests: `smoke_starter_picker.gd`,
`smoke_modal_stacking.gd`, `smoke_interactable_sightline.gd`.

**A Ralph lane fixed the picker bug concurrently**, citing our corrections file by name. Their
version is the one on `main`; ours was dropped to avoid churn. That is the system working.

## 4. Three things this session got wrong

Recorded because a repair pass that hides its own false alarms is not trustworthy. Details in
`POST_BLIND_CORRECTIONS.md`; do not restate them from memory.

- **PT-01's cause, twice.** First blamed on pressing Escape; then over-corrected to "purely a test
  artifact". Both wrong — the defect was real and in the `elif` chain.
- **PT-05** was inverted. `menu_confirm` binds to main Return; numpad Enter is not bound at all.
- **PT-04** is unconfirmed, not a bug — `grab_focus()` does fire; the observation is consistent
  with this container's X input focus.

**The blind report is frozen and stays frozen.** Later understanding goes in the corrections file,
per the protocol's §37.

## 5. Traps, each of which cost real time here

- **Always `godot --headless --path . --import` after pulling art, before any capture.** A capture
  run before an import renders *missing textures* — the frames come out plausible and simply wrong.
  This cost a full render cycle in this session.
- **Never pass `--headless` to anything that renders.** It swaps in a no-op renderer and the run
  hangs. Check **file counts**, not exit codes: Terrain3D aborts on shutdown after rendering (D06),
  so a successful capture still exits non-zero.
- **This container runs the game at ~2–4 FPS and drops roughly half of injected keystrokes.** Send
  discrete keys 3× with gaps; held movement keys are reliable. Three "findings" turned out to be
  artifacts of this, which is why every surviving finding was filtered for it.
- **`docs/HANDOFF.md` is itself partially stale.** Prefer `git log` and the code over it.

## 6. What is open

- **The core loop was never played by hand.** Four attempts ended before it. Combat, catching,
  building, aggression and evolution were verified by driving the real scenes directly (results in
  `FINAL_PLAYTEST_REPORT.md` §5) and they work — but *feel* is unmeasured. Whether combat reads in
  motion and whether the throw is predictable before you commit need a human on the Ally.
- **`OF18` (the website) is partly done.** Copy, credits, framing and the wordmark shipped, and
  three frames are current. The combat and exploration frames still show a placeholder trainer,
  dead creature names and pre-D35 buttons. The item carries a five-step recipe; it leads with the
  import trap above.
- **`PT-03`** — the opening staircase nobody can find — is the report's own pick for highest-value
  remaining fix, and is `model: fable` because the affordance is an owner call.
- **`OW5`** is the owner's world-shape directive and the largest open item: the Meadows as a long
  winding trail leading progressively away from home to the stronghold, inside a square footprint,
  long enough that camping en route is forced. It supersedes `R7.3`'s framing; `R7.3` keeps only
  the bake and capacity half underneath it, and `OW6` is sequenced after it so the captain is not
  placed twice.
