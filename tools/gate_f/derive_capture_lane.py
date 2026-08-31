#!/usr/bin/env python3
"""Derive a Gate F CAPTURE lane from a LOGIC lane, and say honestly what each
frame costs to reach.

    tools/gate_f/derive_capture_lane.py            # regenerate every <id>C.json
    tools/gate_f/derive_capture_lane.py --check    # verify they are up to date

Why this is a generator and not eighteen hand-written files
-----------------------------------------------------------
§H.1's evidence split says a capture lane "reaches a named state the same way
the journey did".  That is a claim about provenance, and the only way to make
it check out is for the capture lane's path to BE the journey's path, minus the
steps that exist to produce a logic verdict.  A hand-written approximation of
the same walk is a different walk, and §0.6 ("production paths only") would then
be resting on an operator's memory of what the journey did.

So a capture lane is derived, mechanically:

  * every step of the logic lane up to and including its LAST capture is kept,
    in order, verbatim -- that is the production path to the named states;
  * everything after the last capture is dropped -- it produces no frame;
  * `note` / `defect` / `probe_cell` are dropped -- they are logic-lane
    bookkeeping and, in X01's case, 1,100 steps of input matrix that photograph
    nothing;
  * `save_out` is dropped -- a capture lane must never overwrite the logic
    lane's handoff saves, which are what seeded it;
  * the four PACING asserts (`route_rows_at_least`, `distance_above`,
    `dead_travel_below`, `dead_travel_peak_above`) are dropped -- they are
    claims about the journey, and a trimmed path would fail them for a reason
    that says nothing about the game;
  * every other `assert` / `assert_context` is KEPT, because an assert costs no
    frames and it is what stops a frame being taken of the wrong thing.

Step ids keep their origin: `S05-27` becomes `S05C-27`, and `_derived_from`
carries the original.

Reachability -- the part a generator cannot decide
--------------------------------------------------
`S01C.json`'s own comment draws the line this file is built around:

    "Not every §G frame is reachable this cheaply.  A title screen needs only a
     boot; a mid-dialogue or mid-fight frame is not a saveable state and its
     capture lane has to be seeded from the logic lane's nearest save
     (seed_save + boot + await_load) and then staged forward by a short
     scripted approach."

That distinction is a judgement about the game, so it is authored here per
frame rather than inferred, and it lands in each generated file's
`_reachability` block where a reader meets it beside the steps:

  A  reached from a cold process by the production front door alone -- a wipe,
     a boot, and at most Start New Game.  No save is involved.  The title
     screen; the wake beat, which costs the ~90 s cold world stand-up as well.

  B  a place a save restores.  A viewpoint, a HUD, a menu tab, a world
     position -- the seeded save already satisfies the frame's preconditions,
     so the cost is a load plus a short walk.  This is the cheap case and it is
     the only one anybody should call cheap.

  C  an event no save holds.  Mid-dialogue, a thrown lure, a swing, a level-up
     announcement, a weather moment, a ceremony screen.  No slot file contains
     it: the lane seeds the nearest save that PRECEDES the event and re-stages
     the event by production play.  Two things follow and both must travel with
     the frame -- the cost is the staging, and the frame is of AN instance of
     that state, not of the journey's instance.

  D  a state whose preconditions the seeded save does not carry.  The staging
     therefore includes the segment work that produces them: a flag, a gate, a
     fight, a rescue, a nightfall.  Class D is where "a short scripted
     approach" stops being true, and it is named separately so that a D can
     never be read as a B.  Every frame behind the Warden is a D.

The honest summary of what that classification found, run-wide, is in
`_summary` at the bottom of this file and in the generated
`ralph/reports/GATE_F_CAPTURE_LANES.md`.
"""

from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEGMENTS = os.path.join(HERE, "segments")

DROP_ACTIONS = {"note", "defect", "probe_cell", "save_out"}
DROP_ASSERT_CHECKS = {"route_rows_at_least", "distance_above",
                      "dead_travel_below", "dead_travel_peak_above"}


# --- authored, per segment ----------------------------------------------------
#
# `lane_note`   -- what this capture lane is and what seeds it.
# `cost_note`   -- what its staging actually costs, said plainly.
# `frames`      -- id -> (class, why).  `SEQ:<base>` covers every expanded frame
#                  of a capture_seq, which the harness numbers <base>-000, -001…

