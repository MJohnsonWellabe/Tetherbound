extends RefCounted
## Portable, client-reserve-first debit for paid Water dock actions (F15).
##
## Problem this addresses (only once the wiring below lands; this module is
## deliberately UNWIRED, so the F15 paid-debit gap is still open in the game):
## a paid dock action (reedhaven_repair) saves the WORLD first and only then
## takes items from the in-memory inventory. A crash or disconnect before the
## next character save yields a free repair, a guest whose delta is lost is
## never debited, and a retry is refused already_done.
##
## Model (same shape as satchel_escrow.gd's client reserve): the character
## moves the cost OUT of its inventory into a durable escrow row and SAVES the
## character before the claim is sent. The world then records a durable
## receipt naming the txn and payer. Settling consumes the row. Items come back
## ONLY on an explicit host refusal whose code proves this txn never committed
## (REFUND_CODES), or on a durable receipt proving another txn paid for the
## action. Absence of a receipt is never a refund reason: the txn may be in
## flight, so the answer to absence is to RESUBMIT the same txn (the host
## dedupes by txn id). Every transition happens once. Only "pending" rows are
## ever resubmitted; once a refusal made a row refund_due/refunded its txn is
## dead and must never be sent again.
##
## Pure data: no nodes, RPCs or saves. The caller persists the character after
## any call whose result has `changed == true`.
##
## --- Data shapes ------------------------------------------------------------
## character_state: Dictionary, built FRESH for every call (see P6)
##   {"character_id": String,
##    "escrow": Dictionary,   # txn_id -> row; wiring passes PlayerState.satchel_escrow
##                            # by reference (already persisted by character saves)
##    "inventory": adapter}   # an Object with count(id)->int, add(id,n)->int leftover,
##                            # remove(id,n)->bool all-or-nothing (autoload/inventory.gd),
##                            # or a Dictionary {"count":Callable,"add":Callable,"remove":Callable}
## escrow row (JSON-safe; ints may come back as floats after a JSON load):
##   {"kind":"water_dock_debit", "version":1, "txn_id", "world_instance_id",
##    "action_id", "character_id", "attempt":int, "cost":{item:int},
##    "status":"pending"|"refund_due"|"settled"|"refunded", "reason":String}
##   Terminal rows ("settled"/"refunded") are kept as small tombstones without
##   "cost" so duplicates are no-ops and the next attempt number is derivable.
##   "refund_due" means the refund is authoritative but the bag lacked room; the
##   items are owed in EVERY world, so reconcile() retries them wherever it runs.
##   A refund_due txn is NEVER resubmitted (begin() answers refund_outstanding).
##   A "pending" row for a world that never comes back (deleted, never hosted
##   again) stays escrowed indefinitely: absence is never a refund reason and
##   there is no refund-on-exit, by design (the txn may have committed there).
## intent (what begin() returns for the wire):
##   {"txn_id", "world_instance_id", "action_id", "attempt":int}
##   txn_id == txn_id(world_instance_id, action_id, <host-resolved character>,
##   attempt); the character is never taken from the packet (P3).
## world receipt (the host's durable fact for one action in one world):
##   {"action_id", "world_instance_id", "txn_id", "payer_character_id"}
##   The host writes it in the same durable world save as the action flag and
##   takes payer_character_id from its own actor resolution, never the packet.
##   legacy_receipt() builds the P4 placeholder in exactly this shape.
## world_facts: Dictionary action_id -> receipt, or action_id -> Array of every
##   receipt for that action, from the host's authoritative durable world for
##   world_instance_id (host world, or a guest's installed handshake snapshot).
##   Absence is never treated as a refusal (see above). water_dock_rules.gd
##   lists an action only once its own flag is set, since receipt flags alone
##   are guest-writable; a row settles on the receipt naming its txn and
##   refunds paid_by_other only when none does and no copy is in flight.
## refusal (refund reason): {"txn_id", "world_instance_id", "code",
##   "receipt": optional receipt}. Only codes in REFUND_CODES return items;
##   "already_done" returns items only when it carries a receipt proving
##   another txn paid (one naming this txn settles instead). Every other code
##   (wrong_world, wrong_realm, unknown_character, too_far, unknown_action,
##   malformed, anything new) is ambiguous for a possibly-committed resubmit:
##   no change, and the row stays pending for resubmission.
##
## --- Known requirements for the wiring work order -------------------------
## Necessary, not sufficient: the wiring must be designed against the live
## ledger/session code and reviewed on its own. Refusal codes are final for ONE
## submission, not for a txn; these are the constraints reviews have shown the
## module relies on. A wiring that cannot meet them must not call refund() on
## prerequisite/journal_failed.
##  P1 (client) Only "pending" rows are ever submitted (begin's intent,
##     already_pending, resubmittable_txns(), optionally reconcile's
##     needs_submit); a refund_due/refunded txn is dead and never sent again,
##     and open_txns() is a UI listing only. At most one outstanding copy per
##     txn per connection (sent, no verdict yet): a copy is resubmitted only
##     after the previous copy's verdict arrived or on a new connection, never
##     on a timer. On already_pending the dock prompt offers "resubmit pending"
##     (the stored txn, unchanged) rather than being disabled, so a non-sticky
##     refusal (retry_later/needs_receipt) or a submit dropped with its
##     connection never locks the escrow. Reconnect resubmission of
##     needs_submit is optional. Callers of reconcile() pass every txn with an
##     outstanding copy as in_flight_txn_ids. refund_outstanding: never
##     resubmit; reconcile()/refund() finish the refund. txn_collision: no
##     action (corrupt row).
##  P2 (host) Sticky refusals are remembered HOST-WIDE keyed by txn id (not
##     per connection), outside the journal_failed rollback (which clears
##     _seen_txns): a REFUND_CODES refusal, or already_done carrying a receipt
##     that names another txn. Any later copy of such a txn gets the same
##     refusal. No other verdict is sticky: the txn stays resubmittable.
##  P3 (host) The receipt lookup for intent.txn_id runs before every other
##     check and answers already_done carrying that receipt. Then
##     intent.txn_id must equal txn_id(intent.world_instance_id,
##     intent.action_id, resolved character, intent.attempt) with an integer
##     attempt >= 1, else malformed. The receipt is written in the same durable
##     world save as the action flag, payer from host actor resolution.
##  P4 (host) Whenever the host answers already_done without a stored receipt
##     (a flag that predates receipts, at world load or at refusal time) it
##     uses legacy_receipt(host world_instance_id, action_id), all four fields,
##     so open rows for the action refund (paid_by_other) instead of waiting.
##  P5 (client) Persist before submit: the character save holding the new
##     pending row must SUCCEED before the first submission; on failure do not
##     submit, call rollback_unsent() and persist again when possible.
##  P6 (client) Build character_state fresh from PlayerState on every call;
##     never cache satchel_escrow or the state (load/rollback replace the map).
##  P7 The escrow IS the debit: the host emits no player item_take for paid
##     dock actions, refuses an intent whose world_instance_id is not the host
##     world (wrong_world), and the client's materials proof counts the
##     escrowed cost (the bag no longer holds it).
##  Verdicts delivered to refund() carry txn_id, world_instance_id, code and
##  any receipt. Rows ride in satchel_escrow (scripts/save/character_save.gd:61
##  STATE_KEYS); satchel_escrow.gd reconcile skips non-death-satchel kinds.
## Policies (deliberate):
##  - begin() reserves even when world_facts shows another txn paid the action;
##    the host's already_done-with-receipt refusal then refunds paid_by_other.
##  - A refund_due row finishes its refund even if a receipt naming its own txn
##    appears later: the refusal was authoritative; such a receipt is a host
##    contradiction, not grounds to keep the items.

