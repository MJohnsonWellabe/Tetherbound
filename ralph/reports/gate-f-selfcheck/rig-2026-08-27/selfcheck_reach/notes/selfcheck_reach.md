# selfcheck_reach — Harness self-check (CD-5): walking to a THING, and pressing interact only when there is one

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 47 s over 7934 frames at 0.0059 s/frame

### SC-R-01 — boot the real Meadows
- expected: the real world scene stands up with the village cast placed
- actual: booted world in 61578 ms (240 settle frames)
- events: t=61.70
- verdict: PASS

### SC-R-02 — input is in the world before anything is pressed
- expected: input_context is 'world'. This is the seam: every step below presses or walks, and if a modal owns input none of them mean what they say.
- actual: input_context is 'world', which satisfies "world" (owner=, focus='')
- events: t=61.70
- verdict: PASS

### SC-R-03 — an entity that is not in the world is a FAIL, not an arrival
- expected: FAIL naming the search. A coordinate walk cannot tell 'I arrived and nothing was here' from 'I arrived'; this step exists to prove the entity walk can.
- actual: FAIL no node named, grouped, labelled or speciesed 'NoSuchVillagerExistsHere' among the 172711 Node3Ds in MeadowsPlayground
- events: t=62.15
- verdict: FAIL
- observation: EXPECTED FAIL: negative control for _find_entity. A PASS means the resolver matched something it should not have.

### SC-R-04 — a prompt belonging to something else must not be pressed
- expected: FAIL. The only live prompt at the spawn belongs to `BedPrompt`, not to Tam, so `interact_with` must refuse rather than activate the wrong provider. That refusal is CD-5's S02-15 in miniature: the bed is the exact object the operator watched a segment press `interact` at 31 times through a floor.
- actual: FAIL the live prompt "[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Get up" belongs to 'BedPrompt', which is not 'Tam' nor part of it. Not pressed: this press would have activated the wrong thing.
- events: t=62.59
- verdict: FAIL
- observation: EXPECTED FAIL: negative control for the provider check. A PASS means interact_with pressed a prompt belonging to something other than the entity it was given.

### SC-R-05 — get out of bed, the way a player does
- expected: the bed's own prompt is live and belongs to the bed, so the press happens and something changes. Named with `expect_prompt` and no `entity`: this step is about the prompt that IS live, which is the other half of what interact_with is for.
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Get up" (provider 'BedPrompt'): flags 1 -> 2
- events: t=62.96
- verdict: PASS

### SC-R-06 — DIAG: out of the house, onto open ground by the well
- expected: the player stands on open ground a short walk from Tam. See this file's `_comment_why_diag`: leaving the house on foot is past what stick_navigator.gd does, and proving that is not this segment's job.
- actual: DIAG teleport to (4, -14); distance/dead-travel accumulators reset
- events: t=64.32
- verdict: PASS

### SC-R-07 — the teleport landed on the ground
- expected: the player is where the jump said, standing on the terrain rather than falling through it
- actual: 0.0 m from (4, -14), wanted within 3.0
- events: t=64.32
- verdict: PASS

### SC-R-08 — walk to Tam, tracking his live position
- expected: the walk resolves Tam by node name, re-reads his position every frame, and ends within 2 m of him IN 3D -- not within 2 m of where he stood when this file was written, and not 3 m above him
- actual: walked 2.6 m to Tam (node name) in 33 walking frames (0 held)
- events: t=65.19
- verdict: PASS

### SC-R-09 — still in the world after the walk
- expected: nothing took input during the walk. If a conversation opened on the way, this says so HERE rather than letting the next step press into it.
- actual: input_context is 'world', which satisfies "world" (owner=, focus='')
- events: t=65.19
- verdict: PASS

### SC-R-10 — the prompt is live, and it is Tam's
- expected: interaction_arbiter.gd offers 'Greet Tam', the winning provider is part of Tam, and the press changes something. A press that changed nothing is a FAIL: that is the 31-interacts-through-a-floor case.
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Greet Tam" (provider 'Interactable'): context world -> narrative_modal
- events: t=66.03
- verdict: PASS

### SC-R-11 — greeting Tam opened his conversation
- expected: input_context is 'narrative_modal': the press reached dialogue_panel.gd rather than doing nothing
- actual: input_context is 'narrative_modal', which satisfies "narrative_modal" (owner=DialoguePanel, focus='')
- events: t=66.03
- verdict: PASS

### SC-R-12 — advance the conversation by predicate until it closes
- expected: the panel's own line is read, pressed past, and the loop stops the moment is_open() goes false -- never a guessed press count, and never a press after close, which would re-open the conversation through the interaction arbiter (CD-3)
- actual: advanced 5 line(s) over 5 press(es) of interact; DialoguePanel closed, context 'narrative_modal' -> 'world'
- events: t=66.77
- verdict: PASS

### SC-R-13 — input came back
- expected: CD-3's own regression, verbatim: after any dialogue step, input_context must not be 'narrative_modal'
- actual: input_context is 'world', which satisfies "world" (owner=, focus='')
- events: t=66.77
- verdict: PASS

### SC-R-14 — walk to a harvest node, resolved by point-of-interest kind
- expected: the second of CD-5's three named targets. Harvest nodes are scattered in their hundreds and none has a name worth writing down, so this resolves by the same script-path table gate_f_probe.gd::_poi_kind uses for the dead-travel meter. The nearest is picked and the result says how many matched. `within` is 1.5 m and not 2.5: harvest_node.gd configures its Interactable at a 2.4 m radius, from a prompt node sitting 0.6 m above the node's origin, so a walk that stopped at 2.5 m in 3D was outside the game's own reach. The first run of this segment asked for 2.5 and SC-R-15 correctly refused to press -- which is interact_with earning its keep on the segment author rather than on the game.
- actual: walked 7.4 m to poi:gather (poi kind, nearest of 86 (@Node3D@60572, @Node3D@60574, @Node3D@60576, @Node3D@60578, @Node3D@60580, @Node3D@60582, ...)) in 91 walking frames (0 held)
- events: t=68.50
- verdict: PASS

### SC-R-15 — the harvest prompt is live, and the press reaches it
- expected: a live prompt from the node the walk arrived at -- "Strip meadow grass" -- and a press that reaches its provider. `expect_change: false`, written down in advance and for a reason: the player boots with an empty satchel and nothing equipped, and harvest_node.gd's `_on_gathered` refuses a bare-handed press for a resource that needs a tool, leaving the node where it is. So there is nothing for _cell_snapshot to see, and the acknowledgement is the honest verdict. What this step still proves is the whole of what it is here for: within the game's own 2.4 m radius the arbiter offers a prompt, interact_with presses it, and outside that radius the same step refuses to press at all.
- actual: pressed `interact` on "[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Strip meadow grass" (provider 'Interactable') and nothing observable changed -- the step declared expect_change:false
- events: t=69.14
- verdict: PASS
- observation: Whether a bare-handed refusal is LEGIBLE to a player -- the press produces no context, focus, satchel, build, party or flag change that this harness can observe -- is a question about the game, and an instrument check must not pretend to answer it. Recorded in ralph/reports/gate-f-rig-log.md as a candidate for a journey segment to look at with a HUD frame.

### SC-R-16 — close the segment
- expected: a note event closes the segment
- actual: SC-R-03 and SC-R-04 are EXPECTED FAILs and are the negative controls for _find_entity and for interact_with's provider check. Every other FAIL here is a real one. INVENTORY.json's `derails` array records any derail even after a resync, so a segment that lost the thread and found it again cannot close looking clean.
- events: t=69.14
- verdict: PASS
