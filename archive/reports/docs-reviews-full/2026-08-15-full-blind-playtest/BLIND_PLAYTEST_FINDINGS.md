# BLIND PLAYTEST FINDINGS — Tetherbound

**Run:** owner-authorized full blind player-experience test
(`ralph/planning/TETHERBOUND_OWNER_ONLY_FULL_BLIND_PLAYTEST.md`)
**Dates:** 2026-08-15 → 2026-08-16
**Builds under test:** `main@7547f386` (run 1), then `main@9e4a90a1` (runs 2–4, after the
owner directed a mid-test repull that brought in 20 commits including OF20–OF33)
**Evidence:** 239 numbered frames + `PLAYER_LOG.md` in this directory
**Status: FROZEN.** Written before any gameplay implementation code was read, per §36/§37.
Anything learned later goes in `PLAYTEST_REPAIR_PLAN.md`, not here.

---

## Executive Summary

Tetherbound's *material* is genuinely good. The writing has a real voice, the creature art is
strong, the item cards have personality, the meadow at dawn looks like a place someone made on
purpose, and the game teaches its hardest rule — five creatures, ever — in a single line of
dialogue without a tutorial popup. There is a game here worth finishing.

What a first-time player actually experiences, though, is a wall of input and staging problems
before any of that material can be reached. In four attempts I never once completed the opening
as a player would: I finished the story beats by talking to a man through a floor, I spent
twenty-five frames unable to find a staircase in a one-room loft, and my final attempt ended in
a **P0 soft-lock where pressing Escape during the mandatory starter choice permanently kills the
ability to choose a starter** — arrows still move, portraits still spin, nothing can be
selected, and the only exit is quitting the game.

The core loop — gathering, combat, catching — remains **untested**, not because it was skipped
but because four separate runs never got far enough to reach it. That is the single most
important sentence in this report.

The pattern across nearly every problem found is the same: **individual pieces are built well
and the seams between them are not**. Dialogue is good; its trigger volume covers the whole
house. Naming works; it opens without keyboard focus. The pause shell is well-organised; it can
open on top of mandatory modals and poison them. The map is handsome; it cannot help you find a
staircase. Almost nothing here is a rewrite — most are boundary and focus-handling bugs, which
is good news for repair.

---

## Playthrough Narrative

**Run 1 (`7547f386`).** Woke in the loft. The prompt said "Talk to Grandpa" with no Grandpa in
sight, so I pressed it — and the entire opening played out from the bedroom: the Team Tether
story, the gift of orbs and potions, the starter selection, the naming grid. I never saw him.
Trying to leave, I got wedged in a corner for four attempts while the camera alternated between
clipping into my character's skull and being blocked by furniture. Pressing Escape at the naming
grid (which the on-screen hint said would delete a letter) opened my backpack over the naming
modal; my subsequent inputs rearranged potions and silently unbound my healing item from the
hotbar. A mis-navigated grid press named my creature "B". I circled the same room four times,
checked the map, jumped off a mezzanine, stood on a railing, and only reached the ground floor
after the owner told me where the stairs were. Grandpa was down there the whole time, correctly
staged by his bed. Outside was lovely. Night fell, the torch did nothing, and I navigated home by
minimap alone. Saved to slot 2 and quit to test persistence.

**Runs 2–4 (`9e4a90a1`).** A silent engine death, then a build swap on owner instruction, then
two more attempts. The new build visibly improved things — the wake camera now shows the whole
room including the ladder, and Escape no longer stacks the backpack over naming. But the naming
dialog now opens with no keyboard focus in its own text field (Tab is the only rescue, and
nothing says so), the ⏎ glyph shown on screen responds only to the numpad Enter, and the final
run ended in the P0 soft-lock described above.

---

## Coverage

