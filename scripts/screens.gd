class_name CardScreen
extends Node2D
## Telas estáticas: título e "FIM DA DEMO".

signal done

var kind := "title"
var t := 0.0
var fired := false
var stars: Array[Vector3] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(40):
		stars.append(Vector3(rng.randf_range(0.0, 240.0), rng.randf_range(0.0, 90.0), rng.randf_range(0.0, TAU)))

func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 0.7 and not fired and Input.is_action_just_pressed("confirm"):
		fired = true
		Game.sfx("blip")
		done.emit()

func _draw() -> void:
	if kind == "title":
		_title()
	else:
		_end()

func _title() -> void:
	draw_rect(Rect2(0, 0, 240, 160), Color("0b0716"))
	for s in stars:
		var a := 0.35 + 0.35 * sin(t * 2.0 + s.z)
		draw_rect(Rect2(floorf(s.x), floorf(s.y), 1, 1), Color(1, 1, 0.9, a))
	draw_circle(Vector2(196, 44), 15.0, Color("e9e5c6"))
	draw_circle(Vector2(191, 40), 3.0, Color("cdc7a4"))
	draw_circle(Vector2(201, 49), 2.0, Color("cdc7a4"))
	var c := Color("120d1c")
	var c2 := Color("1a1429")
	draw_rect(Rect2(52, 84, 136, 54), c)
	draw_colored_polygon(PackedVector2Array([Vector2(46, 84), Vector2(120, 56), Vector2(194, 84)]), c)
	draw_rect(Rect2(36, 72, 22, 66), c2)
	draw_colored_polygon(PackedVector2Array([Vector2(32, 72), Vector2(47, 48), Vector2(62, 72)]), c2)
	draw_rect(Rect2(182, 72, 22, 66), c2)
	draw_colored_polygon(PackedVector2Array([Vector2(178, 72), Vector2(193, 48), Vector2(208, 72)]), c2)
	var wins := [Vector2(43, 80), Vector2(189, 80), Vector2(66, 96), Vector2(86, 96), Vector2(144, 96),
		Vector2(164, 96), Vector2(66, 118), Vector2(164, 118), Vector2(116, 70)]
	for i in range(wins.size()):
		var on := sin(t * 1.3 + i * 2.1) > -0.55
		var col := Color("f2b84b") if on else Color("3a2a20")
		var w: Vector2 = wins[i]
		draw_rect(Rect2(w.x, w.y, 8, 10), col)
		draw_rect(Rect2(w.x + 3, w.y, 1, 10), c)
	draw_rect(Rect2(112, 112, 16, 26), Color("2a180e"))
	draw_rect(Rect2(114, 114, 12, 24), Color("e8a33d") if sin(t * 3.0) > -0.9 else Color("a0702a"))
	draw_rect(Rect2(0, 136, 240, 24), Color("08050e"))
	for x in range(0, 240, 8):
		draw_rect(Rect2(x, 128, 1, 10), Color("0d0916"))
	draw_rect(Rect2(0, 130, 240, 1), Color("0d0916"))
	draw_rect(Rect2(fposmod(t * 8.0, 300.0) - 60.0, 124, 80, 6), Color(0.6, 0.6, 0.75, 0.07))
	draw_rect(Rect2(fposmod(t * 5.0 + 150.0, 300.0) - 60.0, 118, 60, 5), Color(0.6, 0.6, 0.75, 0.06))
	PixelFont.center(self, "NOITES CABULOSAS", 120, 9, Color("c8364b"), 3)
	PixelFont.center(self, "- DEMO -", 120, 31, Color("d8d0b8"), 2)
	PixelFont.center(self, "CAPANGAS DO LAMPIÃO NO CASARÃO", 120, 47, Color("e0a040"), 1)
	if int(t * 2.0) % 2 == 0:
		PixelFont.center(self, "APERTE ENTER", 120, 139, Color("f0e8d0"), 2)
	PixelFont.center(self, "SETAS/WASD: MOVER  SHIFT: CORRER  E: INTERAGIR", 120, 152, Color("8c84a8"), 1)

func _end() -> void:
	draw_rect(Rect2(0, 0, 240, 160), Color("050308"))
	var eyes := [Vector2(30, 30), Vector2(200, 50), Vector2(60, 120), Vector2(170, 125),
		Vector2(120, 18), Vector2(215, 100), Vector2(20, 80)]
	for i in range(eyes.size()):
		if sin(t * 0.8 + i * 1.7) > -0.2:
			var p: Vector2 = eyes[i]
			draw_rect(Rect2(p.x, p.y, 3, 2), Color("d83a3a"))
			draw_rect(Rect2(p.x + 6, p.y, 3, 2), Color("d83a3a"))
	PixelFont.center(self, "FIM DA DEMO", 120, 52, Color("d8d0b8"), 4)
	PixelFont.center(self, "VALEU, CABRA DA PESTE!", 120, 84, Color("c8364b"), 2)
	if int(t * 2.0) % 2 == 0:
		PixelFont.center(self, "APERTE ENTER PRA VOLTAR AO MENU", 120, 130, Color("8c84a8"), 1)
