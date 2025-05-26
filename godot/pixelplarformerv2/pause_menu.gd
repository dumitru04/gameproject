extends CanvasLayer

@onready var continue_button: Button = $BackgroundDim/MenuButtons/ContinueButton 
@onready var settings_button: Button = $BackgroundDim/MenuButtons/SettingsButton
@onready var restart_button: Button = $BackgroundDim/MenuButtons/RestartButton
@onready var exit_button: Button = $BackgroundDim/MenuButtons/ExitButton

var previous_mouse_mode = Input.MOUSE_MODE_HIDDEN

func _ready():
    print("[PauseMenu] _ready: Pause menu ready. Process Mode: " + str(get_process_mode()))
    hide() 
    
    if not continue_button: print("[PauseMenu] _ready: !!! ERROR - ContinueButton not found!")
    else: continue_button.pressed.connect(_on_ContinueButton_pressed)

    if not settings_button: print("[PauseMenu] _ready: !!! ERROR - SettingsButton not found!")
    else: settings_button.pressed.connect(_on_SettingsButton_pressed)

    if not restart_button: print("[PauseMenu] _ready: !!! ERROR - RestartButton not found!")
    else: restart_button.pressed.connect(_on_RestartButton_pressed)
    
    if not exit_button: print("[PauseMenu] _ready: !!! ERROR - ExitButton not found!")
    else: exit_button.pressed.connect(_on_ExitButton_pressed)

func open_menu_and_pause():
    print("[PauseMenu] open_menu: Opening pause menu.")
    get_tree().paused = true
    previous_mouse_mode = Input.get_mouse_mode()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    GameManager.GM_play_overlay_menu_music(true)
    
    show()

func close_menu():
    print("[PauseMenu] close_menu: Closing pause menu.")
    get_tree().paused = false
    Input.set_mouse_mode(previous_mouse_mode)
    hide()
    
    GameManager.GM_play_music_for_current_level()

func _unhandled_input(event: InputEvent):
    if visible and get_tree().paused and event.is_action_pressed("ui_pause"): 
        print("[PauseMenu] _unhandled_input: 'ui_pause' (ESC) pressed, menu was visible. Closing.")
        get_viewport().set_input_as_handled() 
        close_menu()

func _on_ContinueButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[PauseMenu] Continue button pressed.")
    close_menu()

func _on_SettingsButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[PauseMenu] Settings button pressed (not implemented yet).")

func _on_RestartButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[PauseMenu] Restart level button pressed.")
    close_menu()
    var error = get_tree().reload_current_scene()
    if error != OK:
        printerr("[PauseMenu] !!! ERROR restarting level: {error_string(error)}")

func _on_ExitButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[PauseMenu] Exit to main menu button pressed.")
    close_menu()
    GameManager.reset_stats_for_new_attempt()
    GameManager.current_level_index = 0
    
    var main_menu_path = "res://main_menu.tscn"
    var error = get_tree().change_scene_to_file(main_menu_path)
    if error != OK:
        printerr("[PauseMenu] !!! ERROR loading main menu '{main_menu_path}': {error_string(error)}")
        get_tree().quit()
