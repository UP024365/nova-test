extends Node2D

# 건물·컨베이어 설치와 건설 메뉴 선택.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


func update_hovered_pole() -> void:
	game.has_hovered_pole = false

	if not game.mouse_in_game:
		return

	if game.buildings.get(game.mouse_cell, "") == "전봇대":
		game.hovered_pole_cell = game.mouse_cell
		game.has_hovered_pole = true


func select_from_menu(pos: Vector2) -> void:
	if pos.y >= 86 and pos.y < 120:
		game.selected_building = "채굴기"
	elif pos.y >= 126 and pos.y < 160:
		game.selected_building = "석탄 광산"
	elif pos.y >= 166 and pos.y < 200:
		game.selected_building = "용광로"
	elif pos.y >= 206 and pos.y < 240:
		game.selected_building = "발전기"
	elif pos.y >= 246 and pos.y < 280:
		game.selected_building = "석탄 발전소"
	elif pos.y >= 286 and pos.y < 320:
		game.selected_building = "컨베이어"
	elif pos.y >= 326 and pos.y < 360:
		game.selected_building = "창고"
	elif pos.y >= 366 and pos.y < 400:
		game.selected_building = "전봇대"


# --------------------------------
# 자원 및 건물 설치
# --------------------------------

func get_storage_capacity() -> int:
	var warehouse_count: int = 0

	for cell in game.buildings.keys():
		if game.buildings[cell] == "창고":
			warehouse_count += 1

	return FactoryGame.BASE_STORAGE + warehouse_count * FactoryGame.WAREHOUSE_CAPACITY


func get_total_coal() -> int:
	var total: int = 0

	for cell in game.power_plant_coal.keys():
		total += game.power_plant_coal[cell]

	return total


func place_building(cell: Vector2i) -> void:
	if game.buildings.has(cell) or game.belts.has(cell):
		return

	var cost: int = FactoryGame.BUILD_COSTS[game.selected_building]

	if game.iron_ingots < cost:
		return

	game.iron_ingots -= cost
	game.total_ingots_spent += cost

	game.buildings[cell] = game.selected_building

	if game.selected_building == "채굴기":
		game.miner_timers[cell] = 0.0

	if game.selected_building == "석탄 광산":
		game.miner_timers[cell] = 0.0

	if game.selected_building == "용광로":
		game.furnace_ore[cell] = 0
		game.furnace_ingots[cell] = 0
		game.furnace_timers[cell] = 0.0

	if game.selected_building == "석탄 발전소":
		game.power_plant_coal[cell] = 0
		game.power_plant_timers[cell] = 0.0

		if not game.starter_fuel_given:
			game.power_plant_coal[cell] = 5
			game.starter_fuel_given = true

	game.power.calculate_power()


func place_belt(cell: Vector2i, direction: Vector2i) -> void:
	if game.buildings.has(cell) or game.belts.has(cell):
		return

	var cost: int = FactoryGame.BUILD_COSTS["컨베이어"]

	if game.iron_ingots < cost:
		return

	game.iron_ingots -= cost
	game.total_ingots_spent += cost

	game.belts[cell] = direction


func handle_belt_drag(cell: Vector2i) -> void:
	if cell == game.last_drag_cell:
		return

	var difference: Vector2i = cell - game.last_drag_cell

	if abs(difference.x) >= abs(difference.y):
		game.drag_direction = Vector2i.RIGHT if difference.x > 0 else Vector2i.LEFT
	else:
		game.drag_direction = Vector2i.DOWN if difference.y > 0 else Vector2i.UP

	var distance: int = abs(difference.x) + abs(difference.y)

	for i in range(1, distance + 1):
		var target: Vector2i = game.last_drag_cell + game.drag_direction * i
		place_belt(target, game.drag_direction)

	game.last_drag_cell = cell
