extends Node2D

const BACKGROUND = preload("res://assets/visual/background.png")
const V = preload("res://scripts/visuals.gd")
var levels: Array
var store := SaveStore.new()
var audio: MindAudio
var state := PuzzleState.new()
var board: MindBoard
var demo: MindBoard
var ui: Control
var overlay: Node2D
var screen := "splash"
var settings_return := "menu"
var clock := 0.0
var splash_time := 0.0
var victory_time := -1.0
var completion: Dictionary = {}
var active_level := 1
var levels_page := 0
var hint_text := ""
var hint_timer := 0.0
var view := Vector2(960,540)
var capture_path := ""
var capture_frame := 0
var capture_done := false
var lifecycle_paused := false
var control_buttons: Dictionary = {}

func _ready() -> void:
	levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	store.level_count = levels.size()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--view=") or arg.begins_with("--capture="): store.path="user://render-evidence.json"
	store.load_data()
	audio = MindAudio.new(); add_child(audio); audio.configure(store.data.settings)
	board = MindBoard.new(); add_child(board); board.visible = false; board.tile_tapped.connect(tap_tile)
	demo = MindBoard.new(); add_child(demo); demo.visible = false; demo.interactable = false
	overlay = Node2D.new(); overlay.set_script(load("res://scripts/overlay.gd")); overlay.game = self; add_child(overlay)
	ui = Control.new(); ui.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(ui)
	get_viewport().size_changed.connect(resize)
	resize()
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
	for arg in args:
		if arg.begins_with("--view="):
			var value := arg.trim_prefix("--view=")
			if value.is_valid_int(): start_level(clampi(int(value),1,levels.size()))
			elif value == "solved":
				start_level(20)
				for t in state.tiles:
					t.rotation = t.solution
					if t.type == "switch": t.on = true
				state.moves = int(state.level.par); state.refresh(); board.setup(state); begin_victory()
			else: show_screen(value)

