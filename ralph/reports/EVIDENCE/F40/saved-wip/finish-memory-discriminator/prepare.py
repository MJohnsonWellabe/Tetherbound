from pathlib import Path
import hashlib, json, subprocess, sys

repo=Path('D:/tetherbound/codex-look-cloudreach')
out=Path(__file__).resolve().parent
path=repo/'scripts/world/cloudreach_look.gd'
original=path.read_text(encoding='utf-8')
assert '_profile_cover_memory' not in original
assert subprocess.check_output(['git.exe','--no-optional-locks','-c','gc.auto=0','-c','maintenance.auto=false','rev-parse','HEAD'],cwd=repo,text=True).strip()=='52b433c97bc9855f664c1915b1659ece594a9776'
changes=[]
text=original
def insert(anchor, addition, before=False):
    global text
    assert text.count(anchor)==1, (anchor,text.count(anchor))
    replacement=addition+anchor if before else anchor+addition
    changes.append((anchor,replacement))
    text=text.replace(anchor,replacement,1)

insert('var _cover_fill_area := 0.0\n', '''
# Existing opt-in load profiler only. No durable state or GPU/readback query.
var _cover_memory_profile := false
var _cover_memory_started := 0
var _cover_memory_last_progress := 0
var _cover_memory_progress_lines := 0
var _cover_memory_sequence := 0
''')
insert('func dress(world: Node3D) -> void:\n', '''## Engine allocator snapshots at synchronous stage boundaries, not settled
## GPU measurements or exact peaks. Progress has a separate 64-line/10s cap so
## long loops cannot consume the finite boundary markers. No arrays are copied.
func _profile_cover_memory(phase: String, progress: int = -1, total: int = -1,
        packed_floats: int = -1, periodic: bool = false) -> void:
	if not _cover_memory_profile:
		return
	var now := Time.get_ticks_msec()
	if periodic:
		if _cover_memory_progress_lines >= 64 or now - _cover_memory_last_progress < 10000:
			return
		_cover_memory_last_progress = now
		_cover_memory_progress_lines += 1
	# Sample before constructing the small JSON record; serialization still has
	# observer cost. External supervisor samples own process/physical memory.
	var static_bytes := OS.get_static_memory_usage()
	var static_peak_bytes := OS.get_static_memory_peak_usage()
	print("CLOUDREACH_COVER_MEMORY " + JSON.stringify({
		"sequence": _cover_memory_sequence, "phase": phase,
		"elapsed_ms": now - _cover_memory_started, "ticks_ms": now,
		"static_bytes": static_bytes, "static_peak_bytes": static_peak_bytes,
		"progress": progress, "total": total,
		"packed_payload_bytes": packed_floats * 4 if packed_floats >= 0 else -1,
		"main_count": _cover_main_count, "far_count": _cover_far_count,
		"fill_count": _cover_fill_count, "alpine_count": _cover_alpine_count}))
	_cover_memory_sequence += 1


''',True)
insert('\tvar profile_look := OS.get_cmdline_user_args().has("--profile-realm-load")\n','''	_cover_memory_profile = profile_look
	_cover_memory_started = Time.get_ticks_msec()
	_cover_memory_last_progress = _cover_memory_started
	_cover_memory_progress_lines = 0
	_cover_memory_sequence = 0
	_profile_cover_memory("look_begin")
''')
insert('\tif profile_look: print("[cloudreach_look] rails ms=", Time.get_ticks_msec() - phase_started)\n','\t_profile_cover_memory("rails_done")\n')
insert('\tif profile_look: print("[cloudreach_look] moorings ms=", Time.get_ticks_msec() - phase_started)\n','\t_profile_cover_memory("cover_begin")\n')
insert('\tif profile_look: print("[cloudreach_look] cover ms=", Time.get_ticks_msec() - phase_started)\n','\t_profile_cover_memory("cover_returned")\n')
insert('\t\t_cover_counts_by_index.append(placed_main + placed_far)\n','''		if _cover_memory_profile and patch_index % 32 == 0:
			_profile_cover_memory("ellipse_progress", patch_index + 1, ellipse_patches.size(), -1, true)
''')
insert('\t_dress_turf_fill(root, ellipse_patches, cfg, budget, tuft_mesh,\n','\t_profile_cover_memory("ellipse_done", ellipse_patches.size(), ellipse_patches.size())\n',True)
insert('\t_dress_alpine_rim(ellipse_patches, cfg, budget)\n','\t_profile_cover_memory("alpine_returned")\n')
insert('\t_dress_alpine_rim(ellipse_patches, cfg, budget)\n','\t_profile_cover_memory("fill_returned")\n\t_profile_cover_memory("alpine_begin")\n',True)
insert('\tvar surfaces := _collect_turf_triangles()\n','\t_profile_cover_memory("fill_collect_begin")\n',True)
insert('\tvar surfaces := _collect_turf_triangles()\n','\t_profile_cover_memory("fill_collect_done", surfaces.size())\n')
insert('\tprobe_casts = cells.size()\n','\t_profile_cover_memory("fill_cells_ready", cells.size(), surfaces.size())\n')
insert('\tvar far_dry_transforms := PackedFloat32Array()\n','\tvar profile_cell_index := 0\n')
insert('\tfor raw: Variant in cells:\n','''		if _cover_memory_profile:
			profile_cell_index += 1
			if profile_cell_index % 1024 == 0:
				_profile_cover_memory("fill_generate_progress", profile_cell_index, cells.size(),
					near_transforms.size() + dry_transforms.size() + far_transforms.size()
					+ far_dry_transforms.size(), true)
''')
insert('\t_cover_fill_grid = {"turf_triangles": cells.size(), "surfaces": _cover_fill_surfaces,\n','''	_profile_cover_memory("fill_buffers_ready", cells.size(), surfaces.size(),
		near_transforms.size() + dry_transforms.size() + far_transforms.size() + far_dry_transforms.size())
''',True)
for name in ('near','dry','far','far_dry'):
    insert(f'\t{name}_transforms.clear()\n',f'\t_profile_cover_memory("fill_{name}_released", cells.size(), surfaces.size(),\n\t\tnear_transforms.size() + dry_transforms.size() + far_transforms.size() + far_dry_transforms.size())\n')