| System | Status | Note |
|---|---|---|
| Opening / dialogue | **Fully tested** | Four times, on two builds |
| Starter selection & naming | **Fully tested** | Source of the P0 |
| Movement (walk/sprint/strafe/jump/collision) | Fully tested | Indoors and out |
| Camera | **Fully tested** | Interiors exhaustively |
| Menus (Backpack, Creatures, Map, Quests, Save, Settings, Build) | Fully tested | All seven tabs opened |
| Save / load | Partially tested | Save confirmed working; cross-build load never verified |
| Day / night / weather | Partially tested | Day, dusk, full night seen; dawn not |
| Navigation (minimap, map, landmarks) | Partially tested | Night nav done; no destination reached |
| NPCs | Partially tested | Grandpa only; villagers and Tam never reached |
| Lighting tools | Tested — negative result | Torch produced no usable light |
| **Gathering** | **UNREACHED** | Never reached a harvest node |
| **Combat** | **UNREACHED** | Zero encounters entered |
| **Catching** | **UNREACHED** | Zero orbs thrown |
| **Item use / consumables** | **UNREACHED** | Inspected, never consumed |
| **Crafting** | **UNREACHED** | — |
| **Building / camp / rest** | **UNREACHED** | Build menu seen; nothing placed |
| **Party management** | Partially tested | Creature sheet read; no second creature to manage |
| **Death / failure** | **UNREACHED** | — |
| Audio | **Not assessable** | No audio device in this environment |
| Controller (device layer) | **Not assessable** | No physical gamepad; inputs injected at binding level |

---

## Findings by Severity

### P0 — Blocker

**PT-01 — Pause menu during starter selection permanently breaks the starter selection**
*System:* UI modal stacking / input focus · *Frequency:* reproduced once, deterministic in sequence
*Frames:* 222–239 · *Blocked further testing:* **yes — ended the run**

- **Player action:** At "Three orbs, three companions. Choose one.", press Escape — the key any
  new player presses to see what's available.
- **Expected:** Either nothing, or a pause menu that closes cleanly and returns me to the choice.
- **Observed:** The pause shell opens *on top of* the selector; the selector remains live
  underneath (its title and "look / choose" hints ghost through the shell, frames 226–230).
  After closing the shell, arrow keys still move focus between the three creatures and the 3D
  portraits still rotate — but **no input can confirm a choice**. KP_Enter, Return, E, Space and
  a direct mouse click on a portrait were each tried over ~90 seconds; none worked (239).
- **Player impact:** The game cannot be started. No error, no message, no recovery except
  quitting to desktop. A player who presses Escape once at the most natural moment to press it
  loses the entire session.
- **Why this is not an artifact of the test environment:** this environment does drop roughly
  half of injected inputs at its frame rate, so a single dead press proves nothing. Arrow keys
  kept working throughout at the identical injection cadence while five different confirm inputs
  plus the mouse all failed. The asymmetry is the evidence.

### P1 — Major player-experience problems

**PT-02 — The entire opening can be completed without ever seeing Grandpa**
*Frames:* 016–046, 214–216 · Both builds.
The "Talk to Grandpa" prompt and its dialogue trigger reach the upstairs bedroom where the player
spawns. Story, the gift of orbs/potions/revives, the starter choice and naming all complete from
beside the bed, one floor above the man speaking. His script stages a scene that is not happening
("Sit and eat — the bread's still warm"). Grandpa is correctly built and correctly placed
downstairs (088–090); this is a trigger-volume problem, not a missing NPC. It also strands the
new creature: it spawns at the staged location, so the player's first companion is invisible to
them at the moment they receive it.

**PT-03 — The staircase out of the opening room is effectively undiscoverable**
*Frames:* 006–085, 164–184 · Both builds.
Two independent attempts, ~40 frames, a map check, a full 360° panorama, a mezzanine jump and a
railing perch failed to find the way down. The flight is a narrow slot behind a parapet in the
room's north-west corner, entered from the north and descending south; from every vantage a
player naturally occupies it reads as more parapet. Nothing — lighting, geometry, objective text,
or camera framing — says "down is here". The owner had to intervene twice during testing. The
new build's improved wake camera helps but does not solve it.

**PT-04 — The naming dialog opens without focus in its own text field**
*Frames:* 146–159 · New build.
"Name your Terrapup" appears with a text field that is not focused. Typing does nothing. Clicking
directly on the field does nothing. Tab — undiscoverable, and shown nowhere — is the only way in.
This is the very first text entry in the game, and it is mandatory.

**PT-05 — On-screen ⏎ glyph responds only to the numpad Enter**
*Frames:* 145–158 · New build.
Both the starter selector and the naming dialog display the Return glyph as the confirm
affordance. The main Return key does nothing on either; only KP_Enter works. Most keyboards a
player uses have no numpad at all.

**PT-06 — "Back" behaves differently in different menus**
*Frames:* 108–116 · Run 1.
Cancel closed the shell from Backpack and Map, but did nothing on Quests. The inventory key
switched tabs rather than toggling the shell closed. Two full batches of movement input were
swallowed by a menu I believed I had closed. A player stops trusting the back button.

