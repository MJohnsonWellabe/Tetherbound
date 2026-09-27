# F13#3 — six local chains inside the earned four-biome Water stage

Criterion (ACCEPTANCE §6.1 F13#3): six selected local chains, one per group,
satisfy §5 (visible lure, distinct optional action, useful once-only reward +
acknowledgement, saved completion).

**Status: not closed.** Everything below is a `DRY RUN — does not count`: no
earned `water_arrived` checkpoint exists yet (Meadows B8 blocks the relay), so
the run starts from a declared Water-arrival fixture. The lure clause remains
with Codex (V-TW-2..6).

## Design

The close run is the four-biome Water stage itself
(`tests/smoke_four_biome_continuous.gd` `_stage_water_to_ending`) with the six
chain visits woven in at the points where the earned route naturally stands.
From an earned save no upstream flag can be pre-set, so the run plays
Tidewake's main path and every upstream fact comes from the earned segments.

| After earned segment | Chain(s) | Travel |
|---|---|---|
| WATER_OPENING (Pell lesson, First Shore) | Lantern (Pell) | swum: First Shore <-> Lantern Cove |
| BRINE (Tovin trial won, Brine Steps) | Gull (Adair) | swum: Brine <-> Reedhaven <-> Gull Rest |
| TIDAL (Swim Stone + saddle recipe, Tidal Cradle) | Cradle (Otto) | on foot |
| LATE_WATER (Nerissa defeated, tether released; inside Veilfall) | Deep Watch (Orsen; real Tidecoil), Garden (Edda), Lastlight (Halen) | ridden on the earned saddled swimmer |
| WATER_ENDING | saved completion: production save -> reset -> load -> rebuilt Water world; every chain's records/receipts/quest log/rewards re-asserted, each requester greeted again (acknowledgement or its post-restoration line, never a re-offer) |

* Early visits return by input to the exact island/position the segment left,
  so the next earned segment's own entry checks (e.g. Reedhaven's "begin at
  lesson-east") are unchanged.
* Late visits sit before WATER_ENDING because Edda/Orsen/Halen stop offering
  their leads once the ending restores the currents
  (`water_characters.json` greeting_when). The trainer leaves the interior
  through its own "Return through the waterfall" prompt, and re-enters by
  "Enter behind the waterfall", then walks the late segment's interior path
  back to Nerissa's chamber for the ending.
* Garden and Deep Watch routes are saddle-gated
  (`requires_compatible_active_swim_mount`). They are ridden: party_cycle to
  the swimmer, creature_recall to deploy, walk up, Interact on Ride, stick
  through the authored polyline, Interact on Dismount. After the real
  Tidecoil win, the swimmer is re-selected/redeployed and ridden from the
  shallows back to the Deep Watch landing. There is no position write.

Code:
* `tests/helpers/tidewake_b_local_chains.gd`: chain step logic factored out of
  `tests/smoke_tidewake_b_chain_route.gd`, which now drives this helper. It
  adds ridden travel and `_here()`. When the trainer is in open water it keeps
  the last island the trainer was positively on, which fixes the lost
  current-island state ("no water route chain from ''"). Swims never use
  saddle-gated routes (the Garden stamina failure). `earned = true` makes any
  fixture path fail.
* `tests/smoke_four_biome_continuous.gd`: `--with-local-chains` (hooks listed
  above) and `--dry-run-water-fixture`.
* `tests/helpers/tidewake_b_water_arrival_dry_fixture.gd` is the DRY RUN start.
  It mirrors the earned Waterward handoff's end state (completed Stormwood
  world facts through the ledger, `realm_gate_water_unlocked`, key consumed,
  five creatures at L55 (`ENTRY_LEVEL`; the first two dry runs used L46) with one duplicate species, knife/axe/pickaxe on the
  hotbar). It then calls production `enter_realm("water",
  "water_arrival_from_stormwood", bypass_gate=true)`, where the bypass stands
  in for the consumed key.

## How to run

DRY RUN (now):

    godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \
      --dry-run-water-fixture --with-local-chains --no-checkpoints

