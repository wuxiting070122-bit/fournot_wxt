extends SceneTree
const Save = preload("res://scripts/checkpoint.gd")
const PATH := "user://checkpoint_process_probe.json"
func _initialize() -> void:
	if "--write-probe" in OS.get_cmdline_user_args():
		assert(Save.write_save({"version":1,"stage":"meeting","group":1,"notes":"跨进程核对"},PATH))
		print("CHECKPOINT WRITE PASS")
	else:
		var data := Save.read_save(PATH)
		assert(data.stage=="meeting" and data.group==1 and data.notes=="跨进程核对")
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
		print("CHECKPOINT NEW PROCESS READ PASS")
	quit()
