extends Node2D

@export var level_duration_seconds: float = 110.0 
@export var points_per_second_bonus: int = 10

@onready var player_node: Player = $Player 
@onready var finish_area_node: Area2D = $FinishArea 

const LevelCompleteMenuScene: PackedScene = preload("res://level_complete_menu.tscn")

var ui_node
var _level_complete_data: Dictionary = {}

func _ready():
    if finish_area_node:
        finish_area_node.player_reached_finish.connect(_on_player_reached_finish)
    else:
        printerr("[{name}] _ready: !!! ERROR: FinishArea node not found!")
    
    ui_node = find_ui_node()
    if ui_node and ui_node.has_method("initialize_level_timer"):
        ui_node.initialize_level_timer(level_duration_seconds)
    elif not ui_node:
        printerr("[{name}] _ready: !!! UI node not found. Level timer not started.")

func _on_player_reached_finish(player_who_finished: Node2D):
    print("[{name}] _on_player_reached_finish: Player {player_who_finished.name} reached finish.")
    
    var remaining_time: float = 0.0
    if ui_node:
        if ui_node.has_method("stop_level_timer"): ui_node.stop_level_timer()
        if ui_node.has_method("get_remaining_time"): remaining_time = ui_node.get_remaining_time()
    
    print("[{name}] Remaining time: {remaining_time} sec.")

    if player_node and player_node.has_method("start_level_complete_sequence"):
        player_node.start_level_complete_sequence()
    
    var score_before_bonus = GameManager.score 
    var time_bonus_amount = int(remaining_time) * points_per_second_bonus
    print("[{name}] Time bonus: {time_bonus_amount} ( {remaining_time} sec * {points_per_second_bonus} points/sec )")
    
    GameManager.add_score(time_bonus_amount) 
    var total_score_after_bonus = GameManager.score 
    print("[{name}] Total score after bonus: {total_score_after_bonus}")

    _level_complete_data = {
        "score_at_finish": score_before_bonus, 
        "time_bonus": time_bonus_amount,
        "final_total_score": total_score_after_bonus
    }
    print("[{name}] Data for level completion menu: {_level_complete_data}")

    var menu_delay_timer = get_tree().create_timer(2.5) 
    menu_delay_timer.timeout.connect(_show_level_complete_menu)

func _show_level_complete_menu():
    print("[{name}] _show_level_complete_menu: Showing level completion menu.")
    get_tree().paused = true 
    
    GameManager.GM_play_overlay_menu_music(true)

    if LevelCompleteMenuScene:
        var menu_instance = LevelCompleteMenuScene.instantiate()
        get_tree().root.add_child(menu_instance) 
        
        if menu_instance.has_method("setup_menu_with_stats"):
            print("[{name}] Calling setup_menu_with_stats with data: {_level_complete_data}")
            menu_instance.setup_menu_with_stats(_level_complete_data)
        else:
            printerr("[{name}] !!! ERROR: Level completion menu doesn't have setup_menu_with_stats method!")
    else:
        printerr("[{name}] !!! ERROR: LevelCompleteMenuScene not loaded!")

func find_ui_node():
    var ui = get_node_or_null("UI") 
    if not ui:
        var ui_nodes_in_group = get_tree().get_nodes_in_group("ui_group")
        if not ui_nodes_in_group.is_empty():
            ui = ui_nodes_in_group[0]
    if not ui: printerr("[{name}] find_ui_node: UI node not found!")
    return ui
