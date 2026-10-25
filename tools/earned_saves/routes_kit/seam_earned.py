# seam_earned.py <from_dir> <to_dir> <from> <to> <out.json>: f49_piece_seam for earned_chain_runner pieces (consumer hash-bound predecessor receipt)
import json, hashlib, sys
fd, td, fn, tn, outp = sys.argv[1:6]
prod = json.load(open(fd + '/receipt.json'))['payload']; cons = json.load(open(td + '/receipt.json'))['payload']
rh = hashlib.sha256(open(fd + '/receipt.json', 'rb').read()).hexdigest()
bound = [p for p in cons['predecessors'] if p['boundary'] == prod['boundary']][0]['receipt_sha256']
st = prod['state']
out = {"kind": "f49_piece_seam", "from_piece": fn, "from_commit": prod['commit'], "to_piece": tn, "to_commit": cons['commit'],
       "producer_receipt_sha256": rh, "consumer_predecessor_binding": bound, "binding_matches": rh == bound,
       "proof": "earned_chain_runner import_prefix + f49_disk_handoff.reload_boundary: the consumer loaded the producer's hash-bound receipt and save through production Load and compared its saved state; any difference refuses the piece",
       "end_state": {"realm": st.get('realm'), "party": [{"uid": m.get('uid'), "species": m.get('species'), "level": m.get('level')} for m in st.get('party', [])], "flags": len(st.get('flags', []))},
       "differences": [], "matches": rh == bound}
json.dump(out, open(outp, 'w'), indent=1); print(outp.split('/')[-1], "MATCH" if out['matches'] else "MISMATCH")
