"""Select raw executions, never count a published phase parent a second time.

This is an analytics reader, not an acceptance verifier. Published completion
still comes exclusively from aggregate_segment_phases.py. Local clocks remain
local; no continuous cross-process timeline is fabricated.
"""
import json
from pathlib import Path

CHAIN = ["S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08", "S09",
         "S10a", "S10b", "S10c", "S10d", "S10e"]


def document(path):
    path = Path(path)
    if not path.exists():
        return {}
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected object: {path}")
    return value


def safe_id(value):
    if not isinstance(value, str) or not value or value in (".", "..") or any(c in value for c in "/\\:"):
        raise ValueError(f"unsafe evidence id: {value!r}")
    return value


def executions(run_dir):
    root = Path(run_dir)
    inventories = {p.parent.name: document(p) for p in root.glob("*/INVENTORY.json")}
    groups = {}
    for name, inv in inventories.items():
        phase = inv.get("phase") or {}
        if phase:
            parent = safe_id(phase["parent"])
            order = [safe_id(x) for x in phase["order"]]
            if name not in order or len(set(x.casefold() for x in order)) != len(order):
                raise ValueError(f"invalid phase order in {name}")
            if parent in groups and groups[parent] != order:
                raise ValueError(f"inconsistent phase order for {parent}")
            groups[parent] = order
    # A running phase may have metadata and telemetry before its final inventory.
    running = {}
    for path in root.glob("*/RUN_METADATA.json"):
        meta = document(path)
        parent = meta.get("phase_parent")
        if parent and path.parent.name not in inventories:
            running.setdefault(safe_id(parent), []).append(safe_id(path.parent.name))
    for parent, names in running.items():
        if parent not in groups:
            groups[parent] = sorted(names)
        elif any(name not in groups[parent] for name in names):
            raise ValueError(f"running phase not in declared order for {parent}")
    for parent in CHAIN:
        inv = inventories.get(parent, {})
        published = inv.get("execution") == "save_linked_phases"
        if published:
            order = [safe_id(x) for x in inv["aggregate"]["order"]]
            if not order or len(set(x.casefold() for x in order)) != len(order) or parent in order:
                raise ValueError(f"invalid aggregate order for {parent}")
            if parent in groups and groups[parent] != order:
                raise ValueError(f"aggregate/raw phase order mismatch for {parent}")
            groups[parent] = order
        elif parent in groups and inv:
            raise ValueError(f"ambiguous unsplit and phased evidence for {parent}")
        for name in groups.get(parent, [parent]):
            current = inventories.get(name, {})
            phase = current.get("phase") or {}
            if name != parent and current and phase.get("parent") != parent:
                raise ValueError(f"foreign phase inventory: {name}")
            yield {"id": name, "parent": parent, "phase": phase,
                   "is_phase": name != parent, "aggregate_published": published,
                   "inventory": current}


SEMANTICS = ("Save-linked phases are separate raw executions; published aggregate parents "
             "are omitted to avoid double counting. Phase clocks restart at load. Raw elapsed "
             "time includes added save/load seams; route rows exclude those wrappers. No "
             "continuous timeline or cadence across boundaries is inferred. Missing telemetry "
             "is not evidence of zero activity. Analytics do not certify acceptance.")
