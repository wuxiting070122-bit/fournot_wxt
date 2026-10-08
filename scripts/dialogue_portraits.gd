extends Control

const TOP := 83.0
const WAIST := 523.0
const CENTER := 640.0
var portrait: TextureRect
var fade: Tween
var definitions: Dictionary
var character_id := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(0, TOP)
	size = Vector2(1280, WAIST - TOP)
	clip_contents = true
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/portraits.json"))
	portrait = TextureRect.new()
	portrait.name = "SpeakingPortrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Preserve the supplied image colors and native alpha without color keying.
	add_child(portrait)
	portrait.hide()

func identify(speaker: String) -> String:
	if speaker.begins_with("你") or speaker.begins_with("画家"): return "heroine"
	if speaker.begins_with("林梢") or speaker.begins_with("大小姐"): return "linshao"
	if speaker.begins_with("沈知") or speaker.begins_with("作家"): return "shenzhi"
	if speaker.begins_with("晚晚") or speaker.begins_with("女学生"): return "wanwan"
	if speaker.begins_with("阿野") or speaker.begins_with("云野") or speaker.begins_with("男学生") or speaker.begins_with("男大学生"): return "aye"
	if speaker.begins_with("小鹿") or speaker.begins_with("鹿雯雯") or speaker.begins_with("女主播") or speaker.begins_with("女网红"): return "xiaolu"
	if speaker.begins_with("老周") or speaker.begins_with("律师") or speaker.begins_with("周律师"): return "laozhou"
	return ""

func show_speaker(speaker: String, _has_world: bool) -> void:
	var next_id := identify(speaker)
	if is_instance_valid(fade): fade.kill()
	if next_id.is_empty():
		character_id = ""
		portrait.hide()
		return
	var changed := next_id != character_id or not portrait.visible
	character_id = next_id
	var config: Dictionary = definitions[character_id]
	portrait.texture = load(config.texture)
	var factor := (WAIST - TOP) / (float(config.waist_y) - float(config.head_y))
	portrait.size = portrait.texture.get_size() * factor
	portrait.position = Vector2(CENTER - float(config.center_x) * factor, -float(config.head_y) * factor)
	portrait.show()
	portrait.modulate = Color(1, 1, 1, 0 if changed else 1)
	fade = create_tween()
	fade.tween_property(portrait, "modulate:a", 1.0, 0.16)
