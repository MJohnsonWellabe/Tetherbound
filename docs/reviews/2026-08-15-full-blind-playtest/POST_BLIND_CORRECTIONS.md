# Post-Blind Corrections

Protocol §37 requires the blind report to stay frozen once written, and any change in
understanding to be explained separately. This is that file. `BLIND_PLAYTEST_FINDINGS.md` is
unchanged and stays unchanged — it records what a player experienced, which is still true.
This file records what the code turned out to say.

Three findings changed materially once implementation was read. Two were wrong in ways worth
being explicit about, and one was wrong in the opposite direction from my first correction.

---

## PT-01 — right symptom, wrong cause, and my first correction was also wrong

**Blind report said:** pressing Escape during the mandatory starter selection permanently kills
the confirm input; P0 soft-lock.

**My first correction (during testing) said:** it was purely a test-environment artifact,
because I reproduced the dead confirm without ever pressing Escape, and 12 rapid presses then
confirmed instantly.

**What the code actually says — and this is the accurate version:** there is a real bug, and it
is neither Escape nor purely environmental.

`scripts/ui/starter_picker.gd:313-324` reads input as a polled `elif` chain in
`_physics_process`:

```gdscript
if Input.is_action_just_pressed("ui_right"):        _move(1)
elif Input.is_action_just_pressed("ui_left"):       _move(-1)
elif Input.is_action_just_pressed("menu_confirm"):  _confirm()
```

`is_action_just_pressed()` is true for exactly one physics frame. If a confirm registers on the
same physics frame as a direction press, the chain checks the direction first and **the confirm
is dropped permanently** — not deferred to the next frame, gone. And because `_move()`
(`:327-332`) returns early once the index is clamped at either end, the direction press that ate
the confirm produces **no visible change at all**.

That is exactly the symptom I documented blind: arrows appear to work, confirm silently does
nothing. My blind observation was correct; my causal story was wrong; my self-correction
over-corrected. The subagent reproduced the failure deterministically in the real scene, both by
action state and by genuine `InputEventKey` RIGHT+ENTER, four rounds running.

**Severity:** the low frame rate of this test container made the collision happen constantly, so
the P0 framing was environment-amplified. But the defect is real and frame-rate independent in
kind — any player who presses a direction and confirm within the same physics tick loses the
press, and `name_prompt.gd:305-311` already avoids this pattern, so the picker is the outlier.
Fixed rather than dismissed.

**The most damning part is a test, not the game.** `tests/smoke_opening.gd:409-427` contains a
comment describing this precise failure verbatim — "the `elif` chain checks `ui_right` first and
swallows `menu_confirm` … exactly the observed 'confirming an orb did not close the picker'
symptom, present on unmodified `main` before this test existed" — and the test was written to
step around the bug rather than fail on it. A known defect was encoded as expected behaviour.
That is the single most valuable thing this playtest surfaced.

## PT-01b — the modal stacking is real, and separate

The pause shell genuinely can open on top of mandatory story modals, which is what the
screenshots show. `game_menu.open()` (`scripts/ui/game_menu.gd:287-291`) refuses for exactly two
reasons: already open, or a fight in progress. Keeping the shell out is opt-in from each modal
via `hold_input()`. `name_prompt.gd` opts in (added by OF25). `starter_picker.gd` and
`dialogue_panel.gd` do not — so the shell stacks over the starter choice and over live
conversations. `scenes/ui/starter_picker.tscn` also sets no `process_mode` override, so once the
shell pauses the tree the picker stops processing but keeps drawing: that is the "title and
look/choose hints ghost through the overlay" in frames 226–230.

This is being fixed in the shell itself rather than per-modal, so a future fourth modal cannot
forget to opt in.

## PT-05 — inverted, and partly my rig

**Blind report said:** the ⏎ glyph is shown but only numpad Enter works; main Return is dead.

**Code says the reverse.** `project.godot:281-286` binds `menu_confirm` to physical `KEY_ENTER`
(main Return) plus joypad button 0. Numpad Enter is **not bound to it at all**. A raw
`KEY_KP_ENTER` event does nothing to the picker.

What actually happened: my presses were being swallowed by PT-01's `elif` collision regardless of
which key I used, and the numpad presses that eventually "worked" did so because this container's
X keymap delivers KP_Enter as the main Return keycode. So the observation was real, the
attribution was wrong in both directions. There is no binding bug. There *is* a coverage gap: no
test fires a raw physical `KEY_ENTER` at the picker's polled path.

## PT-04 — not reproducible in code; likely my window focus

**Blind report said:** the naming dialog opens without focus in its text field; typing and
clicking do nothing, only Tab rescues it.

`name_prompt.gd:204-205` → `_apply_mode()` (`:232-247`) does call `_field.grab_focus()` on the
keyboard path, and headless verification confirms `focused=true`, focus owner `Field:<LineEdit>`,
both when opened directly and through the real story path. Frame 247 shows a caret and a focus
ring in an empty field after typing — consistent with X-level input focus in this container, not
a missing `grab_focus()`. **Downgraded to unconfirmed**, pending a real-window check on hardware.
No fix attempted.

## PT-09 / PT-10 — already fixed before I reported them

The torch findings came from run 1 on `main@7547f386`. OF24 (`a8034d2c`) landed between that
build and `9e4a90a1`: the torch is now instantiated unconditionally in `player_controller.gd:69-71`,
is not an inventory item, and self-activates at dusk via `torch.gd:213-218`. My observation
predated the fix. No action — worth re-verifying in a real window at night, but the code shows no
remaining item gate.

## PT-11 — working as designed; the gap is feedback

Hotbar slots are positional by explicit design (`playground_hud.gd:1055-1069` — hotbar slot N
mirrors backpack slot N). Rearranging the backpack changing the hotbar is intended. What is
missing is any in-the-moment feedback when a rearrangement displaces a hotbar-bound item. Re-scoped
from "silent unbind bug" to "missing feedback".

## PT-23 — confirmed, and narrower than it looked

Autosave is called from exactly one place in the codebase: `camp.gd:184-187`, inside the rest-at-camp
path. There is no periodic autosave, no day-transition autosave, no milestone autosave. The empty
autosave slot is therefore expected behaviour, not a save-system bug — but it means a player who
has not yet built a camp (i.e. every new player, for the whole first session) has no autosave at all.

---

## What stands unchanged from the blind report

PT-02 (interaction reaches through floors — root cause found and confirmed: `interactable.gd:79-85`
uses raw Euclidean distance with no line-of-sight, measured ≈2.9 m through a solid floor slab
inside a 4.0 m radius; **re-observed live on the current build during the core-loop run**),
PT-03 (stairs undiscoverable — confirmed: no light, no distinguishing geometry, no marker at the
stair head), PT-07 (camera — root cause found: the `SpringArm3D` has no collision shape assigned,
so Godot falls back to a single raycast, which explains both the clipping and the collapse-into-head),
PT-06, PT-08, PT-12, PT-13, PT-14, PT-17, and the whole Positive Findings section.