NOTES: dict[str, dict] = {

"S02": {
 "title": "S02 CAPTURE lane: the opening, photographed",
 "lane_note":
  "CAPTURE lane for S02. There is nothing to seed it with: §B gives S01 the "
  "entry save 'none (fresh)' and S02 the handoff 'in-memory', so the chapter's "
  "first slot file does not exist until this segment's own play makes it. The "
  "front door IS the only production path to every state here, which is why "
  "this lane is a replay of the opening rather than a load and a walk.",
 "cost_note":
  "The most expensive kind of capture lane in the run and the one the split "
  "cannot help: eight frames, seven of them behind the wake beat, the Grandpa "
  "conversation, the starter choice, a named creature, a first ambush and a "
  "first catch. Sixty of S02's seventy-five steps are kept. On a GPU host that "
  "is a few minutes of play; on this container it is the ~8,283-hour envelope "
  "and must not be attempted.",
 "frames": {
  "GF-02-START-01": ("A",
   "the wake beat is what Start New Game lands on. No save precedes it because "
   "none can. Cost is a boot plus the ~90 s cold Meadows stand-up, not a boot."),
  "GF-21-WEATHER-01": ("C",
   "'each weather preset first naturally encountered'. Which preset is up at "
   "the wake beat is the world clock's business, and §0.6 bars pin_clock "
   "outside a DIAG segment, so this lane photographs whatever weather the "
   "restaged opening produced -- not necessarily the one the journey saw."),
  "GF-02-START-02": ("C",
   "mid-dialogue with Grandpa. A narrative modal is not a saveable state; the "
   "conversation is restaged by walking into it exactly as the journey did."),
  "GF-02-START-03": ("C",
   "the starter picker open with an orb focused. Same class as the dialogue, "
   "and the focused index is a live UI state no slot file carries."),
  "GF-14-COMBAT-01": ("C",
   "CB-01, the first ambush. A fight in progress; the lane re-fights it."),
  "GF-15-CATCH-01": ("C",
   "the aim reticle up mid-throw. The most transient state in the protocol."),
  "GF-15-CATCH-02": ("C",
   "the catch resolving. Same throw, six seconds later; a restage that fails "
   "to catch produces a frame of a different outcome, and that has to be read "
   "off the frame rather than assumed."),
  "GF-03-VILLAGE-01": ("D",
   "first arrival at the village centre (10,-10) is a PLACE, and would be a "
   "cheap class B from any save -- but no save exists this early in the "
   "chapter, so reaching it costs the whole opening. A place frame priced like "
   "an event frame, purely because of where the save chain starts."),
 }},

"S03": {
 "title": "S03 CAPTURE lane: village life, the practice trainer, and the first night",
 "lane_note":
  "CAPTURE lane for S03, seeded from the logic lane's run://S02-exit.json "
  "through the production title screen (seed_save -> boot -> Load -> "
  "await_load), which is the pattern §H.1 names.",
 "cost_note":
  "Splits cleanly in two. The map tab and the street-level walk are genuine "
  "class B -- a load and a few tens of metres. The three night frames are the "
  "expensive end of the journey: 'first NATURAL nightfall' means the in-game "
  "hours S03 spends reaching it, and pin_clock is DIAG-only so a journey "
  "capture lane may not skip them. Any attempt to shorten that is a different "
  "claim about the game.",
 "frames": {
  "GF-18-MAP-01": ("B",
   "the Map tab on a fresh-ish save: load, press the tab's shortcut, shoot. "
   "The cheapest frame outside the title screen."),
  "GF-03-VILLAGE-02": ("B",
   "street level between Tam, Oskar and Mira. A position the seeded save "
   "already reaches; the cost is the walk."),
  "GF-14-COMBAT-02": ("C",
   "CB-02, the practice trainer at (13,9). The trainer stands where the save "
   "left him, so the staging is the walk plus the fight -- but the FIGHT is "
   "the state, and a fight is never restored."),
  "GF-19-UI-10": ("C",
   "the first level-up announcement, which is an on-screen event a few frames "
   "wide. It follows from the trainer fight, so it is reproducible -- but only "
   "by fighting, and only if the restaged fight levels the same creature."),
  "GF-20-NIGHT-01": ("D",
   "'first natural nightfall, no torch'. The precondition is the world clock "
   "reaching night through play, which S02-exit does not carry. Class D, and "
   "the reason S03C cannot be described as a short approach."),
  "GF-20-NIGHT-02": ("D", "the same position with the torch drawn: same clock, "
   "same staging, one extra press."),
  "GF-14-COMBAT-13a": ("D",
   "CB-13's night half -- a fight under torch light. Class D twice over: it "
   "needs the nightfall AND an encounter inside it."),
 }},

"S04": {
 "title": "S04 CAPTURE lane: the village tournament",
 "lane_note":
  "CAPTURE lane for S04, seeded from run://S03-exit.json. §H names S04 "
  "(tournament) on the mandatory continuous-evidence list; under the split "
  "that obligation becomes S04-SEQ-final, a BOUNDED forty-frame sequence over "
  "the final round, which is exactly the 'bounded record window around a named "
  "state' §H.1 permits in place of recording the segment.",
 "cost_note":
  "Every frame here is class C: the tournament is one continuous production "
  "sequence and none of its moments is a saveable state. The staging is the "
  "tournament -- sign-up, bracket, final -- run once. There is no cheaper "
  "honest route, because a tournament frame taken from a save AFTER the "
  "tournament is a frame of an empty arena.",
 "frames": {
  "GF-04-TOURN-01": ("C", "sign-up dialogue with the marshal at (20,12): a "
   "narrative modal, restaged by walking up and interacting."),
  "GF-14-COMBAT-03": ("C", "CB-03, a bracket round in progress."),
  "GF-04-TOURN-02": ("C", "mid-final-round combat."),
  "SEQ:S04-SEQ-final": ("C",
   "forty frames at the harness's clamped 1 Hz over the final round. §H's "
   "0.5 Hz cadence is clamped up by _plan_captures, so the id list is "
   "S04-SEQ-final-000..039. A sequence is one staged state photographed forty "
   "times, not forty states, so it costs the fight once."),
  "GF-14-COMBAT-09a": ("C", "CB-09, switching creatures under pressure -- a "
   "two-input window inside a fight."),
  "GF-04-TOURN-03": ("C", "the victory/bracket resolution moment."),
 }},

"S05": {
 "title": "S05 CAPTURE lane: the south meadow, the pond, the bridge",
 "lane_note":
  "CAPTURE lane for S05, seeded from run://S04-exit.json. The first journey "
  "segment where the split actually pays: six of its nine frames are places.",
 "cost_note":
  "Six class-B frames (map, HUD, meadow, pond twice, bridge first sight) that "
  "cost a load and a walk south, and three that do not. The one to read "
  "carefully is GF-07-BRIDGE-02: a PLACE frame -- standing on the bridge -- "
  "that is class D only because the bridge opens as a result of the fight this "
  "segment runs, and S04-exit does not carry that flag. Seeding run://"
  "S05-exit.json instead would make it a class B walk-back, at the price of a "
  "real evidence caveat: the frame would then show the bridge at the END of "
  "S05 rather than at the moment it opened. That trade is left unmade here "
  "deliberately -- the generated lane keeps the journey's own path -- but it is "
  "the obvious first economy if a GPU host still cannot afford S05C.",
 "frames": {
  "GF-18-MAP-03": ("B", "the minimap at a route decision point."),
  "GF-19-UI-08a": ("B", "the HUD in ordinary exploration -- a frame of the "
   "default state, which is the cheapest kind there is."),
  "GF-05-MEADOW-01": ("B", "the first open-meadow sightline on RT-04/05."),
  "GF-21-WEATHER-02": ("C", "whichever preset is up on the walk south. Same "
   "reasoning as GF-21-WEATHER-01."),
  "GF-06-POND-01": ("B", "the pond first visible on the RT-03 approach vector. "
   "A viewpoint; the save restores the world it looks at."),
  "GF-06-POND-02": ("B", "the pond shore at (-342,507)."),
  "GF-07-BRIDGE-01": ("B", "South Bridge first visible, northbound on RT-05."),
  "GF-14-COMBAT-04a": ("C", "CB-04's band-1 representative, the "
   "south_bridge_grunt at (14,1314)."),
  "GF-07-BRIDGE-02": ("D", "on the bridge at (0,1330) AFTER it opens. A place "
   "behind a flag the seeded save does not carry -- see the cost note."),
 }},

"S06": {
 "title": "S06 CAPTURE lane: the quarry and the Burrow Warrens",
 "lane_note":
  "CAPTURE lane for S06, seeded from run://S05-exit.json.",
 "cost_note":
  "The quarry half is cheap and the Warrens half is not. Arrival at the quarry "
  "and the Warrens mouth are class B viewpoints a load and a walk reach. "
  "Everything inside the Warrens is class D: the interior states are behind "
  "the descent and the clear, and 'mid-clear' and 'guardian encounter' are "
  "fights on top of that.",
 "frames": {
  "GF-14-COMBAT-04b": ("C", "CB-04's quarry representative, quarry_picket_dorn."),
  "GF-08-QUARRY-01": ("B", "quarry arrival at (403,1794)."),
  "GF-16-GATHER-02": ("C", "a pickaxe swing landing on a rootstone deposit. "
   "The tool comes with the save; the swing does not."),
  "GF-09-WARRENS-01": ("B", "the Warrens mouth at (-420,2470) -- still outside, "
   "still a viewpoint."),
  "GF-09-WARRENS-02": ("D", "an interior chamber MID-CLEAR: inside, and in a "
   "fight, from a save that is outside and not."),
  "GF-14-COMBAT-05": ("D", "CB-05, the enclosed-geometry fight. Same two "
   "preconditions."),
  "GF-09-WARRENS-03": ("D", "the guardian encounter, deepest state in the "
   "segment."),
 }},

"S07": {
 "title": "S07 CAPTURE lane: the river and the Tether Relay",
 "lane_note":
  "CAPTURE lane for S07, seeded from run://S06-exit.json.",
 "cost_note":
  "Two class-B viewpoints and three that need the segment's own work. The "
  "rescue frame is the expensive one: 'captive rescue / crossing restored' is "
  "the moment the relay falls, which is the whole point of S07.",
 "frames": {
  "GF-10-RELAY-01": ("B", "the river first visible on RT-08."),
  "GF-21-WEATHER-03": ("C", "the preset up on the approach."),
  "GF-14-COMBAT-04c": ("C", "CB-04's river representative: the relay ladder "
   "and relay_captain."),
  "GF-10-RELAY-02": ("B", "the relay compound approach at (350,3760), pylons "
   "in frame. A viewpoint from outside the compound."),
  "GF-10-RELAY-03": ("D", "captive rescue / crossing restored at (-152,4203). "
   "Behind the captain fight and the rescue -- the segment's own outcome."),
 }},

"S08": {
 "title": "S08 CAPTURE lane: the Upper Meadows",
 "lane_note":
  "CAPTURE lane for S08, seeded from run://S07-exit.json, which is the save "
  "that carries the restored crossing.",
 "cost_note":
  "Mostly class B -- the crossing entry, both map zoom extremes, the band-4 "
  "pasture. Two caveats. GF-19-UI-09 wants the party strip at 5/5, and whether "
  "that is a class-B load-and-shoot or a class-D 'go and catch a fifth' "
  "depends entirely on whether S07-exit already carries five creatures; the "
  "logic lane's own party_size telemetry answers it and the reader should "
  "check rather than assume. GF-11-UPPER-02 wants the player MOUNTED, which is "
  "a live state no slot file holds.",
 "frames": {
  "GF-11-UPPER-01": ("B", "Upper Meadows entry across the crossing at the end "
   "of RT-09. S07-exit carries the restored crossing, so this is a walk."),
  "GF-18-MAP-02": ("B", "the Map tab late in the chapter, at both zoom "
   "extremes."),
  "GF-05-MEADOW-02": ("B", "the band-4 high pasture on RT-10."),
  "GF-14-COMBAT-12a": ("C", "CB-12's large half -- the meadowhart/tuskroot "
   "size class, in a fight."),
  "GF-19-UI-09": ("B?", "the party strip at 5/5. Class B IF the seeded save "
   "already holds five; class D if the fifth catch happens inside S08. Not "
   "guessed here -- read the logic lane's party_size at S07's close."),
  "GF-11-UPPER-02": ("C", "riding on Meadowhart. Mounted is a live state, so "
   "the lane has to mount."),
  "GF-14-COMBAT-04d": ("C", "CB-04's band-4 representative, captain_field."),
 }},

"S09": {
 "title": "S09 CAPTURE lane: the Stronghold Approach",
 "lane_note":
  "CAPTURE lane for S09, seeded from run://S08-exit.json.",
 "cost_note":
  "Short lane, four frames, and only one of them is a place. The Hall-on-the-"
  "horizon frame is class D rather than class B only because it is taken past "
  "the sigil gate, which this segment opens.",
 "frames": {
  "GF-12-APPR-01": ("C", "the sigil gate OPENING -- an animation moment, not a "
   "state. The gate open and the gate opening are different frames and only "
   "the second one is prescribed."),
  "GF-21-WEATHER-04": ("C", "the preset up on the approach."),
  "GF-14-COMBAT-04e": ("C", "CB-04's approach representative, "
   "stronghold_outer_watch."),
  "GF-12-APPR-02": ("D", "the Hall dominant on the horizon with the drained "
   "land in frame, mid-RT-11 -- past the gate this segment opens."),
 }},

"S10a": {
 "title": "S10a CAPTURE lane: the Hall gauntlet",
 "lane_note":
  "CAPTURE lane for S10a, seeded from run://S09-exit.json. S10a is the FIRST "
  "of S10's five split sub-segments (ralph/T2-S10-COST, 2026-08-30; see "
  "tools/gate_f/segments/S10a.json's header for the split's full rationale). "
  "Splitting S10 also shrinks each piece's OWN capture lane: this generator "
  "keeps every step up to a segment's LAST capture, so S10a's capture lane no "
  "longer has to walk through the courtyard fight, the recovery beat, the "
  "elite fight, the Warden, the legendary chamber or the ceremony to reach its "
  "two frames -- all of that was retained in the old monolithic S10C only "
  "because a LATER capture (GF-13-FINALE-02, now in S10b) forced it to be kept.",
 "cost_note":
  "Both frames are class D -- the Hall interior and the patrol fight are both "
  "behind the gauntlet, which S09-exit does not carry -- but the split ends "
  "this capture lane at the patrol fight's own camera-verification shot "
  "(GF-14-COMBAT-06) rather than carrying it through two more fights, a rest "
  "beat and the chapter's climax the way the un-split S10C did.",
 "frames": {
  "GF-13-FINALE-01": ("D", "the Hall interior gauntlet space -- inside the "
   "Outer Works, which S09-exit is not."),
  "GF-14-COMBAT-06": ("D", "CB-06: patrol -> courtyard -> elite -> "
   "warden_aldis. A fight chain, inside. Only the patrol leg is staged by "
   "S10a's own capture lane; the courtyard, elite and Warden legs are staged "
   "by S10b's, once each is reached by that segment's own production path."),
 }},

"S10b": {
 "title": "S10b CAPTURE lane: the Warden, the legendary choice, the ceremony",
 "lane_note":
  "CAPTURE lane for S10b, seeded from run://S10a-exit.json -- a split-"
  "introduced handoff (the elite just beaten, shutter lifted) rather than a "
  "save section B names in the original monolithic file. §H names the Warden "
  "on the mandatory continuous-evidence list; under the split that is "
  "S10-SEQ-warden, a bounded sixty-frame sequence over the fight, unchanged "
  "from the original.",
 "cost_note":
  "Every frame here is class D, and this is now the most expensive single "
  "capture lane in the protocol: the Warden fight, the legendary chamber and "
  "the release ceremony are each reached only by playing through the previous "
  "one, and there is no save between S10a-exit and S10b's own close. Whatever "
  "host runs the capture lanes has to be able to afford this one entire, same "
  "as the old monolithic S10C had to for the whole chapter -- the split moved "
  "the boundary, it did not remove this particular cost, because the Warden "
  "through the ceremony genuinely has no cheaper save point along the way.",
 "frames": {
  "GF-13-FINALE-02": ("D", "the Warden's pre-fight dialogue in the arena."),
  "SEQ:S10-SEQ-warden": ("D",
   "sixty frames at the clamped 1 Hz over the chapter's climax "
   "(S10-SEQ-warden-000..059). One staged fight, photographed sixty times."),
  "GF-13-FINALE-03": ("D", "the legendary chamber and the tether machine -- "
   "after the Warden falls."),
  "GF-13-FINALE-04": ("D", "the release ceremony decision screen. A UI state "
   "that exists once, at the end of the chapter."),
 }},

"S10c": {
 "title": "S10c CAPTURE lane: the healed meadow",
 "lane_note":
  "CAPTURE lane for S10c, seeded from run://S10b-exit.json -- a split-"
  "introduced handoff (the roster ceremony just concluded) rather than a save "
  "section B names in the original monolithic file.",
 "cost_note":
  "One frame, and the split's cleanest saving: the healed-meadow capture sits "
  "right after the short approach_drain walk and BEFORE S10c's own giant walk "
  "to Old Mill Crossing (132,750 budget frames in the logic lane), so this "
  "generator -- which keeps only up to a segment's LAST capture -- drops that "
  "entire leg from the capture lane. The old monolithic S10C had to carry this "
  "frame at the END of playing the Warden and the ceremony first; split out on "
  "its own, it costs a load plus one short walk.",
 "frames": {
  "GF-13-FINALE-05": ("D", "the healed meadow on the walk back. The world's "
   "post-victory dressing, which nothing before the victory carries -- still "
   "class D because it is behind the Warden, not because of anything in this "
   "sub-segment's own short walk."),
 }},

"X01": {
 "title": "X01 CAPTURE lane: the menu shell, tab by tab",
 "lane_note":
  "CAPTURE lane for X01, seeded from run://S03-exit.json. X01's 1,203 steps "
  "are the §8 controller/menu exhaustion matrix -- `probe_cell` after "
  "`probe_cell` -- and NONE of that photographs anything. Dropping it leaves "
  "the menu tour that actually takes the eight §G UI frames.",
 "cost_note":
  "After S01C this is the cheapest capture lane in the run, and by a wide "
  "margin the biggest saving the split produces: a 1,203-step segment becomes "
  "a load and a tab walk. Every frame is class B -- a menu tab is a state the "
  "shell reaches from any save, on a button press. §H names X01 on the "
  "mandatory continuous-evidence list; the input matrix that made it "
  "high-risk is a LOGIC concern and stays in the logic lane, which is the "
  "split working exactly as intended.",
 "frames": {
  "GF-19-UI-08b": ("B", "the HUD before the shell is opened."),
  "GF-19-UI-01": ("B", "menu tab 1 -- a load and a shortcut press."),
  "GF-19-UI-02": ("B", "menu tab 2."),
  "GF-19-UI-03": ("B", "menu tab 3."),
  "GF-19-UI-04": ("B", "menu tab 4."),
  "GF-19-UI-05": ("B", "menu tab 5."),
  "GF-19-UI-06": ("B", "menu tab 6."),
  "GF-19-UI-07": ("B", "menu tab 7."),
 }},

"X02": {
 "title": "X02 CAPTURE lane: gathering and the build loop",
 "lane_note":
  "CAPTURE lane for X02, seeded from run://S03-exit.json.",
 "cost_note":
  "Four frames, all class C, all cheaply staged -- this is the case S01C had "
  "in mind when it wrote 'seconds of play per frame instead of hours'. A swing, "
  "an armed ghost and two placements are each a handful of presses from a "
  "loaded save; none of them is a state a save holds, and none of them costs "
  "more than the presses.",
 "frames": {
  "GF-16-GATHER-01": ("C", "a gather swing landing. Seconds from the load."),
  "GF-17-BUILD-03": ("C", "the build ghost armed and placeable -- a live "
   "placement state, reached from the build menu."),
  "GF-17-BUILD-01": ("C", "a structure being placed."),
  "GF-17-BUILD-02": ("C", "the placement resolved."),
 }},

"X03": {
 "title": "X03 CAPTURE lane: the catch lab, aim and resolve",
 "lane_note":
  "CAPTURE lane for X03, seeded from run://S05-exit.json and later "
  "run://S08-exit.json, which is how the lab covers two bands of wild bodies.",
 "cost_note":
  "Fourteen frames in seven aim/resolve pairs. Every one is class C and cannot "
  "be anything else: a thrown lure is the least saveable state in the game. "
  "The staging per pair is short -- find a wild body, engage, throw -- but "
  "there are seven of them and each depends on a wild spawn being there, which "
  "is the one precondition a save does NOT pin down. A pair that restages "
  "against a different species is a frame of a different claim, and the "
  "manifest's own trigger text is what a reader must check it against.",
 "frames": {
  "GF-15-CATCH-02a": ("C", "aim frame, pair 2."),
  "GF-15-CATCH-02b": ("C", "resolve frame, pair 2."),
  "GF-15-CATCH-03a": ("C", "aim frame, pair 3."),
  "GF-15-CATCH-03b": ("C", "resolve frame, pair 3."),
  "GF-15-CATCH-04a": ("C", "aim frame, pair 4."),
  "GF-15-CATCH-04b": ("C", "resolve frame, pair 4."),
  "GF-15-CATCH-05a": ("C", "aim frame, pair 5."),
  "GF-15-CATCH-05b": ("C", "resolve frame, pair 5."),
  "GF-15-CATCH-06a": ("C", "aim frame, pair 6."),
  "GF-15-CATCH-06b": ("C", "resolve frame, pair 6."),
  "GF-15-CATCH-07a": ("C", "aim frame, pair 7 -- the CLAUDE.md hard rule case: "
   "a trainer-owned creature cannot be caught, and the frame is of the refusal."),
  "GF-15-CATCH-07b": ("C", "resolve frame, pair 7."),
  "GF-15-CATCH-09a": ("C", "aim frame, pair 9 -- the five-creature limit case."),
  "GF-15-CATCH-09b": ("C", "resolve frame, pair 9."),
 }},

"X04": {
 "title": "X04 CAPTURE lane: the combat lab",
 "lane_note":
  "CAPTURE lane for X04, seeded in turn from run://S04-exit.json, "
  "run://S06-exit.json and run://S09-exit.json -- three bands of opponent from "
  "three points on the journey.",
 "cost_note":
  "Eight frames, every one class C, and every one a fight. Cheap per frame in "
  "the sense that matters -- each is a walk and an engagement from a save that "
  "already stands beside the opponent -- and expensive in the sense that "
  "matters on this box, because a fight is minutes of physics frames and on "
  "llvmpipe every physics frame is a rendered one.",
 "frames": {
  "GF-14-COMBAT-07": ("C", "CB-07."),
  "GF-14-COMBAT-08": ("C", "CB-08."),
  "GF-14-COMBAT-09b": ("C", "CB-09's lab instance of switching under pressure."),
  "GF-14-COMBAT-11": ("C", "CB-11."),
  "GF-14-COMBAT-12b": ("C", "CB-12's small half."),
  "GF-14-COMBAT-10": ("C", "CB-10 in the open."),
  "GF-14-COMBAT-10-warrens": ("C", "CB-10 repeated in the Warrens' enclosed "
   "geometry."),
  "GF-14-COMBAT-10-stronghold": ("C", "CB-10 repeated at the stronghold."),
 }},

"X05": {
 "title": "X05 CAPTURE lane: the title screen with a chapter behind it",
 "lane_note":
  "CAPTURE lane for X05, which owes exactly one frame. X05's 313 steps are the "
  "save/session lifecycle -- sixteen seeds, eleven copies out, load after load "
  "-- and the single §G frame it carries is the title screen with populated "
  "slots.",
 "cost_note":
  "Class A/B and nearly as cheap as S01C: seed the slots, boot the title, "
  "shoot. The other 300 steps are lifecycle telemetry that belongs to the "
  "logic lane. Note the difference from GF-01-TITLE-01, which S01C takes: that "
  "one is the front door with NO saves, this one is the front door with a "
  "chapter behind it, and the pair is the evidence that the slot list renders "
  "what it holds.",
 "frames": {
  "GF-01-TITLE-02": ("B", "the title screen once slots exist. A boot, after a "
   "seed -- the only §G frame in the protocol besides GF-01-TITLE-01 that "
   "needs no world at all."),
 }},

"X07": {
 "title": "X07 CAPTURE lane: the regional audit, site by site",
 "lane_note":
  "CAPTURE lane for X07, the DIAG world audit. It seeds nothing: X07 reaches "
  "its ten sites by the Settings debug teleport and pins clock and weather, "
  "both permitted here and ONLY here because the segment is prefixed DIAG "
  "(§0.1). The price of that permission is §0.6's other half -- no pacing, "
  "navigation, difficulty or economy claim may ever be sourced from these "
  "frames. They are a look at the world, not at the journey.",
 "cost_note":
  "Eighty frames, the largest single block in the protocol, and simultaneously "
  "the CHEAPEST PER FRAME of the deep lanes: teleport and pin_clock turn a "
  "class-D state into a class-B one by fiat, which is exactly what a DIAG "
  "segment is for. The two combat-lighting frames at the end are the "
  "exception -- a fight is still a fight. This is also the segment CD-7 was "
  "written about: it stopped at step 184 of 266 with two 90-second waits ahead "
  "of it, ~31 hours away from finishing, and its waits are the clock and "
  "weather settling, so they cannot be shortened without changing what the "
  "frames show.",
 "frames": {"__diag_sites__": ("B",
   "site frames -- gameplay, arrival, landmark, terrain, ecology and "
   "vegetation views at each of the ten audited sites, plus the night and "
   "weather variants at the three sites that carry them. Class B by DIAG "
   "permission: teleport puts the camera at the site and pin_clock fixes the "
   "hour and preset, so no journey is replayed to reach any of them."),
  "GF-14-COMBAT-13b": ("C", "CB-13's second lighting variant -- a fight, under "
   "a pinned sky."),
  "GF-14-COMBAT-13-weather": ("C", "CB-13 under a pinned weather preset. Same."),
 }},
}

