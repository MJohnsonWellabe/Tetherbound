C2 / F25#4 readiness audit: PARTIAL; acceptance NOT MET.

Independent read-only reviewer /root/stormursa_reference_review. Reviewed main e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3.

data/config/vfx.json:145 defines ordinary48, ultimate160 and encounter384 decorative slots;12 bodies/effect and4 scene lights. Nineteen attack archetypes request24 impact+18trail slots; five support archetypes12+10. scripts/vfx/move_effect.gd:71 applies admission, move_effect_budget.gd:8 removes trails before impacts. Mesh bodies are separate.

Source-based rank5 body-count stress candidates: ember_burst/ember_bite12 bodies; root_stone_spikes/bramble_trap10; bubble_volley/tail_splash8; ice_shard_volley/ultimate_ice_current8. stone_throw also8. All request42 slots. These are candidates, not measured heaviest effects; geometry, overlap, shaders and lightning rebuilding differ.

Existing tests/smoke_move_effects_library.gd opts in only in process memory. --batch=profile --medium profiles24 archetypes with4 simultaneous rank5 effects and raw wall intervals/P95/P99; no frame-rate threshold is enforced by exit0. --batch=mastery --stage=arena --ranks=5 supplies Compatibility fallback PNGs. Its header explicitly excludes actual four-creature combat. Existing named/F38 fight tools do not combine this opt-in, sustained wall timings and documented four-actor load; shipped move_library remainsfalse.

Missing prerequisite: existing real four-creature fight fixture with local opt-in, live wall-frame arrays and documented stress composition. Source declarations or synthetic effects cannot certify that fight. No engine, source edits, new tests/harness, fallback judge, actual cost ranking or persistent enablement occurred. Criterion remains OPEN.
