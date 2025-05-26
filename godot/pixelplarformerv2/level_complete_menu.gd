extends CanvasLayer

@onready var next_level_button: Button = $MainContainer/NextLevelButton
@onready var restart_button: Button = $MainContainer/RestartButton
@onready var level_select_button: Button = $MainContainer/LevelSelectButton
@onready var exit_menu_button: Button = $MainContainer/ExitToMenuButton

@onready var level_score_display_label: Label = $MainContainer/LevelScoreDisplayLabel 
@onready var time_bonus_display_label: Label = $MainContainer/TimeBonusDisplayLabel  
@onready var final_total_score_label: Label = $MainContainer/FinalTotalScoreLabel 

var level_select_menu_scene_path = "res://level_select_menu.tscn"
var previous_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
    hide()
    print("-----------------------------------------------------")
    print("[LvlCompleteMenu] _ready: Initialization. Process Mode: " + str(get_process_mode()))

    if not next_level_button: 
        print("[LvlCompleteMenu] _ready: !!! ERROR - NextLevelButton NOT FOUND!")
    else:
        print("[LvlCompleteMenu] _ready: NextLevelButton FOUND.")
        var err_next = next_level_button.pressed.connect(_on_NextLevelButton_pressed)
        if err_next == OK: print("[LvlCompleteMenu] _ready: NextLevelButton.pressed signal SUCCESSFULLY connected.")
        else: print("[LvlCompleteMenu] _ready: !!! ERROR connecting NextLevelButton.pressed. Code: " + str(err_next))

    if not restart_button: 
        print("[LvlCompleteMenu] _ready: !!! ERROR - RestartButton NOT FOUND!")
    else:
        print("[LvlCompleteMenu] _ready: RestartButton FOUND.")
        var err_restart = restart_button.pressed.connect(_on_RestartButton_pressed)
        if err_restart == OK: print("[LvlCompleteMenu] _ready: RestartButton.pressed signal SUCCESSFULLY connected.")
        else: print("[LvlCompleteMenu] _ready: !!! ERROR connecting RestartButton.pressed. Code: " + str(err_restart))

    if not level_select_button: 
        print("[LvlCompleteMenu] _ready: !!! ERROR - LevelSelectButton NOT FOUND!")
    else:
        print("[LvlCompleteMenu] _ready: LevelSelectButton FOUND.")
        var err_select = level_select_button.pressed.connect(_on_LevelSelectButton_pressed)
        if err_select == OK: print("[LvlCompleteMenu] _ready: LevelSelectButton.pressed signal SUCCESSFULLY connected.")
        else: print("[LvlCompleteMenu] _ready: !!! ERROR connecting LevelSelectButton.pressed. Code: " + str(err_select))
            
    if not exit_menu_button: 
        print("[LvlCompleteMenu] _ready: !!! ERROR - ExitToMenuButton NOT FOUND!")
    else:
        print("[LvlCompleteMenu] _ready: ExitToMenuButton FOUND.")
        var err_exit = exit_menu_button.pressed.connect(_on_ExitToMenuButton_pressed)
        if err_exit == OK: print("[LvlCompleteMenu] _ready: ExitToMenuButton.pressed signal SUCCESSFULLY connected.")
        else: print("[LvlCompleteMenu] _ready: !!! ERROR connecting ExitToMenuButton.pressed. Code: " + str(err_exit))
    print("-----------------------------------------------------")

func setup_menu_with_stats(stats: Dictionary):
    print("[LevelCompleteMenu] setup_menu_with_stats CALLED. Received data: {stats}")
    if level_score_display_label and stats.has("score_at_finish"): level_score_display_label.text = "Score: " + str(stats.score_at_finish)
    if time_bonus_display_label and stats.has("time_bonus"): time_bonus_display_label.text = "Time Bonus: " + str(stats.time_bonus)
    if final_total_score_label and stats.has("final_total_score"): final_total_score_label.text = "Total: %06d" % stats.final_total_score
    previous_mouse_mode = Input.get_mouse_mode()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    show()

func _cleanup_and_hide():
    Input.set_mouse_mode(previous_mouse_mode) 
    hide()
    queue_free() 
    print("[LevelCompleteMenu] Menu cleaned up and deleted.")

func _on_NextLevelButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[LvlCompleteMenu] FUNCTION _on_NextLevelButton_pressed CALLED.")
    get_tree().paused = false
    var went_to_next = GameManager.go_to_next_level()
    if not went_to_next:
        GameManager.start_new_game() 
        var main_menu_path = "res://main_menu.tscn" 
        get_tree().change_scene_to_file(main_menu_path)
    _cleanup_and_hide()

func _on_RestartButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[LvlCompleteMenu] FUNCTION _on_RestartButton_pressed CALLED.")
    get_tree().paused = false
    var error = get_tree().reload_current_scene()
    if error != OK: printerr("[LevelCompleteMenu] !!! ERROR restarting level: {error_string(error)}")
    _cleanup_and_hide()

func _on_LevelSelectButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[LevelCompleteMenu] Level select button pressed.")
    get_tree().paused = false 
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
    
    var error = get_tree().change_scene_to_file(level_select_menu_scene_path)
    if error != OK:
        printerr("[LevelCompleteMenu] !!! ERROR loading level select scene '{level_select_menu_scene_path}': {error_string(error)}")
        get_tree().quit()
    
    _cleanup_and_hide()

func _on_ExitToMenuButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[LvlCompleteMenu] FUNCTION _on_ExitToMenuButton_pressed CALLED.")
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var main_menu_path = "res://main_menu.tscn"
    get_tree().change_scene_to_file(main_menu_path)
    _cleanup_and_hide()
