# Blind playtest — running player-experience log
Run started 2026-08-15. Build under test: main @ 7547f386 (OF14 + OF16 + R4.10 landed)
Input honesty note: no physical controller exists in this environment; input is
action/binding-level injection (same code path as a pad; device layer untestable).
---
## Beat 1 — waking up (shots 001, 002)
Wake upstairs in a bedroom, camera pitched steeply down at the bed. HUD is already
fully present: minimap (with roads + a marker), hotbar 1-5 (empty), HP 100/100,
"No creature out", and MAIN STORY: "Find a way through the village gate."
- OBS-1: objective at wake is "find a way through the village gate" — nothing has
  pointed me at whoever/whatever is in this house first. As a first-timer I'd
  expect the first objective to be in arm's reach. (severity TBD — maybe the gate
  IS the first beat; play on.)
- OBS-2: prompt glyph is "E" (keyboard). No pad exists in this env so dynamic
  prompts may be behaving correctly; flagged for the KB/M-vs-pad prompt check later.
- OBS-3: room reads clean and warm (wood/plaster, lattice windows onto green).
  Nice first frame apart from the steep camera angle.
Action: press interact ("Get up").
## Beat 2 — getting up (shots 003-005)
"Get up" worked instantly; character stands. Trainer model reads great (scarf,
backpack, gloves). Two immediate player confusions:
- OBS-4: prompt now says "Talk to Grandpa" but NOBODY is visible — no Grandpa in
  the room. Who? Where? Prompt appears to trigger at range (through the floor?).
- OBS-5: MAIN STORY objective ("village gate") and the prompt ("Talk to Grandpa")
  give different instructions within the first 10 seconds.
- OBS-6: after get-up the camera faces the character head-on instead of settling
  behind the shoulders; first movement will be camera-relative-ambiguous.
- Nice: window views onto green meadow + neighbor roofs; minimap rotates with view.
Action: look around for stairs, head downstairs to find Grandpa.
## Beat 3 — first movement (shots 006-007)
Walked forward from the get-up spot and ended wedged into the window corner.
- OBS-7: "Talk to Grandpa" prompt persists even wedged in a corner with nobody
  around — it's looking global/range-through-floor, not proximity-triggered.
- OBS-8: camera-relative movement from the head-on wake camera = my first input
  walked me INTO the scenery. Follows from OBS-6.
- Calibration note (driver): look_left 1.0x1.5s ≈ 90-120° yaw.
Action: turn 180, find the stairs/ladder down.
## Beat 4 — stuck in the corner, camera fights back (shots 008-010)
- OBS-9 (ISSUE, camera): a large faceted brown prop sits between camera and
  character in the corner and blocks the lower third of the frame (008/009).
- OBS-10 (ISSUE, movement): 2s of forward input produced no movement — wedged
  between window wall and the prop; frames 008 and 009 are near-identical.
- OBS-11 (ISSUE, camera comfort): one more turn and the camera collision
  collapsed to an extreme face close-up filling the screen (010). In a small
  interior the camera ricochets between "blocked by prop" and "inside my face".
  This is the strongest issue so far.
Action: back out of the corner, pitch camera level, navigate toward the room's
open side (minimap shows I'm facing the map's edge).
## Beat 5 — still stuck; the corner is a trap (shots 011-013)
- OBS-11 escalates: camera spent another frame fully inside the top of my head
  (011) while backing up. Camera-collision behavior in this interior oscillates
  between head-clip and corner-block. This is now a P1 candidate: first 2
  minutes of the game and the camera has been unusable 3 times.
- OBS-12: second consecutive movement dead-end (012 vs 013 identical after 2.5s
  of forward input). The wake-room corner + camera-facing = a movement trap a
  brand-new player can absolutely fall into on their first 5 inputs.
- No stamina bar seen while walking (only HP visible) — either sprint-only or
  it's hidden; will test sprint later.
