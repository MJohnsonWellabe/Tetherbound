# C2 — The task feed

**Status:** design contract, W19-CONTRACTS lane, 2026-09-04. Written against `main` at
`ef16544f`. Read-only on code and data; every *do* is an instruction to an implementation
lane. **Source directives:** `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-4 and
OP-0904-5, `docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md` D-0904B-1, D-0904B-2 and
amendment A-3. Plan rows: CL-O4 (the feed half), CL-W1, CL-W2 in
`docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G; `docs/FINISH_THE_MEADOWS.md` Phase 2a C2.

The owner's words:

> There isn't enough to do anywhere... There's nothing to take you off the path... I need
> more of a reason to fight everyone. I need more things to go gather. Maybe things pop up
> on the map and tell you to go do them.

> You should have to beat tether grunts along the way at the relay stations and they each
> then allow you to turn off that relay and we should build that into the story so you have
> that to do as you keep going as well. Then a quest to beat all trainers in the meadows and
> that's tracked too for another thing to do. Add more like that so we can keep it
> entertaining rather than being a running simulator.

Every contract has an id (`T-…`), a **do**, an **owns**, a **tests** line and a **fails
if**.

---

## 0. The rules this document is built inside

- **Not a quest engine.** Spec §19 and `CLAUDE.md` ban one, `quest_log.gd`'s own header
  says so twice, and `objectives.json`'s `_comment` records the shape that is allowed: an
  entry is a pure function of the flag store plus static data. **A task is the same
  thing with three more fields** (a pin, a counter, a reward). No prerequisites, no
  branching, no scripting language, no per-task code.
- **The MAIN STORY card is untouched.** `quest_log.gd::tracked_text()` — the first main
  entry whose flag is unset, in file order — stays the HUD's one tracked line, its
  `how` hint stays, its objective marker (`map_state.objective_marker()`) stays. The feed
  never displaces it. Spec §16: "Use one concise tracked objective."
