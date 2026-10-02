class_name PuzzleRules
extends RefCounted

const DIRECTIONS = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
const TYPES = ["straight", "corner", "tee", "cross", "start", "target", "blocked", "one_way", "switch", "gate", "splitter", "color_path", "color_target", "teleporter"]

static func ports(tile: Dictionary) -> Array:
	var kind: String = tile.type
	if kind in ["color_path", "switch", "gate"]: kind = tile.get("shape", "straight")
	var base: Array
	match kind:
		"straight", "one_way", "switch", "gate", "teleporter": base = [1,3] if kind != "straight" else [0,2]
		"corner": base = [0,1]
		"tee": base = [0,1,3]
		"cross", "splitter": base = [0,1,2,3]
		"start": base = [1]
		"target", "color_target": base = [3]
		_: base = []
	var out: Array = []
	for p in base: out.append((p + int(tile.rotation)) % 4)
	return out

static func evaluate(tiles: Array, width: int, height: int) -> Dictionary:
	var channels: Dictionary = {}
	var portals: Dictionary = {}
	var queue: Array = []
	var powered: Dictionary = {}
	var activated: Dictionary = {}
	var edges: Array = []
	var seen: Dictionary = {}
	var required := 0
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if t.type == "switch" and t.get("on", false): channels[t.get("channel", "A")] = true
		if t.type == "teleporter":
			var pair: String = t.get("pair", "A")
			if not portals.has(pair): portals[pair] = []
			portals[pair].append(i)
		if t.type == "start": queue.append([i, -1, "neutral", 0])
		if t.type in ["target", "color_target"] and t.get("required", true): required += 1
	var head := 0
	while head < queue.size():
		var state: Array = queue[head]; head += 1
		var idx: int = state[0]; var entry: int = state[1]; var color: String = state[2]; var distance: int = state[3]
		var key := "%d:%d:%s" % [idx,entry,color]
		if seen.has(key): continue
		seen[key] = true
		var t: Dictionary = tiles[idx]
		var ps := ports(t)
		if entry >= 0 and not ps.has(entry): continue
		if t.type == "blocked": continue
		if t.type == "gate" and not channels.get(t.get("channel", "A"), false): continue
		if t.type in ["one_way", "splitter"] and entry >= 0 and entry != (3 + int(t.rotation)) % 4: continue
		if t.type == "color_path":
			if color != "neutral" and color != t.color: continue
			color = t.color
		if t.type == "color_target" and color != t.color: continue
		if not powered.has(idx): powered[idx] = {"color":color, "distance":distance}
		if t.type in ["target", "color_target"]:
			activated[idx] = true
			continue
		if t.type == "teleporter" and entry != -2:
			var pair: Array = portals.get(t.get("pair", "A"), [])
			if pair.size() == 2:
				var other: int = pair[1] if pair[0] == idx else pair[0]
				queue.append([other,-2,color,distance+1])
				edges.append({"from":idx,"to":other,"color":color,"portal":true})
			continue
		for p in ps:
			if t.type == "one_way" and p != (1 + int(t.rotation)) % 4: continue
			if t.type == "splitter" and p == (3 + int(t.rotation)) % 4: continue
			var x: int = idx % width + DIRECTIONS[p].x
			var y: int = idx / width + DIRECTIONS[p].y
			if x < 0 or y < 0 or x >= width or y >= height: continue
			var ni := y * width + x
			if not ports(tiles[ni]).has((p+2)%4): continue
			queue.append([ni,(p+2)%4,color,distance+1])
			edges.append({"from":idx,"to":ni,"color":color,"portal":false})
	var all_required := required > 0
	for i in tiles.size():
		if tiles[i].type in ["target", "color_target"] and tiles[i].get("required", true) and not activated.has(i): all_required = false
	return {"powered":powered,"targets":activated,"edges":edges,"required":required,"solved":all_required}

static func stars(moves: int, par: int) -> int:
	if moves <= par: return 3
	if moves <= par + maxi(3, int(ceil(par * 0.5))): return 2
	return 1
