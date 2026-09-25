extends RefCounted
## Portable, client-reserve-first debit for paid Water dock actions (F15).
##
## Problem this closes: a paid dock action (reedhaven_repair) saves the WORLD
## first and only then takes items from the in-memory inventory. A crash or
## disconnect before the next character save yields a free repair, a guest
## whose delta is lost is never debited, and a retry is refused already_done.
##
## Model (same shape as satchel_escrow.gd's client reserve): the character
## moves the cost OUT of its inventory into a durable escrow row and SAVES the
## character before the claim is sent. The world then records a durable
## receipt naming the txn and payer. Settling consumes the row. Items come back
## ONLY on an explicit host refusal whose code proves this txn never committed
## (REFUND_CODES), or on a durable receipt proving another txn paid for the
## action. Absence of a receipt is never a refund reason: the txn may be in
## flight, so the answer to absence is to RESUBMIT the same txn (the host
## dedupes by txn id). Every transition happens once.
##
## Pure data: no nodes, RPCs or saves. The caller persists the character after
## any call whose result has `changed == true`.
##
## --- Data shapes ------------------------------------------------------------
## character_state: Dictionary
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
## world receipt (the host's durable fact for one action in one world):
##   {"action_id", "world_instance_id", "txn_id", "payer_character_id"}
##   The host writes it in the same durable world save as the action flag and
##   takes payer_character_id from its own actor resolution, never the packet.
## world_facts: Dictionary action_id -> receipt, from the host's authoritative
##   durable world for world_instance_id (host world, or a guest's installed
##   handshake snapshot). Absence is never treated as a refusal (see above).
## refusal (refund reason): {"txn_id", "world_instance_id", "code",
##   "receipt": optional receipt}. Only codes in REFUND_CODES return items;
##   "already_done" returns items only when it carries a receipt proving
##   another txn paid (one naming this txn settles instead). Every other code
##   (wrong_world, wrong_realm, unknown_character, too_far, unknown_action,
##   malformed, anything new) is ambiguous for a possibly-committed resubmit:
##   no change, and the row stays pending for resubmission.
##
## --- Wiring plan (later work order; needs a coordinator grant) -------------
## 1. scripts/world/water_dock_actions.gd:96-106 `_activate`: for an action with
##    a non-empty cost, call begin() with PlayerState (satchel_escrow as escrow,
##    inventory as adapter), SATCHEL_ESCROW.world_instance(world) and the
##    world's receipts map as world_facts; persist the character (as
##    ledger_rpc.gd:101 `_persist_satchel_character`) BEFORE submitting; add
##    `txn_id` and `world_instance_id` to the intent at :103. The inventory
##    proof sent at :100-102 must read the escrowed cost. An already_pending
##    result resubmits the open row's stored txn instead of reserving again.
##    :112-115 `_on_refused` (clears `_pending` for water_dock_action): route the
##    refusal detail (txn_id/world_instance_id/code/receipt) to refund() before
##    clearing, and keep the prompt disabled while the row is still pending.
## 2. scripts/world/water_dock_rules.gd:17 `evaluate` (refusals :24-46): for paid actions, the
##    FIRST check (before unknown_action, wrong_realm, unknown_character,
##    too_far) looks up the stored receipt for intent.txn_id and, if present,
##    refuses already_done carrying that receipt, so a resubmitted committed
##    txn always gets its proof. Then require txn_id + world_instance_id
##    matching the host world (mismatch -> wrong_world), stop emitting player
##    `item_take` ops (:47-50), and emit a world receipt op carrying
##    context.character_id as payer_character_id; the flag-set already_done
##    path also includes the stored receipt for the action.
## 3. scripts/net/world_ledger.gd:144-148 (`water_dock_action` commit) and
##    :903 `_commit`: apply/replicate the receipt op; autoload/world_state.gd:257
##    save_data / :279 load_data persist a `water_dock_receipts` map.
## 4. scripts/net/ledger_rpc.gd:283 `_commit_here` (~:299-303, :308-320): stamp
##    world_instance_id/txn_id (and the receipt on refusal) into dock verdicts as
##    satchel verdicts already are. :328-345 the save-failure rollback already
##    returns code journal_failed stamped with world_instance_id and txn_id for
##    water_dock_action; that verdict is a REFUND_CODES refund (the world was
##    rolled back as one unit, so nothing was committed). :498 `_rpc_verdict`
##    and the host-local refusal path call refund(). :485 `apply_remote_delta`
##    and :129 `_settle_satchel_receipts` call settle()/reconcile() with the
##    world's receipts (safe anywhere now: reconcile never refunds on absence).
##    Reconnect: on scripts/net/session.gd:945 `snapshot_applied` (i.e. once
##    `snapshot_ready()` is true; the host after its world load), call
##    reconcile() with in_flight_txn_ids = []; every txn in its `needs_submit`
##    is resubmitted unchanged (same txn id and intent, after a character
##    persist). Resubmission is the ONLY absence handler. There is no
##    timer-driven refund anywhere.
##
## --- Wiring preconditions (MANDATORY; the module is only safe under them) --
## Refusal codes are final for ONE submission, not for a txn. The wiring must
## therefore guarantee:
##  P1 (client) At most one outstanding submission per txn per connection.
##     A lost verdict is NOT retried on a timer; the txn is resubmitted only
##     after a verdict for the previous copy or after a reconnect's
##     snapshot_applied. Otherwise copy A can be refused (prerequisite /
##     journal_failed) and refunded while copy B later commits: a free repair.
##  P2 (host) Refused paid-dock txn ids are remembered for the connection
##     outside the journal_failed rollback (which clears _seen_txns), and any
##     later copy of a refused txn gets the same refusal.
##  P3 (host) The receipt lookup for intent.txn_id runs first; a receipt's
##     txn_id must equal txn_id(instance, action, resolved character,
##     attempt) or the intent is refused as malformed.
##  P4 (host) Loading a world whose dock flag predates receipts writes a
##     placeholder receipt {txn_id:"legacy", payer_character_id:"legacy"} so
##     open rows refund instead of resubmitting forever.
## A wiring change that cannot meet P1-P4 must not call refund() on
## prerequisite/journal_failed.
##    :562 `item_take` stays for other kinds only.
## 5. No character schema change: rows ride in satchel_escrow
##    (scripts/save/character_save.gd:45). satchel_escrow.gd reconcile skips
##    rows whose kind is not a death-satchel kind, so the kinds do not collide.