**PT-07 — The third-person camera is not usable in interiors**
*Frames:* 008–014, 050–054, 164–171 · Run 1 heavily; improved but present on new build.
In the opening room the camera alternates between being blocked by furniture (filling the lower
third of frame) and collapsing inside the character's head. Half of a four-point panorama
returned unusable views. This is also a contributing cause of PT-03: the player cannot get the
overview that would reveal the stairs.

### P2 — Noticeable quality and friction issues

**PT-08 — Combat and catch inputs are silently inert outside an encounter** (099–107). Quick
attack, charged attack and orb throw produced no animation, no message, no orb spent. Nothing
teaches the player that these buttons need an encounter, so they read as broken.

**PT-09 — The torch control produces no usable light** (120–123). On Day 1 night, `torch_toggle`
yielded nothing discernible. Either it silently no-ops without a torch item — with no message
saying so — or its radius is negligible.

**PT-10 — Night is unplayably dark at ground level** (117–129). With no working carried light,
the world offers no ground-level information after dark; navigation becomes a minimap-only
exercise. Atmospherically it is excellent (see Positives); practically it is a blackout.

**PT-11 — Moving an item in the backpack silently unbinds it from the hotbar** (038–046). After
an accidental rearrangement, the potion stack was gone from hotbar slot 2 with no indication. The
player loses their heal without being told.

**PT-12 — The context prompt renders on top of the hotbar** (083, 085, 093). "Put B away" and
"Talk to Grandpa" overlap the hotbar icons rather than sitting clear of them.

