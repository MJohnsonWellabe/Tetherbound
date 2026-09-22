# Grandpa homecoming â€” partial regional-ending implementation

Branch `ralph/regional-homecoming`, based on PR144/d313c9817. This delivers
one missing scene in WORLDÂ§6.5: return to the existing Grandpa and have the
current companions acknowledged. It does not deliver the full regional ending.

## Implementation

`sequence_director.gd` routes the existing Grandpa prompt to the homecoming
only in Meadows after the current world's `water_currents_restored`. No
personal opening milestone is required by the homecoming helper. The current
local party supplies0â€“5 names, nickname before species display name, each
on a separate line in `data/dialogue/homecoming.json`. There is no reconstructed
past roster, forced catch, sixth slot, reward, teleport or shared-world write.
The prose celebrates the freed regional road without claiming all eight forces
are resolved or prompting another chapter. A general line honours companionship
without inventing a released-creature history.

`regional_homecoming.gd::complete` rechecks Meadows/current-world eligibility
and the character ID captured at conversation start. It sets player-scoped
`homecoming_seen`, calls existing `save_character` for that exact character,
and rolls the flag back with a readable retry notice if the save fails. A
successful acknowledgement gets a brief repeat greeting. Existing flag storage
handles persistence; no schema increment/autoload is added.

`DialogueRunner.completed` is distinct from existing `finished`: only normal
terminal advance or accepted terminal consent emits it. Programmatic close
and declined consent retain the old close lifecycle without completion.
`DialoguePanel` forwards completion and clears per-conversation substitutions.
Single-pass token expansion leaves nickname text literal, including a name
that looks like another `$party_2` token. Dialogue continues to use existing
local input ownership; other peers are not paused by a new global ending state.

## Focused evidence

Stock Godot4.7 command:
`--headless --path . --script tests/run_tests.gd --
--only=test_regional_homecoming.gd,test_dialogue_runner.gd`.
Final result **76tests/1,278assertions/0failed**. Root inspected the actual
stdout log `tetherbound-regional-homecoming-final-focused.log` in OS temp.
No SCRIPT ERROR; the existing unknown-conversation negative test deliberately
prints an ERROR for `no_such_conversation`. This is not a clean-error-log claim.

New coverage checks current-world eligibility, current roster/name fallback,
five-name display, literal token-like nickname, interrupted versus completed
dialogue, accepted/declined consent, player flag scope, save refusal/retry and
changed-character/realm refusal. Existing dialogue tests pass alongside it.
Initial helper type-inference parse errors and a mistaken compile-test API
were fixed before this final run; their failed logs remain in OS temp. They
are not gameplay failures or passing receipts.

## Acceptance boundary

Production prompt/dialogue/disk behavior has the bounded witness below;
one rendered line has the bounded readability witness below; long-name and guest/device evidence remain open. Even with those,
civilian dock exchange/departure, authored return journey, credits, complete
campaign continuation and multi-peer ending/device witnesses remain open.
No complete ending or chapter acceptance follows from these focused tests.


## Production interaction and disk witness

An OS-temp one-shot loaded actual `meadows_playground.tscn`, using a disclosed
restored-current world flag, personal free-play opening beat, fresh isolated
character ID and a legal two-creature party: Terrapup nicknamed Pip and
Brooktail. It made one setup placement1.2m beside the actual Grandpa prompt,
waited for the real InteractionArbiter to select it, then used ordinary
`interact` input to open and advance the production DialoguePanel. It did not
call the homecoming handler, set the seen flag, or substitute a fake panel.

Observed `regional_homecoming_2`, six lines including both actual party names,
normal closure, live `homecoming_seen`, and the same flag read back from the
portable character file for `character-homecoming-witness`:
`homecoming_witness:OK conversation=regional_homecoming_2 party=[Pip,Brooktail]`
`... saved_character=character-homecoming-witness lines=6`.
Root inspected the temporary script and stdout log
`tetherbound-regional-homecoming-witness.log`. An initial temporary-run setup
started before Game autoload existed; awaiting the process frame corrected
that before the successful world run. This is a fixture-backed local
interaction/disk witness, not an earned four-chapter return or remote peer test.
No SCRIPT ERROR; the existing headless material/RID/resource shutdown errors
remain, rather than a clean-engine-log claim.


Required `tests/smoke_playground.gd` exits0 with `smoke: OK`, no SCRIPT ERROR;
log `tetherbound-regional-homecoming-playground.log`. Root compared its distinct
plain ERROR lines against the preceding Water-gate Playground run: no new
error line. The same comparison for the production homecoming witness also
found no new error category. Baseline headless errors remain disclosed above.


