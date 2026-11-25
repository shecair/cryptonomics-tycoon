extends Control


# ==========================================
# Node References
# ==========================================

@onready var logo: TextureRect = $Logo

@onready var cloud_large: TextureRect = $Clouds/CloudLarge
@onready var cloud_medium: TextureRect = $Clouds/CloudMedium
@onready var cloud_small: TextureRect = $Clouds/CloudSmall

@onready var globe_group: Control = $GlobeGroup
@onready var globe: TextureRect = $GlobeGroup/Globe
@onready var bitcoin: TextureRect = $GlobeGroup/Bitcoin

@onready var progress_clip: Control = $ProgressBar/FillClip
@onready var progress_fill: TextureRect = $ProgressBar/FillClip/Fill

@onready var status_label: Label = $StatusLabel


# ==========================================
# Loading Settings
# ==========================================

const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"

const PROGRESS_MAX_WIDTH: float = 840.0
const PROGRESS_HEIGHT: float = 120.0

const PROGRESS_OFFSET_X: float = 30.0
const PROGRESS_OFFSET_Y: float = 22.0

const PROGRESS_CORNER_RADIUS: float = 51.0
const PROGRESS_EDGE_SOFTNESS: float = 1.5

const MIN_LOADING_DURATION: float = 3.0
const COMPLETE_DELAY: float = 0.5
const FADE_DURATION: float = 0.5

const LOADING_TEXT: String = "Loading..."
const COMPLETED_TEXT: String = "Loading Complete!"

var loading_progress: float = 0.0
var loading_elapsed: float = 0.0

var loading_finished: bool = false
var loading_failed: bool = false
var loading_started: bool = false

var actual_progress: float = 0.0
var resources_loaded: bool = false

var loaded_scene: PackedScene
var progress_material: ShaderMaterial

var fade_overlay: ColorRect


# ==========================================
# Geometric Orbit Settings
# ==========================================

const ORBIT_CENTER: Vector2 = Vector2(400.0, 400.0)

const INNER_RADIUS: Vector2 = Vector2(360.0, 115.0)
const OUTER_RADIUS: Vector2 = Vector2(390.0, 125.0)

const ORBIT_MAX_ANGLE: float = 30.0
const ORBIT_TILT_DURATION: float = 8.0
const ORBIT_REVOLUTION_DURATION: float = 12.0

const ORBIT_SEGMENTS: int = 96
const PARTICLES_PER_RING: int = 4

var orbit_elapsed: float = 0.0
var orbit_angle: float = 0.0
var orbit_phase: float = 0.0

var back_layer: Node2D
var front_layer: Node2D


# ==========================================
# Initialization
# ==========================================

func _ready() -> void:

	print("Loading Screen Started")

	setup_loading_text()

	animate_logo()
	animate_clouds()
	animate_globe()

	setup_geometric_orbits()

	animate_bitcoin()

	setup_progress_bar()
	setup_fade_overlay()

	start_real_loading()


func _process(delta: float) -> void:

	animate_geometric_orbits(delta)

	if loading_finished or loading_failed:
		return

	if loading_started:
		process_real_loading(delta)


# ==========================================
# 01 - Logo Animation
# ==========================================

func animate_logo() -> void:

	logo.pivot_offset = logo.size / 2.0
	logo.scale = Vector2(0.65, 0.65)
	logo.modulate.a = 0.0

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		logo, "modulate:a", 1.0, 0.6
	)

	tween.tween_property(
		logo, "scale", Vector2(1.08, 1.08), 0.8
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_OUT
	)

	tween.chain().tween_property(
		logo, "scale", Vector2.ONE, 0.4
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


# ==========================================
# 02 - Clouds Animation
# ==========================================

func animate_clouds() -> void:

	animate_cloud(cloud_large, 60.0, 6.0)
	animate_cloud(cloud_medium, -50.0, 8.0)
	animate_cloud(cloud_small, 40.0, 5.0)


func animate_cloud(
	cloud: TextureRect,
	distance: float,
	duration: float
) -> void:

	var start_x: float = cloud.position.x

	var tween = create_tween()

	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cloud, "position:x",
		start_x + distance, duration
	)

	tween.tween_property(
		cloud, "position:x",
		start_x, duration
	)