Close run (once a recorded fixture-free run has exported `water_arrived`):

    godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \
      --resume-from=<name>:water_arrived --with-local-chains

Pass means that `FRESH CAMPAIGN RESULT` shows `campaign_complete: true`, with
six `F13#3 CHAIN ... PASS` lines and six `F13#3 RELOAD ...` lines in
`local_chains`, and `POSES (0 ...)`. The resume must be refused unless its
receipt matches (see `four_biome_checkpoints.gd`).

## DRY RUN results

See the section appended below and the logs in this directory
(listed below).

### Woven four-biome Water stage (`--dry-run-water-fixture --with-local-chains`)

| Log | Start | Reached | Chains | Stopped by |
|---|---|---|---|---|
| `dry_run_1_first_shore_hub.log` | fixture L46 | Pell lesson | Lantern FAIL | Helper bug, fixed: First Shore's "landing" hub was the trainer's bind position (lesson-east), so the walk to the Lantern departure stalled. The hub is now the island's first authored departure anchor (the world start spawn), which is the route the standalone run proved. |
| `dry_run_2_L46_tovin_timeout.log` | fixture L46 | Reedhaven paid | Lantern PASS (swum, returned to lesson-east; Reedhaven's own entry check passed) | Main path: BRINE Tovin hosted fight exceeded 180 s at L46 (fixture-party strength). The fixture was raised to L55. |
| `dry_run_3_L55_woven_stage.log` | fixture L55 | `water_shellwatch_liberated` (41 min) | **Lantern PASS**, **Gull PASS** (swum Brine <-> Reedhaven <-> Gull Rest, returned to Brine for Shellwatch) | Main path: TIDAL "Aquaryn fight exceeded 180 seconds". This matches Tidewake lane blocker **B1** (stale host Wind in shared encounters; patch on `tb/tidewake`, shared file not granted). Cradle, the swimmer preparation, late Water, the three late chains and saved completion were **not reached**. |

In the woven run, each earned segment after a visit (Reedhaven, Shellwatch)
accepted its entry unchanged, so the visit-and-return design holds at those
two points.

### Ridden Garden / Deep Watch legs (standalone `--continuous --mount-fixture --only=garden,deep`)

The woven run cannot reach the late chains until B1 clears. The ridden
machinery was therefore exercised in the standalone witness. Its disclosed
fixtures: a Water Mosshell L43 as the fifth member, a carried Swim Saddle,
`water_swim_saddle_recipe_learned`, and the witness's usual upstream flags.

| Log | Result |
|---|---|
| `dry_run_ridden_1_mount_check.log` | Ride worked (the Dismount prompt won), but the identity check `mount_body().instance == mount` failed. Replaced by `_on_mount()`: the mounted body is the director's deployed ally, and that ally is the owned swimmer. |
| `dry_run_ridden_2_salt_crown_landing_stall.log` | The mount stalled about 70 m short of the Salt Crown arrival anchor (4251-frame budget). A 240-frame stall detector now handles this: on the final leg the trainer dismounts by Interact and walks/wades the rest. |
| `dry_run_ridden_garden_deep.log` | Ridden First Shore -> Reedhaven -> Brine -> Shellwatch -> Tidal -> Salt Crown (5 RIDEs, all dry). **Garden PASS**: Edda lead, RIDE Salt Crown -> Drowned Garden 709 m on the saddle-gated route, wall account by Interact, Candy II claimed, RIDE back 709 m, Edda return + thanks. This fixes the continuous_f failure (stamina death swimming the gated route, then lost island state). Deep Watch: RIDE Salt Crown -> Sluice 468 m, Orsen's Sluice conversation heard. Then RIDE Sluice -> Deep Watch 351 m, and the **real Tidecoil fight WON** (135.6 s, 0/5 fainted, engaged by Interact). **Deep Watch FAIL after the win:** the trainer stood in the cliff-foot shallows (1487, -0.2, 3439). The baked-ground plan was non-empty and the trainer was not swimming, so the helper did not ride back. Every walk from there stalled at leg 1, and the remount was attempted only mid-route, where it went nowhere (11416 frames). Fixed after the run and not yet re-run: with a mount, the helper now always rides back to the Deep Watch landing after the fight. |

### Standalone witness after the refactor (fixture mode, `standalone_refactor_check.log`)

Lantern, Gull, Cradle, Deep Watch and Lastlight PASS. Garden FAIL: the
stick-walk to Edda stalled on Salt Crown's slope (leg 36/73, y=38) in this
position-write mode, and every later Garden step cascaded from it. The walk
code is unchanged by the refactor. The same walk passed in the ridden run
above.

## Remaining gaps

1. **No earned `water_arrived` checkpoint** (Meadows B8 blocks the relay).
   Every result here is a DRY RUN.
2. **B1 (Tidewake lane):** the TIDAL Aquaryn fight stalls, so the woven stage
   cannot reach Cradle, the swimmer preparation, late Water, the three late
   chains or saved completion. When `tb/tidewake` lands the Wind fix, merge it
   and rerun.
3. **Not yet exercised end-to-end:** leaving and re-entering the Veilfall
   interior by its prompts, and the post-ending saved-completion leg (which
   accepts either the thanks line or the chain's post-restoration line from
   `greeting_when`).
4. **Design tension (lane B3):** Garden and Deep Watch are reachable only on
   saddle-gated routes. The earned four-biome path gets its swimmer by
   releasing a duplicate species (swimmer preparation). The human-swim late
   segment on `tb/tidewake` does not produce a mount. The F13#3 close run
   therefore depends on the swimmer-preparation path. The owner decision is
   recorded by the lane, not taken here.
5. The lure clause remains with Codex (V-TW-2..6).

## Independent review (read-only subagent): APPROVE

- **Scope:** 12 files, all test or evidence; no product changes.
- **Flag gating:** `--with-local-chains` and `--dry-run-water-fixture` run only when given, and the dry-run fixture is refused together with `--resume-from`.
- **Receipts:** a dry run starts past the last checkpoint boundary, so it can never export a "no fixtures" receipt.
- **Other lanes:** the default and checkpoint flags are unchanged.
- **Follow-ups:** a dry run no longer reports `campaign_complete: true`. The fixture-party level in this file is corrected.
- **Open:** the default `--through-opening` failed once, at "natural travel did not reach and engage the tutorial Bramblebun". Its one confirming rerun passed. The cause is unexplained and was reported to Meadows.

- **Unified `--resume-from` (merge with main's F02):** `--resume-from=<name>:water_arrived` always names a chapter-boundary checkpoint. A `:<boundary>` suffix or a bare name never reaches main's Meadows reload-transition resume, which only takes a dir holding `checkpoint.json`. See `../four_biome_checkpoints/PROOF.md`. `--dry-run-water-fixture` is still refused with either kind of `--resume-from`.

## DRY RUN 5 (with X05's host-Wind fix merged, `tb/x05` @ 7ff64a15) — does not count

`dry_run_5_with_x05_wind.log`, 3067 s, exit 1. `--dry-run-water-fixture --with-local-chains`.
- **Earned main path, all passed:** the opening lesson, Reedhaven (paid), the Brine trial (Tovin won), Shellwatch (liberated), Tidal (Aquaryn Alpha defeated, now past the B1 stall; Swim Stone and saddle recipe earned; the same five kept).
- **Woven chains:** Lantern **PASS** (swum), Gull **PASS** (swum), Cradle **PASS** (Otto's lead, nest Reef Stone +4, return berries +3, thanks).
- **Stopped in** `water_earned_swimmer_preparation_segment` (saddle supply): `water:tidal_cradle:harvest:004 residency walk failed: player=(709.06, 46.27, 1548.55) target=(556.0, 6.83, 1692.0)`. The walk starts from the Tidal plateau where the Tidal segment itself leaves the trainer; the Cradle visit returned the trainer to that same spot. Root-causing is in progress.
- **Not reached:** the swimmer catch and craft, the late main path, Deep Watch, Garden, Lastlight, and saved completion.
