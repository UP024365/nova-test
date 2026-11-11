extends Node2D

# 공용 상태, 입력, 시뮬레이션 순서, 배경과 격자.
@onready var construction = $Construction
@onready var power = $Power
@onready var production = $Production
@onready var progress = $Progress
@onready var hud = $CanvasLayer/HUD
@onready var world_view = $WorldView
@onready var player = $Player


const GRID_SIZE: int = 64
const UI_WIDTH: int = 190

const BELT_SPEED: float = 1.2
const MINING_INTERVAL: float = 2.0
const SMELTING_TIME: float = 4.0

const POWER_PER_PLANT: int = 10
const COAL_BURN_INTERVAL: float = 6.0

const MINER_POWER: int = 2
const FURNACE_POWER: int = 3

const POLE_CONNECTION_RANGE: int = 4
const BUILDING_CONNECTION_RANGE: int = 2

const BUILD_COSTS: Dictionary = {
	"채굴기": 5,
	"용광로": 10,
	"발전기": 8,
	"컨베이어": 1,
	"창고": 15,
	"석탄 광산": 8,
	"석탄 발전소": 10,
	"전봇대": 3
}

const BASE_STORAGE: int = 50
const WAREHOUSE_CAPACITY: int = 100

var iron_ingots: int = 30

var total_ore_mined: int = 0
var total_coal_mined: int = 0
var total_ingots_produced: int = 0
var total_ingots_spent: int = 0

var power_output: int = 0
var power_demand: int = 0
var power_used: int = 0
var power_remaining: int = 0
var power_shortage: int = 0
var power_available: bool = false

var powered_poles: Dictionary = {}
var powered_buildings: Dictionary = {}

var starter_fuel_given: bool = false

var buildings: Dictionary = {}
var belts: Dictionary = {}
var items: Array = []

var selected_building: String = "채굴기"

var dragging_belt: bool = false
var last_drag_cell: Vector2i = Vector2i.ZERO
var drag_direction: Vector2i = Vector2i.RIGHT

var miner_timers: Dictionary = {}

var furnace_ore: Dictionary = {}
var furnace_ingots: Dictionary = {}
var furnace_timers: Dictionary = {}

var power_plant_coal: Dictionary = {}
var power_plant_timers: Dictionary = {}

var mouse_cell: Vector2i = Vector2i.ZERO
var mouse_in_game: bool = false

# STEP 19: 전력 범위 표시
var show_power_ranges: bool = true

# STEP 21: 전봇대 마우스 오버 및 전력망 강조 표시
var hovered_pole_cell: Vector2i = Vector2i.ZERO
var has_hovered_pole: bool = false

# 통합 업데이트: 연구, 저장, 자동 저장
var research_panel_open: bool = false
var research_points: int = 0
var mining_research_level: int = 0
var smelting_research_level: int = 0
var fuel_research_level: int = 0
var autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL: float = 60.0
const SAVE_PATH: String = "user://nova_industria_save.json"
var save_message: String = ""
var save_message_timer: float = 0.0


func _ready() -> void:
	redraw_game()


func _process(delta: float) -> void:
	player.update_player(delta)
	
	power.update_power_plants(delta)
	power.calculate_power()

	production.update_miners(delta)
	production.update_items(delta)
	production.update_furnaces(delta)

	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		autosave_timer = 0.0
		progress.save_game()

	if save_message_timer > 0.0:
		save_message_timer = maxf(0.0, save_message_timer - delta)
		if save_message_timer == 0.0:
			save_message = ""

	redraw_game()