# Segments that take no §G frame at all. They still declare a lane, because
# `evidence_lane: "logic"` is what forces `record_hz` to 0 -- and X06's default
# 0.1 Hz continuous record is precisely the thing §H.1 removed.
NO_CAPTURE_LANE = {
 "S10d":
  "S10d (ralph/T2-S10-COST split, 2026-08-30) is the fourth of S10's five "
  "split sub-segments -- the Tether Relay, the Burrow Warrens and the South "
  "Bridge leg of the post-win walk-back. It plans no §G frame: GF-13-FINALE-05 "
  "was already taken in S10c and nothing else in the original S10 protocol "
  "prescribes a shot along this leg, so it hands nothing over and needs no "
  "capture lane, the same shape as X06/X08 below.",
 "S10e":
  "S10e (ralph/T2-S10-COST split, 2026-08-30) is the fifth and last of S10's "
  "split sub-segments -- the village, Grandpa's house, and the chapter's "
  "terminal save. Every prescribed S10 frame was already taken in S10a/S10b/"
  "S10c, so it hands nothing over and needs no capture lane.",
 "X06":
  "X06 (abuse and failure cases) plans no §G frame, so it hands nothing over "
  "and needs no capture lane -- the harness allows exactly that. It is "
  "declared a logic lane anyway for the OTHER half of the declaration: without "
  "it the segment inherits §H's default 0.1 Hz continuous record, which under "
  "a 12.7 s rendered frame is the 4.6-million-frame recording the split was "
  "created to delete, and which headless would write as file:null rows while "
  "every step said PASS.",
 "X08":
  "X08 (the performance audit) plans no §G frame and already sets record_hz 0, "
  "because §H's own last clause says the perf audit runs WITHOUT capture -- a "
  "framebuffer readback in the middle of a frame-time measurement measures the "
  "readback. Declaring the lane makes that explicit rather than incidental.",
}


