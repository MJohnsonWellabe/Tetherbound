# F23 source handoff and combined ROOT proof ticket

Status: source candidate only. F23#0–#5 remain OPEN. No Godot, import, runtime,
render, gameplay or export was run by F23. ROOT retains the engine/GPU token.
The coherent shared proposal keeps `move_loadout_runtime_enabled` OFF.

Anchor: CODEX_START_HERE F23 at f9b731a35a70cf86b36db51687e4ca74aa845a84,
TRAINING §7 at 27cee94fc6ff3636b9ff2ac55f5250219599246a, COMBAT §8,
CREATURES §4, and docs/ACCEPTANCE F23#0–#5. Owned source baseline b7cb96de89;
shared proposal baseline a5f16a39c25c2c562014baca22911153afc15ea6, matching
ROOT's Manager aebc9180, HUD c43f4ca7 and combat config eb308771 hashes.

## Authored source

Owned data contains 58 species, 70 learnset rows (including water aliases), ten
utility archetypes, nineteen shared type/role signatures and twelve unique
signatures in the existing moves registry. L1 quick/charged/signature, L5/L15
utilities and breakthrough ordinals 1–5 are authored. Existing primary types,
base stats and placeholder visuals are preserved. Stormursa has learning data
but acquisition/evolution and art activation remain OFF.

Teaching stages known moves, knowledge-only primary-type TMs plus exactly one
inventory debit, canonical party admission, and revision-fenced three-slot
edits. Mastery stages actual effective host uses, rank thresholds, effect tiers,
frozen action profiles, full-meter spend, actual arrival damage/effects, and
landed-only meter gain. These are pure candidates: dictionaries are not proof
of authority, a successful stage is not a save, and UI signals grant nothing.

F29's guarded species delta was integrated from its exact
`ralph/reports/TRAINING/f29/species-delta.json` at 0c1b7151f1 (draft PR 507).
Only its approved evolution metadata was added. Cannonback/Stormcapra retain
their wild-form provenance; Staticub/Stormursa evolution remains disabled.

Shared proposal files live under `.tmp/shared/after`; before/after hashes and
one unified patch live beside them. They are reviewable proposals, outside the
owned PR. ROOT must reconcile their exact context with its current shared
sources. The schema proposal is a required landing dependency: new signatures
in loadouts/knowledge/mastery must be admitted by the typed portable schema.
The actual backpack TM branch delegates to Foundation, without local debit or
auto-equip. The controller mapping, manager dispatch, HUD and station panel
are consumers of the same producer below.

## Required canonical producer contract

Foundation owns the existing CharacterAuthority, writer, journal, session and
inventory/party projections. Reuse the paid Altar/forward-camp placement and
interaction identity. The interaction adapter accepts that station's key;
it creates no station registry. Validate real source, proximity, realm,
ownership/admission, stable character, world namespace, session epoch, owned
UID (maximum five), active fight refusal and both revisions on the host.

Session methods required by the authored UI:

- `move_station_available(station_key)` returns current host availability.
- `quote_creature_loadout(station_key, uid)` returns `ok`, stable
  `character_id`, `creature_uid`, `station_key`, `session_epoch`,
  `world_namespace`, `character_revision`, `loadout_revision`, a four-slot
  `loadout`, and `options` for the three editable slots. Rejoin returns the
  original `pending_intent` from the same journal.
- `submit_creature_loadout(station_key, intent)` accepts the immutable
  `edit_id`, character/UID/epoch/namespace, expected character/loadout
  revisions and three requested slots. Stage via Teaching and use the same
  character CAS/writer/journal; retain this exact decision during lost ACK.
- `reconcile_creature_loadout(station_key, original_intent)` reconciles that
  identity without rebuilding the decision against new slots or prices.
- `creature_loadout_completed(station_key, edit_id, result)` includes exact
  character/UID/edit identity, `resolved`, `ok`, `durable`, `saved` and
  `acknowledged`. Success completes only after the real owner bool-write and
  matching host ACK. A durable unresolved decision cannot be cleared as a
  refusal. The existing pending row survives screen/station teardown.
- `submit_creature_tm_knowledge(intent)` receives `teach_id`, `creature_uid`,
  `tm_id` from the actual backpack. Foundation adds trusted admission context,
  freezes the intent and stages Teaching's knowledge+inventory candidate in
  the existing durable transaction. No equipped slot changes.

EncounterDirector/F21 owns the SAME live actor binding and accepted actions.
Add `move_action_start` to `submit_encounter_intent`; a peer supplies only
encounter/UID/slot/move ID. Recheck canonical slot, known moves, alive/piloted
UID, generation, state/cooldown and full meter for signature before accepting.
Mint the action identity and freeze via MoveMastery. Ultimate spending belongs
to that acceptance transaction, never to local input or a hit callback.

