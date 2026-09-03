# Gate 3 — Encounter contracts

**Status:** design contract, G3-ENCOUNTERS lane (Fable), 2026-09-03. Written for the
five Gate 3 implementation lanes against current `main` (`3c73aab5`). Read-only on
code and data; every "do" below is an instruction to a lane, not a change already made.
**Owning roadmap line:** `docs/ROADMAP.md` Gate 3 — *"Fable owns: encounter identity
(guardian, Captain Vance, the three captains, the Warden), pacing per band, the
roster-pressure moment before the legendary."*

Precedence is `CLAUDE.md`'s: a newer owner directive in `docs/owner/` beats this
file; this file beats a prompt in `docs/prompts/`. Where this file proposes changing
something shipped, it says what is there now, why it does not land, and what to do
instead. Where canon is silent and the choice is material, §9 lists it as an owner
question rather than deciding it.

Every contract has an id (`G-…`, `V-…`, `C-…`, `W-…`, `P-…`, `R-…`) so a lane can cite
it in a commit or a report, a **do** block an implementer can act on, and a
**fails if** block a blind evidence run can score.

---

## 0. The rules this document is built inside

Nothing below asks for anything outside these. If a lane finds it cannot satisfy a
contract without crossing one of them, the contract is wrong, not the rule.

- **No new creature or humanoid meshes, no Meshy generation** (`CLAUDE.md`). Every
  encounter here is made from the installed bodies. Allowed levers, and the only
  ones used: materials, textures, modest scale, animation, VFX, habitat, behaviour,
  traits, arena, encounter context, dialogue, rank presentation.
- **Five creatures total. No storage, no reserve, no sixth slot.** The
  roster-pressure moment (§7) is built on the cost of that rule, never around it.
- **Trainer-owned creatures cannot be caught.** No design below makes "catch the
  Warden's Tuskroot" the answer. A wild guardian or alpha *is* catchable and that is
  legal and used.
- **No shields. The human never fights. Real-time, directly piloted combat** (D07).
  Movement is the dodge; the opponent's telegraph and recovery beats are the only
  "mechanics" the player has been taught, and every identity below is built by
  recombining those beats, not by adding a system used once (owner plan
  `MEADOWS_QUALITY_REBUILD_PLAN.md` §9, PW4).
- **No Biome 2.** The finale points outward; nothing here builds outward.
- **Levels are never player-scaled** (spec §3, D30, `chapter_curve.json`). Every
  level named below is a real level and stays inside the band its region authors.
- **Band 5 is short on purpose** (D70). §6.4 does not pad it.
- **Starters are exclusive** (D72). No trainer or wild below fields Terrapup,
  Ripplet or Galewisp.

---

## 1. The standard, taken from the Warren Guardian

The Burrow Warrens guardian is the one Gate 3 encounter that already answers prompt
63's *"memorable, not standard fight + HP."* This section states what it does in
general terms so the rest of the chapter can be held to it, and names the one place
it still falls short.

### 1.1 What the guardian actually does (`data/config/burrow_warrens.json`, `guardian`)

| Lever | What shipped | Why it works |
|---|---|---|
| Named individual | `nickname: "Warren Guardian"` on both the engage prompt and the instance, so a player who catches it keeps the name | The fight is *this* animal, not "a Burrowback" |
| Real scale | `scale: 1.35` on the gameplay body, not the art pivot, so reach, capsule and catch bonus all grow together | No "invisible discrepancy" between what you see and what hits you |
| Colourway | the installed alpha repaint (`_base_color_alpha.png`), rim, mote aura | Reads as an alpha from the den doorway, before the first exchange |
| Self-lit against a blind judge | `glow_energy 1.2` under a warm tint, an `aura_light` parented to the body at leg height | Survives the den's own darkness and its own wander; tuned by measurement, not taste |
| Signature move | `signature_move: earth_fist` (power 1.4, 0.62 s windup, 72° cone), chosen over `earthshatter` because a 360° hit in a 6 m den cannot be stepped around | The move a caught guardian carries into the player's team |
| Encounter context | the den is the fourth chamber, past four residents at 9–11 and Pell's own warning (*"bigger… knows a heavier trick… one answer won't be enough"*); the vault door only lifts on `warrens_cleared`; the Heartstone is behind it | The fight is gated, foreshadowed, and pays for something the player already wants |
| Once only | `once_id` (WARRENS-ONCE): beaten or caught, it does not come back | Owner directive 2026-09-03, finding 9 |
| Catchable | A guardian is wild, so catching is a legal way to clear the warren | The five-slot rule gets its first real test here |

### 1.2 The one honest gap: the signature move is not swung

`scripts/creatures/wild_creature.gd::set_engaged()` replaces `_combat_cfg` with
`combat.json`'s single global `enemy` block, and `combat_ai.gd` has one attack
intent, never a quick/charged branch. `combat_manager.gd::_on_enemy_strike()` then
reads the opponent's **`move_quick`** for power and type. So in play the guardian
swings the generic enemy profile (power 8, telegraph 0.55 s, recovery 0.75 s, cone
90°, lunge 3.4) with Burrow Strike's 1.1× on top, exactly like a field Burrowback
three levels lower. Earth Fist's "heavier, telegraphed, directional" reading in the
file's own `_comment_guardian_move` is true only after the player catches it.

This is not a defect in the guardian's authoring; it is the ceiling of the mechanism
under it. It is also the reason every other Gate 3 encounter, held to the guardian's
standard, would still be "the same fight at a higher number" on the behaviour axis.
The general contract below (G-2) is the single mechanism request in this document.

### 1.3 The general standard (all Gate 3 major encounters)

**G-1 — The three-sentence test.** A blind tester who has just finished a major
encounter must be able to say, unprompted, (a) what it *looked* like that no other
opponent did, (b) what it *did* in the fight that no other opponent did, and (c) what
*changed in the world* when it was over. **Fails if** any of the three answers is
"it was bigger", "it had more health", "it looked different", or "nothing". The owner
plan §9 states this bar; this file makes it the acceptance for every encounter
below. Record the three sentences in the band's evidence template.

