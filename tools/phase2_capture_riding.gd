extends "res://tools/_capture_riding.gd"

## Uses the existing production RidingController capture, pinned to a
## reproducible random seed. --output remains owned by the parent script.


func _run() -> void:
	var selected_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			selected_seed = int(arg.trim_prefix("--seed="))
	seed(selected_seed)
	await super._run()
