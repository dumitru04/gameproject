# game_over_menu.gd
extends CanvasLayer

# ВАЖНО: Проверьте эти пути к узлам в вашей сцене game_over_menu.tscn!
@onready var title_label: Label = $Background/MainContainer/TitleLabel # Если у вас есть TitleLabel
@onready var score_label: Label = $Background/MainContainer/ScoreLabel
@onready var restart_button: Button = $Background/MainContainer/RestartButton
@onready var exit_menu_button: Button = $Background/MainContainer/ExitMenuButton

var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	print("[GameOverMenu] _ready: Сцена Game Over инициализирована.")
	print("[GameOverMenu] _ready: Process Mode этого узла (CanvasLayer): " + str(get_process_mode())) # Должно быть 3 (When Paused)
	hide() 

	if not title_label: print("[GameOverMenu] _ready: Узел TitleLabel не найден (это нормально, если его нет).")
	if not score_label: print("[GameOverMenu] _ready: !!! ОШИБКА - ScoreLabel не найден! Проверьте путь.")
	if not restart_button: print("[GameOverMenu] _ready: !!! ОШИБКА - RestartButton не найден! Проверьте путь.")
	if not exit_menu_button: print("[GameOverMenu] _ready: !!! ОШИБКА - ExitMenuButton не найден! Проверьте путь.")

	if restart_button: restart_button.pressed.connect(_on_RestartButton_pressed)
	if exit_menu_button: exit_menu_button.pressed.connect(_on_ExitMenuButton_pressed)

func show_screen(final_score: int):
	print("[GameOverMenu] show_screen ВЫЗВАНА. Финальный счет: {final_score}")
	if score_label:
		score_label.text = "Счет: %06d" % final_score
	
	if not is_inside_tree():
		print("[GameOverMenu] show_screen: !!! ОШИБКА - Узел еще не в дереве сцены при вызове show_screen!")
		return

	get_tree().paused = true
	print("[GameOverMenu] show_screen: get_tree().paused установлено в " + str(get_tree().paused))
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	print("[GameOverMenu] show_screen: Меню Game Over показано (visible=true), мышь видима.")

func _cleanup_and_unpause():
	hide() 
	Input.set_mouse_mode(previous_mouse_mode) 
	get_tree().paused = false 
	print("[GameOverMenu] _cleanup_and_unpause: Игра снята с паузы, меню скрыто.")

func _on_RestartButton_pressed():
	print("[GameOverMenu] Нажата кнопка 'Перезапустить уровень'.")
	_cleanup_and_unpause()
	
	GameManager.reset_game_state() 
	print("[GameOverMenu] GameManager.reset_game_state() вызван.")
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("[GameOverMenu] !!! ОШИБКА перезапуска уровня: " + error_string(error))
	
	queue_free() # НОВОЕ: Удаляем экземпляр меню после действия

func _on_ExitMenuButton_pressed():
	print("[GameOverMenu] Нажата кнопка 'Выход в главное меню'.")
	_cleanup_and_unpause()
	
	print("[GameOverMenu] Выход из игры...")
	get_tree().quit()
	# queue_free() // Не обязательно, так как игра закрывается
