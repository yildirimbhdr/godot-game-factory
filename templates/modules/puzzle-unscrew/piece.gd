class_name Piece
extends RigidBody2D
## One piece of the figure: a polygon drawn in the game's style with its own physics body.
## Held by its screws (pin joints to the world). With two or more it stays put; with one left it
## swings on it; with none it falls and collides with pieces of its own plane.

const OUTLINE := Color("5B4B8A")

var plane := 0
var screws: Array[Screw] = []
var fill := Color.WHITE
var released := false
var _poly := PackedVector2Array()
var _cover := PackedVector2Array()
var _holes := PackedVector2Array()


## `world_poly` and `world_holes` are in world pixels; the body is placed at the polygon's bounds centre.
func setup(world_poly: PackedVector2Array, world_holes: PackedVector2Array, plane_index: int, fill_color: Color) -> void:
	plane = plane_index
	fill = fill_color
	var bounds := Rect2(world_poly[0], Vector2.ZERO)
	for p in world_poly:
		bounds = bounds.expand(p)
	var center := bounds.get_center()
	position = center
	_poly = PackedVector2Array()
	for p in world_poly:
		_poly.append(p - center)
	_holes = PackedVector2Array()
	for h in world_holes:
		_holes.append(h - center)
	var grown := Geometry2D.offset_polygon(_poly, 18.0, Geometry2D.JOIN_ROUND)
	_cover = grown[0] if not grown.is_empty() else _poly

	collision_layer = 1 << plane
	collision_mask = 1 << plane
	gravity_scale = 2.2
	linear_damp = 0.15
	angular_damp = 0.4
	var mat := PhysicsMaterial.new()
	mat.friction = 0.7
	mat.bounce = 0.15
	physics_material_override = mat
	z_index = plane * 10
	var shape := CollisionPolygon2D.new()
	shape.polygon = _poly
	add_child(shape)
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	queue_redraw()


func _draw() -> void:
	var shadow := PackedVector2Array()
	for p in _poly:
		shadow.append(p + Vector2(0, 9))
	draw_colored_polygon(shadow, Color(OUTLINE, 0.28))
	draw_colored_polygon(_poly, fill.darkened(0.14))
	for inner in Geometry2D.offset_polygon(_poly, -7.0, Geometry2D.JOIN_ROUND):
		var lifted := PackedVector2Array()
		for p in inner:
			lifted.append(p + Vector2(0, -3))
		draw_colored_polygon(lifted, fill)
	var closed := _poly.duplicate()
	closed.append(_poly[0])
	draw_polyline(closed, OUTLINE, 7.0, true)
	# glossy edge: bright strokes where the outline faces up-left
	for inner in Geometry2D.offset_polygon(_poly, -14.0, Geometry2D.JOIN_ROUND):
		for i in inner.size():
			var a: Vector2 = inner[i]
			var b: Vector2 = inner[(i + 1) % inner.size()]
			var normal := (b - a).orthogonal().normalized()
			if (b - a).length() > 18.0 and normal.dot(Vector2(-0.7, -0.7)) > 0.55:
				draw_line(a, b, Color(1, 1, 1, 0.65), 6.0, true)
	for h in _holes:
		draw_circle(h, Screw.R * 0.9, Color(OUTLINE, 0.5))
		draw_arc(h, Screw.R * 0.9, 0.0, TAU, 32, Color(OUTLINE, 0.9), 4.0, true)


func covers(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_point), _cover)


## Remove a screw: drop its joint; with one or none left the plate becomes dynamic.
func detach(screw: Screw) -> void:
	screws.erase(screw)
	if is_instance_valid(screw.joint):
		screw.joint.queue_free()
	screw.joint = null
	screw.plate = null
	if screws.size() <= 1:
		freeze = false
		sleeping = false
	if screws.is_empty():
		released = true
