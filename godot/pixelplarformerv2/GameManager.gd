extends Node

var score: int = 0
var initial_lives: int = 1
var lives: int = initial_lives 
var max_lives: int = 3
var points_for_extra_life: int = 500
var has_key: bool = false

var level_scene_paths: Array[String] = [
    "res://level1.tscn", 
    "res://level2.tscn"
]
var current_level_index: int = 0
var level_index_at_game_over: int = 0

signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal score_added_for_life(points_value: int)
signal key_status_updated(player_has_key: bool)

const GameOverMenuScene: PackedScene = preload("res://game_over_menu.tscn")
var game_over_menu_instance: CanvasLayer = null

const MusicManagerScene: PackedScene = preload("res://music_manager.tscn")
var music_manager_node: Node = null

func _ready():
    print("[GameManager] GameManager ready and auto-loaded.")
    
    if MusicManagerScene:
        music_manager_node = MusicManagerScene.instantiate()
        add_child(music_manager_node)
        print("[GameManager] MusicManager instance created and added as child node.")
    else:
        printerr("[GameManager] _ready: !!! ERROR: MusicManagerScene not preloaded! Check path.")

func add_score(amount: int):
    score += amount
    emit_signal("score_updated", score)

func lose_life():
    print("[GameManager] lose_life called. Lives were: {lives}")
    lives -= 1
    emit_signal("lives_updated", lives)
    
    if lives < 1:
        lives = 0
        emit_signal("lives_updated", lives)
        print("[GameManager] Player lost all lives (lives <= 0).")
        _trigger_game_over_logic("All lives lost (normal damage)")
    else:
        print("[GameManager] Player lost a life. Remaining: {lives}")

func trigger_instant_game_over(reason: String = "Unknown reason"):
    print("[GameManager] Instant Game Over! Reason: {reason}")
    lives = 0
    emit_signal("lives_updated", lives)
    _trigger_game_over_logic(reason)

func _trigger_game_over_logic(reason_for_log: String):
    print("[GameManager] Starting 'Game Over' logic. Reason: {reason_for_log}")
    level_index_at_game_over = current_level_index
    
    GM_play_overlay_menu_music(true)

    if is_instance_valid(game_over_menu_instance):
        print("[GameManager] Found previous GameOverMenu instance. Deleting it.")
        game_over_menu_instance.queue_free()
        game_over_menu_instance = null

    if GameOverMenuScene:
        game_over_menu_instance = GameOverMenuScene.instantiate()
        get_tree().root.add_child(game_over_menu_instance) 
        print("[GameManager] GameOverMenu instance created and added to root.")
        
        if game_over_menu_instance.has_method("show_screen"):
            game_over_menu_instance.show_screen(score)
        else:
            printerr("[GameManager] !!! ERROR: GameOverMenu instance doesn't have show_screen() method!")
            _fallback_game_over_action() 
    else:
        printerr("[GameManager] !!! ERROR: Could not load GameOverMenuScene! Check preload path.")
        _fallback_game_over_action()

func add_life():
    if lives < max_lives:
        lives += 1
        emit_signal("lives_updated", lives)
        print("[GameManager] Life added. Total lives: {lives}")
    else:
        add_score(points_for_extra_life)
        emit_signal("score_added_for_life", points_for_extra_life)
        print("[GameManager] Maximum lives ({max_lives}). Awarded {points_for_extra_life} points.")

func collect_key():
    if not has_key:
        has_key = true
        emit_signal("key_status_updated", true)
        print("[GameManager] Key collected!")

func check_has_key() -> bool:
    return has_key

func GM_play_main_menu_music(force_restart: bool = true):
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("play_main_menu_music"):
        music_manager_node.play_main_menu_music(force_restart)
    else:
        printerr("[GameManager] GM_play_main_menu_music: MusicManager instance invalid or method missing.")

func GM_play_level_music_by_index(index: int, force_restart: bool = true):
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("play_level_music_by_index"):
        music_manager_node.play_level_music_by_index(index, force_restart)
    else:
        printerr("[GameManager] GM_play_level_music_by_index: MusicManager instance invalid or method missing.")

func GM_play_overlay_menu_music(force_restart: bool = true):
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("play_overlay_menu_music"):
        music_manager_node.play_overlay_menu_music(force_restart)
    else:
        printerr("[GameManager] GM_play_overlay_menu_music: MusicManager instance invalid or method missing.")

func GM_stop_music():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("stop_music"):
        music_manager_node.stop_music()
    else:
        printerr("[GameManager] GM_stop_music: MusicManager instance invalid or method missing.")

func GM_sfx_button_click():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_button_click"):
        music_manager_node.GM_sfx_button_click()

func GM_sfx_player_jump():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_player_jump"):
        music_manager_node.GM_sfx_player_jump()

func GM_sfx_player_damage():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_player_damage"):
        music_manager_node.GM_sfx_player_damage()

