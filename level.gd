class_name Level
extends Node2D
## Uma fase completa: mapa, colisão, jogador, capangas, móveis, escuridão e HUD.

signal fell_to_next        # o chão quebrou e o jogador caiu
signal reached_exit        # chegou à saída (fim da demo)
signal retry_requested     # jogador pediu para tentar de novo depois de ser pego

enum St { PLAY, COLLAPSE, CAUGHT, DONE }

const T := 16
const SCREEN := Vector2(240, 160)
const CRACK_TIME := 1.6

const DARK_SHADER := """
shader_type canvas_item;
uniform vec2 center = vec2(120.0, 80.0);
uniform float radius = 86.0;
uniform float darkness = 0.86;
void fragment() {
	vec2 p = floor(UV * vec2(240.0, 160.0));
	float d = distance(p, floor(center));
	float t = clamp((d - radius * 0.28) / (radius * 0.72), 0.0, 1.0);
	float checker = mod(p.x + p.y, 2.0);
	float v = clamp(floor(t * 6.0 + checker * 0.5) / 6.0, 0.0, 1.0);
	COLOR = vec4(0.03, 0.0, 0.08, v * darkness);
}
"""

var data: LevelData
var landing := false

var cells := PackedStringArray()
var solid := PackedByteArray()
var opaque := PackedByteArray()
var astar := AStarGrid2D.new()

var tile_layer: TileLayer
var overlay: Overlay
var player: Player
var monsters: Array = []
var furniture: Array = []
var darkness_mat: ShaderMaterial
var hud: Hud

var state: int = St.PLAY
var time := 0.0
var has_key := false
var key_taken := false
var key_pos := Vector2.ZERO
var door_open := false
var prompt := ""
var msg := ""
var msg_t := 0.0
var card_t := 3.2
var hint_shown := false
var shake := 0.0
var chasers := 0
var collapse_t := -1.0
var break_times := {}
var player_break := 0.0
var fall_sent := false
var caught_t := 0.0

func setup(d: LevelData, land: bool = false) -> void:
	data = d
	landing = land

func _ready() -> void:
	y_sort_enabled = true
	cells = data.cells.duplicate()
	_build_grids()
	_build_astar()

	tile_layer = TileLayer.new()
	tile_layer.level = self
	tile_layer.z_index = -10
	add_child(tile_layer)

	overlay = Overlay.new()
	overlay.level = self
	overlay.z_index = -5
	add_child(overlay)

	for o in data.objects:
		var f := Furniture.new()
		f.kind = o["type"]
		f.tw = o["w"]
		f.th = o["h"]
		f.cell = Vector2i(o["x"], o["y"])
		f.hideable = f.kind == "table" or f.kind == "bed"
		f.position = Vector2(f.cell * T)
		f.rect = Rect2(f.position, Vector2(f.tw * T, f.th * T))
		add_child(f)
		furniture.append(f)

	player = Player.new()
	player.level = self
	player.pos = cell_center(data.start)
	add_child(player)

	for md in data.monsters:
		var m := Monster.new()
		m.level = self
		m.speed_mult = data.monster_speed
		var route: Array[Vector2] = []
		for c in md["route"]:
			route.append(cell_center(nearest_free(Vector2i(c[0], c[1]))))
		m.route = route
		m.route_idx = int(md["start"]) % route.size()
		m.pos = route[m.route_idx]
		m.wait = randf_range(0.3, 1.5)
		add_child(m)
		monsters.append(m)

	if data.key.x >= 0:
		key_pos = cell_center(data.key)
	_build_screen_layers()
	if landing:
		player.drop = 90.0
	_update_camera()
	_update_darkness()

func _build_screen_layers() -> void:
	var dl := CanvasLayer.new()
	dl.layer = 1
	add_child(dl)
	var rect := ColorRect.new()
	rect.size = SCREEN
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = DARK_SHADER
	darkness_mat = ShaderMaterial.new()
	darkness_mat.shader = sh
	rect.material = darkness_mat
	dl.add_child(rect)

	var hl := CanvasLayer.new()
	hl.layer = 2
	add_child(hl)
	hud = Hud.new()
	hud.level = self
	hl.add_child(hud)

# ================================================================ grade / mapa
func _build_grids() -> void:
	var n := data.w * data.h
	solid.resize(n)
	opaque.resize(n)
	for i in range(n):
		var s := 1 if (cells[i] == "#" or cells[i] == "D") else 0
		solid[i] = s
		opaque[i] = s
	for o in data.objects:
		var tall: bool = o["type"] == "shelf" or o["type"] == "wardrobe"
		for yy in range(o["y"], o["y"] + o["h"]):
			for xx in range(o["x"], o["x"] + o["w"]):
				solid[yy * data.w + xx] = 1
				if tall:
					opaque[yy * data.w + xx] = 1

