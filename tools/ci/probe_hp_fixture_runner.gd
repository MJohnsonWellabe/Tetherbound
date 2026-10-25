extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var test = load("res://tests/test_director_join_snapshot.gd").new()
	for boss in [false, true]:
		await test._case_native_trainer_hp_fixture_survives_projectile_snapshot(boss)
		test._native_cleanup()
		if not test._native_hp_fixture_completed: break
	print("DIRECTOR_HP_FIXTURE_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures,"completed":test._native_hp_fixture_completed and test._native_hp_fixture_observations.size() == 2,"observations":test._native_hp_fixture_observations}))
	quit(0 if test.failures.is_empty() and test._native_hp_fixture_completed and test._native_hp_fixture_observations.size() == 2 else 1)
