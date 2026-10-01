# F33 source review and combined proof cut

Owned gameplay/content source: `1fc70f9c76ef8befda277b04a814ca63fbdf5248`, based on main `30fcc38fc591d5df3a7cfb122b9da58445467021`. This is a source-ready draft, not accepted gameplay. F33#0–#4 remain **NOTMET**; runtime, network and visual flags remain OFF.

The five owned files provide 52 stack-one item definitions, 28 base recipes, 24 sequential +1..+3 upgrade links, four live tiers and four reserved tiers. Creature gear lives only in `redesign_character.creatures[uid].gear`, with Harness/Charm item IDs encoding the upgrade level. Equipment actions produce detached full-record candidates; they do not publish state, save, authenticate a peer or create a journal. Release-return planning refuses a full satchel before removal or payout. Harness preparation preserves HP fraction; Charm power belongs in the host-frozen move power once. Trainer gear has only the existing five slots and hazard/support fields.

Workbench recipes require its actual attachment tier 0 and use personal relic knowledge for their regional unlock. Forge/Altar pieces and upgrades require their paid attachment tier. The exact F24 pouch reader from frozen source `470e05ef85` / PR #511 is preserved. F24 owns command numbers and its `tether_commands.gd` dependency must be present in the integrated tree before engine parsing. F32 supplies `rootiron_ingot`, `tidesteel_ingot`, `skyglass_ingot`, `stormglass_plate`, and shed `fiber`, `reed_fiber`, `skyplume`, `sparkfur`. Existing water item proposals supply their registered Tidewake identities.

Independent reviewer `/root/f33_source_review` reviewed the whole owned source and exact nine-file integration proposal. Result: **PASS for source readiness only**. It found the original Workbench attachment deadlock and a regression in existing full insulated-set immunity; both were corrected before the frozen cut. No remaining actionable source defect was found. Material accents use a pass on the fitted body mesh, preserve imported materials/transforms and restore on rebuild, tint and exit; their visual quality is unproven.

| Criterion | Source verdict | Acceptance verdict and remaining work |
|---|---|---|
| F33#0 | PASS: two slots, four tiers and all upgrade links; detached inventory/refusal/release candidates | NOTMET: actual station/journal/release producer composition and named gear checks |
| F33#1 | PASS: tier material pass and exact proposed body lifecycle hooks | NOTMET: canonical deployed-body projection plus ordinary-view code-blind visual witness |
| F33#2 | PASS: HP/defence preparation, once-applied power and bounded meter contracts | NOTMET: canonical host preparation/max-HP escrow, action enrichment, complete encounter bonus cap and four real boss tier-pair C2 runs |
| F33#3 | PASS: existing fall/storm readers plus proposed swim/current/drowning/local-cold/Tidewake contact hooks | NOTMET: shared integration, actual Stormwood contact-damage producer and one named test for each hazard |
| F33#4 | PASS: exact F24 reader, four pouch metadata rows, per-UID schema, full-record staging | NOTMET: actual craft doorway, authenticated durable save/ACK/rejoin and personal co-op proof |

The essential cheap catalog check passed: live item references and cost rows, all 52 stack-one definitions, 28 recipes, 24 same-slot/same-tier sequential upgrades, Workbench unlock metadata, reserved tiers, authored bonus ordering, cap 1.52, exact F24 reader preservation, and all nine proposal before/after hashes. This is static content/source evidence, not GDScript execution, unit-test evidence, boss simulation or hazard execution. `git diff --check` passed. No Godot, check-only, import, render, export, GPU, ImageGen, Meshy, cache copying or full CI ran.

Ignored exact integration packet: `D:/tetherbound/feature-f33/.tmp/f33-integration-r1/source-cut.patch.json`, SHA-256 `bd05268d532f046a4768ea109d062b6bcbdb5623a7c7d379d3ee3fa90c06241f`. Each file has exact before/after bytes and hashes. Foundation's r2 after files are the authority/schema bases; remaining paths name their actual source in the manifest. It is a proposal, not an instruction to overwrite a later owner cut. F23 has since incorporated the finite gain cap and finite status bonus cap into its own source; the r1 MoveMastery pair is a predecessor reference only. Preserve that successor.

Still unconnected: Session's typed gear journal operation and shared pending fence; canonical fresh prepared stat/max-HP escrow through training/evolution; accepted-action gear enrichment and trusted meter cap projection; canonical deployed-body accent projection; existing release producer calling gear return before payout/removal; Stormwood's actual terrain-contact damage consumer. F31 owns the visible station caller and Foundation owns shared publication. No gear registry, action journal or client stat/balance replacement was added.

One combined runtime ticket is frozen at `D:/tetherbound/feature-f33/.tmp/f33-integration-r1/frozen-proof-ticket.json`. Every runtime/visual/C2/save/co-op result is UNRUN. It requires the actual F22 encounter/director runner, matching/prior gear pairs on identical seeds and loadouts, normal player hazard witnesses, body-scale/visibility checks and personal two-peer durable failure/rejoin proof. ROOT is the sole engine/GPU writer. No criterion may close, flag activate or merge on these source checks alone.

| Owned path | Working SHA-256 at source cut |
|---|---|
| data/config/gear.json | 47b65886fe6b801ed4965b8f606e24657038f6de726ad54d3eca9b290726daf9 |
| scripts/creatures/creature_gear.gd | 2c30127b774c374f21bcc55c7efab2f39f426ded2869fd8956a9cbc3ab7491c9 |
| scripts/player/player_equipment.gd | 85b8f46832e4fe7c3acf54bf78ea38844af376c2e500f571525f785ac7a1312b |

The combined ticket also records every owned Git blob and working hash, material-helper hashes, dependency cuts and exact proposal hashes. Board, STATE, main and shared source remain untouched by this lane.
