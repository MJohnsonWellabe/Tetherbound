"""Validate independent F40 scores against actual frames in a P2-021 audit."""
import argparse
import csv
import hashlib
import json
import re
from pathlib import Path

HEX64 = re.compile(r'^[0-9a-f]{64}$')
VARIANTS = ('baseline', 'p2_021_candidate')
PRESETS = ('High', 'Medium')


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def validate_reference(ref, audit_frames):
    if not isinstance(ref, dict):
        raise ValueError('evidence must be a structured reference to an audited frame')
    variant, preset, frame_id = ref.get('variant'), ref.get('preset'), ref.get('frame_id')
    key = f'{variant}/{preset}'
    record = audit_frames.get(key, {}).get(frame_id) if isinstance(frame_id, str) else None
    if not isinstance(record, dict) or ref.get('png_sha256') != record.get('png_sha256'):
        raise ValueError('reference does not name an audited frame and matching PNG hash')
    if not isinstance(ref.get('note'), str) or not ref['note'].strip():
        raise ValueError('frame reference needs an observation note')
    actual_path = Path(record.get('image', ''))
    if not actual_path.is_file() or sha256(actual_path) != record['png_sha256']:
        raise ValueError('referenced frame is missing or changed on disk')
    return {**ref, 'image': record['image']}


def validate_review_evidence(refs, audit_frames):
    if not isinstance(refs, list) or not refs:
        raise ValueError('evidence must be a nonempty list of validated frame references')
    normalized, seen_refs, seen_groups = [], set(), set()
    for ref in refs:
        normalized_ref = validate_reference(ref, audit_frames)
        key = f'{ref.get("variant")}/{ref.get("preset")}'
        identity = (key, ref.get('frame_id'))
        if identity in seen_refs:
            raise ValueError(f'duplicate frame reference {identity}')
        seen_refs.add(identity)
        seen_groups.add(key)
        normalized.append(normalized_ref)
    required_groups = {f'{variant}/{preset}' for variant in VARIANTS for preset in PRESETS}
    if seen_groups != required_groups:
        raise ValueError('evidence must cite baseline and candidate High and Medium frames')
    return normalized


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--reviews', type=Path, required=True)
    parser.add_argument('--pair-audit', type=Path, required=True,
                        help='JSON emitted by validate_cloudreach_p2_021_pair.py')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    evidence_dir = root / 'ralph/reports/R2-F40'
    if not args.output.resolve().is_relative_to(evidence_dir) or args.output.exists():
        parser.error('output must be a fresh file in this checkout ralph/reports/R2-F40')
    try:
        audit = json.loads(args.pair_audit.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as exc:
        parser.error(f'cannot read pair audit: {exc}')
    if (not isinstance(audit, dict) or audit.get('schema') != 'cloudreach-p2-021-four-leg-audit-v1'
            or audit.get('complete') is not True or not re.fullmatch(r'[0-9a-f]{40}', str(audit.get('source_commit', '')))):
        parser.error('pair audit is not a complete validated four-leg audit')
    validator_path = root / 'tools/validate_cloudreach_p2_021_pair.py'
    if audit.get('validator_sha256') != sha256(validator_path):
        parser.error('pair audit was produced by a different validator revision')
    audit_frames = {}
    for variant in VARIANTS:
        for preset in PRESETS:
            key = f'{variant}/{preset}'
            leg = audit.get('legs', {}).get(key)
            if not isinstance(leg, dict) or not isinstance(leg.get('frames'), dict) or len(leg['frames']) != 384:
                parser.error(f'pair audit lacks exactly 384 actual frame references for {key}')
            if not HEX64.fullmatch(str(leg.get('manifest_sha256', ''))):
                parser.error(f'pair audit manifest hash is missing for {key}')
            audit_frames[key] = leg['frames']
    with args.catalog.open(encoding='utf-8-sig', newline='') as stream:
        original = list(csv.DictReader(stream))
    selected = [row for row in original if 'cloudreach' in row['biome(s)'].split(';')]
    reviews = json.loads(args.reviews.read_text(encoding='utf-8'))
    if not isinstance(reviews, list) or any(not isinstance(row, dict) for row in reviews):
        parser.error('reviews must be a JSON list of review objects')
    by_id = {row.get('item_id'): row for row in reviews}
    if len(by_id) != len(reviews) or set(by_id) != {row['item_id'] for row in selected}:
        parser.error('review must score every Cloudreach catalog row exactly once')
    result = []
    for old in selected:
        review = by_id[old['item_id']]
        scores = [review.get(key) for key in ('severity', 'exposure', 'importance')]
        if any(type(score) is not int or not 1 <= score <= 5 for score in scores):
            parser.error('scores must be independently supplied integers 1..5')
        if review.get('verdict') not in ('PASS', 'POLISH', 'FAIL') or not review.get('reviewer'):
            parser.error('each review requires a PASS/POLISH/FAIL verdict and reviewer')
        try:
            normalized = validate_review_evidence(review.get('evidence'), audit_frames)
        except ValueError as exc:
            parser.error(f'{old["item_id"]}: {exc}')
        result.append({**old, 'prior_impact': old['impact'],
                       **{key: review[key] for key in ('severity', 'exposure', 'importance')},
                       'impact': scores[0] * scores[1] * scores[2],
                       'review_verdict': review['verdict'], 'reviewer': review['reviewer'],
                       'review_evidence': json.dumps(normalized, separators=(',', ':')),
                       'evidence_source_commit': audit['source_commit'],
                       'pair_audit_sha256': sha256(args.pair_audit)})
    result.sort(key=lambda row: (-row['impact'], row['item_id']))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(result[0]))
        writer.writeheader()
        writer.writerows(result)
    print(f'{len(result)} independent scores tied to validated frame hashes; no acceptance status changed')


if __name__ == '__main__':
    main()