**G-2 — Behaviour is a per-encounter override, not a new AI.** *Do:* add an optional
`combat` dictionary that `wild_creature.set_engaged()` merges over `combat.json`'s
`enemy` block for **this body only**, read from three places that already exist:
a `spawns.json` entry's `alpha`/`elder` block, `burrow_warrens.json`'s `guardian`
block, and a trainer team member (beside the existing optional `moves` override in
`trainers.json`'s `_comment_team`). Allowed keys are the `enemy` block's own:
`power`, `telegraph`, `recovery`, `attack_cooldown`, `preferred_range`, `chase_speed`,
`reposition_speed`, `reposition_time`, `reposition_distance`, `lunge`,
`first_attack_delay`, `cone_degrees`, `range`. No new intent, no charged-move AI, no
new script; `combat_ai.gd::decide()` stays pure and the profiles below are
unit-testable through it. Absent block means today's behaviour, byte for byte, for
every creature in the game. *Fails if* the override reaches any body that did not
author it, or if any ordinary wild creature's fight changes when the block is absent.

**G-3 — Five behaviour profiles, reused, never one-offs.** Every named opponent in
Gate 3 is one of these or the default. Numbers are starting points and TUNABLE;
the *shape* is the contract. Values are relative to `enemy` defaults (power 8,
telegraph 0.55, recovery 0.75, cooldown 1.1, preferred 2.1, chase 4.6, reposition
4.0 m / 1.0 s, lunge 3.4).

| Profile | Shape the player reads | Override |
|---|---|---|
| **WALL** | Slow, heavy, stands its ground; the punish window is long and the hit is expensive | `telegraph 0.85`, `recovery 1.1`, `power ×1.5`, `chase_speed 3.4`, `reposition_distance 2.5` |
| **CHARGER** | Closes from range in one lunge; the tell is distance, not time | `preferred_range 4.5`, `lunge 7.0`, `telegraph 0.6`, `recovery 0.9`, `attack_cooldown 1.6`, `power ×1.3` |
| **DIVER** | Hit-and-run; short tell, long retreat, comes again from a new side | `telegraph 0.4`, `lunge 5.5`, `reposition_distance 7.0`, `reposition_time 1.6`, `attack_cooldown 0.9`, `power ×0.9` |
| **CURRENT** | Relentless pressure; short cooldown, small hits, never backs off far | `attack_cooldown 0.7`, `recovery 0.55`, `reposition_time 0.5`, `reposition_distance 2.0`, `power ×0.8` |
| **ACE** | The one telegraph in the chapter you must read or lose a creature | `telegraph 1.0`, `recovery 1.2`, `power ×1.8`, `lunge 6.0`, `attack_cooldown 1.8`, `first_attack_delay 2.5` |

*Fails if* two profiles cannot be told apart by a blind tester across two fights,
or if any profile's hit kills a full-health creature of the region's expected entry
level in one blow (compute with `combat_math.base_damage` against
`chapter_curve.json` `team.enter` stats before shipping a number).

**G-4 — The opponent's move slot is a live lever today, use it.** Because the AI's
damage reads `move_quick`'s power and type, a trainer team member's `moves.quick`
override changes what the player is hit *with* — no code change. TM-tier quicks
(`rock_throw` 1.15, `aqua_shot` 1.15, `wind_blade` 1.2) belong on Team Tether's top
ranks only (§5), never on a wild. *Fails if* a wild creature carries a TM move, or a
grunt/officer does.

**G-5 — Presentation minimum for a named opponent creature** (wild guardian, alpha,
elder, or a trainer's ace): a display name or title the engage prompt shows; scale
on the gameplay body (`scale`/`body_scale`), never art-only; the alpha or vivid
colourway where the species has one installed; a self-lit floor that survives the
site's own lighting, measured by the blind judge, not assumed; a ground-contact
shadow (already universal since CREATURE-LEGIBILITY-0903). *Fails if* the blind
judge cannot name the opponent as unusual from the engage distance (6 m) before the
fight starts.

**G-6 — Encounter context minimum for a major encounter:** it is announced before
it is met (a line, a prop, a silhouette, a landmark), it stands between the player
and something the player already wants, it cannot be walked around, and beating it
changes at least one visible thing in the world (a flag-gated prop, light, body,
gate or line). *Fails if* a straight-line runner reaches it with no warning, or
leaves it with the site looking the same.

**G-7 — The readiness signal stays in the world, not the UI** (owner plan §10;
`tests/test_trainers_data.gd::test_the_wider_ladder_carries_its_own_readiness_signal`).
Every major encounter's last conversation before it says, in a character's words:
how many the opponent fields, and one thing about *how* it fights. No level
numbers in dialogue. *Fails if* the challenge line could be swapped with another
trainer's and nobody would notice.

### 1.4 Guardian contract

**G-8 — Keep everything in §1.1.** Do not retint the alpha colourway (owner decision,
per the file's own `_comment_guardian_stand_wash_verified_0830`), do not move the
den, do not change the level (14, set against measured pacing by SH47/D42). The
owner's "burrow warrens doesn't look good" (2026-09-03, finding 9) is the interior's
visual pass and belongs to the Band 2 world lane, not this contract.

**G-9 — Give the fight the move the file promises.** *Do:* guardian block gains
`combat` = **WALL** with `lunge 6.5` and `cone_degrees 72` (Earth Fist's own arc), so
the swing the player sees *is* a heavy, directional, telegraphed hit that can be
stepped around inside the den's ~6 m of clearance. Keep `signature_move: earth_fist`
so a caught guardian still carries it. *Fails if* the guardian's telegraph is not
visibly longer than a den resident's (measure: ≥ 0.3 s longer), or if its expected
damage per landed hit against a creature at the band's expected exit level (10) is
under 1.4× a den resident's (compute with `combat_math.base_damage`), or if a blind
tester does not describe the hit as one worth stepping out of.

**G-10 — Two things the guardian must never become:** a wall that cannot be caught
(the catch route stays open; a `WALL` profile's long recovery is the throw window),
and a fight that can be repeated (WARRENS-ONCE stands).

---

## 2. Band 2 — Stone & Root pacing (mostly shipped; contract states the rhythm)

Band 2 is 2,653 m, walked in ~11 minutes, worst measured gap 165 m (D70 table).
It is the band Gate 3 should copy, not fix. The rhythm, along the spine, with the
beat type in brackets:

South Bridge → trailpup/burrowback/duskhush clusters at the seam (wild) → Dorn at
(315,1668) on the quarry road, 9/9, two Ground (trainer: *"this band's own field is
Ground"*) → the quarry floor, Rootstone seams, the quarry station (resource, detour:
rim overlook) → potion cache at (350,1968) (resource) → ranger camp spur (detour,
camp) → Pell at the warrens mouth, 10/10/11 with the Air lesson (trainer) → the
Warrens: four residents 9–11, the guardian 14, the vault's Elder Trailpup, the
Heartstone (dungeon, memorable encounter, prize) → undertrail second mouth (shortcut)
→ Kest at (0,2980), 12/12 (trainer, "the seams don't end at the door") → Farro's
night watch and the night-gated duskhush alpha at (70,2900) (optional, night) →
Nightburrow at (-168,2940) (exceptional alpha, temptation) → the haulage wreck at the
band-3 seam.

**P-2.1** The longest pull-free interval in Band 2 stays under **60 s at the probe's
walked pace (≈200 m)**; the measured 165 m worst gap already satisfies it. *Fails
if* any Gate 3 edit to Band 2 opens a gap over 200 m on the spine.

**P-2.2** The band's escalation reads as a ladder, not a repeat: Dorn (2 Ground) →
Pell (3, one Air) → guardian (wall) → Kest (Ground+Air, higher). *Fails if* the
evidence run's tester describes Pell and Kest as "the same fight twice"; Kest's
own `_why_team` says he is the same lesson held higher, which is fine only because
the guardian sits between them.

**P-2.3** Roster pressure is present here for a player who explores: the warrens
guardian (catchable, named, Earth Fist), the vault Elder Trailpup, the trailpup and
meadowhart alphas at (-180,2250) and (-150,2650), Nightburrow. *Fails if* a fresh
run's party is under four creatures leaving Band 2 (`chapter_curve.json` expects
4 on exit).

---

## 3. Captain Vance and the relay's inward escalation

### 3.1 What is there now, and what does not land

The relay ladder is Hess 8/8 (grunt, spine, 140 m out) → Orrin 9/9 (grunt, spine,
70 m out) → Officer Dell 10/10/10 (yard, 4 m from centre) → Captain Vance 11/11/12
(yard, 3.6 m past centre). GATE-D3 already moved the two pickets out onto the road,
so *"four NPCs standing together"* is solved for the pickets. The captain is not
solved:

1. **Dell and Vance stand 7 m apart on the same floor.** The officer's fight and
   the captain's are the same arena, the same backdrop, thirty seconds apart, with
   one level between them. The end of the site is a second fight in the same spot.
2. **Dell is the broader test.** Dell fields Water/Ground/Air (mosshell, burrowback,
   galecrest); Vance fields Ground/Air/Air (tuskroot, galecrest, duskhush). On the
   type chart the officer covers more than the captain.
3. **Vance's one genuinely new thing is thrown away first.** Tuskroot never spawns
   wild (D20/D17) and no trainer before order 7 fields one, so Vance's Tuskroot is the
   *first Tuskroot the player has ever seen* — what their own Mudsnout could become
   with the Heartstone they may just have taken. It is sent out first at level 11 and
   is the first to fall; his ace is a level-12 Duskhush, an owl the player has been
   fighting since the grove. His line *"I don't send the weakest out first"* is not
   what the data does.
4. **Nothing about his creatures fights differently** (§1.2).

### 3.2 What the end of a mini-stronghold should feel like

Three things, in this order, and all three are already half-built at this site:

- **Seen before it is fought.** The relay approach loop (`MEADOWS_MACRO_LAYOUT.md`
  §3.2, (230,3670)→(130,3980)) exists so the compound is read from its own picket
  line. The pylon run, the gate, the pad and the console are visible from Orrin's
  post before the player is inside.
- **Fought with what is left.** Four fights, one camp clearing *before* the first
  picket (vegetation order 3000 at (210,3700)), no heal inside the gauntlet. Vance's
  own line says it: *"If your five are still worn from the walk up here, fix it
  now."* The captain is the fight the player arrives at diminished, and the fight
  where switching is forced.
- **Won and the place changes at once.** `relay_disabled` kills every lit conduit
  by material identity, removes the four posted grunts, and `captive_rescued`
  removes Sela and stands her up in the village. This is the best aftermath in the
  chapter and is the model for every other site (G-6).

### 3.3 Contracts

**V-1 — Dell moves to the gate; the yard belongs to the captain.** *What is there:*
Dell at (347.5,3763.5), 4 m from the site centre, facing the road. *Do:* stand Dell
in the gate opening at local (s −13, t +0.6) — world ≈ (343.2,3771.1) — so the yard
is entered *past* him and his fight is framed by the piers and lintel; move the
decorative Relay Sentry three metres inside the yard so the two do not overlap. This
stays inside `test_every_relay_position_sits_inside_the_authored_site` (26 m
radius; the gate is 14 m out). The ladder is then road → road → gate → yard, four
distinct backdrops for four fights. *Fails if* Dell and Vance are both visible in
one engage-distance frame, or if the road through the gate is blocked by Dell's
body (keep him 0.6 m off the centreline, the rule `props.json` already uses).

**V-2 — The Tuskroot is the ace and it charges.** *Do:* reorder Vance's team to
galecrest 11, duskhush 11, tuskroot 12, so the line about not sending the weakest
first is true (the Galecrest opens hard) and the creature the player has never seen
is the one they have to beat last. Give the Tuskroot **CHARGER** (G-3): it closes
from 4.5 m in one lunge, the tell is the distance it keeps. Total levels unchanged
(34), still inside Band 3's `[8,16]`, still the highest fight in the band, still
above Dell and below Oreth. *Fails if* the Tuskroot is not the last creature Vance
sends, or if a blind tester cannot say the Tuskroot "charged".

**V-3 — The fight stands between the player and two things they can see.** Already
true: Vance is on the bearing between the yard and the console pad, Sela is 7 m
behind him facing the player. *Keep.* *Add:* the console's teal glow and Sela's
held pose must both be in frame from Vance's engage point; the props lane verifies
with the `06-relay` stands. *Fails if* either is occluded by the apparatus massing
from the challenge position.

**V-4 — Vance is the most articulate voice of the doctrine before the Warden.** His
lines are right (`_authority_not_menace`). *Do not* rewrite them. *Add one
readiness fact* (G-7): his challenge already says "three of mine"; his *defeated*
line should name what is next in the same register the others do — one clause
pointing at the far end of the line is already there (*"Ask me again once you've
seen the far end of this line"*). Keep.

**V-5 — Local healing on `relay_disabled`.** D41 says drained ground *"heals when
the machinery fails."* The relay's machinery fails the moment the console is
pressed, but its three `drains.stations` (z≈3749) only heal on `legendary_freed`
with everything else. *Do:* on `relay_disabled`, run `meadow_healing` for the
relay's own stations only (the mechanism keys healing by station; this is a filter,
not a new system). It is the *"local environment visibly changes where systems
permit"* of the owner's midgame plan §7 and it is the one thing that makes the
crossing feel earned before the player has even reached it. This reads D41 rather
than contradicting it; §9 lists it for the owner to confirm. *Fails if* a
before/after frame from the `06-relay-standing` stand shows no change in the
ground within the site radius.

**V-6 — Pacing inside the site.** From Hess to Vance is four fights in ~150 m of
road plus the yard. That is the intended density (it is a gauntlet); what must not
happen is a fifth. *Fails if* any lane adds a fightable trainer between Hess and
Vance, or a heal inside the compound. The 24-opponent census test forbids the first
anyway.

---

## 4. The three Sigil captains

### 4.1 The routing question: where is Riverwatch?

Captain Oreth stands at (−100,4350): across the river (z≈4200), 150 m past the Old
Mill Crossing, inside Band 3's z range (3180–4760), while prompt 65 and spec §3
list Riverwatch as one of the Upper Meadows' three. `MEADOWS_MACRO_LAYOUT.md` §3.1
already answers the question in one line: *"Riverwatch Captain sits off-spine on
the Band 3/4 seam."* The z-band table and the captain list are counting different
things: the band is a level band, the three captains are an objective (0/3 → 3/3).

**Verdict: leave him on the far bank. Do not move him into Band 4.** Reasons, in
order of weight:

1. A Riverwatch belongs at the water. His whole site fiction (*"the low ground —
   where everything ends up"*) only works at the draw below the crossing. Moving
   him to the Highfield or the ridge would make him a third field captain.
2. The far bank is the strongest endurance-shaped ground in the chapter *if it is
   composed as one beat*: restored crossing → the aggressive galecrest four at
   (−152,4235) r 8 on the landing → the brooktail bank → the draw → Oreth. Nothing
   between the relay and him is a heal.
3. Fight order is a design opportunity, not a problem. The player meets Oreth
   first, Halder second, Vess third. The owner's midgame plan §8 wants three exams:
   composition, power, endurance. The shipped dialogue and
   `test_each_captains_challenge_signals_its_own_kind_of_readiness` already pin
   Oreth = *"not all one type — you'll want a plan"* (composition), Halder = *"no
   trick… whoever's strongest"* (power), Vess = *"you're already breathing hard…
   whatever's left in your five"* (endurance). That is exactly the order the road
   delivers them in, and it is the right order: plan → strength → stamina.

What *is* wrong and must change:

**C-1 — Oreth's ace dips the ladder.** *What is there:* Oreth 13/14/**16**, then
Halder 13/14/15, then Vess 14/15/16. The first captain's ace equals the third's and
out-levels the second's, which is the backwards step GATEC-CURVE fixed for Halder
and left in Oreth. *Do:* Oreth to 13/14/**15** (brooktail 15). Still inside Band 3
`[8,16]`, still above Vance's 12, and the captain ladder now reads 15 → 15 → 16 in
road order with Halder's bulk and Vess's punch doing the rest. The team-shape test
(bulk/punch/spread) is level-independent and unaffected. *Fails if* any captain's
ace is below the previous captain's in road order.

**C-2 — The far-bank arrival is one composed beat.** *Do (world/props lane):* fix
Oreth's stale `facing_deg` (his own comment flags it) so he faces the crossing the
player arrives from; give his stand a three-prop "Riverwatch post" (banner on a
pier, bench, barrel — the `crossing_watchpost` cluster's own kit) so the draw reads
as a *posting*, not a man on grass; keep the galecrest four at the landing
aggressive and ungated (they are the ambush that makes "endurance" true on this
bank too). *Fails if* the crossing-to-Oreth walk has a camp-able flat pad authored
in it (there is none today; keep it that way), or if Oreth's site has no prop.

### 4.2 What each captain tests that the others do not

**C-3 — Oreth, the Draw: composition.** Mosshell (Water body, Ground charged),
Trailpup (Ground), Brooktail (Water). A mono-Ground party takes 0.8× into two of
three and 1.25× from the Water hits. *Do:* Mosshell gets **WALL** (the roster's
highest defence, 130/12/26, made behavioural: it does not chase, it waits), Brooktail
gets **CURRENT** (92/18/13, fast and thin), Trailpup default. The three read as
three shapes in one fight, which is what "you'll want a plan, not a favourite"
means mechanically. Arena: the bank at the foot of the draw, water in frame, the
mill upstream visible across the river. *Fails if* a mono-Ground party at Band 3
exit level (13) wins without a single switch, or if the tester describes Mosshell
and Brooktail as fighting the same way.

**C-4 — Halder, the Pasture: power.** Duskhush 13, Tuskroot 14, Meadowhart 15 — the
bulkiest roster of the three by test. *Do:* Tuskroot gets **CHARGER** (the second
Tuskroot in the chapter, three levels over Vance's — by now the player may own
one), Meadowhart ace gets **CURRENT** at ×1.0 power (relentless, not thin — the
"no trick" fight is pressure that never lets up). Duskhush default. Arena: the
flattest ground in the upper Meadows (measured 6° over 8 m), the herd cluster
(order 4035) grazing in the background, Juno's warm-up 190 m before. *Fails if* a
party at the band's entry level (13) with type coverage cannot win with at most one
faint, or if a party two levels under can win without a potion — the power exam
must have a floor and a ceiling and both must be measured with the pacing probe.

**C-5 — Vess, the Ridge: endurance.** The exam is the *route*, and her team is the
punchline. From the Highfield stock camp (275,5654) to her stand (−280,6460) is
~1,000 m of climbing with the severed conduit post, the wind overlook, the ridge
road picket (unmanned barricade), the patrol at (−235,6470) at 13/14, the galecrest
den at (−235,6510), and the optional Rue fight at (−300,5870) — and **no authored
camp pad** between the stock camp and the watchtower spur. *Do:* keep it that way
(the spur's 13 m clearing is her arena, not a camp; a player may still drop a camp on
open ground, and that is *their* endurance decision). Her Galecrest ace gets
**DIVER**; Trailpup and Duskhush default. Arena: the last walkable ground on the
ridge (43–76° rock past it), the stronghold first visible from the watchtower.
*Fails if* a straight run from the stock camp arrives at Vess with every creature
above 75 % HP and nothing fainted (measure in the evidence run; if it does, the
route is too kind and the fix is the patrol's team or the den's count, never a
level).

**C-6 — Three places, not three markers.** Each captain's site must answer the
blind judge's "where am I" without the minimap: Oreth — water at the feet, the
crossing behind, the mill across; Halder — open high pasture, a herd, long
sightlines, the road; Vess — rock, wind, the tower, the Hall on the horizon.
The rig-level limit is real and measured (one fused material; the three accents
read as one faction): *do not* spend another round on the captains' body palette.
Site, props, creature behaviour and dialogue carry the difference. *Fails if* the
three captain frames, shown blind side by side, are read as the same location.

**C-7 — The captains are an unordered set, fought in road order.** Nothing enforces
sequence and nothing should; the Sigil gate counts three. *Keep.* The readiness
lines already hand off in road order (Halder → *"Vess is up the road yet"*, Vess →
*"Oreth's down in the draw"*). Since the road delivers Oreth first, *do* flip the
pointers: Oreth's defeated line points up to Halder, Halder's to Vess, Vess's to the
Sigil gate. *Fails if* a first-time player is told to go back for a captain they
have already beaten.

**C-8 — Rewards stay as authored** (T3-REWARD): Field = Sigil + `tm_earth_fist`;
Ridge = Sigil + `elixir_guard`; Riverwatch = Sigil + `elixir_vigour`. Because the
road order is Oreth → Halder → Vess, the owner's ladder ("Captain 1 strong TM,
Captain 2 equipment, Captain 3 final preparation") is delivered as elixir → TM →
elixir. That is acceptable: the last Sigil still hands over a preparation item.
Not changed.

---

## 5. Keeper Hald and Warden Aldis

### 5.1 The measurable oddity, stated plainly

Hald fields 18/19/19 (sum 56, weakest 18). The Warden fields 16/17/17/18/20 (sum 88,
weakest 16, ace 20). The boss is larger in aggregate by 32 levels and five bodies,
and softer at the front by two. Between them sits a creature bed that fully heals
and revives (spec §8's recovery opportunity; `stronghold.json` `recovery`).

Does the escalation read? **Partly.** In a real-time fight the Warden's advantage
is real: five send-outs against a party that cannot heal mid-fight, five faint
pauses, 88 levels of HP. But the *experience* of the first three rounds is a step
down from the fight before: the player leaves Hald's 18/19/19, sleeps, and opens the
chapter's climax against a 16 and two 17s. The boss becomes the boss at member
four. The owner's midgame plan §3 forbids exactly this (*"each rung must feel
meaningfully harder"*), and the owner (D70) puts the chapter's payoff inside this room.

Two secondary defects in the same data:

- Hald's own `_comment` says *"three creatures of three different types"* and his
  team is Air/Ground/Air (galecrest, burrowback, duskhush). The comment describes
  the right fight and the data does not deliver it.
- The Warden's five is one of everything (Ground, Water, Air, Ground, Ground) with
  no order to it: it reads as a sampler, not a doctrine.

### 5.2 The Warden's combat identity

The spec gives him a worldview (§33) and the dialogue delivers it perfectly: control,
order, the burden of holding the seams, *"freedom without control becomes
disorder."* His fight should be that worldview made spatial. **The Warden's five are
drilled, ordered, and each one is the top of a ladder the player has already
climbed.** Not "the biggest numbers": the *most disciplined* opponents in the
chapter, sent out in an order that is itself an argument.

**W-1 — The Warden opens no softer than the elite.** *Do:* levels to
**18/18/19/19/20** (sum 94). No member below Hald's weakest; the ace stays the
chapter's highest; the sum exceeds the elite's by 38 with five bodies. Still inside
Band 5's `[15,20]`, still under the "no step over four levels" and "nothing
out-levels the boss" guards. *Fails if* any Warden member is below the elite's
lowest, or if a player who beat Hald and rested reports the Warden's first round as
easier than Hald's first. (If the pacing probe shows the team's measured exit level
cannot reach this, the number to move is the elite's, downward, never the Warden's.)

**W-2 — Send-out order is the doctrine.** *Do:* order the five as
Burrowback 18 (**WALL**) → Galecrest 18 (**DIVER**) → Brooktail 19 (**CURRENT**) →
Meadowhart 19 (**CHARGER**, the stag that closes in one lunge) → Tuskroot 20 (**ACE**, `lunge 6.5`,
`cone_degrees 72` — Earth Fist's shape, the guardian's own trick at the end of the
chapter). The first four are the four profiles the captains taught, one each, at
the top of their ladders; the fifth is the one telegraph in the chapter the player
must read. A tester who has done the captains should recognise each one as it comes
out. *Fails if* the five are not sent in this order, or if two of the first four
share a profile.

**W-3 — His creatures carry Team Tether's drill (G-4).** *Do:* `moves.quick`
overrides on the Warden's team only: Burrowback `rock_throw`, Brooktail `aqua_shot`,
Galecrest `wind_blade`, Meadowhart `rock_throw`, Tuskroot `rock_throw`. Each hit
lands 15–20 % harder than a wild of the same level and each stays on-type. Nothing
below the Warden carries a TM quick — Hald's and the courtyard's fight with species
moves, so the step into the arena is felt in the first exchange. (Range and cone on
the AI side come from the profile, not the move; the override is power and type
only, which is what the damage path reads.) *Fails if* any trainer other than
`warden_aldis` carries a TM-tier quick.

**W-4 — The arena is the emptiest room and it must stay lit.** `stronghold.json`'s
`warden_arena` is 24 × 26 m, the combat arena radius is 11 m, so the full ring fits
with a metre to spare — *keep it empty of anything with collision inside the ring*.
CONTENT-0828B measured the room at 97 % of pixels under luminance 40 before its
lights were authored; JUDGE-5 later called it *"four untextured walls and a cobble
floor."* *Do (Hall lane):* dress the walls and the far end only — banners on the
end wall behind `warden_stand`, the conduits converging on the chamber door, two
braziers outside the ring — and re-measure: the Warden's body at `warden_challenge`
distance must read above the floor's luminance by the same 1.5:1 the creature
legibility gate uses. *Fails if* any prop stands inside the 11 m ring, or if the
Warden's silhouette fails the 1.5:1 measurement at 16 m.

**W-5 — The Warden is the only Warden rig.** Already true (`npc_ranks.json`: no
`base` on the rank; the grunt rig carries every other rank). *Keep.* The badge is
the reserved oxblood family at its top. *Fails if* any other NPC in the chapter is
stood up on `warden_lod0.glb`.

**W-6 — Dialogue stays as written.** The challenge and defeat lines
(`data/dialogue/stronghold.json`) are the strongest writing in the game and match
§33 exactly. Do not touch them. G-7 is already satisfied by Hald's defeated line
(*"Rest your five first. He fields more than I do"*).

### 5.3 Keeper Hald: the last check of the kit, not the HP

**W-7 — Hald fields three types.** *Do:* duskhush 19 → **mosshell 19** (Water, the
wall). His team becomes galecrest 18 (**DIVER**), burrowback 19 (default), mosshell
19 (**WALL**): Air/Ground/Water, which is what his own comment claims. He is the
composition exam at the top of the ladder, one room before the Warden's five, and
the Water member means a party that dropped its Water answer after Oreth finds out
here, with a bed behind him, rather than in the arena with nothing behind it.
*Fails if* Hald's team has two members of one type.

**W-8 — The bed after Hald makes the elite about consumables, not HP.** Because
`home_recovery.rest` fully heals and revives, whatever Hald costs in HP is refunded
before the Warden. What he *does* cost is potions and revives spent in his fight —
and that is the correct role for the last pre-boss fight: the player walks into the
arena with whatever kit they did not burn on the Keeper. *Keep the bed.* *Do not*
add a shop, a cache or a second bed anywhere in the Hall. *Fails if* any item
pickup is placed between the courtyard and the arena.

**W-9 — The shutter is his identity.** His line *"the shutter behind me stays down
while I'm standing — that isn't a threat, it's the wiring"* is the encounter: he is
the complex's one door. *Keep* the `gated_by_flag` passage. *Add:* the shutter must
be visible behind him from his challenge position, lit by its own conduit run
(`tether_approach` is "the first space more machine than masonry"). *Fails if* the
player cannot see the door he is guarding while he says the line.

### 5.4 The gauntlet's rhythm (spec §8, kept)

Corr 15/15 (doorbell, mouth) → the alpha Galecrest pack (danger) → Sigil gate
(lock) → Ness 16/16/16 (rank) → the waystop (last camp, §7) → Outer Works: Verrick
15/16 (patrol) → Courtyard: Solene 16/17/17 (the first three-creature fight in the
building; her Mudsnout is the escaped special encounter's kin) → Tether Chamber
Approach: Hald (elite, W-7) → bed → Warden Arena: readout, the Warden (W-1..W-6) →
Legendary Chamber.

**W-10** No fight is added or removed inside the Hall; the fourth fight in the
building is the Warden. Spec §8 and §12 cap it and `_comment_gauntlet` explains why.
*Fails if* a fifth trainer stands inside the works.

---

## 6. Per-band pacing

### 6.0 Definitions the evidence run scores against

- **A pull** is anything the player can *see or hear from the road* and could act
  on: a creature inside its own notice range, a trainer, a harvest node, a prop
  cluster, a signpost, a landmark silhouette, a TM or pickup glow, a camp pad, a
  pylon line, a body of water. A thing inside a bush 30 m off the road with no
  silhouette is not a pull.
- **The longest allowed pull-free interval on a required route is 60 seconds at
  the corridor probe's walked pace (≈200 m).** D70's census puts every band's
  worst gap inside it (165 / 163 / 156 / 64 m). Gate 3 must not open one.
- **A beat** is one of: wild, trainer, resource, detour, rest, landmark, faction
  evidence. A band's rhythm is the *sequence* of beats along its spine, and no two
  consecutive required beats may be the same kind twice in a row for more than two
  steps (the "fight, fight, fight" failure the relay pickets used to be).

### 6.1 Band 2 — Stone & Root: see §2.

### 6.2 Band 3 — The River Lock (2,372 m, ~10 min)

Rhythm: haulage wreck at the seam (evidence) → pipwing/mudsnout/burrowback clusters
and the Rootstone seam at (−64,3247) (wild, resource) → Stonewater Reach, the
lockwater overlook (landmark: the gorge read from above) → the springhead and the
Elder Brooktail at (8,3560) (wild, detour) → the camp clearing at (210,3700) (rest)
→ checkpoint barricade (evidence) → Hess → Orrin (trainer, trainer — allowed: they
are 60 m apart on a road with clusters between) → the compound seen from the loop
(landmark) → Dell at the gate → Vance in the yard (§3) → Sela, console, conduits die
(payoff) → Stormtrail at (318,3830) (rare, temptation) → the crossing watchpost on
the bluff (evidence, now empty) → the mill yard and the Gear (resource, story) → the
restored crossing → **the far-bank beat** (galecrest ambush → brooktail bank → the
draw → Oreth, §4) → Riftfrill at (−176,4098) (rare) → the north-bank Ironwood cut
(resource) → meadowhart at (−6,4740) and the Galecrest alpha at (152,4552) (wild,
temptation) → the Band 4 seam.

**P-3.1** The camp at (210,3700) is the band's only authored rest and it sits
*before* the gauntlet. *Keep.* *Fails if* a rest pad or heal is authored between
Hess and the restored crossing.

**P-3.2** Roster pressure: the five is expected full here (`expected_members: 5`),
so this is *"the first region where a catch costs somebody"*. The Elder Brooktail,
Stormtrail, Riftfrill and the Galecrest alpha are four arguments. *Fails if* the
evidence run's tester was never tempted between the warrens and the river.

**P-3.3** The far-bank walk (crossing → Oreth) is a required route with three
beats in ~150 m: ambush, bank, captain. That density is intended. *Fails if* the
galecrest four at the landing are moved, gated, or reduced below three.

### 6.3 Band 4 — Upper Meadows / Ironwood (3,436 m, ~14 min, the longest band)

Rhythm: the seam's mudsnout/galecrest/duskhush clusters and the (−56,4818) Ironwood
pair (wild, resource) → the ironwood grove, the alpha Burrowback at (−285,5080),
the Ironwood stand and crafting clearing at (−330,5090) (resource, rest, temptation)
→ Stormtrail at (−440,5210) and the Galecrest alpha at (−410,5150) (rare, wild) →
Juno at (−225,5400) (trainer, warm-up) → Halder on the pasture (captain) → the
Highfield stock camp at (275,5654) (rest: the band's one *working* camp) → the herd
bull at (425,5844) and the Highfield (landmark, temptation, riding) → the camp pad
at (400,6040) (rest) → the severed conduit post (evidence) → the wind overlook
(landmark: the whole journey behind you) → the ridge road picket, unmanned
(evidence) → the patrol at the watchtower (trainer) → the galecrest den (wild) →
Vess on the last walkable ground (captain) → Rue's Tether Patrol off-spine at
(−300,5870) (optional) → the Broken Tower at (40,6800) with the revive (landmark,
resource) → the Band 5 seam.

**P-4.1** Two rests are authored (stock camp, the (400,6040) pad) and both sit
*before* the ridge climb. *Keep* the climb rest-free (C-5). *Fails if* a clearing
is authored on the spine between (−6.7,6299) and (−280,6460).

**P-4.2** The unmanned ridge road picket is the cheapest open fix for Band 4's
one-trainer-per-859 m finding (`T5-CADENCE`'s own note), but the 24-opponent census
has no headroom. *Do not* add a trainer; *do* make the barricade read as *recently*
manned (a lit brazier, a dropped pack) so it is faction evidence, not litter.

**P-4.3** Riding is the band's traversal payoff and must not create a dead slot
(prompt 67): the Meadowhart clusters here roll [11,14], so a mount caught here
fights. *Fails if* the herd bull at (425,5844) loses its `alpha` block (level +4,
scale 1.35 today; keep it).

**P-4.4** The 1,161 m dead run T4-REGIONS measured through the middle of this band
was closed by five prop beats. *Fails if* any of them (stock camp, conduit post,
overlook, picket, herd bull) is removed or moved off the spine's sightline.

### 6.4 Band 5 — Stronghold Approach (651 m, ~2.7 min, D70: arrival, not journey)

Prompt 66's numbers (23 spawn entries, 8 harvest nodes, 3 prop clusters) look thin
on a table and are not thin on the ground: the band's worst gap is 64 m, the best
in the chapter, and its density per metre is the highest. D70 forbids padding it.
The risk is not emptiness, it is *flatness*: a short straight road where every beat
is the same size. The contract is therefore a crescendo, not a count.

Rhythm: the pylon line already running away from the seam (landmark, bearing) →
Corr at the mouth, 15/15 (trainer, doorbell) → the alpha Galecrest pack of three at
(−25,7255) (wild, the danger beat — the largest aggressive cluster in the chapter)
→ the exposed diagonal with the duskhush roost and the stone node (wild, resource)
→ **the scorched pocket seen from the road** (detour: the special Mudsnout, the
Sunstone at (121,7336), `tm_heavenfall` at (140,7300), the pipwing flock) → the
Sigil gate on the road at (63.6,7400) (lock, payoff of three captains) → Ness 44 m
past it, 16/16/16 (trainer, rank) → **the waystop** at (−25,7460) (rest, the roster
moment, §7) → the last pylon → the works.

**P-5.1 — The Hall must grow.** The one pull that satisfies this band's cadence for
free is the silhouette the player is walking toward. `stronghold.json`'s exterior
lift and weathering rounds exist for this. *Fails if* the Hall does not read as
distinctly larger at the waystop than at the seam in the blind judge's frames
(400 m / 100 m stands).

**P-5.2 — The scorched pocket must be visible from the spine.** It is 100 m east of
the road at the exposed stretch. Today a straight-line runner never sees it. *Do
(world lane):* one pylon spur or one drained-ground tongue from the trunk line
toward (121,7336), and the TM's glow and the Mudsnout's silhouette on the pocket's
near edge, so the detour is *announced* from the road. *Fails if* the Gate F
straight run reaches the gate without the pocket ever entering the frame.

**P-5.3 — Nothing else is added to the road.** Not a trainer, not a cache, not a
cluster. *Fails if* the band's entry count rises for any reason other than P-5.2
and §7.

---

## 7. The roster-pressure moment before the legendary

### 7.1 What the mechanism already guarantees, and what it cannot

`chapter_curve.json`'s `five_slot` block keeps the cap *arithmetically* live: the
strongest wild in every region is within two levels of the team that arrives
(`max_catch_level_deficit: 2`), and the merged spawn table fields at least six
species. D38's release ceremony makes any full-belt catch an immediate,
un-dodgeable, in-place choice with the real creatures' history on screen. The
plumbing is done and tested.

What no number can do is make the player *stand somewhere and think about it*. That
is a staging job, and D70 says where: *"'Are these the five I want to take in?' is a
real beat and it needs somewhere to happen; the runway for it is the tail of band
4"* and the approach. The waystop is that somewhere. Today it is a good camp with
nothing in it that asks the question.

### 7.2 The moment, staged

**R-1 — The waystop is the moment, not a menu.** The clearing at (−25,7460) r 14 has
wood, stone and fiber inside a few paces, a fire, an anvil, seats, the last pylon
framing it 17.6 m outside its edge, and the Hall 100 m ahead. Three things are
added to it and nothing else:

**R-2 — A duty board that says what is inside.** *Do:* one Team Tether readout at
the waystop — the same primitive panel and `interactable` + conversation mechanism
`stronghold_climax.json`'s `reveal` uses (`stronghold_climax.gd::_place_readout`
builds it from one config entry; band 5 needs that builder reachable for a second
entry, a small placer change, no new mesh) — carrying the Hall's garrison
roster in the faction's own register: *VERRICK — 2. SOLENE — 3. HALD — 3. WARDEN — 5.
NO RELIEF UNTIL THE DRAW IS STABLE.* It is the owner's §10 readiness layer in the
world: the player learns, before committing, that the last man fields five and that
the fights are consecutive. The spoiler test (`tests/test_dialogue_runner.gd`)
forbids the words *legendary / veridian / stag / power source* outside
`stronghold.json`; the board must not name the source, only the draw. *Fails if*
the board names what is in chamber five, or if the player can reach the works
without the board being in frame from the waystop fire.

**R-3 — The last "one more", visible from the fire.** *Do:* one named, once-only,
catchable individual standing on the drained ground *between the waystop and the
works*, on the spine's own line of sight, promoted from the existing cluster at
(−20,7505): its first member becomes an **alpha** through the `alpha` block the
director already supports (`level_bonus: 2` over the band's [14,17] roll → 16–19,
`scale 1.3`; `_make_alpha()` brings the alpha colourway, the mote aura and the
`Alpha` nameplate, and the block makes it once-only), with `combat` = **WALL** once
G-2 lands. It is the strongest wild creature in the chapter, at parity
with the elite the player is about to fight, in silhouette against the Hall, and
catching it costs a slot. The four ordinary members of that cluster stay ordinary.
*Fails if* the individual is not visible from the waystop fire at the default camera
pitch, if it respawns, or if its level is below the team's expected entry (16).

**R-4 — The cost side is on screen when the choice is made.** D38 already shows
level, type, stats, appraisal, traits, moves, bond on all six rows. *Do (UI lane,
small):* the Team screen's detail column shows the D70 bond *task* line
("38/50 wild creatures defeated together"), `battles_fought`, `caught_on_day` and
the Best Creature mark for every row — all four fields exist on
`creature_instance`. *Fails if* a release row shows a number with no history under
it.

**R-5 — Nothing at the waystop heals for free.** It is a clearing the player camps
in, not a hotel (prompt 66, owner plan §5 "Camps"). *Keep.* *Fails if* a bed,
potion or revive is authored inside the clearing.

**R-6 — The moment is measured, not assumed.** The band-5 evidence template must
record: whether the tester opened the Team screen between the Sigil gate and the
works; whether they engaged the doorstep elder; whether a catch, a release or a
refusal happened; and their answer to *"are these the five?"* in their own words.
*Fails if* a fresh, realistic run reaches the works without a recorded roster
decision or refusal anywhere after the river.

### 7.3 The legendary's own decision (kept, with one gap flagged)

The chamber sequence is the best-written beat in the game and the ceremony is D38's:
the stag crosses to the player, puts its head down, *"you have not so much as reached
for an orb"*, and a full belt opens the Team screen with the Veridian as the sixth
row. *Keep all of it.* Two contracts on top:

**R-7 — The ceremony opens with the stag in the viewport and the five rows showing
their bond task and battles** (R-4), so the comparison is history against history.
*Fails if* the sixth row is focused with the five rows' history hidden.

**R-8 — Refusal is an ending, and the stag must go somewhere.** `legendary_settled`
already treats "let it walk" as complete. What the world does with a refused
Veridian is not written anywhere: it stands freed in the chamber forever, or it is
seen again in the healed meadow. This is a story choice and §9 escalates it; the
recommended answer is *seen again*: after `legendary_freed` with no
`legendary_joined`, the Veridian stands at the Highfield herd (the one un-hostile
pocket, 4064/4101) with no engage prompt. *Fails if* a refusing player never sees
the creature again.

---

## 8. Where this contradicts something shipped

Each row is a deliberate change to landed data or a shipped reading; the lane that
owns the file makes the edit and cites the contract id.

| Id | Shipped | Change | Owner lane |
|---|---|---|---|
| G-2 | one global `enemy` block for every opponent | per-body `combat` override merged in `set_engaged()` | combat/encounter lane (one function, one merge) |
| G-9 | guardian's signature move is catch-only | guardian `combat` = WALL with Earth Fist's cone | warrens data |
| V-1 | Dell 4 m from the relay centre, 7 m from Vance | Dell to the gate opening; sentry 3 m inside | band 3 data |
| V-2 | Vance tuskroot 11 / galecrest 11 / duskhush 12 | galecrest 11 / duskhush 11 / tuskroot 12, Tuskroot CHARGER | band 3 data (+ `tests/fixtures/band_split_baseline` mirror) |
| V-5 | relay drain stations heal only on `legendary_freed` | heal the relay's own stations on `relay_disabled` | healing/world lane; owner confirm (§9) |
| C-1 | Oreth 13/14/16 | 13/14/15 | band 3 data (+ fixture mirror) |
| C-2 | Oreth `facing_deg` stale, no prop at his stand | re-derived facing, a three-prop post | band 3 data / props |
| C-3..C-5 | captains' creatures fight the default profile | WALL/CURRENT, CHARGER/CURRENT, DIVER per §4.2 | band 3/4 data after G-2 |
| C-7 | defeated lines point Halder → Vess → Oreth | Oreth → Halder → Vess (road order) | dialogue |
| W-1 | Warden 16/17/17/18/20 | 18/18/19/19/20 | band 5 data (+ fixture mirror; `_comment_levels_sh47` reasoning re-checked with the pacing probe) |
| W-2 | Warden send-out order unstated | burrowback → galecrest → brooktail → meadowhart → tuskroot, profiles per §5.2 | band 5 data |
| W-3 | Warden's creatures use species quicks | TM-tier quicks on the Warden's five only | band 5 data |
| W-4 | arena bare | end wall and door dressed, ring kept empty, re-measured | Hall lane |
| W-7 | Hald galecrest / burrowback / duskhush | duskhush → mosshell | band 5 data |
| P-5.2 | scorched pocket invisible from the road | a spur or drained tongue and a visible glow/silhouette | band 5 world |
| R-2 | no readiness carrier at the waystop | a Team Tether duty board (readout mechanism) | band 5 data + dialogue |
| R-3 | (−20,7505) burrowback cluster ordinary | its first member is a once-only alpha, WALL | band 5 spawns |
| R-4 | Team screen shows bond as a meter | bond task line, battles, caught day, Best mark on every row | UI |

Things this document deliberately does **not** change, because they are right:
the guardian's level, scale, colourway and den; the relay pickets' road placement;
the captains' body palettes; the Warden's dialogue; the bed after Hald; the
number of fights in the Hall; Band 5's length; the ceremony's three beats.

---

## 9. Questions escalated to the owner (not decided here)

1. **V-5 — Local healing at the relay.** D41 says the land heals when the machinery
   fails; the relay's machinery fails at the console. Healing the relay's three
   stations on `relay_disabled` (and the quarry's four? no — the quarry has no
   console) is this document's reading of D41. Confirm, or keep all healing for
   the Warden.
2. **W-1 — The Warden's front.** 18/18/19/19/20 is the recommendation. The
   alternative that keeps the shipped 16 opening is to lower Hald to 16/17/18 so
   the ladder still climbs; that makes the elite softer than Solene's ace (17). The
   recommendation is to raise the Warden, not lower the Keeper.
3. **R-8 — Where a refused Veridian goes.** Recommended: seen again at the
   Highfield herd after the healing, unengageable. Alternatives: stays in the
   chamber; never seen. Story decision.
4. **R-3 — A doorstep elder at level 18–19.** `chapter_curve.json`'s tests bound the
   *band* [14,17]; an elder's `level_bonus` sits on top of the roll by design (the
   Warrens residents already fight above their field). Confirm that a wild at
   parity with the elite, on the last 60 m before the Hall, is the intended
   pressure and not a wall — it is optional and catchable, never in the way.
5. **G-2 — Scope.** The per-body `combat` override is one merge in one function
   and data everywhere else. If the coordinator rules it out of Gate 3, every
   profile row in §3–§5 degrades to "default behaviour" and the encounters keep
   their presentation, order, composition and context contracts. The three-sentence
   test (G-1) would then fail on sentence (b) for every encounter except the
   guardian's catch, and this document says so rather than pretending a name and a
   colourway are a behaviour.

---

## 10. How a lane uses this

- Cite the id in the commit that satisfies it and in the band report.
- A contract's *fails if* is the evidence-run assertion; put it in the band's
  evidence template verbatim.
- Every number here is TUNABLE; every shape is not. If a number cannot be hit
  inside the existing tests (`test_chapter_curve.gd`, `test_trainers_data.gd`,
  `test_band_content.gd`'s baseline fixture), move the number and keep the shape,
  and say which.
- If a contract needs a file another lane owns, write the row you would have
  written into your report and name the lane, the way T5-CADENCE did for the ridge
  picket. Do not edit across ownership.
