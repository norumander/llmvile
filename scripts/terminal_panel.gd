extends InteractionPanel
class_name TerminalPanel

signal session_ended
signal status_changed(new_status: NpcStatus.Status)

const QUIET_THRESHOLD_SEC := 1.5

var _panel_opened: bool = false
var _has_been_opened_once: bool = false
var _has_unread: bool = false
var _last_activity_time: float = 0.0
var _current_status: NpcStatus.Status = NpcStatus.Status.IDLE

@onready var _pty: Node = $PTY
@onready var _terminal: Control = $Frame/Terminal
@onready var _status_timer: Timer = $StatusTimer
@onready var _title_label: Label = $Frame/TitleBar/Title
@onready var _close_button: Button = $Frame/TitleBar/CloseButton

func _ready() -> void:
	_terminal.data_sent.connect(_on_terminal_data_sent)
	_pty.data_received.connect(_on_pty_data_received)
	_pty.exited.connect(_on_pty_exited)
	_terminal.resized.connect(_on_terminal_resized)
	_close_button.pressed.connect(close)
	_status_timer.timeout.connect(_recompute_status)
	var err: int = _pty.fork()
	if err != OK:
		push_error("pty.fork failed: %s" % err)

func show_for(npc) -> void:
	_panel_opened = true
	_has_been_opened_once = true
	_has_unread = false
	visible = true
	_terminal.grab_focus()
	if npc != null and npc.config != null:
		_title_label.text = npc.config.display_name
	_set_status(NpcStatus.Status.IDLE)

func close() -> void:
	_panel_opened = false
	visible = false
	panel_closed.emit()

func _on_terminal_data_sent(data: PackedByteArray) -> void:
	_pty.write(data)

func _on_pty_data_received(data: PackedByteArray) -> void:
	_terminal.write(data)
	_last_activity_time = Time.get_ticks_msec() / 1000.0
	if not _panel_opened:
		_has_unread = true
	_recompute_status()

func _on_pty_exited(_code: int, _signum: int) -> void:
	session_ended.emit()

func _on_terminal_resized() -> void:
	_pty.resize(_terminal.get_cols(), _terminal.get_rows())

func _recompute_status() -> void:
	var next: NpcStatus.Status
	if not _has_been_opened_once:
		# Suppress status before the first interaction — the initial shell
		# prompt shouldn't light up the NPC before the user has touched it.
		next = NpcStatus.Status.IDLE
	elif _panel_opened:
		next = NpcStatus.Status.IDLE
	elif not _has_unread:
		next = NpcStatus.Status.IDLE
	else:
		var quiet: bool = (Time.get_ticks_msec() / 1000.0) - _last_activity_time >= QUIET_THRESHOLD_SEC
		next = NpcStatus.Status.NOTIFY if quiet else NpcStatus.Status.BUSY
	_set_status(next)

func _apply_terminal_font_size(pt: int) -> void:
	_terminal.add_theme_font_size_override("normal_font_size", pt)
	_terminal.add_theme_font_size_override("bold_font_size", pt)
	_terminal.add_theme_font_size_override("italics_font_size", pt)
	_terminal.add_theme_font_size_override("bold_italics_font_size", pt)

func _set_status(new_status: NpcStatus.Status) -> void:
	if new_status == _current_status:
		return
	_current_status = new_status
	status_changed.emit(new_status)
