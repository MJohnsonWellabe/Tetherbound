# Owner playtest — 2026-08-23 (ROG Ally, post-integration-W1 build)

Newest owner evidence. Per START_HERE §3, a fresh owner reproduction
reopens any older supposedly-fixed item where they conflict, and outranks
green tests. Items numbered OP23-xx.

## P0 — performance and control

- **OP23-01 ROG performance is awful — "feels like ten frames per
  second."** The single biggest problem. OP21-01's two root-cause fixes
  (arbiter O(n²), scatter bake) are on main, so either they are
  insufficient on-device or something since regressed it (candidates:
  143k scattered props at density 0.05, collision streaming, HUD
  redraws). Needs an on-device profile or a synthetic frame-time harness
  that can rank costs, not container guesses.
- **OP23-02 Combat camera control is lost at Meadows Hall battles**
  (teleported to the stronghold, battle start takes the camera, can't
  see). `smoke_trainer_battle_camera.gd` covers the VILLAGE Mira path and
  is green — the stronghold/gauntlet battle path is a coverage hole.
  Reopens the OP21-05 class for non-village battles.

## P1 — experience-vs-test gaps (tests green, player still fails)

- **OP23-03 The map is still a black rectangle.** The map-fog fix seeded
  ~0.12% of the map — enough to pass `test_map_fog`'s ">0%" assertion,
  experientially invisible. The 2026-08-22 ruling means VISIBLY revealed
  village + roads. Fix the reveal radii to the experience, and raise the
  test's floor to something a player can see. Zoom works; **zoom level
  should persist** (new sub-item).
- **OP23-04 The opening objective chain teaches nothing.** "Find a way
  through the village gate" is the first task and makes no sense. Owner
  directive, Palworld-style: a guided sequential tutorial — it tells you
  the NEXT thing to do (gather, catch a pal, etc.) until tournament
  entry, surfacing only the current step, not the full list in a menu.
  Whatever prerequisite you haven't done, it points at next, until all
  are cleared. This supersedes the current first beats of
  objectives.json's presentation (the beat DATA can stay; the
  presentation and ordering must become a guided checklist).
- **OP23-05 Day/night transition flashed straight to night** instead of
  progressing. And **OP23-06 night is back to too-dark** (regression of
  a previously fixed item), worst immediately after nightfall.

## P1 — presentation

- **OP23-07 TMs still look like little cards on the ground, not orbs.**
- **OP23-08 Grandpa's village layout: his house sits outside the town
  centre but not far enough to read as deliberate — placeless.**
  (Extends OP21-17, still open with the visual coordinator.)
- **OP23-09 HUDs take up far too much screen.**
- **OP23-10 Torch hold still looks unnatural.** (Reopens the OP21-24
  class for the torch pose specifically.)
- **OP23-11 No body in the bed at the opening wake-up.**
- **OP23-12 Player-built roofs don't plane in the right spots.**
  (Reopens OP21-09's class — planes/junctions, not size.)

## P1 — systems/UX

- **OP23-13 Auto-run is needed.** (Owner feature directive.)
- **OP23-14 Bond progression is too slow — one percent per action is
  worthless.** Retune the bond curve to feel meaningful.
- **OP23-15 Traits need explanations next to them** in the UI.
- **OP23-16 With five creatures, the HUD still shows an empty sixth
  slot while the menu correctly shows five.** (Hard rule adjacency:
  nothing may imply a sixth slot.)

## The owner's process question, answered honestly

"All of this is the type of stuff I'd expect a playwright test, full
playthrough agent, and blind visual test agent to be finding. Should I
expect that?" — Yes for most of it, and the gaps have names:

1. **Tests asserting minimums instead of the experience** (OP23-03: 0.12%
   reveal passes ">0%"). Fix: acceptance floors stated in player terms.
2. **Coverage holes off the golden path** (OP23-02: village battle camera
   is smoke-tested, stronghold battles aren't; night TRANSITION had no
   test, only night-state color values).
3. **The full-playthrough agent (Gate F) has not run yet** — it is gated
   on Gate B's continuous run going green and is exactly the pass that
   should catch OP23-04/05/13-16 class issues. This playtest happened
   before that pass existed.
4. **Blind visual judges DID flag** several presentation items
   (village layout, torch/pose class, HUD legibility class) — those are
   in the open visual ledger, not yet landed.
5. **On-device performance (OP23-01) is the one class the container
   cannot see.** It needs a perf harness with frame-time budgets per
   subsystem, or owner-device profiles.

## Standing consequence

Every OP23 item above enters the active ledger. OP23-01 outranks
everything (SHIP). OP23-02/03/04/05/06 are SHIP-class for the chapter.
The rest are QUALITY. Coordinators (ralph/lanes/COORDINATORS.md) must
read this file first per START_HERE read order.
