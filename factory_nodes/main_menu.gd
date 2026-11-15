
extends Control

# ==========================================
# NOVA INDUSTRIA
# MAIN MENU SYSTEM
# Godot 4.x
# ==========================================

@export var game_scene_path: String = "res://factory_game.tscn"
@export var background_texture: Texture2D
@export var ui_font: Font

const SETTINGS_PATH = "user://nova_settings.cfg"

const MENU_ITEMS = [
	"새 게임",
	"불러오기",
	"환경설정",
	"제작진",
    "게임 종료"
]

var hovered_button := -1

var settings_open := false
var credits_open := false
var confirm_exit := false

var master_volume := 1.0
var music_volume := 0.7
var sfx_volume := 0.8

var settings_tab := 1

var dragging_slider := -1

var message := ""
var message_timer := 0.0

var button_rects: Array[Rect2] = []
var slider_rects: Array[Rect2] = []
var tab_rects: Array[Rect2] = []

var back_rect := Rect2()
var apply_rect := Rect2()
var confirm_yes_rect := Rect2()
var confirm_no_rect := Rect2()


# ==========================================
# INITIALIZE
# ==========================================

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

	load_settings()
	update_audio()

	queue_redraw()


func _process(delta):
	if message_timer > 0:
		message_timer -= delta

		if message_timer <= 0:
			message = ""
			queue_redraw()

	var mouse = get_local_mouse_position()
	var old_hover = hovered_button

	hovered_button = -1

	if not settings_open and not credits_open and not confirm_exit:
		for i in range(button_rects.size()):
			if button_rects[i].has_point(mouse):
				hovered_button = i
				break

	if old_hover != hovered_button:
		queue_redraw()


# ==========================================
# DRAW SCREEN
# ==========================================

func _draw():
	var screen = get_rect().size

	button_rects.clear()
	slider_rects.clear()
	tab_rects.clear()

	draw_background(screen)

	if settings_open:
		draw_settings(screen)

	elif credits_open:
		draw_credits(screen)

	else:
		draw_main_menu(screen)

	if confirm_exit:
		draw_exit_confirmation(screen)

	if message != "":
		draw_message(screen)


# ==========================================
# BACKGROUND
# ==========================================

func draw_background(screen: Vector2):

	if background_texture != null:

		draw_texture_rect(
			background_texture,
			Rect2(Vector2.ZERO, screen),
			false
		)

	else:

		# 하늘
		draw_rect(
			Rect2(Vector2.ZERO, screen),
			Color("#344d70")
		)

		# 석양
		draw_circle(
			Vector2(screen.x * 0.76, screen.y * 0.28),
			screen.y * 0.12,
			Color("#e6a05b")
		)

		# 산맥
		var mountains = PackedVector2Array([
			Vector2(0, screen.y * 0.62),
			Vector2(screen.x * 0.18, screen.y * 0.34),
			Vector2(screen.x * 0.34, screen.y * 0.58),
			Vector2(screen.x * 0.55, screen.y * 0.32),
			Vector2(screen.x * 0.78, screen.y * 0.58),
			Vector2(screen.x, screen.y * 0.38),
			Vector2(screen.x, screen.y),
			Vector2(0, screen.y)
		])

		draw_colored_polygon(
			mountains,
			Color("#273d49")
		)

		# 공장 지형
		draw_rect(
			Rect2(
				screen.x * 0.42,
				screen.y * 0.55,
				screen.x * 0.58,
				screen.y * 0.45
			),
			Color("#283a35")
		)

		# 공장 건물
		for i in range(6):

			var x = screen.x * 0.46 + i * screen.x * 0.085
			var height = screen.y * (0.16 + float(i % 3) * 0.07)

			draw_rect(
				Rect2(
					x,
					screen.y * 0.68 - height,
					screen.x * 0.075,
					height
				),
				Color("#596574")
			)

			# 공장 창문
			draw_rect(
				Rect2(
					x + 10,
					screen.y * 0.68 - height + 20,
					13,
					10
				),
				Color("#f4b84c")
			)

		# 굴뚝
		draw_rect(
			Rect2(
				screen.x * 0.62,
				screen.y * 0.17,
				20,
				screen.y * 0.35
			),
			Color("#596574")
		)

		# 바닥
		draw_rect(
			Rect2(
				0,
				screen.y * 0.88,
				screen.x,
				screen.y * 0.12
			),
			Color("#172b2c")
		)


# ==========================================
# MAIN MENU
# ==========================================