- **The map is not a radar** (`GAME_VISION.md` §5, `map_state.gd`'s header). A pin marks
  a *task*, an *alpha the player has been within 300 m of*, or a *named opponent the
  player has been told about* — never a wild population.
- **Five creatures, no storage.** The alphas task clears on caught **or beaten** (A-3), so
  a full roster can always finish it.
- **One fight per opponent** (D-0904B-5, shipped: all 31 authored entries carry
  `rechallenge: false` and a non-empty `defeat_flag`). The all-trainers tally is
  therefore a count of flags that can only be set once each.
- **No new trainers.** `tests/test_chapter_content_map.gd` caps the chapter at 26
  distinct opponents by name and it is at the ceiling. The relay chain is built from
  grunts who already stand where the stations are.
- **Levels are never player-scaled.** Nothing in the feed reads the player's level.
- **No `docs/owner/*` edits, no save-format bump.** Every piece of feed state is a flag in
  `progression_state.gd`'s existing flat store (persisted since save VERSION 3) or is
  derived from flags at read time. D72 established that adding flag ids to that store is
  not a format change.

---

## 1. The mechanic

A **task** is a surfaced, discoverable, tracked thing to do, with a place on the map, a
visible count, a reward and a completion beat. It is what the owner means by "things pop
up on the map and tell you to go do them."

### T-1 — The task record (data)

*Do:* a new file `data/progression/tasks.json`, read by `quest_log.gd` beside
`objectives.json`. One list, `tasks`, file order is display order. Each entry:

| key | required | meaning |
|---|---|---|
| `id` | yes | bookkeeping |
| `title` | yes | the line shown, ≤ 40 characters, no compass directions (`objectives.json` `_comment_directions`) |
| `kind` | yes | `chain` (ordered flags, each a step), `tally` (unordered flags, a count), `find` (one flag) |
| `flags` | yes | the flag ids that make progress; for `chain` in step order |
| `done_flag` | yes | set by the feed itself when every entry of `flags` is set; the entry is DONE when this holds, exactly like a main entry's `flag_id` |
| `surface` | yes | what pops it up (§1.2): `{"on_flag": id}` or `{"on_radius": {"of": <pin source>, "m": 300}}` |
| `pins` | no | where it is on the map (§1.3): a list of `{"world": [x, z], "icon": id, "clears_on": flag}` or `{"from": "trainers" \| "alphas" \| "rest_points" \| "harvest", "filter": …}` |
| `milestones` | no | for `tally`: `[{"at": n, "reward": {…}, "flag": id}]` |
| `reward` | no | on `done_flag`: `{"xp": n, "items": [{"id": …, "n": …}], "flag": id}` |
| `voice` | no | `{"surfaced": conversation_id, "done": conversation_id}` — who speaks the beat, resolved through the ordinary `greeting_when` mechanism on the named NPC |
| `how` | no | one line, same rules as `objectives.json`'s `how` (input-action tokens, device-aware) |

`quest_log.gd` gains `task_entries(progression) -> Array` returning `{id, title, done,
surfaced, count, total, tracked, pins}` per task, computed from flags every call, no
state. `count` for a `tally` is the number of set flags in `flags`; for a `chain` the
index of the first unset flag; for a `find` 0 or 1.

*Owns:* `data/progression/tasks.json` (new), `scripts/world/quest_log.gd`.
*Tests:* `tests/test_task_feed.gd` (new): a fixture `tasks.json` with one of each kind;
counts move only when the named flags are set; `done_flag` fires exactly once and never
un-fires; a task whose `surface` has not fired is not in `task_entries()`; file order is
preserved; every `flags` id referenced by the shipped file exists somewhere a system sets
it (walk the trainer tables' `defeat_flag`s, the spawns' once-ids, the relay consoles'
flags, the rest points' ids — real data, not a grep of scripts).
*Fails if* any task carries a condition on another task, a level, a party fact or a
timer; if a task can be DONE without its `done_flag` set; or if the file needs code to
interpret any entry.

### T-2 — What fires the pop-up

*Do:* `quest_log.gd::surface_check(progression, player_pos)` runs from
`game_state.gd::_process()` on the existing `progression.revision` tick **and** on a 1 Hz
position tick (the same cadence `map_state.update_region()` already uses). For each task
not yet surfaced:

- `on_flag`: surfaced the moment the named flag is set.
- `on_radius`: surfaced the moment the player is within `m` metres of **any** of the
  task's pin sources (an alpha's spawn centre, a captain's position, a rest point).

Surfacing sets the flag `task_surfaced:<id>` (persisted, never cleared) and pushes a
`task_surfaced` event onto **prompt 73's progression feed** (`docs/prompts/73-…` §2.1 —
the queue-with-revision the HUD already drains for XP and bond). The HUD renders it as the
same banner style as a bond milestone, one line: **"New task: Break the relay line"**,
with the map pin icon, 3 s, then gone. The task appears in the quest log's Tasks list
from that moment, with its current count (a tally surfaced late shows the flags already
set — the all-trainers task surfacing after the tournament reads "5/31", not "0/31").

*Owns:* `scripts/world/quest_log.gd`, `autoload/game_state.gd` (the two ticks only; the
feed queue is prompt 73's and must land first or ship a stub of the same shape).
*Tests:* `tests/test_task_feed.gd`: `on_flag` surfaces on the tick after the flag;
`on_radius` surfaces at 299 m and not at 301 m; a surfaced task stays surfaced after
`load_data`; the banner event is pushed exactly once per task per save.
*Fails if* a task surfaces twice, if surfacing depends on anything but a flag or a
distance, or if the banner is drawn by a second mechanism instead of prompt 73's feed.

### T-3 — The pin

*What is there:* `map_state.gd::add_dynamic_marker(id, icon, world_pos)` /
`remove_dynamic_marker(id)`, drawn by `minimap.gd::_draw_landmarks()` and `tab_map.gd`
with collision handling, persisted by `map_state.save_data()` as `dynamic_markers`. CL-W1
already names this as the alpha-pin hook.

*Do:* pins are **derived from flags, never stored as the source of truth**. On every
`progression.revision` change and on load, `quest_log.gd::sync_pins(map_state,
progression)` rebuilds the set of `task:<task_id>:<n>` markers: a pin exists while its
task is surfaced and its `clears_on` flag is unset. The persisted `dynamic_markers` list
is then only a cache that `load_data()` fills and the next sync corrects — so a pin can
never outlive the flag that should have cleared it, which is CL-W1's *fails if*.

Three icons, added to `data/config/map_landmarks.json`'s icon set and drawn by
`test_map_icons.gd`'s existing sweep: `task` (a hollow diamond), `alpha` (a filled diamond
with a notch), `foe` (a diamond with a bar — a named opponent). The MAIN STORY objective
marker keeps its own icon and always draws on top.

*Owns:* `scripts/world/quest_log.gd`, `autoload/map_state.gd` (no API change expected),
`data/config/map_landmarks.json` (icons), `assets/ui/icons/map/` (three icons in the
installed icon style — `tools/gen_item_icons.py`'s family).
*Tests:* `tests/test_map_state.gd` (extend): after `sync_pins`, the marker set equals the
flag-derived set; a marker whose `clears_on` flag is set is removed on the next sync;
`save_data` → `load_data` → `sync_pins` reproduces the set exactly; `tests/test_map_icons.gd`
(extend) draws the three icons.
*Fails if* a pin survives its clearing flag across a save/load, if a pin exists for a
task that has not surfaced, or if pins are ever the thing a system writes to directly
instead of setting a flag.

### T-4 — The counter

*Do:* on every `progression.revision` change, for each surfaced, undone task whose
`count` moved, push a `task_progress` event (`{id, title, count, total}`) onto the
progression feed. The HUD shows it as a **sub-line under the MAIN STORY card** for 3 s:
**"Trainers beaten 12/31"**. The quest log's Tasks list shows the same `n/total` on the row
permanently (`objectives.json` `count_flags` already renders ` n/total`; reuse that
formatter).

*Owns:* `scripts/ui/playground_hud.gd` (the sub-line under the objective card, same slot
the level-up sub-line of prompt 73 uses; they queue, never overlap),
`scripts/ui/tab_quest_log.gd`.
*Tests:* `tests/test_task_feed.gd`: a count event per change and no event when nothing
moved; `tests/smoke_objective_hint_card.gd` (extend): the sub-line appears and clears and
the MAIN STORY line above it never changes text or position while it does.
*Fails if* a counter tick displaces, shortens or restyles the MAIN STORY line, or if two
feed events draw at once.

### T-5 — The reward and the completion beat

*Do:* when `done_flag` lands (set by `surface_check` the tick after the last progress
flag), the feed grants `reward` through the existing `give:` path
(`sequence_director.gd::_give_items()`'s validation, reused as a static call, so a
reward that names an item `item_db` cannot resolve fails the build not the player), banks
`xp` to the party through `progression.gd`'s ordinary award (party share as usual), sets
`reward.flag`, sets `task_rewarded:<id>`, and pushes a `task_done` event. The HUD shows
the milestone-style banner: **"Task complete: Every trainer in the Meadows"** with the
reward line beneath. If `voice.done` names a conversation, the named NPC's
`greeting_when` gains a branch `if_flag: task_rewarded:<id>` for it — the beat is *said*
by a person the next time the player talks to them, in the world, not by a pop-up alone.
`milestones` on a `tally` grant the same way at each `at`, each once
(`task_milestone:<id>:<n>`).

*Owns:* `scripts/world/quest_log.gd`, `autoload/game_state.gd` (the grant call),
`data/dialogue/village.json` and band dialogue files (the `voice` conversations, small).
*Tests:* `tests/test_task_feed.gd`: a reward is granted exactly once across
set/save/load/set; a milestone at 10 does not re-grant at 11; a reward naming a bad item
id fails the test suite. `tests/test_band_dialogue.gd` (extend): every `voice`
conversation exists and every `give:` it carries resolves.
*Fails if* a reward can be claimed twice, if a task's XP is awarded outside the ordinary
award (a second XP path is exactly what prompt 73 forbids), or if a done beat exists only
as UI.

### T-6 — Coexistence: the MAIN STORY card, the quest log and the controller

*Do:*

- **HUD.** One tracked line (MAIN STORY) as today; beneath it one transient sub-line
  shared by prompt 73's feed and this one. Nothing else is added to the world HUD. No task
  is ever the tracked line.
- **Quest log tab** (`scripts/ui/tab_quest_log.gd`): today two lists, Main Story (guided
  view) and Local Requests. *Do:* the second list becomes **Tasks** and shows every
  surfaced task with `n/total`, DONE state, and a tracked marker. The six shipped
  `objectives.json` `local` entries migrate into `tasks.json` as `find` tasks
  (§2.6) so there is one list, not two; `quest_log.gd::local_entries()` stays as an alias
  over the migrated set so `tests/smoke_local_requests.gd` keeps its meaning.
- **Tracking.** In the Tasks list, `menu_confirm` on a row toggles it as the **tracked
  task** (flag `task_tracked:<id>`, at most one; toggling another clears the first). The
  minimap draws the tracked task's pins *and* the MAIN STORY marker; the full map draws
  every surfaced task's pins with the tracked one emphasised. No new binding: confirm is
  already the row verb in every tab (`smoke_menu_owns_dpad.gd`). A dismissed tracked task
  (confirm again) draws nothing on the minimap and stays on the full map. Alpha pins (§2.3)
  always draw on the minimap regardless of tracking — CL-W1 asked for that specifically.
- **Nothing is ever "accepted".** A surfaced task is simply there. There is no
  accept/decline modal, no giver to return to unless `voice` says so, and no task can be
  failed or abandoned.

*Owns:* `scripts/ui/tab_quest_log.gd`, `scripts/ui/minimap.gd`, `scripts/ui/tab_map.gd`,
`data/progression/objectives.json` (removing the migrated `local` list only).
*Tests:* `tests/smoke_menu_focus.gd` / `tests/smoke_menu_owns_dpad.gd` (extend: confirm on
a task row toggles tracking and the d-pad stays the menu's); `tests/smoke_gate_a_map_cycle.gd`
(extend: the minimap draws the objective marker plus the tracked task's pin plus any alpha
pin, and no untracked task pin); `tests/test_quest_log.gd` (existing 38 must stay green;
`local_entries()` still returns the six).
*Fails if* the tracked line ever shows a task title, if a task needs an accept step, or if
tracking needs a new controller binding.

---

## 2. The authored instances

Two the owner named, four "like that". Every one is built from content that already
exists; the feed gives it a pin, a count, a reward and a voice.

### 2.1 T-7 — The relay shutdown chain ("Break the relay line")

*What is there:* one Tether Relay Station (Band 3, `tether_relay.gd`, `relay_site.json`,
`tether_relay.json`) with a four-fight ladder (Hess → Orrin → Dell → Vance, V-1..V-6) and
one console whose `requires_flag` is `relay_captain_defeated`; pressing it sets
`relay_disabled`, kills the conduits, withdraws the four decorative grunts
(`place_when: unless relay_disabled`) and — V-5 / CL-E12, owner answer 1, "yes" —
heals that relay's own three `drains.stations` (`relay_core`, `relay_yard`,
`relay_approach`) through `meadow_healing` filtered to those ids. The drain network has
**four groups** in `terrain_playground.json` `drains.stations`: the quarry
(`quarry_conduit_head` + three runs, Band 2), the relay (three, Band 3), the approach
(`approach_mouth` + six runs, Band 5) and `stronghold_works`. Bands 2, 4 and 5 already
have grunts standing at or near those groups: Dorn (quarry picket, 315,1668), the ridge
patrol (−235,6470) at the watchtower, Watchman Corr (−68,7140) at the approach mouth.

*Do:* **four relay stations, one per band from 2 to 5**, each a console the player can
only operate once that station's grunt is beaten. The Band 3 station is the shipped
compound; the other three are **a console on a small deck beside the existing station
hardware** (the quarry's conduit head, a new Band 4 pylon pair on the ridge, the approach
mouth), built by a new `scripts/world/relay_console.gd` that is `tether_relay.gd`'s
`_build_console` / `disable_relay()` / `_sync_console()` / `_heal_local_ground()` lifted
out into a reusable node reading a `relay_consoles` block in each band's `props.json`:

| Station | Band | Guard (existing trainer) | `requires_flag` | Console flag | Heals stations | Hardware |
|---|---|---|---|---|---|---|
| Quarry relay | 2 | `quarry_picket_dorn` (move Dorn from (315,1668) to the conduit head's own approach, ~(395,1790); still inside `test_chapter_curve`'s band) | `defeated_quarry_dorn` | `relay_quarry_disabled` | `quarry_conduit_head`, `quarry_run_1..3` (scatter and skin only — the quarry's colour map is baked, D45, and stays discoloured; recorded as the honest remainder) | the conduit head that stands there today (`old_quarry.json`) |
| River relay | 3 | Hess → Orrin → Dell → **Vance** (as shipped) | `relay_captain_defeated` | `relay_disabled` (as shipped) | `relay_core`, `relay_yard`, `relay_approach` (CL-E12, as shipped) | the compound (as shipped) |
| Ridge relay | 4 | `patrol_ridgeline` (Tether Patrol, at the watchtower, as placed) | `defeated_patrol_ridgeline` | `relay_ridge_disabled` | two **new** `drains.stations` entries at the watchtower spur (`ridge_run_1`, `ridge_run_2`, strength 0.5/0.6, radius 15) — scatter thinning is live at boot; the bake is optional and deferred | two pylons from the installed `tether_pylon` model (SF33) on the spur, conduit run between, lit until disabled |
| Approach relay | 5 | `stronghold_outer_watch` (Watchman Corr, at the mouth, as placed) | `defeated_stronghold_outer_watch` | `relay_approach_disabled` | `approach_mouth`, `approach_run_1..3` — the near half; the far half (`run_4..6`, `stronghold_works`) is the Warden's and heals on `legendary_freed` as today | the approach pylons (`stronghold.json::approach_pylons`) |

The task:

```json
{"id": "relay_line", "title": "Break the relay line", "kind": "chain",
 "flags": ["relay_quarry_disabled", "relay_disabled", "relay_ridge_disabled", "relay_approach_disabled"],
 "done_flag": "relay_line_broken",
 "surface": {"on_flag": "south_bridge_open"},
 "pins": [{"world": [404, 1804], "icon": "task", "clears_on": "relay_quarry_disabled"},
          {"world": [350, 3760], "icon": "task", "clears_on": "relay_disabled"},
          {"world": [-280, 6460], "icon": "task", "clears_on": "relay_ridge_disabled"},
          {"world": [-35, 7081], "icon": "task", "clears_on": "relay_approach_disabled"}],
 "reward": {"xp": 400, "items": [{"id": "elixir_vigour", "n": 1}], "flag": "relay_line_broken_rewarded"},
 "voice": {"surfaced": "quarry_foreman_relay_line", "done": "grandpa_relay_line_broken"},
 "how": "Beat the guard at each station, then {interact} at its console."}
```

Only the **next** unbroken station's pin draws (a `chain` draws one pin at a time), so the
feed leads the player down the line rather than dumping four diamonds on the map at the
bridge.

**Story-carried, as the owner asked:** the chain is voiced by people already on the
route. The Quarry Foreman — resited to the Old Quarry by C3 — surfaces it ("they run the
conduit off my quarry, and there's a man on the head of it"); Sela's rescue line already
says the relay feeds "whatever is at the far end"; Ren, the former Tether member (resited
to the wind ridge by C3), explains that a console only answers once its guard is down;
Grandpa's post-chapter line acknowledges the whole line broken. Each is one `greeting_when`
branch on an existing NPC; the shipped `objectives.json` main entries `disable_the_relay`
and `see_what_changed` are unchanged.

**What each shutdown does in the world, visibly:** conduits go dark
(`_kill_the_conduits()`, shipped for Band 3; `relay_console.gd` reuses it against the
station's own conduit holder), the station's decorative grunts withdraw (`place_when:
unless <flag>` on each site's people), and the ground within that station group's radius
heals over 12 s (`meadow_healing.apply()` filtered — CL-E12's mechanism, called with a
station-id list). That is "built into the story so you have that to do as you keep going":
every band has a machine you can turn off, and every one you turn off leaves grass
behind you.

*Owns:* `scripts/world/relay_console.gd` (new, lifted from `tether_relay.gd`),
`scripts/world/tether_relay.gd` (delegates its console to the new node; behaviour
byte-identical), `scripts/world/meadow_healing.gd` (a `station_ids` filter on `apply()`,
CL-E12's), `data/config/bands/band{2,4,5}_*/props.json` (`relay_consoles`, the ridge
pylons), `data/config/terrain_playground.json` (**two new `drains.stations` rows only** —
no bake required for the task to work; the ridge's baked discolouration is a later,
optional re-bake of one region), `data/config/bands/band2_stone_and_root/trainers.json`
(Dorn's position), `data/config/relay_site.json` and the band-4/5 people files
(`place_when` on decorative bodies), dialogue files for the four voice lines.
*Tests:* `tests/smoke_relay_station.gd` (must stay green byte-for-byte on Band 3);
`tests/smoke_relay_line.gd` (new): walk the four stations in order with the guard flags
set by real fights (`begin_trainer_battle` through the director, resolved by the harness's
existing fight driver), assert the console refuses before the guard flag and disables
after, assert the chain's pin moves to the next station, assert `meadow_healing.report()`
names exactly that station group healed and no other, assert `relay_line_broken` lands on
the fourth; `tests/test_task_feed.gd`: the chain counts in order (disabling station 3
before station 2 does not advance the count past 1 — the flags are still recorded, the
*chain* is ordered); `tests/test_chapter_content_map.gd` stays at ≤ 26 distinct names.
*Fails if* a station can be disabled with its guard standing; if the chain adds a fightable
trainer (the census forbids it and V-6 forbids one inside the Band 3 compound); if a
station's shutdown heals a group it does not own; if the Band 3 compound's own behaviour
changes at all; or if the far half of the approach heals before `legendary_freed`.

### 2.2 T-8 — Every trainer in the Meadows

*What is there:* 31 authored battle entries across the five band `trainers.json` files,
every one with a unique `defeat_flag` and `rechallenge: false`. The village three appear
twice (field fight + tournament round) under different ids and flags. Beating the Warden is
one of the 31.

*Do:*

```json
{"id": "every_trainer", "title": "Every trainer in the Meadows", "kind": "tally",
 "flags": ["<every defeat_flag in every band trainers.json, in band order>"],
 "done_flag": "every_trainer_beaten",
 "surface": {"on_flag": "tournament_won"},
 "pins": [{"from": "trainers", "filter": "unbeaten_within_300m", "icon": "foe"}],
 "milestones": [
   {"at": 10, "reward": {"items": [{"id": "potion_large", "n": 2}, {"id": "revive", "n": 2}]}, "flag": "every_trainer_10"},
   {"at": 20, "reward": {"items": [{"id": "orb_greater", "n": 3}]}, "flag": "every_trainer_20"},
   {"at": 31, "reward": {"xp": 600, "items": [{"id": "elixir_might", "n": 1}, {"id": "elixir_guard", "n": 1}], "flag": "every_trainer_31"}],
 "reward": {"flag": "meadows_champion"},
 "voice": {"surfaced": "tournament_halda_champion", "done": "grandpa_meadows_champion"},
 "how": "Anyone who offers a fight counts once. The tally is on the Tasks page."}
```

The `flags` list is **generated, not typed**: `tests/test_task_feed.gd` asserts it equals
the set of `defeat_flag`s across the five band files, so a band lane that adds an opponent
(inside the 26-name ceiling) fails the build until the tally includes them. The count
therefore reads **n/31 today** and moves with the content.

**Pins:** `from: trainers, filter: unbeaten_within_300m` — an unbeaten trainer the player
has come within 300 m of gets a `foe` pin that clears on their `defeat_flag`. That is
"things pop up on the map": the trainer road reveals itself as the player walks it, and a
beaten trainer's pin is gone — which is also A-2's Challenge-button fix seen on the map.
The 300 m is CL-W1's number, shared on purpose.

**Why it is a reason to fight everyone:** the milestones are recovery and catching
supply (potions, Revives, Greater Orbs) at 10 and 20 — the things C4's recovery scarcity
makes worth having — and the two permanent elixirs (D47: rare, capped, never sold, "belong
to the world — a dungeon, a captain, the stronghold") at 31. A player who fights every
trainer arrives at the Warden with a stronger five and more to catch with; a player who
does not is not blocked. Halda voices it after the tournament (she already hands over the
Revives and the saddle recipe — CL-G3 — so "you've beaten three; there are a lot more out
there" is her line), and Grandpa acknowledges the champion flag on the walk home.

*Owns:* `data/progression/tasks.json`, `scripts/world/trainer_npc.gd` (one static:
`all_defeat_flags()`), `data/dialogue/village.json` (Halda's and Grandpa's branch).
*Tests:* `tests/test_task_feed.gd` (generated list equals the data; every flag is set only
by a trainer win — walk `trainer_npc.gd`'s reward path in isolation); `tests/smoke_relay_line.gd`
(reuse: after the four guard fights the tally's count is exactly four higher);
`tests/test_trainers_data.gd` (extend: no `defeat_flag` is shared by two entries — the
tally depends on it).
*Fails if* the tally can exceed the number of authored opponents, if it counts a
rechallenge (there are none, and the test asserts it stays so), or if any milestone's
reward is a candy (the candy economy is the addendum's §B lane, placed in the world, not
handed out by counters).

### 2.3 T-9 — The alphas of the Meadows (CL-W1, pinned and tallied)

*What is there:* 16 `alpha`/`elder` entries across the band spawn files, each cleared
once by `wild_creature.gd`'s once-id mechanism (`tests/test_wild_once.gd`); the Warren
Guardian is a seventeenth on the dungeon's own clear flag. CL-W1 asks for a pin at 300 m
that clears on caught or beaten and is persisted.

*Do:*

```json
{"id": "alphas", "title": "Alphas of the Meadows", "kind": "tally",
 "flags": ["<every once-id flag of every alpha/elder spawn, plus warrens_cleared>"],
 "done_flag": "every_alpha_met",
 "surface": {"on_radius": {"of": "alphas", "m": 300}},
 "pins": [{"from": "alphas", "filter": "unclaimed_within_300m", "icon": "alpha"}],
 "milestones": [
   {"at": 4, "reward": {"items": [{"id": "orb_greater", "n": 2}]}, "flag": "alphas_4"},
   {"at": 9, "reward": {"items": [{"id": "revive", "n": 3}, {"id": "potion_large", "n": 2}]}, "flag": "alphas_9"},
   {"at": 17, "reward": {"xp": 500, "flag": "alphas_17"}}],
 "voice": {"surfaced": "sorrel_alpha_tracker_first", "done": "sorrel_alpha_tracker_done"},
 "how": "An alpha shows on the map once you are near it and stays until you catch it or beat it."}
```

The pin is CL-W1 exactly: it appears at 300 m, it **persists** (derived from the
`alpha_seen:<once_id>` flag that the radius check sets, so it survives save/load and never
depends on the marker cache), and it clears on the once-id flag, which
`wild_creature.gd` sets on **caught or beaten** (A-3 — no dismissal mechanic). The
minimap always draws alpha pins (T-6). Sorrel, the alpha tracker at the Pond, is the
voice; she already stands 100 m from the elder Mosshell.

*Owns:* `scripts/creatures/wild_creature.gd` (expose `once_flag()` per instance; already
computes it), `scripts/world/burrow_warrens.gd` (the guardian's once-id is `warrens_cleared`,
already), `data/config/bands/band1_lower_meadows/pond_npc.json` / `village_npcs.json`
(Sorrel's branches).
*Tests:* `tests/test_wild_alphas.gd` (extend: the generated flag list equals the alpha /
elder set in the spawn tables + the guardian); `tests/test_map_state.gd` (the alpha pin
appears at 300 m, survives save/load, clears on the flag); `tests/smoke_aggression.gd` or
a new `tests/smoke_alpha_pin.gd`: walk to 300 m of the Band 1 elder Mosshell, assert the
pin; beat it through the real fight, assert the pin is gone and the tally is 1.
*Fails if* a pin clears on anything but caught-or-beaten, if a pin does not survive a
load, if the tally can be completed without the guardian, or if the radius check ever
reveals an alpha's position **before** the player is inside 300 m (no radar).

### 2.4 T-10 — The Sigils, pinned (the captains on the map)

*What is there:* the MAIN STORY entry `defeat_the_captains` (`count_flags` on the three
captain defeat flags, label "Defeat the Upper Meadows captains. n/3") with a single
objective marker. Three captains at (170,5590), (−280,6460) and (−100,4350).

*Do:* a task that exists **only to give the main line three pins** — the feed's one
sanctioned way to add pins to a main objective without touching the main line:

```json
{"id": "sigils", "title": "The three Sigils", "kind": "tally",
 "flags": ["defeated_captain_riverwatch", "defeated_captain_field", "defeated_captain_ridge"],
 "done_flag": "hall_approach_open",
 "surface": {"on_flag": "mill_crossing_restored"},
 "pins": [{"world": [-100, 4350], "icon": "foe", "clears_on": "defeated_captain_riverwatch"},
          {"world": [170, 5590], "icon": "foe", "clears_on": "defeated_captain_field"},
          {"world": [-280, 6460], "icon": "foe", "clears_on": "defeated_captain_ridge"}],
 "voice": {"surfaced": "relay_captive_freed"}}
```

`done_flag` is the main entry's own flag, set by the Sigil gate when all three keys turn;
the task carries **no reward** (the Sigils are the reward) and no milestones. Its whole
job is that the full map shows three diamonds in Band 4 the moment the crossing opens,
each clearing as a captain falls, so "2/3" on the tracked line has a *where*. Sela's
rescue line already names the three; that conversation is the surfacing voice with no
new text.

*Owns:* `data/progression/tasks.json` only.
*Tests:* `tests/test_task_feed.gd`: a task whose `done_flag` is a main entry's flag is
DONE the moment the main entry is, and vice versa; `tests/test_gateb_objective_chain.gd`
/ `tests/test_quest_log.gd`: the main line's label and `count_flags` are unchanged.
*Fails if* the Sigils task ever carries a reward or an extra flag, or if the main entry is
edited to make it work.

### 2.5 T-11 — The rare node surveys (Rootstone, then Ironwood)

*What is there:* D72 makes every authored harvest node one-time, flagged
`harvest_node:order:<n>`. Band 2 authors 5 Rootstone and 5 Ironwood nodes; Band 3 authors
3 Rootstone and 4 Ironwood; Band 4 authors 10 Ironwood. The band-2 nodes are inside the
quarry and the warrens' branch chambers, which is the off-path exploration the owner is
asking to be rewarded.

*Do:* two `tally` tasks, generated from the harvest tables by `item` and band:

- **"Survey the Rootstone"** — the 8 Rootstone nodes of Bands 2–3; surfaces on
  `south_bridge_open`; pins `from: harvest, filter: rootstone_ungathered_within_300m`;
  milestone at 4 (`{"items": [{"id": "saddle_frame", "n": 1}]}` — half the saddle, C1's
  own unlock, handed to a player who went and looked); done reward at 8:
  `reinforce_axe`'s recipe flag if it is flag-gated, else `orb_greater ×2`. Voice: Maren,
  the field researcher at the pond ranger station (C3 keeps her there).
- **"Survey the Ironwood"** — the 19 Ironwood nodes of Bands 2–4; surfaces on
  `mill_crossing_restored`; milestone at 8 (`potion_large ×2`, `revive ×2`); done at 19
  (`xp 400`, `elixir_guard ×1`). Voice: Ada, the craftsperson resited to the Band 2 ranger
  camp by C3, whose rest point already offers crafting.

Counts are generated and asserted the same way as T-8's, so a density lane adding nodes
moves the totals rather than breaking the tally.

*Owns:* `data/progression/tasks.json`, `scripts/world/harvest_node.gd` (expose the flag id
it already derives), NPC dialogue for the two voices.
*Tests:* `tests/test_task_feed.gd` (generated node lists match `harvest.json` by item and
band; a gathered node advances exactly once; `test_harvest_permanence.gd`'s replay-on-load
keeps the count after a load); `tests/smoke_gate_a_rest_torch.gd`-style smoke: gather one
Rootstone node through the real tool swing and assert the count is 1.
*Fails if* a survey counts a node that respawns (none do — D72 — and the test asserts the
counted set is the permanent set), if a pin reveals a node the player has not been within
300 m of, or if the milestone hands out Rootstone itself (the survey rewards *going*, not
the material; the material is at the node).

### 2.6 T-12 — The camping chain (with C4)

*What is there:* six authored rest points across the bands (`props.json` `rest` blocks:
Band 1 trail camp (345.6,935.4), Band 2 ranger camp (−256.4,2260.1), Band 3 riverwatch
rest (215.3,3697.0), Band 4 watchtower (−239.1,6472.2) and wind-ridge (276.7,5652.5), Band
5 approach (−21.0,7456.6)), each with a creature bed, each calling
`night_rest.pass_the_night()`, which sets `player_slept_at_home` and nothing else specific
to the site.

*Do:* `rest_point.gd` sets `rested_at:<cluster_id>` on a completed night at that site
(`night_rest.pass_the_night()` gains an optional `site_id` argument; the buildable
`camp.gd` passes none). Then:

```json
{"id": "camps", "title": "Sleep at every camp on the road", "kind": "tally",
 "flags": ["rested_at:trail_camp", "rested_at:ranger_camp", "rested_at:riverwatch_rest", "rested_at:wind_ridge_rest", "rested_at:watchtower_rest", "rested_at:approach_rest"],
 "done_flag": "every_camp_slept",
 "surface": {"on_radius": {"of": "rest_points", "m": 60}},
 "pins": [{"from": "rest_points", "filter": "unslept_within_300m", "icon": "task"}],
 "milestones": [{"at": 3, "reward": {"items": [{"id": "travel_pack", "n": 1}]}, "flag": "camps_3"}],
 "reward": {"xp": 300, "items": [{"id": "elixir_vigour", "n": 1}], "flag": "every_camp_slept_rewarded"},
 "voice": {"surfaced": "wilhelm_trail_camp_host", "done": "wilhelm_trail_camp_done"},
 "how": "A night at a camp with a bed clears strain your team cannot rest off on the road."}
```

Wilhelm, the innkeeper resited by C3 to the Band 1 trail camp, is the host. The `how`
line names C4's strain mechanic, which is what makes this a *reason* and not a checklist:
each authored camp is where the road's attrition gets cleared, and the chain pins the
next one. The camps stay places you *want* to stop (`MEADOWS_MACRO_LAYOUT.md` §5,
"Camps"); the task only tells you where they are.

*Owns:* `scripts/world/rest_point.gd`, `scripts/world/night_rest.gd` (the optional
argument), `data/progression/tasks.json`, dialogue for Wilhelm.
*Tests:* `tests/smoke_authored_camps.gd` (extend: a night at the trail camp sets exactly
`rested_at:trail_camp` and `player_slept_at_home`; a night at the buildable camp sets
only the latter); `tests/test_task_feed.gd` (the six ids match the `rest` blocks with an
id; a `rest` block without an id fails the build).
*Fails if* a buildable camp counts toward the chain (the chain is about *the road's*
camps), or if any rest point lacks the id the tally needs.

### 2.7 The six shipped Local Requests migrate

`objectives.json`'s `local` list (Old Bram, Rae's herd, Coll's cart, the night watch,
Doss's nest, the stolen Meadowhart) becomes six `find` tasks in `tasks.json` with the
same labels and flags, `surface: on_radius 300 m of the giver`, one pin at the giver's
position clearing on the flag, and no reward (their rewards are already in their
dialogue). `quest_log.gd::local_entries()` returns exactly these six so
`smoke_local_requests.gd` is unchanged in meaning.

*Fails if* any of the six changes label, flag or reward in the migration.

---

## 3. Save fields

**None new.** Every piece of state is one of:

| State | Where | Persisted by |
|---|---|---|
| surfaced | flag `task_surfaced:<id>` | progression store (save VERSION 3+) |
| progress | the task's own `flags` (defeat flags, once-ids, harvest ids, console flags, rest ids) | already persisted by their owners |
| done | `done_flag` | progression store |
| milestone / reward claimed | `task_milestone:<id>:<n>`, `task_rewarded:<id>` | progression store |
| tracked | `task_tracked:<id>` | progression store |
| alpha seen | `alpha_seen:<once_id>` | progression store |
| pins | derived; `map_state.dynamic_markers` is a cache corrected on load by `sync_pins` | `map_state.save_data()` (already) |

`tests/test_save_format.gd` (extend) round-trips a save with every flag kind above and
asserts `task_entries()` and `sync_pins()` reproduce the pre-save state. `save_game.gd`'s
`VERSION` does not move.

*Fails if* the feed adds a key to `save_game.gd`'s dictionary, or if any feed state lives
anywhere but the flag store and the marker cache.

---

## 4. Controller-first UI, stated once

- No new input action. Confirm tracks; back leaves; the d-pad stays the menu's.
- The banner and sub-line are read-only and never take focus or block input.
- Every string is data; every `how` uses input-action tokens resolved by
  `input_glyph.gd`, swept by `tests/test_input_glyph_verbs.gd` (extend the sweep to
  `tasks.json`).
- On the Ally at 1280×720 the Tasks list shows at least six rows without scrolling and
  the row's `n/total` is legible at `hud_scale.gd`'s handheld floor
  (`smoke_hud_handheld_legibility.gd`, extend).

---

## 5. Implementation slices

| Slice | Do | Owns | Tests | Size |
|---|---|---|---|---|
| **C2-S1 model** | T-1, T-2 (surfacing rules), T-5 (reward maths), §3 | `data/progression/tasks.json`, `scripts/world/quest_log.gd`, `autoload/game_state.gd` (ticks + grant) | `tests/test_task_feed.gd` (new), `tests/test_quest_log.gd`, `tests/test_save_format.gd` | M |
| **C2-S2 pins** | T-3, the three icons, `sync_pins` | `autoload/map_state.gd`, `data/config/map_landmarks.json`, `assets/ui/icons/map/`, `scripts/ui/minimap.gd`, `scripts/ui/tab_map.gd` | `tests/test_map_state.gd`, `tests/test_map_icons.gd`, `tests/smoke_gate_a_map_cycle.gd` | M |
| **C2-S3 surfaces** | T-4, T-6: the sub-line, the Tasks tab, tracking; migrates the six local entries (§2.7) | `scripts/ui/playground_hud.gd`, `scripts/ui/tab_quest_log.gd`, `data/progression/objectives.json` (`local` removed) | `tests/smoke_objective_hint_card.gd`, `tests/smoke_menu_owns_dpad.gd`, `tests/smoke_local_requests.gd`, `tests/smoke_hud_handheld_legibility.gd` | M |
| **C2-S4 relay line** | T-7: `relay_console.gd`, three stations, the healing filter, Dorn's move, four voice lines | listed under T-7 | `tests/smoke_relay_station.gd` (unchanged, green), `tests/smoke_relay_line.gd` (new), `tests/test_chapter_content_map.gd` | L |
| **C2-S5 tallies** | T-8, T-9, T-10, T-11, T-12: generated flag lists, once-flag exposure, rest ids, voices | listed per task | `tests/test_wild_alphas.gd`, `tests/test_trainers_data.gd`, `tests/test_harvest_permanence.gd`, `tests/smoke_authored_camps.gd`, `tests/smoke_alpha_pin.gd` (new) | M |

**Order:** S1 → S2 → S3 are sequential (each builds on the last); S4 and S5 are parallel
after S1 and each may land before S2/S3 (a task with no pin drawn yet is still a task).
**S1 depends on prompt 73's progression feed queue** (CL-W6) or ships a stub with the
same push/drain shape that prompt 73 then replaces. **S4 must land after CL-E12**
(`meadow_healing` filtered to the relay's stations) — it generalises that filter.

**Density first.** `docs/FINISH_THE_MEADOWS.md`'s dependency stands: the feed sends players
to Bands 2–5. If those bands are still 23 spawns and 8 nodes, the pins point at empty
ground. C2-S4/S5 ship after the density pass has landed at least Bands 2 and 3, or their
pins are worse than none.

---

## 6. What this deliberately does not do

- No task ever gates a main objective, a gate, a trainer or a shop.
- No daily, repeatable, timed or randomly generated task. Every task is authored, finite
  and once per save.
- No task rewards a candy (addendum §B: candy is placed in the world).
- No "abandon", "fail", "decline" or "accept".
- No new HUD element beyond the shared sub-line; no new controller binding.
- No pin for anything the player has not been within 300 m of or been told about by a
  flag.

---

## 7. Evidence the band lanes score

On a continuous run from the tournament to the Hall, without reading any document, a
tester can name at any moment: the main objective (the card), one thing to do off the
road (a pin), and how far along it they are (a count). At least three tasks surface
between the South Bridge and the river without a menu being opened. Every relay they shut
down leaves grass behind them and a person on the road who says so. The alphas they met
are on the map until they catch or beat them, across a save and a load. The tally of
trainers they beat reads the same number after the Warden as the number of fights they
had. Nothing on the map points at something they have not been near.
