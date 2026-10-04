# F19 authored curve checkpoint

Curve source: `a778658659`; source consumers through `24db37dc1d`, based on
main `ddeadbc1eb9cc2f81693d69eded98ee9183579a1`.
Windows source authoring only. No Godot, gameplay, save, co-op or earned-route
proof has run for this checkpoint. No F19/F20 criterion is claimed MET.

| Runtime realm | Team | Ordinary wild | Boss send-out levels |
|---|---|---|---|
| meadows | 3→22 | 2–20 | 21/21/21/22/22 |
| water (Tidewake) | 20→33 | 18–32 | 32/32/33/33 |
| cloudreach | 31→44 | 29–43 | 43/43/44 |
| stormwood | 42→55 | 40–54 | 54/54/54/55/55 |

`biome_order.json` remains the sole order authority. `chapter_curve.json`
adds chapter targets keyed by existing runtime realm ids and explicitly calls
them unmeasured authored targets. Its Meadows split is
3→9→12→15→18→22, with wild 2–6 / 7–10 / 10–13 / 13–17 / 16–20.
BOSSES §0's half-down formulas rederive named teams; its explicit boss arrays
override the formulas. The three Sigil captains and Band 4–5 teams gain +2.
The Warrens residents/guardian gain +2, preserving weakest resident > Band 2
field ceiling. Solmane volunteers at 44, Aquaryn is 26, and Stormheart uses
existing Fulgocobra at 55, with its offer catalogue marked non-catchable.

Band 5 retains its authored geometry, species, order ids, density, three road
supplies and recovery placement. No pickup, harvest, route, heal, combat AI,
team species, reward amount or gate was retuned. Authored alpha bonuses stay;
the separately reviewed combat helper (`dc558ee04d`, from `1bc651be72`) honors
an optional `level_ceiling`, and only leaders whose bonus could exceed 20
receive that field. Missing ceilings preserve prior behavior.

`derive_curve.py` reproduces the data edits from the recorded baseline and
preserves JSON formatting except the expanded chapter curve. The existing
band-split trainer fixture mirrors matching level edits without changing row
identities. This is a content mirror, **not an earned save**. Every earned
checkpoint fixture remains untouched and must be regenerated from the real
new-order route with provenance after runtime integration.

The required curve pin is authored at `tests/test_redesign_chapter_curve.gd`
and has not run. Required subsequent proofs remain: the curve pin, gate scan,
ordinary portal signs with no hidden level gate, per-participant key/relic
transactions with reconnect/reload, all four legendary offer branches, and
earned saves. Dependency landing holds remain F16+F18 for F19 and F18+F19 for
F20. F16 is landed; F18 is not. No PR has been opened.

The `4c3e9d791d` checkpoint adds exact `boss_hand_offs` rows to existing
chapter rewards and an unconnected pure `EncounterRewards.chapter_grants`
projector. Canonical typed keys remain separate from ItemDB SKUs; relics use
existing personal `relics_held`/`relics_hung` biome ids. Foundation owns the
protected admitted-participant delivery journal and acknowledgement. The
projector cannot yet replace a live payout until that arm is implemented.

`80a4babddf` closes the actual Stormheart volunteer's hardcoded level gap:
`stormwood_ending.gd` reads Dynamo captive level 55, with fallback 55, and
the chapter's final-encounter metadata agrees. The acceptance pin covers the
actual read. It remains unrun.

The subsequent F20 source prototype gates Grandpa on this exact personal
receipt: `home_return_after_stormwood:<world-instance>:<character-id>:<host-ticket>`.
Foundation will author it only after successful durable Home arrival for the
same admitted character who already holds or has hung the Stormwood relic.
The consumer requires matching character identity and Meadows, never a host
world's ahead flags. The producer is not yet implemented or proved.
Dialogue substitutes current names, existing companion history counters or
an honest no-history fallback, and existing personal chapter answers. An
accepted offer does not imply that companion is still retained. Starter
status now consumes only the actual-choice receipt
`starter_choice:<character-id>:<creature-uid>` from the same personal journal.
The current UID must match before Grandpa says the original companion remains;
a known UID absent from the five yields an honest absent status. A legacy or
conflicting record yields explicitly unknown status. A traded-in starter
species never proves this character chose it. Foundation owns atomic actual
adoption/save and declared receipt production, still pending. Creature counters
are lifetime history, so the text no longer attributes a prior owner's travels,
rests or feeds to this character. No invented identity, event log or reset is
introduced; exact personal bond memory remains a separate proof obligation.
Credits retain the existing character save/rollback and once-only receipts.
The old tests now explicitly use synthetic receipt fixtures for isolated
consumer and disk-persistence checks; **they are not earned route/arrival
proof**. No test has run. Tidewake's chapter result no longer qualifies a
character for homecoming.

