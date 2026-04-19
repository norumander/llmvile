extends Control
class_name Hud

signal spawn_requested

const TOAST_SECONDS := 2.0

@onready var _spawn_button: Button = $SpawnButton
@onready var _toast: Label = $Toast
@onready var _toast_timer: Timer = $ToastTimer

func _ready() -> void:
	_spawn_button.pressed.connect(func(): spawn_requested.emit())
	_toast.visible = false
	_toast_timer.timeout.connect(func(): _toast.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_terminal"):
		_on_spawn_terminal_action()

func _on_spawn_terminal_action() -> void:
	if not GameRoot.world_input_paused:
		spawn_requested.emit()

func show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.visible = true
	_toast_timer.start(TOAST_SECONDS)
