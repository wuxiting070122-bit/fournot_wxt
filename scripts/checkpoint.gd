extends RefCounted
const PATH := "user://checkpoint.json"
static func read_save(path: String = PATH) -> Dictionary:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK: continue
		var data = parser.data
		if not data is Dictionary: continue
		if int(data.get("version",0)) not in [1,2] or data.get("stage") not in ["bedroom","hallway","cold","meeting","vote"]: continue
		if not data.get("group",null) is float and not data.get("group",null) is int: continue
		if int(data.group)< -1 or int(data.group)>2: continue
		if data.stage in ["cold","meeting","vote"] and int(data.group)<0: continue
		if not data.get("notes",null) is String: continue
		return data
	return {}

static func write_save(data: Dictionary, path: String = PATH) -> bool:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(path) and not read_save(path).is_empty():
		DirAccess.copy_absolute(path,path+".bak")
	return DirAccess.rename_absolute(path+".tmp",path)==OK
