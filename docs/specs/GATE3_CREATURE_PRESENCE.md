# Gate 3 — Creature presence contracts

**Status:** design contract, G3-READS-AS-CREATURE-GAME lane (Fable), 2026-09-04. Written
against `ralph/G3-LAND-0904` (`44f06cf9`). Read-only on code, data, assets and tests;
every "do" below is an instruction to a lane, not a change already made.
**Owning roadmap lines:** `docs/ROADMAP.md` 2.15 (*the visual evidence pipeline cannot
show a creature*) and Gate 2's blind-judge clause (Bar B), carried into Gate 3.

Precedence is `CLAUDE.md`'s: a newer owner directive in `docs/owner/` beats this file;
this file beats a prompt in `docs/prompts/`. Where this file proposes changing something
shipped, it says what is there now, why it does not reach the player, and what to do
instead. Where canon is silent and the choice is material, §7 lists it as an owner
question rather than deciding it.

Every contract has an id (`CP-…`) so a lane can cite it in a commit or a report, a
**do** block an implementer can act on, and a **fails if** block a blind evidence run can
score. Same shape as `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`.

---

## 0. The finding, and the rules this document is built inside

Gate 2's 2.8 evidence run (`ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`) put sixteen
frames from the played route — gameplay camera, HUD on, where the player stood — in front
of a code-blind critic. On Bar B (*is this trying to be the same kind of game as
Palworld?*) it answered **no**:

> A viewer would call it a third-person open-world game with a survival HUD. Nothing
> signals creature collection or creature combat: no creature at readable size, no
> companion beside the trainer, no nameplates or level tags, no catch affordance, no
> combat VFX.

Its first ranked gap says the same from the other side: *creatures absent or unreadable
where the references always feature them.* The owner's 2026-09-03 playtest says it in
the owner's words: *"barely any creatures … nothing to do and nothing to see."*

This document answers the five absences one at a time. For each it establishes, from the
code and not from the comments, whether the thing **exists and is not visible in play**
or **does not exist**; says what must be true in an ordinary gameplay frame; names the
lane whose files the change lands in; and gives the next blind judge a *fails if*.

Nothing below asks for anything outside these rules. If a lane finds it cannot satisfy a
contract without crossing one, the contract is wrong, not the rule.

- **No new creature or humanoid meshes, no Meshy generation** (`CLAUDE.md`). Every lever
  used here is siting, behaviour, camera, contrast, VFX, HUD and encounter context.
- **Five creatures total. No storage, no reserve, no sixth slot.** Nothing here adds a
  body to the world that the party does not own; "one active companion body" stays the
  rule (`docs/prompts/48-PARTY-cycle-pals-in-world.md`).
- **Real-time, directly piloted combat. No shields. The human never fights** (D07). The
  combat picture asked for in §3 is the picture of what already happens.
- **Creatures loom; never shrink one** (OD-0901-1, `docs/owner/OWNER_DIRECTIVES_2026-09-01.md`).
  Where a creature is unreadable at distance the answer below is contrast, siting or
  camera. No height in `species.json` moves down because of this file.
- **The near grass is not touched.** Owner, verbatim: *"don't change the look of my
  grass. it's awesome."* Nothing here edits `grass_field.json`, the grass shader or the
  blade decision.
- **Levels are never player-scaled and never UI locks** (spec §3, D30, `GAME_VISION.md`
  §7). A level tag, where §6 discusses one, is information, not a gate.

---

## 1. What exists and what does not — the table the rest of this file hangs on

Verified on the branch by reading the scripts, the scene and the config, then checking
the contact sheet against them. "Invisible" means a real player, on the real path, would
not ordinarily see it in an exploration frame.

