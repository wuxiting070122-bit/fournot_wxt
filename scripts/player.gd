extends CharacterBody2D

@export var speed := 175.0
var active := true
var facing := 0
var sprite: AnimatedSprite2D

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 20)
	collider.position = Vector2(0, -8)
	collider.shape = shape
	add_child(collider)
	var visual_root := Node2D.new()
	visual_root.scale = Vector2(1.8,1.8)
	add_child(visual_root)
	sprite = preload("res://scripts/character_visual.gd").new()
	visual_root.add_child(sprite)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if active:
		direction.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		direction.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	velocity = direction.normalized() * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = 2 if direction.x > 0 else 1
		else:
			facing = 0 if direction.y > 0 else 3
	sprite.set_motion(direction, get_position_delta().length_squared() > 0.01)

func _draw() -> void:
	draw_ellipse_shadow()

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.34))
	draw_set_transform(Vector2.ZERO)