const KIND := "water_dock_debit"
const VERSION := 1
const TXN_NAMESPACE := "water-dock-debit-v1"
const OPEN := ["pending", "refund_due"]
## P4 placeholder txn/payer; never a sha256 txn id, so it never pays a row.
const LEGACY := "legacy"
## Host refusal codes that prove THIS txn never committed, so its items return.
## Host order (water_dock_rules.gd:24-46, plus the wiring's txn-receipt lookup
## placed first) means each is only reachable when no receipt exists for it:
##   materials    -- :46, after the already_done flag check (:36), so the
##                   action (hence this txn) is not recorded in that world.
##   prerequisite -- :39, also after already_done; same proof.
##   journal_failed -- ledger_rpc.gd:328-345 rolled the whole in-memory commit
##                   back (world, seq, seen txns) after the durable save failed;
##                   the host dedupe check precedes commit, so a duplicate of a
##                   committed txn can never reach this path.
## Excluded on purpose: unknown_action/wrong_realm/unknown_character/too_far
## (:24-34) are emitted BEFORE already_done, and malformed can also come from
## ledger validation ahead of the rules, so each can answer a resubmit of an
## already committed txn.
const REFUND_CODES := ["materials", "prerequisite", "journal_failed"]


## Deterministic txn id. `attempt` starts at 1 and increments after a refund,
## so a retry after a refusal is a fresh transaction the world has never seen.
static func txn_id(world_instance_id: String, action_id: String, character_id: String, attempt: int = 1) -> String:
	if world_instance_id.is_empty() or action_id.is_empty() or character_id.is_empty() or attempt < 1:
		return ""
	return ("%s\n%s\n%s\n%s\n%d" % [TXN_NAMESPACE, world_instance_id, action_id, character_id, attempt]).sha256_text()


