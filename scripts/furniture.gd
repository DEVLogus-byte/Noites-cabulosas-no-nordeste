class_name Furniture
extends Node2D
## Móvel desenhado por código. Mesas e camas permitem se esconder embaixo.

const T := 16

var kind := "table"
var tw := 1
var th := 1
var cell := Vector2i.ZERO
var hideable := false
var occupied := false
var rect := Rect2()

func _process(_delta: float) -> void:
	if occupied:
		queue_redraw()

func _draw() -> void:
	var W := tw * T
	var H := th * T
	match kind:
		"table": _table(W)
		"bed": _bed(W, H)
		"shelf": _shelf(W)
		"wardrobe": _wardrobe(W)
		"plant": _plant()
		"barrel": _barrel()
		"crate": _crate(W)

func _eyes(x: float, y: float) -> void:
	# olhinhos brilhando no escuro: o jogador escondido
	if fmod(Time.get_ticks_msec() / 1000.0, 3.2) < 0.18:
		return
	draw_rect(Rect2(x - 3, y, 2, 2), Color("ffe58a"))
	draw_rect(Rect2(x + 2, y, 2, 2), Color("ffe58a"))

func _table(W: int) -> void:
	draw_rect(Rect2(0, 1, W, 9), Color("a9774b"))
	draw_rect(Rect2(0, 1, W, 1), Color("cf9f6e"))
	draw_rect(Rect2(0, 10, W, 3), Color("744a2b"))
	if W >= 48:
		draw_rect(Rect2(3, 3, W - 6, 4), Color("8f2f40"))     # toalha / caminho de mesa
		draw_rect(Rect2(3, 3, W - 6, 1), Color("b24a5b"))
	draw_rect(Rect2(3, 13, W - 6, 3), Color(0, 0, 0, 0.5))    # sombra embaixo
	draw_rect(Rect2(1, 13, 2, 3), Color("4d2e19"))
	draw_rect(Rect2(W - 3, 13, 2, 3), Color("4d2e19"))
	if occupied:
		_eyes(W / 2.0, 13)

func _bed(W: int, H: int) -> void:
	draw_rect(Rect2(0, 0, W, H), Color("4a2f1e"))
	draw_rect(Rect2(2, 2, W - 4, H - 8), Color("d9d3c2"))
	draw_rect(Rect2(4, 4, W - 8, 7), Color("f2eee2"))
	draw_rect(Rect2(2, 14, W - 4, H - 22), Color("7b3043"))
	draw_rect(Rect2(2, 14, W - 4, 1), Color("a54a5e"))
	draw_rect(Rect2(0, H - 6, W, 6), Color("1f130b"))          # vão embaixo da cama
	draw_rect(Rect2(0, H - 6, 2, 6), Color("4a2f1e"))
	draw_rect(Rect2(W - 2, H - 6, 2, 6), Color("4a2f1e"))
	if occupied:
		_eyes(W / 2.0, H - 4)

func _shelf(W: int) -> void:
	draw_rect(Rect2(0, 0, W, T), Color("4a2f1c"))
	draw_rect(Rect2(1, 1, W - 2, T - 3), Color("22140b"))
	draw_rect(Rect2(1, 7, W - 2, 1), Color("4a2f1c"))
	var cols := [Color("8f2f40"), Color("2f5f8f"), Color("c9a45c"), Color("3f7f4a"), Color("6a4a8a")]
	for i in range(1, W - 3, 3):
		draw_rect(Rect2(i, 2, 2, 5), cols[(i * 7) % 5])
		draw_rect(Rect2(i, 8, 2, 5), cols[(i * 3 + 1) % 5])

func _wardrobe(W: int) -> void:
	draw_rect(Rect2(0, 0, W, T), Color("4d301d"))
	draw_rect(Rect2(1, 1, W - 2, T - 2), Color("6c452b"))
	for i in range(tw):
		draw_rect(Rect2(i * T + 7, 1, 1, T - 3), Color("3b2414"))
		draw_rect(Rect2(i * T + 5, 8, 1, 2), Color("d6b25e"))
		draw_rect(Rect2(i * T + 10, 8, 1, 2), Color("d6b25e"))
	draw_rect(Rect2(0, T - 2, W, 2), Color("2c1a10"))

func _plant() -> void:
	draw_rect(Rect2(7, 1, 2, 3), Color("58b660"))
	draw_rect(Rect2(5, 3, 6, 7), Color("2f7d3c"))
	draw_rect(Rect2(2, 5, 4, 4), Color("3f9a4a"))
	draw_rect(Rect2(10, 4, 4, 5), Color("3f9a4a"))
	draw_rect(Rect2(3, 9, 10, 2), Color("a05a3a"))
	draw_rect(Rect2(4, 11, 8, 5), Color("8a4a30"))

func _barrel() -> void:
	draw_rect(Rect2(3, 2, 10, 13), Color("7a4f2c"))
	draw_rect(Rect2(4, 1, 8, 2), Color("9a6a3a"))
	draw_rect(Rect2(3, 5, 10, 1), Color("3b2a1a"))
	draw_rect(Rect2(3, 11, 10, 1), Color("3b2a1a"))
	draw_rect(Rect2(5, 3, 1, 11), Color("93603a"))
	draw_rect(Rect2(3, 15, 10, 1), Color(0, 0, 0, 0.4))

func _crate(W: int) -> void:
	for i in range(tw):
		var x := i * T
		draw_rect(Rect2(x + 1, 2, 14, 13), Color("8c6a3c"))
		draw_rect(Rect2(x + 1, 2, 14, 1), Color("b08a54"))
		draw_rect(Rect2(x + 1, 14, 14, 1), Color("5c4326"))
		draw_rect(Rect2(x + 1, 2, 1, 13), Color("5c4326"))
		draw_rect(Rect2(x + 14, 2, 1, 13), Color("5c4326"))
		for k in range(10):
			draw_rect(Rect2(x + 3 + k, 4 + k, 1, 1), Color("5c4326"))
			draw_rect(Rect2(x + 12 - k, 4 + k, 1, 1), Color("5c4326"))
