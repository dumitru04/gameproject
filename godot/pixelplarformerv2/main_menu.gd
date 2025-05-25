# main_menu.gd
extends Control

@onready var start_game_button: Button = $MenuButtonsContainer/StartGameButton
@onready var level_select_button: Button = $MenuButtonsContainer/LevelSelectButton
@onready var settings_button: Button = $MenuButtonsContainer/SettingsButton
@onready var exit_game_button: Button = $MenuButtonsContainer/ExitGameButton

func _ready():
	# Показываем курсор мыши, если он был скрыт
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Подключаем сигналы кнопок
	if start_game_button: start_game_button.pressed.connect(_on_StartGameButton_pressed)
	if level_select_button: level_select_button.pressed.connect(_on_LevelSelectButton_pressed)
	if settings_button: settings_button.pressed.connect(_on_SettingsButton_pressed)
	if exit_game_button: exit_game_button.pressed.connect(_on_ExitGameButton_pressed)

func _on_StartGameButton_pressed():
	print("[MainMenu] Нажата кнопка 'Начать игру'.")
	# GameManager (Autoload) сбросит состояние и загрузит первый уровень
	GameManager.start_new_game() 

func _on_LevelSelectButton_pressed():
	print("[MainMenu] Нажата кнопка 'Выбор уровня' (пока не реализовано).")
	# Здесь будет переход на сцену выбора уровня, например:
	# get_tree().change_scene_to_file("res://scenes/menus/level_select_menu.tscn")
	# Пока что можно просто выйти или ничего не делать
	get_tree().quit() # Заглушка

func _on_SettingsButton_pressed():
	print("[MainMenu] Нажата кнопка 'Настройки' (пока не реализовано).")
	# Здесь будет переход на сцену настроек, например:
	# get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")
	get_tree().quit() # Заглушка

func _on_ExitGameButton_pressed():
	print("[MainMenu] Нажата кнопка 'Выход из игры'.")
	get_tree().quit()
