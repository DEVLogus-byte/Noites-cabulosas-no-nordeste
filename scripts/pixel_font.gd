class_name PixelFont
extends RefCounted
## Fonte bitmap 3x5 desenhada com retângulos (visual de GBA, sem arquivos externos).
## Só tem letras maiúsculas; acentos do português são desenhados como um pontinho.

const GLYPHS := {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011",
	"D": "110101101101110", "E": "111100110100111", "F": "111100110100100",
	"G": "011100101101011", "H": "101101111101101", "I": "111010010010111",
	"J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
	"M": "101111111101101", "N": "110101101101101", "O": "010101101101010",
	"P": "110101110100100", "Q": "010101101110011", "R": "110101110101101",
	"S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
	"V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
	"Y": "101101010010010", "Z": "111001010100111",
	"0": "111101101101111", "1": "010110010010111", "2": "110001010100111",
	"3": "110001010001110", "4": "101101111001001", "5": "111100110001110",
	"6": "011100111101111", "7": "111001010010010", "8": "111101111101111",
	"9": "111101111001110",
	"!": "010010010000010", "?": "110001010000010", ".": "000000000000010",
	",": "000000000010100", ":": "000010000010000", "-": "000000111000000",
	"'": "010010000000000", "/": "001001010100100", "(": "001010010010001",
	")": "100010010010100",
}

const ACCENTS := {
	"Á": "A", "À": "A", "Â": "A", "Ã": "A", "É": "E", "Ê": "E", "Í": "I",
	"Ó": "O", "Ô": "O", "Õ": "O", "Ú": "U", "Ç": "C",
}

static func width(text: String, s: int = 1) -> int:
	return maxi(0, text.length() * 4 * s - s)

static func draw(ci: CanvasItem, text: String, pos: Vector2, col: Color, s: int = 1, shadow: bool = true) -> void:
	if shadow:
		_raw(ci, text, pos + Vector2(s, s), Color(0, 0, 0, col.a * 0.85), s)
	_raw(ci, text, pos, col, s)

static func center(ci: CanvasItem, text: String, cx: float, y: float, col: Color, s: int = 1, shadow: bool = true) -> void:
	draw(ci, text, Vector2(cx - width(text, s) / 2.0, y), col, s, shadow)

static func _raw(ci: CanvasItem, text: String, pos: Vector2, col: Color, s: int) -> void:
	var x := pos.x
	var up := text.to_upper()
	for i in range(up.length()):
		var ch: String = up[i]
		var accent := ""
		if ACCENTS.has(ch):
			accent = ch
			ch = ACCENTS[ch]
		if GLYPHS.has(ch):
			var bits: String = GLYPHS[ch]
			for k in range(15):
				if bits[k] == "1":
					ci.draw_rect(Rect2(x + (k % 3) * s, pos.y + floori(k / 3.0) * s, s, s), col)
		if accent == "Ç":
			ci.draw_rect(Rect2(x + s, pos.y + 5 * s, s, s), col)
		elif accent != "":
			ci.draw_rect(Rect2(x + s, pos.y - 2 * s, s, s), col)
		x += 4 * s