func resize() -> void:
	view = get_viewport_rect().size
	position = Vector2.ZERO
	if OS.has_feature("android"):
		var physical := Vector2(DisplayServer.screen_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		if physical.x > 0 and safe.size.x > 0:
			var ratio := view / physical
			position = safe.position * ratio
			view = safe.size * ratio
	if ui != null: ui.size = view
	if board != null and state.level:
		board.area = Rect2(32,132,view.x-324,view.y-202); board.relayout()
	if demo != null and demo.state != null:
		demo.area = Rect2(view.x*.53,132,view.x*.43,view.y-226); demo.relayout()
	build_ui()
	queue_redraw()

func clear_ui() -> void:
	for child in ui.get_children(): ui.remove_child(child); child.queue_free()
	control_buttons.clear()

func show_screen(name: String) -> void:
	screen = name
	board.visible = name in ["game","pause","complete"] or (name == "settings" and settings_return == "pause")
	board.interactable = name == "game" and victory_time < 0
	demo.visible = name == "menu"
	if name == "menu":
		var preview := PuzzleState.new(); preview.setup(levels[5])
		for t in preview.tiles: t.rotation = t.solution
		preview.refresh(); demo.setup(preview); demo.area = Rect2(view.x*.53,132,view.x*.43,view.y-226);demo.relayout()
	overlay.visible = name in ["pause","settings","complete"]
	build_ui(); queue_redraw()

func label(text: String, at: Vector2, size: Vector2, font_size := 15, color: Color = V.MUTED, bold := false) -> Label:
	var l := Label.new(); l.text = text; l.position = at; l.size = size; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",V.BOLD if bold else V.FONT); l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color)
	ui.add_child(l); return l

func button(text: String, r: Rect2, callback: Callable, primary := false, disabled := false) -> Button:
	var b := Button.new(); b.text = text; b.position = r.position; b.size = Vector2(r.size.x,maxf(r.size.y,48)); b.disabled = disabled
	b.add_theme_font_override("font",V.BOLD); b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",V.BG if primary else V.TEXT)
	b.add_theme_color_override("font_hover_color",V.BG if primary else V.TEXT)
	b.add_theme_color_override("font_pressed_color",V.BG if primary else V.TEXT)
	b.add_theme_color_override("font_disabled_color",Color("576879"))
	b.add_theme_stylebox_override("normal",V.style(V.MINT if primary else Color("1b2b3b"),V.MINT if primary else Color("344859"),12))
	b.add_theme_stylebox_override("hover",V.style(Color("a7f5df") if primary else Color("293c4d"),V.MINT if primary else Color("536e7a"),12))
	b.add_theme_stylebox_override("pressed",V.style(Color("5bc9ad") if primary else Color("344d59"),V.MINT,12))
	b.add_theme_stylebox_override("disabled",V.style(Color("121d2c"),Color("243444"),12))
	b.add_theme_stylebox_override("focus",V.style(Color.TRANSPARENT,V.GOLD,12,2))
	b.pressed.connect(func(): audio.play("button"); callback.call())
	ui.add_child(b); return b

func build_ui() -> void:
	if ui == null: return
	clear_ui()
	var w := view.x; var h := view.y
	match screen:
		"menu":
			var play_text := "CONTINUE  →" if not store.data.session.is_empty() else "PLAY  →"
			button(play_text,Rect2(56,h*.56,264,52),continue_play,true)
			button("Level select",Rect2(56,h*.56+64,126,46),func():show_screen("levels"))
			button("Settings",Rect2(194,h*.56+64,126,46),func():open_settings("menu"))
			label("20 handcrafted puzzles  ·  no rush, just rhythm",Vector2(56,h-72),Vector2(430,26),12)
		"levels":
			button("←  Back",Rect2(w-150,38,114,42),func():show_screen("menu"))
			var cw := (w-72)/5.0; var ch := minf(84,(h-190)/4.0)
			for i in range(levels_page*20,mini(levels_page*20+20,levels.size())):
				var slot := i%20
				var number := i+1; var unlocked: bool = number <= int(store.data.unlocked)
				var r := Rect2(36+(slot%5)*cw,139+(slot/5)*ch,cw-12,ch-12)
				var b := button("%02d"%number,r,func():start_level(number),false,not unlocked)
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.add_theme_font_size_override("font_size",24)
				for style_name in ["normal","hover","pressed","disabled"]:
					var s: StyleBoxFlat = b.get_theme_stylebox(style_name).duplicate();s.content_margin_left = 12;b.add_theme_stylebox_override(style_name,s)
				var title: String = levels[i].title
				var title_label := Label.new(); title_label.text = title;title_label.position = Vector2(53,12);title_label.size = Vector2(cw-72,20)
				title_label.add_theme_font_override("font",V.FONT);title_label.add_theme_font_size_override("font_size",10);title_label.add_theme_color_override("font_color",V.TEXT if unlocked else Color("536476"));title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(title_label)
				var earned: int = store.data.results.get(str(number),{}).get("stars",0)
				var star_label := Label.new();star_label.text = "★".repeat(earned)+"☆".repeat(3-earned) if unlocked else "LOCKED"
				star_label.position = Vector2(53,32);star_label.add_theme_font_override("font",V.FONT);star_label.add_theme_font_size_override("font_size",14 if unlocked else 9);star_label.add_theme_color_override("font_color",V.GOLD if earned>0 else Color("536a79"));star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE;b.add_child(star_label)
			if levels.size()>20:
				button("←",Rect2(w/2-64,h-58,56,48),func():levels_page-=1;build_ui(),false,levels_page==0)
				button("→",Rect2(w/2+8,h-58,56,48),func():levels_page+=1;build_ui(),false,(levels_page+1)*20>=levels.size())
		"game":
			button("Ⅱ",Rect2(w-84,30,52,52),pause_game)
			var x := w-258
			control_buttons.undo = button("↶  Undo",Rect2(x,292,208,52),undo_move,false,state.history.is_empty())
			control_buttons.restart = button("Restart",Rect2(x,354,98,52),restart_level)
			control_buttons.hint = button("✧  Hint",Rect2(x+110,354,98,52),request_hint)
			button("←  Levels",Rect2(x,416,208,50),return_levels)
		"pause":
			var x := (w-360)/2
			button("Resume",Rect2(x+28,196,304,46),resume_game,true)
			button("Restart level",Rect2(x+28,254,304,42),restart_level)
			button("Settings",Rect2(x+28,307,304,42),func():open_settings("pause"))
			button("Level select",Rect2(x+28,360,304,42),return_levels)
		"settings":
			var x := (w-400)/2
			button("ON" if store.data.settings.music else "OFF",Rect2(x+250,198,112,44),func():toggle_setting("music"),store.data.settings.music)
			button("ON" if store.data.settings.sfx else "OFF",Rect2(x+250,264,112,44),func():toggle_setting("sfx"),store.data.settings.sfx)
			button("Done",Rect2(x+38,370,324,46),func():show_screen(settings_return),true)
		"complete":
			var x := (w-400)/2
			button("NEXT LEVEL  →" if active_level<levels.size() else "ALL LEVELS  →",Rect2(x+30,324,340,48),func():start_level(active_level+1) if active_level<levels.size() else show_screen("levels"),true)
			button("Replay",Rect2(x+30,385,164,42),restart_level)
			button("Level select",Rect2(x+206,385,164,42),return_levels)

func start_level(number: int) -> void:
	active_level = clampi(number,1,levels.size()); state.setup(levels[active_level-1]); victory_time = -1; hint_text = "";hint_timer = 0
	board.setup(state); board.area = Rect2(32,132,view.x-324,view.y-202);board.relayout()
	if active_level == 1: board.hint_index = state.hint()
	show_screen("game")
	store.checkpoint(state)

func continue_play() -> void:
	var saved: Dictionary = store.data.session.duplicate(true)
	var number: int = clampi(int(saved.get("level",store.data.unlocked)),1,int(store.data.unlocked))
	start_level(number)
	if saved.get("level") != number or not (saved.get("tiles") is Array) or saved.tiles.size()!=state.tiles.size(): return
	for i in state.tiles.size():
		if not (saved.tiles[i] is Dictionary) or saved.tiles[i].get("type")!=state.tiles[i].type or int(saved.tiles[i].get("rotation",-1)) not in range(4): return
		if state.tiles[i].get("fixed",false) and state.tiles[i].type != "switch" and saved.tiles[i].rotation != state.tiles[i].rotation: return
	for i in state.tiles.size():
		state.tiles[i].rotation = int(saved.tiles[i].rotation)
		if state.tiles[i].type == "switch": state.tiles[i].on = bool(saved.tiles[i].get("on",false))
	state.moves = maxi(0,int(saved.get("moves",0)))
	# Only restore structurally valid undo entries; never trust arbitrary tile definitions.
	state.history = []
	for move in saved.get("history",[]):
		if not (move is Dictionary) or not (move.get("tile") is Dictionary): state.history.clear();break
		var idx: int = int(move.get("index",-1))
		if idx < 0 or idx >= state.tiles.size() or move.tile.get("type") != state.tiles[idx].type: state.history.clear();break
		var prior: Dictionary = state.level.tiles[idx].duplicate(true)
		prior.rotation = posmod(int(move.tile.get("rotation",0)),4)
		if prior.type == "switch": prior.on = bool(move.tile.get("on",false))
		state.history.append({"index":idx,"tile":prior})
	state.refresh();board.setup(state);board.relayout();build_ui()
	store.checkpoint(state)
	if state.network.solved: begin_victory()

func tap_tile(index: int) -> void:
	if screen != "game" or victory_time >= 0: return
	var before: int = state.network.targets.size()
	var lit_before: int = state.network.powered.size()
	if not state.manipulate(index): return
	board.feedback(index);audio.play("rotate")
	if OS.has_feature("android"): Input.vibrate_handheld(12)
	if state.network.targets.size()>before: audio.play("target")
	elif state.network.powered.size()>lit_before: audio.play("connect")
	if control_buttons.has("undo"): control_buttons.undo.disabled = false
	store.checkpoint(state)
	if state.network.solved: begin_victory()

func undo_move() -> void:
	if victory_time>=0: return
	var idx := state.undo()
	if idx<0: return
	board.feedback(idx,false);audio.play("rotate");hint_text = "";store.checkpoint(state)
	if control_buttons.has("undo"): control_buttons.undo.disabled = state.history.is_empty()

func restart_level() -> void:
	start_level(active_level)

func request_hint() -> void:
	board.hint_index = state.hint()
	if board.hint_index < 0: return
	hint_text = "Tap the highlighted switch." if state.tiles[board.hint_index].type=="switch" else "Rotate the highlighted tile toward a matching connection."
	hint_timer = 6

func begin_victory() -> void:
	victory_time = 0;board.interactable = false
	completion = store.record(active_level,state.moves,int(state.level.par))
	audio.play("complete")
	for b in control_buttons.values(): b.disabled = true

func return_levels() -> void:
	if not state.level.is_empty() and victory_time<0:store.checkpoint(state)
	victory_time = -1;show_screen("levels")

func pause_game() -> void:
	if screen != "game" or victory_time>=0: return
	store.checkpoint(state);show_screen("pause")

func resume_game() -> void:
	audio.resume(); lifecycle_paused = false;show_screen("game")

func open_settings(from: String) -> void:
	settings_return = from;show_screen("settings")

func toggle_setting(key: String) -> void:
	store.data.settings[key] = not store.data.settings[key];store.persist();audio.configure(store.data.settings);build_ui()

func _notification(what: int) -> void:
	if not is_instance_valid(audio): return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		lifecycle_paused = true
		if screen == "game":
			if victory_time<0: pause_game()
			else: show_screen("complete")
		audio.suspend()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if screen != "pause": audio.resume()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not state.level.is_empty() and victory_time<0:store.checkpoint(state)
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen == "game":pause_game()
		elif screen == "pause":resume_game()
		elif screen == "settings":show_screen(settings_return)
		else:show_screen("menu")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.is_action_pressed("ui_cancel"):
		if screen=="game":pause_game()
		elif screen=="pause":resume_game()
		elif screen=="settings":show_screen(settings_return)
		else:show_screen("menu")
		get_viewport().set_input_as_handled();return
	if screen!="game" or victory_time>=0:return
	if event is InputEventKey:
		match event.keycode:
			KEY_Z:undo_move()
			KEY_R:restart_level()
			KEY_H:request_hint()
			KEY_ENTER,KEY_SPACE:
				if board.focused>=0:tap_tile(board.focused)
			KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN:
				if board.focused<0:board.focused=0
				else:
					var step: int = -1 if event.keycode==KEY_LEFT else 1 if event.keycode==KEY_RIGHT else -int(state.level.width) if event.keycode==KEY_UP else int(state.level.width)
					board.focused = posmod(board.focused+step,state.tiles.size())

func _process(delta: float) -> void:
	clock += delta
	if screen=="splash":
		splash_time+=delta
		if splash_time>1.35:show_screen("menu")
	if hint_timer>0:
		hint_timer-=delta
		if hint_timer<=0:hint_text="";board.hint_index=-1
	if victory_time>=0 and screen=="game":
		victory_time+=delta
		if victory_time>1.55:show_screen("complete")
	if not capture_path.is_empty() and not capture_done:
		capture_frame+=1
		if capture_frame==150:
			capture_done=true
			capture.call_deferred()
	queue_redraw()
	if overlay != null: overlay.queue_redraw()

func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_path)
	print("Rendered evidence saved: ",capture_path)
	audio.release_streams()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func move_text(count: int) -> String:
	return "%d move%s"%[count,"" if count==1 else "s"]

