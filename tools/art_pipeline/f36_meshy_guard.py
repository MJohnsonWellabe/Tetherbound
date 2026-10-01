"""Attended F36 entry point over the installed Meshy client, with a 30-task cap.

Call with --night YYYY-MM-DD --subject ID --reference PATH --inspected-sha256
HASH -- followed by the existing meshy.py arguments. Inspection is a human or
agent visual step; a hash is only its receipt. Never purchases credits. Every
POST is reserved BEFORE submission, including retries/refine/retexture. An
uncertain network result retains its slot; reconcile its task id before retry.
F36 is the sole generation owner; retain this ledger through consolidation.
"""
import argparse
from datetime import date, datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sys
import uuid

import meshy

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / 'ralph/reports/R2-F36/meshy-night-ledger.json'
CAP = 30


def write_atomic(path, payload):
    temp = path.with_suffix('.tmp')
    with temp.open('w', encoding='utf-8') as handle:
        json.dump(payload, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temp, path)


def submit_guarded(request, night, subject, reference, reference_hash, method, path, body=None):
    if method.upper() != 'POST':
        return request(method, path, body)
    # Exclusive CREATE prevents concurrent owners from racing count/receipt.
    lock = LEDGER.with_suffix('.lock')
    lock.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    try:
        ledger = json.loads(LEDGER.read_text()) if LEDGER.exists() else {'cap_per_night': CAP, 'tasks': []}
        count = sum(row['night'] == night for row in ledger['tasks'])
        if count >= CAP:
            raise RuntimeError(f'F36 nightly cap reached ({count}/{CAP}); no task submitted')
        row = {'reservation_id': str(uuid.uuid4()), 'night': night, 'subject': subject,
               'reference': reference, 'reference_sha256': reference_hash, 'endpoint': path,
               'submitted_utc': datetime.now(timezone.utc).isoformat(), 'task_id': None,
               'status': 'submission_uncertain_counts_against_cap'}
        ledger['tasks'].append(row)
        write_atomic(LEDGER, ledger)
        response = request(method, path, body)
        task_id = response.get('result') or response.get('id')
        if not isinstance(task_id, str) or not task_id:
            raise RuntimeError('Meshy returned no task id; reserved slot retained for reconciliation')
        row.update(task_id=task_id, status='submitted_pending_inspection')
        ledger['actual_meshy_submissions'] = sum(isinstance(task.get('task_id'), str) for task in ledger['tasks'])
        write_atomic(LEDGER, ledger)
        print(f'F36 ledger: {count + 1}/{CAP}, task {task_id}')
        return response
    finally:
        os.close(fd)
        lock.unlink()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--night', required=True, help='America/Chicago night start date, explicit across midnight')
    parser.add_argument('--subject', required=True)
    parser.add_argument('--reference', required=True, type=Path)
    parser.add_argument('--inspected-sha256', required=True)
    parser.add_argument('meshy_args', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    date.fromisoformat(args.night)
    manifest = json.loads((ROOT / 'ralph/reports/R2-F36/priority-source-audit.json').read_text())
    if args.subject not in [row['id'] for row in manifest['subjects']]:
        parser.error('subject is outside the bounded F36 roster')
    reference = args.reference.resolve(strict=True)
    if not reference.is_relative_to(ROOT):
        parser.error('save the inspected reference in the F36 checkout first')
    actual_hash = hashlib.sha256(reference.read_bytes()).hexdigest()
    if actual_hash != args.inspected_sha256:
        parser.error('reference differs from the visually inspected receipt')
    if not os.environ.get('MESHY_API_KEY'):
        parser.error('installed Meshy client has no MESHY_API_KEY; no task submitted')
    original_request = meshy.request
    meshy.request = lambda method, path, body=None: submit_guarded(original_request, args.night, args.subject,
        reference.relative_to(ROOT).as_posix(), actual_hash, method, path, body)
    sys.argv = ['meshy.py'] + [arg for arg in args.meshy_args if arg != '--']
    meshy.main()


if __name__ == '__main__':
    main()
