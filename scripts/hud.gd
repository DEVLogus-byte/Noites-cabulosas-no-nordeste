class_name Hud
extends Node2D
## Interface: objetivo, dicas, mensagens, cartão de início de fase e tela de "pego".

var level

func _process(_delta: float) -> void:
	queue_redraw()

func _panel(r: Rect2) -> void:
	draw_rect(r, Color("e8e0c8"))
	draw_rect(r.grow(-1), Color("17112e"))
	draw_rect(r.grow(-2), Color("3a2f6e"))
	draw_rect(r.grow(-3), Color("17112e"))

func _draw() -> void:
	if level == null:
		return
	var L = level

	# borda vermelha pulsante quando algum capanga te persegue
	if L.chasers > 0 and L.is_playing():
		var a := 0.16 + 0.12 * sin(L.time * 12.0)
		draw_rect(Rect2(2, 2, 236, 156), Color(1.0, 0.1, 0.1, a), false, 4.0)

	# barra de objetivo
	draw_rect(Rect2(0, 0, 240, 11), Color(0, 0, 0, 0.62))
	PixelFont.draw(self, L.objective(), Vector2(4, 3), Color("e8e0c8"))
	if L.has_key:
		Overlay.draw_key(self, Vector2(226, 9))
	if L.player.hiding:
		PixelFont.draw(self, "ESCONDIDO", Vector2(150, 3), Color("7fd1ff"))

	# dica de interação
	if L.prompt != "" and L.is_playing():
		var w := PixelFont.width(L.prompt) + 10
		var r := Rect2(120 - w / 2.0, 147, w, 11)
		_panel(r)
		PixelFont.center(self, L.prompt, 120, 150, Color("f0e8d0"), 1, false)

	# caixa de mensagem
	if L.msg_t > 0.0 and L.msg != "":
		var lines: PackedStringArray = L.msg.split("\n")
		var width := 0
		for ln in lines:
			width = maxi(width, PixelFont.width(ln))
		var rr := Rect2(120 - (width + 12) / 2.0, 15, width + 12, lines.size() * 8 + 6)
		_panel(rr)
		for i in range(lines.size()):
			PixelFont.center(self, lines[i], 120, 19 + i * 8, Color("f0e8d0"), 1, false)

	# cartão de início de fase
	if L.card_t > 0.0:
		var fa := clampf(L.card_t / 0.7, 0.0, 1.0)
		draw_rect(Rect2(0, 56, 240, 44), Color(0, 0, 0, 0.78 * fa))
		PixelFont.center(self, L.data.card_title, 120, 62, Color(0.9, 0.3, 0.35, fa), 3)
		PixelFont.center(self, L.data.card_sub, 120, 84, Color(0.9, 0.85, 0.72, fa), 2)

	# pego!
	if L.is_caught() and L.caught_t > 0.6:
		var ca := clampf((L.caught_t - 0.6) / 0.6, 0.0, 1.0)
		draw_rect(Rect2(0, 0, 240, 160), Color(0.25, 0, 0, 0.55 * ca))
		PixelFont.center(self, "LASCOU-SE!", 120, 58, Color(1.0, 0.3, 0.3, ca), 3)
		PixelFont.center(self, "OS CABRAS DO LAMPIÃO TE PEGARAM!", 120, 80, Color(0.95, 0.85, 0.7, ca), 1)
		if L.caught_t > 1.3 and int(L.caught_t * 2.0) % 2 == 0:
			PixelFont.center(self, "ENTER: BORA DE NOVO", 120, 100, Color("f0e8d0"), 1)