func text(value: String, pos: Vector2, size: int, color: Color = V.TEXT, bold := false) -> void:
	draw_string(V.BOLD if bold else V.FONT,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func logo(pos: Vector2, scale_factor := 1.0) -> void:
	var points := PackedVector2Array([Vector2(0,24),Vector2(0,0),Vector2(22,0),Vector2(22,34),Vector2(44,34),Vector2(44,10)])
	for i in points.size():points[i]=pos+points[i]*scale_factor
	draw_polyline(points,V.MINT,4*scale_factor,true)
	draw_circle(pos+Vector2(0,24)*scale_factor,5*scale_factor,V.MINT,true,-1,true)
	draw_circle(pos+Vector2(44,10)*scale_factor,5*scale_factor,V.GOLD,true,-1,true)

func _draw() -> void:
	var w:=view.x;var h:=view.y
	# Baked, original lighting gradient uses a single draw.
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,view),false)
	for i in 18:
		var x: float = fmod(i*173.0+32,w);var y: float = fmod(i*97.0+14,h)
		draw_circle(Vector2(x,y),1,Color("263b4a"),true,-1,true)
	if screen in ["game","pause","complete"] or (screen=="settings" and settings_return=="pause"):
		draw_game()
	elif screen == "splash":
		logo(Vector2(w/2-44,h/2-60),2)
		text("MindFlip",Vector2(w/2-112,h/2+58),48,V.TEXT,true)
		text("TWIST  ·  CONNECT  ·  ILLUMINATE",Vector2(w/2-144,h/2+97),12,V.MUTED)
	elif screen == "menu":
		logo(Vector2(58,52),.9)
		text("MINDFLIP / VOL. 01",Vector2(118,74),11,V.MINT,true)
		text("MindFlip",Vector2(52,h*.35),68,V.TEXT,true)
		text("Make the connection.",Vector2(57,h*.35+43),23,V.TEXT)
		text("A small twist. A bright idea.",Vector2(58,h*.35+76),14,V.MUTED)
		text("THE ART OF CONNECTING",Vector2(w*.57,h-62),10,V.MINT,true)
		text("Rotate the pieces. Let your mind flow.",Vector2(w*.57,h-38),13,V.MUTED)
	elif screen == "levels":
		text("YOUR NEXT CONNECTION",Vector2(38,53),10,V.MINT,true)
		text("Choose a puzzle",Vector2(36,105),36,V.TEXT,true)
		var stars_total:=0
		for result in store.data.results.values():stars_total+=int(result.stars)
		text("%02d / %02d completed"%[store.data.results.size(),levels.size()],Vector2(38,h-24),12,V.MUTED)
		text("★  %02d / %02d"%[stars_total,levels.size()*3],Vector2(w-140,h-24),13,V.GOLD)

