extends Node2D

# 설비, 전선, 자원 및 마우스 위치 시각화.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


# --------------------------------
# 전력선 그리기
# --------------------------------

func draw_power_lines() -> void:
	# 발전소와 전봇대 사이의 실제 연결 관계를 항상 표시
	for source in game.buildings.keys():
		if game.buildings[source] != "석탄 발전소":
			continue

		for pole_cell in game.buildings.keys():
			if game.buildings[pole_cell] != "전봇대":
				continue

			if game.grid_distance(source, pole_cell) <= FactoryGame.POLE_CONNECTION_RANGE:
				var line_color: Color = Color("#69756d")

				if game.powered_poles.has(pole_cell) and game.power_plant_coal.get(source, 0) > 0:
					line_color = Color("#e5d28b")

				draw_line(
					game.grid_to_screen(source) + Vector2(0, -15),
					game.grid_to_screen(pole_cell) + Vector2(0, -15),
					line_color,
					2.0
				)

	# 전봇대끼리의 연결 관계 표시
	for pole_cell in game.buildings.keys():
		if game.buildings[pole_cell] != "전봇대":
			continue

		for other_pole in game.buildings.keys():
			if game.buildings[other_pole] != "전봇대":
				continue

			if pole_cell == other_pole or not is_cell_before(pole_cell, other_pole):
				continue

			if game.grid_distance(pole_cell, other_pole) <= FactoryGame.POLE_CONNECTION_RANGE:
				var line_color: Color = Color("#69756d")

				if game.powered_poles.has(pole_cell) and game.powered_poles.has(other_pole):
					line_color = Color("#e5d28b")

				draw_line(
					game.grid_to_screen(pole_cell) + Vector2(0, -15),
					game.grid_to_screen(other_pole) + Vector2(0, -15),
					line_color,
					2.0
				)


func draw_hovered_power_network() -> void:
	if not game.has_hovered_pole:
		return

	var network: Dictionary = game.power.get_hovered_power_network()
	var network_poles: Dictionary = network["poles"]
	var network_generators: Dictionary = network["generators"]
	var network_machines: Dictionary = network["machines"]

	# 연결된 전봇대와 기계에 반투명 강조 표시
	for pole_cell in network_poles.keys():
		var pole_pos: Vector2 = game.grid_to_screen(pole_cell)
		draw_circle(pole_pos, 25.0, Color(0.25, 0.85, 1.0, 0.16))
		draw_arc(pole_pos, 29.0, 0.0, TAU, 32, Color("#55dfff"), 3.0)

	for generator_cell in network_generators.keys():
		var generator_pos: Vector2 = game.grid_to_screen(generator_cell)
		draw_rect(
			Rect2(generator_pos - Vector2(29, 29), Vector2(58, 58)),
			Color(0.25, 0.85, 1.0, 0.12)
		)
		draw_rect(
			Rect2(generator_pos - Vector2(29, 29), Vector2(58, 58)),
			Color("#55dfff"),
			false,
			2.0
		)

	for machine_cell in network_machines.keys():
		var machine_pos: Vector2 = game.grid_to_screen(machine_cell)
		draw_rect(
			Rect2(machine_pos - Vector2(29, 29), Vector2(58, 58)),
			Color(0.25, 0.85, 1.0, 0.12)
		)
		draw_rect(
			Rect2(machine_pos - Vector2(29, 29), Vector2(58, 58)),
			Color("#55dfff"),
			false,
			2.0
		)

	# 선택한 전봇대 네트워크의 전선을 밝은 청록색으로 덧그림
	for pole_cell in network_poles.keys():
		for other_pole in network_poles.keys():
			if pole_cell == other_pole or not is_cell_before(pole_cell, other_pole):
				continue

			if game.grid_distance(pole_cell, other_pole) <= FactoryGame.POLE_CONNECTION_RANGE:
				draw_line(
					game.grid_to_screen(pole_cell) + Vector2(0, -15),
					game.grid_to_screen(other_pole) + Vector2(0, -15),
					Color("#55dfff"),
					4.0
				)

	for generator_cell in network_generators.keys():
		for pole_cell in network_poles.keys():
			if game.grid_distance(generator_cell, pole_cell) <= FactoryGame.POLE_CONNECTION_RANGE:
				draw_line(
					game.grid_to_screen(generator_cell) + Vector2(0, -15),
					game.grid_to_screen(pole_cell) + Vector2(0, -15),
					Color("#55dfff"),
					4.0
				)


func is_cell_before(a: Vector2i, b: Vector2i) -> bool:
	if a.x < b.x:
		return true

	if a.x == b.x and a.y < b.y:
		return true

	return false


# --------------------------------
# 컨베이어
# --------------------------------

