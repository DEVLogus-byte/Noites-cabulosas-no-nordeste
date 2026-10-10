class_name LevelData
extends RefCounted
## Dados de uma fase: mapa, móveis, capangas e textos.
##
## Legenda das células:  #=parede  .=chão  X=chão frágil (quebra)  D=porta trancada
##                       o=porta aberta  Z=escada de saída  H=buraco
## Posições são em "tiles" de 16x16 pixels.

var w := 30
var h := 20
var cells := PackedStringArray()
var theme := "mansion"          # "mansion" ou "cellar"
var card_title := ""
var card_sub := ""
var hint := ""
var obj_key := "ENCONTRE A CHAVE"
var obj_door := "ABRA A PORTA"
var obj_exit := "SAIA"
var exit_mode := "collapse"     # "collapse": chão cede e vai pra próxima fase | "end": escada = fim da demo
var monster_speed := 1.0
var start := Vector2i.ZERO
var key := Vector2i(-1, -1)
var door := Vector2i(-1, -1)
var objects: Array = []
var monsters: Array = []

func _init(width: int = 30, height: int = 20) -> void:
	w = width
	h = height
	cells.resize(w * h)
	cells.fill("#")

func get_cell(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return cells[y * w + x]

func set_cell(x: int, y: int, c: String) -> void:
	cells[y * w + x] = c

func carve(x: int, y: int, cw: int, ch: int, c: String = ".") -> void:
	for yy in range(y, y + ch):
		for xx in range(x, x + cw):
			set_cell(xx, yy, c)

## type: table, bed (escondem) | shelf, wardrobe, plant, barrel, crate (só obstáculos)
func add_obj(type: String, x: int, y: int, ow: int = 1, oh: int = 1) -> void:
	objects.append({"type": type, "x": x, "y": y, "w": ow, "h": oh})

## route: lista de [x, y] em tiles. start_idx: em qual ponto da rota o capanga nasce.
func add_monster(route: Array, start_idx: int = 0) -> void:
	monsters.append({"route": route, "start": start_idx})

static func get_level(index: int) -> LevelData:
	if index == 0:
		return _level1()
	return _level2()

# ===================================================================== FASE 1
static func _level1() -> LevelData:
	var d := LevelData.new(30, 20)
	d.theme = "mansion"
	d.card_title = "ANDAR 1"
	d.card_sub = "O CASARÃO DO CORONEL"
	d.hint = "OS CAPANGAS DO LAMPIÃO INVADIRAM O CASARÃO!\nSE AVEXE NÃO: ANDE DEVAGAR, SEM BARULHO.\nPERTO DE MESA OU CAMA: E = SE ESCONDER"
	d.obj_key = "ACHE A CHAVE"
	d.obj_door = "ABRA A PORTA TRANCADA"
	d.obj_exit = "ENTRE NO QUARTO"
	d.exit_mode = "collapse"

	# salas de cima, corredor, salas de baixo
	d.carve(1, 1, 7, 5)       # A: biblioteca
	d.carve(9, 1, 10, 5)      # B: sala de jantar
	d.carve(20, 1, 9, 5)      # C: quarto
	d.carve(1, 7, 28, 2)      # corredor
	d.carve(1, 10, 7, 9)      # D: quarto de hóspedes
	d.carve(9, 10, 10, 9)     # E: salão de entrada
	d.carve(20, 10, 9, 9, "X")  # F: a sala trancada (chão frágil)
	# passagens
	d.carve(4, 6, 1, 1)
	d.carve(13, 6, 2, 1)
	d.carve(24, 6, 1, 1)
	d.carve(4, 9, 1, 1)
	d.carve(13, 9, 2, 1)
	d.set_cell(24, 9, "D")    # porta trancada da sala F

	d.start = Vector2i(13, 17)
	d.key = Vector2i(27, 4)
	d.door = Vector2i(24, 9)

	# A
	d.add_obj("shelf", 1, 1, 2)
	d.add_obj("shelf", 5, 1, 3)
	d.add_obj("table", 3, 3, 2)
	d.add_obj("plant", 7, 5)
	# B
	d.add_obj("shelf", 9, 1, 2)
	d.add_obj("shelf", 16, 1, 3)
	d.add_obj("table", 11, 3, 5)
	d.add_obj("plant", 18, 5)
	# C
	d.add_obj("wardrobe", 20, 1, 2)
	d.add_obj("bed", 26, 1, 2, 2)
	d.add_obj("table", 22, 3, 2)
	# D
	d.add_obj("bed", 1, 11, 2, 2)
	d.add_obj("shelf", 6, 10, 2)
	d.add_obj("table", 4, 14, 2)
	d.add_obj("wardrobe", 1, 17, 2)
	d.add_obj("plant", 7, 18)
	# E
	d.add_obj("table", 10, 13, 3)
	d.add_obj("table", 15, 15, 3)
	d.add_obj("plant", 9, 10)
	d.add_obj("plant", 18, 10)

	# capangas do Lampião (rotas de patrulha)
	d.add_monster([[2, 7], [13, 8], [27, 7], [27, 8], [13, 7], [2, 8]], 0)
	d.add_monster([[5, 4], [4, 7], [14, 4], [14, 7], [24, 7], [24, 3], [21, 5], [24, 7]], 2)
	d.add_monster([[16, 11], [10, 16], [14, 8], [4, 8], [4, 12], [5, 16], [4, 8], [14, 8]], 4)
	return d

# ===================================================================== FASE 2
static func _level2() -> LevelData:
	var d := LevelData.new(30, 20)
	d.theme = "cellar"
	d.card_title = "ANDAR 2"
	d.card_sub = "O PORÃO DO CORONEL"
	d.hint = "OS CABRAS TÃO MAIS ARRETADOS AQUI EMBAIXO.\nACHE A CHAVE E A ESCADA, MEU REI."
	d.obj_key = "ACHE A CHAVE"
	d.obj_door = "ABRA O PORTÃO"
	d.obj_exit = "SUBA A ESCADA"
	d.exit_mode = "end"
	d.monster_speed = 1.1

	d.carve(1, 1, 11, 5)      # L1
	d.carve(1, 7, 11, 6)      # L2
	d.carve(1, 14, 11, 5)     # L3
	d.carve(16, 1, 13, 5)     # R1
	d.carve(16, 7, 13, 6)     # R2
	d.carve(16, 14, 13, 5)    # R3
	d.carve(13, 1, 2, 18)     # corredor vertical
	# passagens entre corredor e salas
	d.carve(12, 3, 1, 1)
	d.carve(12, 9, 1, 1)
	d.carve(12, 16, 1, 1)
	d.carve(15, 2, 1, 1)
	d.carve(15, 10, 1, 1)
	d.carve(15, 15, 1, 1)
	# alcova da saída (trancada)
	for yy in range(1, 6):
		d.set_cell(24, yy, "#")
	d.set_cell(24, 3, "D")
	d.set_cell(27, 3, "Z")

	d.start = Vector2i(3, 17)
	d.key = Vector2i(2, 2)
	d.door = Vector2i(24, 3)

	# L1
	d.add_obj("shelf", 1, 1, 3)
	d.add_obj("barrel", 1, 5)
	d.add_obj("table", 5, 3, 2)
	d.add_obj("crate", 9, 1, 2)
	d.add_obj("barrel", 11, 5)
	# L2
	d.add_obj("bed", 1, 8, 2, 2)
	d.add_obj("table", 6, 10, 3)
	d.add_obj("crate", 10, 7, 2)
	d.add_obj("barrel", 1, 12)
	d.add_obj("barrel", 11, 12)
	# L3
	d.add_obj("shelf", 1, 14, 3)
	d.add_obj("table", 6, 16, 2)
	d.add_obj("crate", 9, 14)
	d.add_obj("barrel", 10, 18)
	d.add_obj("barrel", 11, 18)
	# R1
	d.add_obj("shelf", 17, 1, 3)
	d.add_obj("bed", 16, 4, 2, 2)
	d.add_obj("table", 19, 4, 3)
	d.add_obj("barrel", 22, 1)
	d.add_obj("barrel", 22, 5)
	# R2
	d.add_obj("table", 18, 8, 2)
	d.add_obj("bed", 25, 9, 2, 2)
	d.add_obj("crate", 21, 11, 2)
	d.add_obj("barrel", 28, 7)
	d.add_obj("barrel", 28, 12)
	# R3
	d.add_obj("table", 20, 16, 3)
	d.add_obj("shelf", 25, 14, 4)
	d.add_obj("barrel", 28, 18)
	d.add_obj("crate", 17, 18)

	d.add_monster([[13, 2], [13, 17], [14, 17], [14, 2]], 0)
	d.add_monster([[4, 2], [10, 4], [13, 3], [10, 9], [4, 11], [8, 8], [13, 9]], 3)
	d.add_monster([[17, 3], [22, 4], [14, 5], [17, 9], [27, 11], [21, 9], [14, 12]], 0)
	d.add_monster([[18, 16], [26, 16], [24, 18], [14, 15], [14, 12], [20, 10], [27, 8]], 1)
	return d
