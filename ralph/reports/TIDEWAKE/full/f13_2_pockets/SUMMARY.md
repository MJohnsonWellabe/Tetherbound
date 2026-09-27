# F13#2 "Eight reward pockets reachable and paid": tb/tidewake-full

## Solo: all eight pockets in one production-Water run, with the real Tidecoil fight
- Log: `pocket_walk_claim_real_tidecoil.log`. Code ccf3f806, 0 dirty tracked files.
- Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_pocket_walk_claim.gd -- --real-tidecoil`
- Result: **53 checks, 0 failures**.

| Pocket | Reached by | Paid |
|---|---|---|
| brine_upper_shelf | stick walk 483 m from the Brine arrival | Skill Candy, by Interact |
| salt_bell_terrace | stick walk 463 m | Skill Candy |
| lantern_hidden_cache | stick walk 204 m | Skill Candy I |
| gull_research_satchel | stick walk 129 m | Skill Candy |
| garden_exposed_vault | stick walk 224 m | Skill Candy |
| deep_watch_tidecoil_cache | real Tidecoil fight won by Interact-engage; the gate flag is written by the director's won terminal; then a 231 m walk | Skill Candy III |
| cradle_shell_nest | stick walk 500 m, pickaxe seam | +4 Reef Stone |
| reed_root_hollow | stick walk 219 m, knife patch | +3 Reed Fiber, and learns Reed Camp Cordage |

- Each claim is one Interact press on the production prompt. The host ledger then shows a
  receipt and the pickup is no longer resident.
- **Game defect fixed on the way (ccf3f806):** the Deep Watch chart-station lure lamp
  stood on the walk line 13 m from the landing, and every walk inland stalled against its
  post. It now stands 2.5 m beside the chart.

## Co-op: each character claims its own
Proof: `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/f13_tidewake_b_reed_recipe_two_character_pockets.json`
at ced5addd, in `two_peer_reed_recipe_run{1..5}.log`.
- Host and guest each gather their own reed_root_hollow patch: +3 fibre and their own
  cordage recipe each.
- Host and guest each claim their own lantern_hidden_cache candy.
- Repeats are refused with `already_taken`.
- The saves hold each character's own recipe and receipts; the world holds one receipt per
  character per pocket.
- **4 of 5 runs green** (24/24 steps each). Run 4 failed at step #7: the host's reed gather
  press was not accepted (+0, receipt false) with the knife held.
  - Before this, the step toggled off an already-held knife or lost a swallowed hotbar tap.
    That was fixed at ced5addd.
  - Two harness strikes, so under the owner's two-strike rule the residual intermittency
    is disclosed, not chased further.

## Shortcuts disclosed
- Solo run: one position write per island onto its authored arrival landing, because the
  pocket smoke does not swim between islands. Inter-island swims are proven in card T1
  (`../card_t1/`) and in the F13#3 chains.
- Deep Watch: after the Tidecoil win, the pose back to the landing (fixture B).
- A granted L43 retained-five party, and a carried pickaxe and knife.
- Harness-planned walks steered by real left-stick input.
- Two-peer proof: a granted knife, teleport stand-offs beside each patch, loopback ENet;
  4 of 5 runs green, as above.
- Lures are F13#3's §5 clause, not part of this row; they are not claimed here.