## Reserve `cost` into a new escrow row. Returns
## {"ok", "code", "changed", "txn_id",
##  "intent": {txn_id, world_instance_id, action_id, attempt}} (intent on success).
## Refuses with no change when inputs are invalid, items are insufficient, an
## open row for the same action/world/character exists, or it was already paid.
## Refusal codes, in precedence order (independent of escrow iteration order),
## and what the caller may do:
##   already_pending    -- a valid pending row exists; `txn_id` is that row's
##                         txn and is the ONLY txn begin() ever hands back for
##                         resubmission ("resubmit pending", subject to P1).
##   refund_outstanding -- a refused txn still owes items (refund_due). It is
##                         dead: `txn_id` is "" and it must never be resubmitted;
##                         reconcile()/refund() finish returning the items.
##   txn_collision      -- a pending row for this action fails validation, or a
##                         corrupt row occupies the next txn key: no action,
##                         `txn_id` is "".
##   already_paid       -- a settled tombstone blocks (see world_facts below).
##   materials / no_cost / malformed -- nothing reserved.
##
## `world_facts` (optional, same shape as reconcile's) is the authoritative
## durable receipts map for world_instance_id. A "settled" tombstone normally
## blocks (already_paid). When world_facts is a Dictionary with NO entry for
## action_id, the host world has been restored to before that repair, so the
## tombstone for the older attempt does not block and a fresh attempt number
## is reserved. Pass world_facts only when it is authoritative (host world, or
## an installed handshake snapshot); null keeps the conservative block.
static func begin(state: Dictionary, action_id: String, cost: Dictionary, world_instance_id: String,
		world_facts: Variant = null) -> Dictionary:
	var character := str(state.get("character_id", ""))
	var escrow: Variant = state.get("escrow")
	if character.is_empty() or action_id.is_empty() or world_instance_id.is_empty() or not escrow is Dictionary:
		return _result(false, "malformed", false)
	var clean := _clean_cost(cost)
	if clean.is_empty():
		return _result(false, "no_cost", false)
	var restored := world_facts is Dictionary and (world_facts as Dictionary).get(action_id) == null
	var attempt := 1
	var pending := ""
	var refund_due := false
	var corrupt := false
	var paid := ""
	var keys: Array = (escrow as Dictionary).keys()
	keys.sort()
	for key: Variant in keys:
		var raw: Variant = (escrow as Dictionary)[key]
		if not _same_action(raw, world_instance_id, action_id, character):
			continue
		var status := str((raw as Dictionary).get("status", ""))
		if status == "refund_due":
			refund_due = true
		elif status == "pending":
			if _row(state, str(key)).is_empty():
				corrupt = true
			elif pending.is_empty():
				pending = str(key)
		elif status == "settled" and not restored and paid.is_empty():
			paid = str(raw.get("txn_id", ""))
		attempt = maxi(attempt, int(raw.get("attempt", 0)) + 1)
	if not pending.is_empty():
		return _result(false, "already_pending", false, pending)
	if refund_due:
		return _result(false, "refund_outstanding", false)
	if corrupt:
		return _result(false, "txn_collision", false)
	if not paid.is_empty():
		return _result(false, "already_paid", false, paid)
	var txn := txn_id(world_instance_id, action_id, character, attempt)
	if (escrow as Dictionary).has(txn):
		# Not a row of this action (the loop above would have matched it), so
		# it is corrupt: never hand it out as a resubmittable pending txn.
		return _result(false, "txn_collision", false)
	for item: String in clean:
		if _count(state, item) < int(clean[item]):
			return _result(false, "materials", false)
	var taken: Dictionary = {}
	for item: String in clean:
		if not _remove(state, item, int(clean[item])):
			for back: String in taken:
				_add(state, back, int(taken[back]))
			return _result(false, "materials", false)
		taken[item] = int(clean[item])
	(escrow as Dictionary)[txn] = {"kind": KIND, "version": VERSION, "txn_id": txn,
		"world_instance_id": world_instance_id, "action_id": action_id,
		"character_id": character, "attempt": attempt, "cost": clean,
		"status": "pending", "reason": ""}
	var out := _result(true, "", true, txn)
	out["intent"] = {"txn_id": txn, "world_instance_id": world_instance_id,
		"action_id": action_id, "attempt": attempt}
	return out


