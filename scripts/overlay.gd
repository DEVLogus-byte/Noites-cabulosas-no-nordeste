class_name Overlay
extends Node2D
## Camada entre o chão e os objetos: cones de visão dos capangas, anel de barulho e a chave.

var level

func _process(_delta: float) -> void:
	queue_redraw()

static func draw_key(ci: CanvasItem, p: Vector2) -> void:
	var gold := Color("f2c94c")
	ci.draw_rect(Rect2(p.x - 4, p.y - 9, 5, 5), gold)
	ci.draw_rect(Rect2(p.x - 3, p.y - 8, 3, 3), Color("8a6a1c"))
	ci.draw_rect(Rect2(p.x + 1, p.y - 8, 7, 2), gold)
	ci.draw_rect(Rect2(p.x + 5, p.y - 6, 2, 2), gold)
	ci.draw_rect(Rect2(p.x + 3, p.y - 6, 1, 2), gold)

func _draw() -> void:
	if level == null:
		return
	for m in level.monsters:
		_cone(m)
	var pl = level.player
	if pl.is_noisy():
		var r := fposmod(level.time * 50.0, 40.0) + 8.0
		draw_arc(pl.pos, r, 0.0, TAU, 24, Color(1, 1, 1, 0.16), 1.0)
		draw_arc(pl.pos, Monster.NOISE_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.05), 1.0)
	if not level.key_taken and level.data.key.x >= 0:
		var kp: Vector2 = level.key_pos
		var bob := sin(level.time * 3.0) * 1.5
		draw_circle(kp + Vector2(0, -3), 8.0 + sin(level.time * 5.0), Color(1.0, 0.85, 0.3, 0.12))
		draw_key(self, kp + Vector2(0, bob))

func _cone(m) -> void:
	var pts := PackedVector2Array()
	pts.append(m.pos)
	var n := 12
	for i in range(n + 1):
		var a: float = m.facing - Monster.HALF_FOV + (2.0 * Monster.HALF_FOV) * float(i) / float(n)
		var dir := Vector2.from_angle(a)
		var dist := Monster.VISION
		var t := 4.0
		while t <= Monster.VISION:
			if level.is_opaque_at(m.pos + dir * t):
				dist = maxf(t - 4.0, 3.0)
				break
			t += 4.0
		pts.append(m.pos + dir * dist)
	var col := Color(1.0, 0.95, 0.5, 0.13)
	if m.state == Monster.S.CHASE:
		col = Color(1.0, 0.2, 0.2, 0.22)
	elif m.state != Monster.S.PATROL or m.awareness > 0.05:
		col = Color(1.0, 0.65, 0.25, 0.18)
	draw_colored_polygon(pts, col)
