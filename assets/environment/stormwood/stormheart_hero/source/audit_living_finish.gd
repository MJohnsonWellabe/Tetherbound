extends SceneTree
func _initialize() -> void:
    call_deferred("_audit")
func _audit() -> void:
    var scene := (load("res://assets/environment/stormwood/stormheart_hero/stormheart_hero.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await process_frame
    var crowns := scene.get_node("LivingCanopy")
    var report := {"crown_clusters": crowns.get_child_count(), "clusters": [], "minimum_low_canopy_xz_aabb_distance": INF, "finite_unit_transformed_normals": true, "leaf_triangles": 0}
    for raw in crowns.get_children():
        var child := raw as MeshInstance3D
        var box := child.transform * child.get_aabb()
        var nearest := Vector2(clampf(0.0, box.position.x, box.end.x), clampf(0.0, box.position.z, box.end.z)).length()
        if box.position.y <= 174.0:
            report.minimum_low_canopy_xz_aabb_distance = minf(report.minimum_low_canopy_xz_aabb_distance, nearest)
            assert(nearest > 44.0)
        assert(box.end.y <= 300.01)
        report.clusters.append({"name":child.name,"min":[box.position.x,box.position.y,box.position.z],"max":[box.end.x,box.end.y,box.end.z]})
        for s in child.mesh.get_surface_count():
            var arrays := child.mesh.surface_get_arrays(s)
            report.leaf_triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
            for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
                var normal := (child.basis.inverse().transposed() * n).normalized()
                if not normal.is_finite() or absf(normal.length() - 1.0) > 0.001:
                    report.finite_unit_transformed_normals = false
    assert(report.finite_unit_transformed_normals)
    var file := FileAccess.open("res://assets/environment/stormwood/stormheart_hero/source/living_finish_audit.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  ")+"\n")
    print(JSON.stringify(report))
    quit()
