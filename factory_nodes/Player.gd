# player.gd
extends Node2D

const FactoryGame = preload("res://factory_nodes/factory_game.gd")
@onready var game: FactoryGame = get_parent() as FactoryGame

const MOVE_SPEED: float = 240.0
const PLAYER_SIZE: float = 14.0

var player_cell: Vector2i = Vector2i.ZERO
var look_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	# 초기 시작 위치: UI 영역 우측 타일 중앙 부근
	position = Vector2(FactoryGame.UI_WIDTH + 300, 360)
	player_cell = game.get_grid_cell(position)


func update_player(delta: float) -> void:
	var move_vec := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0

	if move_vec != Vector2.ZERO:
		move_vec = move_vec.normalized()
		look_direction = move_vec

		var target_pos: Vector2 = position + move_vec * MOVE_SPEED * delta

		# UI 패널(좌측 190px) 및 상단 경계 침범 방지 (우측·하단은 카메라 확장을 위해 개방)
		target_pos.x = maxf(target_pos.x, FactoryGame.UI_WIDTH + PLAYER_SIZE)
		target_pos.y = maxf(target_pos.y, PLAYER_SIZE)

		var target_cell: Vector2i = game.get_grid_cell(target_pos)
		var can_move: bool = true

		# 건물 충돌 판정 (전봇대/컨베이어는 통과 가능)
		if game.buildings.has(target_cell):
			var building_name: String = game.buildings[target_cell]
			if building_name != "전봇대":
				can_move = false

		if can_move:
			position = target_pos

	player_cell = game.get_grid_cell(position)


func _draw() -> void:
	# 플레이어가 밟고 있는 그리드 셀 하이라이트 (로컬 좌표 변환)
	var cell_center: Vector2 = game.grid_to_screen(player_cell) - position
	draw_rect(
		Rect2(cell_center - Vector2(FactoryGame.GRID_SIZE / 2.0, FactoryGame.GRID_SIZE / 2.0), Vector2(FactoryGame.GRID_SIZE, FactoryGame.GRID_SIZE)),
		Color(0.5, 0.9, 0.6, 0.08),
		false,
		1.5
	)

	# 플레이어 외곽선 및 본체 (중심 0, 0)
	draw_circle(Vector2.ZERO, PLAYER_SIZE, Color("#2e3934"))
	draw_circle(Vector2.ZERO, PLAYER_SIZE - 2.0, Color("#7ec992"))

	# 이동 방향을 바라보는 바이저(눈)
	var eye_offset: Vector2 = look_direction * 5.0
	draw_rect(Rect2(eye_offset - Vector2(3, 3), Vector2(6, 6)), Color("#ffe19a"))
