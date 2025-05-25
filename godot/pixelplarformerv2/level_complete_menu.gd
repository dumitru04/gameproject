# level_complete_menu.gd
extends CanvasLayer

# ВАЖНО: Проверьте, что эти пути ТОЧНО соответствуют вашей иерархии в сцене level_complete_menu.tscn
@onready var next_level_button: Button = $MainContainer/NextLevelButton
@onready var restart_button: Button = $MainContainer/RestartButton
@onready var level_select_button: Button = $MainContainer/LevelSelectButton
@onready var exit_menu_button: Button = $MainContainer/ExitToMenuButton

@onready var level_score_display_label: Label = $MainContainer/LevelScoreDisplayLabel 
@onready var time_bonus_display_label: Label = $MainContainer/TimeBonusDisplayLabel  
@onready var final_total_score_label: Label = $MainContainer/FinalTotalScoreLabel 

var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	hide()
	print("-----------------------------------------------------")
	print("[LvlCompleteMenu] _ready: Инициализация. Process Mode: " + str(get_process_mode()))

	# Проверка и подключение NextLevelButton
	if not next_level_button: 
		print("[LvlCompleteMenu] _ready: !!! ОШИБКА - NextLevelButton НЕ НАЙДЕН!")
	else:
		print("[LvlCompleteMenu] _ready: NextLevelButton НАЙДЕН.")
		var err_next = next_level_button.pressed.connect(_on_NextLevelButton_pressed)
		if err_next == OK: print("[LvlCompleteMenu] _ready: Сигнал NextLevelButton.pressed УСПЕШНО подключен.")
		else: print("[LvlCompleteMenu] _ready: !!! ОШИБКА подключения NextLevelButton.pressed. Код: " + str(err_next))

	# Проверка и подключение RestartButton
	if not restart_button: 
		print("[LvlCompleteMenu] _ready: !!! ОШИБКА - RestartButton НЕ НАЙДЕН!")
	else:
		print("[LvlCompleteMenu] _ready: RestartButton НАЙДЕН.")
		var err_restart = restart_button.pressed.connect(_on_RestartButton_pressed)
		if err_restart == OK: print("[LvlCompleteMenu] _ready: Сигнал RestartButton.pressed УСПЕШНО подключен.")
		else: print("[LvlCompleteMenu] _ready: !!! ОШИБКА подключения RestartButton.pressed. Код: " + str(err_restart))

	# Проверка и подключение LevelSelectButton
	if not level_select_button: 
		print("[LvlCompleteMenu] _ready: !!! ОШИБКА - LevelSelectButton НЕ НАЙДЕН!")
	else:
		print("[LvlCompleteMenu] _ready: LevelSelectButton НАЙДЕН.")
		var err_select = level_select_button.pressed.connect(_on_LevelSelectButton_pressed)
		if err_select == OK: print("[LvlCompleteMenu] _ready: Сигнал LevelSelectButton.pressed УСПЕШНО подключен.")
		else: print("[LvlCompleteMenu] _ready: !!! ОШИБКА подключения LevelSelectButton.pressed. Код: " + str(err_select))
			
	# Проверка и подключение ExitToMenuButton
	if not exit_menu_button: 
		print("[LvlCompleteMenu] _ready: !!! ОШИБКА - ExitToMenuButton НЕ НАЙДЕН!")
	else:
		print("[LvlCompleteMenu] _ready: ExitToMenuButton НАЙДЕН.")
		var err_exit = exit_menu_button.pressed.connect(_on_ExitToMenuButton_pressed)
		if err_exit == OK: print("[LvlCompleteMenu] _ready: Сигнал ExitToMenuButton.pressed УСПЕШНО подключен.")
		else: print("[LvlCompleteMenu] _ready: !!! ОШИБКА подключения ExitToMenuButton.pressed. Код: " + str(err_exit))
	print("-----------------------------------------------------")
	# ... (проверка меток для счета, если нужно)


func setup_menu_with_stats(stats: Dictionary):
	# ... (код без изменений, с print внутри для отладки установки текста) ...
	print("[LevelCompleteMenu] setup_menu_with_stats ВЫЗВАНА. Получены данные: {stats}")
	if level_score_display_label and stats.has("score_at_finish"): level_score_display_label.text = "Очки: " + str(stats.score_at_finish)
	if time_bonus_display_label and stats.has("time_bonus"): time_bonus_display_label.text = "Бонус за время: " + str(stats.time_bonus)
	if final_total_score_label and stats.has("final_total_score"): final_total_score_label.text = "Итого: %06d" % stats.final_total_score
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _cleanup_and_hide():
	# ... (код без изменений) ...
	Input.set_mouse_mode(previous_mouse_mode) 
	hide()
	queue_free() 
	print("[LevelCompleteMenu] Меню очищено и удалено.")

func _on_NextLevelButton_pressed():
	print("[LvlCompleteMenu] ФУНКЦИЯ _on_NextLevelButton_pressed ВЫЗВАНА.")
	# ... (остальная логика) ...
	get_tree().paused = false
	var went_to_next = GameManager.go_to_next_level()
	if not went_to_next:
		GameManager.start_new_game() 
		var main_menu_path = "res://main_menu.tscn" 
		get_tree().change_scene_to_file(main_menu_path)
	_cleanup_and_hide()


func _on_RestartButton_pressed():
	print("[LvlCompleteMenu] ФУНКЦИЯ _on_RestartButton_pressed ВЫЗВАНА.")
	# ... (остальная логика) ...
	get_tree().paused = false
	var error = get_tree().reload_current_scene()
	if error != OK: printerr("[LevelCompleteMenu] !!! ОШИБКА перезапуска уровня: {error_string(error)}")
	_cleanup_and_hide()


func _on_LevelSelectButton_pressed():
	print("[LvlCompleteMenu] ФУНКЦИЯ _on_LevelSelectButton_pressed ВЫЗВАНА.")
	# ... (остальная логика) ...
	get_tree().paused = false
	GameManager.start_new_game() 
	print("Логика выбора уровня не реализована. Запуск новой игры (заглушка).")
	_cleanup_and_hide()


func _on_ExitToMenuButton_pressed():
	print("[LvlCompleteMenu] ФУНКЦИЯ _on_ExitToMenuButton_pressed ВЫЗВАНА.")
	# ... (остальная логика) ...
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# GameManager.start_new_game() # Выход в меню = начало новой игровой сессии
	var main_menu_path = "res://main_menu.tscn" # GameManager.start_new_game() уже загрузит первый уровень или меню
	get_tree().change_scene_to_file(main_menu_path)
	_cleanup_and_hide()
