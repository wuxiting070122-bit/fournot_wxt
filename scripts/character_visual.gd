extends AnimatedSprite2D
@export var character_id := "heroine"
var facing := 0
var walking := false
var breath_time := 0.0
static var cached: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	position = Vector2(-32,-62)
	if not cached.has(character_id):
		var frames := SpriteFrames.new()
		var sheet: Texture2D = load("res://assets/characters/%s.png" % character_id)
		for row in range(4):
			for action in ["walk","idle"]:
				var animation := "%s_%d" % [action,row]
				frames.add_animation(animation)
				frames.set_animation_speed(animation,12.0 if action=="walk" else 2.0)
				var columns: Array = [1,1,0,0,2,2,0,0] if action=="walk" else [3,4,3,5]
				if action == "walk" and row in [1,2] and character_id in ["shenzhi","linshao"]:
					# Equal half-cycles: contact A, side-on passing pose,
					# contact B, side-on passing pose. Column 1 turns frontward.
					columns = [0,0,3,3,2,2,3,3]
				for column in columns:
					var frame_texture := AtlasTexture.new()
					frame_texture.atlas = sheet
					frame_texture.region = Rect2(column*64,row*64,64,64)
					frames.add_frame(animation,frame_texture)
		cached[character_id] = frames
	sprite_frames = cached[character_id]
	play("idle_%d" % facing)

func set_motion(direction: Vector2, moving: bool) -> void:
	walking = moving
	if direction != Vector2.ZERO:
		if absf(direction.x)>absf(direction.y): facing=2 if direction.x>0 else 1
		else: facing=0 if direction.y>0 else 3
	var next_animation := "%s_%d" % ["walk" if walking else "idle",facing]
	if animation != next_animation: play(next_animation)

func _process(delta: float) -> void:
	breath_time += delta
	# Tiny chest-height change, anchored at the soles; collision never scales.
	var amount := 1.0 if walking else 1.0+sin(breath_time*TAU/2.8)*0.012
	scale.y = amount
	position.y = -62.0*amount
