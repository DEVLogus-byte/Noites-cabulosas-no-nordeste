class_name Monster
extends Node2D
## Capanga do Lampião (cangaceiro) com IA de patrulha, visão em cone, audição e perseguição.
##
## PATROL      -> segue a rota de pontos
## INVESTIGATE -> ouviu barulho (jogador correndo): vai até lá e olha em volta
## CHASE       -> viu o jogador por tempo suficiente: persegue (use E para sumir de vista!)
## SEARCH      -> perdeu o jogador de vista: vai ao último lugar visto e procura

enum S { PATROL, INVESTIGATE, CHASE, SEARCH }

const VISION := 82.0            # alcance da visão (px)
const HALF_FOV := 0.62          # metade do ângulo do cone (rad) ~ 35 graus
const CLOSE_RANGE := 13.0       # abaixo disso ele "sente" o jogador mesmo de costas
const NOISE_RADIUS := 62.0      # raio em que ouve o jogador correndo
const PATROL_SPEED := 24.0
const INVESTIGATE_SPEED := 38.0
const CHASE_SPEED := 58.0

var level
var speed_mult := 1.0
var pos := Vector2.ZERO
var state: int = S.PATROL
var route: Array[Vector2] = []
var route_idx := 0
var path: Array[Vector2] = []
var path_idx := 0
var facing := 0.0
var base_face := 0.0
var wait := 1.0
var look_t := 0.0
var target := Vector2.ZERO
var repath_t := 0.0
var awareness := 0.0
var sees := false
var last_seen := Vector2.ZERO
var lose_t := 0.0
var search_t := 0.0
var anim := 0.0
var moving := false

func _ready() -> void:
	position = pos.round()
	anim = randf() * 10.0

func tick(delta: float) -> void:
	anim += delta
	var before := pos
	_perceive(delta)
	if sees and state != S.CHASE:
		# desconfiado: para e encara o jogador enquanto a barra de atenção enche
		var to: Vector2 = level.player.pos - pos
		facing = lerp_angle(facing, to.angle(), clampf(10.0 * delta, 0.0, 1.0))
	else:
		match state:
			S.PATROL:
				_patrol(delta)
			S.INVESTIGATE:
				_investigate(delta)
			S.CHASE:
				_chase(delta)
			S.SEARCH:
				_search(delta)
	moving = pos.distance_to(before) > 0.02
	position = pos.round()
	queue_redraw()

# ---------------------------------------------------------------- percepção
func _perceive(delta: float) -> void:
	var p = level.player
	sees = false
	var d := 9999.0
	if not p.hiding and not p.falling:
		var to: Vector2 = p.pos - pos
		d = to.length()
		if d <= VISION:
			var in_cone := d < CLOSE_RANGE or absf(angle_difference(facing, to.angle())) <= HALF_FOV
			if in_cone and level.line_of_sight(pos, p.pos):
				sees = true
		if p.is_noisy() and state != S.CHASE:
			var radius := NOISE_RADIUS if level.line_of_sight(pos, p.pos) else NOISE_RADIUS * 0.55
			if d < radius:
				if state != S.INVESTIGATE or target.distance_to(p.pos) > 12.0:
					state = S.INVESTIGATE
					target = p.pos
					wait = 0.0
					_set_path(target)
	if sees:
		last_seen = p.pos
		if state == S.CHASE:
			awareness = 1.0
			target = p.pos
			lose_t = 0.0
		else:
			var k := clampf(1.0 - d / VISION, 0.0, 1.0)
			var rate := lerpf(0.9, 2.8, k)
			if p.running:
				rate *= 1.5
			awareness += rate * delta
			if awareness >= 1.0:
				_start_chase()
	elif state != S.CHASE:
		awareness = maxf(0.0, awareness - 0.4 * delta)

func _start_chase() -> void:
	state = S.CHASE
	awareness = 1.0
	target = level.player.pos
	lose_t = 0.0
	repath_t = 0.0
	Game.sfx("alert")

func _start_search() -> void:
	state = S.SEARCH
	search_t = 5.0
	awareness = 0.0
	_set_path(last_seen)

# ------------------------------------------------------------------ estados
func _set_path(to: Vector2) -> void:
	path = level.find_path(pos, to)
	path_idx = 0

