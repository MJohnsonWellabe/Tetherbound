extends "res://tests/test_case.gd"

## The world scene and network smoke own the physical ceremony. These focused
## contracts make the chapter order, per-participant offers and authored seams fail
## loudly in the fast suite before a long Stormwood run is attempted. The
## Stormheart follows the owner's per-participant legendary rule.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


func test_every_participant_gets_their_own_once_only_offer() -> void:
	var fought := ["trainer-a", "trainer-b"]
	assert_false(ENDING.claim_allowed([], fought, "trainer-a", false),
		"Marrow's captive cannot be claimed before the Dynamo releases it")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-a", false),
		"a participant may answer the freed Stormheart")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG, ENDING.OFFER_FLAG], fought, "trainer-b", false),
		"a second participant keeps their own offer after the first has settled")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-c", false),
		"a character who did not fight for the release receives nothing")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-a", true),
		"a character who already answered cannot be offered again")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], [], "solo", false),
		"a solo freeing records no other participant; the only player may answer")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "", false))


func test_claims_are_kept_per_character_and_legacy_saves_migrate() -> void:
	var state := {"participants": ["trainer-a", "trainer-b"], "claims": {
		"trainer-a": {"creature": {"species_id": "fulgocobra"}, "settled": true, "kept": true},
		"trainer-b": {"creature": {"species_id": "fulgocobra"}, "settled": false, "kept": false}}}
	assert_true(ENDING.claim_for_character(state, "trainer-a").is_empty(), "A settled claim is not resent")
	assert_false(ENDING.claim_for_character(state, "trainer-b").is_empty(), "Each character's own claim waits")
	assert_true(ENDING.claim_for_character(state, "trainer-c").is_empty())
	var legacy := {"recipient_character_id": "trainer-a", "creature": {"species_id": "fulgocobra"},
		"settled": false, "kept": false}
	var migrated := ENDING.migrate_state(legacy)
	assert_false(migrated.has("recipient_character_id"))
	assert_eq(migrated.participants, ["trainer-a"],
		"Only the legacy recipient is known to have fought; no one else may claim a fresh Stormheart")
	assert_eq((migrated.claims as Dictionary).keys(), ["trainer-a"])
	assert_false(ENDING.claim_for_character(migrated, "trainer-a").is_empty(),
		"An interrupted single-recipient ceremony resumes for its character")
	assert_eq(ENDING.migrate_state(migrated), migrated, "Migration is idempotent")


func test_waterward_waits_for_the_roster_decision_and_is_once_only() -> void:
	assert_false(ENDING.waterward_allowed([ENDING.FREED_FLAG]),
		"freeing the Stormheart does not skip its roster decision")
	assert_true(ENDING.waterward_allowed([ENDING.OFFER_FLAG]),
		"resolving the Stormheart offer unlocks the high-platform view")
	assert_false(ENDING.waterward_allowed([ENDING.OFFER_FLAG, ENDING.WATERWARD_FLAG]),
		"the durable Waterward reveal cannot be farmed")


func test_production_wires_the_existing_five_slot_and_story_transports() -> void:
	var ending := FileAccess.get_file_as_string("res://scripts/world/stormwood_ending.gd")
	var hub := FileAccess.get_file_as_string("res://scripts/world/stormwood_encounter_hub.gd")
	var world := FileAccess.get_file_as_string("res://scripts/world/stormwood_world.gd")
	assert_true(ending.contains('game.set("pending_catch", _local_creature)'),
		"a full belt must enter the one shipped five-slot ceremony")
	assert_true(ending.contains('"kind": "ending_settled"'),
		"the party owner must acknowledge its personal decision to the host")
	assert_true(ending.contains('call("set_flag", PERSONAL_RECEIPT_FLAG)'),
		"an interrupted character must resume after its saved ceremony decision")
	assert_true(ending.contains('_chapter.call("emit_event", "dynamo:release")'),
		"release must grant chapter flags through the host-led ledger adapter")
	assert_true(ending.contains('_chapter.call("emit_event", "aftermath:waterward_view")'),
		"the Water key and route reveal must come from the authored objective event")
	assert_false(ending.contains('"ending_commit_offer"') or ending.contains('"ending_commit_waterward"'),
		"the host shell must commit ending flags itself, not delegate authority to a client")
	assert_true(hub.contains('kind.begins_with("ending_")'),
		"ending intents must use Stormwood's reliable host channel")
	assert_true(world.contains('ending.mount(self)'),
		"the production Stormwood scene must mount the ending controller")