func GM_sfx_coin_collect():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_coin_collect"):
        music_manager_node.GM_sfx_coin_collect()

func GM_sfx_enemy_defeated():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_enemy_defeated"):
        music_manager_node.GM_sfx_enemy_defeated()
        
func GM_sfx_block_hit():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_block_hit"):
        music_manager_node.GM_sfx_block_hit()

func GM_sfx_powerup_spawn():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("GM_sfx_powerup_spawn"):
        music_manager_node.GM_sfx_powerup_spawn()

func reset_stats_for_new_attempt():
    score = 0
    lives = initial_lives 
    has_key = false 
    print("[GameManager] Stats for new attempt reset. Score: {score}, Lives: {lives}, Key: {has_key}")
    emit_signal("score_updated", score)
    emit_signal("lives_updated", lives)
    emit_signal("key_status_updated", has_key)

func start_new_game():
    print("[GameManager] Starting new game (start_new_game).")
    current_level_index = 0
    _reset_stats_for_level_start()
    
    GM_play_level_music_by_index(current_level_index, true)
    
    var first_level_path = get_current_level_path()
    if not first_level_path.is_empty():
        print("[GameManager] Loading first level: {first_level_path}")
        if get_tree().paused: get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        var error = get_tree().change_scene_to_file(first_level_path)
        if error != OK:
            printerr("[GameManager] !!! ERROR loading first level '{first_level_path}': {error_string(error)}")
    else:
        printerr("[GameManager] !!! ERROR: No levels in level_scene_paths for startup!")

func restart_failed_level():
    print("[GameManager] Restarting level {level_index_at_game_over} after Game Over.")
    current_level_index = level_index_at_game_over
    reset_stats_for_new_attempt()
    
    GM_play_level_music_by_index(current_level_index, true) 
    
    var level_path = get_current_level_path()
    if not level_path.is_empty():
        print("[GameManager] Loading level for restart: {level_path}")
        if get_tree().paused: get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        var error = get_tree().change_scene_to_file(level_path)
        if error != OK:
            printerr("[GameManager] !!! ERROR restarting level '{level_path}': {error_string(error)}")
            start_new_game()
    else:
        printerr("[GameManager] !!! ERROR: Path to level for restart is empty.")
        start_new_game() 

func get_current_level_path() -> String:
    if current_level_index >= 0 and current_level_index < level_scene_paths.size():
        return level_scene_paths[current_level_index]
    printerr("[GameManager] ERROR: current_level_index ({current_level_index}) invalid for level_scene_paths (size: {level_scene_paths.size()})!")
    return "" if level_scene_paths.is_empty() else level_scene_paths[0]

func _reset_stats_for_level_start():
    score = 0
    lives = initial_lives 
    has_key = false 
    print("[GameManager] Stats (score, lives, key) reset for level start. Current level index: {current_level_index}")
    emit_signal("score_updated", score)
    emit_signal("lives_updated", lives)
    emit_signal("key_status_updated", has_key)

func go_to_next_level() -> bool: 
    print("[GameManager] go_to_next_level called. Current index: {current_level_index}")
    var next_idx = current_level_index + 1
    if next_idx < level_scene_paths.size():
        current_level_index = next_idx
        
        GM_play_level_music_by_index(current_level_index, true)
        
        var next_level_path = level_scene_paths[current_level_index]
        print("[GameManager] Going to next level: '{next_level_path}' (index: {current_level_index})")
        
        has_key = false
        emit_signal("key_status_updated", has_key)

        if get_tree().paused: get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        var error = get_tree().change_scene_to_file(next_level_path)
        if error != OK:
            printerr("[GameManager] !!! ERROR loading level '{next_level_path}': {error_string(error)}")
            current_level_index -= 1
            return false 
        return true
    else:
        print("[GameManager] Next level not found (index {next_idx}). This was the last level.")
        return false

func load_specific_level(index: int):
    if index >= 0 and index < level_scene_paths.size():
        print("[GameManager] Loading level by index {index}.")
        current_level_index = index
        _reset_stats_for_level_start()
        
        var path = level_scene_paths[current_level_index]
        print("[GameManager] Loading selected level: '{path}'")
        if get_tree().paused: get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
        var error = get_tree().change_scene_to_file(path)
        if error != OK:
            printerr("[GameManager] !!! ERROR loading level '{path}': {error_string(error)}")
    else:
        printerr("[GameManager] !!! ERROR: Invalid level index {index} for loading.")

func GM_play_music_for_current_level():
    if is_instance_valid(music_manager_node) and music_manager_node.has_method("play_level_music_by_index"):
        music_manager_node.play_level_music_by_index(current_level_index, false)
    else:
        printerr("[GameManager] GM_play_music_for_current_level: MusicManager not ready.")

func _fallback_game_over_action():
    print("GameManager: _fallback_game_over_action: Emergency new game start.")
    start_new_game()

func use_key():
    if has_key:
        has_key = false
        emit_signal("key_status_updated", false)
        print("GameManager: Key used!")
