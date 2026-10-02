extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))[19]
	var start:=Time.get_ticks_usec()
	for i in 10000: PuzzleRules.evaluate(level.tiles,int(level.width),int(level.height))
	print("Logic: level 20, 10000 evaluations, average %.2f us"%((Time.get_ticks_usec()-start)/10000.0))
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.store.path="user://benchmark.json";game.start_level(20)
	for i in 60:await process_frame
	var times: Array=[];var drawcalls: Array=[];start=Time.get_ticks_usec()
	for i in 180:
		await process_frame
		times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		drawcalls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var elapsed:float=(Time.get_ticks_usec()-start)/1000000.0
	times.sort();drawcalls.sort()
	print("Native %s: %.1f measured frames/sec, median CPU frame %.3f ms, median draw calls %d, static memory %.1f MiB"%[root.size,180/elapsed,times[90],drawcalls[90],Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0])
	game.queue_free();await process_frame;await create_timer(.1).timeout
	for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://benchmark.json"+suffix))
	quit()
