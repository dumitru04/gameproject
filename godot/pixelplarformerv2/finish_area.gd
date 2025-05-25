# finish_area.gd
extends Area2D

signal player_reached_finish(player_node: Node2D) # Сигнал, который будет отправлен уровню

func _ready():
	body_entered.connect(_on_body_entered)
	print("[" + name + "] FinishArea готова и ожидает игрока.")

func _on_body_entered(body: Node2D):
	# Проверяем, что это игрок и у него есть нужный метод (для запуска анимации убегания)
	if body.is_in_group("player") and body.has_method("start_level_complete_sequence"):
		print("[" + name + "] Игрок достиг финиша!")
		# Отключаем дальнейшее обнаружение, чтобы сигнал сработал только один раз
		set_deferred("monitoring", false) 
		set_deferred("monitorable", false) # Для Godot 4.x monitorable более актуально
		emit_signal("player_reached_finish", body) # Отправляем сигнал вместе с узлом игрока
