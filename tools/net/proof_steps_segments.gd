extends RefCounted

## Proof steps for CI SEGMENTS (tests/helpers/ci_segments.gd holds the
## boundaries and their one start contract). Dispatched by
## `tools/net/proof_peer_runner.gd` for actions starting `seg_`:
##
##   seg_verify      {boundary, role}       the committed checkpoint is fresh (current
##                                          VERSION, production loader accepts it, manifest
##                                          digest and producer fingerprint match) and its
##                                          loaded state meets the boundary's start contract
##   seg_seed_home   {boundary, role}       seg_verify, then copy that checkpoint into this
##                                          peer's own user:// exactly as a player's disk
##                                          holds it (no load, no boot): the next production
##                                          step (title Continue / production_join) reads it
##   seg_contract    {boundary, role}       the LIVE Game meets the boundary's contract
##                                          (a host after `load_save`)
##   seg_checkpoint  {boundary, role, label} END of a producer segment: what `capture_saves
##                                          {label}` just wrote through the production save
##                                          meets the contract, and its state digest equals
##                                          the committed checkpoint's (else STALE, with the
##                                          command that regenerates it). With
##                                          TB_SEGMENT_REGEN=1 the digest is recorded instead
##                                          (tools/ci/segments/regen.sh installs it).

const SEGMENTS := preload("res://tests/helpers/ci_segments.gd")
const PROOF_STEPS := preload("res://tools/net/proof_steps.gd")
const WORK_DIR := "user://ci_segment_scratch/"


static func handles(action: String) -> bool:
	return action in ["seg_verify", "seg_seed_home", "seg_contract", "seg_checkpoint"]


static func run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	var boundary := str(args.get("boundary", ""))
	var role := str(args.get("role", ""))
	if SEGMENTS.role_spec(boundary, role).is_empty():
		return {"verdict": "ERROR", "detail": "unknown segment boundary '%s' role '%s'" % [boundary, role]}
	match action:
		"seg_verify":
			return _verify(boundary, role)
		"seg_seed_home":
			var verified := _verify(boundary, role)
			if verified.verdict != "PASS":
				return verified
			var copied := 0
			var user := OS.get_user_data_dir()
			for sub: String in PROOF_STEPS.SAVE_DIRS:
				copied += PROOF_STEPS._copy_tree(ProjectSettings.globalize_path(
					SEGMENTS.checkpoint_dir(boundary, role)).path_join(sub), user.path_join(sub), true)
			if copied == 0:
				return {"verdict": "FAIL", "detail": "nothing copied from %s" % SEGMENTS.checkpoint_dir(boundary, role)}
			verified.detail = "%s; copied %d checkpoint files into this home" % [verified.detail, copied]
			return verified
		"seg_contract":
			var game := tree.root.get_node_or_null(^"Game")
			if game == null:
				return {"verdict": "ERROR", "detail": "no /root/Game"}
			var failures := SEGMENTS.evaluate(boundary, role, game)
			return {"verdict": "PASS" if failures.is_empty() else "FAIL",
				"detail": "live state meets %s:%s start contract" % [boundary, role] if failures.is_empty()
					else "live state misses %s:%s contract: %s" % [boundary, role, "; ".join(failures)],
				"data": {"failures": failures, "party": SEGMENTS.party_species(game)}}
		"seg_checkpoint":
			return _checkpoint(tree, boundary, role, str(args.get("label", "checkpoint")))
	return {"verdict": "ERROR", "detail": "proof_steps_segments: unknown action '%s'" % action}


static func _verify(boundary: String, role: String) -> Dictionary:
	return SEGMENTS.check_start(boundary, role, WORK_DIR)


static func _checkpoint(tree: SceneTree, boundary: String, role: String, label: String) -> Dictionary:
	return SEGMENTS.check_produced(boundary, role, PROOF_STEPS.out_dir(tree).path_join(label), WORK_DIR)