`3cb2eaa2cf` removes the retired Cloudreach/Stormwood chapter-entry world-key
clauses. Actual F18 portal admission remains the hard gate. `6602da6a64`
authors personal regional objectives through the agreed detached traveler
getters. Before actual arrival, the objective sends the traveler by Home Key
to the Crossing Hall HOME ARCH, then along the village road to Grandpa.
An ahead host world never supplies this character's ending eligibility.
Foundation published the getter source at `a4b484cbea2b8b650185df89f0890de93bdd33a0`;
the shared source is not merged into this branch and has no runtime proof yet.
The existing quest-log fixture is explicitly synthetic and has not run.

`5c681064e1` authors fifth-arch presentation data only: the installed Hall
PortalSurface material family, a bounded 1.2-second pulse, a tracked neutral
tether-drone excerpt, and literal `Not ready yet.`. The sealed arch receives
no travel permission, quest, marker or new durable state. Asset provenance
and authored envelopes are recorded in the config; audible quality and
performance have not been measured. Foundation owns the actual Hall consumer
after a protected typed biome5 stir result.

`e5a14672e8` adds a prerequisite-field scan to the existing named curve pin
and replaces Tidewake's old cross-realm dialogue with the Home Key/Hall
route and dock resolution. `24db37dc1d` hides the old physical map crossing
in the shipping F16 path. Historical coordinate/label helpers remain for
their pure data tests. The tracked canonical portal-map consumer now requires
that foundation getter pin: only finite live destinations and the actual host
world or personal portal unlock expose remote maps. Current realm display,
local fog, chapter cycle order and icon helpers remain covered by the existing
test file. Discovery and old key/gate flags no longer substitute for unlocks;
a stirred fifth arch remains unavailable. These unlock fixtures are synthetic,
and the migrated tests remain unrun.

Remaining real-path gaps: live boss payouts still use legacy world key flags;
protected participant grants and Home travel remain unconnected. The Warden's
old reward flags must remain until its protected per-participant next-key and
relic replacement connects in the same coherent candidate. Fifth-arch effects,
all four legendary capacity/choice branches, personal objective/map getter
integration, disconnect/reload and earned route saves remain unproved. These
require owned runtime handoffs and F18's transactions before landing. All
authored acceptance checks remain unrun; there is no native or real-path PASS.

The separately allocated F22 forward-camp data hunk explicitly opts in the
existing Band 5 cluster `the_waystop` (order 5001) with `rest.loadout: true`.
Its placement, radius, crafting point, creature bed and every prop remain
unchanged. The normalized props source SHA256 changes from
`d0fc3016ffbbc91d8acbfc42527f9e0b1223db845c3d48846ff13d0c9276a8c5` to
`f6ca97297a07a488731c1948a8d89aa20a8fad8abb1120ce48ef551655e1344f`.
A source-only structural comparison finds exactly that one field addition;
this is not runtime loadout proof. Terrain/scatter bake fingerprint inputs
exclude this props file, so their freshness is unaffected. The camp's added
regional order 5001 is absent from the pre-split props fixture; no historical
fixture mirror is changed. Combat owns the actual explicit loadout consumer.

The later active-consumer audit removes the retired `realm_key_cloudreach`
entry requirement from Aila's arrival event, Maela's flight-trial event, and
Maela's matching greeting in `cloudreach_npc_runtime.json`. Their authored
chapter-start/aerie prerequisites remain intact. The named curve pin now
checks these three real data rows; no ordinary traversal has run.

Stormwood's existing `aftermath:waterward_view` event and saved objective/flag
identities remain for compatibility. Its world objective no longer grants or
consumes an obsolete Tidewake entry key; presentation/chapter completion facts
remain. Its prompt, guide and three aftermath dialogue lines now describe the
quiet cleared sky and Home Key → Hall HOME ARCH → village walk → Grandpa.
Reward metadata names typed `portal_key_biome5` and keeps the destination sealed.
Only the protected boss projector may owe the fifth key/relic to participants;
this world event never replaces it. The source generator reproduces the narrow
data edits. This source checkpoint stays unlanded until the actual protected
delivery/arrival producers connect; no partial progress-stranding cut is ready.

Cloudreach's matching active reward conversation now points its personal relic
to the Hall Shrine and its next Stormwood key to the keyed Hall arch. Aila's
existing `cloudreach_aila_after_restoration` closing line and final-reward
effect identity remain; they no longer invite a scarred physical crossing or
future Water route. The owned chapter guide and route-description metadata
match that Hall itinerary while saved objective, event, reward and flag IDs
remain intact. Legacy world key grants still await their protected participant
replacement in one coherent candidate. These lines describe the intended
handoff; the actual protected delivery and ordinary Hall travel remain unproved.

The bounded Warden, Edda and Stormheart prompt lines also direct the personal
relic to the Hall Shrine; Warden names the Tidewake key and Hall arch. Hesk's
arrival greeting no longer assumes the traveler walked down from Cloudreach.
Grandpa's six initial conversations acknowledge the actual return without
claiming every earlier personal chapter was cleared. Two existing earned
Stormheart helpers now require the authored level 55 pending newcomer; their
ordinary capacity, participant and identity assertions remain. Historical
level-44 captures and earned proof are unchanged and do not prove this new
curve. None of these helpers or updated conversations has run on this candidate.
