extends Node
## Autoload "Game": mapeamento de teclas, efeitos sonoros gerados por código e constantes globais.

const SCREEN := Vector2(240, 160)

var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _next := 0

func _ready() -> void:
	_setup_input()
	_setup_audio()

# ---------------------------------------------------------------- entrada
func _key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _pad(action: String, button) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _axis(action: String, axis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)

func _setup_input() -> void:
	_key("move_left", [KEY_A, KEY_LEFT])
	_key("move_right", [KEY_D, KEY_RIGHT])
	_key("move_up", [KEY_W, KEY_UP])
	_key("move_down", [KEY_S, KEY_DOWN])
	_key("run", [KEY_SHIFT, KEY_X])
	_key("interact", [KEY_E, KEY_Z, KEY_SPACE])
	_key("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z, KEY_E])
	_pad("move_left", JOY_BUTTON_DPAD_LEFT)
	_pad("move_right", JOY_BUTTON_DPAD_RIGHT)
	_pad("move_up", JOY_BUTTON_DPAD_UP)
	_pad("move_down", JOY_BUTTON_DPAD_DOWN)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_pad("run", JOY_BUTTON_B)
	_pad("interact", JOY_BUTTON_A)
	_pad("confirm", JOY_BUTTON_A)
	_pad("confirm", JOY_BUTTON_START)

# ------------------------------------------------------------------ áudio
func _setup_audio() -> void:
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_streams["blip"] = _wave(880.0, 0.06, 0.0, 0.35)
	_streams["alert"] = _wave(260.0, 0.35, 700.0, 0.45)
	_streams["key"] = _wave(660.0, 0.30, 700.0, 0.35)
	_streams["hide"] = _wave(220.0, 0.12, -90.0, 0.35)
	_streams["deny"] = _wave(140.0, 0.15, 0.0, 0.35)
	_streams["fall"] = _wave(700.0, 0.9, -640.0, 0.4)
	_streams["door"] = _noise(0.35, 0.4, 14)
	_streams["thud"] = _noise(0.25, 0.6, 90)
	_streams["catch"] = _noise(0.6, 0.55, 30)
	_streams["rumble"] = _noise(2.2, 0.5, 60)
	var amb := AudioStreamPlayer.new()
	amb.stream = _drone()
	amb.volume_db = -16.0
	add_child(amb)
	amb.play()

func sfx(id: String) -> void:
	if not _streams.has(id):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[id]
	p.play()

func _to_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

func _wave(freq: float, dur: float, slide: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(n)
		phase += (freq + slide * t) / float(rate)
		var s := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		data[i] = int(s * vol * (1.0 - t) * 120.0) & 0xFF
	return _to_wav(data, rate)

func _noise(dur: float, vol: float, hold: int) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n)
	var held := 0.0
	for i in range(n):
		var t := float(i) / float(n)
		if i % hold == 0:
			held = randf() * 2.0 - 1.0
		data[i] = int(held * vol * (1.0 - t) * 120.0) & 0xFF
	return _to_wav(data, rate)

func _drone() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 2
	var data := PackedByteArray()
	data.resize(n)
	for i in range(n):
		var t := float(i) / float(rate)
		var s := sin(TAU * 82.0 * t) * 0.5 + sin(TAU * 86.0 * t) * 0.4 + sin(TAU * 164.0 * t) * 0.06
		data[i] = int(s * 80.0) & 0xFF
	var w := _to_wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w
