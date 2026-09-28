# P2-081 disabled conversation candidate

The candidate supplies location-specific challenge and defeated text for the
26 existing trainer identities. It remains disabled in
`data/config/stormwood_dialogue_presentation.json`. No encounter, progression,
reward, camera, placement or dialogue-flow changes are included.

Independent read-only reviewer `stormwood_dialogue_review` checked all 26
identities against the catalogue, the two challenge/one defeated line counts,
and the disabled path. The first review found an assumed previous Ivo fight
and unconditional claims about untracked battle sequences. The revision
removed both classes of claim across the candidate. The second review found
no remaining actionable narrative findings or new prerequisite/reward promises.

This is code/content review only. Native dialogue captures, a code-blind visual
verdict, and all-sighting regression checks remain outstanding. P2-081 is open;
neither regional visual acceptance nor a fixed defect is claimed.

Dependency recheck after the NPC portrait acceptance: Tidewake confirms there
is no completed shared archetype portrait set or mapping for these26 trainers.
Its `9bb88eee8` appearance-variant foundation is plumbing only and is not an
ancestor of this lane's current main-integrated source. The current trainer
presentation config has26 entries and zero portrait fields; the runtime uses
a portrait only when supplied and loadable. Thus the text candidate cannot
close the complete text-plus-missing-portrait catalog defect. Audit existing
body-matched plates and trainer framing independently rather than assuming a
finished portrait delivery is imminent. No new dependency acceptance or
trainer presentation enablement is claimed.

The config-only audit in `existing-plate-audit.json` finds exact existing plate
recipes for19 of26 trainers. It compares the actual trainer catalogue through
`trainer_npc.model_config()` against every installed portrait recipe through
`village_npcs.model_config()`, requires `ResourceLoader.exists()`, and retains source
and plate hashes. Seven trainers have no exact match across four profiles:
`grunt_c`, `officer_a`, `officer_b` and `captain_a`. Their world specs use raw
`config_key` profiles; the existing plates add rank palettes/accessories, so
similar file names are not proof of identical dressing. The next candidate
can reuse the19 exact recipes and render four plates from the unchanged world
configs before native panel judgment. This audit does not establish appearance
acceptance and does not modify the trainer candidate.
