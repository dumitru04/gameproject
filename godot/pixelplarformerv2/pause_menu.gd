# pause_menu.gd
extends CanvasLayer

@onready var continue_button: Button = $BackgroundDim/MenuButtons/ContinueButton 
@onready var settings_button: Button = $BackgroundDim/MenuButtons/SettingsButton
@onready var restart_button: Button = $BackgroundDim/MenuButtons/RestartButton
@onready var exit_button: Button = $BackgroundDim/MenuButtons/ExitButton

var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED 

func _ready():
	hide() 
	
	if continue_button: continue_button.pressed.connect(_on_ContinueButton_pressed)
	if settings_button: settings_button.pressed.connect(_on_SettingsButton_pressed)
	if restart_button: restart_button.pressed.connect(_on_RestartButton_pressed)
	if exit_button: exit_button.pressed.connect(_on_ExitButton_pressed)

func _unhandled_input(event: InputEvent):
	if get_tree().paused and event.is_action_pressed("ui_pause"):
		print("[PauseMenu] _unhandled_input: Нажата 'ui_pause' ВО ВРЕМЯ ПАУЗЫ. Снимаю с паузы.")
		get_viewport().set_input_as_handled() # ИСПРАВЛЕНО
		close_menu_and_unpause()

func open_menu_and_pause():
	print("[PauseMenu] open_menu_and_pause: Открытие меню и постановка игры на паузу.")
	get_tree().paused = true
	print("[PauseMenu] open_menu_and_pause: get_tree().paused = " + str(get_tree().paused))
	previous_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	print("[PauseMenu] open_menu_and_pause: Меню показано, мышь видима.")

func close_menu_and_unpause():
	print("[PauseMenu] close_menu_and_unpause: Закрытие меню и снятие с паузы.")
	get_tree().paused = false
	print("[PauseMenu] close_menu_and_unpause: get_tree().paused = " + str(get_tree().paused))
	Input.set_mouse_mode(previous_mouse_mode)
	hide()
	print("[PauseMenu] close_menu_and_unpause: Меню скрыто, режим мыши восстановлен.")

func _on_ContinueButton_pressed():
	print("[PauseMenu] _on_ContinueButton_pressed: Кнопка 'Продолжить' нажата.")
	close_menu_and_unpause()

func _on_SettingsButton_pressed():
	print("[PauseMenu] _on_SettingsButton_pressed: Кнопка 'Настройки' нажата (функционал в разработке).")

func _on_RestartButton_pressed():
	print("[PauseMenu] _on_RestartButton_pressed: Кнопка 'Перезапустить уровень' нажата.")
	get_tree().paused = false 
	Input.set_mouse_mode(previous_mouse_mode) 
	
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("[PauseMenu] _on_RestartButton_pressed: !!! ОШИБКА перезапуска уровня: " + error_string(error))

func _on_ExitButton_pressed():
	print("[PauseMenu] _on_ExitButton_pressed: Кнопка 'Выход в главное меню' нажата.")
	get_tree().paused = false
	Input.set_mouse_mode(previous_mouse_mode)
	print("[PauseMenu] _on_ExitButton_pressed: Выход из игры...")
	get_tree().quit()