const KIND := "water_dock_debit"
const VERSION := 1
const TXN_NAMESPACE := "water-dock-debit-v1"
const OPEN := ["pending", "refund_due"]
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
## {"ok", "code", "changed", "txn_id", "intent": {txn_id, world_instance_id}}.
## Refuses with no change when inputs are invalid, items are insufficient, an
## open row for the same action/world/character exists, or it was already paid.
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
	for raw: Variant in (escrow as Dictionary).values():
		if not _same_action(raw, world_instance_id, action_id, character):
			continue
		var status := str((raw as Dictionary).get("status", ""))
		if status in OPEN:
			return _result(false, "already_pending", false, str(raw.get("txn_id", "")))
		if status == "settled" and not restored:
			return _result(false, "already_paid", false, str(raw.get("txn_id", "")))
		attempt = maxi(attempt, int(raw.get("attempt", 0)) + 1)
	var txn := txn_id(world_instance_id, action_id, character, attempt)
	if (escrow as Dictionary).has(txn):
		return _result(false, "already_pending", false, txn)
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
	out["intent"] = {"txn_id": txn, "world_instance_id": world_instance_id}
	return out


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
##   ""/no_room       -- items returned (fully / partly, rest refund_due).
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
	var receipt: Variant = reason.get("receipt")
	if receipt is Dictionary and _receipt_pays(receipt, row):
		var paid := settle(state, receipt)
		paid["code"] = "paid_by_this_txn"
		return paid
	if str(row.status) == "refund_due":
		# Already authoritative; only finish returning what is still owed.
		return _return_items(state, row, str(row.get("reason", "")))
	if code == "already_done":
		if receipt is Dictionary and _receipt_for(receipt, row):
			return _return_items(state, row, "paid_by_other")
		return _result(false, "needs_receipt", false, txn)
	if not code in REFUND_CODES:
		return _result(false, "retry_later", false, txn)
	return _return_items(state, row, code)


## Reconnect/load path. `world_facts` must be the host's authoritative durable
## receipts for `world_instance_id`. NEVER refunds on absence of a receipt.
## Returns {"changed", "settled":[txn], "refunded":[txn], "waiting":[txn],
##          "needs_submit":[txn]}:
##   - refund_due rows in ANY world retry returning their owed items (the
##     refund was already authoritative; items are owed regardless of world);
##   - pending rows of this world whose receipt names them settle;
##   - pending rows whose well-formed receipt names another txn/payer refund
##     (the action is durably paid by someone else, so this txn cannot commit);
##   - pending rows with no receipt land in `needs_submit` (resubmit the same
##     txn; the host dedupes by txn id), or in `waiting` if listed in
##     `in_flight_txn_ids` (already sent; await the verdict);
##   - pending rows with a malformed/foreign receipt stay in `waiting`;
##   - pending rows of other worlds are untouched and not reported.
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
			var receipt: Variant = world_facts.get(str(row.action_id))
			if receipt == null:
				# Absence: maybe in flight, maybe lost. Never a refund.
				var bucket := "waiting" if in_flight_txn_ids.has(str(key)) else "needs_submit"
				(out[bucket] as Array).append(str(key))
				continue
			if receipt is Dictionary and _receipt_pays(receipt, row):
				result = settle(state, receipt)
			elif receipt is Dictionary and _receipt_for(receipt, row):
				result = _return_items(state, row, "paid_by_other")
			else:
				# Malformed or foreign receipt: never guess. Leave the row open.
				(out.waiting as Array).append(str(key))
				continue
		out.changed = bool(out.changed) or bool(result.get("changed", false))
		match str(row.status):
			"settled": (out.settled as Array).append(str(key))
			"refunded": (out.refunded as Array).append(str(key))
			_: (out.waiting as Array).append(str(key))
	return out


## Open (unresolved) txn ids for this character, for UI and submission retry.
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
