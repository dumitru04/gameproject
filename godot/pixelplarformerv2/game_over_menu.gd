extends CanvasLayer

@onready var score_label: Label = $MainContainer/ScoreLabel 
@onready var restart_button: Button = $MainContainer/RestartButton
@onready var exit_menu_button: Button = $MainContainer/ExitMenuButton

var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
    hide()
    print("-----------------------------------------------------")
    print("[GameOverMenu] _ready: Initialization. Process Mode: " + str(get_process_mode()))

    if not score_label: print("[GameOverMenu] _ready: !!! ERROR - ScoreLabel not found!")
    else: print("[GameOverMenu] _ready: ScoreLabel FOUND.")

    if not restart_button: 
        print("[GameOverMenu] _ready: !!! ERROR - RestartButton NOT FOUND!")
    else:
        print("[GameOverMenu] _ready: RestartButton FOUND.")
        var err_restart = restart_button.pressed.connect(_on_RestartButton_pressed)
        if err_restart == OK: print("[GameOverMenu] _ready: RestartButton.pressed signal SUCCESSFULLY connected.")
        else: print("[GameOverMenu] _ready: !!! ERROR connecting RestartButton.pressed. Code: " + str(err_restart))
            
    if not exit_menu_button: 
        print("[GameOverMenu] _ready: !!! ERROR - ExitMenuButton NOT FOUND!")
    else:
        print("[GameOverMenu] _ready: ExitMenuButton FOUND.")
        var err_exit = exit_menu_button.pressed.connect(_on_ExitMenuButton_pressed)
        if err_exit == OK: print("[GameOverMenu] _ready: ExitMenuButton.pressed signal SUCCESSFULLY connected.")
        else: print("[GameOverMenu] _ready: !!! ERROR connecting ExitMenuButton.pressed. Code: " + str(err_exit))
    print("-----------------------------------------------------")

func show_screen(final_score: int):
    print("[GameOverMenu] show_screen CALLED. Final score: {final_score}")
    if score_label: score_label.text = "Score: %06d" % final_score
    get_tree().paused = true
    previous_mouse_mode = Input.get_mouse_mode()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    show()

func _cleanup_and_unpause():
    hide() 
    Input.set_mouse_mode(previous_mouse_mode) 
    get_tree().paused = false 
    queue_free() 
    print("[GameOverMenu] Menu cleared, game unpaused, instance deleted.")

func _on_RestartButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[GameOverMenu] FUNCTION _on_RestartButton_pressed CALLED.")
    _cleanup_and_unpause()
    GameManager.restart_failed_level()

func _on_ExitMenuButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[GameOverMenu] FUNCTION _on_ExitMenuButton_pressed CALLED.")
    _cleanup_and_unpause()
    get_tree().change_scene_to_file("res://main_menu.tscn")
