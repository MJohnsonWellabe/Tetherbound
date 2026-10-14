"""Root-only sparse transition; wrapper owns the lease. No rollback on failure."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, time
BOOT = time.monotonic()
assert hashlib.sha256((Path(__file__).resolve().parent / 'transition_checks.py').read_bytes()).hexdigest() == 'd5127d0fe97870a489b64560ea309d911616c4e1afef85f69a5a516ce0018a18'
from transition_checks import *
assert hashlib.sha256((Path(__file__).resolve().parent / 'operation_budget.py').read_bytes()).hexdigest() == '3472bf51e7305c077b7f70cd0b157d6d80aac2b49ee590eca54376ceea8507b8'
from operation_budget import OperationBudget, read_bytes, write_bytes, digest_bytes
BUDGET = OperationBudget(started=BOOT)
P = Path(__file__).resolve().parent
PACKET = P.parent
S = Path('C:/CodexTemp/tetherbound-native-service')
B = Path('D:/CodexTemp/tetherbound-native-preserved-sysc836-fromb9-r3')
O = PACKET / 'offline.git'
OLD = 'b9d7edeb7f18d7ca2192f018016d4126f1910f91'
NEW = 'c836df19793e420982bb4aa7b4a0428380126c82'
G = 'C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
ENV = dict(os.environ, GIT_NO_LAZY_FETCH='1', GIT_OPTIONAL_LOCKS='0', GIT_TERMINAL_PROMPT='0')

def check_budget():
    BUDGET.check(cleanup=BUDGET.cleanup_end is not None)

def read_file(path):
    return read_bytes(path, BUDGET, cleanup=BUDGET.cleanup_end is not None)

def write_file(path, data):
    return write_bytes(path, data, BUDGET, cleanup=BUDGET.cleanup_end is not None)

def sha(data):
    return digest_bytes(data, hashlib.sha256(), BUDGET, cleanup=BUDGET.cleanup_end is not None)

def blob_id(data):
    h = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\x00')
    return digest_bytes(data, h, BUDGET, cleanup=BUDGET.cleanup_end is not None)
WATCH = False
REMAINING = {'C': 0, 'D': 0}

def guard():
    check_budget()
    if WATCH:
        assert_resources(resource_snapshot(), REMAINING)

def git(root, *args, data=None, index=None, check=True):
    e = dict(ENV)
    if index:
        e['GIT_INDEX_FILE'] = str(index)
    command = [G, '-C', str(root), '-c', 'gc.auto=0', '-c', 'maintenance.auto=false', '-c', 'core.fsmonitor=false', *args]
    guard()
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=e)
    try:
        supplied = data
        while True:
            guard()
            try:
                out, err = process.communicate(input=supplied, timeout=BUDGET.child_timeout())
                guard()
                break
            except subprocess.TimeoutExpired:
                supplied = None
        if check:
            assert process.returncode == 0, (args, err.decode(errors='replace'))
        return out if check else subprocess.CompletedProcess(command, process.returncode, out, err)
    except BaseException:
        if process.poll() is None:
            process.kill()
        BUDGET.begin_cleanup()
        process.wait(timeout=BUDGET.child_timeout(5, cleanup=True))
        BUDGET.check(cleanup=True)
        raise

def safe(root, rel):
    p = root / rel
    assert not Path(rel).is_absolute() and '..' not in Path(rel).parts
    assert p.resolve().is_relative_to(root.resolve())
    for q in [p, *p.parents]:
        check_budget()
        if q.exists():
            assert not q.is_symlink() and (not getattr(q.lstat(), 'st_file_attributes', 0) & 1024), 'Reparse refused'
    return p

def tree(ref):
    result = {}
    for row in git(O, 'ls-tree', '-rz', ref).split(b'\x00'):
        check_budget()
        if row:
            meta, name = row.split(b'\t')
            mode, typ, oid = meta.split()
            assert typ == b'blob' and mode in (b'100644', b'100755')
            result[name.decode()] = (mode.decode(), oid.decode())
    return result

def index_rows(index=None):
    result = {}
    for row in git(S, 'ls-files', '--stage', '-z', index=index).split(b'\x00'):
        check_budget()
        if row:
            meta, name = row.split(b'\t')
            mode, oid, stage = meta.split()
            assert stage == b'0'
            result[name.decode()] = (mode.decode(), oid.decode())
    return result

def normalized(data, mode):
    assert mode in ('binary', 'utf8_lf')
    return data if mode == 'binary' else data.decode('utf-8-sig').replace('\r\n', '\n').encode('utf-8')

def matches(data, b):
    if b['kind'] == 'gitblob':
        return blob_id(data) == b['blob']
    return sha(normalized(data, b['hash_mode'])) == b['sha256']

def save(name, value):
    write_file(B / name, (json.dumps(value, indent=2) + '\n').encode('utf-8'))

def main():
    global WATCH, REMAINING, BUDGET
    assert sha(read_file(P / 'transition_checks.py')) == 'd5127d0fe97870a489b64560ea309d911616c4e1afef85f69a5a516ce0018a18'
    if sys.argv[1:] != ['--artifact-check']:
        assert len(sys.argv) == 6 and sys.argv[1] == '--root-authorized-under-lock' and (sys.argv[2] == '--work-seconds') and (sys.argv[4] == '--total-seconds')
        BUDGET = OperationBudget(float(sys.argv[3]), float(sys.argv[5]), started=BOOT)
    guard()
    jobpath = PACKET / 'native-supervisor/native-job.json'
    assert sha(read_file(jobpath)) == '98c4b4dd6f95a160fcebbc18af4fe6d074f6b58427c7959c7b17e118d6247dc3'
    job = json.loads(read_file(jobpath))
    assert job['source_commit'] == NEW and job['staging_base'] == OLD and (job['status'] == 'PREPARED') and (job['launch_allowed'] is False)
    pb = job['pack_binding']
    pack = Path(pb['path'])
    payload = read_file(pack)
    assert len(payload) == 2079468 and sha(payload) == '733a3a9c579c4e87983dad84f4edcf49b1b0456c8fc31128d9d005e4720e42d2'
    before, after = (tree(OLD), tree(NEW))
    changed = sorted((p for p in before.keys() | after.keys() if before.get(p) != after.get(p)))
    assert changed == job['changed_source_paths'] and len(changed) == 35
    bindings = job['source_bindings']
    assert len(bindings) == 3521 and len({b['path'] for b in bindings}) == 3521
    changed_blobs = batch_blobs(git, O, [b['blob'] for b in bindings if b['path'] in changed])
    for b in bindings:
        check_budget()
        assert after[b['path']][1] == b['blob']
        assert b['sha256'] or b['kind'] == 'gitblob'
        if b['path'] in changed:
            assert sha(normalized(changed_blobs[b['blob']], b['hash_mode'])) == b['sha256']
    if sys.argv[1] == '--artifact-check':
        print(json.dumps(dict(status='PASS_ARTIFACT_ONLY', changed_paths=len(changed), bindings=len(bindings), stage_access=False)))
        return
    WATCH = True
    assert_resources(resource_snapshot(), admission=True)
    for b in bindings:
        check_budget()
        guard()
        if b['path'] not in changed:
            f = safe(S, b['path'])
            assert f.is_file(), ('Missing retained runtime dependency; no transition', b['path'])
            assert matches(read_file(f), b), ('Retained dependency differs', b['path'])
    assert git(S, 'symbolic-ref', '-q', 'HEAD', check=False).returncode == 1
    assert git(S, 'rev-parse', 'HEAD').decode().strip() == OLD and index_rows() == before
    gd = Path(git(S, 'rev-parse', '--absolute-git-dir').decode().strip())
    assert not (gd / 'index.lock').exists() and (not B.exists())
    existing = {}
    sizes = {}
    fallback = {}
    for rel, (_, oid) in before.items():
        check_budget()
        guard()
        f = safe(S, rel)
        if f.exists():
            assert f.is_file()
            raw = read_file(f)
            if blob_id(raw) != oid:
                candidate = canonical_candidate(rel, raw)
                assert blob_id(candidate) == oid, ('Dirty materialized file', rel)
                fallback[rel] = (oid, sha(raw))
            existing[rel] = sha(raw)
            sizes[rel] = len(raw)
    canonical = batch_blobs(git, S, [v[0] for v in fallback.values()])
    for rel, (oid, digest) in fallback.items():
        check_budget()
        guard()
        raw = read_file(safe(S, rel))
        assert sha(raw) == digest
        assert_canonical(rel, raw, canonical[oid], oid)
    materialize = sorted(existing.keys() & after.keys() | {b['path'] for b in bindings} | set(changed) & after.keys())
    affected = sorted(set(changed) & existing.keys() | set(materialize) - existing.keys())
    for rel in set(materialize) - existing.keys():
        check_budget()
        assert not safe(S, rel).exists(), ('Untracked collision', rel)
    original_index = read_file(gd / 'index')
    original_head = read_file(gd / 'HEAD')
    metadata = {name: read_file(gd / name) for name in ('info/sparse-checkout', 'config', 'config.worktree') if (gd / name).exists()}
    writes = batch_blobs(git, O, [after[r][1] for r in affected if r in after])
    inventory = json.loads(read_file(PACKET / 'transport-inventory.json'))
    budget = peak_budget([sizes[r] for r in affected if r in sizes], [len(writes[after[r][1]]) for r in affected if r in after], len(original_index), len(original_head), sum(map(len, metadata.values())), max(len(before), len(after)), max(sum((len(r.encode()) for r in before)), sum((len(r.encode()) for r in after))), len(payload), len(inventory['required_objects']))
    REMAINING = {k: budget[k] for k in ('C', 'D')}
    assert_resources(resource_snapshot(), REMAINING, admission=True)
    safe(B.parent, B.name)
    B.mkdir()
    save('resource-budget.json', dict(peak=budget, initial=resource_snapshot(), status='ADMITTED_BEFORE_FIRST_BACKUP'))
    save('preflight-preservation.json', dict(original_materialized=existing, original_index_sha256=sha(original_index), original_head_sha256=sha(original_head), affected=affected, originally_absent=[r for r in affected if r not in existing], target_materialized=materialize))
    write_file(B / 'index', original_index)
    write_file(B / 'HEAD', original_head)
    REMAINING['D'] -= len(original_index) + len(original_head)
    guard()
    for name in ('info/sparse-checkout', 'config', 'config.worktree'):
        check_budget()
        f = gd / name
        if f.exists():
            guard()
            dst = B / 'git-metadata' / name
            dst.parent.mkdir(parents=True, exist_ok=True)
            write_file(dst, metadata[name])
            assert read_file(dst) == metadata[name]
            REMAINING['D'] -= len(metadata[name])
            guard()
    for rel in affected:
        check_budget()
        guard()
        if rel in existing:
            dst = safe(B / 'files', rel)
            dst.parent.mkdir(parents=True, exist_ok=True)
            write_file(dst, read_file(safe(S, rel)))
            assert sha(read_file(dst)) == existing[rel]
            REMAINING['D'] -= sizes[rel]
            guard()
    state = dict(status='PRESERVED_BEFORE_IMPORT', old=OLD, target=NEW, git_dir=str(gd), original_index_sha256=sha(original_index), original_head_sha256=sha(original_head), original_materialized=existing, materialize=materialize, affected=affected, originally_absent=[r for r in affected if r not in existing], completed_writes=[])
    save('transition-state.json', state)
    try:
        assert read_file(gd / 'HEAD') == original_head and read_file(gd / 'index') == original_index
        for rel, digest in existing.items():
            check_budget()
            assert sha(read_file(safe(S, rel))) == digest
        git(S, 'index-pack', '--stdin', data=payload)
        REMAINING['C'] -= budget['components']['pack_import']
        guard()
        state['status'] = 'PACK_IMPORTED'
        save('transition-state.json', state)
        newindex = B / 'target-index'
        git(S, 'read-tree', NEW, index=newindex)
        git(S, 'update-index', '--skip-worktree', '-z', '--stdin', data=b''.join((p.encode() + b'\x00' for p in sorted(after))), index=newindex)
        git(S, 'update-index', '--no-skip-worktree', '-z', '--stdin', data=b''.join((p.encode() + b'\x00' for p in materialize)), index=newindex)
        assert index_rows(newindex) == after
        assert newindex.stat().st_size <= budget['components']['target_index_bound']
        REMAINING['D'] -= 2 * budget['components']['target_index_bound']
        guard()
        for rel in affected:
            check_budget()
            guard()
            f = safe(S, rel)
            if rel in after:
                raw = writes[after[rel][1]]
                f.parent.mkdir(parents=True, exist_ok=True)
                write_file(f, raw)
                assert read_file(f) == raw
                REMAINING['C'] -= len(raw)
                guard()
            elif f.exists():
                f.unlink()
            state['completed_writes'].append(rel)
            state['status'] = 'WRITING_SOURCE'
            save('transition-state.json', state)
        assert read_file(gd / 'HEAD') == original_head and read_file(gd / 'index') == original_index
        lock = gd / 'index.lock'
        write_bytes(lock, read_file(newindex), BUDGET, exclusive=True)
        guard()
        os.replace(lock, gd / 'index')
        assert index_rows() == after
        REMAINING['C'] -= budget['components']['target_index_bound']
        guard()
        state['status'] = 'INDEX_UPDATED'
        save('transition-state.json', state)
        git(S, 'update-ref', '--no-deref', 'HEAD', NEW, OLD)
        for b in bindings:
            check_budget()
            assert matches(read_file(safe(S, b['path'])), b)
        assert git(S, 'rev-parse', 'HEAD').decode().strip() == NEW and index_rows() == after
        for rel in materialize:
            check_budget()
            guard()
            raw = read_file(safe(S, rel))
            if rel in affected:
                assert blob_id(raw) == after[rel][1], ('Written file changed', rel)
            else:
                assert sha(raw) == existing[rel], ('Retained raw bytes changed', rel)
        for rel in affected:
            check_budget()
            if rel not in after:
                assert not safe(S, rel).exists(), ('Deleted path reappeared', rel)
        assert index_rows() == after and git(S, 'rev-parse', 'HEAD').decode().strip() == NEW
        save('resource-terminal.json', dict(remaining=REMAINING, observed=resource_snapshot()))
        state.update(status='SOURCE_PREPARED_NOT_ADMITTED', bindings_verified=3521, full_target_index_verified=True)
        save('transition-state.json', state)
        guard()
        print(json.dumps(dict(status=state['status'], preservation=str(B), time_budget=BUDGET.snapshot())))
    except BaseException as e:
        BUDGET.begin_cleanup()
        state.update(status='FAILED_PRESERVE_INTERMEDIATE_STATE', error=str(e), time_budget=BUDGET.snapshot())
        save('transition-state.json', state)
        raise
if __name__ == '__main__':
    try:
        main()
    except BaseException as error:
        BUDGET.begin_cleanup()
        if sys.argv[1:2] == ['--root-authorized-under-lock'] and B.exists():
            save('failure.json', dict(status='FAILED_PRESERVE_INTERMEDIATE_STATE', error=str(error), remaining=REMAINING, time_budget=BUDGET.snapshot()))
        raise
