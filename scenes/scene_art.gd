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

func _draw_cloud(center: Vector2, scale: float, color: Color) -> void:
	draw_circle(center, scale * 1.0, color)
	draw_circle(center + Vector2(scale * 0.9, scale * 0.1), scale * 0.75, color)
	draw_circle(center + Vector2(-scale * 0.9, scale * 0.15), scale * 0.7, color)
	draw_circle(center + Vector2(scale * 0.3, -scale * 0.4), scale * 0.6, color)

func _draw_bird(center: Vector2, scale: float, color: Color) -> void:
	draw_line(center, center + Vector2(-scale, -scale * 0.6), color, scale * 0.08, false)
	draw_line(center, center + Vector2(scale, -scale * 0.6), color, scale * 0.08, false)

func _draw_lantern(center: Vector2, scale: float, glow_color: Color) -> void:
	draw_line(center - Vector2(0, scale * 1.4), center - Vector2(0, scale * 0.6), Color(0.2, 0.15, 0.1), 1.5)
	draw_circle(center, scale * 0.55, glow_color)
	draw_circle(center, scale * 0.55, Color(0.15, 0.05, 0.05, 0.6))
	draw_rect(Rect2(center - Vector2(scale * 0.08, scale * 0.55), Vector2(scale * 0.16, scale * 1.1)), Color(0.15, 0.05, 0.05, 0.5))

func _draw_mist_band(size: Vector2, y_ratio: float, height_ratio: float, color: Color) -> void:
	draw_rect(Rect2(Vector2(0, size.y * y_ratio), Vector2(size.x, size.y * height_ratio)), color)

func _draw_bamboo(base: Vector2, height: float, color: Color) -> void:
	draw_line(base, base - Vector2(0, height), color, 4.0)
	var segments := 4
	for i in range(1, segments):
		var y := base.y - height * (float(i) / segments)
		draw_line(Vector2(base.x - 4, y), Vector2(base.x + 4, y), color.darkened(0.2), 2.0)
	draw_circle(base - Vector2(0, height), 6.0, color.lightened(0.2))

