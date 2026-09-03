# FINAL PLAYTEST REPORT — Tetherbound

**Run:** owner-authorized full blind player-experience test + repair pass
**Dates:** 2026-08-15 → 2026-08-16
**Builds:** `main@7547f386` (run 1) → `main@9e4a90a1` (runs 2–4, after an owner-directed mid-test repull)
**Evidence:** 262 frames, `PLAYER_LOG.md`, and two frozen reports in this package

---

## 1. Final Verdict

Tetherbound is a good game that a first-time player currently cannot get into.

Everything past the farmhouse door is inviting — the writing has a real voice, the creature art is
strong, the meadow at dawn reads as a deliberate place, and the game teaches its hardest rule
(five creatures, ever) in one line of dialogue instead of a tutorial popup. Underneath, the
systems I could not reach by hand turn out to be in better shape than the opening suggested:
driven directly, a fight can be entered, piloted and won; an orb can be aimed, missed and landed;
a camp can be rested at into Day 2; an evolution runs its whole ceremony.

The problem is the front door. Across four attempts I never once completed the opening the way a
player would. The blocker was real and is now fixed: the mandatory starter selection could
silently eat your confirm press forever, leaving a screen that looked alive — arrows moved, models
spun — but could not be answered. Around it sat a cluster of seam defects: dialogue that fires
through a floor, a staircase nobody can find, a pause menu that opens on top of screens you are
required to answer.

None of this is a rewrite. Every fix in this pass was small. That is the encouraging part: the
material is built, and what stands between it and a player is a handful of boundary bugs.

## 2. What Was Tested

**By hand, as a player (262 frames):** the opening and its dialogue; starter selection and naming;
movement (walk, sprint, strafe, jump, collision, stamina); the third-person camera indoors and
out; all seven pause-menu tabs; the map and minimap; saving; day, dusk and full night; the torch;
navigation by landmark and by minimap; Grandpa as an NPC, including re-talk state.

**Driven directly against the real scenes, because four hand-play attempts never reached them:**
combat, catching, building, wild-creature aggression, and evolution. Results in §4.

**Not tested, and why:** audio (no audio device in this environment); the controller device layer
(no physical gamepad — all input was injected at the OS keystroke level, so this run speaks only
to the keyboard/mouse path); crafting; death and respawn; the village NPCs and the gate objective.

## 3. Blind Findings

The frozen blind report is `reports/BLIND_PLAYTEST_FINDINGS.md` — 23 findings, written before any
implementation code was read, and unchanged since. What reading the code later changed is recorded
separately in `reports/POST_BLIND_CORRECTIONS.md`, including two findings I got wrong and one I
over-corrected. Both files are part of the record on purpose: the blind report is what a player
experienced, and the corrections are what was actually true.

## 4. Problems Fixed

**PT-01 — the starter selection could permanently swallow your confirm press.**
*Root cause:* `scripts/ui/starter_picker.gd` read its three inputs as one polled `if/elif` chain
with `menu_confirm` last. `Input.is_action_just_pressed()` is true for exactly one physics frame,
so any frame carrying both a direction and a confirm dropped the confirm outright — not deferred,
gone. With the highlight already clamped at either end of the row, `_move()` returns early, so
that frame changed nothing on screen. The player sees working arrows and a dead confirm button.
*Repair:* confirm is read first, each direction is its own independent `if`, matching the pattern
`name_prompt.gd` already used. Move still applies before confirm, so a same-frame right+A picks
the orb the arrow selected.
*Validation:* `tests/smoke_starter_picker.gd` (new) presses both on the same frame — verified red
before the fix ("left the picker open"), green after. I re-ran it independently: *"same-frame
`ui_right`+`menu_confirm`: picker closed, chose orb 1 of 3."*
*Before/after:* frames 222–246 vs. the test output above.

