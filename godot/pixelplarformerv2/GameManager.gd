# GameManager.gd
extends Node

var score = 0
var initial_lives = 1
var lives = initial_lives 
var max_lives = 3 
var points_for_extra_life = 500

var has_key: bool = false # НОВОЕ: есть ли у игрока ключ

signal score_updated(new_score)
signal lives_updated(new_lives)
signal score_added_for_life(points_value)
signal key_status_updated(player_has_key) # НОВОЕ: сигнал для UI, если нужно отображать ключ

func _ready():
	reset_game_state() 

func add_score(amount: int):
	score += amount
	emit_signal("score_updated", score)

func lose_life():
	# ... (код без изменений) ...
	lives -= 1
	emit_signal("lives_updated", lives)
	if lives <= 0: 
		print("GameManager: Игрок потерял последнюю жизнь (жизни: {lives})! Game Over.")
		reset_game_state_and_restart_level("Все жизни потеряны")


func trigger_instant_game_over(reason: String = "Неизвестная причина"):
	# ... (код без изменений) ...
	print("GameManager: Мгновенный Game Over! Причина: {reason}")
	reset_game_state_and_restart_level(reason)


func add_life():
	# ... (код без изменений) ...
	print("DEBUG: GameManager add_life() ВЫЗВАНА. Жизней до: " + str(lives))
	if lives < max_lives:
		lives += 1
		emit_signal("lives_updated", lives)
		print("DEBUG: GameManager add_life(). Жизнь добавлена. Жизней после: " + str(lives))
	else:
		add_score(points_for_extra_life)
		emit_signal("score_added_for_life", points_for_extra_life)
		print("DEBUG: GameManager add_life(). Максимум жизней. Начислены очки.")


func reset_game_state():
	score = 0
	lives = initial_lives 
	has_key = false # НОВОЕ: сбрасываем ключ при полном рестарте игры
	print("GameManager: Состояние игры сброшено. Счет: {score}, Жизни: {lives}, Ключ: {has_key}")
	emit_signal("score_updated", score)
	emit_signal("lives_updated", lives)
	emit_signal("key_status_updated", has_key) # Обновляем UI по ключу

func reset_game_state_and_restart_level(reason_for_log: String):
	# ... (код без изменений) ...
	print("GameManager: Выполняется reset_game_state_and_restart_level. Причина: {reason_for_log}")
	reset_game_state()
	get_tree().reload_current_scene()

# --- НОВЫЕ ФУНКЦИИ ДЛЯ КЛЮЧА ---
func collect_key():
	if not has_key:
		has_key = true
		emit_signal("key_status_updated", true)
		print("GameManager: Ключ подобран!")
		# Здесь можно проиграть звук подбора ключа

func check_has_key() -> bool:
	return has_key

# Опционально, если ключ одноразовый:
func use_key():
	if has_key:
		has_key = false
		emit_signal("key_status_updated", false)
		print("GameManager: Ключ использован!")