func draw_belts() -> void:
	for cell in game.belts.keys():
		var center: Vector2 = game.grid_to_screen(cell)
		var direction: Vector2i = game.belts[cell]

		draw_rect(
			Rect2(center - Vector2(25, 25), Vector2(50, 50)),
			Color("#39413e")
		)

		draw_rect(
			Rect2(center - Vector2(21, 8), Vector2(42, 16)),
			Color("#a18b55")
		)

		draw_line(
			center - Vector2(15, 0),
			center + Vector2(15, 0),
			Color("#e0c17b"),
			3.0
		)

		var arrow_end: Vector2 = center + Vector2(direction) * 17.0
		var perpendicular: Vector2 = Vector2(-direction.y, direction.x)

		var triangle: PackedVector2Array = [
			arrow_end + Vector2(direction) * 7.0,
			arrow_end - Vector2(direction) * 5.0 + perpendicular * 6.0,
			arrow_end - Vector2(direction) * 5.0 - perpendicular * 6.0
		]

		draw_colored_polygon(triangle, Color("#fff0bd"))


# --------------------------------
# 건물 그리기 및 전력 상태 표시
# --------------------------------

func draw_buildings() -> void:
	for cell in game.buildings.keys():
		var pos: Vector2 = game.grid_to_screen(cell)
		var building_name: String = game.buildings[cell]

		draw_pixel_building(pos, building_name)

		# 전력 소비 건물에 상태 표시
		if building_name == "채굴기" or building_name == "석탄 광산" or building_name == "용광로":
			var status_color: Color = Color("#e65e50")

			if game.power.is_building_powered(cell):
				status_color = Color("#72e08a")

			draw_rect(
				Rect2(pos + Vector2(16, -25), Vector2(10, 10)),
				status_color
			)

			# 전력 공급 우선순위 표시
			var priority_label: String = "P" + str(game.power.get_building_priority(cell))
			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-8, -30),
				priority_label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				8,
				Color("#f1d58b")
			)

			var connection_label: String = "망 미연결"
			var connection_color: Color = Color("#e65e50")

			if game.power.is_building_connected_to_grid(cell):
				connection_label = "망 연결"
				connection_color = Color("#8ed18a")

			if game.power.is_building_connected_to_grid(cell) and not game.power.is_building_powered(cell):
				connection_label = "전력 부족"
				connection_color = Color("#e5a45b")

			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-25, 55),
				connection_label,
				HORIZONTAL_ALIGNMENT_CENTER,
				50,
				8,
				connection_color
			)

			# 공급 중인 건물은 은은한 초록색 표시
			if game.power.is_building_powered(cell):
				draw_rect(
					Rect2(pos - Vector2(25, 25), Vector2(50, 50)),
					Color(0.25, 0.9, 0.4, 0.10)
				)

		if building_name == "용광로":
			var ore: int = game.furnace_ore.get(cell, 0)
			var ingots: int = game.furnace_ingots.get(cell, 0)
			var timer: float = game.furnace_timers.get(cell, 0.0)

			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-29, 30),
				"광석 " + str(ore),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color("#e3c078")
			)

			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-29, 43),
				"생산 " + str(ingots),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color("#d4dce0")
			)

			if ore > 0 and game.power.is_building_powered(cell) and game.iron_ingots < game.construction.get_storage_capacity():
				var progress: float = clampf(timer / (FactoryGame.SMELTING_TIME / (1.0 + float(game.smelting_research_level) * 0.2)), 0.0, 1.0)

				draw_rect(
					Rect2(pos + Vector2(-23, -34), Vector2(46, 5)),
					Color("#493c32")
				)

				draw_rect(
					Rect2(pos + Vector2(-23, -34), Vector2(46 * progress, 5)),
					Color("#e9a04b")
				)

		elif building_name == "석탄 발전소":
			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-27, -31),
				"최대 " + str(FactoryGame.POWER_PER_PLANT) + " kW",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				9,
				Color("#8ed18a")
			)

			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-27, 34),
				"석탄 " + str(game.power_plant_coal.get(cell, 0)),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color("#e0c17b")
			)

		elif building_name == "전봇대":
			var pole_status: String = "대기"
			var pole_color: Color = Color("#aaaaaa")

			if game.powered_poles.has(cell):
				pole_status = "연결"
				pole_color = Color("#8ed18a")

			draw_circle(
				pos + Vector2(0, -27),
				6.0,
				pole_color
			)

			draw_string(
				ThemeDB.fallback_font,
				pos + Vector2(-17, 35),
				pole_status,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				pole_color
			)


			if game.has_hovered_pole and game.hovered_pole_cell == cell:
				draw_string(
					ThemeDB.fallback_font,
					pos + Vector2(-30, -43),
					"전력망 강조 중",
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					9,
				Color("#55dfff")
			)


