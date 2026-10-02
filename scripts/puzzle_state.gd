class_name PuzzleState
extends RefCounted

var level: Dictionary
var tiles: Array
var history: Array = []
var moves := 0
var network: Dictionary

func setup(definition: Dictionary) -> void:
	level = definition
	restart()

func restart() -> void:
	tiles = level.tiles.duplicate(true)
	for t in tiles: t.rotation = int(t.rotation)
	history.clear()
	moves = 0
	refresh()

func refresh() -> void:
	network = PuzzleRules.evaluate(tiles, int(level.width), int(level.height))

func manipulate(index: int) -> bool:
	if index < 0 or index >= tiles.size(): return false
	var t: Dictionary = tiles[index]
	if t.type == "blocked" or (t.get("fixed",false) and t.type != "switch"): return false
	history.append({"index":index,"tile":t.duplicate(true)})
	if t.type == "switch": t.on = not t.get("on",false)
	else: t.rotation = (int(t.rotation) + 1) % 4
	moves += 1
	refresh()
	return true

func undo() -> int:
	if history.is_empty(): return -1
	var move: Dictionary = history.pop_back()
	tiles[move.index] = move.tile
	moves -= 1
	refresh()
	return move.index

func hint() -> int:
	# One suggestion toward a verified authored solution. Never mutates the board.
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if t.type == "switch" and t.get("on",false) != t.get("solution_on",true): return i
		if t.get("fixed",false) or t.type == "blocked": continue
		var period := 2 if t.type == "straight" or (t.type == "color_path" and t.get("shape") == "straight") else 4
		if posmod(int(t.rotation) - int(t.solution),period) != 0: return i
	return -1
