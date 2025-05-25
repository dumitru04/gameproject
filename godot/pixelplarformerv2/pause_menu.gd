# pause_menu.gd
extends CanvasLayer

# ВАЖНО: Адаптируйте пути к вашей структуре узлов в pause_menu.tscn!
@onready var continue_button: Button = $BackgroundDim/MenuButtons/ContinueButton 
@onready var settings_button: Button = $BackgroundDim/MenuButtons/SettingsButton
@onready var restart_button: Button = $BackgroundDim/MenuButtons/RestartButton
@onready var exit_button: Button = $BackgroundDim/MenuButtons/ExitButton

var previous_mouse_mode = Input.MOUSE_MODE_HIDDEN # Предполагаем, что в игре мышь скрыта/захвачена

func _ready():
	print("[PauseMenu] _ready: Меню паузы готово. Process Mode: " + str(get_process_mode()))
	hide() 
	
	if not continue_button: print("[PauseMenu] _ready: !!! ОШИБКА - ContinueButton не найден!")
	else: continue_button.pressed.connect(_on_ContinueButton_pressed)

	if not settings_button: print("[PauseMenu] _ready: !!! ОШИБКА - SettingsButton не найден!")
	else: settings_button.pressed.connect(_on_SettingsButton_pressed)

	if not restart_button: print("[PauseMenu] _ready: !!! ОШИБКА - RestartButton не найден!")
	else: restart_button.pressed.connect(_on_RestartButton_pressed)
	
	if not exit_button: print("[PauseMenu] _ready: !!! ОШИБКА - ExitButton не найден!")
	else: exit_button.pressed.connect(_on_ExitButton_pressed)

# Вызывается извне (например, player.gd) для показа меню
func open_menu_and_pause():
	print("[PauseMenu] open_menu: Открытие меню паузы.")
	get_tree().paused = true
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

# Вызывается для закрытия меню и снятия с паузы
func close_menu():
	print("[PauseMenu] close_menu: Закрытие меню паузы.")
	get_tree().paused = false
	Input.set_mouse_mode(previous_mouse_mode)
	hide()

# Для закрытия меню паузы по клавише ESC, если оно видимо
func _unhandled_input(event: InputEvent):
	if visible and get_tree().paused and event.is_action_pressed("ui_pause"): 
		print("[PauseMenu] _unhandled_input: Нажата 'ui_pause' (ESC), меню было видимо. Закрываю.")
		get_viewport().set_input_as_handled() 
		close_menu()

func _on_ContinueButton_pressed():
	print("[PauseMenu] Кнопка 'Продолжить' нажата.")
	close_menu()

func _on_SettingsButton_pressed():
	print("[PauseMenu] Кнопка 'Настройки' нажата (пока не реализовано).")

func _on_RestartButton_pressed():
	print("[PauseMenu] Кнопка 'Перезапустить уровень' нажата.")
	close_menu() # Сначала закрываем меню и снимаем с паузы
	# GameManager НЕ сбрасывает состояние для этого типа перезапуска
	var error = get_tree().reload_current_scene()
	if error != OK:
		printerr("[PauseMenu] !!! ОШИБКА перезапуска уровня: {error_string(error)}")

func _on_ExitButton_pressed():
	print("[PauseMenu] Кнопка 'Выход в главное меню' нажата.")
	close_menu()
	GameManager.reset_stats_for_new_attempt() # Сбрасываем статистику сессии (счет, жизни, ключ)
	GameManager.current_level_index = 0       # Указываем, что главное меню - это как бы "уровень 0" для логики GameManager
	
	var main_menu_path = "res://main_menu.tscn" # <<< ЗАМЕНИТЕ НА ВАШ ПРАВИЛЬНЫЙ ПУТЬ!
	var error = get_tree().change_scene_to_file(main_menu_path)
	if error != OK:
		printerr("[PauseMenu] !!! ОШИБКА загрузки главного меню '{main_menu_path}': {error_string(error)}")
		get_tree().quit()
