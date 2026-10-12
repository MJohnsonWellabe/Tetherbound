# F25#0 code-blind judge, round 2 (coordinator, Sun 11 Oct 2026, 9:14 PM CT)

Input: v2 sheets at 339b0ea37 (systems-b; capture at aaa271a8a), 24 generic archetype sequences.
Method: two independent code-blind judges with 12 sheets each. The names were shuffled (clip-01..24; key withheld) and the judges had no README, code or mapping. PASS = body, trail (N/A for self-targeted) and impact all clearly visible, with no blocking defect.

Verdict: **FAIL, 4 PASS / 7 WEAK / 13 FAIL** (needs about 20 PASS). This is the second failed round (r1: 12/24 at 20d194139), so it is parked under the two-attempt rule and re-scoped (see below).

| archetype | verdict | judge's reason (short) |
|---|---|---|
| shadow_bolt | PASS | readable spiky orb, purple trail, flash and burst plus scorch |
| charge_dash | PASS | solid textured orb, dust spiral, chips and dust ring |
| water_jet | PASS | clear beam to snout, mist, splash burst |
| fireball | PASS | 3D orb, glow streak, flash, burst, scorch |
| stone_throw | WEAK | real stones; trail a faint smear; small contact puff |
| flame_cone | WEAK | strong fire cloud impact; flight is a thin low streak, no head |
| tidal_wave | WEAK | see-through crescent close to a flat ribbon; weak trail |
| quake_ring | WEAK | solid boulder; faint trail; puff reads as a flat disc |
| chain_lightning | WEAK | thin line bolt, little volume |
| sky_lightning | WEAK | strong bolt; impact leans on cartoon speed lines |
| psychic_pulse | WEAK | clear orb; corkscrew floats above, not behind it |
| slash_trail | FAIL | flat fan slabs appear at the target, no travel, a slab through the boar |
| heal_pulse | FAIL | faint flat 2D ribbon at the caster, nothing envelops it |
| wind_blade | FAIL | near-invisible flat slab, no trail |
| tornado | FAIL | ribbon segments drift above the target and miss it |
| ice_shard_volley | FAIL | flat card shards, no trail (contact good) |
| debuff_hex | FAIL | huge bubble spawns swallowing the caster; ribbon in the sky; no impact |
| ember_burst | FAIL | tiny random dots, too faint |
| catch_tether_beam | FAIL | 1–2 px line, no reaction at the target |
| buff_aura | FAIL | flat squares spiral above the head; nothing on the body |
| root_stone_spikes | FAIL | flat grey slabs under the target, no dust or debris |
| bubble_volley | FAIL | far too faint |
| guard_flash | FAIL | sphere floats in front of the face instead of wrapping the caster |
| frost_breath | FAIL | shapeless faint smear |

Patterns: orb and beam bodies with particle trails work. Ribbon, slab and card meshes, thin lines and caster-anchored auras do not.

## effects-claude kit r1 (8:08 AM CT Mon 12 Oct; tb/ev-effects-claude d3f60022): 4 PASS / 17 WEAK / 1 FAIL of 22 judged
Two independent code-blind judges, 11 clips each. Clips 08 and 19 (water_jet and the tether beam on the original renderer) were excluded; the lane is rebuilding them on the kit.
- PASS: 02 (storm bolt with chunks), 06 (rock volley), 09 (fireball), 18 (leaf nature buff).
- FAIL: 07 (fire reads as a stack of identical yellow spheres).
- Shared WEAK causes:
  - one pale grey-white impact dome plus streak cards on most clips, which hides the target's face and doesn't read as the element;
  - recoloured orb projectiles;
  - bare projectiles with no trail;
  - no cast wind-up;
  - earth spikes with no flash that crowd the target;
  - lingering clouds on the target's head;
  - generic self-buffs.
- The lane's self-judge reported 20/24 under a looser prompt. It was given the coordinator's exact bar for its next self-check.

## effects-claude kit r2 (9:44 AM CT Mon 12 Oct; tb/ev-effects-claude 59d57018): 12 PASS / 10 WEAK / 2 FAIL of 24
Revised bar (a brief contact flash may overlap the face; the after phase must not leave a lingering dome or cloud). Two independent code-blind judges, 12 clips each.
- PASS: 02, 04, 07, 09, 10, 13, 16, 17, 19, 20, 22, 24.
- WEAK: 01, 05, 06, 08, 11, 12, 14, 15, 18, 21.
- FAIL:
  - 03: even-width glowing ribbon lightning, no forks;
  - 23: sparse guard buff, no burst.
- Follow-ups sent:
  - rocks hanging at the snout after impact (01/13/24);
  - 17 and 20 near-duplicates;
  - thin water-jet core (12);
  - capsule fire (08).
- No red in any clip.

## effects-claude kit r3 and r4 (9:57 and 10:06 AM CT Mon 12 Oct): 0 FAIL, F25#0 MET
Two independent code-blind judges per round, each seeing every changed clip, with the same revised bar.
- r3 (0f6026b3), changed clips 01, 03, 08, 10, 12, 13, 17, 22, 23, 24: X 3/5/2 and Y 4/4/2 (pass/weak/fail). FAILs:
  - 08: flame puffs never left the caster (root cause: the 32-slot pool recycled the far puffs);
  - 03: lightning too thin (one judge);
  - 12: no contact flash (one judge).
- r4 (b6d8d237), changed clips 03, 08, 12, 13, 24: X 1 PASS / 4 WEAK / 0 FAIL; Y 3 PASS / 2 WEAK / 0 FAIL.
- Final state, all 24 archetypes at their latest version:
  - every clip PASS or WEAK from both judges, 0 FAIL, no red;
  - every archetype has a real 3D or particle body, a trail, an impact and an audio.json sound entry;
  - configured in data/config/kit_move_effects.json and vfx.json move_library.
- WEAK carry-overs (generic look, not blocking):
  - 08 soft flame puffs;
  - 13/24 faint flight trail and white flash;
  - 23 generic guard glow;
  - 05/06/11/14/15/18/21 from r2.
- Flag kit_move_effects.enabled turned ON by the coordinator at 10:06 AM CT. Move-effect, VFX, trainer-battle and solo-duel tests with the flag on: 29 tests, 0 failed.

## F25#2 and F25#5 regression checks under the kit (10:2x-10:37 AM CT Mon 12 Oct)
- c3424109 rank pairs: the code-blind judge picked the mastered row in 3/3 (pebble and fireball PASS, ice WEAK). The judge saw a single stone in flight: the volley fanned along the camera's depth axis.
- 2f624913 (merged 11:3x AM): clip-P1 pebble toss shows 3 separate stones in flight (F25#2 PASS). Pair-01 mastered row identified, with about 6–7 larger stones against 3, visible without zoom (F25#5 PASS). The min-size floor fix (it had clamped rank growth) is also merged.
