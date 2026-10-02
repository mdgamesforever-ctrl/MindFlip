class_name MindBoard
extends Node2D
signal tile_tapped(index: int)
const CARD_ATLAS = preload("res://assets/visual/tile_atlas.png")
var state: PuzzleState
var area := Rect2(30,132,632,340)
var cell := 80.0
var origin := Vector2.ZERO
var angles: Array = []
var tweens: Dictionary = {}
var bounces: Array = []
var base_ports: Array = []
var tray_style: StyleBoxFlat

func _exit_tree() -> void:
	for tw in tweens.values(): tw.kill()
	tweens.clear()
var flow_time := 0.0
var clock := 0.0
var hint_index := -1
var focused := -1
var interactable := true
var hint_style: StyleBoxFlat

func setup(puzzle: PuzzleState) -> void:
	state = puzzle
	for tw in tweens.values(): tw.kill()
	tweens.clear()
	angles.clear(); bounces.clear(); base_ports.clear()
	for t in state.tiles:
		angles.append(float(t.rotation)*PI/2); bounces.append(0.0)
		var base: Dictionary = t.duplicate(); base.rotation = 0
		base_ports.append(PuzzleRules.ports(base))
	tray_style = MindVisuals.style(Color("0e1926"),Color("253642"),24)
	hint_style = MindVisuals.style(Color.TRANSPARENT,MindVisuals.GOLD,16,2)
	hint_index = -1; focused = -1; flow_time = 0
	relayout()

func relayout() -> void:
	if state == null: return
	cell = minf(108,minf((area.size.x-32)/state.level.width,(area.size.y-24)/state.level.height))
	origin = area.position + (area.size - Vector2(state.level.width,state.level.height)*cell)/2
	queue_redraw()

func tile_rect(index: int) -> Rect2:
	return Rect2(origin+Vector2(index%int(state.level.width),index/int(state.level.width))*cell+Vector2(5,5),Vector2.ONE*(cell-10))

func index_at(point: Vector2) -> int:
	if state == null or not interactable: return -1
	var local := point-origin
	var x := int(floor(local.x/cell)); var y := int(floor(local.y/cell))
	if x<0 or y<0 or x>=state.level.width or y>=state.level.height: return -1
	var idx: int = y*int(state.level.width)+x
	return idx if tile_rect(idx).has_point(point) else -1

func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed: point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1: point = event.position
	else: return
	var idx := index_at(get_global_transform().affine_inverse() * point)
	if idx>=0:
		tile_tapped.emit(idx)
		get_viewport().set_input_as_handled()

