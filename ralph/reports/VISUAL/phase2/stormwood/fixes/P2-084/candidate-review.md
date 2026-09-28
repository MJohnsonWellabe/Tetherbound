# P2-084 NPC opening candidate

The original four arrival-panel sightings show Fenn and Oswin sharing a gathering
opening, and Maud and Bryn sharing a Rodfolk-road opening. The source confirms
those duplicated openings. Their existing in-progress and aftermath panels also
reuse generic opening text, except for Bryn's distinct progression briefing.

The disabled `npc_openings` candidate in `stormwood_dialogue_presentation.json`
gives these four existing speakers eleven distinct opening lines across the
three states. Bryn's in-progress conversation is omitted. The chapter loader
replaces only line zero of known, nonempty conversations; conversation IDs,
speakers, portraits, subsequent guidance, state requirements and completion
events remain authored. This nested flag is independent of the existing disabled
trainer-presentation flag.

The content uses their existing roles and places: Bryn's responsibility for the
roads, Oswin's supplies near Rodline Post, Maud's familiarity with the forest,
and Fenn's preparation advice at Lantern Hollow. It adds no quest, reward,
service, route or progression state. Existing generic follow-up guidance is
retained; this is a candidate for the repeated-opening defect, not a rewrite of
the chapter or a claim that all dialogue now has sufficient identity.

Independent reviewer `stormwood_dialogue_review` confirmed the eleven source IDs,
separate disabled gates, preserved metadata/guidance and untouched Bryn briefing.
Fenn's aftermath wording was corrected from an unconditional claim that thunder
is gone to the existing Long Storm completion, avoiding a stronger weather claim.

Godot 4.7 parsed the changed chapter script. The existing NPC dialogue and NPC
data suites passed 5 tests / 430 assertions. Those checks cover the source
conversation/state/flag and cast placement contracts, not execution of the
enabled overlay or panel appearance. Native arrival comparisons for all four
catalog sightings, plus in-progress/aftermath panels for the additional lines,
remain required. P2-084 stays open and the candidate stays off.

The shared `phase2_capture_stormwood_people.gd` matrix includes all eleven
changed openings plus Bryn's unchanged in-progress briefing as a control.
It also compares the installed portrait candidate. Its direct-start panels
isolate chapter progression/arrival callbacks and record unchanged flag
snapshots; they cannot establish earned progression or ordinary interaction.
