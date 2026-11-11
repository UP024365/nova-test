extends Node2D

# 발전, 연료 소비, 전력 배분과 연결망 조회.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


# --------------------------------
# 전력망 계산
# --------------------------------

func has_pole_in_range(cell: Vector2i) -> bool:
	for other_cell in game.buildings.keys():
		if game.buildings[other_cell] != "전봇대":
			continue

		if game.grid_distance(cell, other_cell) <= FactoryGame.POLE_CONNECTION_RANGE:
			return true

	return false


func calculate_power() -> void:
	game.power_output = 0
	game.power_demand = 0
	game.power_used = 0
	game.power_remaining = 0
	game.power_shortage = 0

	game.powered_poles.clear()
	game.powered_buildings.clear()

	var power_sources: Array[Vector2i] = []

	# 1. 연료가 있고 전봇대에 연결된 발전소의 발전량 합산
	for cell in game.buildings.keys():
		if game.buildings[cell] != "석탄 발전소":
			continue

		if game.power_plant_coal.get(cell, 0) <= 0:
			continue

		if has_pole_in_range(cell):
			game.power_output += FactoryGame.POWER_PER_PLANT
			power_sources.append(cell)

	# 2. 발전소에 연결된 전봇대 찾기
	for source in power_sources:
		for pole_cell in game.buildings.keys():
			if game.buildings[pole_cell] != "전봇대":
				continue

			if game.grid_distance(source, pole_cell) <= FactoryGame.POLE_CONNECTION_RANGE:
				game.powered_poles[pole_cell] = true

	# 3. 연결된 전봇대를 통해 전력망 확장
	var changed: bool = true

	while changed:
		changed = false

		for pole_cell in game.buildings.keys():
			if game.buildings[pole_cell] != "전봇대":
				continue

			if game.powered_poles.has(pole_cell):
				continue

			for connected_pole in game.powered_poles.keys():
				if game.grid_distance(pole_cell, connected_pole) <= FactoryGame.POLE_CONNECTION_RANGE:
					game.powered_poles[pole_cell] = true
					changed = true
					break

	# 4. 전력망에 연결된 기계의 전체 요구량 계산
	for cell in game.buildings.keys():
		var demand: int = get_building_power_demand(cell)

		if demand > 0 and is_building_connected_to_grid(cell):
			game.power_demand += demand

	# 5. 우선순위에 따라 전력 배분
	# 1순위: 석탄 광산 / 2순위: 철광석 채굴기 / 3순위: 용광로
	var available_power: int = game.power_output

	for priority in range(1, 4):
		for cell in game.buildings.keys():
			if get_building_priority(cell) != priority:
				continue

			var demand: int = get_building_power_demand(cell)

			if demand <= 0 or not is_building_connected_to_grid(cell):
				continue

			if available_power >= demand:
				game.powered_buildings[cell] = true
				available_power -= demand
				game.power_used += demand

	game.power_remaining = available_power
	game.power_shortage = max(0, game.power_demand - game.power_used)
	game.power_available = game.power_shortage == 0


func get_building_power_demand(cell: Vector2i) -> int:
	var building_name: String = game.buildings.get(cell, "")

	if building_name == "채굴기" or building_name == "석탄 광산":
		return FactoryGame.MINER_POWER

	if building_name == "용광로":
		return FactoryGame.FURNACE_POWER

	return 0


func get_building_priority(cell: Vector2i) -> int:
	var building_name: String = game.buildings.get(cell, "")

	if building_name == "석탄 광산":
		return 1

	if building_name == "채굴기":
		return 2

	if building_name == "용광로":
		return 3

	return 99


func is_building_connected_to_grid(cell: Vector2i) -> bool:
	for pole_cell in game.powered_poles.keys():
		if game.grid_distance(cell, pole_cell) <= FactoryGame.BUILDING_CONNECTION_RANGE:
			return true

	return false

func is_building_powered(cell: Vector2i) -> bool:
	return game.powered_buildings.has(cell)


# --------------------------------
# 발전소 및 석탄 연소
# --------------------------------

func update_power_plants(delta: float) -> void:
	for cell in game.buildings.keys():
		if game.buildings[cell] != "석탄 발전소":
			continue

		var coal: int = game.power_plant_coal.get(cell, 0)
		var timer: float = game.power_plant_timers.get(cell, 0.0)

		if coal > 0 and has_pole_in_range(cell):
			timer += delta

			while timer >= FactoryGame.COAL_BURN_INTERVAL and coal > 0:
				timer -= FactoryGame.COAL_BURN_INTERVAL * (1.0 + float(game.fuel_research_level) * 0.2)
				coal -= 1
		elif coal <= 0:
			timer = 0.0

		game.power_plant_coal[cell] = coal
		game.power_plant_timers[cell] = timer


func get_hovered_power_network() -> Dictionary:
	var result: Dictionary = {
		"poles": {},
		"generators": {},
		"machines": {}
	}

	if not game.has_hovered_pole:
		return result

	# 마우스가 올라간 전봇대부터 연결된 전봇대를 탐색
	var network_poles: Dictionary = {game.hovered_pole_cell: true}
	var queue: Array[Vector2i] = [game.hovered_pole_cell]

	while not queue.is_empty():
		var current_pole: Vector2i = queue.pop_front()

		for candidate in game.buildings.keys():
			if game.buildings[candidate] != "전봇대":
				continue

			if network_poles.has(candidate):
				continue

			if game.grid_distance(current_pole, candidate) <= FactoryGame.POLE_CONNECTION_RANGE:
				network_poles[candidate] = true
				queue.append(candidate)

	result["poles"] = network_poles

	# 해당 전봇대 네트워크에 닿는 발전소와 기계를 찾음
	for cell in game.buildings.keys():
		var building_name: String = game.buildings[cell]

		if building_name == "석탄 발전소":
			for pole_cell in network_poles.keys():
				if game.grid_distance(cell, pole_cell) <= FactoryGame.POLE_CONNECTION_RANGE:
					result["generators"][cell] = true
					break

		elif get_building_power_demand(cell) > 0:
			for pole_cell in network_poles.keys():
				if game.grid_distance(cell, pole_cell) <= FactoryGame.BUILDING_CONNECTION_RANGE:
					result["machines"][cell] = true
					break

	return result
