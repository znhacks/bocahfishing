extends Control

# Reeling Minigame HUD (Horizontal Bottom Bar style)
signal reeling_finished(success: bool, fish_data: Dictionary)
signal reeling_tick(progress_ratio: float, is_inside: bool, is_active: bool)

@onready var track: Control = $Panel/Margin/VBox/Track
@onready var catch_bar: Panel = $Panel/Margin/VBox/Track/CatchBar
@onready var fish_icon: Label = $Panel/Margin/VBox/Track/FishIcon
@onready var fish_texture: TextureRect = $Panel/Margin/VBox/Track/FishTexture
@onready var progress_bar: ProgressBar = $Panel/Margin/VBox/TopRow/ProgressBar
@onready var lbl_tier: Label = $Panel/Margin/VBox/TopRow/LblTier
@onready var status_badge: PanelContainer = $Panel/Margin/VBox/TopRow/StatusBadge
@onready var lbl_status: Label = $Panel/Margin/VBox/TopRow/StatusBadge/LblStatus

var current_fish: Dictionary = {}
var is_active: bool = false

# Horizontal Physics & Tracking
const TRACK_WIDTH: float = 460.0
var catch_bar_width: float = 125.0
var catch_bar_x: float = 160.0
var catch_velocity: float = 0.0

const GRAVITY: float = 1100.0  # Leftward return force
const THRUST: float = 1900.0   # Rightward push force
const MAX_VELOCITY: float = 450.0

# Fish AI
var fish_x: float = 230.0
var fish_target_x: float = 230.0
var fish_speed: float = 110.0
var fish_timer: float = 0.0
var fish_change_interval: float = 1.4

# Progress
var progress: float = 35.0
const FILL_RATE: float = 16.0
const DRAIN_RATE: float = 9.0