func _input(event: InputEvent) -> void:
	# V 키로 전력 범위 표시 전환
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_V:
				show_power_ranges = not show_power_ranges
				redraw_game()
			elif event.keycode == KEY_R:
				research_panel_open = not research_panel_open
				redraw_game()
			elif event.keycode == KEY_F5:
				progress.save_game()
			elif event.keycode == KEY_F9:
				progress.load_game()
			elif research_panel_open and event.keycode == KEY_1:
				progress.buy_research("채굴 효율")
			elif research_panel_open and event.keycode == KEY_2:
				progress.buy_research("제련 기술")
			elif research_panel_open and event.keycode == KEY_3:
				progress.buy_research("연료 효율")

	if event is InputEventMouseMotion:
		# 카메라 이동이 반영된 실제 월드 상의 마우스 위치를 가져옴
		var world_mouse_pos: Vector2 = get_global_mouse_position()
		mouse_cell = get_grid_cell(world_mouse_pos)
		mouse_in_game = event.position.x >= UI_WIDTH  # UI 검사는 화면 좌표 유지
		construction.update_hovered_pole()

		if dragging_belt and mouse_in_game:
			construction.handle_belt_drag(mouse_cell)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.position.x < UI_WIDTH:
					construction.select_from_menu(event.position)
				else:
					var world_mouse_pos: Vector2 = get_global_mouse_position()
					mouse_cell = get_grid_cell(world_mouse_pos)
					mouse_in_game = true
					construction.update_hovered_pole()

					if selected_building == "컨베이어":
						dragging_belt = true
						last_drag_cell = mouse_cell
						construction.place_belt(mouse_cell, drag_direction)
					else:
						construction.place_building(mouse_cell)
			else:
				dragging_belt = false


# --------------------------------
# 좌표 및 메뉴
# --------------------------------

func get_grid_cell(pos: Vector2) -> Vector2i:
	var x: int = int(floor((pos.x - UI_WIDTH) / GRID_SIZE))
	var y: int = int(floor(pos.y / GRID_SIZE))
	return Vector2i(x, y)


func grid_to_screen(cell: Vector2i) -> Vector2:
	return Vector2(
		UI_WIDTH + cell.x * GRID_SIZE + GRID_SIZE / 2.0,
		cell.y * GRID_SIZE + GRID_SIZE / 2.0
	)


func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func draw_background() -> void:
	draw_rect(
		Rect2(0, 0, 1280, 720),
		Color("#26302e")
	)


func draw_grid() -> void:
	for x in range(0, 1200, GRID_SIZE):
		var screen_x: float = UI_WIDTH + x

		draw_line(
			Vector2(screen_x, 0),
			Vector2(screen_x, 720),
			Color("#394541"),
			1.0
		)

	for y in range(0, 720, GRID_SIZE):
		draw_line(
			Vector2(UI_WIDTH, y),
			Vector2(1280, y),
			Color("#394541"),
			1.0
		)


# --------------------------------
# STEP 19: 전력 범위 시각화
# --------------------------------

func draw_power_ranges() -> void:
	if not show_power_ranges:
		return

	for pole_cell in powered_poles.keys():
		# 전봇대의 전체 연결 범위
		for x in range(-POLE_CONNECTION_RANGE, POLE_CONNECTION_RANGE + 1):
			for y in range(-POLE_CONNECTION_RANGE, POLE_CONNECTION_RANGE + 1):
				if abs(x) + abs(y) > POLE_CONNECTION_RANGE:
					continue

				var target_cell: Vector2i = pole_cell + Vector2i(x, y)
				var target_pos: Vector2 = grid_to_screen(target_cell)

				draw_rect(
					Rect2(
						target_pos - Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0),
						Vector2(GRID_SIZE, GRID_SIZE)
					),
					Color(0.25, 0.8, 0.45, 0.055)
				)

		# 기계에 전력을 공급하는 범위
		for x in range(-BUILDING_CONNECTION_RANGE, BUILDING_CONNECTION_RANGE + 1):
			for y in range(-BUILDING_CONNECTION_RANGE, BUILDING_CONNECTION_RANGE + 1):
				if abs(x) + abs(y) > BUILDING_CONNECTION_RANGE:
					continue

				var target_cell: Vector2i = pole_cell + Vector2i(x, y)
				var target_pos: Vector2 = grid_to_screen(target_cell)

				draw_rect(
					Rect2(
						target_pos - Vector2(30, 30),
						Vector2(60, 60)
					),
					Color(0.3, 0.65, 1.0, 0.08)
				)


func _draw() -> void:
	draw_background()
	draw_grid()
	draw_power_ranges()


func redraw_game() -> void:
	queue_redraw()
	hud.queue_redraw()
	world_view.queue_redraw()
	if player:
		player.queue_redraw()