## P5: the character save holding a fresh reservation FAILED, so the txn was
## never submitted. Return its items and close the row (refunded, reason
## "unsent"). Only valid between begin() and the first submission; calling it
## for a submitted txn could return items for a committed action.
static func rollback_unsent(state: Dictionary, txn: String) -> Dictionary:
	var row := _row(state, txn)
	if row.is_empty():
		return _result(false, "unknown_txn", false)
	if str(row.status) != "pending":
		return _result(false, "not_pending", false, str(row.txn_id))
	return _return_items(state, row, "unsent")


## P4 placeholder receipt for a world whose dock flag predates receipts. Full
## receipt shape, so an open row for the action resolves as paid_by_other.
static func legacy_receipt(world_instance_id: String, action_id: String) -> Dictionary:
	return {"action_id": action_id, "world_instance_id": world_instance_id,
		"txn_id": LEGACY, "payer_character_id": LEGACY}


## The world's receipt names this txn and this character: consume the row.
static func settle(state: Dictionary, receipt: Dictionary) -> Dictionary:
	var row := _row(state, str(receipt.get("txn_id", "")))
	if row.is_empty():
		return _result(false, "unknown_txn", false)
	var txn := str(row.txn_id)
	if str(row.status) == "settled":
		return _result(true, "already_settled", false, txn)
	if str(row.status) != "pending":
		# refund_due / refunded: a refusal was already authoritative for this
		# txn, so a receipt for it would be a host contradiction. No change.
		return _result(false, "not_pending", false, txn)
	if not _receipt_pays(receipt, row):
		return _result(false, "receipt_mismatch", false, txn)
	row.status = "settled"
	row.erase("cost")
	return _result(true, "", true, txn)