func draw_main_menu(screen: Vector2):

	# 왼쪽 어두운 패널
	draw_rect(
		Rect2(
			0,
			0,
			screen.x * 0.35,
			screen.y
		),
		Color(0.04, 0.07, 0.10, 0.91)
	)

	# 제목
	draw_text_center(
		"NOVA",
		Vector2(screen.x * 0.175, screen.y * 0.15),
		55,
		Color("#f1f3f5")
	)

	draw_text_center(
		"INDUSTRIA",
		Vector2(screen.x * 0.175, screen.y * 0.23),
		38,
		Color("#f4a52d")
	)

	draw_text_center(
		"BUILD  •  AUTOMATE  •  EXPAND",
		Vector2(screen.x * 0.175, screen.y * 0.29),
		13,
		Color("#c5cdd2")
	)

	# 버튼 배치
	var button_width = screen.x * 0.28
	var button_height = 53

	var start_x = screen.x * 0.035
	var start_y = screen.y * 0.39

	for i in range(MENU_ITEMS.size()):

		var rect = Rect2(
			start_x,
			start_y + i * 66,
			button_width,
			button_height
		)

		button_rects.append(rect)

		var button_color = Color("#273341")

		if hovered_button == i:
			button_color = Color("#bd812c")

		draw_rect(
			rect,
			button_color
		)

		draw_rect(
			rect,
			Color("#8996a5"),
			false,
			2.0
		)

		draw_text_center(
			MENU_ITEMS[i],
			rect.get_center(),
			22,
			Color.WHITE
		)

	# 하단 버전
	draw_string(
		get_ui_font(),
		Vector2(20, screen.y - 20),
		"NOVA INDUSTRIA v0.1.0",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color("#d4dce4")
	)

	draw_string(
		get_ui_font(),
		Vector2(screen.x - 280, screen.y - 20),
		"A NEW INDUSTRIAL ERA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color("#d4dce4")
	)


# ==========================================
# SETTINGS SCREEN
# ==========================================

func draw_settings(screen: Vector2):

	draw_overlay(screen)

	var panel = Rect2(
		screen.x * 0.2,
		screen.y * 0.13,
		screen.x * 0.6,
		screen.y * 0.74
	)

	draw_rect(
		panel,
		Color("#202b3b")
	)

	draw_rect(
		panel,
		Color("#8996a5"),
		false,
		2.0
	)

	draw_text_center(
		"환경설정",
		Vector2(screen.x * 0.5, panel.position.y + 45),
		30,
		Color.WHITE
	)

	# 설정 탭
	var tabs = [
		"일반",
		"오디오",
		"그래픽",
        "조작법"
	]

	for i in range(tabs.size()):

		var rect = Rect2(
			panel.position.x + 25 + i * (panel.size.x - 50) / 4,
			panel.position.y + 85,
			(panel.size.x - 60) / 4,
			42
		)

		tab_rects.append(rect)

		var tab_color = Color("#354252")

		if settings_tab == i:
			tab_color = Color("#b77b28")

		draw_rect(rect, tab_color)

		draw_text_center(
			tabs[i],
			rect.get_center(),
			17,
			Color.WHITE
		)

	# 탭별 화면
	match settings_tab:

		0:
			draw_general_settings(screen)

		1:
			draw_audio_settings(panel)

		2:
			draw_graphics_settings(screen)

		3:
			draw_controls_settings(screen)

	# 하단 버튼
	back_rect = Rect2(
		screen.x * 0.32,
		panel.end.y - 65,
		screen.x * 0.16,
		48
	)

	apply_rect = Rect2(
		screen.x * 0.52,
		panel.end.y - 65,
		screen.x * 0.16,
		48
	)

	draw_rect(back_rect, Color("#354252"))
	draw_rect(apply_rect, Color("#a86f25"))

	draw_text_center(
		"뒤로",
		back_rect.get_center(),
		19,
		Color.WHITE
	)

	draw_text_center(
		"적용",
		apply_rect.get_center(),
		19,
		Color.WHITE
	)


# ==========================================
# GENERAL SETTINGS
# ==========================================

func draw_general_settings(screen):

	draw_text_center(
		"언어 : 한국어",
		Vector2(screen.x * 0.5, screen.y * 0.46),
		20,
		Color.WHITE
	)

	draw_text_center(
		"자동 저장 : 활성화",
		Vector2(screen.x * 0.5, screen.y * 0.55),
		20,
		Color.WHITE
	)


# ==========================================
# AUDIO SETTINGS
# ==========================================

