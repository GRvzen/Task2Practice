extends Control
@onready var grid = $CenterContainer/MainVBox/LevelsGridContainer

func _ready():
	# Подключаем все 10 кнопок уровней в GridContainer
	var level_buttons = grid.get_children()
	for i in range(level_buttons.size()):
		# Передаем индекс кнопки (+1 для номера уровня) в сигнал
		level_buttons[i].pressed.connect(_on_level_selected.bind(i + 1))

func _on_level_selected(level_num: int):
	Global.selected_level_id = level_num
	get_tree().change_scene_to_file("res://scenes/Level.tscn")

func _on_stats_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