func _draw_mountain_gate(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.85, 0.4, 0.55), Color(1.0, 0.72, 0.35))

	# Sun disc with soft halo
	var sun_center := Vector2(size.x * 0.8, size.y * 0.25)
	draw_circle(sun_center, size.y * 0.14, Color(1.0, 0.85, 0.5, 0.25))
	draw_circle(sun_center, size.y * 0.09, Color(1.0, 0.95, 0.55, 0.95))

	# Drifting clouds
	_draw_cloud(Vector2(size.x * 0.2, size.y * 0.18), size.y * 0.05, Color(1.0, 0.9, 0.85, 0.55))
	_draw_cloud(Vector2(size.x * 0.5, size.y * 0.12), size.y * 0.04, Color(1.0, 0.9, 0.85, 0.45))
	_draw_cloud(Vector2(size.x * 0.65, size.y * 0.3), size.y * 0.035, Color(1.0, 0.85, 0.8, 0.4))

	# A pair of distant birds
	_draw_bird(Vector2(size.x * 0.35, size.y * 0.15), size.y * 0.02, Color(0.2, 0.1, 0.15, 0.8))
	_draw_bird(Vector2(size.x * 0.4, size.y * 0.2), size.y * 0.015, Color(0.2, 0.1, 0.15, 0.7))

	# Far mountain silhouette
	var far_points := PackedVector2Array([
		Vector2(0, size.y * 0.5),
		Vector2(size.x * 0.15, size.y * 0.38),
		Vector2(size.x * 0.35, size.y * 0.48),
		Vector2(size.x * 0.55, size.y * 0.32),
		Vector2(size.x * 0.8, size.y * 0.45),
		Vector2(size.x, size.y * 0.4),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(far_points, Color(0.55, 0.4, 0.55, 0.45))

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

	# Mist band between the mountain layers
	_draw_mist_band(size, 0.55, 0.06, Color(1.0, 0.95, 0.9, 0.2))

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

	# Ground mist rolling at the base
	_draw_mist_band(size, 0.85, 0.06, Color(1.0, 0.95, 0.9, 0.25))

	# Stone steps leading to the gate
	for i in range(5):
		var step_y := size.y * (0.88 + i * 0.024)
		var step_w := size.x * (0.5 - i * 0.03)
		draw_rect(Rect2(Vector2(size.x * 0.5 - step_w * 0.5, step_y), Vector2(step_w, size.y * 0.02)), Color(0.3, 0.25, 0.22))

	# Gate pillars with banners
	var pillar_w := size.x * 0.04
	var pillar_h := size.y * 0.4
	var pillar_y := size.y - pillar_h
	draw_rect(Rect2(Vector2(size.x * 0.35, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.55, 0.12, 0.14))
	draw_rect(Rect2(Vector2(size.x * 0.6, pillar_y), Vector2(pillar_w, pillar_h)), Color(0.55, 0.12, 0.14))
	draw_rect(Rect2(Vector2(size.x * 0.33, pillar_y - size.y * 0.05), Vector2(size.x * 0.34, size.y * 0.05)), Color(0.85, 0.65, 0.15))

	# Hanging banners on each pillar
	draw_rect(Rect2(Vector2(size.x * 0.35, pillar_y + size.y * 0.02), Vector2(pillar_w * 0.9, size.y * 0.12)), Color(0.75, 0.15, 0.15, 0.85))
	draw_rect(Rect2(Vector2(size.x * 0.6, pillar_y + size.y * 0.02), Vector2(pillar_w * 0.9, size.y * 0.12)), Color(0.75, 0.15, 0.15, 0.85))

	# Small lanterns flanking the gate
	_draw_lantern(Vector2(size.x * 0.3, pillar_y + size.y * 0.1), size.y * 0.03, Color(1.0, 0.7, 0.3, 0.9))
	_draw_lantern(Vector2(size.x * 0.68, pillar_y + size.y * 0.1), size.y * 0.03, Color(1.0, 0.7, 0.3, 0.9))

func _draw_sect_hall(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.55, 0.35, 0.75), Color(1.0, 0.75, 0.45))

	_draw_cloud(Vector2(size.x * 0.15, size.y * 0.15), size.y * 0.045, Color(1.0, 0.85, 0.9, 0.5))
	_draw_cloud(Vector2(size.x * 0.85, size.y * 0.2), size.y * 0.04, Color(1.0, 0.85, 0.9, 0.45))

	# Floor with subtle tile lines
	draw_rect(Rect2(Vector2(0, size.y * 0.8), Vector2(size.x, size.y * 0.2)), Color(0.4, 0.25, 0.5))
	for i in range(8):
		var lx := size.x * (float(i) / 8.0)
		draw_line(Vector2(lx, size.y * 0.8), Vector2(lx, size.y), Color(0.3, 0.18, 0.38, 0.6), 1.5)

	# Distant secondary rooftops peeking behind the main hall
	var side_roof_points := PackedVector2Array([
		Vector2(size.x * 0.02, size.y * 0.52),
		Vector2(size.x * 0.14, size.y * 0.38),
		Vector2(size.x * 0.26, size.y * 0.52)
	])
	draw_colored_polygon(side_roof_points, Color(0.45, 0.15, 0.2, 0.75))
	var side_roof_points_r := PackedVector2Array([
		Vector2(size.x * 0.74, size.y * 0.52),
		Vector2(size.x * 0.86, size.y * 0.38),
		Vector2(size.x * 0.98, size.y * 0.52)
	])
	draw_colored_polygon(side_roof_points_r, Color(0.45, 0.15, 0.2, 0.75))

	# Main hall roof (pagoda-style)
	var roof_points := PackedVector2Array([
		Vector2(size.x * 0.1, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.15),
		Vector2(size.x * 0.9, size.y * 0.45),
		Vector2(size.x * 0.75, size.y * 0.45),
		Vector2(size.x * 0.5, size.y * 0.3),
		Vector2(size.x * 0.25, size.y * 0.45)
	])
	draw_colored_polygon(roof_points, Color(0.6, 0.1, 0.15))

	# Roof ridge highlight and upturned eave tips
	draw_line(Vector2(size.x * 0.5, size.y * 0.15), Vector2(size.x * 0.5, size.y * 0.3), Color(0.85, 0.65, 0.2), 3.0)
	draw_circle(Vector2(size.x * 0.1, size.y * 0.45), 5.0, Color(0.85, 0.65, 0.2))
	draw_circle(Vector2(size.x * 0.9, size.y * 0.45), 5.0, Color(0.85, 0.65, 0.2))

	# Hall body with a doorway
	draw_rect(Rect2(Vector2(size.x * 0.2, size.y * 0.45), Vector2(size.x * 0.6, size.y * 0.35)), Color(0.75, 0.35, 0.2))
	draw_rect(Rect2(Vector2(size.x * 0.46, size.y * 0.6), Vector2(size.x * 0.08, size.y * 0.2)), Color(0.2, 0.08, 0.06))

	# Pillars
	for i in range(3):
		var px := size.x * (0.28 + i * 0.22)
		draw_rect(Rect2(Vector2(px, size.y * 0.5), Vector2(size.x * 0.03, size.y * 0.3)), Color(0.85, 0.65, 0.2))

	# Hanging lanterns along the eaves
	_draw_lantern(Vector2(size.x * 0.3, size.y * 0.47), size.y * 0.025, Color(1.0, 0.8, 0.4, 0.9))
	_draw_lantern(Vector2(size.x * 0.5, size.y * 0.44), size.y * 0.025, Color(1.0, 0.8, 0.4, 0.9))
	_draw_lantern(Vector2(size.x * 0.7, size.y * 0.47), size.y * 0.025, Color(1.0, 0.8, 0.4, 0.9))

	# Incense smoke curling near the doorway
	for i in range(4):
		var t := float(i) / 4.0
		draw_circle(Vector2(size.x * 0.5 + sin(t * 6.0) * 4.0, size.y * (0.6 - t * 0.1)), 2.5 - t * 1.5, Color(0.9, 0.9, 0.9, 0.3 - t * 0.05))

func _draw_character_creation(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.1, 0.08, 0.3), Color(0.55, 0.25, 0.55))

	# Crescent moon (drawn as a bright disc with a shadow disc offset to carve the crescent look)
	var moon_center := Vector2(size.x * 0.75, size.y * 0.22)
	var moon_radius := size.y * 0.1
	draw_circle(moon_center, moon_radius * 1.6, Color(1.0, 0.95, 0.8, 0.15))
	draw_circle(moon_center, moon_radius, Color(1.0, 0.95, 0.75, 0.95))
	draw_circle(moon_center + Vector2(moon_radius * 0.4, -moon_radius * 0.15), moon_radius * 0.9, Color(0.1, 0.08, 0.3, 1.0))

	# Scattered stars, plus a few brighter "twinkle" stars
	var star_positions := PackedVector2Array([
		Vector2(0.08, 0.15), Vector2(0.18, 0.35), Vector2(0.3, 0.1),
		Vector2(0.45, 0.28), Vector2(0.55, 0.08), Vector2(0.65, 0.4),
		Vector2(0.85, 0.12), Vector2(0.95, 0.3), Vector2(0.4, 0.5),
		Vector2(0.12, 0.55), Vector2(0.25, 0.62), Vector2(0.05, 0.4)
	])
	for i in star_positions.size():
		var star = star_positions[i]
		var r := 2.0 if i % 3 != 0 else 3.0
		draw_circle(Vector2(size.x * star.x, size.y * star.y), r, Color(1.0, 1.0, 0.9, 0.85))

	# A faint shooting star streak
	draw_line(Vector2(size.x * 0.15, size.y * 0.05), Vector2(size.x * 0.28, size.y * 0.12), Color(1.0, 1.0, 0.9, 0.5), 1.5)

	# Distant mountain silhouette, layered
	var far_mountain_points := PackedVector2Array([
		Vector2(0, size.y * 0.6),
		Vector2(size.x * 0.3, size.y * 0.5),
		Vector2(size.x * 0.6, size.y * 0.58),
		Vector2(size.x, size.y * 0.5),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(far_mountain_points, Color(0.18, 0.12, 0.3, 0.6))

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

	# A cluster of bamboo silhouettes framing the scene
	_draw_bamboo(Vector2(size.x * 0.08, size.y * 0.88), size.y * 0.28, Color(0.08, 0.1, 0.12))
	_draw_bamboo(Vector2(size.x * 0.14, size.y * 0.9), size.y * 0.22, Color(0.08, 0.1, 0.12))
	_draw_bamboo(Vector2(size.x * 0.92, size.y * 0.88), size.y * 0.26, Color(0.08, 0.1, 0.12))

	# Fireflies / floating spirit motes drifting near the figure
	var motes := PackedVector2Array([
		Vector2(0.42, 0.7), Vector2(0.58, 0.68), Vector2(0.48, 0.78), Vector2(0.53, 0.6)
	])
	for m in motes:
		draw_circle(Vector2(size.x * m.x, size.y * m.y), 2.5, Color(0.8, 0.9, 1.0, 0.7))

	# A lone figure silhouette, standing at the edge, contemplating their fate
	var figure_x := size.x * 0.5
	var figure_base_y := size.y * 0.85
	draw_rect(Rect2(Vector2(figure_x - size.x * 0.012, figure_base_y - size.y * 0.18), Vector2(size.x * 0.024, size.y * 0.18)), Color(0.05, 0.04, 0.1))
	draw_circle(Vector2(figure_x, figure_base_y - size.y * 0.2), size.y * 0.025, Color(0.05, 0.04, 0.1))

func _draw_fallback(size: Vector2) -> void:
	_draw_sky_gradient(size, Color(0.5, 0.3, 0.65), Color(0.85, 0.5, 0.55))
	_draw_cloud(Vector2(size.x * 0.3, size.y * 0.25), size.y * 0.05, Color(1.0, 0.9, 0.9, 0.4))
	_draw_cloud(Vector2(size.x * 0.7, size.y * 0.35), size.y * 0.04, Color(1.0, 0.9, 0.9, 0.35))