func _build_astar() -> void:
	astar.region = Rect2i(0, 0, data.w, data.h)
	astar.cell_size = Vector2(T, T)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in range(data.h):
		for x in range(data.w):
			if solid[y * data.w + x] == 1:
				astar.set_point_solid(Vector2i(x, y), true)

func cell_at(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= data.w or y >= data.h:
		return "#"
	return cells[y * data.w + x]

func cell_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * float(T)

func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))

func is_solid_cell(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= data.w or y >= data.h:
		return true
	return solid[y * data.w + x] == 1

func is_opaque_at(p: Vector2) -> bool:
	var x := floori(p.x / T)
	var y := floori(p.y / T)
	if x < 0 or y < 0 or x >= data.w or y >= data.h:
		return true
	return opaque[y * data.w + x] == 1

func rect_blocked(r: Rect2) -> bool:
	var x0 := floori(r.position.x / T)
	var y0 := floori(r.position.y / T)
	var x1 := floori((r.end.x - 0.01) / T)
	var y1 := floori((r.end.y - 0.01) / T)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if is_solid_cell(x, y):
				return true
	return false

## Linha de visão: só paredes, estantes, guarda-roupas e portas fechadas bloqueiam.
func line_of_sight(a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / 4.0)
	for i in range(1, steps + 1):
		if is_opaque_at(a.lerp(b, float(i) / float(steps))):
			return false
	return true

## Linha livre para andar em linha reta (móveis bloqueiam).
func line_clear(a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / 4.0)
	for i in range(1, steps + 1):
		var p := a.lerp(b, float(i) / float(steps))
		if is_solid_cell(floori(p.x / T), floori(p.y / T)):
			return false
	return true

func nearest_free(c: Vector2i) -> Vector2i:
	for r in range(0, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var p := Vector2i(c.x + dx, c.y + dy)
				if not is_solid_cell(p.x, p.y):
					return p
	return c

func find_path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var a := nearest_free(world_to_cell(from))
	var b := nearest_free(world_to_cell(to))
	if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b):
		return out
	var ids := astar.get_id_path(a, b)
	for id in ids:
		out.append(cell_center(id))
	if out.size() > 1:
		out.remove_at(0)
	return out

func rect_dist(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return sqrt(dx * dx + dy * dy)

# ======================================================================== loop
func is_playing() -> bool:
	return state == St.PLAY

func is_caught() -> bool:
	return state == St.CAUGHT

func say(text: String, seconds: float = 3.0) -> void:
	msg = text
	msg_t = seconds

func objective() -> String:
	if not has_key:
		return data.obj_key
	if not door_open:
		return data.obj_door
	return data.obj_exit

func on_landed() -> void:
	Game.sfx("thud")
	shake = 3.0

func _physics_process(delta: float) -> void:
	time += delta
	if card_t > 0.0:
		card_t -= delta
	elif not hint_shown:
		hint_shown = true
		say(data.hint, 5.0)
	if msg_t > 0.0:
		msg_t -= delta
	match state:
		St.PLAY:
			_play(delta)
		St.COLLAPSE:
			_collapse(delta)
		St.CAUGHT:
			_caught(delta)
	if state != St.COLLAPSE:
		shake = maxf(0.0, shake - delta * 5.0)
	_update_camera()
	_update_darkness()

func _play(delta: float) -> void:
	player.tick(delta)
	chasers = 0
	for m in monsters:
		m.tick(delta)
		if m.state == Monster.S.CHASE:
			chasers += 1
	_interactions()
	_check_catch()
	if state == St.PLAY:
		_check_tiles()

func _interactions() -> void:
	prompt = ""
	if player.drop > 0.0:
		return
	var press := Input.is_action_just_pressed("interact")
	if player.hiding:
		prompt = "E: SAIR"
		if press:
			player.leave_hide()
			Game.sfx("hide")
		return
	if not key_taken and data.key.x >= 0 and player.pos.distance_to(key_pos) < 12.0:
		key_taken = true
		has_key = true
		Game.sfx("key")
		say("ARRETADO! PEGOU A CHAVE!")
	var best: Furniture = null
	var bd := 11.0
	for f in furniture:
		if f.hideable:
			var d := rect_dist(f.rect, player.pos)
			if d < bd:
				bd = d
				best = f
	var door_near := false
	if data.door.x >= 0 and not door_open:
		door_near = player.pos.distance_to(cell_center(data.door)) < 20.0
	if door_near:
		prompt = "E: ABRIR" if has_key else "E: OLHAR"
		if press:
			if has_key:
				_open_door()
			else:
				Game.sfx("deny")
				say("TRANCADA, OXE! CADÊ A CHAVE?")
	elif best != null:
		prompt = "E: SE ESCONDER"
		if press:
			_try_hide(best)

func _try_hide(f: Furniture) -> void:
	for m in monsters:
		if m.sees:
			Game.sfx("deny")
			say("OS CABRAS TÃO TE VENDO!", 1.5)
			return
		if m.state == Monster.S.CHASE and m.pos.distance_to(player.pos) < 70.0:
			Game.sfx("deny")
			say("TÃO PERTO! CORRA, CABRA!", 1.5)
			return
	player.hide_in(f)
	Game.sfx("hide")

func _open_door() -> void:
	door_open = true
	var dc := data.door
	var idx := dc.y * data.w + dc.x
	cells[idx] = "o"
	solid[idx] = 0
	opaque[idx] = 0
	astar.set_point_solid(dc, false)
	tile_layer.queue_redraw()
	Game.sfx("door")
	if data.exit_mode == "collapse":
		say("EITA... A PORTA RANGEU. VIXE MARIA!", 3.5)
	else:
		say("O PORTÃO ABRIU, ARRETADO!", 2.5)

func _check_catch() -> void:
	if player.hiding or player.falling:
		return
	for m in monsters:
		if m.pos.distance_to(player.pos) < 10.0:
			state = St.CAUGHT
			caught_t = 0.0
			player.moving = false
			player.running = false
			shake = 3.0
			Game.sfx("catch")
			return

func _check_tiles() -> void:
	var pc := world_to_cell(player.pos)
	var ch := cell_at(pc.x, pc.y)
	if ch == "X" and data.exit_mode == "collapse":
		_start_collapse()
	elif ch == "Z":
		state = St.DONE
		player.frozen = true
		player.moving = false
		Game.sfx("key")
		reached_exit.emit()

# ===================================================== o chão que desmorona
func _start_collapse() -> void:
	state = St.COLLAPSE
	collapse_t = 0.0
	player.frozen = true
	player.moving = false
	player.running = false
	Game.sfx("rumble")
	say("EITA! O CHÃO TÁ CEDENDO!", 3.0)
	var pc := world_to_cell(player.pos)
	var xs: Array[Vector2i] = []
	var maxd := 1.0
	for y in range(data.h):
		for x in range(data.w):
			if cells[y * data.w + x] == "X":
				xs.append(Vector2i(x, y))
				maxd = maxf(maxd, Vector2(x, y).distance_to(Vector2(pc)))
	for c in xs:
		var dist := Vector2(c).distance_to(Vector2(pc))
		break_times[c] = CRACK_TIME + (maxd - dist) * 0.07 + randf() * 0.1
	break_times[pc] = CRACK_TIME + maxd * 0.07 + 0.15
	player_break = break_times[pc]

func _collapse(delta: float) -> void:
	collapse_t += delta
	shake = 1.0 + minf(collapse_t, 2.5) * 0.8
	if collapse_t >= player_break and not player.falling:
		player.start_fall()
		Game.sfx("fall")
	player.tick(delta)
	tile_layer.queue_redraw()
	if player.falling and player.fall_t > 1.0 and not fall_sent:
		fall_sent = true
		fell_to_next.emit()

func _caught(delta: float) -> void:
	caught_t += delta
	if caught_t > 1.3 and Input.is_action_just_pressed("confirm"):
		state = St.DONE
		retry_requested.emit()

# ===================================================== câmera e escuridão
func _update_camera() -> void:
	var mapsize := Vector2(data.w * T, data.h * T)
	var cam := player.pos + Vector2(0, -6) - SCREEN * 0.5
	cam.x = clampf(cam.x, 0.0, maxf(0.0, mapsize.x - SCREEN.x))
	cam.y = clampf(cam.y, 0.0, maxf(0.0, mapsize.y - SCREEN.y))
	var so := Vector2.ZERO
	if shake > 0.05:
		so = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	position = (-cam.round() + so).round()

func _update_darkness() -> void:
	var c := player.position + position + Vector2(0, -6)
	var r := 86.0 + sin(time * 2.7) * 1.5
	if chasers > 0:
		r -= 8.0
	if state == St.CAUGHT:
		r = maxf(18.0, r - caught_t * 45.0)
	darkness_mat.set_shader_parameter("center", c)
	darkness_mat.set_shader_parameter("radius", r)