## Return escrowed items after an authoritative host refusal (shape above).
## Codes:
##   wrong_world      -- instance mismatch or host said wrong_world: no change.
##   paid_by_this_txn -- the refusal's receipt names this txn: settles instead.
##   needs_receipt    -- already_done without a receipt deciding who paid.
##   retry_later      -- code not in REFUND_CODES (ambiguous): no change; the
##                       row stays pending and the caller resubmits later.
##   ""/no_room       -- items returned (fully / partly, rest refund_due). A
##                       refund_due row only ever finishes its refund here,
##                       whatever the reason carries.
static func refund(state: Dictionary, reason: Dictionary) -> Dictionary:
	var row := _row(state, str(reason.get("txn_id", "")))
	if row.is_empty():
		return _result(false, "unknown_txn", false)
	var txn := str(row.txn_id)
	var instance := str(reason.get("world_instance_id", ""))
	var code := str(reason.get("code", ""))
	if instance.is_empty() or instance != str(row.world_instance_id) or code == "wrong_world":
		return _result(false, "wrong_world", false, txn)
	if str(row.status) == "refunded":
		return _result(true, "already_refunded", false, txn)
	if str(row.status) == "settled":
		return _result(false, "already_settled", false, txn)
	if str(row.status) == "refund_due":
		# Already authoritative (a late receipt cannot flip it, as in
		# reconcile); only finish returning what is still owed.
		return _return_items(state, row, str(row.get("reason", "")))
	var receipt: Variant = reason.get("receipt")
	if receipt is Dictionary and _receipt_pays(receipt, row):
		var paid := settle(state, receipt)
		paid["code"] = "paid_by_this_txn"
		return paid
	if code == "already_done":
		if receipt is Dictionary and _receipt_for(receipt, row):
			return _return_items(state, row, "paid_by_other")
		return _result(false, "needs_receipt", false, txn)
	if not code in REFUND_CODES:
		return _result(false, "retry_later", false, txn)
	return _return_items(state, row, code)


## Reconnect/load path. `world_facts` must be the host's authoritative durable
## receipts for `world_instance_id`: action_id -> one receipt, or an Array of
## EVERY receipt the world holds for that action (a forged extra receipt must
## never hide the genuine one). NEVER refunds on absence of a receipt, and
## never refunds a row listed in `in_flight_txn_ids` (defer to its verdict).
## Returns {"changed", "settled":[txn], "refunded":[txn], "waiting":[txn],
##          "needs_submit":[txn]}:
##   - refund_due rows in ANY world retry returning their owed items (the
##     refund was already authoritative; items are owed regardless of world);
##   - pending rows of this world whose receipt names them settle;
##   - pending rows whose well-formed receipt names another txn/payer refund
##     (the action is durably paid by someone else, so this txn cannot commit),
##     but only when NO receipt names this txn and no copy is in flight;
##   - pending rows with no receipt land in `needs_submit` (resubmit the same
##     txn; the host dedupes by txn id), or in `waiting` if listed in
##     `in_flight_txn_ids` (already sent; await the verdict);
##   - pending rows with a malformed/foreign receipt stay in `waiting`;
##   - pending rows of other worlds are untouched and not reported.
## `needs_submit` only ever holds pending rows. Callers MUST pass every txn with
## an outstanding copy on this connection as `in_flight_txn_ids`; resubmitting
## `needs_submit` is optional and always subject to P1.
static func reconcile(state: Dictionary, world_facts: Dictionary, world_instance_id: String,
		in_flight_txn_ids: Array = []) -> Dictionary:
	var out := {"changed": false, "settled": [], "refunded": [], "waiting": [], "needs_submit": []}
	var escrow: Variant = state.get("escrow")
	if not escrow is Dictionary:
		return out
	var keys: Array = (escrow as Dictionary).keys()
	keys.sort()
	for key: Variant in keys:
		var row := _row(state, str(key))
		if row.is_empty() or not str(row.status) in OPEN:
			continue
		var result: Dictionary = {}
		if str(row.status) == "refund_due":
			result = _return_items(state, row, str(row.get("reason", "")))
		else:
			if world_instance_id.is_empty() or str(row.world_instance_id) != world_instance_id:
				continue
			var fact: Variant = world_facts.get(str(row.action_id))
			if fact == null:
				# Absence: maybe in flight, maybe lost. Never a refund.
				var bucket := "waiting" if in_flight_txn_ids.has(str(key)) else "needs_submit"
				(out[bucket] as Array).append(str(key))
				continue
			var receipts: Array = fact if fact is Array else [fact]
			var paying: Dictionary = {}
			var names_this_txn := false
			var other_paid := false
			for receipt: Variant in receipts:
				if not receipt is Dictionary:
					continue
				if _receipt_pays(receipt, row):
					paying = receipt
				if str((receipt as Dictionary).get("txn_id", "")) == str(row.txn_id):
					names_this_txn = true
				elif _receipt_for(receipt, row):
					other_paid = true
			if not paying.is_empty():
				result = settle(state, paying)
			elif other_paid and not names_this_txn and not in_flight_txn_ids.has(str(key)):
				result = _return_items(state, row, "paid_by_other")
			else:
				# Malformed/contradictory receipts, or a copy of this txn is
				# still in flight: never guess and never refund while a verdict
				# is outstanding. Leave the row open.
				(out.waiting as Array).append(str(key))
				continue
		out.changed = bool(out.changed) or bool(result.get("changed", false))
		match str(row.status):
			"settled": (out.settled as Array).append(str(key))
			"refunded": (out.refunded as Array).append(str(key))
			_: (out.waiting as Array).append(str(key))
	return out