`local_move_action_view(encounter_id, uid)` projects trusted `ready_slots` and
`ultimate_meter`. `apply_host_move_action` receives authority-verified
`started`/`resolved` deltas with UID, action identity, body generation and the
frozen profile; presentation cannot authenticate this dictionary itself.

At real host release/arrival, recheck alive UID/generation and host geometry,
roll/stats/status/target type, then call `stage_action_outcome` inside the
existing HP/effect transaction. Publish its actual clamped target debit,
source heal/status, mastery, meter and original accepted receipt together.
Keep the original decision through save refusal/retry/lost ACK. Store the
returned `meter_credited` marker on the SAME original accepted action receipt;
no parallel ledger/high-water sequence. A distinct earlier action arriving
after a later action remains valid; the same receipt replay earns nothing.

Meter is per owned UID: maximum 100; actual quick/charged/damaging-utility
gains 6/14/4; signature/incoming damage gain 0. Bench switch retains it, a new
encounter resets it, same encounter rejoin retains it. No human/bench/loaner
damage or new actor registry. Utility status uses the existing effect state;
Hearten/Sap modify real damage and a next-hit buff consumes only with the
published positive clamped debit. Named signature damage is capped to 20% of
target maximum HP. Host timing owns damage; visual release occurs at windup
end and must be synchronized with the same host release/arrival clock.

## One combined ROOT proof ticket

Run only after producer/schema/shared consumer convergence on one exact
source/package with engine ownership serialized. Record commit/package,
actors/stable characters, ordinary path and independent verdict per row.

| Criterion | Named proof in the combined batch | Required result | Current verdict |
|---|---|---|---|
| F23#0 | Four-slot dispatch and controller witness | All roster slots; tap X/Y/B; RB then each face and same-frame RB+face fires signature once; A dodges; no physical holds; refusal/delayed reply cannot permit movement/burst/throw/switch during committed action; OFF mapping preserves basic combat | OPEN: source and grammar only |
| F23#1 | Learnset and real backpack teaching witness | L1/L5/L15/all five breakthroughs; alias/evolution knowledge retained; primary-type compatible TM consumes one stack, adds knowledge, leaves slots; wrong type, stale revision, duplicate/rejoin and writer failure preserve inventory/knowledge | OPEN: authored-data check only |
| F23#2 | Ten utility effects ordinary-play witness | Every role has two options; actual dash sweep/push, heal, traps/status/fields; full-health/immune/miss no mastery; Hearten/Sap affect damage; one-hit consumption only on debit; no revive/invulnerability/teleport | OPEN: data and outcome source only |
| F23#3 | Paid Altar and forward-camp durable edit witness | Actual station interaction, five owned selectors, controller focus/scroll; edit persists through bool-save/reload and two-peer rejoin; lost ACK resumes original intent; stale/foreign/fight/out-of-range refusal; forced writer failure no optimistic change | OPEN: UI adapter authored, producer required |
| F23#4 | Actual-use mastery and persistence witness | Rank 1–5 thresholds 0/25/75/150/300; real damage/effective utility only; increasing damage and visible effect tier; frozen rank on in-flight action; duplicate/no effect/bench earns none; durable save/reload/rejoin and rank5 saturation | OPEN: planners and grammar only |
| F23#5 | Actual-hit meter and signature HUD witness | Gains 6/14/4/0/0 only actual debit; out-of-order distinct arrivals each credit once, replay none; full-only single spend; per-UID bench/rejoin/new-encounter semantics; visible meter/readiness, release-before-arrival presentation; named cap; no human damage | OPEN: planners and consumer source only |

Visual QA includes the expanded HUD at 1920×1080 and ROG Ally resolution,
long signature labels, the panel scroll/focus path, and projectile timing.
Static parsing cannot establish Godot types, runtime calls, authority, visual
layout, durable correctness or ordinary-play acceptance.

## Source checks and independent review

Named selective check: `source_check.py --shared` validates authored references,
unchanged canonical types/stats/visuals, learnset gates, ten utility archetypes,
TM primary types, alias signatures, OFF flag and signature schema enums/maps.
It optionally parses two owned plus seven proposed GDScript sources with the
local gdtoolkit grammar parser. This is neither Godot nor an acceptance test.
`git diff --check` verifies whitespace only. Independent source review and
frozen hashes are recorded in the companion review/manifest evidence.

Do not reuse the old incoming-HP r5-v2 frozen packet as approved runtime source.
Do not enable or land before Foundations/F21 convergence and ROOT proof.
