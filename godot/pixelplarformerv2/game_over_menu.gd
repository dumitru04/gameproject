# game_over_menu.gd
extends CanvasLayer

# ВАЖНО: Проверьте эти пути к узлам в вашей сцене game_over_menu.tscn!
@onready var score_label: Label = $MainContainer/ScoreLabel 
@onready var restart_button: Button = $MainContainer/RestartButton
@onready var exit_menu_button: Button = $MainContainer/ExitMenuButton

var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	hide()
	print("-----------------------------------------------------")
	print("[GameOverMenu] _ready: Инициализация. Process Mode: " + str(get_process_mode()))

	if not score_label: print("[GameOverMenu] _ready: !!! ОШИБКА - ScoreLabel не найден!")
	else: print("[GameOverMenu] _ready: ScoreLabel НАЙДЕН.")

	# Проверка и подключение RestartButton
	if not restart_button: 
		print("[GameOverMenu] _ready: !!! ОШИБКА - RestartButton НЕ НАЙДЕН!")
	else:
		print("[GameOverMenu] _ready: RestartButton НАЙДЕН.")
		var err_restart = restart_button.pressed.connect(_on_RestartButton_pressed)
		if err_restart == OK: print("[GameOverMenu] _ready: Сигнал RestartButton.pressed УСПЕШНО подключен.")
		else: print("[GameOverMenu] _ready: !!! ОШИБКА подключения RestartButton.pressed. Код: " + str(err_restart))
			
	# Проверка и подключение ExitMenuButton
	if not exit_menu_button: 
		print("[GameOverMenu] _ready: !!! ОШИБКА - ExitMenuButton НЕ НАЙДЕН!")
	else:
		print("[GameOverMenu] _ready: ExitMenuButton НАЙДЕН.")
		var err_exit = exit_menu_button.pressed.connect(_on_ExitMenuButton_pressed)
		if err_exit == OK: print("[GameOverMenu] _ready: Сигнал ExitMenuButton.pressed УСПЕШНО подключен.")
		else: print("[GameOverMenu] _ready: !!! ОШИБКА подключения ExitMenuButton.pressed. Код: " + str(err_exit))
	print("-----------------------------------------------------")


func show_screen(final_score: int):
	# ... (код без изменений, с print внутри для отладки установки текста) ...
	print("[GameOverMenu] show_screen ВЫЗВАНА. Финальный счет: {final_score}")
	if score_label: score_label.text = "Счет: %06d" % final_score
	get_tree().paused = true
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()


func _cleanup_and_unpause(): # Ваша вспомогательная функция
	hide() 
	Input.set_mouse_mode(previous_mouse_mode) 
	get_tree().paused = false 
	queue_free() 
	print("[GameOverMenu] Меню очищено, игра снята с паузы, экземпляр удален.")


func _on_RestartButton_pressed():
	print("[GameOverMenu] ФУНКЦИЯ _on_RestartButton_pressed ВЫЗВАНА.")
	_cleanup_and_unpause()
	GameManager.restart_failed_level() # Перезапускаем проигранный уровень


func _on_ExitMenuButton_pressed():
	print("[GameOverMenu] ФУНКЦИЯ _on_ExitMenuButton_pressed ВЫЗВАНА.")
	_cleanup_and_unpause()
	# GameManager.start_new_game() # Выход в меню = начало новой игровой сессии
	# Загрузка главного меню теперь происходит через GameManager.start_new_game() -> загрузка первого уровня,
	# или если у вас есть сцена главного меню, то ее нужно загружать:
	get_tree().change_scene_to_file("res://main_menu.tscn")
