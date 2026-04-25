extends Control

@onready var levels_label = %LevelsLabel
@onready var average_label = %AverageLabel

func _ready():
	# проверяем, что узлы существуют, прежде чем писать в них текст
	if levels_label == null or average_label == null:
		print("ОШИБКА: Метки статистики не найдены! Проверь Unique Name (%) в сцене Stats")
		return

	# Вывод пройденных уровней
	levels_label.text = "Пройдено уровней: " + str(Global.levels_completed)
	
	# Расчет среднего количества попыток
	var average = 0.0
	if Global.levels_completed > 0:
		# Используем float для точного расчета
		average = float(Global.total_attempts) / float(Global.levels_completed)
	
	# Вывод среднего значения
	average_label.text = "Среднее кол-во попыток: %.2f" % average

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
