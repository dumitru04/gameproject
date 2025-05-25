# level2.gd (или скрипт вашего текущего уровня)
extends Node2D # или Node

@export var level_duration_seconds: float = 180.0 
@export var points_per_second_bonus: int = 10 # Очки за каждую оставшуюся секунду

@onready var player_node: Player = $Player 
@onready var finish_area_node: Area2D = $FinishArea 

const LevelCompleteMenuScene: PackedScene = preload("res://level_complete_menu.tscn") # Путь к вашей сцене меню

var ui_node # Ссылка на ваш UI (где таймер)
var _level_complete_data: Dictionary = {} # Для хранения данных для меню

func _ready():
	if finish_area_node:
		finish_area_node.player_reached_finish.connect(_on_player_reached_finish)
	else:
		printerr("[{name}] _ready: !!! ОШИБКА: Узел FinishArea не найден!")
	
	ui_node = find_ui_node() # Ваша функция поиска UI
	if ui_node and ui_node.has_method("initialize_level_timer"):
		ui_node.initialize_level_timer(level_duration_seconds)
	elif not ui_node:
		printerr("[{name}] _ready: !!! Узел UI не найден. Таймер уровня не запущен.")


func _on_player_reached_finish(player_who_finished: Node2D):
	print("[{name}] _on_player_reached_finish: Игрок {player_who_finished.name} достиг финиша.")
	
	var remaining_time: float = 0.0
	if ui_node:
		if ui_node.has_method("stop_level_timer"): ui_node.stop_level_timer()
		if ui_node.has_method("get_remaining_time"): remaining_time = ui_node.get_remaining_time()
	
	print("[{name}] Оставшееся время: {remaining_time} сек.")

	if player_node and player_node.has_method("start_level_complete_sequence"):
		player_node.start_level_complete_sequence()
	
	var score_before_bonus = GameManager.score 
	var time_bonus_amount = int(remaining_time) * points_per_second_bonus
	print("[{name}] Бонус за время: {time_bonus_amount} ( {remaining_time} сек * {points_per_second_bonus} очков/сек )")
	
	GameManager.add_score(time_bonus_amount) 
	var total_score_after_bonus = GameManager.score 
	print("[{name}] Общий счет после бонуса: {total_score_after_bonus}")

	_level_complete_data = {
		"score_at_finish": score_before_bonus, 
		"time_bonus": time_bonus_amount,
		"final_total_score": total_score_after_bonus
	}
	print("[{name}] Данные для меню завершения уровня: {_level_complete_data}")

	var menu_delay_timer = get_tree().create_timer(2.5) 
	menu_delay_timer.timeout.connect(_show_level_complete_menu)

func _show_level_complete_menu():
	print("[{name}] _show_level_complete_menu: Показ меню завершения уровня.")
	get_tree().paused = true 

	if LevelCompleteMenuScene:
		var menu_instance = LevelCompleteMenuScene.instantiate()
		get_tree().root.add_child(menu_instance) 
		
		if menu_instance.has_method("setup_menu_with_stats"):
			print("[{name}] Вызов setup_menu_with_stats с данными: {_level_complete_data}")
			menu_instance.setup_menu_with_stats(_level_complete_data)
		else:
			printerr("[{name}] !!! ОШИБКА: Меню завершения уровня не имеет метода setup_menu_with_stats!")
	else:
		printerr("[{name}] !!! ОШИБКА: Сцена LevelCompleteMenuScene не загружена!")

# ... (ваша функция find_ui_node())
func find_ui_node():
	var ui = get_node_or_null("UI") 
	if not ui:
		var ui_nodes_in_group = get_tree().get_nodes_in_group("ui_group") # Если используете группу
		if not ui_nodes_in_group.is_empty():
			ui = ui_nodes_in_group[0]
	if not ui: printerr("[{name}] find_ui_node: Узел UI не найден!")
	return ui