**PT-13 — The menu footer legend names gamepad buttons with no keyboard equivalent** (226–230).
"A Select   B Close" sits beside correctly dual-labelled hints ("Q / LB Prev tab", "Tab / RB Next
tab"). A keyboard player obeying the legend presses B and navigates to Backpack instead of
closing. Inconsistent within a single row.

**PT-14 — The creature preview crops the creature's head out of frame** (062). On the Creatures
tab, the model preview is framed so the head is above the visible area.

**PT-15 — Unfocused starter portraits render ghost-white** (219–239, new build only). On
`7547f386` all three portraits were fully coloured; on `9e4a90a1` the two unfocused ones render
as pale silhouettes. Suspected regression from the shiny-repaint work (OF27/OF28) — flagged for
verification, not asserted.

**PT-16 — Opening the menu is not reliable on the first press** (130–132). One press produced no
shell; an identical press moments later did.

**PT-17 — No way to rename a creature** (062). The name is permanent from a single mandatory
grid interaction, which in run 1 produced "B" from one mis-navigated press, with no confirmation
step and no rename affordance anywhere in the Creatures tab.

**PT-18 — Boot cost rose sharply across the mid-test build change.** Run 1's build reached first
frame in roughly two minutes; `9e4a90a1` took materially longer under identical conditions.
Software rendering exaggerates absolute numbers, but the relative jump is worth a check on target
hardware.

**PT-19 — One silent engine death at boot** on `7547f386` (one of two launches), with no error
output. Recorded because save-loss and startup failures are the highest-cost class of bug;
insufficient evidence to characterise further.

### P3 — Minor polish

**PT-20** — "Slot 2 — Day 1, 1 creatures" (134): plural grammar.
**PT-21** — Save UI "slot 2" writes `slot_1.json` on disk: off-by-one between UI label and file.
**PT-22** — Starter portrait rotation frequently parks on a rear view, so the player's first look
at their creature is its back (026, 030).
**PT-23** — The autosave slot was still empty deep into Day 1 (134); autosave appears to be tied
only to camp rest, so a crash costs the entire session.

---

## Positive Findings — protect these

1. **The dialogue voice.** Warm, specific, and economical. "I heard the floorboards." "So you go.
   And you don't go empty-handed." It sounds like a person, not a quest dispenser.
2. **Teaching through fiction, not popups.** The five-creature cap — the game's hardest constraint
   — arrives as "five is all any trainer carries, and you've just spent your first." Revives are
   introduced the same way. This is the best tutorialisation in the build.
3. **Item card writing.** "It works because your throw does the work, not the orb." Flavour text
   that teaches a mechanic in one sentence.
4. **Live rotating 3D portraits in the starter selector.** A lovely, confident touch.
5. **Creature art.** Terrapup earns its status as the quality benchmark — teal eyes, stone mantle,
   badger stripes all read instantly at portrait size and at full scale in the world.
6. **The Save tab.** The best-behaved interface in the game: clear slots, greyed-out unavailable
   actions, an explicit "Saved to slot 2." confirmation.
7. **Conversation state is sound.** Re-talking to Grandpa after the opening gives fresh,
   contextual dialogue and does not re-run the gifts. No duplication, no loop.
8. **The world outside.** Long dawn shadows, grass colour variation, a legible path network. The
   meadow reads as a deliberate place.
9. **The tether beam at night.** The single strongest image in the run — a teal column across a
   black sky that doubles as a genuine navigation landmark.
10. **The outdoor camera.** Comfortable, stable and well-distanced. The camera problems are
    specifically an interiors problem.
11. **The map's bones.** Fog of war, a "Surveyed: 3%" counter and a teasing "?" POI — good
    structure to build on.
12. **The new build's wake camera** is a clear improvement: the whole room, including the ladder,
    is legible from the first frame.

---

## Top 10 Player-Experience Problems

1. **PT-01** — Escape during starter selection makes the game unfinishable (P0).
2. **PT-03** — The opening room's exit cannot be found.
3. **PT-02** — The whole opening plays out without meeting the character delivering it.
4. **PT-04** — Mandatory text entry that ignores the keyboard until you find Tab.
5. **PT-07** — Camera unusable in the interior the game starts you in.
6. **PT-06** — "Back" means different things in different menus.
7. **PT-05** — The confirm glyph on screen is not the confirm key on the keyboard.
8. **PT-08** — Core-loop buttons fail silently outside encounters.
9. **PT-10 / PT-09** — Night is a blackout and the light source does nothing.
10. **PT-11** — Inventory rearrangement silently disarms your hotbar.

---

## Player Verdict

**Would you voluntarily keep playing?** Not in this state — not because the game is bad, but
because I was never allowed to start it. Four attempts, zero fights, zero catches. If the opening
worked, I would absolutely keep going: everything past the front door was inviting.

**When was the game most fun?** Walking out the front door into the meadow at dawn, and standing
under the tether beam at night with my creature's silhouette against it.

**When was it most frustrating?** Circling one bedroom for twenty-five frames looking for stairs
— narrowly ahead of discovering that Escape had permanently broken my starter choice.

**What felt unfinished?** The seams. Trigger volumes, modal layering, focus handling, prompt
glyph mapping — the joins between well-built pieces.

**What felt surprisingly polished?** The writing, the creature art, the item cards, the Save tab,
and the outdoor lighting.

**What confused you?** Being told to talk to someone who wasn't there; a room with no visible
exit; a naming field that ignored my typing; a legend telling a keyboard player to press "A".

**What did you have to guess?** Where the stairs were (and I guessed wrong, repeatedly). That Tab
would rescue the naming field. That numpad Enter would confirm. That combat buttons needed an
encounter.

**Which controls did you stop trusting?** Escape and Back, absolutely — Escape cost me the run.
Then the confirm key, after the glyph lied about it.

**Which UI did you stop trusting?** The pause shell — because it opens where it shouldn't, closes
inconsistently, and in one case took the game down with it.

**Which mechanic most needs another design/polish pass?** The opening as a staged sequence: where
the player is when it fires, where their creature appears, and how they get out of the room.

**What are the three most important changes?**
1. Make mandatory story modals refuse to be interrupted, and restore their input focus when they
   are (fixes PT-01, PT-04, and run 1's naming-stack bug at one stroke).
2. Bound the opening dialogue trigger to Grandpa's actual room, so the scene happens where it was
   written to happen — and the player's first creature appears in front of them.
3. Make the way out of the opening room readable: light it, frame it, or point at it.

---

## Coverage Gaps and Why

**The core loop was never reached.** Gathering, combat, catching, item use, crafting, building and
death/failure are all untested — four runs ended before them (PT-01 ended the last one outright).
Per the owner's scoping decision, these move to the post-repair validation playthrough, which
becomes the first real test of the game's heart.

**Audio could not be assessed** — no audio device in the test environment.

**The controller device layer could not be assessed.** No physical gamepad exists here; input was
injected at the OS keystroke and binding level. Everything in this report concerns the
keyboard/mouse path, which is the honest framing. Whether the ROG Ally presents its sticks
correctly remains, as the repo's own `smoke_input.gd` says, a question only real hardware answers.

**Test-environment caveat, stated plainly.** This container runs the game at a few frames per
second under software rendering and drops roughly half of injected inputs. Any finding that
rested on a single unresponsive press has been marked ambiguous or excluded. The findings above
survive that filter — by reproduction across runs and builds, by asymmetry (one input working
while another fails under identical conditions), or by direct visual evidence in the frames.