func draw_audio_settings(panel):

	var labels = [
		"전체 음량",
		"배경음악",
        "효과음"
	]

	var values = [
		master_volume,
		music_volume,
		sfx_volume
	]

	for i in range(3):

		var y = panel.position.y + 190 + i * 85

		draw_string(
			get_ui_font(),
			Vector2(panel.position.x + 45, y + 8),
			labels[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			19,
			Color.WHITE
		)

		var bar = Rect2(
			panel.position.x + 180,
			y - 5,
			panel.size.x - 300,
			12
		)

		draw_rect(
			bar,
			Color("#465365")
		)

		draw_rect(
			Rect2(
				bar.position,
				Vector2(bar.size.x * values[i], 12)
			),
			Color("#e9a332")
		)

		draw_circle(
			Vector2(
				bar.position.x + bar.size.x * values[i],
				y + 1
			),
			10,
			Color.WHITE
		)

		slider_rects.append(
			Rect2(
				bar.position.x - 10,
				y - 18,
				bar.size.x + 20,
				42
			)
		)

		draw_string(
			get_ui_font(),
			Vector2(bar.end.x + 20, y + 8),
			str(roundi(values[i] * 100)) + "%",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			Color.WHITE
		)


# ==========================================
# GRAPHICS SETTINGS
# ==========================================

func draw_graphics_settings(screen):

	draw_text_center(
		"화면 해상도 : 현재 해상도 사용",
		Vector2(screen.x * 0.5, screen.y * 0.46),
		19,
		Color.WHITE
	)

	draw_text_center(
		"전체 화면 설정은 다음 단계에서 연결",
		Vector2(screen.x * 0.5, screen.y * 0.55),
		17,
		Color("#bdc7d1")
	)


# ==========================================
# CONTROLS SETTINGS
# ==========================================

func draw_controls_settings(screen):

	draw_text_center(
		"캐릭터 이동 : W A S D",
		Vector2(screen.x * 0.5, screen.y * 0.44),
		19,
		Color.WHITE
	)

	draw_text_center(
		"건설 : 마우스 왼쪽 클릭",
		Vector2(screen.x * 0.5, screen.y * 0.52),
		19,
		Color.WHITE
	)

	draw_text_center(
		"화면 이동 및 확대 : 마우스",
		Vector2(screen.x * 0.5, screen.y * 0.60),
		19,
		Color.WHITE
	)


# ==========================================
# CREDITS
# ==========================================

func draw_credits(screen):

	draw_overlay(screen)

	draw_text_center(
		"NOVA INDUSTRIA",
		Vector2(screen.x * 0.5, screen.y * 0.35),
		42,
		Color("#f4a52d")
	)

	draw_text_center(
		"GAME DEVELOPMENT",
		Vector2(screen.x * 0.5, screen.y * 0.46),
		22,
		Color.WHITE
	)

	draw_text_center(
		"뒤로",
		Vector2(screen.x * 0.5, screen.y * 0.7),
		22,
		Color.WHITE
	)


# ==========================================
# EXIT CONFIRMATION
# ==========================================

func draw_exit_confirmation(screen):

	draw_overlay(screen)

	var panel = Rect2(
		screen.x * 0.3,
		screen.y * 0.36,
		screen.x * 0.4,
		screen.y * 0.28
	)

	draw_rect(panel, Color("#202b3b"))
	draw_rect(panel, Color("#8996a5"), false, 2.0)

	draw_text_center(
		"게임을 종료하시겠습니까?",
		Vector2(screen.x * 0.5, screen.y * 0.43),
		22,
		Color.WHITE
	)

	confirm_yes_rect = Rect2(
		screen.x * 0.36,
		screen.y * 0.51,
		screen.x * 0.1,
		42
	)

	confirm_no_rect = Rect2(
		screen.x * 0.54,
		screen.y * 0.51,
		screen.x * 0.1,
		42
	)

	draw_rect(confirm_yes_rect, Color("#a86f25"))
	draw_rect(confirm_no_rect, Color("#354252"))

	draw_text_center(
		"종료",
		confirm_yes_rect.get_center(),
		18,
		Color.WHITE
	)

	draw_text_center(
		"취소",
		confirm_no_rect.get_center(),
		18,
		Color.WHITE
	)


# ==========================================
# INPUT
# ==========================================

func _gui_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:

				handle_click(event.position)

			else:

				dragging_slider = -1

	if event is InputEventMouseMotion:

		if dragging_slider >= 0:
			change_slider(event.position)


func handle_click(pos):

	var screen = get_rect().size

	# 종료 확인창
	if confirm_exit:

		if confirm_yes_rect.has_point(pos):
			get_tree().quit()

		elif confirm_no_rect.has_point(pos):
			confirm_exit = false
			queue_redraw()

		return

	# 제작진
	if credits_open:
		credits_open = false
		queue_redraw()
		return

	# 환경설정
	if settings_open:
		handle_settings_click(pos)
		return

	# 메인 메뉴
	for i in range(button_rects.size()):

		if button_rects[i].has_point(pos):

			handle_menu_button(i)
			return


func handle_menu_button(index):

	match index:

		0:
			# 새 게임
			if ResourceLoader.exists(game_scene_path):

				get_tree().change_scene_to_file(
					game_scene_path
				)

			else:

				show_message("게임 씬 경로를 확인해 주세요.")

		1:
			# 불러오기
			show_message("저장 시스템은 다음 단계에서 연결합니다.")

		2:
			settings_open = true

		3:
			credits_open = true

		4:
			confirm_exit = true

	queue_redraw()


# ==========================================
# SETTINGS INPUT
# ==========================================

func handle_settings_click(pos):

	for i in range(tab_rects.size()):

		if tab_rects[i].has_point(pos):

			settings_tab = i
			queue_redraw()
			return

	if settings_tab == 1:

		for i in range(slider_rects.size()):

			if slider_rects[i].has_point(pos):

				dragging_slider = i
				change_slider(pos)
				return

	if back_rect.has_point(pos):

		settings_open = false
		save_settings()

	elif apply_rect.has_point(pos):

		save_settings()
		update_audio()

		show_message("설정이 저장되었습니다.")

	queue_redraw()


# ==========================================
# AUDIO SLIDER
# ==========================================

func change_slider(pos):

	if dragging_slider < 0:
		return

	if dragging_slider >= slider_rects.size():
		return

	var rect = slider_rects[dragging_slider]

	var value = clampf(
		(pos.x - rect.position.x) / rect.size.x,
		0.0,
		1.0
	)

	match dragging_slider:

		0:
			master_volume = value

		1:
			music_volume = value

		2:
			sfx_volume = value

	update_audio()
	queue_redraw()


# ==========================================
# AUDIO SERVER
# ==========================================

func update_audio():

	set_bus_volume("Master", master_volume)
	set_bus_volume("Music", music_volume)
	set_bus_volume("SFX", sfx_volume)


func set_bus_volume(bus_name: String, value: float):

	var index = AudioServer.get_bus_index(bus_name)

	if index >= 0:

		AudioServer.set_bus_mute(
			index,
			value <= 0.001
		)

		AudioServer.set_bus_volume_linear(
			index,
			maxf(value, 0.001)
		)


# ==========================================
# SAVE SETTINGS
# ==========================================

func save_settings():

	var config = ConfigFile.new()

	config.set_value(
		"audio",
		"master",
		master_volume
	)

	config.set_value(
		"audio",
		"music",
		music_volume
	)

	config.set_value(
		"audio",
		"sfx",
		sfx_volume
	)

	config.set_value(
		"general",
		"settings_tab",
		settings_tab
	)

	config.save(SETTINGS_PATH)


func load_settings():

	var config = ConfigFile.new()

	if config.load(SETTINGS_PATH) == OK:

		master_volume = config.get_value(
			"audio",
			"master",
			1.0
		)

		music_volume = config.get_value(
			"audio",
			"music",
			0.7
		)

		sfx_volume = config.get_value(
			"audio",
			"sfx",
			0.8
		)

		settings_tab = config.get_value(
			"general",
			"settings_tab",
			1
		)


# ==========================================
# UTILITY
# ==========================================

func get_ui_font() -> Font:

	if ui_font != null:
		return ui_font

	return ThemeDB.fallback_font


func draw_text_center(
	text: String,
	center: Vector2,
	size: int,
	color: Color
):

	var font = get_ui_font()

	var text_width = font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size
	).x

	draw_string(
		font,
		Vector2(
			center.x - text_width / 2.0,
			center.y + size * 0.35
		),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		color
	)


func draw_overlay(screen):

	draw_rect(
		Rect2(Vector2.ZERO, screen),
		Color(0, 0, 0, 0.75)
	)


func show_message(text: String):

	message = text
	message_timer = 3.0

	queue_redraw()


func draw_message(screen):

	var rect = Rect2(
		screen.x * 0.3,
		screen.y * 0.84,
		screen.x * 0.4,
		45
	)

	draw_rect(
		rect,
		Color("#202b3b")
	)

	draw_text_center(
		message,
		rect.get_center(),
		15,
		Color.WHITE
	)
