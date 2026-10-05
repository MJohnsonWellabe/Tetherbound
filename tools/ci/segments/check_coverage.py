#!/usr/bin/env python3
"""Prove a segmented chain still runs every step of its original continuous
scenario exactly once, unchanged.

    python3 tools/ci/segments/check_coverage.py <original.json> <segment.json>...

Each segment step either carries `_comment` "orig #N" -- then, apart from
`peer` (mapped through the segment's `_comment_segment.peer_map`) and
`_comment`, it must equal original step N -- or "SEGMENT: ..." (setup or
checkpoint steps the split adds). The (step, peer) instances the segments
cover, with "all" expanded to every peer, must equal the original's instance
set, each exactly once, and keep their original order within each segment.
"""
import json, sys


def instances(peer, n_peers, peer_map=None):
    peers = list(range(n_peers)) if peer == "all" else (peer if isinstance(peer, list) else [peer])
    return [int(peer_map[str(p)]) if peer_map else int(p) for p in peers]


def strip(step):
    return {k: v for k, v in step.items() if k not in ("peer", "_comment")}


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    orig = json.load(open(argv[1]))
    n_orig_peers = int(orig.get("peers", 2))
    want = {}
    for i, s in enumerate(orig["steps"], 1):
        for p in instances(s.get("peer", 0), n_orig_peers):
            want[(i, p)] = 0
    errors = []
    for path in argv[2:]:
        seg = json.load(open(path))
        meta = seg.get("_comment_segment", {})
        peer_map = meta.get("peer_map")
        if not peer_map:
            errors.append("%s: no _comment_segment.peer_map" % path)
            continue
        last = 0
        for j, s in enumerate(seg["steps"], 1):
            c = str(s.get("_comment", ""))
            if c.startswith("SEGMENT:"):
                continue
            if not c.startswith("orig #"):
                errors.append("%s step %d: neither 'orig #N' nor 'SEGMENT:'" % (path, j))
                continue
            n = int(c[len("orig #"):].split()[0])
            if n < last:
                errors.append("%s step %d: orig #%d out of order (after #%d)" % (path, j, n, last))
            last = n
            if n < 1 or n > len(orig["steps"]):
                errors.append("%s step %d: orig #%d does not exist" % (path, j, n))
                continue
            if strip(s) != strip(orig["steps"][n - 1]):
                errors.append("%s step %d: differs from orig #%d (an assertion changed)" % (path, j, n))
            for p in instances(s.get("peer", 0), int(seg.get("peers", 2)), peer_map):
                if (n, p) not in want:
                    errors.append("%s step %d: orig #%d never ran on original peer %d" % (path, j, n, p))
                else:
                    want[(n, p)] += 1
    for (n, p), count in sorted(want.items()):
        if count != 1:
            errors.append("orig #%d peer %d (%s) runs %d times across the segments, wanted exactly 1"
                          % (n, p, orig["steps"][n - 1].get("label", orig["steps"][n - 1].get("action",
                             orig["steps"][n - 1].get("probe"))), count))
    if errors:
        print("COVERAGE FAIL (%d)" % len(errors))
        for e in errors:
            print("  " + e)
        return 1
    print("COVERAGE OK: %d original (step, peer) instances of %s each run exactly once across %d segments"
          % (len(want), argv[1], len(argv) - 2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