## Gameplay-camera capture

`_homecoming.png` is actual Compatibility rendering at1280×720 from the same
bounded production interaction fixture, captured while Grandpa says
“Pip came home with you.” The player, Grandpa, interior, normal DialoguePanel
and input hint are present. Root inspected the image: this line and the
Continue hint are legible and unclipped. The initial Main Story objective and
Day1 clock reflect the disclosed fixture, not an earned campaign save.
No new camera, layout or art was staged to replace the actual scene.

Rendered run exits0, capture error0, and repeats the successful disk witness;
log `tetherbound-regional-homecoming-capture.log`. No SCRIPT ERROR. It reports
GLES mesh/material/shader/texture/instance and buffer leaks, PagedAllocator
pages and resources still in use at shutdown. This is not a clean-renderer
log or a broad art/Ally/long-name readability pass. Render lock released.


## Regional credits continuation

`ralph/regional-credits`, based on PR150/fb0b7f304, adds the local continuation
after saved homecoming. Source: `scripts/ui/regional_credits.gd`, the existing
homecoming/sequence story scripts, `data/config/regional_credits.json`, and
player scope in `data/progression/flag_scopes.json`. Natural initial completion
must save homecoming first. Older acknowledged saves receive credits after
the repeat greeting. Interrupted dialogue does not open credits.

Continue/Skip acknowledges the roll, without claiming every credit was read.
`complete_credits` saves the same character's `regional_credits_seen`, validates
Meadows/current-world eligibility and rolls back with a readable notice on
failure. Failure closes the panel; the next Grandpa greeting permits retry.
There is no schema increment, world write, party edit, reward, teleport or
reload. Input/story-modal ownership and director lockout silence local input
and camera; the world never pauses. World/realm/character/session changes
close without acknowledgement. No existing reduced-motion setting was found.

Config owns timings/layout. The1080p canvas uses72-unit margins,66-unit title,
36-unit body and54-unit/s scroll:48/44/24px and36px/s at720p. After1.5s the roll
scrolls to the bottom without auto-exit. Continue is focused; a0.25s guard
prevents the opening edge from dismissing it. Contributor/Godot/Terrain3D and
Kenney Survival Kit credits are factual but not a final release license audit.

### Verification

Sol implemented bounded source, Luna extended the existing tests, and root
reviewed actual diffs/logs. Final focused test command:
`--headless --path . --script tests/run_tests.gd -- --only=test_regional_homecoming.gd`.
**14tests/77assertions/0failed**, exit0, no SCRIPT ERROR/ERROR in OS-temp
`tetherbound-regional-homecoming.log`. Tests cover old-save eligibility,
player scope, idempotent same-character save, failure rollback/retry,
wrong-character/realm/world refusal and world/party invariants. An initial
new-test variable inference error was corrected before that final result.
All three affected scripts pass parse-only checks.

The reused OS-temp production witness loads actual Meadows with disclosed
restored-current/free-play flags, fresh isolated character and legal Pip
(Terrapup)/Brooktail party. One setup placement selects the actual Grandpa
InteractionArbiter prompt. Normal interaction advances six real DialoguePanel
lines and opens credits; a focused GUI accept press closes it. It checks disk
`regional_credits_seen`, modal ownership, no tree pause, hidden/restored HUD,
unchanged world/party/position and resumed ordinary movement. No completion
handler is called directly and no credits acknowledgement flag is preseeded.

First production run exited0 with `credits_witness:OK`. Its720p capture exposed
small text caused by1080p canvas scaling; the config correction above addresses
that. Final production rerun exits0 with the same `credits_witness:OK` verdict;
root inspected `_sheet_credits.png` at1280x720: the opening credit labels and
focused Continue button are legible/unclipped, with the remaining roll scrollable.
Log: OS-temp `tetherbound-regional-credits-final-witness.log`; isolated user-data
folder `regional-credits-appdata-0mmh9wa2`. No SCRIPT ERROR occurred. Both rendered
runs report GLES RID/material/texture/buffer/resource shutdown leaks; this is
not a clean engine-log claim and those shutdown defects are not fixed here.
Required `tests/smoke_playground.gd` exits0 with `smoke: OK`, no SCRIPT ERROR.
Log: `tetherbound-regional-credits-playground.log`. Root compared its distinct
ERROR lines against `tetherbound-ci-boundary-playground.log`: no new categories
versus the eight baseline headless material/RID/resource errors. These remain
open engine/shutdown issues rather than a clean-error-log claim.

