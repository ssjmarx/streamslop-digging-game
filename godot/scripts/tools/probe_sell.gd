## Sale probe (headless): two sells through the real kiosk -- money must land at
## 1 dirt = $1 on the SECOND sale too (the vanished-transfer regression,
## Addendum 45), the HUD must stand down, and post-sale digs must log.
extends SceneTree

const SETTLE_FRAMES := 1200   # boot sequence + loading, before the first sale
const POLL_PHYSICS_FRAMES := 1500   # a pour runs ~6.5s on physics ticks; 25s margin

var _kiosk: Node
var _diglog: Node
var _hud: Node


## Boot: run once the tree exists.
func _initialize() -> void:
	_run()


## Boot the real scene, run two sale cycles, verify money/HUD/log after each.
func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in SETTLE_FRAMES:
		await process_frame
	_kiosk = get_first_node_in_group("kiosk")
	_diglog = get_first_node_in_group("diglog")
	_hud = get_first_node_in_group("hud")
	var state = root.get_node("GameState")
	var money0: int = state.money   # additive dirt: the dev save's wallet and banked dirt survive the probe
	var dirt0: int = state.dirt
	var fail := ""
	state.dirt += 500
	_kiosk._begin_sale()
	fail = await _await_sale(state, money0 + dirt0 + 500)
	print("== sale one: money=%d dirt=%d hud_sale=%s" % [state.money, state.dirt, _hud._sale_active])
	if fail == "":
		state.dirt += 300
		_kiosk._begin_sale()
		fail = await _await_sale(state, money0 + dirt0 + 800)
		print("== sale two: money=%d dirt=%d hud_sale=%s" % [state.money, state.dirt, _hud._sale_active])
	if fail == "":
		_diglog.append_sphere(Vector3(0.5, -3.5, 0.5), 1.5)
		var entries: Array[Dictionary] = _diglog.read_entries()
		if entries.size() != 1:
			fail = "post-sale dig did not log (%d entries)" % entries.size()
		else:
			print("== post-sale dig logged (%d entry)" % entries.size())
	_verdict(fail)


## Poll on physics frames (the pour advances on physics ticks) until it ends, then check the law.
func _await_sale(state, expected_money: int) -> String:
	for i in POLL_PHYSICS_FRAMES:
		await physics_frame
		if not _kiosk._pouring:
			break
	if _kiosk._pouring:
		return "the pour never ended"
	for i in 10:
		await process_frame   # let the HUD's next _process see the landed state
	if state.money != expected_money:
		return "money landed at %d, expected %d (1 dirt = 1 dollar)" % [state.money, expected_money]
	if state.dirt != 0:
		return "dirt did not collapse to 0"
	if _hud._sale_active:
		return "the HUD never left sale mode"
	return ""


## Print the verdict and exit.
func _verdict(fail: String) -> void:
	print("== RESULT: %s" % ("PASS -- money lands on every sale, the HUD stands down, digs log after a sale" if fail == "" else "FAIL -- " + fail))
	quit(0 if fail == "" else 1)