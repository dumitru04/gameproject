extends Control

@onready var levels_container: Container = $LevelsContainer 
@onready var back_button: Button = $BackButton

var main_menu_path = "res://main_menu.tscn" 

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if not levels_container:
        printerr("[LevelSelectMenu] _ready: !!! ERROR: LevelsContainer node not found! Check path.")
        return 
    if not back_button:
        printerr("[LevelSelectMenu] _ready: !!! ERROR: BackButton node not found! Check path.")
    else:
        back_button.pressed.connect(_on_BackButton_pressed)

    populate_level_buttons()

func populate_level_buttons():
    for child in levels_container.get_children():
        child.queue_free()

    if GameManager.level_scene_paths.is_empty():
        var no_levels_label = Label.new()
        no_levels_label.text = "No levels defined in GameManager."
        levels_container.add_child(no_levels_label)
        print("[LevelSelectMenu] No levels found in GameManager.level_scene_paths.")
        return

    print("[LevelSelectMenu] Loading buttons for {GameManager.level_scene_paths.size()} levels.")
    for i in range(GameManager.level_scene_paths.size()):
        var level_path = GameManager.level_scene_paths[i]
        var level_name_for_display = level_path.get_file().get_basename() 
        
        var button: Button
        button = Button.new()
        button.text = "Level " + str(i + 1)
        button.custom_minimum_size = Vector2(200, 40)
        
        button.pressed.connect(Callable(self, "_on_LevelButtonPressed").bind(i))
        
        levels_container.add_child(button)
        print("[LevelSelectMenu] Added button for level {i} ('{button.text}').")

func _on_LevelButtonPressed(level_index: int):
    GameManager.GM_sfx_button_click()
    print("[LevelSelectMenu] Button pressed for level with index {level_index}.")
    if GameManager.has_method("load_specific_level"):
        GameManager.load_specific_level(level_index)
    else:
        printerr("[LevelSelectMenu] !!! ERROR: GameManager doesn't have load_specific_level method!")

func _on_BackButton_pressed():
    GameManager.GM_sfx_button_click()
    print("[LevelSelectMenu] Back button pressed. Going to main menu.")
    var error = get_tree().change_scene_to_file(main_menu_path)
    if error != OK:
        printerr("[LevelSelectMenu] !!! ERROR loading main menu '{main_menu_path}': {error_string(error)}")