insert('\t\t\t\ti += 3\n','''				if _cover_memory_profile and i % 12288 == 0:
					_profile_cover_memory("fill_collect_progress", out.size(), _cover_fill_surfaces, -1, true)
''')
insert('\t\t_cover_alpine_count += placed\n','''		if _cover_memory_profile:
			_profile_cover_memory("alpine_generate_progress", patch_index + 1, qualifying.size(), -1, true)
''')
insert('\tfor kind_name: String in kind_names:\n\t\tvar transforms: Array = buckets[kind_name]\n','\t_profile_cover_memory("alpine_buckets_ready", _cover_alpine_count, kind_names.size())\n',True)
insert('\t\tinstances.name = "AlpineMix%s" % kind_name\n','\t\t_profile_cover_memory("alpine_bucket_uploaded", transforms.size(), _cover_alpine_count)\n',True)

reversed_text=text
for anchor,replacement in reversed(changes):
    assert reversed_text.count(replacement)==1
    reversed_text=reversed_text.replace(replacement,anchor,1)
assert reversed_text==original
# Preserve exact original bytes and insertion recipe for independent source review.
(out/'cloudreach_look.before.gd').write_bytes(path.read_bytes())
(out/'insertions.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
path.write_text(text,encoding='utf-8',newline='\n')
sys.path.insert(0,str(repo/'.artifacts/source-check-deps'))
from gdtoolkit.parser import parser
parser.parse(text)
report={'status':'SOURCE_PARSE_AND_EXACT_INSERTION_REVERSAL_PASS_NATIVE_UNRUN','parent':'52b433c97bc9855f664c1915b1659ece594a9776','file':'scripts/world/cloudreach_look.gd','before_sha256':hashlib.sha256(original.encode()).hexdigest(),'after_sha256':hashlib.sha256(text.encode()).hexdigest(),'insertions':len(changes),'exact_reversal':True,'native_launches':0,'existing_gate':'--profile-realm-load','periodic_max_lines':64,'periodic_min_ms':10000,'native_stage_accessed':False,'actual_owner_accessed':False}
(out/'source-checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