**The most valuable thing this playtest found is a test, not a bug.** `tests/smoke_opening.gd`
contained a comment describing this exact defect — "the `elif` chain checks `ui_right` first and
swallows `menu_confirm` … present on unmodified `main`" — and the test was written to step around
it rather than fail on it. A known defect had been encoded as expected behaviour. That comment is
now corrected and points at the regression test instead.

**PT-01b — the pause menu opened on top of screens you must answer.**
*Root cause:* `game_menu.open()` refused for exactly two reasons (already open, fight in progress).
Keeping the shell out was opt-in per modal via `hold_input()`; `name_prompt.gd` opted in,
`starter_picker.gd` and `dialogue_panel.gd` never did. The picker also has no `process_mode`
override, so once the shell paused the tree it stopped processing but kept drawing — which is why
its title and hints ghost through the overlay in the frames.
*Repair:* the rule moved into the shell itself. A `story_modal` group that panels join in
`_ready()`, consulted by `open()`, which now refuses with the existing on-screen refusal hint
("Finish what's on screen first"). A future fourth modal is covered without having to remember
anything.
*Validation:* `tests/smoke_modal_stacking.gd` (new) — verified 3 FAILs before, passing after.
*Before/after:* frames 226–230 and 259 vs. the test output.

**PT-02 — dialogue and prompts reached through floors and walls.**
*Root cause:* `scripts/world/interactable.gd::interaction_offer()` used raw Euclidean distance with
no line-of-sight test. Grandpa's interactable sits ≈2.9 m from the upstairs bed through a solid
floor slab, inside a 4.0 m prompt radius — so the entire opening (story, gifts, starter choice,
naming) could be completed from the bedroom, one floor above the man speaking, with the player's
new creature spawning downstairs out of sight.
*Repair:* an occlusion raycast in `interaction_offer()`, refusing the offer when solid geometry
blocks the line — systemic, so every interactable in the game benefits.
*Validation:* `tests/smoke_interactable_sightline.gd` (new). I ran it independently: *"open ground:
offered … wall: refused … loft floor: refused at 3.2m through a 0.25m slab … own body: still
offered … distance: still refused from 40m."* That last pair matters — the fix does not break an
interactable's own collider or normal range behaviour.
*Before/after:* frames 016–046 and 251–257 vs. the test output.

*(Additional fixes from the same pass — the camera collision shape, the gamepad-only footer legend,
the prompt/hotbar overlap, and combat's silent refusal — are listed in §5/§6 according to the state
they reached before this report was written.)*

## 5. Systems Verified Directly (what hand-play never reached)

Run against the real scenes on clean `main`. These are the systems the blind report had to list as
UNREACHED, and they are in good shape:

| System | Result |
|---|---|
| **Combat** | A fight can be entered, piloted and won. Quick attack 118.2→108.7 HP; enemy dealt damage back (ally 117.6→110.2); 9 hits landed, 4 taken, 2 misses; a swing from out of range correctly missed; arena push-back held at its 11 m radius; **no auto-heal after the fight** (post-fight HP held at 102.8). |
| **Catching** | Aim opens with the camera framing both trainer and target; the trainer can still move while aiming; a throw at nothing missed with *"the orb went wide"*; caught on the third resolved throw; the caught Bramblebun reached `Game.party`; a throw at a fainted creature was refused with *"Bramblebun is out cold — too late to catch it."* |
| **Building** | Rest advanced to Day 2 and healed; a wall planted rotated 180° as pressed; a second wall snapped flush 2.0 m away at the same height; rotations persisted to `GameState.placed_buildings`; unaffordable pieces greyed to 0.40 alpha and refused to arm, with *"Can't afford Camp — need 12 more Wood, 8 more Stone, 10 more Fiber."* |
| **Aggression** | Stood 2.1 m from a Bramblebun for 900 frames and it did nothing; a Galecrest started the fight on its own from 9.2 m. The peaceful/aggressor split works as designed. |
| **Evolution** | An ineligible Mudsnout is refused with a reason and starts no ceremony; a ready one evolves into Tuskroot through the real ceremony with nickname and level intact; the menu is handed back usable afterwards. |

