extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("FAIL: "+message)
func tile(kind: String, x: int, rotation := 0, extra := {}) -> Dictionary:
	var t := {"type":kind,"x":x,"y":0,"rotation":rotation,"solution":rotation,"fixed":false}
	t.merge(extra,true);return t
func line(mid: Dictionary, target := "target", extra := {}) -> Dictionary:
	return {"id":1,"width":3,"height":1,"par":1,"tiles":[tile("start",0),mid,tile(target,2,0,extra)]}
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	check(levels.size()==20,"20 levels shipped")
	for l in levels:
		var p:=PuzzleState.new();p.setup(l)
		check(not p.network.solved,"Level %d starts unsolved"%l.id)
		var original: Array = p.tiles.duplicate(true)
		var idx:=p.hint();check(idx>=0,"Useful hint for %d"%l.id)
		check(p.tiles==original,"Hint does not mutate %d"%l.id)
		check(p.manipulate(idx),"Manipulate hint %d"%l.id)
		check(p.moves==1,"Move count %d"%l.id)
		check(p.undo()==idx and p.tiles==original and p.moves==0,"Undo restores %d"%l.id)
		p.manipulate(idx);p.restart();check(p.tiles==original and p.moves==0 and p.history.is_empty(),"Restart restores %d"%l.id)
		var turns:=0
		while not p.network.solved and turns<100:
			idx=p.hint()
			if idx<0:break
			p.manipulate(idx);turns+=1
		check(p.network.solved,"Runtime solves level %d with useful hints"%l.id)
		check(p.network.targets.size()==p.network.required,"All targets %d"%l.id)
		check(p.moves<=l.par,"Witness matches authored par %d"%l.id)
	# All directions and tile families, including teleporter support not yet taught.
	for kind in ["straight","corner","tee","cross"]:
		var t:=tile(kind,0);var old:=PuzzleRules.ports(t)
		for j in 4:t.rotation=(int(t.rotation)+1)%4
		check(PuzzleRules.ports(t)==old,"Four rotations restore "+kind)
	var simple:=line(tile("straight",1,1));check(PuzzleRules.evaluate(simple.tiles,3,1).solved,"Straight connects")
	simple.tiles[1].rotation=0;check(not PuzzleRules.evaluate(simple.tiles,3,1).solved,"Misaligned straight blocks")
	var oneway:=line(tile("one_way",1));check(PuzzleRules.evaluate(oneway.tiles,3,1).solved,"One-way forward")
	oneway.tiles[1].rotation=2;check(not PuzzleRules.evaluate(oneway.tiles,3,1).solved,"One-way reverse blocks")
	var color:=line(tile("color_path",1,1,{"shape":"straight","color":"violet"}),"color_target",{"color":"violet"})
	check(PuzzleRules.evaluate(color.tiles,3,1).solved,"Color matches")
	color.tiles[2].color="coral";check(not PuzzleRules.evaluate(color.tiles,3,1).solved,"Color mismatch rejects")
	var mismatch: Array = [tile("start",0),tile("color_path",1,1,{"color":"violet"}),tile("color_path",2,1,{"color":"coral"}),tile("color_target",3,0,{"color":"coral"})]
	check(not PuzzleRules.evaluate(mismatch,4,1).solved,"Different path colors cannot mix")
	var gates: Array = [tile("start",0),tile("switch",1,1,{"shape":"straight","channel":"A","on":false}),tile("gate",2,1,{"shape":"straight","channel":"A"}),tile("target",3)]
	check(not PuzzleRules.evaluate(gates,4,1).solved,"Gate closed")
	gates[1].on=true;check(PuzzleRules.evaluate(gates,4,1).solved,"Switch opens paired gate")
	gates[2].channel="B";check(not PuzzleRules.evaluate(gates,4,1).solved,"Channels isolated")
	var tele: Array = [tile("start",0),tile("teleporter",1,0,{"pair":"P"}),tile("blocked",2),tile("blocked",3),tile("teleporter",4,0,{"pair":"P"}),tile("target",5)]
	check(PuzzleRules.evaluate(tele,6,1).solved,"Teleporter pair crosses blocked gap")
	tele[4].pair="Q";check(not PuzzleRules.evaluate(tele,6,1).solved,"Unpaired portal blocks")
	var split:=line(tile("splitter",1));check(PuzzleRules.evaluate(split.tiles,3,1).solved,"Splitter accepts tail")
	split.tiles[1].rotation=2;check(not PuzzleRules.evaluate(split.tiles,3,1).solved,"Splitter rejects output as input")
	var blocked:=line(tile("blocked",1));check(not PuzzleRules.evaluate(blocked.tiles,3,1).solved,"Obstruction blocks")
	var fixed:=PuzzleState.new();fixed.setup(levels[6]);check(not fixed.manipulate(5),"Fixed tile ignores manipulation")
	check(not fixed.manipulate(-1) and not fixed.manipulate(99),"Invalid taps ignored")
	check(PuzzleRules.stars(5,5)==3 and PuzzleRules.stars(8,5)==2 and PuzzleRules.stars(9,5)==1,"Star thresholds")
	# Save/progress, best result, recovery, and session history in isolated test file.
	var save:=SaveStore.new();save.path="user://test-progress.json"
	for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save.path+suffix))
	check(save.persist(),"Initial atomic save")
	save.record(1,2,1);check(save.data.unlocked==2,"Progression unlocks next")
	save.record(1,1,1);save.record(1,99,1);check(save.data.results["1"].moves==1 and save.data.results["1"].stars==3,"Best result never degrades")
	save.data.settings.music=false;save.persist()
	var reloaded:=SaveStore.new();reloaded.path=save.path;reloaded.load_data()
	check(reloaded.data.unlocked==2 and reloaded.data.results["1"].stars==3 and not reloaded.data.settings.music,"Save reload survives new instance")
	var live:=PuzzleState.new();live.setup(levels[1]);live.manipulate(live.hint());save.checkpoint(live)
	reloaded.load_data();check(reloaded.data.session.moves==1 and reloaded.data.session.history.size()==1,"Session and undo checkpoint")
	var file:=FileAccess.open(save.path,FileAccess.WRITE);file.store_string("corrupt");file.close();reloaded.load_data()
	check(reloaded.data.unlocked==2,"Corrupt primary recovers backup")
	for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(save.path+suffix))
	# Actual scene integration, logical touch coordinates, resizing and lifecycle.
	var game = load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.store.path="user://test-integration.json";game.store.data={"version":1,"unlocked":20,"results":{},"settings":{"music":false,"sfx":false},"session":{}}
	game.start_level(2)
	check(game.overlay.get_index()>game.board.get_index() and game.ui.get_index()>game.overlay.get_index(),"Modal canvas draws above board, controls above modal")
	check(game.audio.sounds.size()==5 and game.audio.music.stream.get_length()>15,"Original audio assets load and ambience loops")
	var hint:int=game.state.hint();var touch:=InputEventScreenTouch.new();touch.pressed=true;touch.index=0;touch.position=game.board.tile_rect(hint).get_center()
	game.board._unhandled_input(touch);check(game.state.moves==1,"Actual touch event rotates tile")
	var emulated:=InputEventMouseButton.new();emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=true;emulated.device=-1;emulated.position=touch.position
	game.board._unhandled_input(emulated);check(game.state.moves==1,"Emulated mouse cannot double-rotate touch")
	game.undo_move();check(game.state.moves==0,"Scene undo")
	game.position=Vector2(36,0);touch.position=game.board.tile_rect(hint).get_center()+game.position;game.board._unhandled_input(touch)
	check(game.state.moves==1,"Touch respects safe-area offset")
	game.undo_move();game.position=Vector2.ZERO
	game.request_hint();check(game.board.hint_index>=0 and game.state.moves==0,"Scene hint suggests only")
	game.tap_tile(game.state.hint());game.pause_game();check(game.screen=="pause","Pause screen")
	var paused_moves:int=game.state.moves;game.tap_tile(game.state.hint());check(game.state.moves==paused_moves,"Paused touch cannot mutate")
	game.resume_game();check(game.screen=="game","Resume")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);check(game.screen=="pause" and game.store.data.session.moves==paused_moves,"Lifecycle pauses and saves")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);check(game.screen=="pause","Lifecycle waits for explicit resume")
	game.resume_game();game.restart_level();check(game.state.moves==0,"Scene restart")
	for size in [Vector2(960,540),Vector2(1200,540),Vector2(960,600),Vector2(960,720)]:
		game.view=size;game.start_level(20)
		check(game.board.cell>=50,"Tap size at "+str(size))
		for i in game.state.tiles.size():
			var r:Rect2=game.board.tile_rect(i)
			check(game.board.area.encloses(r),"Board fits aspect "+str(size))
		check(game.board.index_at(game.board.tile_rect(17).get_center())==17,"Coordinate mapping across aspect")
	game.view=Vector2(960,540);game.start_level(1);game.tap_tile(game.state.hint())
	check(game.victory_time>=0 and game.store.data.results.has("1"),"Completion saved before celebration")
	check(game.screen=="game","Completion retains energized board")
	game._process(1.6);check(game.screen=="complete","Celebration transitions to result")
	game.start_level(2);game.tap_tile(game.state.hint());var before: Array=game.state.tiles.duplicate(true);game.continue_play()
	check(game.state.moves==1 and game.state.tiles==before and game.state.history.size()==1,"Continue restores board moves and undo")
	game.open_settings("pause");game.toggle_setting("music");check(game.store.data.settings.music,"Independent music toggle")
	game.toggle_setting("sfx");check(game.store.data.settings.sfx,"Independent SFX toggle")
	for i in 5:
		var extra: Dictionary=game.levels[0].duplicate(true);extra.id=21+i;game.levels.append(extra)
	game.store.level_count=game.levels.size();game.store.data.unlocked=25;game.levels_page=1;game.show_screen("levels")
	check(game.ui.get_child_count()>=8,"Additional level packs paginate without changing puzzle code")
	game.start_level(21);check(game.active_level==21,"Catalog length controls level loading")
	game.queue_free();await process_frame
	for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test-integration.json"+suffix))
	await create_timer(.1).timeout
	print("MINDFLIP TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
