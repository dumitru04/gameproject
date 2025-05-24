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
	lives -= 1
	emit_signal("lives_updated", lives)
	
	if lives <= 0: 
		print("GameManager: Игрок потерял последнюю жизнь (жизни: {lives})!")
		_trigger_game_over_sequence("Все жизни потеряны")


func trigger_instant_game_over(reason: String = "Неизвестная причина"):
	print("GameManager: Мгновенный Game Over! Причина: {reason}")
	lives = 0 # Устанавливаем жизни в 0 для корректного отображения, если это важно
	emit_signal("lives_updated", lives) # Обновляем UI
	_trigger_game_over_sequence(reason)
	
func _trigger_game_over_sequence(reason_for_log: String):
	print("[GameManager] Запуск последовательности Game Over. Причина: " + reason_for_log)
	print("[GameManager] Текущий счет для передачи: " + str(score))
	
	var game_over_menu_exists = Engine.has_singleton("GameOverMenu")
	print("[GameManager] Autoload 'GameOverMenu' существует: " + str(game_over_menu_exists))

	if game_over_menu_exists:
		GameOverMenu.show_screen(score) # Передаем текущий счет на экран
	else:
		print("GameManager: !!! ОШИБКА: Autoload 'GameOverMenu' не найден! Выполняю аварийный перезапуск.")
		_fallback_hard_restart()


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
	print("GameManager: Состояние игры сброшено. Счет: {score}, Жизни: {lives}")
	emit_signal("score_updated", score)
	emit_signal("lives_updated", lives)

func _fallback_hard_restart(): # Если экран Game Over не загрузился
	print("GameManager: _fallback_hard_restart: Сброс и перезапуск уровня.")
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