# ==========================================
# 03 - Globe Floating Animation
# ==========================================

func animate_globe() -> void:

	var start_y: float = globe_group.position.y

	var tween = create_tween()

	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		globe_group, "position:y",
		start_y - 25.0, 2.5
	)

	tween.tween_property(
		globe_group, "position:y",
		start_y, 2.5
	)


# ==========================================
# 04 - Create Geometric Orbit Layers
# ==========================================

func setup_geometric_orbits() -> void:

	globe.z_index = 1
	bitcoin.z_index = 3

	back_layer = Node2D.new()
	back_layer.name = "GeometricOrbitBack"
	back_layer.z_index = 0

	globe_group.add_child(back_layer)

	back_layer.draw.connect(
		draw_orbit_layer.bind(back_layer, false)
	)

	front_layer = Node2D.new()
	front_layer.name = "GeometricOrbitFront"
	front_layer.z_index = 2

	globe_group.add_child(front_layer)

	front_layer.draw.connect(
		draw_orbit_layer.bind(front_layer, true)
	)

	back_layer.queue_redraw()
	front_layer.queue_redraw()


# ==========================================
# 05 - Shared Orbit Geometry
# ==========================================

func get_orbit_point(
	radius: Vector2,
	phase: float
) -> Vector2:

	var point = Vector2(
		cos(phase) * radius.x,
		sin(phase) * radius.y
	)

	point = point.rotated(orbit_angle)

	return ORBIT_CENTER + point


# ==========================================
# 06 - Draw Orbit Layers
# ==========================================

func draw_orbit_layer(
	layer: Node2D,
	is_front: bool
) -> void:

	draw_single_orbit(
		layer,
		INNER_RADIUS,
		is_front,
		7.0
	)

	draw_single_orbit(
		layer,
		OUTER_RADIUS,
		is_front,
		5.0
	)

	draw_orbit_particles(
		layer,
		INNER_RADIUS,
		is_front,
		0.0
	)

	draw_orbit_particles(
		layer,
		OUTER_RADIUS,
		is_front,
		PI / 4.0
	)


# ==========================================
# 07 - Draw Golden Elliptical Rings
# ==========================================

func draw_single_orbit(
	layer: Node2D,
	radius: Vector2,
	is_front: bool,
	line_width: float
) -> void:

	var points = PackedVector2Array()

	var start_angle: float
	var end_angle: float

	if is_front:

		start_angle = 0.0
		end_angle = PI

	else:

		start_angle = PI
		end_angle = TAU

	for i in range(ORBIT_SEGMENTS + 1):

		var ratio: float = (
			float(i) / float(ORBIT_SEGMENTS)
		)

		var phase: float = lerpf(
			start_angle,
			end_angle,
			ratio
		)

		points.append(
			get_orbit_point(radius, phase)
		)

	layer.draw_polyline(
		points,
		Color(1.0, 0.65, 0.05, 0.10),
		line_width + 18.0,
		true
	)

	layer.draw_polyline(
		points,
		Color(1.0, 0.75, 0.10, 0.25),
		line_width + 9.0,
		true
	)

	layer.draw_polyline(
		points,
		Color(0.90, 0.48, 0.03, 1.0),
		line_width + 3.0,
		true
	)

	layer.draw_polyline(
		points,
		Color(1.0, 0.81, 0.15, 1.0),
		line_width,
		true
	)

	layer.draw_polyline(
		points,
		Color(1.0, 0.96, 0.65, 1.0),
		2.0,
		true
	)


# ==========================================
# 08 - Draw Moving Golden Particles
# ==========================================

