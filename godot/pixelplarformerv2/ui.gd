# ui.gd
extends CanvasLayer

@onready var score_text_label: Label = $MarginContainer/MainLayout/ScoreTimeDisplay/ScoreTextLabel
@onready var lives_count_label: Label = $MarginContainer/MainLayout/LivesDisplay/LivesCountLabel
@onready var time_label: Label = $MarginContainer/MainLayout/ScoreTimeDisplay/TimeLabel 
@onready var level_timer: Timer = $LevelTimer
@onready var notification_label: Label = $NotificationLabel

var current_time_left: int = 0

func _ready():
    GameManager.score_updated.connect(_on_score_updated)
    GameManager.lives_updated.connect(_on_lives_updated)
    
    if level_timer:
        level_timer.timeout.connect(_on_LevelTimer_timeout)
    else:
        print("UI_ready: WARNING! LevelTimer node not found.")
        
    if notification_label:
        notification_label.hide()
    
    _on_score_updated(GameManager.score)
    _on_lives_updated(GameManager.lives)
    _update_time_display()

func initialize_level_timer(duration_seconds: float):
    current_time_left = duration_seconds
    _update_time_display()
    if level_timer:
        level_timer.start()
        print("UI: Level timer initialized for {duration_seconds} seconds and started.")
    else:
        print("UI: Cannot start timer, LevelTimer node not found.")

func _on_LevelTimer_timeout():
    if current_time_left > 0:
        current_time_left -= 1.0 
        if current_time_left < 0: 
            current_time_left = 0
    
    _update_time_display()
    
    if current_time_left <= 0:
        if level_timer: level_timer.stop() 
        GameManager.trigger_instant_game_over("Time's up")

func _update_time_display():
    if time_label:
        var total_seconds_remaining = floor(current_time_left)
        time_label.text = str(total_seconds_remaining) 
    else:
        print("UI _update_time_display: TimeLabel node not found.")

func _on_score_updated(new_score: int):
    if score_text_label:
        score_text_label.text = "%06d" % new_score 
    else:
        print("UI _on_score_updated: ScoreTextLabel node not found.")

func _on_lives_updated(new_lives: int):
    if lives_count_label:
        lives_count_label.text = str(new_lives)
    else:
        print("UI _on_lives_updated: LivesCountLabel node not found.")

func get_remaining_time() -> float:
    return current_time_left

func stop_level_timer():
    if level_timer and not level_timer.is_stopped():
        level_timer.stop()
        print("UI: Level timer STOPPED.")
