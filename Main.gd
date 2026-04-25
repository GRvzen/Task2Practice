extends Node

var save_path = "user://stats.save"

# Данные для статистики
var levels_completed: int = 0
var total_attempts: int = 0

var selected_level_id: int = 1

func _ready():
	load_data()

# Сохранение в JSON
func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var data = {
		"levels_completed": levels_completed,
		"total_attempts": total_attempts
	}
	file.store_string(JSON.stringify(data))

# Загрузка данных при старте
func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data:
			levels_completed = data.get("levels_completed", 0)
			total_attempts = data.get("total_attempts", 0)