## Open (unresolved: pending or refund_due) txn ids for this character, for UI
## listing ONLY. Never a resubmit source: refund_due txns are dead (P1). Use
## resubmittable_txns() for submission retry.
static func open_txns(state: Dictionary, world_instance_id: String = "") -> Array:
	var out: Array = []
	var escrow: Variant = state.get("escrow")
	if not escrow is Dictionary:
		return out
	for key: Variant in (escrow as Dictionary).keys():
		var row := _row(state, str(key))
		if not row.is_empty() and str(row.status) in OPEN \
				and (world_instance_id.is_empty() or str(row.world_instance_id) == world_instance_id):
			out.append(str(key))
	out.sort()
	return out


## Txn ids that may be resubmitted to `world_instance_id` (P1): its "pending"
## rows only, sorted. Empty for an empty world id. Never refund_due rows.
static func resubmittable_txns(state: Dictionary, world_instance_id: String) -> Array:
	var out: Array = []
	var escrow: Variant = state.get("escrow")
	if world_instance_id.is_empty() or not escrow is Dictionary:
		return out
	for key: Variant in (escrow as Dictionary).keys():
		var row := _row(state, str(key))
		if not row.is_empty() and str(row.status) == "pending" \
				and str(row.world_instance_id) == world_instance_id:
			out.append(str(key))
	out.sort()
	return out


# --- internals -----------------------------------------------------------------

static func _return_items(state: Dictionary, row: Dictionary, reason: String) -> Dictionary:
	var txn := str(row.txn_id)
	var changed := false
	if str(row.status) == "pending":
		row.status = "refund_due"
		row.reason = reason
		changed = true
	var cost: Variant = row.get("cost", {})
	var remaining: Dictionary = cost if cost is Dictionary else {}
	var items: Array = remaining.keys()
	items.sort()
	for item: Variant in items:
		var n := int(remaining[item])
		if n <= 0:
			remaining.erase(item)
			continue
		var left := _add(state, str(item), n)
		if left != n:
			changed = true
		if left <= 0:
			remaining.erase(item)
		else:
			# Journal what is still owed; the rest is already back in the bag.
			remaining[item] = left
	row["cost"] = remaining
	if remaining.is_empty():
		row.status = "refunded"
		row.erase("cost")
		return _result(true, "", true, txn)
	return _result(true, "no_room", changed, txn)


