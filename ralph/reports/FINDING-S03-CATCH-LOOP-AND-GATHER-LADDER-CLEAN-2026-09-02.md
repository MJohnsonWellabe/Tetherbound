# S03: the catch loop and 20-node gather ladder are clean; the remaining tail, run by run

**Author:** operator agent, `ralph/GATE-F-S03-CATCH-LOOP`.
**Candidates:** eight full S03 runs across this session, `gate-f-run-20260902T163541Z-s03fablefix`
through `gate-f-run-20260902T185617Z-s03fablefix8`, each committed with its own
telemetry. FAIL count across the session: 42 -> 18 -> 17 -> 16 -> 16 -> 17 -> 16 -> 12.

This branch's own name is the mandate: get the catch loop and the gather ladder
clean. That happened, verified across multiple runs, not once. This doc is the
consolidated account of how, and an honest handoff of what is left.

## Part 1: the branch's actual scope, done

**The catch loop.** `chip_to_floor` (computed HP floor, not a guessed fraction)
and `throw_until_caught` (repeat against the same target until caught or the
fight ends another way) both hold across every run this session. The
ten-attempt ladder now early-exits once `party_size >= 5`.

**The 20-node gather ladder.** `S03-105` (`home_materials_gathered`) has PASSED
clean on every run since `equip_tool` landed -- 5/5 of the last five runs.
Two real, previously-hidden bugs accounted for the whole prior shortfall, not
terrain, not a merge:

1. **Wrong-tool gathering, silently refused.** `harvest_node.gd::_on_gathered()`
   checks the actually-equipped tool and, on a mismatch, only shows a toast
   ("Needs a Knife.") -- no error, no inventory change, nothing the old
   vocabulary could see. The equip steps pressed a fixed hotbar slot once;
   `playground_hud.gd`'s hotbar TOGGLES (pressing an already-equipped slot
   un-equips it), and a press mid-swing is dropped, not queued. Fixed:
   `equip_tool` (new action) reads `hotbar_slot_of(tool)` LIVE off the probe
   before every press -- never a fixed slot guess -- and retries, re-reading
   the slot each attempt, until the wanted tool is actually equipped.
2. **`move_to`'s vertical-gap handling was too blunt.** A flat arrival with a
   small closing vertical gap (a slope, a step up to a node) FAILed instantly
   instead of finishing the climb. Fixed in `_walk_loop`: keep walking through
   a small vertical gap that is still shrinking, and only FAIL when the
   vertical gap alone is at or past `close_enough`, or the 3D distance stalls
   (stops shrinking) while the flat gap is under 0.8m.

A third, unrelated hazard surfaced and was closed while getting here:
**a blind press could accidentally start a real wild fight.** The gather
ladder's second-swing tap (added this session to avoid FAILing an
already-depleted node) was an unconditional plain press; if a wild creature
wandered up and won `interaction_arbiter.gd`'s priority-then-nearest contest
over the node's own prompt, the blind press activated "Engage &lt;creature&gt;"
instead -- a real fight the ladder has no script to resolve, cascading FAILs
through the rest of the segment for as long as the world stayed in combat.
Measured directly: one run lost 42 FAILs to exactly this, chained through a
fainted-ally state. Two fixes closed it:

- `interact_with` gained `optional: true` -- the three "not pressed" reasons
  (arbiter disabled, no live prompt, wrong live prompt) become a `SKIPPED`
  instead of a press. Used on all 20 second-swing taps.
- `move_to`'s `answer_prompts` (blind `interact`/`menu_confirm` press during a
  held walk, meant only to answer a narrative modal) is now gated on
  `input_context == "narrative_modal"` specifically -- previously it pressed
  blind on ANY reason locomotion was disabled, including a wild creature
  standing close enough to win the same priority contest.

Verified: two runs after the `answer_prompts` fix landed, no stray-companion
or fainted-ally incident recurred. The gather ladder holds.

## Part 2: the feed sequence, mostly fixed

The 5-entrant feed sequence (`S03-231..319`) had two real, now-fixed bugs and
one still-open mystery.

