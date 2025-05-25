# ui.gd
extends CanvasLayer

# Обновляем ссылки на узлы Label
@onready var score_text_label: Label = $MarginContainer/MainLayout/ScoreTimeDisplay/ScoreTextLabel
@onready var lives_count_label: Label = $MarginContainer/MainLayout/LivesDisplay/LivesCountLabel
@onready var time_label: Label = $MarginContainer/MainLayout/ScoreTimeDisplay/TimeLabel 
# --- Остальные ссылки ---
@onready var level_timer: Timer = $LevelTimer # Предполагаем, что LevelTimer остался прямым потомком UI
@onready var notification_label: Label = $NotificationLabel # Если он тоже прямой потомок UI

var current_time_left: int = 0

func _ready():
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.lives_updated.connect(_on_lives_updated)
	GameManager.score_added_for_life.connect(_on_score_added_for_life)
	
	if level_timer:
		level_timer.timeout.connect(_on_LevelTimer_timeout)
	else:
		print("UI_ready: ВНИМАНИЕ! Узел LevelTimer не найден.")
		
	if notification_label:
		notification_label.hide()
	
	# Инициализация отображения при старте
	_on_score_updated(GameManager.score) # Показываем начальный счет
	_on_lives_updated(GameManager.lives) # Показываем начальные жизни
	_update_time_display() # Показываем начальное время (будет 00:00 или 0 до инициализации таймера)

func initialize_level_timer(duration_seconds: float):
	current_time_left = duration_seconds
	_update_time_display()
	if level_timer:
		level_timer.start()
		print("UI: Таймер уровня инициализирован на {duration_seconds} секунд и запущен.")
	else:
		print("UI: Не могу запустить таймер, узел LevelTimer не найден.")

func _on_LevelTimer_timeout():
	if current_time_left > 0:
		current_time_left -= 1.0 
		if current_time_left < 0: 
			current_time_left = 0
	
	_update_time_display()
	
	if current_time_left <= 0:
		if level_timer: level_timer.stop() 
		GameManager.trigger_instant_game_over("Время вышло") # Используем trigger_instant_game_over

func _update_time_display():
	if time_label:
		var total_seconds_remaining = floor(current_time_left)
		time_label.text = str(total_seconds_remaining) 
	else:
		print("UI _update_time_display: Узел TimeLabel не найден.")


func _on_score_updated(new_score: int):
	if score_text_label:
		# Форматируем счет, чтобы было 6 цифр с ведущими нулями
		score_text_label.text = "%06d" % new_score 
	else:
		print("UI _on_score_updated: Узел ScoreTextLabel не найден.")


func _on_lives_updated(new_lives: int):
	if lives_count_label:
		lives_count_label.text = str(new_lives)
	else:
		print("UI _on_lives_updated: Узел LivesCountLabel не найден.")

func get_remaining_time() -> float:
	return current_time_left

func stop_level_timer(): # Этот метод у вас уже должен быть
	if level_timer and not level_timer.is_stopped():
		level_timer.stop()
		print("UI: Таймер уровня ОСТАНОВЛЕН.")

func _on_score_added_for_life(points_value: int):
	if notification_label:
		notification_label.text = "+{points_value} ОЧКОВ!"
		notification_label.show()
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(notification_label.hide)
