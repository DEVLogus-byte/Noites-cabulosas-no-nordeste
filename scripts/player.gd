class_name Player
extends Node2D
## O jogador: anda, corre (faz barulho) e se esconde embaixo de móveis.
## `pos` é o ponto dos pés, em pixels do mundo.

const WALK := 46.0
const RUN := 76.0

var level
var pos := Vector2.ZERO
var facing := 0            # 0 baixo, 1 cima, 2 esquerda, 3 direita
var moving := false
var running := false
var hiding := false
var hide_obj = null
var pre_pos := Vector2.ZERO
var frozen := false
var falling := false
var fall_t := 0.0
var drop := 0.0            # animação de aterrissagem (altura em px)
var anim := 0.0

func _ready() -> void:
	position = pos.round()

func hitbox(p: Vector2) -> Rect2:
	return Rect2(p.x - 4.0, p.y - 3.0, 8.0, 6.0)

func is_noisy() -> bool:
	return running and moving and not hiding

func tick(delta: float) -> void:
	anim += delta
	if falling:
		fall_t += delta
	elif drop > 0.0:
		drop = maxf(0.0, drop - 240.0 * delta)
		if drop == 0.0:
			level.on_landed()
	elif not frozen and not hiding:
		_move(delta)
	else:
		moving = false
		running = false
	position = pos.round()
	queue_redraw()

func _move(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	moving = dir.length() > 0.1
	running = moving and Input.is_action_pressed("run")
	if not moving:
		return
	var spd := RUN if running else WALK
	var v := dir * spd * delta
	var np := pos + Vector2(v.x, 0.0)
	if not level.rect_blocked(hitbox(np)):
		pos = np
	np = pos + Vector2(0.0, v.y)
	if not level.rect_blocked(hitbox(np)):
		pos = np
	if absf(dir.x) > absf(dir.y):
		facing = 3 if dir.x > 0.0 else 2
	else:
		facing = 0 if dir.y > 0.0 else 1

func start_fall() -> void:
	falling = true
	fall_t = 0.0

func hide_in(f) -> void:
	hiding = true
	hide_obj = f
	pre_pos = pos
	pos = f.rect.get_center()
	f.occupied = true
	f.queue_redraw()
	moving = false
	running = false
	position = pos.round()

func leave_hide() -> void:
	var f = hide_obj
	var r: Rect2 = f.rect
	var cands: Array[Vector2] = [
		Vector2(clampf(pre_pos.x, r.position.x + 3.0, r.end.x - 3.0), r.end.y + 6.0),
		Vector2(clampf(pre_pos.x, r.position.x + 3.0, r.end.x - 3.0), r.position.y - 6.0),
		Vector2(r.position.x - 6.0, clampf(pre_pos.y, r.position.y + 3.0, r.end.y - 3.0)),
		Vector2(r.end.x + 6.0, clampf(pre_pos.y, r.position.y + 3.0, r.end.y - 3.0)),
	]
	var best := pre_pos
	var bd := INF
	for p in cands:
		if not level.rect_blocked(hitbox(p)):
			var d := p.distance_to(pre_pos)
			if d < bd:
				bd = d
				best = p
	pos = best
	hiding = false
	hide_obj = null
	f.occupied = false
	f.queue_redraw()
	position = pos.round()

func _draw() -> void:
	if hiding:
		return
	draw_rect(Rect2(-4, -1, 8, 3), Color(0, 0, 0, 0.35))      # sombra no chão
	var sc := 1.0
	var yo := -drop
	if falling:
		sc = maxf(0.05, 1.0 - fall_t / 0.9)
		yo += fall_t * 12.0
	draw_set_transform(Vector2(0, yo), 0.0, Vector2(sc, sc))

	var step := 0
	if moving:
		step = int(anim * (12.0 if running else 8.0)) % 2
	var lift_l := 1 if (moving and step == 0) else 0
	var lift_r := 1 if (moving and step == 1) else 0
	var pants := Color("2b2a3d")
	var shoe := Color("15121c")
	var coat := Color("3a78ad")
	var coat_d := Color("285a85")
	var skin := Color("f1c9a5")
	var hair := Color("4b2d1c")
	var dark := Color("1b1020")

	# pernas
	draw_rect(Rect2(-3, -4, 2, 4 - lift_l), pants)
	draw_rect(Rect2(1, -4, 2, 4 - lift_r), pants)
	draw_rect(Rect2(-3, -1 - lift_l, 2, 1), shoe)
	draw_rect(Rect2(1, -1 - lift_r, 2, 1), shoe)
	# casaco
	draw_rect(Rect2(-4, -10, 8, 7), coat)
	draw_rect(Rect2(-4, -5, 8, 1), coat_d)
	draw_rect(Rect2(-5, -9, 1, 5), coat_d)
	draw_rect(Rect2(4, -9, 1, 5), coat_d)
	# cabeça
	draw_rect(Rect2(-3, -15, 6, 6), skin)
	match facing:
		0:
			draw_rect(Rect2(-3, -16, 6, 2), hair)
			draw_rect(Rect2(-4, -15, 1, 3), hair)
			draw_rect(Rect2(3, -15, 1, 3), hair)
			draw_rect(Rect2(-2, -12, 1, 2), dark)
			draw_rect(Rect2(1, -12, 1, 2), dark)
		1:
			draw_rect(Rect2(-4, -16, 8, 7), hair)
		2:
			draw_rect(Rect2(-3, -16, 6, 2), hair)
			draw_rect(Rect2(0, -15, 4, 5), hair)
			draw_rect(Rect2(-2, -12, 1, 2), dark)
		3:
			draw_rect(Rect2(-3, -16, 6, 2), hair)
			draw_rect(Rect2(-4, -15, 4, 5), hair)
			draw_rect(Rect2(1, -12, 1, 2), dark)
	# lanterninha na mão
	var lx := 5
	var ly := -6
	match facing:
		1:
			lx = -7
		2:
			lx = -8
	draw_rect(Rect2(lx, ly, 3, 3), Color("ffd966"))
	draw_rect(Rect2(lx + 1, ly - 1, 1, 1), Color("8a6a1c"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
