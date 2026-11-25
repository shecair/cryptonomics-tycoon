
extends Control

# ==========================================
# Node References
# ==========================================

@onready var background: TextureRect = $Background
@onready var menu_panel: Control = $MenuPanel
@onready var crown: TextureRect = $MenuPanel/Crown
@onready var buttons: VBoxContainer = $MenuPanel/Buttons

@onready var start_button: TextureButton = $MenuPanel/Buttons/StartButton
@onready var continue_button: TextureButton = $MenuPanel/Buttons/ContinueButton
@onready var settings_button: TextureButton = $MenuPanel/Buttons/SettingsButton
@onready var about_button: TextureButton = $MenuPanel/Buttons/AboutButton
@onready var exit_button: TextureButton = $MenuPanel/Buttons/ExitButton


# ==========================================
# Intro Animation Settings
# ==========================================

const BACKGROUND_DURATION: float = 0.3
const PANEL_DURATION: float = 0.4
const CROWN_DURATION: float = 0.4
const BUTTON_DURATION: float = 0.25
const BUTTON_DELAY: float = 0.1


# ==========================================
# Button Interaction Settings
# ==========================================

const BUTTON_PRESSED_SCALE: float = 0.95
const BUTTON_PRESS_DURATION: float = 0.08
const BUTTON_RELEASE_DURATION: float = 0.15


# ==========================================
# Variables
# ==========================================

var menu_buttons: Array[TextureButton] = []
var original_disabled_states: Array[bool] = []

var button_tweens: Dictionary = {}

var crown_original_position: Vector2
var animation_finished: bool = false


# ==========================================
# Ready
# ==========================================

func _ready() -> void:

	menu_buttons = [
		start_button,
		continue_button,
		settings_button,
		about_button,
		exit_button
	]

	await get_tree().process_frame

	setup_initial_state()
	connect_button_animation_signals()

	await play_intro_animation()


# ==========================================
# Initial State
# ==========================================

func setup_initial_state() -> void:

	animation_finished = false

	# Background
	background.modulate.a = 0.0

	# Main Panel
	menu_panel.pivot_offset = menu_panel.size / 2.0
	menu_panel.scale = Vector2(0.75, 0.75)
	menu_panel.modulate.a = 0.0

	# Crown
	crown_original_position = crown.position
	crown.position.y -= 180.0
	crown.modulate.a = 0.0

	# Buttons
	original_disabled_states.clear()

	for button in menu_buttons:

		original_disabled_states.append(button.disabled)

		button.pivot_offset = button.size / 2.0
		button.modulate.a = 0.0
		button.scale = Vector2(0.8, 0.8)

		button.disabled = true


# ==========================================
# Intro Animation
# ==========================================

func play_intro_animation() -> void:

	await animate_background()
	await animate_menu_panel()
	await animate_crown()
	await animate_buttons()

	enable_menu_buttons()

	animation_finished = true

	print("Main Menu Animation Completed")


# ==========================================
# Background Animation
# ==========================================

func animate_background() -> void:

	var tween: Tween = create_tween()

	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		BACKGROUND_DURATION
	)

	await tween.finished


# ==========================================
# Panel Animation
# ==========================================

func animate_menu_panel() -> void:

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		menu_panel,
		"modulate:a",
		1.0,
		PANEL_DURATION
	)

	tween.tween_property(
		menu_panel,
		"scale",
		Vector2.ONE,
		PANEL_DURATION
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished


# ==========================================
# Crown Animation
# ==========================================

func animate_crown() -> void:

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		crown,
		"modulate:a",
		1.0,
		CROWN_DURATION
	)

	tween.tween_property(
		crown,
		"position",
		crown_original_position,
		CROWN_DURATION
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished


# ==========================================
# Buttons Intro Animation
# ==========================================

func animate_buttons() -> void:

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	for i in range(menu_buttons.size()):

		var button: TextureButton = menu_buttons[i]
		var delay: float = float(i) * BUTTON_DELAY

		button.disabled = original_disabled_states[i]
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		tween.tween_property(
			button,
			"modulate:a",
			1.0,
			BUTTON_DURATION
		).set_delay(delay)

		tween.tween_property(
			button,
			"scale",
			Vector2.ONE,
			BUTTON_DURATION
		).set_delay(delay).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)

	await tween.finished


# ==========================================
# Enable Buttons
# ==========================================

func enable_menu_buttons() -> void:

	for i in range(menu_buttons.size()):

		var button: TextureButton = menu_buttons[i]

		button.disabled = original_disabled_states[i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP


# ==========================================
# Connect Button Animation Signals
# ==========================================

func connect_button_animation_signals() -> void:

	for button in menu_buttons:

		button.button_down.connect(
			_on_button_down.bind(button)
		)

		button.button_up.connect(
			_on_button_up.bind(button)
		)

		button.mouse_exited.connect(
			_on_button_mouse_exited.bind(button)
		)


# ==========================================
# Button Pressed
# ==========================================

func _on_button_down(button: TextureButton) -> void:

	if not animation_finished:
		return

	if button.disabled:
		return

	animate_button_scale(
		button,
		Vector2(
			BUTTON_PRESSED_SCALE,
			BUTTON_PRESSED_SCALE
		),
		BUTTON_PRESS_DURATION,
		Tween.TRANS_QUAD
	)


# ==========================================
# Button Released
# ==========================================

func _on_button_up(button: TextureButton) -> void:

	if not animation_finished:
		return

	animate_button_scale(
		button,
		Vector2.ONE,
		BUTTON_RELEASE_DURATION,
		Tween.TRANS_BACK
	)


# ==========================================
# Mouse Exited
# ==========================================

func _on_button_mouse_exited(
	button: TextureButton
) -> void:

	if not animation_finished:
		return

	if button.disabled:
		return

	if button.is_pressed():
		return

	if button.scale.is_equal_approx(Vector2.ONE):
		return

	animate_button_scale(
		button,
		Vector2.ONE,
		BUTTON_RELEASE_DURATION,
		Tween.TRANS_BACK
	)


# ==========================================
# Shared Button Scale Animation
# ==========================================

func animate_button_scale(
	button: TextureButton,
	target_scale: Vector2,
	duration: float,
	transition: Tween.TransitionType
) -> void:

	# Stop previous animation
	if button_tweens.has(button):

		var old_tween: Tween = button_tweens[button]

		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	# Update pivot
	button.pivot_offset = button.size / 2.0

	# Create new animation
	var tween: Tween = create_tween()

	button_tweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		target_scale,
		duration
	).set_trans(
		transition
	).set_ease(
		Tween.EASE_OUT
	)