func test_chapter_data_orders_release_offer_and_waterward_before_home_placement() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json"))
	assert_true(parsed is Dictionary, "Stormwood chapter JSON must parse")
	if not parsed is Dictionary:
		return
	var objectives: Array = []
	for act: Dictionary in (parsed as Dictionary).get("acts", []):
		objectives.append_array(act.get("objectives", []))
	var by_id: Dictionary = {}
	for objective: Dictionary in objectives:
		by_id[str(objective.get("id", ""))] = objective
	assert_eq(str(by_id["stormwood_legendary_freed"].completion_event), "dynamo:release")
	assert_true((by_id["stormwood_legendary_freed"].grants_flags as Array).has(
		"realm_heart_stormwood_earned"), "release awards the Spark")
	assert_false(by_id.has("stormwood_spark_placed"),
		"Spark placement belongs to the Meadows home circle, not the remote chapter")
	assert_true((by_id["stormwood_waterward_revealed"].requires_flags as Array).has(
		"stormwood:legendary_offer_made"), "Waterward follows the roster decision")
	for flag: String in ["realm_key_water", "waterward_route_revealed", "stormwood:chapter_complete"]:
		assert_true((by_id["stormwood_waterward_revealed"].grants_flags as Array).has(flag),
			"Waterward reveal must grant %s" % flag)


func test_livewire_is_the_single_active_cooldown_power() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/realm_hearts.json"))
	assert_true(parsed is Dictionary, "realm heart config must parse")
	if not parsed is Dictionary:
		return
	var heart: Dictionary = (parsed as Dictionary).hearts.stormwood
	assert_eq(str(heart.display_name), "Spark of the Stormwood")
	assert_eq(str(heart.power.display_name), "Livewire")
	assert_almost_eq(float(heart.power.cooldown_multiplier), 0.75, 0.0001,
		"Livewire shortens move cooldowns by exactly twenty-five percent")
	var shrine := FileAccess.get_file_as_string("res://scripts/world/realm_heart_shrine.gd")
	assert_true(shrine.contains("Only one relic power can be active."),
		"the physical shrine must explain the single-active replacement rule")


func test_ceremony_receipt_is_player_owned_despite_the_stormwood_world_prefix() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/progression/flag_scopes.json"))
	assert_true((parsed.player.ids as Array).has(ENDING.PERSONAL_RECEIPT_FLAG),
		"the party owner's decision must persist in that character, not the shared world")


func test_offer_asks_an_explicit_yes_or_no_and_receipts_each_answer() -> void:
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	var lines: Array = dialogue[ENDING.OFFER_CONVERSATION].lines
	var last: Variant = lines.back()
	assert_true(last is Dictionary and str((last as Dictionary).get("confirm_effect", "")) != "",
		"the offer ends on a Yes/No consent line, so accepting with room is a choice, not a silent grant")
	assert_eq(ENDING.resolution_flag(true, "trainer-a"), "stormwood:legendary_resolution:accepted:trainer-a")
	assert_eq(ENDING.resolution_flag(false, "trainer-a"), "stormwood:legendary_resolution:refused:trainer-a")
	assert_eq(PROGRESSION_STATE.scope_of(ENDING.resolution_flag(false, "trainer-a")), "world",
		"the per-character answer receipt is a world fact every peer sees")


func test_a_legacy_freeing_without_recorded_fighters_never_offers_whoever_claims_first() -> void:
	var freed := [ENDING.FREED_FLAG]
	var legacy := {}
	# (a) The Dynamo's persisted fighter characters are the fallback; its
	# contributor peer ids (an old session's) are never mapped, and the
	# claimant's own id never is.
	var dynamo := {"fighter_characters": ["trainer-a", "trainer-b"], "contributors": [1, 7, 9]}
	var fallback := ENDING.fallback_participants(dynamo, "host")
	assert_eq(fallback, ["trainer-a", "trainer-b"],
		"the Dynamo's fighter characters are the participants; old-session peer ids add nobody")
	assert_eq(ENDING.participants_for_claim(legacy, fallback), fallback)
	assert_true(ENDING.offer_owed(legacy, "trainer-a", freed, false, fallback),
		"a recorded Dynamo fighter is still owed their Stormheart on a legacy save")
	assert_false(ENDING.offer_owed(legacy, "host", freed, false, fallback),
		"the host is not added when the Dynamo recorded its fighters")
	assert_false(ENDING.offer_owed(legacy, "guest", freed, false, fallback),
		"a guest the Dynamo never recorded receives nothing, even claiming first")
	assert_eq(ENDING.fallback_participants({"contributors": [1]}, "host"), ["host"],
		"contributors alone are not read: the host is the best available guess")
	# (b) With no Dynamo record at all, only the world owner's character.
	var host_only := ENDING.fallback_participants({}, "host")
	assert_eq(host_only, ["host"], "with no Dynamo record the host's own character is the one participant")
	assert_false(ENDING.offer_owed(legacy, "guest", freed, false, host_only),
		"a guest claiming first on a legacy save gets no creature")
	assert_true(ENDING.offer_owed(legacy, "host", freed, false, host_only),
		"the host who freed it keeps its offer after a guest claimed first")
	assert_false(ENDING.offer_owed(legacy, "guest", freed),
		"with no recorded list and no fallback nobody is owed, rather than whoever arrives")
	var claimed := {"claims": {"host": {"creature": {"species_id": "fulgocobra"},
		"settled": false, "kept": false}}}
	assert_false(ENDING.offer_owed(claimed, "trainer-b", freed, false, host_only),
		"a later character on a legacy save receives no creature: nothing proves they fought")
	assert_true(ENDING.offer_owed(claimed, "host", freed, false, host_only),
		"the host's own unsettled claim still resumes")
	var recorded_empty := {"participants": []}
	assert_true(ENDING.offer_owed(recorded_empty, "solo", freed, false, ["solo"]),
		"a solo freeing that recorded nobody still offers its only player, the host")
	recorded_empty["claims"] = {"solo": {"creature": {}, "settled": true, "kept": true}}
	assert_false(ENDING.offer_owed(recorded_empty, "joiner", freed, false, ["solo"]),
		"a character joining a solo freeing after its claim receives nothing")
	assert_false(ENDING.offer_owed({"participants": ["trainer-a"]}, "trainer-b", freed, false, ["trainer-b"]),
		"a recorded participant list is used as is; the fallback never widens it")


