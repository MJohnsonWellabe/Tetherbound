extends "res://tests/test_case.gd"

const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")


func test_enabled_portraits_cover_named_and_side_conversations_without_changing_story() -> void:
	var conversations: Dictionary = _read("res://data/dialogue/stormwood.json").conversations
	conversations[CHAPTER.WEN_REFUSAL_CONVERSATION] = CHAPTER.wen_refusal_conversation()
	conversations.merge(CHAPTER.GLASS_FOR_BRYN.conversations())
	var original := conversations.duplicate(true)
	var actors: Array = _read("res://data/config/stormwood_npcs.json").characters
	var settings: Dictionary = _read("res://data/config/stormwood_dialogue_presentation.json").npc_portraits
	settings.enabled = true
	CHAPTER.apply_npc_portraits(conversations,actors,settings)
	var expected := {"Rook":"juno","Lio":"fenn","Elder Maud":"old_perrin",
		"Keeper Ondra":"ada","Rodkeeper Hesk":"old_perrin","Oswin":"corin",
		"Warden-Elect Bryn":"old_perrin","Archivist Wen":"maren","Tamsin":"bryn",
		"Fenn":"corin","Neri":"fenn"}
	var seen := {}
	for id: String in conversations:
		var changed: Dictionary = conversations[id].duplicate(true)
		var before: Dictionary = original[id].duplicate(true)
		var speaker := str(changed.get("speaker",""))
		if expected.has(speaker):
			assert_eq(changed.portrait,"res://assets/ui/portraits/%s.png"%expected[speaker],id)
			seen[speaker] = true
		else:
			assert_eq(changed.get("portrait"),before.get("portrait"),"unmapped speaker: "+id)
		changed.erase("portrait")
		before.erase("portrait")
		assert_eq(changed,before,"text, choices, requirements, events and all other metadata: "+id)
	for speaker: String in expected:
		assert_true(seen.has(speaker),"exercise actual registered speaker "+speaker)
	assert_eq(conversations[CHAPTER.WEN_REFUSAL_CONVERSATION].portrait,
		"res://assets/ui/portraits/maren.png","synthetic refusal matches Wen's world body too")
	var bryn_synthetic := CHAPTER.GLASS_FOR_BRYN.conversations()
	assert_eq(bryn_synthetic.size(),4,"cover the four later activity registrations")
	for id: String in bryn_synthetic:
		assert_eq(conversations[id].portrait,"res://assets/ui/portraits/old_perrin.png",id)


func test_disabled_or_missing_plate_preserves_original_conversation() -> void:
	var conversations := {"sample":{"speaker":"Wen","portrait":"original.png","lines":["unchanged"]}}
	var original := conversations.duplicate(true)
	var actors := [{"name":"Wen","body_profile":"field_researcher"}]
	CHAPTER.apply_npc_portraits(conversations,actors,{"enabled":false,
		"plates_by_profile":{"field_researcher":"res://assets/ui/portraits/maren.png"}})
	assert_eq(conversations,original,"disabled gate leaves the complete conversation unchanged")
	CHAPTER.apply_npc_portraits(conversations,actors,{"enabled":true,
		"plates_by_profile":{"field_researcher":"res://missing-portrait.png"}})
	assert_eq(conversations,original,"invalid candidate cannot blank an existing plate")


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
