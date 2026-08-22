# D16 — Free build is temporary scaffolding, and is built to be deleted

**Status:** accepted
**Milestone:** menu groundwork (Settings tab), development convenience

## The problem

The owner: *"I should also have a toggle to free build without cost right now
until we launch the real game. that should be a setting too"*.

Building costs materials, gathering barely exists, and placement (M8) does not
exist at all. Testing the build screen therefore means either seeding a satchel
by hand or ignoring the costs — both of which get in the way of the thing
CLAUDE.md actually asks for, which is a game the owner voluntarily keeps
playing.

The real risk is not the toggle. It is what a toggle like this becomes. A cheat
that leaks into gameplay code turns into a permanent mechanic nobody decided to
add, and a cheat that is silent turns into a costing bug report six months later
that costs an afternoon to discover is not a bug.

## What was decided

### 1. It is a development convenience with an expiry date, and it says so

The owner's own framing — *"until we launch the real game"* — is written into
the code, into `data/config/menu.json`, and into this file. It is not a
difficulty setting, not a creative mode, and not a game rule. Nothing else in
the design may lean on it.

**Removing it is deleting four things, and nothing else knows it exists:**

| File | What comes out |
| --- | --- |
| `autoload/game_state.gd` | the `free_build` block: the flag, `set_free_build`, the free branch in `build_cost_for`, `_adopt_preferences` |
| `data/config/menu.json` | the `gameplay` section entry and the `gameplay` block |
| `scripts/ui/tab_settings.gd` | `_build_gameplay`, `_on_free_build`, `_poll_gameplay`, the `"gameplay"` case |
| `scripts/ui/tab_build.gd` | `_free_note`, `_free_build`, and the three sentences that read them |

Plus `tests/test_free_build.gd`, `tests/smoke_free_build.gd` and one CI step.
`GameState.build_cost_for` itself stays: it is not scaffolding.

### 2. One accessor, and every cost check goes through it

```gdscript
GameState.build_cost_for(id) -> Array   # what the piece costs RIGHT NOW
GameState.can_afford(id) -> bool        # asks build_cost_for
```

This is the whole design, and it is the reason the toggle is safe to have.

Placement does not exist yet. When M8 writes it, it will spend what
`build_cost_for` returns — and because free build returns an *empty cost*, M8
spends nothing while the toggle is on **without ever having heard of the
toggle**. The alternative, a boolean consulted at each call site, is a rule that
holds only until the fifth caller forgets, and the bug it produces looks like a
costing bug rather than a cheat left switched on.

`scripts/ui/tab_build.gd` therefore contains no affordability rule at all any
more. It draws what the accessor says. The catalogue cost is still read directly
for *display*, because "what this normally costs" is worth reading while free
build is on — but nothing decides anything from it.

A piece that is not in the catalogue is refused whatever the toggle says.
Otherwise the empty cost would make every typo'd id affordable.

### 3. It is loud, on the screen where it changes the numbers

While the toggle is on, the Build tab carries a banner above the catalogue —
before anything is selected, not buried in the detail panel — and the cost list
grows a heading that says none of it will be spent and stops marking shortfalls.
The Settings row itself reads `Free build:  On` in the same amber the Controls
screen uses for "changed from default".

A hidden cheat that silently changes economics is how someone later reports a
costing bug that is not one. This one cannot be on without saying so.

### 4. It lives in the settings file the controls already established

D15 made `user://settings.json` the project's first and only file in `user://`,
versioned from the first write, with a comment promising that display and audio
would join it rather than each inventing their own. This is the first thing to
take that promise up.

`scripts/ui/key_bindings.gd` gained a `gameplay` dictionary that it carries
verbatim through a save and a load. That matters more than it looks: a save
rewrites the whole document, so without the passthrough the next rebind would
silently erase the toggle.

No format bump was needed in either direction. An older build reads a version-1
file and ignores the section; a build that has never seen the key reads it as
absent, which is the same as off.

**Absent is off, and so is every failure.** A missing file is the normal first
run. A corrupt file, or one from a newer build, ends with free build off — the
section is adopted only on the way to `LOAD_OK`. A file that was truncated
mid-write must not be able to switch a cheat on.

### 5. Gameplay is drawn above Controls

Not a statement about importance. Everything in the Controls section lives
inside a `ScrollContainer` that expands to fill the tab, so a section placed
after it would sit at the bottom of the screen behind a list the player has to
scroll past. Above it, the toggle is two presses of the stick from where the
screen opens (asserted in `tests/smoke_free_build.gd`), and it is one row to
delete later rather than a hole in the middle of the Controls layout.

## What was rejected

**A second preferences file.** Two files in `user://` is two things to version,
two things to migrate, and a race the day both are written in one frame.

**A generic data-driven toggle framework.** One toggle exists. A JSON list of
toggles with a generic id-to-property binding is exactly the speculative
generalisation CLAUDE.md warns against, and it would make the feature *harder*
to delete, which is the one property it must keep.

**Deducting materials on confirm so free build could skip the deduction.**
Nothing is spent when a piece is armed, deliberately: a cancelled placement must
not eat a gathering trip. Free build did not get to change that.

**A cheat menu, a console, or a debug build flag.** The owner asked for a
setting. A setting is discoverable, controller-navigable, and — being in the
Settings screen next to the controls — impossible to forget is switched on.

## Consequences

- Anything that spends materials to build **must** call
  `GameState.build_cost_for`. A second reader of `buildables.json` that decides
  affordability is a bug, not a shortcut, and `tests/test_free_build.gd` is
  written to say so.
- The toggle must come out before launch. It is four deletions and this file.
- `user://settings.json` is now genuinely a *settings* file rather than a
  controls file. Display and audio follow the same passthrough.

## Amendment — OP21-10 (2026-08-22): free build now waives crafting too

Section 2 above scoped free build to *building* costs on purpose, and
`tests/test_recipes.gd::test_craft_never_touches_free_build` was written to
assert exactly that boundary — crafting has its own materials loop
(`GameState.recipe_cost_for`/`can_craft`/`craft`) and deliberately did not
consult the toggle.

The owner's `ralph/OWNER_PLAYTEST_2026-08-21.md` (OP21-10) overrules that
scoping: if building is free in the current mode, a structure's prerequisite
crafting must not be the one step that still drains the satchel. A build
costing nothing while its own recipe eats materials reads as inconsistent
friction, not as a boundary anyone playing the game can see the reason for.

**What changed:** `GameState.recipe_cost_for` now returns `[]` while
`free_build` is on, the same empty-cost shape `build_cost_for` already
returns. Nothing else about the contract moves — `can_craft` still refuses an
untaught (OF30) or unknown recipe however rich the satchel is or however the
toggle is set, and a `reinforce` recipe still refuses if the tool it upgrades
is not actually owned. Free build waives *cost*, not the recipe's other
gates.

The old test was inverted in place rather than deleted —
`test_craft_now_respects_free_build_per_op21_10` in `tests/test_recipes.gd` —
specifically so a future reader searching history for "free_build" and
"craft" finds the reversal and its reason, not a hole where a test used to
be.

This is the second thing D16 said would need touching before launch: the
toggle itself (section "What was decided" / "Consequences") still comes out
entirely before release, and when it does, `recipe_cost_for`'s `free_build`
branch leaves with it — one more line for the same four-deletion list, not a
new permanent branch in the crafting path.