func draw_pixel_building(pos: Vector2, building_name: String) -> void:
	if building_name == "채굴기":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#596b5b"))
		draw_rect(Rect2(pos - Vector2(16, 16), Vector2(32, 32)), Color("#a9b3a1"))
		draw_rect(Rect2(pos - Vector2(7, 7), Vector2(14, 14)), Color("#39443c"))
		draw_rect(Rect2(pos + Vector2(-4, -28), Vector2(8, 12)), Color("#d3b56b"))

	elif building_name == "석탄 광산":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#343b3b"))
		draw_rect(Rect2(pos - Vector2(18, -1), Vector2(36, 36)), Color("#59636a"))
		draw_rect(Rect2(pos - Vector2(12, -7), Vector2(24, 24)), Color("#24292d"))
		draw_rect(Rect2(pos - Vector2(5, -10), Vector2(10, 18)), Color("#a6a6a0"))
		draw_rect(Rect2(pos + Vector2(-20, -20), Vector2(40, 5)), Color("#d0a45d"))

	elif building_name == "용광로":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#704b3c"))
		draw_rect(Rect2(pos - Vector2(16, 16), Vector2(32, 32)), Color("#a85e3c"))
		draw_rect(Rect2(pos - Vector2(8, 8), Vector2(16, 16)), Color("#f0a54e"))
		draw_rect(Rect2(pos - Vector2(4, 4), Vector2(8, 8)), Color("#ffe19a"))

	elif building_name == "발전기":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#485d69"))
		draw_rect(Rect2(pos - Vector2(16, 16), Vector2(32, 32)), Color("#829ba2"))
		draw_rect(Rect2(pos - Vector2(6, 6), Vector2(12, 12)), Color("#e4c66f"))
		draw_rect(Rect2(pos + Vector2(-20, -29), Vector2(40, 6)), Color("#a9b8b5"))

	elif building_name == "석탄 발전소":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#424b50"))
		draw_rect(Rect2(pos - Vector2(18, -1), Vector2(36, 34)), Color("#68777a"))
		draw_rect(Rect2(pos - Vector2(10, -9), Vector2(20, 22)), Color("#30383b"))
		draw_rect(Rect2(pos - Vector2(6, -6), Vector2(12, 12)), Color("#e49a48"))
		draw_rect(Rect2(pos + Vector2(-17, -29), Vector2(12, 12)), Color("#9ca8a5"))
		draw_rect(Rect2(pos + Vector2(5, -35), Vector2(12, 18)), Color("#7f8988"))

	elif building_name == "창고":
		draw_rect(Rect2(pos - Vector2(25, 25), Vector2(50, 50)), Color("#695c48"))
		draw_rect(Rect2(pos - Vector2(19, 17), Vector2(38, 34)), Color("#b18d58"))
		draw_rect(Rect2(pos - Vector2(4, 17), Vector2(8, 34)), Color("#72583c"))
		draw_rect(Rect2(pos + Vector2(-19, -21), Vector2(38, 5)), Color("#e0c28b"))

	elif building_name == "전봇대":
		draw_rect(Rect2(pos - Vector2(5, 25), Vector2(10, 50)), Color("#76634b"))
		draw_rect(Rect2(pos - Vector2(21, -10), Vector2(42, 6)), Color("#a58c65"))
		draw_rect(Rect2(pos - Vector2(17, -4), Vector2(5, 10)), Color("#d1c6a3"))
		draw_rect(Rect2(pos + Vector2(12, 4), Vector2(5, 10)), Color("#d1c6a3"))


# --------------------------------
# 아이템
# --------------------------------

func draw_items() -> void:
	for item in game.items:
		var cell: Vector2i = item["cell"]
		var progress: float = item["progress"]
		var resource_type: String = item["type"]

		var direction: Vector2i = game.belts.get(cell, Vector2i.ZERO)

		var start: Vector2 = game.grid_to_screen(cell)
		var end: Vector2 = start + Vector2(direction) * FactoryGame.GRID_SIZE

		var item_position: Vector2 = start.lerp(end, progress)

		var item_color: Color = Color("#d8a64f")

		if resource_type == "석탄":
			item_color = Color("#282d30")

		draw_rect(
			Rect2(item_position - Vector2(7, 7), Vector2(14, 14)),
			item_color
		)

		if resource_type == "철광석":
			draw_rect(
				Rect2(item_position - Vector2(3, 3), Vector2(6, 6)),
				Color("#f5d58a")
			)
		else:
			draw_rect(
				Rect2(item_position - Vector2(3, 3), Vector2(6, 6)),
				Color("#777f82")
			)


# --------------------------------
# 마우스 표시
# --------------------------------

func draw_mouse_highlight() -> void:
	if not game.mouse_in_game:
		return

	var pos: Vector2 = game.grid_to_screen(game.mouse_cell)

	draw_rect(
		Rect2(pos - Vector2(30, 30), Vector2(60, 60)),
		Color(0.8, 0.9, 0.7, 0.15)
	)

	draw_rect(
		Rect2(pos - Vector2(30, 30), Vector2(60, 60)),
		Color("#b5d4a0"),
		false,
		2.0
	)


func _draw() -> void:
	draw_belts()
	draw_power_lines()
	draw_buildings()
	draw_hovered_power_network()
	draw_items()
	draw_mouse_highlight()
