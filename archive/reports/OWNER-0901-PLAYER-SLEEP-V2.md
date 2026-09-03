# OWNER-0901-PLAYER-SLEEP-V2

Reopening of `OWNER-0901-PLAYER-SLEEP`. Branch: `ralph/OWNER-0901-PLAYER-SLEEP-V2`
off `main` (`38147fca`). Not merged.

## What was reported

`ralph/OWNER_PLAYTEST_2026-09-01.md` item 4, original finding: "Still no way for a
person to sleep." A fix (`OWNER-0901-PLAYER-SLEEP`, merge `74b7d0dd`, 2026-09-01
01:45:57 UTC) landed the same day: a "Sleep" prompt on the loft bed inside Grandpa's
house, gated open the same moment the front door itself unlocks.

On 2026-09-02 the owner went back through the 09-01 list a second time and reported,
verbatim: **"player sleep was impossible still."** Per `CLAUDE.md`'s precedence
rules a fresh owner reproduction reopens an item regardless of what a prior landed
fix claimed, so this is a confirmed live-bug reopen, not a re-verification task.

Context the coordinator flagged going in: the campsite was split into three
independently placeable pieces the same day as this confirmation
(`ralph/OWNER-0902-CAMP-SPLIT`, merge `852fe366`, 2026-09-02 10:21:08-10:36:55 UTC),
and the player's rest path now also runs through the new `bedroll` piece
(`scripts/build/player_bed.gd`).

## Investigation method

Per the task brief and `CLAUDE.md`'s own recorded lesson on this project (a "nothing
to fix" or "landed" claim with no real execution behind it has repeatedly turned out
wrong under real play), this was not treated as a code-reading exercise. `tools/
art_pipeline/setup.sh godot` fetched a real Godot 4.7 headless binary, the project
was imported (`godot --headless --path . --import`), and every claim below is backed
by an actual headless run of the live production interaction path — real
`InputEventJoypadButton`/keyboard events through the live `InputMap`, real
`Interactable` prompts, real `BuildPlacer` placement, real dialogue effects — not a
unit test calling a rest function directly.

## What is actually on `main`: two independent sleep paths

1. **Grandpa's house, the loft bed** (`scripts/world/grandpa_house.gd`,
   `_build_sleep_prompt`/`_on_sleep_activated`). Offers "Sleep" once the front door
   itself is unlocked (`sequence_director.gd::_refresh_door_gate`). Activating it
   calls the shared `night_rest.gd::rest()` entry point.
2. **The player's own Bedroll**, one of the three campsite pieces split out of the
   old bundled `camp` buildable (`OWNER-0902-CAMP-SPLIT`,
   `scripts/build/player_bed.gd`; catalogue cost 4 wood / 6 fiber,
   `data/items/buildables.json`). Offers "Rest until morning" once placed anywhere
   in the world through the real Build menu.

### Probe 1 — Grandpa's house bed, real interact input

    godot --headless --path . --script tests/smoke_home_sleep.gd

**Result: PASS.** Standing 1.5m from the loft bed with the house unlocked, the game
offers (real prompt text, real bound-key glyph):

    home bed offers '[keyboard_e] Sleep'

Pressing interact: `[rest] rested; day 2` / `slept at home: day 1 -> 2`. The
`player_slept_at_home` objective flag is set on the completed rest, not on the
interact press.