func start_reeling(fish_data: Dictionary) -> void:
	current_fish = fish_data
	var tier = fish_data.get("tier", 1)
	
	# Configure balanced difficulty based on tier
	match tier:
		1:
			catch_bar_width = 160.0
			fish_speed = 70.0
			fish_change_interval = 2.2
		2:
			catch_bar_width = 135.0
			fish_speed = 100.0
			fish_change_interval = 1.8
		3:
			catch_bar_width = 115.0
			fish_speed = 135.0
			fish_change_interval = 1.4
		4:
			catch_bar_width = 100.0
			fish_speed = 175.0
			fish_change_interval = 1.1
		5:
			catch_bar_width = 85.0
			fish_speed = 220.0
			fish_change_interval = 0.85
			
	# Apply character bar_scale modifier
	var mods = GameManager.get_character_modifiers() if GameManager else {}
	catch_bar_width *= mods.get("bar_scale", 1.0)
	
	catch_bar.size.x = catch_bar_width
	catch_bar_x = (TRACK_WIDTH - catch_bar_width) * 0.5
	catch_velocity = 0.0
	
	fish_x = TRACK_WIDTH * 0.5
	fish_target_x = fish_x
	fish_timer = 0.0
	
	progress = 35.0
	progress_bar.value = progress
	
	# Display tier name & color
	var tier_name = GameManager.TIER_NAMES.get(tier, "Fish")
	var tier_color = GameManager.TIER_COLORS.get(tier, Color.WHITE)
	lbl_tier.text = "[ %s ]" % tier_name.to_upper()
	lbl_tier.modulate = tier_color
	
	# Hide specific fish illustration to keep the fish a mystery during the fight
	fish_texture.visible = false
	fish_icon.visible = true
	fish_icon.text = "🐟"
	fish_icon.scale = Vector2.ONE
	fish_icon.modulate = Color.WHITE
	
	visible = true
	is_active = true
	set_process(true)
	
	# Pop in
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	# 1. Player Input: Holding pushes RIGHT, releasing slides LEFT
	var is_holding: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
	if is_holding:
		catch_velocity += THRUST * delta
		if catch_velocity < 0.0:
			catch_velocity *= 0.82
	else:
		catch_velocity -= GRAVITY * delta
		if catch_velocity > 0.0:
			catch_velocity *= 0.88
		
	catch_velocity = clamp(catch_velocity, -MAX_VELOCITY, MAX_VELOCITY)
	catch_bar_x += catch_velocity * delta
	
	# Clamp catch bar within track
	var max_bar_x = TRACK_WIDTH - catch_bar_width
	if catch_bar_x < 0:
		catch_bar_x = 0
		catch_velocity = -catch_velocity * 0.2
	elif catch_bar_x > max_bar_x:
		catch_bar_x = max_bar_x
		catch_velocity = -catch_velocity * 0.2
		
	catch_bar.position.x = catch_bar_x
	
	# 2. Fish AI Movement
	fish_timer -= delta
	if fish_timer <= 0:
		fish_timer = randf_range(fish_change_interval * 0.6, fish_change_interval * 1.4)
		fish_target_x = randf_range(16.0, TRACK_WIDTH - 36.0)
		
	var mods = GameManager.get_character_modifiers() if GameManager else {}
	var resilience: float = mods.get("resilience", 1.0)
	
	# High resilience stabilizes erratic thrashing
	var speed_mult: float = 1.0
	if resilience > 1.0:
		speed_mult = 1.0 - (resilience - 1.0) * 0.35
		
	var prev_x = fish_x
	fish_x = move_toward(fish_x, fish_target_x, fish_speed * speed_mult * delta)
	
	var active_fish: Control = fish_icon
	if fish_texture.visible:
		active_fish = fish_texture
	active_fish.position.x = fish_x
	
	# Flip fish sprite based on swim direction
	if fish_x > prev_x:
		active_fish.scale.x = -1.0  # Face right
	elif fish_x < prev_x:
		active_fish.scale.x = 1.0   # Face left
	
	# 3. Collision check: Is fish inside Catch Bar?
	var fish_center = fish_x + 12.0
	var is_inside: bool = (fish_center >= catch_bar_x and fish_center <= catch_bar_x + catch_bar_width)
	
	if is_inside:
		progress += FILL_RATE * delta
		catch_bar.modulate = Color(0.4, 1.0, 0.5, 1.0)
		lbl_status.text = "▲ REEL +%d%%" % int(FILL_RATE)
		lbl_status.modulate = Color(0.35, 1.0, 0.65)
	else:
		# Resilience scales escape drain significantly
		var effective_drain: float
		if resilience >= 1.0:
			effective_drain = DRAIN_RATE / (1.0 + (resilience - 1.0) * 2.0)
		else:
			effective_drain = DRAIN_RATE * (1.0 + (1.0 - resilience) * 2.0)
			
		progress -= effective_drain * delta
		catch_bar.modulate = Color(1.0, 0.45, 0.35, 0.85)
		
		if resilience >= 1.15:
			lbl_status.text = "▼ ESC -%d%% [🛡️ Resilient]" % int(effective_drain)
			lbl_status.modulate = Color(1.0, 0.7, 0.4)
		elif resilience <= 0.85:
			lbl_status.text = "▼ ESC -%d%% [⚠️ Fragile]" % int(effective_drain)
			lbl_status.modulate = Color(1.0, 0.25, 0.25)
		else:
			lbl_status.text = "▼ ESC -%d%%" % int(effective_drain)
			lbl_status.modulate = Color(1.0, 0.45, 0.4)
		
	progress = clamp(progress, 0.0, 100.0)
	progress_bar.value = progress
	reeling_tick.emit(progress / 100.0, is_inside, is_active)
	
	# 4. Victory / Loss condition
	if progress >= 100.0:
		_end_reeling(true)
	elif progress <= 0.0:
		_end_reeling(false)

func _end_reeling(success: bool) -> void:
	is_active = false
	set_process(false)
	reeling_tick.emit(progress / 100.0, false, false)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	reeling_finished.emit(success, current_fish)
