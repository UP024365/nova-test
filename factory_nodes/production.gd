extends Node2D

# 채굴, 컨베이어 자원 운반, 용광로 제련.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


# --------------------------------
# 채굴
# --------------------------------

func update_miners(delta: float) -> void:
	for cell in game.buildings.keys():
		var building_name: String = game.buildings[cell]

		if building_name != "채굴기" and building_name != "석탄 광산":
			continue

		if not game.power.is_building_powered(cell):
			continue

		var timer: float = game.miner_timers.get(cell, 0.0)
		timer += delta

		if timer >= FactoryGame.MINING_INTERVAL / (1.0 + float(game.mining_research_level) * 0.2):
			if building_name == "채굴기":
				if try_spawn_resource(cell, "철광석"):
					timer = 0.0
				else:
					timer = FactoryGame.MINING_INTERVAL / (1.0 + float(game.mining_research_level) * 0.2)

			elif building_name == "석탄 광산":
				if try_spawn_resource(cell, "석탄"):
					timer = 0.0
				else:
					timer = FactoryGame.MINING_INTERVAL / (1.0 + float(game.mining_research_level) * 0.2)

		game.miner_timers[cell] = timer


func try_spawn_resource(miner_cell: Vector2i, resource_type: String) -> bool:
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.DOWN,
		Vector2i.UP
	]

	for direction in directions:
		var belt_cell: Vector2i = miner_cell + direction

		if game.belts.has(belt_cell):
			if game.belts[belt_cell] == direction:
				game.items.append({
					"cell": belt_cell,
					"progress": 0.0,
					"type": resource_type
				})

				if resource_type == "철광석":
					game.total_ore_mined += 1
				elif resource_type == "석탄":
					game.total_coal_mined += 1

				return true

	return false


# --------------------------------
# 컨베이어 및 자원 이동
# --------------------------------

func update_items(delta: float) -> void:
	for i in range(game.items.size() - 1, -1, -1):
		var item: Dictionary = game.items[i]

		var current_cell: Vector2i = item["cell"]
		var progress: float = item["progress"]
		var resource_type: String = item["type"]

		progress += FactoryGame.BELT_SPEED * delta

		var remove_item: bool = false

		while progress >= 1.0:
			progress -= 1.0

			if not game.belts.has(current_cell):
				remove_item = true
				break

			var next_cell: Vector2i = current_cell + game.belts[current_cell]

			if game.belts.has(next_cell):
				current_cell = next_cell

			elif game.buildings.has(next_cell):
				var target_building: String = game.buildings[next_cell]

				if resource_type == "철광석" and target_building == "용광로":
					game.furnace_ore[next_cell] = game.furnace_ore.get(next_cell, 0) + 1

				elif resource_type == "석탄" and target_building == "석탄 발전소":
					game.power_plant_coal[next_cell] = game.power_plant_coal.get(next_cell, 0) + 1

				remove_item = true
				break

			else:
				remove_item = true
				break

		if remove_item:
			game.items.remove_at(i)
		else:
			item["cell"] = current_cell
			item["progress"] = progress
			game.items[i] = item


# --------------------------------
# 용광로
# --------------------------------

func update_furnaces(delta: float) -> void:
	for cell in game.buildings.keys():
		if game.buildings[cell] != "용광로":
			continue

		if not game.power.is_building_powered(cell):
			continue

		var ore: int = game.furnace_ore.get(cell, 0)
		var timer: float = game.furnace_timers.get(cell, 0.0)

		if ore > 0 and game.iron_ingots < game.construction.get_storage_capacity():
			timer += delta

			if timer >= FactoryGame.SMELTING_TIME / (1.0 + float(game.smelting_research_level) * 0.2):
				game.furnace_ore[cell] -= 1
				game.furnace_ingots[cell] = game.furnace_ingots.get(cell, 0) + 1

				game.iron_ingots += 1
				game.total_ingots_produced += 1
				game.research_points += 1

				timer = 0.0
		else:
			timer = 0.0

		game.furnace_timers[cell] = timer