### Remaining acceptance

This is fixture-backed local dialogue/presentation/disk proof, not an earned
four-chapter return, remote peer/device witness or complete ending. Civilian
dock aftermath/shared departure, authored return journey, final credit asset
inventory, audio and campaign acceptance remain open. No stacked PR is landed.


## Regional return guidance

`ralph/regional-return-guidance`, based on PR152/f112e7c85, closes a presentation
gap between Water's restored-current result and the existing homecoming. The
old main-story feed ended at `water_currents_restored`, leaving no tracked
return objective. The new `data/config/regional_ending_objectives.json` supplies
two rows over existing player flags: `homecoming_seen`, then
`regional_credits_seen`. `quest_log.gd::_active_main` selects that feed only
while the current merged world state has restored currents in one of the four
supported realms. Every main-story text/hint/id/entry/beacon reader shares it.
Both receipts clear the active objective; removing restoration returns the
normal chapter feed. Local Requests and earlier personal flags are unchanged.

Realm-specific hints and targets use the actual return connections: Water
First Shore (12,162) to Stormwood; Stormwood (-300,145) to Cloudreach;
Cloudreach (-55,-300) to Meadows; then the existing Grandpa destination
(-22,-16). These are horizontal coordinates from the authored configs/opening
objective, not new travel edges. `objective_beacon.gd` is now mounted in the
real Water/Stormwood/Cloudreach worlds, never their simulation shells, and
uses finite terrain grounding. Its retained MapState reference and transient
metadata owner ensure that old-realm cleanup cannot erase a newer presenter's
marker. Realm/map-reference changes refresh even without a flag revision.
No map format, progression flag, reward, party mutation, ferry or teleport.

Mara's existing current-world aftermath now describes Reedhaven/Shellwatch/
Salt Crown exchange, Rodfolk/Cloudreach couriers and the actual route home.
It remains optional speech without a receipt. The pre-existing Water NPC
`finished`/last-line guard is therefore not used as a new completion authority.
The later Grandpa/credits acknowledgements retain their verified normal-
completion and save/rollback behavior.

### Evidence and limits

Sol implemented the bounded reader/beacon/mount files; root reviewed source,
added Mara's prose, completed the focused checks and checked the production
path. All affected source scripts parse under stock Godot4.7. Existing suites
`test_quest_log.gd,test_objective_beacon.gd` pass56tests/1122assertions, exit0,
with no SCRIPT ERROR/ERROR in `tetherbound-regional-return-tests.log` (OS-temp).
Three added tests cover all four realm feeds through both personal receipts
and a different unfinished world, canonical gate/Grandpa destinations, and
old-presenter/map cleanup ownership. No new test framework or campaign harness.

A reused OS-temp one-shot loads the actual Water world at1280x720 with a
fresh isolated character and an explicitly seeded restored-current world
flag. It verifies that actual `StormwoodReturnRealmGate`, active QuestLog,
Game HUD objective, world beacon and active map marker agree. A disclosed
placement beside actual Mara lets ordinary interact input select and advance
the real DialoguePanel's five post-restoration lines. World and personal flags
are unchanged by that speech. A second disclosed pose22m from the gate yields
the actual gameplay-camera capture `_sheet_return.png`; no replacement camera
or fake UI is used. Root inspected it: objective text is legible/unclipped,
with the beam over the gate and its nearby minimap marker visible.

Production result: `return_witness:OK`, exit0, in OS-temp
`tetherbound-regional-return-witness.log`; isolated data folder
`regional-return-appdata-t_vwftzd`. This proves a local Water presentation/
interaction slice, not earned traversal, an unlocked fixture gate, a network
session, all-realm visual quality, hardware performance or the full return.
The supplied fixture has no earned party/campaign history. The rendered run
has no SCRIPT ERROR/ERROR (it reports the existing interpolation deprecation).
Required Playground exits0 with `smoke: OK` and no SCRIPT ERROR; log
`tetherbound-regional-return-playground.log`. Root compared it with
`tetherbound-dock-save-playground.log`: the same eight distinct headless
material/RID/resource errors, no new category. Baseline shutdown errors remain.

**Pacing risk:** actual return gate endpoints span roughly19km across
Stormwood, Cloudreach and Meadows before counting Water crossings and route
bends. That is source geometry, not a measured novice completion time. The
owner preference for an earned shorter return is still unanswered. This slice
preserves the current approved route. Physical civilian departure and the
earned continuous ending remain open; source-backed guidance does not accept
the journey's length or enjoyment.
