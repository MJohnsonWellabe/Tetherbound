# Host-exit ObjectDB leak (F18 net travel host B; split_realms host)

Symptom: `WARNING: N ObjectDB instances were leaked at exit` on a host whose
guest is in another realm (smoke_net_f18_travel host B: 11; smoke_net_split_realms
host: 72-73). With engine `--verbose` every leaked instance is
`RefCounted ... Reference count: 0`.

Pre-existing: origin/main 946bb39e split_realms host leaked 73; tb/f18 with the
portal flag off leaked 73. Not caused by the portal runtime.

## Bisect
- split_realms stopped after join: host 0. After the guest's Cloudreach crossing
  (host stands a Cloudreach shell): host 73. After the host's fight: 73.
- Standalone: host a session (no peers) and call Realms._stand_up("cloudreach"):
  74; without the stand-up: 0. Leak present even when the shell never builds
  (stop 5 frames after the request) and after release_all.
- Pure engine repro (repro_threaded_request_cached_deps.gd.txt): a
  `ResourceLoader.load_threaded_request()` of cloudreach_cliffs.tscn, collected
  with `load_threaded_get()`: 0 leaks in an empty tree, **73** while the Meadows
  world is loaded (its dependencies are already cached). Unloading the scene
  first, use_sub_threads and every cache mode: still 73. Godot 4.7 does not
  release the load tokens of already-cached dependencies of a threaded request.
- Workaround (repro_thread_plain_load.gd.txt): a plain `ResourceLoader.load()`
  on our own worker Thread, same scene, same loaded Meadows world: **0** leaks,
  still off the main thread.

## Fix
scripts/net/realm_shells.gd reads shell scenes with `ResourceLoader.load()` on
a worker Thread; every thread is joined (on completion, on abandon once done,
and at exit). Separately, 5fe6b2ec fixed 5 leaks per Meadows shell from the
stripped SequenceDirector's suspended _ready.