func test_only_a_portable_acceptance_withholds_an_offer_in_another_world() -> void:
	var state := {"participants": ["trainer-a"]}
	var freed := [ENDING.FREED_FLAG]
	var flags := PROGRESSION_STATE.new()
	ENDING.record_answer(flags, "creature-world-a", false)
	assert_true(flags.has(ENDING.PERSONAL_RECEIPT_FLAG) and flags.has(ENDING.answer_flag("creature-world-a", false)),
		"a refusal records the receipt and its answer scoped to that world's claim")
	var intent := ENDING.claim_intent(flags)
	assert_false(bool(intent.get("already_accepted", true)),
		"a refusal in world A (a scoped refusal, no acceptance) sends no withholding hint")
	assert_false(intent.has("already_resolved"), "the old answered-anywhere hint is gone")
	assert_true(ENDING.offer_owed(state, "trainer-a", freed, bool(intent.already_accepted)),
		"refused in world A, fought in world B: world B offers its Stormheart")
	flags.set_flag(ENDING.ACCEPTED_FLAG)
	intent = ENDING.claim_intent(flags)
	assert_true(bool(intent.get("already_accepted", false)), "an acceptance anywhere is sent as the hint")
	assert_false(ENDING.offer_owed(state, "trainer-a", freed, bool(intent.already_accepted)),
		"accepted in world A: no second creature in world B")
	assert_true(ENDING.claim_intent(null).get("already_accepted") == false)


func test_a_bare_legacy_receipt_is_an_acceptance_and_is_never_cleared() -> void:
	var state := {"participants": ["trainer-a"]}
	var freed := [ENDING.FREED_FLAG]
	var legacy := PROGRESSION_STATE.new()
	legacy.set_flag(ENDING.PERSONAL_RECEIPT_FLAG)
	assert_true(ENDING.accepted_anywhere(legacy),
		"an older build's receipt never said Yes or No, so it reads as an acceptance")
	assert_false(ENDING.offer_owed(state, "trainer-a", freed, bool(ENDING.claim_intent(legacy).already_accepted)),
		"a legacy receipt withholds a fresh Stormheart: no offer is ever granted twice")
	# That character later answers a claim some world already held for it (a
	# resume) with No. The legacy Yes must survive the first scoped answer.
	ENDING.record_answer(legacy, "creature-held", false)
	assert_true(legacy.has(ENDING.ACCEPTED_FLAG) and legacy.has(ENDING.PERSONAL_RECEIPT_FLAG),
		"the legacy receipt becomes an explicit acceptance before any scoped answer, and stays")
	assert_true(ENDING.accepted_anywhere(legacy), "a later refusal never turns a legacy Yes into No")


func test_a_saved_answer_resumes_only_the_claim_it_answered() -> void:
	var flags := PROGRESSION_STATE.new()
	var world_a := {"creature": {"uid": "creature-a"}}
	var world_b := {"creature": {"uid": "creature-b"}}
	assert_eq(ENDING.claim_id(world_a), "creature-a", "a claim is identified by its reserved Stormheart")
	ENDING.record_answer(flags, ENDING.claim_id(world_a), false)
	assert_eq(ENDING.recorded_answer(flags, ENDING.claim_id(world_a)), "refused",
		"world A's own unacknowledged refusal resumes world A")
	assert_eq(ENDING.recorded_answer(flags, ENDING.claim_id(world_b)), "",
		"world A's refusal is never read as an answer to world B's claim")
	ENDING.record_answer(flags, ENDING.claim_id(world_b), true)
	assert_eq(ENDING.recorded_answer(flags, "creature-b"), "accepted")
	assert_eq(ENDING.recorded_answer(flags, ""), "", "a claim without an id has no saved answer")