func draw_orbit_particles(
	layer: Node2D,
	radius: Vector2,
	is_front: bool,
	phase_offset: float
) -> void:

	for i in range(PARTICLES_PER_RING):

		var phase: float = orbit_phase + phase_offset

		phase += (
			float(i) / float(PARTICLES_PER_RING)
		) * TAU

		var particle_is_front: bool = sin(phase) >= 0.0

		if particle_is_front != is_front:
			continue

		var point: Vector2 = get_orbit_point(
			radius,
			phase
		)

		layer.draw_circle(
			point,
			15.0,
			Color(1.0, 0.70, 0.05, 0.10),
			true,
			-1.0,
			true
		)

		layer.draw_circle(
			point,
			10.0,
			Color(1.0, 0.80, 0.10, 0.30),
			true,
			-1.0,
			true
		)

		layer.draw_circle(
			point,
			6.0,
			Color(1.0, 0.80, 0.10, 1.0),
			true,
			-1.0,
			true
		)

		layer.draw_circle(
			point,
			3.0,
			Color(1.0, 0.99, 0.80, 1.0),
			true,
			-1.0,
			true
		)


# ==========================================
# 09 - Orbit Animation
# ==========================================

func animate_geometric_orbits(delta: float) -> void:

	orbit_elapsed += delta

	var tilt_phase: float = (
		orbit_elapsed / ORBIT_TILT_DURATION
	) * TAU

	orbit_angle = deg_to_rad(
		sin(tilt_phase) * ORBIT_MAX_ANGLE
	)

	orbit_phase = (
		orbit_elapsed / ORBIT_REVOLUTION_DURATION
	) * TAU

	back_layer.queue_redraw()
	front_layer.queue_redraw()


# ==========================================
# 10 - Bitcoin Pulse Animation
# ==========================================

func animate_bitcoin() -> void:

	bitcoin.pivot_offset = bitcoin.size / 2.0

	var start_scale: Vector2 = bitcoin.scale

	var tween = create_tween()

	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		bitcoin, "scale",
		start_scale * 1.10, 1.2
	)

	tween.tween_property(
		bitcoin, "scale",
		start_scale, 1.2
	)


# ==========================================
# 11 - Progress Bar Setup
# ==========================================

func setup_progress_bar() -> void:

	progress_clip.clip_contents = false

	progress_clip.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	progress_clip.position = Vector2(
		PROGRESS_OFFSET_X,
		PROGRESS_OFFSET_Y
	)

	progress_clip.custom_minimum_size = Vector2.ZERO

	progress_clip.size = Vector2(
		PROGRESS_MAX_WIDTH,
		PROGRESS_HEIGHT
	)

	progress_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	progress_clip.show()

	progress_fill.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	progress_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	progress_fill.stretch_mode = TextureRect.STRETCH_SCALE

	progress_fill.custom_minimum_size = Vector2.ZERO

	progress_fill.position = Vector2.ZERO

	progress_fill.size = Vector2(
		PROGRESS_MAX_WIDTH,
		PROGRESS_HEIGHT
	)

	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var source_material := progress_fill.material as ShaderMaterial

	if source_material == null:
		push_error("Progress ShaderMaterial not found.")
		progress_fill.hide()
		return

	if source_material.shader == null:
		push_error("Progress Shader not found.")
		progress_fill.hide()
		return

	progress_material = source_material.duplicate() as ShaderMaterial

	progress_fill.material = progress_material

	progress_material.set_shader_parameter(
		"bar_size",
		Vector2(
			PROGRESS_MAX_WIDTH,
			PROGRESS_HEIGHT
		)
	)

	progress_material.set_shader_parameter(
		"corner_radius",
		PROGRESS_CORNER_RADIUS
	)

	progress_material.set_shader_parameter(
		"edge_softness",
		PROGRESS_EDGE_SOFTNESS
	)

	progress_fill.show()

	update_progress(0.0)


# ==========================================
# 12 - Update Progress Bar
# ==========================================

func update_progress(value: float) -> void:

	loading_progress = clampf(
		value,
		0.0,
		100.0
	)

	var normalized_progress: float = (
		loading_progress / 100.0
	)

	if progress_material != null:

		progress_material.set_shader_parameter(
			"progress",
			normalized_progress
		)

	update_loading_text(normalized_progress)


# ==========================================
# 13 - Loading Text Setup
# ==========================================

func setup_loading_text() -> void:

	status_label.text = LOADING_TEXT

	status_label.text_direction = Control.TEXT_DIRECTION_LTR

	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	status_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

	status_label.visible_characters = 1