# --- derivation ---------------------------------------------------------------

def _read(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def expand_capture_ids(step: dict) -> list[str]:
    """The harness's own numbering, restated. `_plan_captures` clamps hz up to
    1.0 and seconds up to 0.2, so a 0.5 Hz / 40 s sequence is FORTY ids, not
    twenty. Getting this wrong would put an id in `owes` that no step shoots,
    which is a BLOCKER at step 1 -- so it is copied from the harness rather
    than reasoned about here."""
    args = step.get("args", {}) or {}
    base = str(args.get("id", step.get("id", "?")))
    if step.get("action") == "capture":
        return [base]
    hz = max(1.0, float(args.get("hz", 5.0)))
    seconds = max(0.2, float(args.get("seconds", 2.0)))
    return ["%s-%03d" % (base, i) for i in range(int(hz * seconds))]


def keep(step: dict) -> bool:
    action = str(step.get("action", ""))
    if action in DROP_ACTIONS:
        return False
    if action == "assert":
        return str((step.get("args", {}) or {}).get("check", "")) not in DROP_ASSERT_CHECKS
    return True


def derive(seg_id: str) -> dict:
    src = _read(os.path.join(SEGMENTS, "%s.json" % seg_id))
    note = NOTES[seg_id]
    steps = src.get("steps", [])

    last = max(i for i, s in enumerate(steps)
               if str(s.get("action", "")) in ("capture", "capture_seq"))
    kept = [s for s in steps[:last + 1] if keep(s)]

    owes: list[str] = []
    reach: dict[str, dict] = {}
    unclassified: list[str] = []
    for step in kept:
        if str(step.get("action", "")) not in ("capture", "capture_seq"):
            continue
        base = str((step.get("args", {}) or {}).get("id", step.get("id", "?")))
        ids = expand_capture_ids(step)
        owes.extend(ids)
        entry = note["frames"].get(base) or note["frames"].get("SEQ:" + base)
        if entry is None and "__diag_sites__" in note["frames"]:
            entry = note["frames"]["__diag_sites__"]
        if entry is None:
            unclassified.append(base)
            continue
        reach[base] = {"class": entry[0], "count": len(ids), "why": entry[1]}
    if unclassified:
        raise SystemExit("%s: no reachability class authored for %s"
                         % (seg_id, unclassified))

    out_steps: list[dict] = [{
        "id": "%sC-00" % seg_id,
        "title": "declare the lane",
        "action": "note",
        "args": {"text":
            "CAPTURE lane for %s (§H.1 evidence split, owner decision "
            "2026-08-27). %s runs this same production path headless for its "
            "mechanics, telemetry and step verdicts and hands these %d "
            "prescribed frame(s) here. The harness has already checked, before "
            "step 1, that a step of this segment takes every one of them. "
            "Reachability per frame is in this file's `_reachability` block; "
            "the classes are defined in tools/gate_f/derive_capture_lane.py."
            % (seg_id, seg_id, len(owes))},
        "expected": "a note event opens the segment",
    }]
    for step in kept:
        new = dict(step)
        new["id"] = str(step.get("id", "")).replace(seg_id, seg_id + "C", 1)
        new["_derived_from"] = str(step.get("id", ""))
        out_steps.append(new)
    out_steps.append({
        # NOT "%sC-99": that collided with the derived id of any logic-lane
        # step numbered 99, and S03 has one (S03-99, a gathering walk), so
        # regenerating S03C produced two steps called S03C-99 and
        # test_gate_f_instrumentation.gd::test_every_segment_script_is_well_formed
        # failed on the duplicate. A step number can be anything; a tail marker
        # must be something a step number cannot be.
        "id": "%sC-close" % seg_id,
        "title": "close",
        "action": "note",
        "args": {"text":
            "The debt %s handed over is paid here. tools/gate_f/run_inventory.py "
            "is what checks that over the whole run directory: a delegation "
            "nobody paid is a run-level deficiency even when both segments' own "
            "inventories are complete." % seg_id},
        "expected": "a note event closes the segment",
    })

    classes: dict[str, int] = {}
    for row in reach.values():
        classes[row["class"]] = classes.get(row["class"], 0) + row["count"]

    return {
        "id": "%sC" % seg_id,
        "title": note["title"],
        "lane": src.get("lane", "journey"),
        "evidence_lane": "capture",
        "owes": owes,
        "record_hz": 0,
        "_comment": note["lane_note"],
        "_comment_generated":
            "GENERATED by tools/gate_f/derive_capture_lane.py from %s.json. Do "
            "not hand-edit: change the source segment or the authored notes in "
            "the generator and regenerate, or the capture lane stops being the "
            "journey's own path and §H.1's provenance claim stops being true. "
            "`--check` fails CI-style if the two have drifted." % seg_id,
        "_comment_derivation":
            "Kept: every step of %s up to and including its last capture "
            "(index %d of %d), minus note/defect/probe_cell/save_out and the "
            "four pacing asserts. %d of %d steps survive. Step ids carry their "
            "origin in `_derived_from`."
            % (seg_id, last, len(steps) - 1, len(kept), len(steps)),
        "_comment_seeding":
            "Run this into the SAME run directory as the logic lanes. Its "
            "`seed_save` steps resolve `run://` against that directory's "
            "saves, so a capture lane run anywhere else has no chapter to load "
            "and will stop at its first seed.",
        "_comment_cost": note["cost_note"],
        "_reachability_classes": classes,
        "_reachability": reach,
        "steps": out_steps,
    }


def _dumps(doc: dict) -> str:
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def main(argv: list[str]) -> int:
    check = "--check" in argv
    drift: list[str] = []
    for seg_id in sorted(NOTES):
        doc = derive(seg_id)
        path = os.path.join(SEGMENTS, "%sC.json" % seg_id)
        text = _dumps(doc)
        if check:
            have = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
            if have != text:
                drift.append(path)
            continue
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        classes = doc["_reachability_classes"]
        print("%-5s -> %-11s %3d frame(s), %3d step(s), classes %s"
              % (seg_id, os.path.basename(path), len(doc["owes"]),
                 len(doc["steps"]), dict(sorted(classes.items()))))
    if check and drift:
        print("derive_capture_lane: out of date: %s" % ", ".join(drift), file=sys.stderr)
        return 1
    if check:
        print("derive_capture_lane: every capture lane matches its source")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
