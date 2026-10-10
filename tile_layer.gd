class_name TileLayer
extends Node2D
## Desenha o chão, as paredes, as portas e o chão que desmorona.

const T := 16

var level
var themes := {
	"mansion": {
		"style": "paper",
		"floor_a": Color("6d4a39"), "floor_b": Color("654333"), "line": Color("523427"),
		"top": Color("1d1220"), "rim": Color("3d2742"),
		"face": Color("5e2b40"), "face_d": Color("4f2335"), "trim": Color("2a1420"),
		"base": Color("3c2619"), "base_h": Color("6b4a2e"),
	},
	"cellar": {
		"style": "brick",
		"floor_a": Color("4a505c"), "floor_b": Color("434956"), "line": Color("343945"),
		"top": Color("13161c"), "rim": Color("2a2f3a"),
		"face": Color("59627a"), "face_d": Color("3f485c"), "trim": Color("262b36"),
		"base": Color("353c4c"), "base_h": Color("6a7388"),
	},
}

func _draw() -> void:
	if level == null:
		return
	var d: LevelData = level.data
	var P: Dictionary = themes[d.theme]
	for y in range(d.h):
		for x in range(d.w):
			var c: String = level.cell_at(x, y)
			var px := x * T
			var py := y * T
			match c:
				"#":
					_wall(P, x, y, px, py)
				"D":
					_wall(P, x, y, px, py)
					_door(px, py)
				"o":
					_floor(P, x, y, px, py)
					_open_door(px, py)
				"Z":
					_floor(P, x, y, px, py)
					_stairs(px, py)
				"X":
					_fragile(P, x, y, px, py)
				_:
					_floor(P, x, y, px, py)

# ------------------------------------------------------------------- chão
func _floor(P: Dictionary, x: int, y: int, px: int, py: int) -> void:
	draw_rect(Rect2(px, py, T, T), P["floor_a"] if (x + y) % 2 == 0 else P["floor_b"])
	var line: Color = P["line"]
	if P["style"] == "paper":
		draw_rect(Rect2(px, py + 5, T, 1), line)
		draw_rect(Rect2(px, py + 11, T, 1), line)
		var o := ((x * 7 + y * 3) % 4) * 4
		draw_rect(Rect2(px + o, py, 1, 5), line)
		draw_rect(Rect2(px + (o + 8) % 16, py + 6, 1, 5), line)
		draw_rect(Rect2(px + (o + 4) % 16, py + 12, 1, 4), line)
	else:
		draw_rect(Rect2(px, py + 15, T, 1), line)
		draw_rect(Rect2(px + 15, py, 1, T), line)
		var h := absi((x * 31 + y * 17) % 7)
		draw_rect(Rect2(px + 3 + h, py + 4 + h % 3, 2, 1), line)
		draw_rect(Rect2(px + 10 - h, py + 10, 1, 2), line)
	if level.cell_at(x, y - 1) == "#":
		draw_rect(Rect2(px, py, T, 4), Color(0, 0, 0, 0.28))
	if level.cell_at(x - 1, y) == "#":
		draw_rect(Rect2(px, py, 2, T), Color(0, 0, 0, 0.2))

func _fragile(P: Dictionary, x: int, y: int, px: int, py: int) -> void:
	var t: float = level.collapse_t
	var bt: float = level.break_times.get(Vector2i(x, y), 9999.0)
	if t >= 0.0 and t >= bt:
		_hole(px, py)
		return
	_floor(P, x, y, px, py)
	# pregos antigos: uma pista sutil de que este piso é podre
	draw_rect(Rect2(px + 2, py + 2, 1, 1), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(px + 13, py + 9, 1, 1), Color(0, 0, 0, 0.35))
	if t >= 0.0:
		var prog := clampf(t / 1.6, 0.0, 1.0)
		var h := absi((x * 73856093) ^ (y * 19349663))
		if prog > float(h % 100) / 125.0:
			var o := h % 5
			var col := Color(0.04, 0.01, 0.03, 0.95)
			draw_rect(Rect2(px + 3 + o, py + 2, 1, 4), col)
			draw_rect(Rect2(px + 4 + o, py + 6, 5, 1), col)
			draw_rect(Rect2(px + 8 + o, py + 6, 1, 5), col)
			draw_rect(Rect2(px + 6 + o, py + 11, 3, 1), col)
		if bt - t < 0.3:
			draw_rect(Rect2(px, py, T, T), Color(0, 0, 0, 0.4))

func _hole(px: int, py: int) -> void:
	draw_rect(Rect2(px, py, T, T), Color("050208"))
	draw_rect(Rect2(px, py, T, 2), Color("2a1a10"))
	draw_rect(Rect2(px + 3, py + 7, 4, 1), Color("0f0816"))
	draw_rect(Rect2(px + 9, py + 11, 4, 1), Color("0f0816"))

