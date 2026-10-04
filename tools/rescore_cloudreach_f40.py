"""Validate independent F40 scores; write evidence only, never the live board.

Inputs: --catalog <original csv> --reviews <JSON list> --output <fresh csv>
Each review needs item_id, severity/exposure/importance (1..5), verdict,
reviewer, evidence. Missing reviews fail; no source-derived visual PASS.
"""
import argparse
import csv
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--reviews', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    evidence = root / 'ralph/reports/R2-F40'
    if not args.output.resolve().is_relative_to(evidence) or args.output.exists():
        parser.error('output must be a fresh file in this checkout ralph/reports/R2-F40')
    with args.catalog.open(encoding='utf-8-sig', newline='') as stream:
        original = list(csv.DictReader(stream))
    selected = [row for row in original if 'cloudreach' in row['biome(s)'].split(';')]
    reviews = json.loads(args.reviews.read_text(encoding='utf-8'))
    by_id = {row['item_id']: row for row in reviews}
    if len(by_id) != len(reviews) or set(by_id) != {row['item_id'] for row in selected}:
        parser.error('review must score every Cloudreach catalog row exactly once')
    result = []
    for old in selected:
        review = by_id[old['item_id']]
        scores = [review.get(key) for key in ('severity', 'exposure', 'importance')]
        if any(type(score) is not int or not 1 <= score <= 5 for score in scores):
            parser.error('scores must be independently supplied integers 1..5')
        if review.get('verdict') not in ('PASS', 'POLISH', 'FAIL') or not review.get('reviewer') or not review.get('evidence'):
            parser.error('each review requires verdict, reviewer and native evidence link')
        result.append({**old, 'prior_impact': old['impact'],
                       **{key: review[key] for key in ('severity', 'exposure', 'importance')},
                       'impact': scores[0] * scores[1] * scores[2],
                       'review_verdict': review['verdict'], 'reviewer': review['reviewer'],
                       'review_evidence': review['evidence']})
    result.sort(key=lambda row: (-row['impact'], row['item_id']))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(result[0]))
        writer.writeheader()
        writer.writerows(result)
    print(f'{len(result)} independently supplied scores validated; no acceptance status changed')


if __name__ == '__main__':
    main()
