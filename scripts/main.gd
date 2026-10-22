extends Node
## Controla o fluxo do jogo: título -> fase 1 -> (chão quebra) -> fase 2 -> FIM DA DEMO.

var current: Node = null
var fade: ColorRect
var busy := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.size = Game.SCREEN
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	_transition(_make_title)

func _unhandled_input(event: InputEvent) -> void:
	# ESC volta ao título durante o jogo
	if event.is_action_pressed("ui_cancel") and current is Level:
		_transition(_make_title)

func _fade_to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, seconds)
	await tw.finished

func _transition(make: Callable) -> void:
	if busy:
		return
	busy = true
	await _fade_to(1.0, 0.4)
	if current != null:
		remove_child(current)
		current.queue_free()
	current = make.call()
	add_child(current)
	await _fade_to(0.0, 0.4)
	busy = false

func _make_title() -> Node:
	var s := CardScreen.new()
	s.kind = "title"
	s.done.connect(_on_title_done)
	return s

func _make_end() -> Node:
	var s := CardScreen.new()
	s.kind = "end"
	s.done.connect(func(): _transition(_make_title))
	return s

func _on_title_done() -> void:
	_transition(func(): return _make_level(0, false))

func _make_level(index: int, landing: bool) -> Node:
	var lv := Level.new()
	lv.setup(LevelData.get_level(index), landing)
	lv.retry_requested.connect(func(): _transition(func(): return _make_level(index, landing)))
	lv.fell_to_next.connect(func(): _transition(func(): return _make_level(1, true)))
	lv.reached_exit.connect(func(): _transition(_make_end))
	return lv