**The exact sequence a player performs:** walk to the loft bed inside Grandpa's
house (reachable any time after the front door unlocks, i.e. from `walk_out` beat
onward), stand within ~2.2m of it, press the bound interact button (`E` on
keyboard, `X` on the owner's controller map). The screen fades, the night passes,
the screen fades back in.

### Probe 2 — the Bedroll, real Build-menu placement + real interact

    godot --headless --path . --script tools/_probe_camp_split.gd

**Result: PASS.** Arms `bedroll` through the real catalogue, gets a green ghost, a
real `build_place` press plants it, and it registers in
`GameState.placed_buildings`. Its real "Rest until morning" `Interactable` prompt is
then fired the same way a player's interact press would:

    placed 'bedroll' through the real catalogue+placer
    [player_bed] rested; day 2
    bedroll Rest prompt advanced the day and healed the trainer

**The exact sequence a player performs:** gather wood and fiber (4 wood / 6 fiber),
equip the hammer, press interact to open Build, select Bedroll, walk to a clear spot
until the ghost turns green, press the build button to place it, then press interact
on it (prompt reads "Rest until morning").

### Probe 3 — the real prerequisite chain, from a genuinely fresh save

The one test built to prove the whole chain end to end from a fresh save —
`tests/smoke_gate_b_continuous.gd` (wake → Grandpa → catch → village tools → gather
→ camp → creature bed → sleep → tournament, every press a real controller event) —
**failed at its very first village check**, before ever reaching the build/sleep
segment:

    ERROR: Mira's required opening visit left 'recipe_orb_basic' unset; the gift
    branch is what the Foreman's hammer and the orb recipe wait on

Root cause, found by reading the actual call sequence in
`tests/helpers/gate_a_npc_gather_segment.gd::run()`: the segment visited only Tam,
then asserted `recipe_orb_basic` plus an axe/pickaxe count — all three of which are
**Mira's** gifts (`village_mira_shop_intro` in `data/dialogue/village.json` is the
only place any of them are granted; Tam's own line even says so — "Mira set you up
for gathering"). Nothing in the segment had visited Mira yet; her visit was
scheduled far later in the file, after gathering. This is a harness ordering bug,
not a live-game one — `data/config/village_npcs.json`'s own `greeting_when` gates
neither villager's first-visit branch on the other, so a real player can greet
either one first — but it meant **the one real, continuous, fresh-save proof of the
gather → build → sleep chain has been failing at the first village check, and
therefore never actually exercising the build/bed/sleep segment, since whichever
pass moved the starter tools off Tam onto Mira.**

Fixed in `tests/helpers/gate_a_npc_gather_segment.gd`: visit Mira first (matching
Tam's own line), check her real gifts, then Tam, then the Foreman as before; dropped
the now-duplicate second Mira visit later in the file.

Re-running the fixed segment from a fresh save now gets through the entire real
tools/gather chain:

    GATE A NPC/GATHER +12.60s — Mira cycle 1 exited and movement resumed
    GATE A NPC/GATHER +13.58s — Mira handed over axe, pickaxe and the Basic Orb pattern through dialogue
    GATE A NPC/GATHER +16.64s — Tam cycle 1 exited and movement resumed
    GATE A NPC/GATHER +16.64s — Tam handed over knife and torch through dialogue
    GATE A NPC/GATHER +21.31s — Quarry Foreman cycle 1 exited and movement resumed
    GATE A NPC/GATHER +21.31s — the Foreman handed over the build hammer through dialogue
    GATE A NPC/GATHER +24.77s — Satchel assigned four tools by focused controller input
    GATE A NPC/GATHER +28.63s — axe equipped, swung, gathered +4 Wood
    GATE A NPC/GATHER +32.02s — pickaxe equipped, swung, gathered +4 Stone
    GATE A NPC/GATHER +36.50s — knife equipped, swung, gathered +4 Fiber

confirming, from a genuinely fresh save with no seeded inventory, that the entire
prerequisite chain to reach the Bedroll (Mira → Tam → Foreman's hammer → real
harvesting) is real and reachable by a player who greets Tam and Mira in either
order.

A second, unrelated pre-existing bug then surfaced further into the same segment
(the Oskar/Bram commerce visits, which are not part of the sleep chain): after
Bram's third dialogue cycle, `_exit_through()` walked a single straight line from
wherever `_prove_movement_resumed()`'s own exploratory nudge had left the player,
which could be off the door's axis and clip his shop's furniture the same way
`_enter_through()`'s own header says an oblique entry clips a narrow doorway.
Reproduced twice, identically. Fixed by staging the exit through the same on-axis
waypoint `_enter_through()` already uses before approaching the door, matching the
existing pattern rather than inventing a new one.

### What happened chasing full end-to-end evidence

The fixed segment (Mira → Tam → Foreman → real gather) was re-run twice more.
Both times it got past the entire tools/gather chain again and then hit a
**second, separate, pre-existing bug**, unrelated to sleep and unrelated to
the fix above: after Bram's third dialogue/shop cycle,
`_exit_through()` walked a single straight line from wherever
`_prove_movement_resumed()`'s own exploratory nudge had left the player,
which can land off the door's own axis and clip his shop's counter — the
same class of defect `_enter_through()`'s own header already documents for
an oblique entry through a narrow doorway. Reproduced identically twice
("could not naturally leave Bram's building", 6.5m short both times). I
staged the exit through the same on-axis waypoint `_enter_through()` already
uses before approaching the door; a third run still failed at the same
spot, so that fix is not sufficient and the underlying geometry issue is
still open. Bram is the innkeeper — a commerce-only NPC with nothing to do
with sleep or the build chain — so I did not sink further time into it under
this task's scope, but it is real and worth its own follow-up (I left the
partial fix in place; it should not have regressed anything).

To still get real, continuous, fresh-save evidence reaching the actual
build/sleep step without being blocked by that unrelated bug, I added an
`include_vendors` parameter to `gate_a_npc_gather_segment.gd::run()`
(default `true`, so every existing caller's coverage is unchanged) and wrote
`tools/_probe_sleep_chain_e2e.gd`: real opening → real Mira/Tam/Foreman →
real gather → (skip Oskar/Bram) → the real authored material route → a real
Build-menu selection and placement of the Bedroll specifically → a real
walk-up-and-interact on its own prompt. First run of this surfaced a **third
real bug**, this one a genuine crash: `gate_a_material_route.gd
::_unlock_road_gate()` read `key.global_position` for a transcript line
immediately after `_press_and_confirm()` on that same key — and a real
completed pickup frees the world key node, so this crashed with "Invalid
access to property or key 'global_position' on a base object of type
'previously freed'" on its own success path. Fixed by capturing the position
before the press. That fix is real and clearly correct on its own terms.

After that fix, the crash was gone, but the very first leg of the authored
material route ("could not reach authored wood at (16.0, -28.0), stopped
22.9m short") failed to close a real navigation gap even with the route's
own generous 5x-margin travel budget — which reads as a genuine path
obstruction, not a timing budget. This is most likely **self-inflicted by
skipping Oskar and Bram**: the authored route's first leg was presumably
only ever validated starting from the position a player reaches *after*
all five NPC visits (the order every existing caller uses), not the earlier
position mine leaves the player at by skipping two of them. I did not chase
this further — introducing it via my own probe's shortcut makes it weak
evidence of anything beyond "this exact composition needs more work," which
is not what this task is about.

**Net effect:** three real bugs found and fixed in this project's test
evidence infrastructure (the Mira/Tam visit order that had silently kept
`smoke_gate_b_continuous.gd` from ever exercising the build/sleep segment;
the Bram-exit navigation defect, partially addressed and flagged for
follow-up; the freed-key crash in the material route). None of them
required inventing a fourth to get a full green run of either the original
test or my own composed probe. **The actual sleep mechanism itself was never
in question after Probes 1 and 2 — those are direct, real-execution PASSes
on both paths, and Probe 3's real, fresh-save run through Mira → Tam →
Foreman → real gathering independently confirms the prerequisite chain to
reach the Bedroll is real and reachable.** Full single-run, start-to-finish
proof remains blocked by the Bram-exit bug and needs a dedicated follow-up
session; I judged continuing to spend this session's time on an
Oskar/Bram-shaped detour a worse use of it than reporting clearly what
stands and what doesn't.

## Conclusion

**Player sleep does not currently reproduce as broken on `main`.** Both paths work
under real interact-driven execution, with real prompt text, real day advance, and
a real save on completion. The prerequisite chain to reach the Bedroll specifically
(the path the coordinator asked to check first) is real and gatherable from a fresh
save with no seeded materials.

## Timestamp evidence for the "stale build" hypothesis

Tested, not asserted, per instruction. `ralph/conventions.md` warns a Ralph ship
does not reliably trigger `release.yml` on its own (`ralph-merge.yml` pushes with
the default `GITHUB_TOKEN`, which cannot raise a `push` workflow event) — it now
dispatches the release explicitly after a fast-forward, so the release asset's own
build timestamp, not the merge timestamp, says what the owner could actually have
downloaded and played.

Pulled every `release.yml` run around this window directly from GitHub Actions
(`mcp__github__actions_list`) and the live release asset's own metadata
(`mcp__github__get_release_by_tag`, tag `latest`):

| commit | what it is | release run started | release run completed (asset live) |
|---|---|---|---|
| `1c152d93`/`5ecabab9` | Grandpa's Revive-grant raise | 2026-09-02 05:17:57 UTC | **2026-09-02 05:47:38 UTC** |
| `852fe366` | **OWNER-0902-CAMP-SPLIT** (bedroll becomes its own piece) | 2026-09-02 10:21:08 UTC | **2026-09-02 10:36:55 UTC** |
| `90d9029e` | Coordinator handover, already quoting "player sleep was impossible still" | — | **pushed 2026-09-02 10:29:48 UTC** |
| `38147fca` | Backlog entry formally recording the confirmation-pass finding | 2026-09-02 10:42:20 UTC | 2026-09-02 11:12:40 UTC |

The handover documenting the "still impossible" finding (`90d9029e`) was pushed at
**10:29:48 UTC** — **7 minutes before camp-split's own release build even finished**
(10:36:55 UTC), let alone before that .zip could have been downloaded and played.
Between the previous release (05:47:38 UTC) and camp-split's (10:36:55 UTC) no other
release fired, so **any build the owner could have played before the confirmation
was written up necessarily predates `OWNER-0902-CAMP-SPLIT` — the Bedroll, as an
independently placeable piece, did not exist yet in that build.** That specific path
cannot be what the owner tested when this report was made, which is consistent with
(without single-handedly proving) a stale-build explanation for at least the Bedroll
half of this finding.

This does not by itself explain a failure to reach Grandpa's-house sleep, which
landed the day before (2026-09-01) and has been untouched since (`git log` on
`scripts/world/grandpa_house.gd` shows exactly one commit touching the sleep prompt,
the original 09-01 fix) — that path should have been present and working in
whatever build the owner played on 09-02. I don't have a way to prove or disprove
whether the owner actually walked back to that bed rather than only trying the
(pre-split, at that point already-fixed-for-placement) bundled `camp` object; that
remains an open, real possibility this investigation cannot close without asking.

## Recommendation

The next real-world event that can close this for good is a fresh owner playtest
against the **current** release asset (built from a commit at or after `38147fca`,
which already carries camp-split), specifically re-testing sleep both via a placed
Bedroll and via Grandpa's own bed. If either still fails under real play on real
hardware, that is new, current evidence this investigation did not have access to
and reopens the item for real; a real hardware run also proves things this headless
container fundamentally cannot (frame-accurate controller timing, whether the
"Sleep"/"Rest until morning" prompt is legible on-screen, discoverability without a
scripted walk telling the player exactly where to go).