func test_the_scoped_answer_prefix_is_player_owned() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/progression/flag_scopes.json"))
	assert_true((parsed.player.prefixes as Array).has(ENDING.ANSWER_PREFIX),
		"each answer travels with the character, so its prefix must be declared a player prefix")
	assert_eq(PROGRESSION_STATE.scope_of(ENDING.answer_flag("creature-x", false)), "player")


func test_an_unknown_participant_list_is_never_published_as_a_solo_freeing() -> void:
	assert_eq(ENDING.published_participants([]), [ENDING.NO_KNOWN_PARTICIPANT])
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], ENDING.published_participants([]), "anyone", false),
		"a client told nobody is known does not offer the Stormheart to everyone")
	assert_eq(ENDING.published_participants(["host"]), ["host"])


func test_the_portable_acceptance_is_player_owned_despite_the_stormwood_world_prefix() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/progression/flag_scopes.json"))
	assert_true((parsed.player.ids as Array).has(ENDING.ACCEPTED_FLAG),
		"the acceptance travels with the character, so it must be declared a player flag")
	assert_eq(PROGRESSION_STATE.scope_of(ENDING.ACCEPTED_FLAG), "player")


func test_the_host_decides_an_offer_from_its_own_receipts_not_the_clients_flag() -> void:
	var state := {"participants": ["trainer-a", "trainer-b"]}
	var freed := [ENDING.FREED_FLAG]
	for accepted: bool in [true, false]:
		var flags := freed + [ENDING.resolution_flag(accepted, "trainer-b")]
		assert_false(ENDING.offer_owed(state, "trainer-b", flags, false),
			"a world receipt for B's answer refuses a second offer even when B's client says it never answered")
	assert_true(ENDING.offer_owed(state, "trainer-a", freed + [ENDING.resolution_flag(false, "trainer-b")], false),
		"B's receipt is B's alone; A is still owed their own offer")
	var settled := {"participants": ["trainer-a"], "claims": {"trainer-a": {"creature": {}, "settled": true, "kept": false}}}
	assert_false(ENDING.offer_owed(settled, "trainer-a", freed, false),
		"a settled claim the host holds refuses whatever the client reports")
	assert_false(ENDING.offer_owed(state, "trainer-a", freed, true),
		"the client's own receipt can withhold its fresh creature")
	var pending := {"participants": ["trainer-a"], "claims": {"trainer-a": {"creature": {}, "settled": false, "kept": false}}}
	assert_true(ENDING.offer_owed(pending, "trainer-a", freed, true),
		"the hint never cancels a claim the host already holds; the client resumes and settles it")
	assert_false(ENDING.offer_owed(state, "trainer-c", freed, false),
		"a non-participant is refused whatever it reports")


func test_the_offer_accept_effect_is_consumed_by_the_ending() -> void:
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	var last: Dictionary = (dialogue[ENDING.OFFER_CONVERSATION].lines as Array).back()
	assert_eq(str(last.get("confirm_effect", "")), ENDING.OFFER_ACCEPT_EFFECT,
		"the consent line's effect is the one the ending drains and reads as Yes")
	var ending := FileAccess.get_file_as_string("res://scripts/world/stormwood_ending.gd")
	assert_true(ending.contains('panel.call("drain_effects")'),
		"the ending drains the panel on completion, so the Yes effect is never queued forever")
	assert_true(ending.contains("panel.declined.connect(_dialogue_declined)"),
		"only the panel's explicit decline signal records a refusal")
	assert_false(ending.contains("Input.is_action_just_pressed"),
		"the ending no longer reads raw input to decide a refusal")
	var panel := FileAccess.get_file_as_string("res://scripts/ui/dialogue_panel.gd")
	assert_true(panel.contains('Input.is_action_just_pressed("menu_cancel")'),
		"the dialogue panel still declines a consent line on menu_cancel")
	assert_true(panel.contains('_runner.call("confirm", false)') and panel.contains("declined.emit("),
		"the panel's menu_cancel decline reaches its forwarded declined signal")


func test_a_missing_local_record_reads_as_no_character_instead_of_crashing() -> void:
	assert_eq(ENDING._local_character_id(null), "", "no Game yet reads as no character")
	var bare := Node.new()
	assert_eq(ENDING._local_character_id(bare), "", "a Game whose local record is not set yet reads as no character")
	bare.free()
