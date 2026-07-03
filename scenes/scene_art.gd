extends Control
class_name SceneArt

var _backdrop: String = "mountain_gate"

func set_backdrop(key: String) -> void:
	_backdrop = key
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	match _backdrop:
		"mountain_gate":
			_draw_mountain_gate(size)
		"sect_hall":
			_draw_sect_hall(size)
		"character_creation":
			_draw_character_creation(size)
		_:
			_draw_fallback(size)

func _draw_sky_gradient(size: Vector2, top_color: Color, bottom_color: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), top_color)
	var band_count := 24
	for i in band_count:
		var t := float(i) / band_count
		var c := top_color.lerp(bottom_color, t)
		var y := size.y * t
		var h := size.y / band_count + 1.0
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, h)), c)

func _draw_mountain_gate(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.85, 0.4, 0.55), Color(1.0, 0.72, 0.35))
	draw_circle(Vector2(size.x * 0.8, size.y * 0.25), size.y * 0.09, Color(1.0, 0.95, 0.55, 0.95))

	var back_points := PackedVector2Array([
		Vector2(0, size.y * 0.55),
		Vector2(size.x * 0.2, size.y * 0.35),
		Vector2(size.x * 0.45, size.y * 0.5),
		Vector2(size.x * 0.7, size.y * 0.3),
		Vector2(size.x, size.y * 0.5),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(back_points, Color(0.35, 0.3, 0.55, 0.7))

	var front_points := PackedVector2Array([
		Vector2(0, size.y * 0.75),
		Vector2(size.x * 0.3, size.y * 0.5),
		Vector2(size.x * 0.55, size.y * 0.7),
		Vector2(size.x * 0.8, size.y * 0.45),
		Vector2(size.x, size.y * 0.65),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(front_points, Color(0.15, 0.1, 0.28))

	var pillar_w := size.x * 0.04
	var pillar_h := size.y * 0.4
	var pillar_y := size.y - pillar_h
	draw_rect(Rect2(Vector2(size.x * 0.35, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.55, 0.12, 0.14))
	draw_rect(Rect2(Vector2(size.x * 0.6, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.55, 0.12, 0.14))
	draw_rect(Rect2(Vector2(size.x * 0.33, pillar_y - size.y * 0.05), Vector2(size.x * 0.34, size.y * 0.05)), Color(0.85, 0.65, 0.15))

func _draw_sect_hall(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.55, 0.35, 0.75), Color(1.0, 0.75, 0.45))
	draw_rect(Rect2(Vector2(0, size.y * 0.8), Vector2(size.x, size.y * 0.2)), Color(0.4, 0.25, 0.5))

	var roof_points := PackedVector2Array([
		Vector2(size.x * 0.1, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.15),
		Vector2(size.x * 0.9, size.y * 0.45),
		Vector2(size.x * 0.75, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.3),
		Vector2(size.x * 0.25, size.y * 0.45)
	])
	draw_colored_polygon(roof_points, Color(0.6, 0.1, 0.15))
	draw_rect(Rect2(Vector2(size.x * 0.2, size.y * 0.45), Vector2(size.x * 0.6, size.y * 0.35)), Color(0.75, 0.35, 0.2))

	for i in range(3):
		var px := size.x * (0.28 + i * 0.22)
		draw_rect(Rect2(Vector2(px, size.y * 0.5), Vector2(size.x * 0.03, size.y * 0.3)), Color(0.85, 0.65, 0.2))

func _draw_character_creation(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.1, 0.08, 0.3), Color(0.55, 0.25, 0.55))

	# Crescent moon (drawn as a bright disc with a shadow disc offset to carve the crescent look)
	var moon_center := Vector2(size.x * 0.75, size.y * 0.22)
	var moon_radius := size.y * 0.1
	draw_circle(moon_center, moon_radius, Color(1.0, 0.95, 0.75, 0.95))
	draw_circle(moon_center + Vector2(moon_radius * 0.4, -moon_radius * 0.15), moon_radius * 0.9, Color(0.1, 0.08, 0.3, 1.0))

	# Scattered stars
	var star_positions := PackedVector2Array([
		Vector2(0.08, 0.15), Vector2(0.18, 0.35), Vector2(0.3, 0.1),
		Vector2(0.45, 0.28), Vector2(0.55, 0.08), Vector2(0.65, 0.4),
		Vector2(0.85, 0.12), Vector2(0.95, 0.3), Vector2(0.4, 0.5)
	])
	for star in star_positions:
		draw_circle(Vector2(size.x * star.x, size.y * star.y), 2.0, Color(1.0, 1.0, 0.9, 0.85))

	# Distant mountain silhouette
	var mountain_points := PackedVector2Array([
		Vector2(0, size.y * 0.7),
		Vector2(size.x * 0.25, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.65),
		Vector2(size.x * 0.75, size.y * 0.4),
		Vector2(size.x, size.y * 0.6),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(mountain_points, Color(0.12, 0.08, 0.22))

	# A lone figure silhouette, standing at the edge, contemplating their fate
	var figure_x := size.x * 0.5
	var figure_base_y := size.y * 0.85
	draw_rect(Rect2(Vector2(figure_x - size.x * 0.012, figure_base_y - size.y * 0.18), Vector2(size.x * 0.024, size.y * 0.18)), Color(0.05, 0.04, 0.1))
	draw_circle(Vector2(figure_x, figure_base_y - size.y * 0.2), size.y * 0.025, Color(0.05, 0.04, 0.1))

func _draw_fallback(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.5, 0.3, 0.65), Color(0.85, 0.5, 0.55))
