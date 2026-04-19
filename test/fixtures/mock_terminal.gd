extends Control

signal data_sent(data: PackedByteArray)
# resized is a Control signal — no redeclaration needed.

var cols: int = 80
var rows: int = 24
var written: Array[PackedByteArray] = []

func get_cols() -> int:
	return cols

func get_rows() -> int:
	return rows

func write(data) -> void:
	var bytes: PackedByteArray
	if data is PackedByteArray:
		bytes = data
	elif data is String:
		bytes = data.to_utf8_buffer()
	written.append(bytes)

# grab_focus() is a native Control method; we don't override it. Production
# godot-xterm Terminal sets focus_mode=2 and accepts the native call.