Action: turn left toward the visible open floor, walk out along the wall.
## Beat 6 — free of the corner (shots 014-015)
Turn + wall-follow worked; standing by the bed now, room readable (bed, side
table, warm light — genuinely cozy). Camera skimmed my hair again on the turn
(014) — every close-quarters turn risks a head-clip.
Experiment per protocol §8/§16: the HUD has said "E - Talk to Grandpa" since I
got up, with no Grandpa visible anywhere. Pressing it right here, next to the
bed. If a conversation starts with someone I cannot see, the prompt is firing
through the floor and teaching me not to trust prompts.
## Beat 7 — I talked to Grandpa through the floor (shots 016-017)
CONFIRMED P1 CANDIDATE (FIND-DIALOGUE-RANGE): pressing E from the upstairs
bedroom starts the Grandpa dialogue with no Grandpa in sight. His script stages
a scene ("Sit and eat — the bread's still warm") that is not happening — I'm
standing next to my bed one floor up. The opening's staging can be bypassed
entirely from the spawn point. Dialogue writing itself is warm and good
("I heard the floorboards" — he did not).
Second press advanced to Team Tether exposition — pacing fine so far.
Action: ride the conversation to the end from up here, capture every page,
see if the item gifts also arrive through the floor.
## Beat 8 — gifts + starter choice, still through the floor (shots 018-029)
Dialogue ran ~10 warm, well-written pages (a touch long in one sitting), gifted
berries/potions/orbs into the hotbar (counts appeared in slots 1-3 — no toast or
"received X" callout beyond the dialogue text), then opened the starter selector:
"Three orbs, three companions. Choose one." Terrapup/Ripplet/Galewisp with LIVE
rotating 3D portraits (positive finding — lovely touch; initial angle showed
Terrapup's rear in 026, front by 029).
- FIND-DIALOGUE-RANGE deepens: the ENTIRE opening (story + gifts + starter
  choice) ran from the bedroom with Grandpa never on screen.
- OBS-13 (controls consistency): E advanced 10 dialogue pages, but the selector
  ignores E — its hint switches to arrows + Enter glyphs.
- OBS-14: no item-received feedback beyond prose; hotbar counts just appear.
Action: browse all three (arrows), try cancel (does B/Esc work? can I walk away
from choosing?), then pick Terrapup.
## Beat 9 — starter browsing + cancel test (shots 030-033)
Arrow navigation between the three is instant and clear; live turntable
portraits are a genuine positive (though the spin regularly parks on a rear
view — Terrapup butt-first in 026/030).
- OBS-15: menu_cancel does NOTHING on the starter selector — hard modal, no
  way to step back into the world (or go meet Grandpa) before deciding.
- Choosing Terrapup (yes, partly because it is the tanky digger and partly
  because it looked at me front-on in 033).
## Beat 10 — the choose button (shots 034-035)
Sent ui_accept: selector did not confirm. Flagged as DRIVER-AMBIGUOUS, not yet
a game finding: synthetic action-level ui_accept only reaches ui_accept
listeners; a physical Enter would also fire any custom confirm action mapped to
the same key. Retrying with a raw Enter keystroke, then menu_confirm.
(If raw Enter works: my artifact, not a bug. If only menu_confirm works while
the hint shows the Enter glyph: real prompt/binding mismatch finding.)
## Beat 11 — naming grid (shots 036-037)
Raw Enter confirmed Terrapup → naming screen. VERDICT on the confirm mystery:
driver artifact, not a game bug (raw keystroke works; my action-level inject
didn't reach the listener). Corrected in the record.
Naming grid: controller-style char grid, "every creature gets a name" (name
mandatory, OK greys out when empty), confirm-to-type, Esc/B-glyph = delete.
- OBS-16: "delete" on the Esc/B position is where most games put *cancel* —
  fine once learned, but the first Esc press a KB player makes will eat a
  letter instead of backing out. Also: can you cancel naming at all?
Typing "Bo": DEL the stray A, navigate and type, then OK.
## Beat 12 — Esc opened my backpack ON TOP of the naming screen (038-040)
FIND-NAMING-ESC (P1 candidate, REAL): naming grid hint says [ESC] delete.
Physical Esc instead opened the Backpack pause shell OVER the naming modal
("Name your Terrapup" ghosting behind it). My next inputs went to the
backpack — picked up the Small Potion stack and dropped it in a random slot
(038: slot 2 → 040: row 4). A brand-new player following the on-screen hint
mid-mandatory-naming lands in their backpack rearranging potions.
- Positives: item cards are excellent — flavor text has real voice ("your
  throw does the work, not the orb"), shows GEAR/CONSUMABLE class, hotbar
  binding, stack rules, actions. Pause shell: 7 tabs, Day counter, full
  control legend along the bottom.
- OBS-17: pause shell reachable during the mandatory opening flow (modal
  stacking; unclear what else can interleave — save during naming?).
Action: close backpack (B), check the naming grid state, finish naming Bo.
## Beat 13 — naming survives the stacking (shot 041)
Closing the backpack returned me to the naming grid, name field empty, focus
reset. So the stack recovers — FIND-NAMING-ESC stays a P1-class input bug
(hint says delete, reality opens pause; typed name lost) but not a soft-lock.
Typing B-o, then hunting the OK button.
## Beat 14 — my creature is named "B" now (shots 042-043)
FIND-NAMING-NAV (P1/P2): grid focus is not spatially predictable — from 'B',
down x3 + right x3 landed on OK (not the letter 'o' beneath), so my second
"type" press CONFIRMED the one-letter name. No confirmation dialog for a
permanent choice. Creature is now "B", Lv 3, on the party HUD. Grandpa:
"B. Good. Say it out loud a few times on the road" — the game canonized the
fat-finger. Keeping it, as a real player would have to; rename availability
now becomes a test item for the Creatures tab.
(Also confirms: naming CAN complete despite the earlier backpack stacking.)
Action: finish dialogue, go downstairs, finally lay eyes on Grandpa.
## Beat 15 — opening dialogue ends (shots 044-046)
- Positive: "five is all any trainer carries, and you've just spent your first"
  — the five-cap taught diegetically in one line. Excellent.
- FIND-HOTBAR-UNBIND (consequence of FIND-NAMING-ESC): the potion stack I
  accidentally moved in the backpack is GONE from hotbar slot 2 (046). The
  stacking bug quietly unbound my heal. New players won't even know they lost it.
- B is on the party bar (Lv 3, GROUND type shown — nice) but not visible in
  the world yet. Prompt STILL "Talk to Grandpa"; objective still the gate.
Action: look for B, find the stairs, get downstairs to Grandpa at last.
## Beat 16 — stuck again; B is out but not HERE (047-049)
Third movement dead-end (bed-side this time). Also: paw row now shows "B Lv 3"
(replacing "No creature out") — my creature is deployed SOMEWHERE, just not in
this room. Presumably wherever the starter scene was staged. FIND-DIALOGUE-RANGE
keeps compounding: the through-the-floor opening leaves your new companion
spawned out of sight.
- OBS-18: no stairs/exit visible in any frame yet from this room; wayfinding
  inside the house is genuinely unclear (possible ladder glimpsed at frame edge
  in 001).
Action: 4x90-degree panorama to map exits properly.
## Beat 17 — panorama defeated by the camera (050-053)
The 4x90 panorama produced only 2 distinct views: half the turns ended with the
camera inside my hair against a wall (050, 052). Interior camera comfort is now
the run's dominant impression. Spotted: open mezzanine edge left of the bed
(landing below), possible ladder top at the frame corner. No stairs seen from
this room, still.
Action: player instinct — walk to the edge and JUMP down the mezzanine. Tests
jump, the drop, and any fall damage, and gets me to Grandpa at last.
## Beat 18 — over the railing (054-056)
Jump carried me onto the mezzanine edge; 056 finally reveals the ground floor:
open front door with daylight, desk+chair, no Grandpa in the visible slice.
No fall damage so far (HP 100). Camera did another face-fill on the approach
(054). A second marker appeared on the minimap (white diamond) — unlabeled;
guessing objective or door.
Action: drop to the ground floor, locate Grandpa, re-talk. TEST: does re-talking
repeat the gift sequence (dupe items)? Then head out the front door.
## Beat 19 — perched on the railing (057-058)
The railing jump left me STANDING ON the parapet (058) — balanced on the
railing cap, drop beside me. Comic, and diagnostic: the mezzanine railing is
climbable/standable, and nothing about the room communicates the intended way
down (I still have not seen stairs or a ladder clearly).
Action: jump-forward twice with different facings until gravity wins.
## Beat 20 — the mezzanine edge won't let me over (059-060)
Both jump attempts bounced me back into the bedroom. The visually-open edge I
could STAND ON the cap of will not let me over — collision reads higher than
the railing looks (invisible-barrier feel). 20 frames without leaving room one;
navigation communication in the opening interior is a P1-class finding on its
own. A second diamond marker also appeared on the minimap, unlabeled.
Action: what a lost player does — open the Map tab.
## Beat 21 — Creatures tab detour (061-062)
Pressed tab-right twice from Backpack, landed on Creatures — ONE PRESS SWALLOWED
(first-input-after-open class; protocol redflag). B's sheet is informative:
Lv 3, HP 134/134, ATK 24, DEF 22, Appraisal ***--, EXP 0/231, Pebble Toss
(QUICK, Energy +26), Stone Rush (CHARGED, Cost 100), BOND 0/100, "Goes out
first." Findings: model preview crops the head entirely out of frame
(FIND-PREVIEW-CROP); no rename action visible (B is forever, apparently —
FIND-NO-RENAME candidate, right panel may continue below fold).
Action: one more tab to Map.
## Beat 22 — the Map (063)
World map: THE MEADOWS, Surveyed 3%, fog-of-war, roads radiating from
GRANDPA'S VILLAGE (I'm the teal dot), "?" POI to the NE, legend with Grandpa's
House + The Village. Good bones — survey %, POI teasing. Useless for interiors
(fair), map art reads as soft blobs at this zoom. Re-reading my frames: the
opening I overlooked downstairs through (056) is door-shaped — likely the
stairwell doorway, and my "railing" was its side wall. Going through it.
## Beat 23 — full circle (064-065)
Walked into the SAME lattice corner from beats 3-5. Four orbits of one bedroom.
The room has no readable exit affordance and the camera denies the overview
that would reveal one — compounding P1.
Testing re-talk right here (prompt still up, conversation already completed):
dupe check — if gifts re-run it's P0-class; fresh farewell dialogue = healthy
state machine. Then diagonal room cross toward the interior doorway.
## Beat 24 — re-talk is healthy; still lost (066-068)
POSITIVE: re-talk gives fresh contextual dialogue (wild-creature approach hint),
no gift re-run — no dupe, state machine sound. The hint itself is well-aimed
("get close and it'll stop and look at you") — good tutorialization IF the
player can get outside to use it.
Diagonal cross ended at another lattice junction; floor tone suggests I may
have crossed onto the landing. Trying a hard top-down camera pitch for an
overhead read of the layout.
## Beat 25 — owner ground truth arrives
Owner (exasperated, correctly): stairs are in the room, on the one side never
visited. This confirms FIND-OPENING-NAV as a real P1 — 25 frames, a map check,
and the room's exit never read. Note for the repair pass: the stairs need an
affordance (light, geometry, objective pointer, or camera assist), and the
reusable journey test gets a scripted opening-descent macro (owner directive).
Heading west-by-minimap now.
## Beat 26 — GROUND FLOOR (083-085), ~40 frames after waking
Descent worked: stairwell is in the room's NW corner behind a rail, visually
indistinguishable from the mezzanine parapet until you are on top of it.
Total time-to-ground-floor for a blind player with no interior hints: absurd.
FIND-OPENING-NAV finalized as P1 with owner corroboration (had to point me at
the stairs twice mid-run).
- NEW FIND-PROMPT-OVERLAP (P2): context prompt ("Put B away") renders on top
  of the hotbar icons (083, 085).
- B was downstairs all along — "Put B away" prompt confirms the creature
  staged at the intended scene location while I did the flow upstairs.
- Verified descent sequence recorded to tools/playtest_macros/opening_descent.txt
  (owner directive).
Action: find Grandpa + B, then out the front door.
## Beat 27 — B is a two-meter roommate (086-087)
B found downstairs: a gorgeous model (teal eyes, badger stripes — the quality
benchmark creature earns it) that FILLS the farmhouse hallway. Scale is canon
(D12/D19, deliberate, not a bug) — but the player experience of a boar-sized
companion deployed INSIDE a small interior is slapstick: he blocks sightlines
and squeezes between furniture. Report note: consider auto-putting-away or
shrinking deployment indoors, purely as staging.
Grandpa STILL not seen in any frame, 45+ frames into the run. If he has no
physical NPC in this scene, the whole opening dialogue is untethered — huge
staging finding. One hall sweep to check, then outside.
## Beat 28 — Grandpa found (088-090)
Grandpa Elias IS downstairs, correctly staged by his bed/bookcases, decent
idle, rig matches his portrait. FIND-DIALOGUE-RANGE refines: not a missing
NPC — an interact-range bug. The prompt/dialogue trigger reaches the entire
house including the upstairs spawn, so the scripted scene (gifts, starter,
naming) can complete without the player ever laying eyes on him.
Charming accident: B peeking through the doorframe behind Grandpa (089).
The interior itself is nicely dressed (bookcases, rugs, gear table).
Opening documented: 90 frames, findings so far — dialogue range (P1),
opening navigation/stairs affordance (P1), naming Esc/pause stacking (P1),
naming grid nav→accidental confirm (P1/P2), hotbar unbind via item move (P2),
prompt/hotbar overlap (P2), interior camera comfort (P1), plus positives
(writing voice, item cards, live portraits, five-cap teaching, B's model).
Action: out the front door. Village, gate objective, first wild encounter.
## Beat 29 — OUTSIDE (095-096)
Through the front door into morning meadow. Immediate impressions:
- POSITIVE: the camera is instantly comfortable outdoors — pulled back,
  stable, readable. Camera findings are interior-specific.
- POSITIVE: long shadows, warm light, grass variation — the meadow reads as
  a place. Wild rabbits visible ahead (Grandpa's hint immediately usable —
  good beat sequencing when the flow works).
- "Put B away" prompt persists over the hotbar outdoors (overlap finding
  stands). B follows behind (his shadow enters frame right).
Full house-exit macro committed (owner directive).
Action: sprint toward the rabbits (stamina check en route), first wild
encounter per Grandpa's instruction.
## Beat 30 — dead combat inputs outside encounters (099-107)
Approach scattered the rabbits (sprinting at them = wrong per Grandpa's hint,
fair). Then: combat_quick x3, combat_charged, combat_throw x2 — ZERO response.
No animation, no orb spent, no rejection feedback. FIND-DEAD-INPUTS (P2):
outside an active encounter the combat/catch buttons are silently inert; a new
player gets no explanation. (Ambiguity note: action-level injection, but these
are the exact actions the smoke tests drive combat with — leaning real.)
Also: pylon-like tower NW with a large bird — first Team Tether landmark seen.
Stamina arc during sprint was clean; bars refilled properly.
Action: Quests tab for guidance, then slow-walk stalk of the rabbits.
## Beat 31 — cancel doesn't work on the Quests tab (108-111)
Quest log: MAIN STORY gate objective (expandable, unexpanded), LOCAL REQUESTS
empty. No how-to for combat/catching anywhere a player would look.
FIND-CANCEL-QUESTS (P2): menu_cancel closed the shell from Backpack (beat 13)
and Map (beat 22) but NOT from Quests — my stalk inputs went into the open
menu (109-111 identical quest screens). Per-tab back-button inconsistency —
textbook systemic input finding.
Action: toggle shell closed via inventory key, re-run the stalk.
## Beat 32 — the menu that wouldn't close (112-115)
Inventory hotkey with the shell open on Quests SWITCHED to Backpack instead of
closing. Cancel works from Backpack/Map but not Quests; inventory key focuses
rather than toggles. FIND-MENU-EXIT (P1, consolidates FIND-CANCEL-QUESTS):
menu-exit behavior is inconsistent per tab and per key — a player learns they
cannot trust "back". Two full input batches died into the open shell.
(Confirmed good: orb card says Hotbar 1, 15 held — combat attempts really
spent nothing.)
Action: cancel from Backpack (known-good), then stalk the rabbits.
## Beat 33 — night falls mid-fumble (116-119)
Menu closed via Backpack-cancel (confirming the per-tab exit inconsistency),
and the world outside is now FULL NIGHT — the run's earlier deep shadows were
a live sunset. Positive: the tether beam glows teal across the dark sky —
first genuinely atmospheric moment of the run. Findings:
- OBS-19: night is near-absolute black at ground level; without carried light
  the meadow is unplayable-dark (character has a fill light, world does not).
- OBS-20: no HUD hint about time of day or the approaching night existed —
  dusk arrived unannounced (camp/bedroll teaching came from dialogue only).
Action: torch_toggle test (§13 artificial lighting), night walk, sky look.
## Beat 34 — torch is a rumor (120-123)
torch_toggle: no usable light appears. Either it no-ops without a torch item
(I have none — nothing taught crafting one) or the radius is negligible.
FIND-TORCH (P2): the dedicated lighting control does nothing discernible on a
fresh Day-1 night, silently. Pairs with FIND-DEAD-INPUTS as "controls that
fail without telling you."
Night positives: B looming overhead against the beam (122) is the game's
best accidental frame yet; the tether beam is a real navigation landmark.
Action: landmark navigation test — follow the beam to the pylon at night.
## Beat 35 — night navigation is minimap-or-nothing (124-126)
Off the beam's sightline, the night world offers zero ground-level
information; the minimap alone carried me. FIND-NIGHT-READABILITY (P2):
one excellent landmark (the beam) + otherwise unplayable darkness + no
working carried light = night is currently a UI experience, not a world one.
Action: navigate home by minimap, attempt to sleep in my own bed (the game
taught "Get up" from it — will it teach "lie down"?), then save/load test
from indoors.
## Beat 36 — the menu didn't open this time (130-131)
press inventory produced NO shell (131 = raw night world). Same input opened
the menu in beats 20 and 31. FIND-MENU-OPEN-FLAKY (P2, folds into the input-
reliability cluster): menu open is not dependable on the first press.
Action: retry with checkpoint shot right after the open press.
## Beat 37 — save works cleanly (133-134)
Save tab: 5 slots, autosave slot reserved, Load greyed when empty, explicit
"Saved to slot 2." confirmation. POSITIVE: best-behaved UI in the game so far.
P3: "1 creatures" grammar. OBS-21: autosave slot still empty this deep into
Day 1 (autosave = camp rest only) — a crash now loses the entire session.
Action: quit cleanly, relaunch, load slot 2, verify state round-trips
(position/night, B named B, hotbar contents, moved potion slot).
## BUILD SWAP (owner-directed)
Run 1 (frames 001-134) was on main@7547f386. Main moved (20 commits, incl.
harvest-node visibility fix OF20, torch OF24, naming keyboard OF25, menu focus
OF22/23, new NPC Tam OF30). All frames from 135 on are on main@9e4a90a1.
Run-1 findings stand as independent blind discoveries at the old SHA; several
were fixed in parallel by lanes and will be re-verified rather than re-filed.
Second driver boot on old build crashed silently (xvfb wrapper hung 35 min,
engine gone) — recovery folded into this swap. FIND-BOOT-CRASH noted (1 of 2
boots failed; worth watching, could be env-specific).
## Beat 38 — the long boot (run 3, main@9e4a90a1)
Run 2 (old build): genuine silent engine death at boot — logged FIND-BOOT-CRASH.
Run 3 (new build): NOT hung — engine loading at 225% CPU. But boot has gone
from ~2-3 min (old build, same env) to >10 min on the new 20 commits.
OBS-22: scene load cost jumped several-fold across those commits (17 shiny
colourway textures et al. suspected). Software-GL exaggerates absolute times;
the relative jump deserves a check on target hardware.
(Also: driver diagnosis lesson — the xvfb wrapper masks the engine PID;
fixed my process checks to match the real binary.)
## Beats 39-41 — new build opening re-run (frames 139-158)
Driver retired (its settle loop stalls on new main — repair-phase item); now
driving via REAL OS keystrokes (xdotool/XTEST) + X screenshots. This makes the
rest of the run an authentic keyboard-path test.
RE-VERIFIED on main@9e4a90a1:
- FIND-DIALOGUE-RANGE still present (Grandpa's full opening ran from upstairs).
- Wake camera GREATLY improved (whole room + ladder + rail readable, frame 135).
- Esc no longer stacks the backpack over naming (old FIND-NAMING-ESC fixed).
- Dialogue pacing: typewriter + advance = 2 presses/page, ~14 pages now (Revive
  page added); ~28 presses before the player can move. OBS-23.
- Revive mechanic taught diegetically, clean (frame 143).
NEW FINDINGS on the rebuilt flows:
- FIND-RETURN-KEY (P1): selector and naming both show the ⏎ glyph but respond
  ONLY to numpad Enter; main Return is dead on both (worked on old build's
  selector). Every KB player presses Return first.
- FIND-NAMING-FOCUS (P1): naming dialog opens with focus NOT in its text
  field; typing and even clicking the field do nothing; Tab (undiscoverable)
  is the only rescue. First-focus class, on the game's newest dialog.
- FIND-SELECTOR-GHOST (P2, regression suspect): unfocused starter portraits
  render ghost-white on new build (old build: full color) — coincides with
  shiny repaint plumbing (OF27/OF28). Needs code-phase verification.
Starter named "Bo" (real keyboard, after Tab rescue).
## Beats 42-44 — descent, round two (frames 164-184)
KB/M pass data: mouse-look works only after a world click (capture), large
mouse warps under-register at low FPS (must step turns), and the stairwell
remains the room's great riddle — the flight is a narrow slot behind the
parapet, entered from the north, descending south, with zero visual language
saying "stairs" from above. Second full run of failed descent attempts (this
time WITH working camera + real keys). FIND-OPENING-NAV is fully saturated.
WORKAROUND (explicitly logged per §3, owner-authorized "just respawn
downstairs"): using OF26's Settings-gated debug teleport to a named place to
exit the interior. All interior findings stand; nothing further to learn here.

## Beat 45 — P0 SOFT-LOCK FOUND (frames 222-239)
**FIND-SELECTOR-SOFTLOCK (P0).** Reproduced on main@9e4a90a1:
1. Reach the mandatory starter selector ("Three orbs, three companions").
2. Press Escape (the universal "what does this do" key for any new player).
3. The PAUSE SHELL opens ON TOP of the selector — the selector stays live
   underneath (its title and "look / choose" hints ghost through the shell).
4. Close the shell.
5. **The selector's confirm input is now permanently dead.** Arrow keys still
   move focus and the 3D portraits still spin, so the screen looks perfectly
   alive — but NOTHING selects a starter: KP_Enter, Return, E, Space, and a
   direct mouse click on a portrait were all tried; none confirm (239).
Consequence: the game cannot be started. The player is stuck at the opening
with no error, no message, and no recovery except quitting to desktop.
Same modal-stacking root cause as run 1's naming-screen Esc bug — but this
one does not recover.
Ambiguity noted honestly: this environment runs the game at a few FPS and
drops ~half of injected inputs, so single dead presses are not evidence.
This finding is NOT that: arrows kept working throughout at the same
injection cadence, and confirm failed across 5 different inputs + mouse over
~90 seconds. The asymmetry is the evidence.

## Beat 46 — menu legend is gamepad-only (frames 226-230)
FIND-LEGEND-GAMEPAD (P2): the shell footer reads "A Select   B Close" —
gamepad button names with no keyboard equivalent — while the neighbouring
hints correctly show both ("Q / LB Prev tab", "Tab / RB Next tab"). A
keyboard player who obeys the legend and presses the B key navigates to
Backpack instead of closing (228). Inconsistent within one legend row.