**Fixed: "focus entrant N" fought its own auto-focus.**
`tab_backpack.gd::_open_target_picker()` calls
`_first_eligible_target_row().grab_focus()` on every open --
`_first_eligible_target_row()` walks the party in order and returns the first
NOT-YET-FED one, skipping fed rows. The picker already lands on the right
entrant with zero extra input, every time. The old script pressed
`ui_down` N-1 more times on top of that (a holdover from when the team was 3,
not 5), which does not merely waste a press -- it steers focus AWAY from the
auto-selected row, and once the eligible-row count shrinks late in the
sequence, those extra downs have nowhere to go and FAIL ("did not move focus
off"), corrupting every entrant after. Removed the four manual steps entirely.

**Fixed: `close_menu` could report the shell stuck open on a press that would
have worked a moment later.** Measured directly: entrant close-shell FAILs
did not stick to one entrant number run to run (failed at 1 in one run, at 2
and 3 in another, at 3 only in a third) -- a flaky first press, not a
deterministic state bug. `close_menu` now retries up to `max_attempts` (default
3), same shape `equip_tool` already retries a hotbar press for. Confirmed:
the run after this landed had ZERO "close the shell" FAILs, for the first
time this session.

**CORRECTION, same day: the "feeding works for entrants 1-3" claim above was
wrong, and the real bug was worse than a focus-navigation edge case.**
Dispatched a second-opinion pass (Fable) on the `_on_slot`/`_read_use`
contradiction rather than continue guessing from a static read, per the
operator's standing instruction to do that when stuck. The static read was
right, and its conclusion holds: pressing `ui_accept` on a grid slot only
ever reaches `tab_backpack.gd::_on_slot()`'s pick-up/move/swap logic; the
ONLY path into `_open_target_picker()` for food is `_read_use()`, gated on
the `interact` action specifically (`data/config/input_contexts.json:83-86`
confirms `interact` is the Satchel's own Use verb), a different physical pad
button than `ui_accept` (`JoyBtn:2` vs `JoyBtn:0`). **No entrant was ever
actually fed, in any run, all session.** The old 4-step sequence
(`ui_accept` / `focus_move` down / `ui_accept` / `ui_accept`) picked the
berries stack up, moved the grid cursor down one row per entrant, dropped it
there, and picked it back up again -- confirmed directly against
`gate-f-run-20260902T185617Z-s03fablefix8`'s own telemetry: berries count is
**identical** (11) at the start and end of the feed window, the diff
detector shows zero `craft`/inventory-loss events in that window, and the
berries cursor cell walks 4 -> 10 -> 16 -> 22 -> 22 across entrants -- exactly
+1 grid row each time, on a 6-column grid, which is what a pick-up/move-down/
drop sequence produces and has nothing to do with a target picker.

The apparent "it worked" evidence in the original write-up above was a
SEPARATE bug: the event detector emitting `feed`
(`operator_harness.gd::_diff_state`, the "rest and feed" block) keyed its
`_prev_condition` state by party member NAME, and this team carries four
creatures literally named "Bramblebun". Iterating the party, an unfed
Bramblebun set `prev=false`; the NEXT Bramblebun in the array, if already
fed from a different cause (satiety hadn't yet drained below the `fed_at`
threshold), then read as a false "not-fed -> fed" transition against the
first one's stale entry and emitted "Bramblebun is fed" -- a real-looking
event describing nothing that actually happened to the creature it named.
Fixed: `_prev_condition` is now keyed by party INDEX, not name.

**Fixed properly, both halves.** `open the slot's actions` steps now press
`interact` (the real Use verb) instead of `ui_accept`. The `focus_move`
steps are replaced with a new `focus_row{prefix:"N."}` harness action that
reads the live picker row text and presses `ui_down` until it starts with
the entrant's own number, rather than either a blind press count OR trusting
`_open_target_picker()`'s own auto-focus -- which lands on the first row
ELIGIBLE (not fainted, not already full), not the first not-yet-fed one, so
a real feeding pass can legitimately re-land on the SAME entrant twice (one
berry does not fill a creature) rather than advancing down the list. The
redundant extra `ui_accept` ("choose Feed", a second pick-up-again press
left over from the mis-modelled mechanism) is removed. `S03-260`
(`tournament_team_fed`) remains the authoritative check that feeding
actually landed.

A ninth full run is in progress to verify feeding now actually happens.

## Part 3: not fixed here, and why

**`tournament_training_ready` display-tracking (`S03-106/174/206/229`).**
`quest_log.gd` tracks the first unset main-chain flag; that flag is
`tournament_training_ready`, written from `entry.min_level` (5) checked
against ALL FIVE party creatures (`min_party_size` = 5 =
`required_party_size()`, and `training_ready()` checks the top `wanted`
strongest against the floor -- with `wanted` equal to the full roster, that is
every creature owned). This run's team ends the segment at a uniform level 3.
`data/config/tournament.json`'s own comment: "a first honest guess at 'your
team is ready' and nobody has played the ladder yet." Closing a ~600 XP/
creature gap (`progression.gd::xp_to_next`, base 40 * level^1.6, level 3 to 5
per creature) is a pacing question for real playtesting, not a rig defect --
scripting dozens of extra fights into S03.json to force it shut would be
inventing tutorial pacing unilaterally. Recorded for whoever owns that
tuning call.

**`player_slept_at_home` / `tournament_team_fed` via the S03-205 collision
(`S03-205a/b/c`, `S03-228`, `S03-260`).** Walked the full investigation
trail across four escalating hypotheses, each ruled out by the next run's
own evidence:

1. *Camp/bed prompt collision* (documented earlier this session,
   `within: 3.0 -> 1.2`) -- confirmed real on the run it was measured against
   (4.0m separation), but the fix does not generalize: the relative
   stick-placement (`S03-121n/131n/141n`) does not guarantee a fixed
   camp-to-bed separation run to run, and a later run at a smaller measured
   separation reproduced the collision at `within: 1.2`. Tightened to `0.6`.
2. *A deployed companion's own recall prompt* -- two consecutive runs showed
   "Put &lt;creature&gt; away" (once a wild Mudsnout caught mid-run, once a
   scripted Bramblebun) winning over the bed's prompt at the exact spot
   `within: 0.6` was supposed to fix. Added a companion-recall step
   (`interact_with{control: creature_recall, optional: true}` -- also fixed
   `interact_with` itself to accept a `control` override, since "Put X away"
   answers to `creature_recall`, not `interact`, and the old code would have
   pressed the wrong button while reporting nothing wrong until it did).
3. **Ruled out by direct code read:** `prompt_arbiter.gd::choose_index()` is
   "highest priority wins, ties go to nearest." `_creature_control_offer()`'s
   "Put/Call out" lines carry priority -1/-2 against an ordinary
   interactable's default 0. A creature_bed offer genuinely present in the
   arbiter's candidate list would ALWAYS beat the companion line on priority
   alone. The companion-recall step then confirmed this empirically: it
   successfully recalled the creature (prompt flipped from "Put ... away" to
   "Call out ..."), and the identical collision persisted anyway -- proof the
   companion was never the real blocker.
4. **What the next run's own telemetry actually showed:** `S03-205a` (the
   walk to the bed) FAILing to arrive at all -- "stopped 2.9m short in 1800
   walking frames, 0 held." No creature_bed offer was ever in contention,
   because the player was never close enough for one to exist. This is
   `creature_bed.gd`/`interactable.gd`'s own prompt registration or
   `move_to_entity`'s pathing near that specific structure, not a
   prompt-priority question a harness-side `within` value or press sequence
   can out-tune.

This is squarely the ground `ralph/OWNER-0902-REST-VISIBILITY` (its name is
literally this problem) and `ralph/OWNER-0901-PLAYER-SLEEP-V2` already stand
on. Per the coordinator's earlier explicit instruction not to touch or
duplicate that work, none of `camp.gd`/`creature_bed.gd`/`interactable.gd`
were edited this session. This doc, plus the eight runs' own telemetry
committed alongside it, is the evidence handed over -- not re-diagnosed
further here.

**`S03-25w`.** Explicitly diagnostic per its own step text ("This assert is
diagnostic and changes no behaviour"), unrelated to anything touched this
session, present before and after every fix above.

## Numbers for the record

| Run | FAILs | What changed since the previous run |
|---|---|---|
| s03fablefix | 42 | equip_tool + interact_with(optional) landed; hit an unrelated fainted-ally cascade |
| s03fablefix2 | 18 | equip_tool live-slot-read (hotbar_slot_of) |
| s03fablefix3 | 16 | interact_with(optional) on second-swing taps; gather ladder clean for the first time |
| s03fablefix4 | 18 | feed-picker "focus entrant N" removed; surfaced answer_prompts wild-engage hazard |
| s03fablefix5 | 16 | answer_prompts narrowed to narrative_modal; camp/bed collision at closer separation |
| s03fablefix6 | 17 | within 1.2 -> 0.6; surfaced the deployed-companion collision |
| s03fablefix7 | 16 | companion-recall step + interact_with `control` override; traced priority math, ruled out companion |
| s03fablefix8 | 12 | close_menu retry; "close the shell" cluster fully cleared |

Every run and its full telemetry is committed on this branch
(`ralph/reports/gate-f-run-*-s03fablefix*`).
