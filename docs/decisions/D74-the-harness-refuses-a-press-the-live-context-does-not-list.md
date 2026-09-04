# D74 — The Gate F harness refuses a press the live input context does not list

**Date:** 2026-09-04
**Lane:** W02-HARNESS-CONTEXT-0904 (CL-H13, `docs/FINISH_THE_MEADOWS.md` §0.2)
**Status:** decided; implemented in `tools/gate_f/operator_harness.gd`

## The finding this records

Three Gate 3 lanes saw `input_context` flip to `build_catalogue` and never return
(Oreth in S08, Captain Vance in S07, "after Captain Riverwatch" in S08 — Riverwatch is
Oreth, so the third site is the first one seen from a second run). Two documents then
described it as "the harness's context resolution misresolving" and one as a shipped
controller bug. Both readings were wrong in the same direction: `input_context` was
reporting the truth, and the game's context router was doing exactly what a real
trigger pull asks of it.

The mechanism, reproduced per frame by `tools/gate_f/probe_press_context_flip.gd`:

- a `press` step names an **action** (`combat_charged`) but the harness injects that
  action's **physical binding** (LT, `JoyAxis:4`), because a poll-only press reaches
  nothing that reads events;
- the engine marks every action bound to that axis pressed — `combat_charged`, and
  `build_shortcut`, and `map_zoom_out`, and `build_rotate_left` — exactly as it does
  for hardware; `data/config/input_contexts.json` keeps the four in mutually exclusive
  contexts, so the game acts on one of them;
- every one of the three sites pressed `combat_charged` **with no fight running** (the
  challenge was refused because the lead had fainted or was not deployed, or the
  scripted press count outlived the fight). In the `world` context LT is
  `build_shortcut`, which opens the Build catalogue by design (HUD-INPUT-0903);
- the harness recorded `pressed combat_charged x1 … PASS`, noticed nothing, and every
  later step ran behind the catalogue. LB became "category left", X became a pick.

A real player cannot be surprised by this — they know whether they are in a fight. A
step-script does not, and until now nothing in the harness asked.

## The decision

`press`, `press_until` and `hold` resolve the named control against the **live**
`input_context` and the authored context map (`input_contexts.json`, `includes`
expanded) before injecting anything, re-checked before every repetition:

- live in the context → the press goes in unchanged;
- not live in a mapped context → the press is **refused** and the step **FAILs**, naming
  the context, the physical binding that would have gone in, and the live action(s) that
  binding would have fired instead (or "inert" when it would have fired nothing);
- an unmapped context (`title`, `scene:*`, `panel:*`, `locked`, an unlisted `menu_*` tab)
  or an action listed in no context (`ui_*`) → the press goes through **unchecked** and
  the result line says so.

The guard lives in the three script-facing blind primitives, deliberately not in
`_inject()`/`_edge()`: `advance_dialogue_until_closed`, `fight_until_resolved`,
`chip_to_floor` and the menu walkers each check the state they are about before
pressing, and `press_multi` exists to press across contexts on purpose (the §8
collision matrix).

## What this changes about evidence

A blind press block whose count outlives the fight now goes red at the first press after
the fight ends ("25 of 40 landed before the refusal"), instead of green with the
catalogue open. Steps in S02–S09 that were PASSing by pressing a combat verb at nothing
will FAIL. That is the honest reading and it is what CL-H1's move to
`fight_until_resolved` already asks for; a segment author who wants a moot press to read
as SKIP has `skip_if` for it.

## What this does not do

- It does not rebind anything. LT is still `combat_charged` in a fight and
  `build_shortcut` in the world; `project.godot` and `input_contexts.json` are untouched.
- It does not route any step through another device. S07-57's mouse routing stays as
  written; out of a fight it is now refused as inert rather than silently doing nothing.
- It does not close a catalogue a segment opened some other way. A flip that reaches
  `require_context` still derails the segment exactly as before; the guard removes the
  cause, not the symptom.
- It does not touch a game script. Nothing under `scripts/` changed for this.