| Judge's absence | Exists? | Where | Why it is not in the frame |
|---|---|---|---|
| **Companion beside the trainer** | **Yes — built, and invisible** | `scripts/creatures/follower_creature.gd` (the body), `encounter_director.gd::_spawn_ally_body()` / `summon_active_creature()`, `data/config/opening.json` `follower` | Three causes, all in §2: nothing summons it after a save is loaded; it heels 3–8 m *behind* the trainer, which is where the camera is; when it faints it is hidden and nothing else comes out |
| **Creature at readable size** | **Partly** | Contact shadow on every body (`creature_body.gd:960`), per-species `field_emission`/`field_rim` (`:793`, `:821`), alpha aura (`alpha_aura.gd`), spawn siting clear of shrubs (`_pick_clear_spot()`) | Clusters are sited off the walked line and are small species; nothing about *where the player walks* is a contract. The two closest reads in sixteen frames were ~35 px on a ridge (§3) |
| **Combat VFX** | **Yes — built, and never photographed** | `combat/impact_flash.gd` (0.85–1.15 m burst, 0.26–0.34 s), `telegraph_glow.gd` (1.1 m ring), `move_projectile.gd`, `target_marker.gd`, the arena band (`combat.json` `arena`), a 4.6 m / 62° fight camera | The evidence lane teleported to where a fight *had* happened and took a frame with no fight running (`REPORT.md` §8.2). One genuine gap: the level-up beat is a text pulse on a HUD line and nothing in the world (§4) |
| **Catch affordance** | **Yes inside a fight; nothing outside one** | `ui/capture_reticle.gd` (explicit %), `combat/throw_preview.gd` (the arc), `throw_aim.gd`, `orb.gd`, the Throw cell in the combat grid (`combat_hud.gd:759`), the target slow-down while aiming (`catching.json` `target_slowdown_scale`) | Orbs are `kind: gear` (`data/items/items.json`) and the hotbar accepts only `tool`/`consumable`/`food` (`game_state.gd:235`), so the orb count is never on screen in exploration; the engage prompt reads "Engage Bramblebun" and carries no hint that the thing can be caught (§5) |
| **Nameplates and level tags** | **No** | No `Label3D`, plate or tag node exists under `scripts/creatures`, `scripts/combat`, `scripts/ui` or `scripts/npc`. A creature is named in exactly three places: the engage prompt at ≤ 6 m (`encounter_director.gd:1457`), the combat HUD's enemy panel (name, type, HP, telegraph — **no level**, `scenes/combat/combat_hud.tscn:36-77`), and a caught creature's own party rows | A design decision, argued in §6, not an omission to be filled in by default |

The distinction matters because this repository has been wrong about it before. The
Warren Guardian's signature move was documented across several paragraphs and never
swung (`GATE3_ENCOUNTER_CONTRACTS.md` §1.2). The companion is the mirror case: it is
fully built, smoke-tested (`tests/smoke_creature_control.gd` asserts the body exists and
`is_following()` — never *where it is on screen*), and absent from every frame the
project has ever shown a judge.

---

## 2. CP-1 — The companion beside the trainer  *(rank 1)*

### 2.1 What is there now, and the three reasons it is never in shot

**It is built.** `follower_creature.gd` extends the creature body, takes the trainer as
`leader`, and walks toward them through the same `request_move()` the combat AI uses.
`adopt_starter()` stands it up behind the trainer's right shoulder the moment the
starter is chosen (`_spawn_ally_body()`, 2.4 m back, 1.2 m right). `creature_recall`
toggles it (`_read_creature_control_input()`), `party_cycle` swaps it through
`_sync_active_creature()`, combat hands the same body back and forth
(`_set_exploration_active()`), and a revive shows it again
(`_show_a_revived_follower()`). The HUD's active-creature block knows whether it is out:
its header reads `ACTIVE COMPANION` or `READY TO CALL OUT` (`playground_hud.gd:1374`) and
the action legend reads `Put Away` or `Call Out` (`:3011`).

