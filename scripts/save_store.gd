class_name SaveStore
extends RefCounted

var level_count := 20
var path := "user://mindflip.json"
var data := {"version":1,"unlocked":1,"results":{},"settings":{"music":true,"sfx":true},"session":{}}

func load_data() -> void:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK: continue
		var value = parser.data
		if value is Dictionary and value.get("version") == 1 and value.get("results") is Dictionary and value.get("settings") is Dictionary:
			data.unlocked = clampi(int(value.get("unlocked",1)),1,level_count)
			data.results = {}
			for key in value.results:
				var result = value.results[key]
				if str(key).is_valid_int() and int(key) in range(1,level_count+1) and result is Dictionary and (result.get("moves") is float or result.get("moves") is int) and (result.get("stars") is float or result.get("stars") is int):
					data.results[str(int(key))] = {"moves":maxi(0,int(result.moves)),"stars":clampi(int(result.stars),1,3)}
			data.settings.music = bool(value.settings.get("music",true))
			data.settings.sfx = bool(value.settings.get("sfx",true))
			data.session = value.get("session",{}) if value.get("session",{}) is Dictionary else {}
			return

func persist() -> bool:
	var file := FileAccess.open(path + ".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"): DirAccess.remove_absolute(absolute + ".bak")
		DirAccess.rename_absolute(absolute,absolute + ".bak")
	return DirAccess.rename_absolute(absolute + ".tmp",absolute) == OK

func record(level: int, moves: int, par: int) -> Dictionary:
	var key := str(level)
	var old: Dictionary = data.results.get(key,{"moves":99999,"stars":0})
	var result := {"moves":mini(moves,int(old.moves)),"stars":maxi(PuzzleRules.stars(moves,par),int(old.stars))}
	data.results[key] = result
	data.unlocked = maxi(int(data.unlocked), mini(level+1,level_count))
	data.session = {}
	persist()
	return result

func checkpoint(state: PuzzleState) -> void:
	data.session = {"level":state.level.id,"tiles":state.tiles,"moves":state.moves,"history":state.history}
	persist()