# ==========================================
# 14 - Loading Text Animation
# ==========================================

func update_loading_text(progress: float) -> void:

	if loading_finished:
		return

	var total_characters: int = LOADING_TEXT.length()

	var visible_count: int = clampi(
		floori(progress * total_characters) + 1,
		1,
		total_characters
	)

	status_label.visible_characters = visible_count


# ==========================================
# 15 - Fade Overlay Setup
# ==========================================

func setup_fade_overlay() -> void:

	fade_overlay = ColorRect.new()

	fade_overlay.name = "FadeOverlay"

	fade_overlay.color = Color.BLACK

	fade_overlay.modulate.a = 0.0

	fade_overlay.z_index = 100

	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fade_overlay)

	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


# ==========================================
# 16 - Start Real Resource Loading
# ==========================================

func start_real_loading() -> void:

	if not ResourceLoader.exists(MAIN_MENU_PATH):

		show_loading_error(
            "Main Menu scene not found."
		)

		return

	var error: Error = ResourceLoader.load_threaded_request(
		MAIN_MENU_PATH,
        "PackedScene"
	)

	if error != OK:

		show_loading_error(
            "Unable to start resource loading."
		)

		return

	loading_started = true

	print("Real resource loading started.")


# ==========================================
# 17 - Process Real Resource Loading
# ==========================================

func process_real_loading(delta: float) -> void:

	loading_elapsed += delta

	if not resources_loaded:

		var progress: Array = []

		var status = ResourceLoader.load_threaded_get_status(
			MAIN_MENU_PATH,
			progress
		)

		match status:

			ResourceLoader.THREAD_LOAD_IN_PROGRESS:

				if not progress.is_empty():

					actual_progress = maxf(
						actual_progress,
						clampf(float(progress[0]), 0.0, 1.0)
					)

			ResourceLoader.THREAD_LOAD_LOADED:

				loaded_scene = ResourceLoader.load_threaded_get(
					MAIN_MENU_PATH
				) as PackedScene

				if loaded_scene == null:

					show_loading_error(
                        "Invalid Main Menu scene."
					)

					return

				resources_loaded = true

				actual_progress = 1.0

			ResourceLoader.THREAD_LOAD_FAILED:

				show_loading_error(
                    "Resource loading failed."
				)

				return

			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:

				show_loading_error(
                    "Invalid resource path."
				)

				return

	var time_progress: float = clampf(
		loading_elapsed / MIN_LOADING_DURATION,
		0.0,
		1.0
	)

	var target_progress: float = minf(
		actual_progress,
		time_progress
	) * 100.0

	if not resources_loaded:

		target_progress = minf(
			target_progress,
			99.0
		)

	var smooth_progress: float = move_toward(
		loading_progress,
		target_progress,
		delta * 100.0
	)

	update_progress(smooth_progress)

	if resources_loaded and loading_elapsed >= MIN_LOADING_DURATION:

		if loading_progress >= 99.99:

			on_loading_completed()


# ==========================================
# 18 - Loading Completed
# ==========================================

func on_loading_completed() -> void:

	if loading_finished:
		return

	loading_finished = true

	update_progress(100.0)

	status_label.text = COMPLETED_TEXT

	status_label.visible_characters = -1

	print("Loading Completed: 100%")

	await get_tree().create_timer(
		COMPLETE_DELAY
	).timeout

	transition_to_main_menu()


# ==========================================
# 19 - Transition to Main Menu
# ==========================================

func transition_to_main_menu() -> void:

	var tween = create_tween()

	tween.tween_property(
		fade_overlay,
		"modulate:a",
		1.0,
		FADE_DURATION
	)

	await tween.finished

	print("Opening Main Menu...")

	var error: Error = get_tree().change_scene_to_packed(
		loaded_scene
	)

	if error != OK:

		fade_overlay.modulate.a = 0.0

		show_loading_error(
            "Unable to open Main Menu."
		)


# ==========================================
# 20 - Loading Error Management
# ==========================================

func show_loading_error(message: String) -> void:

	loading_failed = true

	loading_started = false

	status_label.text = "Loading Error!"

	status_label.visible_characters = -1

	push_error(message)
