# player.gd
extends Node2D

const FactoryGame = preload("res://factory_nodes/factory_game.gd")
@onready var game: FactoryGame = get_parent() as FactoryGame
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const MOVE_SPEED: float = 240.0
const PLAYER_SIZE: float = 14.0

var player_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	# 초기 시작 위치: UI 영역 우측 타일 중앙 부근
	position = Vector2(FactoryGame.UI_WIDTH + 300, 360)
	player_cell = game.get_grid_cell(position)
	if sprite:
		sprite.play("idle")


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

	# 이동 및 스프라이트 애니메이션 제어
	if move_vec != Vector2.ZERO:
		move_vec = move_vec.normalized()

		if sprite:
			if move_vec.y < 0: # 위로 이동 (뒷모습)
				sprite.play("walk_up")
				sprite.flip_h = false
			elif move_vec.y > 0 and abs(move_vec.x) < 0.1: # 정면 아래로 이동
				sprite.play("idle")
				sprite.flip_h = false
			else: # 좌우 이동
				sprite.play("walk_side")
				sprite.flip_h = (move_vec.x < 0) # 왼쪽으로 갈 때 좌우 반전

		var target_pos: Vector2 = position + move_vec * MOVE_SPEED * delta

		# UI 패널(좌측 190px) 및 상단 경계 침범 방지
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
	else:
		if sprite:
			sprite.play("idle")

	player_cell = game.get_grid_cell(position)


func _draw() -> void:
	# 플레이어가 서 있는 타일 하이라이트 (본체는 AnimatedSprite2D가 출력)
	var cell_center: Vector2 = game.grid_to_screen(player_cell) - position
	draw_rect(
		Rect2(
			cell_center - Vector2(FactoryGame.GRID_SIZE / 2.0, FactoryGame.GRID_SIZE / 2.0),
			Vector2(FactoryGame.GRID_SIZE, FactoryGame.GRID_SIZE)
		),
		Color(0.5, 0.9, 0.6, 0.08),
		false,
		1.5
	)