func _follow(spd: float, delta: float) -> bool:
	if path_idx >= path.size():
		return true
	var tgt := path[path_idx]
	var to := tgt - pos
	var dist := to.length()
	var step := spd * delta
	if dist <= step:
		pos = tgt
		path_idx += 1
	else:
		var dir := to / dist
		pos += dir * step
		facing = lerp_angle(facing, dir.angle(), clampf(8.0 * delta, 0.0, 1.0))
	return path_idx >= path.size()

func _back_to_patrol() -> void:
	state = S.PATROL
	wait = 0.0
	path.clear()
	path_idx = 0

func _patrol(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		look_t += delta
		facing = base_face + sin(look_t * 2.0) * 0.9
		return
	if path_idx >= path.size():
		_set_path(route[route_idx])
	if _follow(PATROL_SPEED * speed_mult, delta):
		route_idx = (route_idx + 1) % route.size()
		wait = randf_range(0.7, 1.8)
		base_face = facing
		look_t = 0.0
		path.clear()
		path_idx = 0

func _investigate(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		look_t += delta
		facing = base_face + sin(look_t * 3.0) * 1.2
		if wait <= 0.0:
			_back_to_patrol()
		return
	if _follow(INVESTIGATE_SPEED * speed_mult, delta):
		wait = 2.2
		base_face = facing
		look_t = 0.0

func _chase(delta: float) -> void:
	var p = level.player
	if not sees:
		lose_t += delta
	repath_t -= delta
	var direct: bool = sees and pos.distance_to(p.pos) < 26.0 and level.line_clear(pos, p.pos)
	if direct:
		var dir: Vector2 = (p.pos - pos).normalized()
		pos += dir * CHASE_SPEED * speed_mult * delta
		facing = lerp_angle(facing, dir.angle(), clampf(12.0 * delta, 0.0, 1.0))
		return
	if repath_t <= 0.0:
		repath_t = 0.22
		_set_path(target)
	var arrived := _follow(CHASE_SPEED * speed_mult, delta)
	if lose_t > 3.5 or (arrived and not sees):
		_start_search()

func _search(delta: float) -> void:
	if path_idx < path.size():
		_follow(INVESTIGATE_SPEED * speed_mult, delta)
		return
	search_t -= delta
	facing += delta * 2.2        # gira procurando
	if search_t <= 0.0:
		_back_to_patrol()

# ------------------------------------------------------------------ desenho
func _dir_index() -> int:
	var c := cos(facing)
	var sn := sin(facing)
	if absf(c) > absf(sn):
		return 3 if c > 0.0 else 2
	return 0 if sn > 0.0 else 1

func _draw() -> void:
	var dir := _dir_index()
	var chase := state == S.CHASE
	var step := 0
	if moving:
		step = int(anim * (10.0 if chase else 6.0)) % 2
	var b := -1 if (moving and step == 1) else 0
	var ox := 1 if (chase and int(anim * 30.0) % 2 == 0) else 0
	var lens := Color("1b1020")
	if state == S.INVESTIGATE or state == S.SEARCH:
		lens = Color("ff9f43")
	elif chase:
		lens = Color("ff3b3b")
	var skin := Color("c98f62")
	var khaki := Color("a98a52")
	var khaki_d := Color("7d6338")
	var leather := Color("6b3f1d")
	var leather_l := Color("94602f")
	var gold := Color("f2c94c")
	var boot := Color("3a2414")
	var gun := Color("2a2a30")
	var wood := Color("5a3a1e")

	draw_rect(Rect2(-6, -1, 12, 3), Color(0, 0, 0, 0.4))
	# pernas e botas
	var ll := 1 if (moving and step == 0) else 0
	var lr := 1 if (moving and step == 1) else 0
	draw_rect(Rect2(-3 + ox, -6, 2, 6 - ll), khaki_d)
	draw_rect(Rect2(1 + ox, -6, 2, 6 - lr), khaki_d)
	draw_rect(Rect2(-3 + ox, -2 - ll, 2, 2), boot)
	draw_rect(Rect2(1 + ox, -2 - lr, 2, 2), boot)
	# camisa, cinto e braços
	draw_rect(Rect2(-5 + ox, -13 + b, 10, 8), khaki)
	draw_rect(Rect2(-5 + ox, -6 + b, 10, 1), leather)
	draw_rect(Rect2(-1 + ox, -6 + b, 2, 1), gold)
	draw_rect(Rect2(-6 + ox, -12 + b, 1, 6), khaki_d)
	draw_rect(Rect2(5 + ox, -12 + b, 1, 6), khaki_d)
	# cartucheira cruzada no peito
	for k in range(7):
		draw_rect(Rect2(-4 + k + ox, -12 + k + b, 1, 1), leather)
		if k % 2 == 0:
			draw_rect(Rect2(-4 + k + ox, -11 + k + b, 1, 1), gold)
		if dir == 1:
			draw_rect(Rect2(3 - k + ox, -12 + k + b, 1, 1), leather)
	# cabeça, lenço e rosto
	draw_rect(Rect2(-3 + ox, -18 + b, 6, 5), skin)
	draw_rect(Rect2(-3 + ox, -13 + b, 6, 1), Color("b23a3a"))
	match dir:
		0:
			draw_rect(Rect2(-3 + ox, -16 + b, 2, 2), lens)     # óculos redondos
			draw_rect(Rect2(1 + ox, -16 + b, 2, 2), lens)
			draw_rect(Rect2(-1 + ox, -16 + b, 2, 1), khaki_d)
			draw_rect(Rect2(-2 + ox, -14 + b, 4, 1), Color("2a1a10"))   # bigode
			if chase:
				draw_rect(Rect2(-1 + ox, -13 + b, 2, 1), Color("3a0c0c"))
		1:
			draw_rect(Rect2(-3 + ox, -18 + b, 6, 5), Color("3a2414"))
		2:
			draw_rect(Rect2(-3 + ox, -16 + b, 2, 2), lens)
			draw_rect(Rect2(-3 + ox, -14 + b, 2, 1), Color("2a1a10"))
		3:
			draw_rect(Rect2(1 + ox, -16 + b, 2, 2), lens)
			draw_rect(Rect2(1 + ox, -14 + b, 2, 1), Color("2a1a10"))
	# chapéu de couro de aba virada (meia-lua) com estrela dourada
	draw_rect(Rect2(-7 + ox, -20 + b, 14, 2), leather)
	draw_rect(Rect2(-4 + ox, -24 + b, 8, 5), leather)
	draw_rect(Rect2(-8 + ox, -23 + b, 2, 4), leather)
	draw_rect(Rect2(6 + ox, -23 + b, 2, 4), leather)
	draw_rect(Rect2(-4 + ox, -24 + b, 8, 1), leather_l)
	draw_rect(Rect2(-5 + ox, -20 + b, 1, 1), gold)
	draw_rect(Rect2(4 + ox, -20 + b, 1, 1), gold)
	if dir != 1:
		draw_rect(Rect2(-1 + ox, -23 + b, 2, 2), gold)
	# rifle
	match dir:
		0:
			draw_rect(Rect2(6 + ox, -15 + b, 1, 13), gun)
			draw_rect(Rect2(5 + ox, -4 + b, 3, 3), wood)
		1:
			draw_rect(Rect2(-7 + ox, -15 + b, 1, 13), gun)
			draw_rect(Rect2(-8 + ox, -4 + b, 3, 3), wood)
		2:
			draw_rect(Rect2(-12 + ox, -9 + b, 10, 1), gun)
			draw_rect(Rect2(-3 + ox, -8 + b, 3, 2), wood)
		3:
			draw_rect(Rect2(2 + ox, -9 + b, 10, 1), gun)
			draw_rect(Rect2(0 + ox, -8 + b, 3, 2), wood)

	# ícones de estado (acima do chapéu)
	if chase:
		PixelFont.draw(self, "!", Vector2(-4, -41), Color("ff3b3b"), 3)
	elif awareness > 0.05:
		PixelFont.draw(self, "?", Vector2(-4, -41), Color("ffd23f"), 3)
		draw_rect(Rect2(-7, -26, 14, 2), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-7, -26, 14.0 * awareness, 2), Color("ffd23f"))
	elif state == S.SEARCH or state == S.INVESTIGATE:
		PixelFont.draw(self, "?", Vector2(-2, -36), Color("ff9f43"), 2)
