extends Control

@onready var start_game_button: Button = $MenuButtonsContainer/StartGameButton
@onready var level_select_button: Button = $MenuButtonsContainer/LevelSelectButton
@onready var settings_button: Button = $MenuButtonsContainer/SettingsButton
@onready var exit_game_button: Button = $MenuButtonsContainer/ExitGameButton

var level_select_menu_scene_path = "res://level_select_menu.tscn" 

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    if start_game_button: start_game_button.pressed.connect(_on_StartGameButton_pressed)
    if level_select_button: level_select_button.pressed.connect(_on_LevelSelectButton_pressed)
    if settings_button: settings_button.pressed.connect(_on_SettingsButton_pressed)
    if exit_game_button: exit_game_button.pressed.connect(_on_ExitGameButton_pressed)
    
    if is_instance_valid(GameManager):
        GameManager.GM_play_main_menu_music(false) 
    else:
        printerr("[MainMenu] _ready: GameManager not found! Cannot start music.")

func _on_StartGameButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[MainMenu] Start game button pressed.")
    GameManager.start_new_game() 

func _on_LevelSelectButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[MainMenu] Level select button pressed.")
    var error = get_tree().change_scene_to_file(level_select_menu_scene_path)
    if error != OK:
        printerr("[MainMenu] !!! ERROR loading level select scene '{level_select_menu_scene_path}': {error_string(error)}")

func _on_SettingsButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[MainMenu] Settings button pressed (not implemented yet).")
    get_tree().quit()

func _on_ExitGameButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[MainMenu] Exit game button pressed.")
    get_tree().quit()