func feedback(index: int, clockwise := true) -> void:
	if tweens.has(index): tweens[index].kill()
	var from: float = angles[index]
	var to := float(state.tiles[index].rotation)*PI/2
	if state.tiles[index].type != "switch":
		if clockwise:
			to = from + fposmod(to-from,TAU)
		else:
			to = from - fposmod(from-to,TAU)
	var tw := create_tween(); tweens[index] = tw
	tw.tween_method(func(v: float): angles[index] = v,from,to,.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bounces[index] = .22; hint_index = -1; flow_time = 0

func _process(delta: float) -> void:
	clock += delta; flow_time += delta
	for i in bounces.size(): bounces[i] = maxf(0,bounces[i]-delta)
	queue_redraw()

func _draw() -> void:
	if state == null: return
	# Recessed board tray, soft edge and tiny precision markings.
	draw_style_box(tray_style,area)
	for x in [area.position.x+14,area.end.x-14]:
		for y in [area.position.y+14,area.end.y-14]: draw_circle(Vector2(x,y),1.4,Color("47606a"),true,-1,true)
	for i in state.tiles.size():
		var t: Dictionary = state.tiles[i]; var r := tile_rect(i); var center := r.get_center()
		var lit: bool = state.network.powered.has(i) and flow_time >= state.network.powered[i].distance*.075
		var c := MindVisuals.energy(state.network.powered[i].color) if state.network.powered.has(i) else MindVisuals.MUTED
		var bounce: float = 1.0+sin(bounces[i]/.22*PI)*.045
		var size := r.size*bounce
		r = Rect2(center-size/2,size)
		var region: int = 1 if lit else 2 if t.type == "blocked" else 0
		draw_texture_rect_region(CARD_ATLAS,r,Rect2(region*128,0,128,128))
		if t.type == "blocked":
			# Quiet inset obstruction, intentionally subordinate to the route.
			var diamond := PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0)])
			draw_colored_polygon(diamond,Color("2b3b49"))
			continue
		if hint_index == i or focused == i:
			draw_style_box(hint_style,r.grow(2+sin(clock*4)*1.3))
		var ps: Array = base_ports[i]
		var length := cell*.37; var angle: float = angles[i]
		var glyph_color := c if lit else MindVisuals.energy(t.color) if t.type in ["color_path","color_target"] else Color("8fa6b5")
		var gate_closed: bool = t.type == "gate" and not state.network.powered.has(i)
		if gate_closed: glyph_color = Color("65737e")
		for p in ps:
			var v := Vector2(PuzzleRules.DIRECTIONS[p]).rotated(angle)*length*bounce
			if lit:
				draw_line(center,center+v,Color(c,.055),16,true); draw_line(center,center+v,Color(c,.11),11,true)
			draw_line(center,center+v,glyph_color,5.5,true)
			draw_circle(center+v,2.75,glyph_color,true,-1,true)
			if lit and t.type not in ["target","color_target"]:
				var phase := fposmod(clock*.8-i*.085,1.0)
				var pulse := center+v*phase
				draw_circle(pulse,3,Color(c,.12),true,-1,true); draw_circle(pulse,1.7,Color("eafff5"),true,-1,true)
		draw_circle(center,3,glyph_color,true,-1,true)
		match String(t.type):
			"start":
				draw_circle(center,cell*.15,Color(c,.09),true,-1,true)
				draw_circle(center,cell*.115,MindVisuals.MINT,true,-1,true)
				var bolt := PackedVector2Array([center+Vector2(1,-7),center+Vector2(-5,1),center+Vector2(0,1),center+Vector2(-1,7),center+Vector2(5,-1),center+Vector2(0,-1)])
				draw_colored_polygon(bolt,MindVisuals.BG)
			"target", "color_target":
				var tc := MindVisuals.energy(t.color) if t.type == "color_target" else MindVisuals.GOLD
				draw_circle(center,cell*.14,MindVisuals.TILE,true,-1,true)
				draw_arc(center,cell*.135,0,TAU,40,tc,2.5,true)
				draw_circle(center,cell*.065,tc if lit else Color(tc,.16),true,-1,true)
				if lit:
					var phase := fposmod(clock*.65,1.0)
					draw_arc(center,cell*(.15+.09*phase),0,TAU,40,Color(tc,(1-phase)*.28),1.2,true)
			"one_way", "splitter":
				var v := Vector2.RIGHT.rotated(angle); var side := v.orthogonal()
				draw_circle(center,9,MindVisuals.TILE,true,-1,true)
				var pts := PackedVector2Array([center-v*4-side*4,center+v*3,center-v*4+side*4])
				draw_polyline(pts,glyph_color,2.3,true)
				if t.type == "splitter": draw_arc(center,12,0,TAU,28,Color(glyph_color,.6),1,true)
			"switch":
				draw_style_box(MindVisuals.style(Color("122631"),glyph_color,8),Rect2(center-Vector2(14,9),Vector2(28,18)))
				var on: bool = t.get("on",false)
				draw_circle(center+Vector2(6 if on else -6,0),5,MindVisuals.MINT if on else MindVisuals.MUTED,true,-1,true)
				_draw_channel(t,r,MindVisuals.MINT)
			"gate":
				var v := Vector2.UP.rotated(angle); var side := v.orthogonal()
				for step in [-1,1]:
					var offset: Vector2 = side*(12 if lit else 5)*step
					draw_line(center+offset-v*8,center+offset+v*8,MindVisuals.MINT if lit else MindVisuals.GOLD,3,true)
				_draw_channel(t,r,MindVisuals.GOLD)
			"color_path":
				draw_circle(center,8,MindVisuals.TILE,true,-1,true);draw_colored_polygon(MindVisuals.star(center,7),MindVisuals.energy(t.color))
			"teleporter":
				draw_circle(center,10,MindVisuals.TILE,true,-1,true); draw_arc(center,9,clock,clock+PI*1.55,24,MindVisuals.VIOLET,2,true)
		if t.get("fixed",false) and t.type not in ["start","target","color_target","switch","gate","blocked","cross"]:
			var pos := r.position+Vector2(r.size.x-13,9)
			draw_arc(pos+Vector2(0,1),3,PI,TAU,10,Color("71828d"),1.3,true)
			draw_style_box(MindVisuals.style(Color("71828d"),Color.TRANSPARENT,1),Rect2(pos+Vector2(-4,1),Vector2(8,6)))

func _draw_channel(t: Dictionary, r: Rect2, c: Color) -> void:
	draw_string(MindVisuals.BOLD,r.position+Vector2(r.size.x-15,16),str(t.get("channel","A")),HORIZONTAL_ALIGNMENT_LEFT,-1,10,c)
