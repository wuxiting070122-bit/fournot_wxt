extends RefCounted
const CELL := 16.0
var grid := AStarGrid2D.new()
var walls: Array = []
func rebuild(rectangles: Array) -> void:
	walls = rectangles.duplicate()
	grid.region = Rect2i(0,0,192,128)
	grid.cell_size = Vector2(CELL,CELL)
	grid.offset = Vector2(8,8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(192):
		for y in range(128):
			var p := Vector2(x*CELL+8,y*CELL+8)
			for rect in walls:
				# Feet origin: collider extends 22 sideways, 18 up and 2 down.
				if Rect2(rect.position-Vector2(24,4),rect.size+Vector2(48,24)).has_point(p):
					grid.set_point_solid(Vector2i(x,y))
					break
func cell(at: Vector2) -> Vector2i:
	var start := Vector2i(floor(at.x/CELL),floor(at.y/CELL))
	for radius in range(12):
		var closest := Vector2i(-1,-1)
		var distance := INF
		for x in range(start.x-radius,start.x+radius+1):
			for y in range(start.y-radius,start.y+radius+1):
				var candidate := Vector2i(x,y)
				if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate): continue
				var d := at.distance_squared_to(grid.get_point_position(candidate))
				if d < distance: distance=d; closest=candidate
		if closest.x >= 0: return closest
	return Vector2i(-1,-1)
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := cell(from)
	var b := cell(to)
	if a.x < 0 or b.x < 0: return PackedVector2Array()
	return grid.get_point_path(a,b)