func draw_overlay(canvas: Node2D) -> void:
	var w:=view.x;var h:=view.y
	if screen=="pause":
		canvas.draw_rect(Rect2(Vector2.ZERO,view),Color(0.025,.045,.075,.78))
		var r:=Rect2((w-360)/2,100,360,326);canvas.draw_style_box(V.style(V.PANEL,Color("36505a"),24),r)
		overlay_text(canvas,"PAUSED",r.position+Vector2(28,35),10,V.MINT,true)
		overlay_text(canvas,"Take a breath.",r.position+Vector2(28,70),26,V.TEXT,true)
	elif screen=="settings":
		canvas.draw_rect(Rect2(Vector2.ZERO,view),Color(0.025,.045,.075,.86))
		var r:=Rect2((w-400)/2,96,400,345);canvas.draw_style_box(V.style(V.PANEL,Color("36505a"),24),r)
		overlay_text(canvas,"MAKE IT YOURS",r.position+Vector2(38,36),10,V.MINT,true)
		overlay_text(canvas,"Settings",r.position+Vector2(38,73),30,V.TEXT,true)
		overlay_text(canvas,"Music",r.position+Vector2(38,130),18,V.TEXT,true)
		overlay_text(canvas,"A calm, ambient pulse",r.position+Vector2(38,151),11,V.MUTED)
		overlay_text(canvas,"Sound effects",r.position+Vector2(38,197),18,V.TEXT,true)
		overlay_text(canvas,"Glass tones & connections",r.position+Vector2(38,218),11,V.MUTED)
		overlay_text(canvas,"Your preferences are saved on this device.",r.position+Vector2(38,254),11,V.MUTED)
	elif screen=="complete":
		canvas.draw_rect(Rect2(Vector2.ZERO,view),Color(0.025,.045,.075,.8))
		var r:=Rect2((w-400)/2,82,400,370);canvas.draw_style_box(V.style(V.PANEL,Color("47706a"),24),r)
		overlay_text(canvas,"CONNECTION COMPLETE",r.position+Vector2(81,34),11,V.MINT,true)
		var earned:=PuzzleRules.stars(state.moves,int(state.level.par))
		for i in 3:
			var center:=r.position+Vector2(140+i*60,84)
			canvas.draw_colored_polygon(V.star(center,22),V.GOLD if i<earned else Color("344957"))
		overlay_text(canvas,"Beautifully connected.",r.position+Vector2(37,139),26,V.TEXT,true)
		overlay_text(canvas,"%02d  /  %s"%[active_level,state.level.title],r.position+Vector2(42,170),13,V.MUTED)
		overlay_text(canvas,move_text(state.moves),r.position+Vector2(55,207),20,V.TEXT,true)
		overlay_text(canvas,"Best: %d"%completion.get("moves",state.moves),r.position+Vector2(240,207),17,V.MINT,true)
		overlay_text(canvas,"3-star goal: %s or fewer"%move_text(int(state.level.par)),r.position+Vector2(75,230),12,V.MUTED)
		# Finite geometric celebration, no runaway emitter or assets.
		for i in 16:
			var a:=float(i)*TAU/16;var dist:=130+sin(clock*2+i)*18
			var p:=Vector2(w/2,180)+Vector2(cos(a),sin(a)*.45)*dist
			canvas.draw_circle(p,1.5,Color(V.GOLD,.28),true,-1,true)