static func _receipt_pays(receipt: Dictionary, row: Dictionary) -> bool:
	return not str(row.get("txn_id", "")).is_empty() \
		and str(receipt.get("txn_id", "")) == str(row.txn_id) \
		and str(receipt.get("action_id", "")) == str(row.action_id) \
		and not str(receipt.get("world_instance_id", "")).is_empty() \
		and str(receipt.get("world_instance_id", "")) == str(row.world_instance_id) \
		and str(receipt.get("payer_character_id", "")) == str(row.character_id)


## A well-formed receipt for this row's action in this row's world that does
## NOT pay this row: durable proof another txn/character paid the action.
## A receipt proving ANOTHER txn paid this action in this world. A receipt
## for this very txn with a different payer is a contradiction (this txn did
## commit), so it is never grounds for a refund: the row keeps waiting.
static func _receipt_for(receipt: Dictionary, row: Dictionary) -> bool:
	return not _receipt_pays(receipt, row) \
		and str(receipt.get("txn_id", "")) != str(row.get("txn_id", "")) \
		and not str(receipt.get("txn_id", "")).is_empty() \
		and not str(receipt.get("payer_character_id", "")).is_empty() \
		and str(receipt.get("action_id", "")) == str(row.action_id) \
		and str(receipt.get("world_instance_id", "")) == str(row.world_instance_id)


## A well-formed row of this kind owned by the state's character, or {}.
static func _row(state: Dictionary, txn: String) -> Dictionary:
	var escrow: Variant = state.get("escrow")
	if txn.is_empty() or not escrow is Dictionary:
		return {}
	var raw: Variant = (escrow as Dictionary).get(txn)
	if not raw is Dictionary:
		return {}
	var row: Dictionary = raw
	var character := str(state.get("character_id", ""))
	if str(row.get("kind", "")) != KIND or character.is_empty() \
			or str(row.get("character_id", "")) != character \
			or str(row.get("txn_id", "")) != txn \
			or txn_id(str(row.get("world_instance_id", "")), str(row.get("action_id", "")),
				character, int(row.get("attempt", 0))) != txn:
		return {}
	return row


static func _same_action(raw: Variant, world_instance_id: String, action_id: String, character: String) -> bool:
	return raw is Dictionary and str(raw.get("kind", "")) == KIND \
		and str(raw.get("world_instance_id", "")) == world_instance_id \
		and str(raw.get("action_id", "")) == action_id \
		and str(raw.get("character_id", "")) == character


static func _clean_cost(cost: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in cost:
		var n: Variant = cost[key]
		if str(key).is_empty() or not (n is int or n is float) or not is_finite(float(n)) \
				or float(n) != floor(float(n)) or float(n) < 0.0:
			return {}
		if int(n) > 0:
			out[str(key)] = int(n)
	return out


static func _count(state: Dictionary, item: String) -> int:
	var inv: Variant = state.get("inventory")
	if inv is Dictionary:
		return int((inv.get("count") as Callable).call(item))
	return int((inv as Object).call("count", item)) if inv is Object else 0


static func _add(state: Dictionary, item: String, n: int) -> int:
	var inv: Variant = state.get("inventory")
	if inv is Dictionary:
		return int((inv.get("add") as Callable).call(item, n))
	return int((inv as Object).call("add", item, n)) if inv is Object else n


static func _remove(state: Dictionary, item: String, n: int) -> bool:
	var inv: Variant = state.get("inventory")
	if inv is Dictionary:
		return bool((inv.get("remove") as Callable).call(item, n))
	return bool((inv as Object).call("remove", item, n)) if inv is Object else false


static func _result(ok: bool, code: String, changed: bool, txn: String = "") -> Dictionary:
	return {"ok": ok, "code": code, "changed": changed, "txn_id": txn}