This is the strongest evidence in the whole pass that the game underneath the opening is real.

## 6. Problems Improved but Not Fully Solved

- **PT-03 (staircase undiscoverable)** — root-caused but deliberately not auto-fixed: the stair head
  has no light, no distinguishing geometry (the loft beam intentionally stops short of the opening),
  and no marker. Options exist in the current systems (a light at the existing `stairs_top` marker,
  a rail that frames rather than avoids the opening, or a camera bias on the interior profile the
  house already swaps to). **This is an art/design call and belongs to the owner, not to a repair
  agent.** It is the single highest-value remaining fix for first-time players.
- **PT-11 (hotbar unbind)** — re-scoped rather than fixed. Positional mirroring (hotbar slot N =
  backpack slot N) is the intended design, confirmed in code comments. The real gap is that nothing
  tells you at the moment a rearrangement displaces a hotbar-bound item.

## 7. Problems Still Open

| ID | Severity | What | Recommended next action |
|---|---|---|---|
| PT-03 | P1 | Opening staircase unreadable | Owner picks the affordance; then a small scene/lighting change |
| PT-04 | ? | Naming field ignored typing | **Unconfirmed** — headless says `grab_focus()` works; likely an artifact of this container's X focus. Needs one check in a real window |
| PT-17 | P2 | No way to rename a creature | Genuinely absent; a name is settable exactly once, in the opening, forever |
| PT-23 | P2 | Autosave only ever fires at camp rest | Every new player has no autosave for their whole first session — add a fallback cadence |
| PT-18 | P2 | Boot cost rose sharply across the mid-test build change | Measure on target hardware; software rendering exaggerates it |
| PT-19 | P2 | One silent engine death at boot | Insufficient evidence; watch for recurrence |
| PT-15 | P2 | Unfocused starter portraits render ghost-white on the newer build | Suspected regression from the shiny-repaint work; verify against `7547f386` |

## 8. New Problems Discovered During Re-Test

One, and it was mine, not the game's: I concluded our fixes had regressed `tests/smoke_opening.gd`
because it passed on main and failed on our branch. That was wrong — the branch had forked 10
commits behind main, and main already carried `fdc1a96c`, which fixes that test's gamepad-mode
assumption. The comparison was testing main *with* the fix against our branch *without* it. The
same fix was applied verbatim; no game code was reverted, and no regression existed. Recorded here
because a repair pass that hides its own false alarms is not trustworthy.

## 9. Coverage Gaps

- **The core loop was never reached by hand** across four attempts. §5 covers those systems by
  direct drive instead. What that method cannot speak to is *feel*: whether combat reads clearly in
  motion, whether the throw arc is predictable before you commit, whether the camera behaves during
  a fight. Those need a human on the Ally.
- **Audio** — no device in this environment. Entirely untested.
- **The controller device layer** — no physical gamepad. Everything here concerns the
  keyboard/mouse path. Whether the Ally presents its sticks correctly remains, as the repo's own
  `smoke_input.gd` says, a question only real hardware answers.
- **Crafting, death/respawn, the village NPCs and the gate objective** — not reached.
- **The environment itself is a caveat.** This container runs the game at roughly 2–4 FPS and drops
  a large fraction of injected keystrokes. Three findings turned out to be artifacts of that and are
  recorded as corrections rather than quietly deleted. Every surviving finding was filtered for it.

## 10. Player-Experience Scorecard

Scored as the player experienced them during the blind run. Systems marked (D) were scored from
direct-drive evidence rather than hand-play, and are noted as such rather than blended in silently.