# ------------------------------------------------------------------ paredes
func _wall(P: Dictionary, x: int, y: int, px: int, py: int) -> void:
	var below: String = level.cell_at(x, y + 1)
	if below == "#":
		# topo da parede (visto de cima)
		draw_rect(Rect2(px, py, T, T), P["top"])
		if level.cell_at(x, y - 1) != "#":
			draw_rect(Rect2(px, py, T, 2), P["rim"])
		if level.cell_at(x - 1, y) != "#":
			draw_rect(Rect2(px, py, 2, T), P["rim"])
		if level.cell_at(x + 1, y) != "#":
			draw_rect(Rect2(px + T - 2, py, 2, T), P["rim"])
		return
	# face frontal da parede
	draw_rect(Rect2(px, py, T, T), P["face"])
	var fd: Color = P["face_d"]
	var trim: Color = P["trim"]
	var hsh := (x * 7 + y * 13) % 11
	if P["style"] == "paper":
		for i in range(4):
			draw_rect(Rect2(px + i * 4 + 1, py + 2, 1, 10), fd)
		draw_rect(Rect2(px, py, T, 2), trim)
		draw_rect(Rect2(px, py + 12, T, 4), P["base"])
		draw_rect(Rect2(px, py + 12, T, 1), P["base_h"])
		if hsh == 0:      # janela com luar
			draw_rect(Rect2(px + 3, py + 2, 10, 9), trim)
			draw_rect(Rect2(px + 4, py + 3, 8, 7), Color("27406b"))
			draw_rect(Rect2(px + 4, py + 3, 8, 3), Color("3a5c94"))
			draw_rect(Rect2(px + 7, py + 3, 2, 7), trim)
		elif hsh == 5:    # quadro
			draw_rect(Rect2(px + 3, py + 3, 10, 7), Color("c9a45c"))
			draw_rect(Rect2(px + 4, py + 4, 8, 5), Color("2b3a2f"))
			draw_rect(Rect2(px + 6, py + 5, 3, 3), Color("7a8a6a"))
	else:
		draw_rect(Rect2(px, py + 5, T, 1), fd)
		draw_rect(Rect2(px, py + 10, T, 1), fd)
		var o := (y % 2) * 4
		draw_rect(Rect2(px + 4 + o, py, 1, 5), fd)
		draw_rect(Rect2(px + (10 + o) % 16, py + 6, 1, 4), fd)
		draw_rect(Rect2(px + 3 + o, py + 11, 1, 2), fd)
		draw_rect(Rect2(px, py, T, 1), trim)
		draw_rect(Rect2(px, py + 13, T, 3), P["base"])
		draw_rect(Rect2(px, py + 13, T, 1), P["base_h"])
		if hsh == 3:      # tocha
			draw_rect(Rect2(px + 7, py + 5, 2, 6), Color("4a3a2a"))
			draw_rect(Rect2(px + 6, py + 2, 4, 4), Color("ffb347"))
			draw_rect(Rect2(px + 7, py + 1, 2, 2), Color("ffe08a"))

func _door(px: int, py: int) -> void:
	draw_rect(Rect2(px + 1, py, 14, 16), Color("2a1810"))
	draw_rect(Rect2(px + 2, py + 1, 12, 15), Color("8b5a2b"))
	draw_rect(Rect2(px + 4, py + 3, 8, 4), Color("a56e37"))
	draw_rect(Rect2(px + 4, py + 9, 8, 5), Color("a56e37"))
	draw_rect(Rect2(px + 10, py + 7, 3, 3), Color("f2c94c"))
	draw_rect(Rect2(px + 11, py + 8, 1, 1), Color("2a1810"))

func _open_door(px: int, py: int) -> void:
	draw_rect(Rect2(px, py, 2, T), Color("2a1810"))
	draw_rect(Rect2(px + T - 2, py, 2, T), Color("2a1810"))
	draw_rect(Rect2(px, py, T, 2), Color("2a1810"))
	draw_rect(Rect2(px + 2, py + 2, 3, 13), Color("6b4423"))

func _stairs(px: int, py: int) -> void:
	for i in range(4):
		draw_rect(Rect2(px + 1, py + 2 + i * 3, 14, 2), Color("9aa3b8").lerp(Color("e8ecf8"), i / 3.0))
		draw_rect(Rect2(px + 1, py + 4 + i * 3, 14, 1), Color("2a2f3a"))
	draw_rect(Rect2(px, py, T, 2), Color("ffffff", 0.35))
