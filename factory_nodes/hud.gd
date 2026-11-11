extends Node2D

# 건설 메뉴, 상태 정보, 연구 패널.
const FactoryGame = preload("res://factory_nodes/factory_game.gd")

@onready var game: FactoryGame = get_parent() as FactoryGame


# --------------------------------
# 메뉴
# --------------------------------

func draw_menu() -> void:
	draw_rect(
		Rect2(0, 0, FactoryGame.UI_WIDTH, 720),
		Color("#171e1c")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 42),
		"NOVA INDUSTRIA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("#d9e6dc")
	)

	draw_line(
		Vector2(15, 60),
		Vector2(175, 60),
		Color("#53645a"),
		2.0
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 78),
		"BUILD MENU",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color("#91a69a")
	)

	draw_menu_button(86, "채굴기")
	draw_menu_button(126, "석탄 광산")
	draw_menu_button(166, "용광로")
	draw_menu_button(206, "발전기")
	draw_menu_button(246, "석탄 발전소")
	draw_menu_button(286, "컨베이어")
	draw_menu_button(326, "창고")
	draw_menu_button(366, "전봇대")

	draw_line(
		Vector2(15, 410),
		Vector2(175, 410),
		Color("#53645a"),
		2.0
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 432),
		"RESOURCE STATUS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("#91a69a")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 455),
		"철괴: " + str(game.iron_ingots),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("#e5c77c")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 475),
		"보관 한도: " + str(game.construction.get_storage_capacity()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("#d9e6dc")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 497),
		"석탄 재고: " + str(game.construction.get_total_coal()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("#d9e6dc")
	)

	var power_color: Color = Color("#e66b55")

	if game.power_shortage == 0:
		power_color = Color("#8ed18a")

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 521),
		"발전: " + str(game.power_output) + " kW",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		power_color
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 539),
		"소비: " + str(game.power_used) + " / " + str(game.power_demand),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#d9e6dc")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 557),
		"잔여 전력: " + str(game.power_remaining),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#8ed18a")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 575),
		"부족 전력: " + str(game.power_shortage),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#e66b55") if game.power_shortage > 0 else Color("#d9e6dc")
	)

	var power_status: String = "전력 공급 정상"

	if game.power_demand == 0:
		power_status = "전력 소비 없음"
	elif game.power_shortage > 0:
		power_status = "우선순위에 따라 차단"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 593),
		power_status,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		9,
		power_color
	)
	draw_line(
		Vector2(15, 610),
		Vector2(175, 610),
		Color("#53645a"),
		1.0
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 630),
		"PRODUCTION STATS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("#91a69a")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 649),
		"철광석: " + str(game.total_ore_mined),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#d9e6dc")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 666),
		"석탄: " + str(game.total_coal_mined),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#d9e6dc")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 683),
		"철괴 생산: " + str(game.total_ingots_produced),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#d9e6dc")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 700),
		"건설 소비: " + str(game.total_ingots_spent),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#d9e6dc")
	)

	var range_status: String = "V: 범위 표시 ON"

	if not game.show_power_ranges:
		range_status = "V: 범위 표시 OFF"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 715),
		range_status,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color("#a9c6a5")
	)


func draw_menu_button(y: int, label: String) -> void:
	var button_color: Color = Color("#46564d")

	if game.selected_building == label:
		button_color = Color("#728d72")

	draw_rect(
		Rect2(15, y, 160, 34),
		button_color
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(25, y + 23),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color("#ffffff")
	)


func draw_research_panel() -> void:
	if not game.research_panel_open:
		if game.save_message != "":
			draw_string(ThemeDB.fallback_font, Vector2(210, 30), game.save_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffe09a"))
		return

	var panel_rect := Rect2(850, 35, 390, 250)
	draw_rect(panel_rect, Color(0.08, 0.11, 0.10, 0.96))
	draw_rect(panel_rect, Color("#8ba995"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(870, 65), "RESEARCH LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e1eadf"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 92), "연구 포인트: " + str(game.research_points), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e7c978"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 130), "1. 채굴 효율  Lv." + str(game.mining_research_level) + "/3  (다음 비용 " + str((game.mining_research_level + 1) * 5) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d9e6dc"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 166), "2. 제련 기술  Lv." + str(game.smelting_research_level) + "/3  (다음 비용 " + str((game.smelting_research_level + 1) * 5) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d9e6dc"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 202), "3. 연료 효율  Lv." + str(game.fuel_research_level) + "/3  (다음 비용 " + str((game.fuel_research_level + 1) * 5) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d9e6dc"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 245), "숫자 1 / 2 / 3 키로 연구 · R 키로 닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9fc6a8"))

	if game.save_message != "":
		draw_string(ThemeDB.fallback_font, Vector2(870, 270), game.save_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffe09a"))


func _draw() -> void:
	draw_menu()
	draw_research_panel()
