extends Node2D

# 연구 구매, 저장 및 불러오기.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


# --------------------------------
# 연구 시스템 / 저장 및 불러오기
# --------------------------------

func buy_research(research_name: String) -> void:
	var current_level: int = 0
	if research_name == "채굴 효율":
		current_level = game.mining_research_level
	elif research_name == "제련 기술":
		current_level = game.smelting_research_level
	elif research_name == "연료 효율":
		current_level = game.fuel_research_level

	if current_level >= 3:
		game.save_message = "최대 연구 단계입니다."
		game.save_message_timer = 2.0
		return

	var cost: int = (current_level + 1) * 5
	if game.research_points < cost:
		game.save_message = "연구 포인트가 부족합니다."
		game.save_message_timer = 2.0
		return

	game.research_points -= cost
	if research_name == "채굴 효율":
		game.mining_research_level += 1
	elif research_name == "제련 기술":
		game.smelting_research_level += 1
	elif research_name == "연료 효율":
		game.fuel_research_level += 1

	game.save_message = research_name + " 연구 완료!"
	game.save_message_timer = 2.0


func save_game() -> void:
	var data: Dictionary = {}
	var building_records: Array = []
	for cell in game.buildings.keys():
		building_records.append({
			"x": cell.x,
			"y": cell.y,
			"name": game.buildings[cell],
			"miner_timer": game.miner_timers.get(cell, 0.0),
			"furnace_ore": game.furnace_ore.get(cell, 0),
			"furnace_ingots": game.furnace_ingots.get(cell, 0),
			"furnace_timer": game.furnace_timers.get(cell, 0.0),
			"plant_coal": game.power_plant_coal.get(cell, 0),
			"plant_timer": game.power_plant_timers.get(cell, 0.0)
		})

	var belt_records: Array = []
	for cell in game.belts.keys():
		var direction: Vector2i = game.belts[cell]
		belt_records.append({"x": cell.x, "y": cell.y, "dx": direction.x, "dy": direction.y})

	var item_records: Array = []
	for item in game.items:
		var item_cell: Vector2i = item.get("cell", Vector2i.ZERO)
		item_records.append({
			"x": item_cell.x,
			"y": item_cell.y,
			"progress": item.get("progress", 0.0),
			"type": item.get("type", "철광석")
		})

	data = {
		"version": 2,
		"iron_ingots": game.iron_ingots,
		"total_ore_mined": game.total_ore_mined,
		"total_coal_mined": game.total_coal_mined,
		"total_ingots_produced": game.total_ingots_produced,
		"total_ingots_spent": game.total_ingots_spent,
		"starter_fuel_given": game.starter_fuel_given,
		"research_points": game.research_points,
		"mining_research_level": game.mining_research_level,
		"smelting_research_level": game.smelting_research_level,
		"fuel_research_level": game.fuel_research_level,
		"buildings": building_records,
		"belts": belt_records,
		"items": item_records
	}

	var file := FileAccess.open(FactoryGame.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		game.save_message = "저장 파일을 열 수 없습니다."
		game.save_message_timer = 3.0
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	game.save_message = "게임 저장 완료"
	game.save_message_timer = 2.5


func load_game() -> void:
	if not FileAccess.file_exists(FactoryGame.SAVE_PATH):
		game.save_message = "저장 파일이 없습니다."
		game.save_message_timer = 3.0
		return

	var file := FileAccess.open(FactoryGame.SAVE_PATH, FileAccess.READ)
	if file == null:
		game.save_message = "저장 파일을 읽을 수 없습니다."
		game.save_message_timer = 3.0
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		game.save_message = "저장 파일 형식이 올바르지 않습니다."
		game.save_message_timer = 3.0
		return

	var data: Dictionary = parsed
	game.buildings.clear()
	game.belts.clear()
	game.items.clear()
	game.miner_timers.clear()
	game.furnace_ore.clear()
	game.furnace_ingots.clear()
	game.furnace_timers.clear()
	game.power_plant_coal.clear()
	game.power_plant_timers.clear()

	game.iron_ingots = int(data.get("iron_ingots", 30))
	game.total_ore_mined = int(data.get("total_ore_mined", 0))
	game.total_coal_mined = int(data.get("total_coal_mined", 0))
	game.total_ingots_produced = int(data.get("total_ingots_produced", 0))
	game.total_ingots_spent = int(data.get("total_ingots_spent", 0))
	game.starter_fuel_given = bool(data.get("starter_fuel_given", false))
	game.research_points = int(data.get("research_points", 0))
	game.mining_research_level = int(data.get("mining_research_level", 0))
	game.smelting_research_level = int(data.get("smelting_research_level", 0))
	game.fuel_research_level = int(data.get("fuel_research_level", 0))

	for record in data.get("buildings", []):
		var cell := Vector2i(int(record.get("x", 0)), int(record.get("y", 0)))
		var building_name: String = str(record.get("name", ""))
		if building_name == "":
			continue
		game.buildings[cell] = building_name
		if building_name == "채굴기" or building_name == "석탄 광산":
			game.miner_timers[cell] = float(record.get("miner_timer", 0.0))
		elif building_name == "용광로":
			game.furnace_ore[cell] = int(record.get("furnace_ore", 0))
			game.furnace_ingots[cell] = int(record.get("furnace_ingots", 0))
			game.furnace_timers[cell] = float(record.get("furnace_timer", 0.0))
		elif building_name == "석탄 발전소":
			game.power_plant_coal[cell] = int(record.get("plant_coal", 0))
			game.power_plant_timers[cell] = float(record.get("plant_timer", 0.0))

	for record in data.get("belts", []):
		var belt_cell := Vector2i(int(record.get("x", 0)), int(record.get("y", 0)))
		var direction := Vector2i(int(record.get("dx", 1)), int(record.get("dy", 0)))
		game.belts[belt_cell] = direction

	for record in data.get("items", []):
		game.items.append({
			"cell": Vector2i(int(record.get("x", 0)), int(record.get("y", 0))),
			"progress": float(record.get("progress", 0.0)),
			"type": str(record.get("type", "철광석"))
		})

	game.autosave_timer = 0.0
	game.power.calculate_power()
	game.save_message = "게임 불러오기 완료"
	game.save_message_timer = 2.5
	game.redraw_game()