func overlay_text(canvas: Node2D, value: String, pos: Vector2, size: int, color: Color = V.TEXT, bold := false) -> void:
	canvas.draw_string(V.BOLD if bold else V.FONT,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw_game() -> void:
	var w:=view.x;var h:=view.y
	logo(Vector2(34,37),.65)
	text("MINDFLIP",Vector2(77,54),13,V.TEXT,true)
	text("%02d / %02d   ·   %s"%[active_level,levels.size(),state.level.chapter],Vector2(34,89),10,V.MINT,true)
	text(state.level.title,Vector2(32,119),24,V.TEXT,true)
	var r:=Rect2(w-274,132,242,h-202)
	draw_style_box(V.style(V.PANEL,Color("2b414f"),20),r)
	text("CONNECTIONS",r.position+Vector2(17,29),10,V.MUTED,true)
	var connected: int = state.network.targets.size();var total: int = state.network.required
	text("%d / %d targets"%[connected,total],r.position+Vector2(17,59),22,V.MINT if connected>0 else V.TEXT,true)
	for i in total:
		var p:=r.position+Vector2(24+i*22,80)
		draw_circle(p,4.5,V.GOLD if i<connected else Color("354953"),true,-1,true)
	draw_line(r.position+Vector2(17,103),r.position+Vector2(225,103),Color("2d4351"),1,true)
	text("MOVES",r.position+Vector2(17,120),10,V.MUTED,true)
	text(str(state.moves),r.position+Vector2(17,148),26,V.TEXT,true)
	text("3-star goal  ≤ %d"%state.level.par,r.position+Vector2(72,142),12,V.GOLD)
	var tip: String = hint_text if hint_timer>0 else state.level.tip
	if victory_time>=0:tip="All targets connected. Let it flow."
	text("✦",Vector2(36,h-38),15,V.GOLD)
	text(tip,Vector2(60,h-38),12,V.GOLD if hint_timer>0 else V.MUTED)
	text("TAP TO ROTATE",Vector2(36,h-17),9,Color("566e7d"),true)