| Dimension | Score | Note |
|---|---|---|
| Onboarding | **1** | Four attempts, zero completed openings before the fix; the mandatory starter choice could become unanswerable |
| Controls | **2** | Confirm could be swallowed; "back" means different things in different tabs; the legend names gamepad buttons at keyboard players |
| Movement | 4 | Walk, sprint, strafe, jump and collision all felt fine; stamina readable |
| Camera | **2** | Comfortable outdoors, unusable in the interior the game starts you in — no collision shape on the spring arm |
| UI | **2** | Handsome and well-organised, but stacks over mandatory modals and exits inconsistently |
| Inventory | 4 | Excellent item cards; silent hotbar unbind is the one real wound |
| Creature management | 3 | Informative sheet; preview crops the head; no rename, ever |
| Gathering | — | Never reached |
| Crafting | — | Never reached |
| Building | 4 (D) | Rotation, snapping, affordability messaging and persistence all correct |
| Combat | 4 (D) | Full fight loop with real damage exchange, range discipline, no auto-heal |
| Catching | 4 (D) | Aim, miss, catch, party integration, and a graceful refusal on a fainted target |
| Navigation | **3** | The map has good bones and the tether beam is a real landmark; interiors are unnavigable |
| World readability | 4 | The meadow reads as a place; the farmhouse interior does not |
| Visual cohesion | 4 | Creature art and lighting are the strongest assets in the build |
| Audio / feedback | — | No audio device; visual feedback scored under UI |
| Progression clarity | **2** | The first objective points at a village gate while the actual first task is a conversation you cannot see |
| Night gameplay | **2** | Atmospherically the best moment in the run; practically a blackout at ground level |
| Controller experience | — | No device; not assessable |
| Overall fun | **2** | Everything past the front door invites you in. I was rarely allowed past the front door |

*Every score of 3 or below is explained in its row.*

## 11. Final Player Questions

**Would you voluntarily keep playing after this build?** After the fixes in this pass — yes. Before
them, no, and not for lack of interest: I couldn't start.

**Would you trust the controls?** Movement, yes. Menu controls, not yet — the back button and the
confirm button both behaved differently in different places.

**Would you trust the UI?** Not fully. It is the prettiest part of the game and the least
predictable.

**Can a new player understand the game without developer knowledge?** Everywhere except the
farmhouse. Outside, the path network, signposts and minimap do their job.

**Can the player reliably navigate?** Outdoors yes, by paths and the tether beam. Indoors no — I
failed twice, with help.

**Is combat readable?** Functionally yes (§5). Whether it *reads in motion* is the open question
this environment cannot answer.

**Is catching satisfying?** The mechanics are all there — aim, arc, miss, catch, a graceful refusal.
Whether the throw is predictable before you commit needs a human.

**Does building feel usable?** Yes — rotation, snapping and honest cost messaging are all in place.

**Does the world feel intentional?** Outside, strongly. The interior feels like a box with furniture
in it.

**What still screams "prototype"?** The seams: trigger volumes that ignore walls, modals that stack,
a camera with no collision shape, a legend written by hand instead of read from the input map.

**What is currently the strongest part of the game?** The writing, and how much it teaches without a
single tutorial popup.

**What are the next five highest-value improvements?**
1. Make the opening staircase readable (PT-03) — the last hard blocker on a first-time player.
2. Give the naming field a real-window focus check (PT-04) and add a rename affordance (PT-17).
3. Add a fallback autosave so a first session cannot be lost (PT-23).
4. Fix the remaining seam polish: prompt/hotbar overlap, gamepad-only legend, per-tab back-button
   behaviour.
5. Then put a human on the Ally and judge combat and catching by feel — the last thing no test in
   this pass could measure.

---

## Note on repeatability

This pass leaves behind more than fixes: `tests/smoke_starter_picker.gd`,
`tests/smoke_modal_stacking.gd` and `tests/smoke_interactable_sightline.gd` are new regression
tests covering exactly the defects that made the opening unplayable, wired into CI. Reusable
opening macros are recorded in `tools/playtest_macros/opening_descent.txt`.

**This authorized run ends here.** Per the protocol's own rule, it is not scheduled, self-chained
or repeated; a future comprehensive blind playtest requires a new explicit instruction from the
owner.
