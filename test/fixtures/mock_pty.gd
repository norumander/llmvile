extends Node

signal data_received(data: PackedByteArray)
signal exited(exit_code: int, signum: int)

var fork_calls: int = 0
var write_calls: Array[PackedByteArray] = []
var resize_calls: Array = []  # Array[Vector2i]

func fork(_file := "", _args := [], _cwd := "", _cols := 0, _rows := 0) -> int:
	fork_calls += 1
	return OK

func write(data) -> void:
	var bytes: PackedByteArray
	if data is PackedByteArray:
		bytes = data
	elif data is String:
		bytes = data.to_utf8_buffer()
	write_calls.append(bytes)

func resize(cols: int, rows: int) -> void:
	resize_calls.append(Vector2i(cols, rows))

func emit_output(text: String) -> void:
	data_received.emit(text.to_utf8_buffer())

func emit_exit(code: int = 0, sig: int = 0) -> void:
	exited.emit(code, sig)