**Reason 1 — a load deploys nothing.** `summon_active_creature()` is called from exactly
three places: the recall press, the party-cycle swap, and the resting-creature swap
(`encounter_director.gd:1292,1298,1346`). `_ready()` summons only through
`adopt_starter()` and only when `default_starter` is set (`:586-589`). Nothing under
`autoload/`, `scripts/save/`, `title_screen.gd` or `tab_save.gd` summons on load. The
harness has known this since RIG-11 and works around it by pressing `creature_recall`
after every load (`tools/gate_f/segments/S06.json:104-107`, `S03C.json:163-166`: *"a load
restores the party and deploys nothing"*). **Every one of the sixteen judged frames
shows `Call Out` in the legend** — the companion was not out in any of them, and it
would not have been for a player who loaded that save either. This is the player-facing
half of 2.11 (a revived creature not re-deployed), and it belongs with it.

**Reason 2 — it heels where the camera is.** `opening.json` `follower`: stop 3.0 m,
resume 4.2 m, run past 8.0 m, walk 3.8 m/s, run 7.2 m/s. The exploration camera sits
5.2 m behind the pivot at 1.75 m (`movement.json` `camera`). The trainer walks at 5.0
and sprints at 8.6 (`opening.json`'s own `_comment_speeds`). So on any straight walk the
follower — slower than the trainer at a walk — drifts from 4.2 m to 8 m behind, breaks
into a run, closes to under 8 m, and drops back to a walk: it oscillates across the
camera's own standoff distance, alternating between *behind the lens* and *an
out-of-focus back filling the bottom of the frame*. At a sprint it falls behind without
limit until the 45 m leash teleports it (`LEASH`). The one time it is composed in frame
is when the trainer stops and turns round. One more detail a flank fix must know:
`_spawn_ally_body()`'s "behind the right shoulder" spot and the leash re-place are
computed from `_player.global_basis`, but `player_controller.gd` yaws only the model
child (`_model.rotation.y`, `:696`) and never the `CharacterBody3D` — so that spot is
world −Z / +X whichever way the trainer faces, and the body's basis cannot be used to
find a flank. The key art's DAY and NIGHT panels put the
companion **at the trainer's flank, shoulder to shoulder, both facing the view** — a
rear third-person frame in which the creature is beside the human, not behind them.
`palworld-04` does the same: the pals are level with or ahead of the rider.
`_comment_speeds` says the slow walk was chosen so *"the little burst when it falls
behind is most of what makes it read as alive"* — a good instinct that, combined with a
rear heel point, makes the creature alive exactly where nobody can see it.

**Reason 3 — a fainted companion leaves a gap nothing fills.** When the deployed creature
faints, `combat_manager.gd::_finish()` hides the body, `_set_exploration_active()`
correctly refuses to show it, and the prompt line reads *"X is out of the fight."*
(`:1454`). `_sync_active_creature()` swaps bodies only when `party.active` *changes*,
which it does only on a `party_cycle` press. A player who lost a fight walks on alone
until they press a button; the harness presses it for them (`S03C.json:1448`). The
judge's own roster panel read `TEAM 5/5` with three KO'd.

### 2.2 What must be true in an ordinary gameplay frame

The player's active creature is on screen, at the trainer's flank, at a size the
1.80 m trainer can be measured against, in the overwhelming majority of exploration
frames: after a new game, after any load, after any fight the creature survived, and
after a revive. When the active creature cannot stand (fainted, resting), another
healthy party member is out instead, or the HUD says plainly why nobody is.

### 2.3 Contracts

**CP-1a — A load calls the creature out.** *Do:* when the world finishes restoring a
save with a party whose `active` creature is neither fainted nor resting, run the same
`summon_active_creature()` the recall press runs, once, after the terrain has ground
under the trainer (the `_stand_on_ground` wait `_spawn_ally_body()` already does). Same
for a new game after `adopt_starter()` (already true) and for the opening's own faint
recovery. Do not persist "was it out" in the save (`docs/decisions/D27`; the harness
note is right that ownership and condition are the facts worth saving) — *out* is the
default, *put away* is the transient choice. **Lands in:** `scripts/combat/encounter_director.gd`
→ **G3-OPENING-FIX**, beside its 2.11. **Fails if** any save loaded with a healthy
active creature shows the `Call Out` legend or the `READY TO CALL OUT` header before
the player presses anything; or if a fainted/resting active creature is stood up by a
load.

**CP-1b — The heel point is the flank, and the follower holds station.** *Do:* the
follower's goal point becomes the trainer's **side**, not their back, computed from the
trainer's *facing* — never from `_player.global_basis`, which does not turn (§2.1).
The facing the follower can read without touching `scripts/player/**` (no round-two
lane owns it) is the leader's horizontal `velocity` (public on `CharacterBody3D`),
remembered whenever it is non-zero and held while the trainer stands still; the
flank point is then `leader.global_position + right(facing) * side_offset −
forward(facing) * back_offset` with `side_offset` ≈ 1.8 m (right, the side
`_spawn_ally_body()` intends) and `back_offset` ≈ 0.5 m, so the creature walks half a
step behind the trainer's hip and inside the camera's view cone at all times. Use the
same facing for the summon spot and the leash re-place, so a called-out creature
appears at the flank rather than at a fixed world offset. Hold station: walk speed ≥ the
trainer's 5.0 so a walking creature never drifts back into the lens, run ≥ the 8.6
sprint so a sprint does not shed it. Keep `_comment_speeds`' "burst" by keeping the
walk/run hysteresis (`resume_distance`, `run_distance`) — the creature still lags and
catches up, but between roughly 1 m and 4 m of the flank point, never past the camera.
Keep `collision_layer = 0` while following (a flank companion that could wall the trainer
on a narrow bridge would be a worse defect than one that clips through a fence post).
Put every number in `opening.json` `follower`; they are TUNABLE, the shape is not.
**Lands in:** `scripts/creatures/follower_creature.gd` + `data/config/opening.json`
`follower`. By file ownership that is **G3-CREATURE-COLOUR** (`scripts/creatures/**`);
this is a behaviour change, not a colour one, and the coordinator should consider
handing this one file to **G3-OPENING-FIX** as part of the same feature as CP-1a — the
row is written here either way. **Fails if**, on a 60 s straight walk along the Band 1
spine with the companion out and the gameplay camera untouched, the companion's screen
bounding box is fully inside the 1280×720 frame and ≥ 80 px tall in fewer than 80 % of
sampled frames; or if it is ever between the camera and the trainer; or if it is more
than 12 m from the trainer at the end of a 10 s sprint.

**CP-1c — Somebody is always out.** *Do:* when a fight ends with the deployed creature
fainted and at least one party member healthy and not resting, the next healthy member
comes out — the same `party.cycle_active(1)` → `_sync_active_creature()` path the
`party_cycle` button already runs, with the same world message (*"Active creature:
Moss"*). The player may put it away or swap it as before. A wholly fainted party keeps
today's *"X is out of the fight."* line. This is what the harness already does by hand
at `S03C.json:1448` and it is the behaviour a player would assume. **Lands in:**
`scripts/combat/encounter_director.gd` → **G3-OPENING-FIX**. **Fails if** a player with
two or more healthy creatures ever walks with none out after a lost fight without
having chosen to; or if the swap happens while a fight or a trainer round is running.
*Owner note:* this changes which creature is "active" without a press. It is the
smallest possible version of that (only on faint, only forward, announced). Flagged in
§7 as a confirm-or-veto, not a blocker — ship it unless the owner says otherwise.

**CP-1d — The companion is a subject, not a prop.** While standing, it faces the trainer
(already true: `face_towards(leader)` in `_tick_follow()`); while walking, its stride
and the trainer's are visibly different speeds so it reads as an animal keeping up, not
a mesh parented to a capsule. Species with an idle clip use it. Nothing new is asked
here beyond keeping what `creature_animator.gd` already does once the body is in frame.
**Fails if** a blind judge, given three frames of the pair walking, calls the companion
"attached to" or "following on rails behind" the trainer.

---

## 3. CP-2 — A wild creature at readable size, where the player walks  *(rank 2)*

### 3.1 What is there now

Every creature body carries a ground-contact ellipse (`creature_body.gd:960`), a
per-species emission/rim lift tuned against grass (`field_emission`, `field_rim`), an
alpha aura for cluster leaders, a title prefix for elders (`_apply_elder()`, `:913`), and
spawn siting that retries out of solid scatter (`_pick_clear_spot()`). The engage prompt
names the creature at 6 m (`combat.json` `flow.engage_range`). None of that is in doubt.

What is not a contract anywhere is **the relation between where clusters sit and where
the player walks.** Band 1's practice cluster is three Bramblebun at radius 15 m
(`band1_lower_meadows/spawns.json` order 0, and its own comment records that a 5 m
radius was tried and reverted for a test's sake, not for a picture's). The judged frames
show pink dots in the far mid-ground read as flowers, and four brown quadrupeds on a
ridge at ~35 px, identical mesh, scale and rotation, the same value as the sunlit grass
behind them. A 1.0 m Bramblebun at 40 m under the 70° exploration lens is ~15 px tall
at 720p; the same animal at 12 m is ~50 px, and a 2.05 m Meadowhart at 25 m is ~55 px.
Distance, not height, is the lever — and height is closed by owner directive anyway.

### 3.2 What must be true in an ordinary gameplay frame

Walking the spine of any band, a wild creature is in frame at a size where its head,
body and legs separate — not as a species-identification exercise, but so the frame
says *animal* — often enough that a sixteen-frame set from the played route cannot
avoid one. Two creatures in one frame are not the same body at the same scale in the
same pose.

### 3.3 Contracts

**CP-2a — The road herd.** *Do:* along each band's spine, at intervals no longer than
the dead-travel bar (~60 s of walking, ~250 m), one cluster is sited so that its centre
is within 12 m of the walked line for a species under 1.3 m, or within 25 m for a
species over 1.7 m, on the open side of the path (not behind a tree line) and never
inside the grass carpet's densest cells (`_pick_clear_spot()` already handles scatter).
Prefer the band's tall commons for these road clusters (Meadowhart, Burrowback,
Trailpup in Band 1; each band's own equivalents) and keep the small species for the
pockets the player *finds*. Do not move the practice cluster (its radius is pinned by
`smoke_catching.gd`); add beside it. **Lands in:** per-band `spawns.json` → **G3-BAND1-FINISH**
for Band 1 (band data), the band lanes for 2–5. **Fails if** the played-route frame set
for a band contains no wild creature whose screen height is ≥ 40 px at 720p, or if the
longest spine interval with no creature inside 25 m of the line exceeds 250 m (measured
from the spawn table against the spine polyline, not by eye).

**CP-2b — No two bodies alike in one frame.** *Do:* ordinary cluster members roll a
modest per-instance scale in a band that never crosses the elder/alpha `body_scale`
(say ±6 %, TUNABLE — grow the band's floor, never its ceiling, to stay inside
OD-0901-1), a random facing, and a staggered idle phase, at spawn. Cluster members
wander (`wander_radius` exists in the wild config) so a still frame catches them in
different poses. **Lands in:** `encounter_director.gd`'s spawn path → by file
**G3-OPENING-FIX** (`scripts/combat/**`); a one-function change, and the coordinator may
prefer to route it with CP-2a's band lane. **Fails if** a blind judge can name two
bodies in one frame as "the same mesh at the same size and rotation", or if any
ordinary member renders larger than its cluster's elder.

**CP-2c — Value and hue separate the animal from what it stands on.** Already scoped to
**G3-CREATURE-COLOUR** (Bramblebun off candy pink, the rest of the roster against the
1.5 : 1 bar, time-of-day scaling). This file adds only the *fails if* the judge
supplied: **fails if** a creature in frame is the same hue family as the tree trunks
behind it (the judge's "salmon-brown" read) or within 1.3 : 1 luma of the ground it
stands on at the frame's own hour; and — the standing rule — fails if any species'
height is lowered to pass this.

**CP-2d — The first creature the player sees is a creature.** The opening's own
practice encounter already exists and is gated. This contract asks only that the first
*ambient* wild body a new player can see from the farmhouse door or the road gate is
within CP-2a's distance and is one of the tall commons, so the genre is declared in the
first outdoor minute rather than at the first fight. **Lands in:** `band1_lower_meadows/spawns.json`
→ **G3-BAND1-FINISH**. **Fails if** the first outdoor evidence stand after the opening
contains no wild creature ≥ 40 px.

---

## 4. CP-3 — Combat produces a picture  *(rank 3)*

### 4.1 What is there now

Everything the judge asked for at the strike is built and measured: the impact burst
(`impact_flash.gd`, sized against the judge's own 10-pixel finding), the telegraph ring,
the projectile performance for ranged moves, the floating marker over the real opponent,
the drawn arena band, a fight camera 4.6 m from a creature at 62°, the enemy panel with
name/type/HP/telegraph, the ally panel with name and level, an effect banner, and the
level-up line *"Moss reached Lv 5"* with a scale-and-colour pulse
(`combat_hud.gd:1209,1242`). The two "fight-starts" frames and the "level-up" frame the
judge received contained none of it because the capture lane stands where a fight
happened and does not restage it (`REPORT.md` §8.2, 2.15).

The one honest gap: **the level-up is a HUD text pulse and nothing in the world.** The
XP line lives in the combat HUD, which is torn down with the fight, so a level-up that
lands as the fight ends is a line the player may never read. There is no burst on the
creature, no persistent line, no world message.

### 4.2 What must be true in a fight frame

Two creatures, the arena band, the marker over the opponent, and — at the moment of a
hit — the burst, all in one frame from the fight camera. A level-up is visible in the
world for long enough to be seen and survives the HUD handoff.

### 4.3 Contracts

**CP-3a — The evidence stages the fight.** *Do:* the capture lane's segment generator
turns a `combat_start` event into a real engagement at that position (the trace has the
opponent's cluster; `interaction_activate()` starts it), and captures at
`combat_hit` + ~0.1 s (inside the burst's 0.26–0.34 s life) and at `telegraph_started`
+ ~0.3 s; a `level_up` event captures while `_celebrate_level_up()` is running. **Lands
in:** `tools/gate_f/derive_gate2_route_captures.py`, `operator_harness.gd` → **G3-HARNESS**
(this is 2.15's own row). **Fails if** a frame labelled `fight-starts` contains no
opponent, no marker and no arena band, or a frame labelled `level-up` contains no
level-up text.

**CP-3b — The level-up is a world event.** *Do:* on level-up, a short burst on the
creature's own body (the impact-flash family: mesh-based, MIX-blended, physics-clocked,
in a warm non-danger colour — the same lessons `impact_flash.gd`'s header paid for),
and the *"X reached Lv N"* line pushed through `Game.push_world_message()` so it
outlives the combat HUD and is read in exploration. **Lands in:** burst in
`scripts/combat/**` → **G3-OPENING-FIX**; the message's exploration surface is the
existing world-message line → **G3-HUD** if it needs a style. **Fails if** a level-up
that lands on the fight's last blow leaves no trace on screen two seconds into
exploration.

**CP-3c — The foe's level is on the plate.** The ally panel shows `Lv`; the enemy panel
shows none (`combat_hud.tscn` `EnemyPanel`: Eyebrow, Name, TypeTag, Health, Telegraph).
*Do:* add the level beside the name in the enemy panel, same style as the ally's. This
is the one place a level tag is uncontroversial — the fight has started, the number is
a fact about the opponent, and G-7's "readiness stays in the world" rule is about the
approach, not the exchange. **Lands in:** `scripts/ui/combat_hud.gd` + `combat_hud.tscn`
→ **G3-HUD**. **Fails if** a fight frame's enemy panel shows no level, or if the number
is shown for a wild creature *before* the fight starts (that is §6's question, not this
one).

---

## 5. CP-4 — Catching is legible before the throw  *(rank 4)*

### 5.1 What is there now

Inside a wild fight the catch is the most completely presented verb in the game: an
explicit percentage on a reticle that tracks the creature, the predicted arc drawn from
the same numbers the orb flies, a Throw cell that reads "Throw" or "No orbs", a slowed
target while aiming (owner ask 2026-09-02 #6, shipped as `target_slowdown_scale`), and a
resolution camera on the orb (`catching.json` `camera`). D08 makes the throw cost the
player their creature's guard, on purpose.

Outside a fight there is nothing. Orbs are `kind: gear` and the hotbar refuses that kind
(`HOTBAR_KINDS_ALLOWED := ["tool", "consumable", "food"]`), so the orb count is never on
screen; the engage prompt reads *"Engage Bramblebun"* whether the creature is wild or a
trainer's; the exploration HUD's active-creature block carries no catch verb. A viewer
of an exploration frame with a wild creature at engage range has no way to know that
catching is a thing this game does, which is the judge's "no catch affordance".

### 5.2 What must be true in an ordinary gameplay frame

When a wild (catchable) creature is at engage range, the frame says two things: this
can be fought, and this can be caught, with what you are carrying. In a fight, an aim
frame is unmistakably an aim.

### 5.3 Contracts

**CP-4a — The engage prompt carries the catch read.** *Do:* when `_engageable()` is a
wild creature, the offer line becomes *"Engage Bramblebun"* plus the orb glyph and the
carried count (*"· 10 orbs"*), in the prompt's existing single-line form (`PROMPTS.offer`
already carries a second verb's glyph, per `_creature_control_offer()`'s comment).
Zero orbs reads *"· no orbs"* in the warning tint — a player who walks up to a creature
they want should learn they cannot catch it *before* the fight, not at the Throw cell.
Trainer challenges and the guardian keep the plain line. **Lands in:** the offer text in
`encounter_director.gd` → **G3-OPENING-FIX**; any glyph/tint work in `scripts/ui/**` →
**G3-HUD**. **Fails if** a blind judge, given an exploration frame with the engage prompt
up over a wild creature, cannot say that catching is available; or if the count is
shown for a trainer-owned creature.

**CP-4b — The aim frame is staged and judged.** *Do:* the capture lane takes a frame
during `throw_aim.gd`'s AIMING state in at least one wild fight per set, with the
reticle, its percentage and the arc in shot. **Lands in:** **G3-HARNESS** (2.15).
**Fails if** the set contains no aim frame, or the judge cannot tell from it that a
throw is being lined up.

**CP-4c — Orbs are visible at a glance in exploration.** Two options, one recommended:
(i) *recommended* — a small orb count in the active-creature block, beside the party
pips, always on (it is the one consumable whose count changes what the player does at
every wild encounter); (ii) allow `gear` on the hotbar, which spends a slot the owner has
already asked to keep for tools and food. **Lands in:** `scripts/ui/playground_hud.gd` →
**G3-HUD**. **Fails if** the exploration HUD shows no orb count in an idle frame; or if
the count is drawn where it competes with the `TEAM` pips for the "five of something"
read (`_party_pips`' own comment records that mistake once already).

---

## 6. CP-5 — Nameplates and level tags  *(rank 5; an owner decision)*

### 6.1 What is there now

Nothing in world space. The judge is right that this is the single element that makes a
distant Palworld blob legible *as an encounter*, and right that every Palworld reference
tags its pals. It is also the element most at odds with this game's own key art, which
has no plate anywhere, and with the naturalism the board sells (*"cozy and inviting,
with hints of mystery"*).

### 6.2 The case, both ways

**For plates.** A tag over a creature says "this is a thing you can fight or catch"
before its silhouette can. It is HUD work, not art, and it lands in one lane. At sixteen
pixels a species will never be identifiable by mesh alone with this roster (the judge's
"needs art" list, and D10), so a tag is the only honest way a distant creature declares
itself. Palworld is the owner's stated bar for Bar B.

**Against plates.** The board's own promise is a world you read by looking. D12 made
creatures peers, not pets; a floating label over an animal grazing in a meadow turns it
back into an inventory row. The game already has *in-world* answers to "is this unusual":
the elder's title in the engage prompt, the alpha's mote aura, the guardian's glow and
scale — G-5 and G-7 in the encounter contracts were written to keep the readiness
signal out of the UI. A level tag over every wild creature also does what
`GAME_VISION.md` §7 forbids in spirit: it turns the region into a number ladder the
player reads off the screen instead of off the animals. And the owner has never asked
for one in five playtests; they asked for creatures to *be there*.

**The measured middle.** The genre read the judge wants comes overwhelmingly from CP-1
and CP-2: a companion at the trainer's flank and a herd on the road say "creature game"
in one second with no text at all. Plates are the cheapest fix and the least
Tetherbound one.

### 6.3 Options

| | Option | What the player sees | Cost to the board |
|---|---|---|---|
| A | **None** (status quo) | Name at 6 m in the prompt line; name/type/HP in the fight | none |
| B | **Range-gated plate** *(recommended)* | Within engage range (6 m) only, and only over the one creature the prompt names: a small camera-facing plate with the name and level (*"Bramblebun · Lv 3"*, elders and alphas with their title), fading in over ~0.3 s; nothing beyond 6 m, nothing over a companion, nothing over a trainer's creature in the world | low: it is the existing prompt's information placed on its subject, and it is gone the moment you step back |
| C | **Palworld plates** | Name and level over every wild creature inside ~40 m, always | high: the meadow becomes a menu; contradicts the board and D12 |

**Recommendation: B**, plus CP-3c (the level on the fight plate). B answers the judge's
"nothing marks a creature as a creature" at the distance where the player is deciding
what to do, and leaves the distance shot to the animals themselves (CP-2). If the owner
chooses A, CP-3c still ships and CP-2 carries the whole distance read. If the owner
chooses C, the plate must still never show a level on a creature the player cannot
engage (a resting elder behind a gate) and must fade below a fixed screen size.

**CP-5a — Range-gated plate (if B).** *Do:* one plate node, owned by the HUD, positioned
from the engageable creature's head height (`target_marker.gd`'s `top_level` technique),
showing `label()` and level, styled from `UITokens`, visible only while the engage offer
is winning the prompt arbiter. **Lands in:** `scripts/ui/**` → **G3-HUD**, reading the
candidate the director already exposes. **Fails if** a plate is visible over a creature
beyond engage range, over more than one creature at once, over the companion, or over a
trainer's creature; or if it is visible while any menu, dialogue or build mode owns
input.

**CP-5b — Whatever is chosen, the readiness signal stays in the world.** G-7 stands:
no dialogue line names a level; no plate is a gate. **Fails if** a tester says they
knew a fight was too hard "because of the number" rather than because of what the
animal looked like or what a character said.

---

## 7. Questions escalated to the owner (not decided here)

1. **CP-5 — Nameplates.** A (none), B (range-gated, recommended), or C (Palworld
   plates). §6 gives the argument; the recommendation is B. This is a look decision
   about the board's naturalism, and the owner should make it.
2. **CP-1c — Auto-swap on faint.** Recommended and small (only on faint, only forward,
   announced), but it changes the active creature without a press. Confirm or veto;
   ship unless vetoed.
3. **CP-1b — Which side.** Right flank is recommended because `_spawn_ally_body()` already
   chooses it and the board's DAY panel has the creature on the trainer's left as seen
   from behind, i.e. the viewer's left — either reads. Not worth a wait; noting it so
   the choice is recorded.
4. **CP-4c — Where the orb count lives.** Active-creature block (recommended) or a
   hotbar exception for `gear`. UI real estate on the Ally is the owner's call.

---

## 8. Ranking, and what to do with time for two

| Rank | Contract | Frames it changes | Why this order |
|---|---|---|---|
| **1** | **CP-1 companion** (1a load, 1b flank, 1c faint) | Every exploration frame — 14 of the judge's 16 | Fully built; three small changes in two files put the game's own premise in every shot. Nothing else moves Bar B as far per line changed. The evidence lane's workaround (press recall after load) is a symptom of 1a being a player defect, not a harness one |
| **2** | **CP-2 road herd** (2a siting, 2b variance, 2d first sight) | Every route frame past the village; the owner's own #4 complaint | Data, not code, for 2a/2d; a one-function roll for 2b. Turns "pink dots" into animals without touching height or grass |
| 3 | CP-3 combat picture (3a staging, 3b level-up, 3c foe level) | The fight and level-up frames only | The VFX exists; 3a is 2.15's row and costs the harness lane an afternoon; 3b is the only genuinely missing beat |
| 4 | CP-4 catch read (4a prompt, 4b aim frame, 4c orb count) | Frames at engage range and aim frames | Small text and HUD work; makes the second half of "fight *or catch*" visible before the fight |
| 5 | CP-5 nameplates | Frames at engage range | Owner decision; the recommendation is deliberately the smallest version |

**With time for two: CP-1 and CP-2.** Together they put a creature beside the trainer
in every frame and an animal on the road in every stand, which is the whole of the
judge's first ranked gap. CP-3a should ride along in G3-HARNESS regardless, because it
costs nothing but staging and is what lets the next judge see CP-1 and CP-2 at all.

---

## 9. The evidence contract (so the next judge can be held to this)

For any blind set drawn from a played route after these land, the set **fails** if:

- fewer than 80 % of its exploration frames contain the companion inside the frame at
  ≥ 80 px (CP-1b), or any post-load frame shows `Call Out` before a press (CP-1a);
- it contains no wild creature at ≥ 40 px (CP-2a), or two bodies the judge calls
  identical (CP-2b);
- a `fight-starts` frame has no opponent, marker or arena band, or a `level-up` frame
  has no level-up (CP-3a);
- it contains no aim frame (CP-4b), or an engage-range frame with no catch read (CP-4a);
- and, if B is chosen, a plate appears anywhere §6.3 says it must not (CP-5a).

The judge is asked the same two bar questions as before and told nothing about what
changed. Bar B's answer is the acceptance; this file's *fails if* rows are how a "no"
gets traced back to a contract instead of to a mood.

---

## 10. How a lane uses this

- Cite the id in the commit that satisfies it and in the lane report.
- A contract's *fails if* is the evidence-run assertion; put it in the band's evidence
  template verbatim.
- Every number is TUNABLE; every shape is not. If a number cannot be hit inside the
  existing tests (`smoke_creature_control.gd`, `smoke_catching.gd`'s practice-cluster
  reach, `test_hud_widgets.gd`), move the number and keep the shape, and say which.
- If a contract needs a file another lane owns, write the row you would have written
  into your report and name the lane. Do not edit across ownership. Where this file's
  routing by file and routing by feature disagree (CP-1b, CP-2b), the coordinator
  decides; both rows are written so either lane can take them.
