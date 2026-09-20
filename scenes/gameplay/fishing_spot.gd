extends Control

# Fishing Gameplay Controller (Fisch-style Reeling & Alert)
# Micro Jam 065 - Everything is Bait!

enum FishingState {
	IDLE,
	CASTING,
	WAITING,
	BITING,
	REELING,
	RESULT,
	ESCAPED
}

var current_state: FishingState = FishingState.IDLE
var pending_fish: Dictionary = {}

# Node references
@onready var water_surface: Control = $WaterArea
@onready var fishing_line: Line2D = $FishingLine
@onready var bobber: Control = $Bobber
@onready var bobber_icon: Label = $Bobber/BobberIcon
@onready var alert_icon: Label = $Bobber/AlertIcon
@onready var ripple_ring: Panel = $Bobber/RippleRing
@onready var splash_particles: CPUParticles2D = $Bobber/SplashParticles
@onready var lbl_prompt: Label = $HUD/LblPrompt

@onready var reeling_hud: Control = $HUD/ReelingHUD
@onready var catch_dialog: Control = $HUD/CatchDialog
@onready var tackle_dialog: Control = $HUD/TackleBoxDialog

@onready var btn_back: Button = $HUD/TopBar/BtnBack
@onready var btn_tackle: Button = $HUD/TopBar/BtnTackle
@onready var lbl_bait_info: Label = $HUD/TopBar/BaitCard/HBoxBait/LblBaitInfo
@onready var tex_bait: TextureRect = $HUD/TopBar/BaitCard/HBoxBait/TexBait
@onready var lbl_cahs: Label = $HUD/TopBar/CahsCard/LblCahs
@onready var lbl_clock: Label = $HUD/TopBar/ClockCard/LblClock
@onready var water_texture: TextureRect = $BgLayer/WaterTexture
@onready var water_texture_fade: TextureRect = $BgLayer/WaterTextureFade
@onready var bg_texture: TextureRect = $BgLayer/BgTexture
@onready var bg_texture_fade: TextureRect = $BgLayer/BgTextureFade

var _bobber_origin_y: float = 0.0
var _anim_time: float = 0.0
var _cast_pos: Vector2 = Vector2(640.0, 520.0)
var _player_pos: Vector2 = Vector2(640.0, 660.0)
var _far_pos: Vector2 = Vector2(640.0, 400.0)
var _reeling_progress: float = 0.35
var _is_reeling_inside: bool = false
var _is_reeling_active: bool = false

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_tackle.pressed.connect(_on_tackle_pressed)
	water_surface.gui_input.connect(_on_water_clicked)
	
	reeling_hud.reeling_finished.connect(_on_reeling_finished)
	reeling_hud.reeling_tick.connect(_on_reeling_tick)
	catch_dialog.dialog_closed.connect(_on_catch_dialog_closed)
	
	if GameManager:
		GameManager.bait_changed.connect(func(_b): _update_bait_display())
		GameManager.inventory_updated.connect(_update_bait_display)
		GameManager.cahs_changed.connect(func(_c): _update_bait_display())
		GameManager.time_updated.connect(_on_time_updated)
		GameManager.period_changed.connect(_on_period_changed)
		
		if bg_texture:
			bg_texture.texture = GameManager.get_current_period_bg_texture()
		if water_texture:
			water_texture.texture = GameManager.get_current_period_water_texture()
		if lbl_clock:
			lbl_clock.text = GameManager.get_time_formatted()
		
	alert_icon.visible = false
	ripple_ring.visible = false
	bobber.visible = false
	if fishing_line:
		fishing_line.visible = false
	reeling_hud.visible = false
	catch_dialog.visible = false
	tackle_dialog.visible = false
	if splash_particles:
		splash_particles.emitting = false
	
	_update_bait_display()
	_set_state(FishingState.IDLE)

func _on_reeling_tick(progress_ratio: float, is_inside: bool, is_active: bool) -> void:
	_reeling_progress = progress_ratio
	_is_reeling_inside = is_inside
	_is_reeling_active = is_active

func _process(delta: float) -> void:
	_anim_time += delta
	
	# Gentle floating animation on bobber in water
	if bobber.visible and current_state == FishingState.WAITING:
		bobber.position.y = _bobber_origin_y + sin(_anim_time * 4.0) * 4.0
		bobber.rotation = sin(_anim_time * 2.0) * 0.05
		
	elif current_state == FishingState.BITING:
		# Exclamation mark jumping pulse and quick bobber dip
		alert_icon.position.y = -55.0 + sin(_anim_time * 18.0) * 6.0
		bobber.position.y = _bobber_origin_y + 8.0 + sin(_anim_time * 14.0) * 3.0
		bobber.rotation = sin(_anim_time * 16.0) * 0.12
		
	elif current_state == FishingState.REELING and _is_reeling_active and bobber.visible:
		# Dynamic bobber minigame behavior:
		# 1. Pulling (inside bar) -> bobber approaches player (bottom center) & wobbles
		# 2. Miss (outside bar) -> fish pulls away deeper into water & thrashes erratically
		# 3. Water splashes reflect current action
		
		if _is_reeling_inside:
			# Player successfully reels! Bobber smoothly glides towards player (bottom center)
			var target_base = _cast_pos.lerp(_player_pos, _reeling_progress)
			
			# Gentle rhythmic wobble as line is reeled in
			var wobble_x = sin(_anim_time * 8.0) * 3.5
			var wobble_y = cos(_anim_time * 7.0) * 1.5
			var wobble_rot = sin(_anim_time * 7.0) * 0.08
			
			bobber.position = bobber.position.lerp(target_base + Vector2(wobble_x, wobble_y), delta * 1.8)
			bobber.rotation = lerp_angle(bobber.rotation, wobble_rot, delta * 4.0)
			
			if splash_particles:
				splash_particles.emitting = true
				splash_particles.amount = 8
				splash_particles.initial_velocity_min = 35.0
				splash_particles.initial_velocity_max = 75.0
		else:
			# Player misses / fish pulls back! Bobber smoothly drifts away into deeper water
			var miss_factor = clamp(1.0 - _reeling_progress, 0.0, 1.0)
			var target_base = _cast_pos.lerp(_far_pos, miss_factor)
			
			# Gentle struggle motion as fish pulls away
			var thrash_x = sin(_anim_time * 11.0) * 5.0 + sin(_anim_time * 5.0) * 2.5
			var thrash_y = cos(_anim_time * 9.0) * 2.5
			var thrash_rot = sin(_anim_time * 9.0) * 0.12
			
			bobber.position = bobber.position.lerp(target_base + Vector2(thrash_x, thrash_y), delta * 1.4)
			bobber.rotation = lerp_angle(bobber.rotation, thrash_rot, delta * 4.0)
			
			if splash_particles:
				splash_particles.emitting = true
				splash_particles.amount = 10
				splash_particles.initial_velocity_min = 45.0
				splash_particles.initial_velocity_max = 95.0
				
	_update_fishing_line()

func _set_state(new_state: FishingState) -> void:
	current_state = new_state
	
	match current_state:
		FishingState.IDLE:
			var has_bait = not GameManager.equipped_bait.is_empty() and GameManager.inventory.get(GameManager.equipped_bait, 0) > 0
			if not has_bait:
				lbl_prompt.text = "💭 \"I should get bait for fish...\""
				lbl_prompt.modulate = Color(1.0, 0.9, 0.65, 0.95)
			else:
				lbl_prompt.text = "Click water to cast line"
				lbl_prompt.modulate = Color(1, 0.95, 0.85, 0.8)
			alert_icon.visible = false
			ripple_ring.visible = false
			bobber.visible = false
			bobber.rotation = 0.0
			if fishing_line:
				fishing_line.visible = false
			if splash_particles:
				splash_particles.emitting = false
		FishingState.CASTING:
			lbl_prompt.text = ""
			alert_icon.visible = false
			if fishing_line:
				fishing_line.visible = true
		FishingState.WAITING:
			lbl_prompt.text = ""
			ripple_ring.visible = true
			alert_icon.visible = false
			if fishing_line:
				fishing_line.visible = true
			if splash_particles:
				splash_particles.emitting = false
		FishingState.BITING:
			lbl_prompt.text = ""
			if fishing_line:
				fishing_line.visible = true
		FishingState.REELING:
			lbl_prompt.text = ""
			alert_icon.visible = false
			bobber.visible = true
			if fishing_line:
				fishing_line.visible = true
			_is_reeling_active = true
		FishingState.ESCAPED:
			alert_icon.visible = false
			if fishing_line:
				fishing_line.visible = false
			if splash_particles:
				splash_particles.emitting = false
			bobber.rotation = 0.0
		FishingState.RESULT:
			if fishing_line:
				fishing_line.visible = false

func _on_water_clicked(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	match current_state:
		FishingState.IDLE:
			var click_pos = water_surface.get_global_mouse_position()
			if click_pos.y < 365.0:
				return
			_cast_line(click_pos)
		FishingState.BITING:
			_hook_fish()

func _clamp_to_water(raw_pos: Vector2) -> Vector2:
	var y = clamp(raw_pos.y, 375.0, 675.0)
	var min_x = 70.0
	var max_x = 1210.0
	
	# Upper water (near distant mountains/shores) is narrower between left bank & right island
	if y < 450.0:
		var t = clamp((y - 375.0) / 75.0, 0.0, 1.0)
		min_x = lerp(260.0, 100.0, t)
		max_x = lerp(740.0, 1180.0, t)
	else:
		min_x = 70.0
		max_x = 1210.0
		
	var x = clamp(raw_pos.x, min_x, max_x)
	return Vector2(x, y)

func _cast_line(target_pos: Vector2) -> void:
	_set_state(FishingState.CASTING)
	
	_cast_pos = _clamp_to_water(target_pos)
	_player_pos = Vector2(640.0, 715.0) # Bottom center where player holds rod
	_far_pos = Vector2(_cast_pos.x + randf_range(-40.0, 40.0), clamp(_cast_pos.y - 110.0, 375.0, 540.0))
	
	# Start bobber launching in arc from bottom-center towards target water position
	var launch_start = Vector2(lerp(640.0, _cast_pos.x, 0.45), _cast_pos.y - 150.0)
	bobber.position = launch_start
	bobber.rotation = 0.0
	_bobber_origin_y = _cast_pos.y
	bobber.visible = true
	bobber.modulate.a = 0.0
	
	_reeling_progress = 0.35
	_is_reeling_inside = false
	_is_reeling_active = false
	if splash_particles:
		splash_particles.emitting = false
	
	# Splash arc tween: bobber flies smoothly and lands right on the clicked water spot
	var tween = create_tween().set_parallel()
	tween.tween_property(bobber, "position", _cast_pos, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bobber, "modulate:a", 1.0, 0.18)
	
	await tween.finished
	_spawn_water_ripple()
	if splash_particles:
		splash_particles.restart()
	if GameManager:
		GameManager.play_bobber_splash()
	_set_state(FishingState.WAITING)
	
	# Random wait time until bite (significantly affected by bait tier & lure_speed)
	var mods = GameManager.get_character_modifiers() if GameManager else {}
	var lure_speed_mult: float = mods.get("lure_speed", 1.0)
	
	var has_bait = not GameManager.equipped_bait.is_empty() and GameManager.inventory.get(GameManager.equipped_bait, 0) > 0
	var base_wait: float
	if not has_bait:
		# Bare hook (no bait): Fish take noticeably longer to investigate an empty hook
		base_wait = randf_range(6.5, 9.5)
	else:
		var bait_data = GameManager.get_equipped_bait_data()
		var bait_tier = bait_data.get("tier", 1)
		if bait_tier >= 3:
			base_wait = randf_range(2.0, 3.2)
		elif bait_tier == 2:
			base_wait = randf_range(2.8, 4.0)
		else:
			base_wait = randf_range(3.6, 5.0)
			
	var wait_duration: float = base_wait / lure_speed_mult
	get_tree().create_timer(wait_duration).timeout.connect(func():
		if current_state == FishingState.WAITING:
			_trigger_bite()
	)

func _spawn_water_ripple() -> void:
	ripple_ring.visible = true
	ripple_ring.scale = Vector2(0.2, 0.2)
	ripple_ring.modulate.a = 0.9
	var r_tween = create_tween().set_parallel()
	r_tween.tween_property(ripple_ring, "scale", Vector2(1.6, 0.8), 0.6)
	r_tween.tween_property(ripple_ring, "modulate:a", 0.0, 0.6)

func _update_fishing_line() -> void:
	if not fishing_line:
		return
	if not bobber.visible or current_state == FishingState.IDLE or current_state == FishingState.RESULT or current_state == FishingState.ESCAPED:
		fishing_line.visible = false
		return
		
	fishing_line.visible = true
	var start_pos = Vector2(640.0, 720.0) # Screen bottom-center where player holds rod
	var bobber_tip_offset = Vector2(0.0, -14.0).rotated(bobber.rotation)
	var end_pos = bobber.position + bobber_tip_offset
	
	var points: PackedVector2Array = PackedVector2Array()
	var num_segments: int = 14
	
	# Determine line sag or tension based on state
	var sag_amount: float = 0.0
	if current_state == FishingState.WAITING:
		# Natural resting catenary curve that sways gently with water waves
		sag_amount = 20.0 + sin(_anim_time * 2.4) * 3.5
	elif current_state == FishingState.BITING:
		# Sudden twitching / tension snap
		sag_amount = 4.0 + sin(_anim_time * 22.0) * 4.0
	elif current_state == FishingState.REELING:
		# Taut line under strain with fight jitter
		var jitter = sin(_anim_time * 30.0) * (2.2 if not _is_reeling_inside else 1.0)
		sag_amount = -3.0 + jitter
	elif current_state == FishingState.CASTING:
		sag_amount = 12.0
	
	# Quadratic Bezier midpoint
	var mid_pos = (start_pos + end_pos) * 0.5 + Vector2(0.0, sag_amount)
	
	for i in range(num_segments + 1):
		var t = float(i) / float(num_segments)
		var p = (1.0 - t) * (1.0 - t) * start_pos + 2.0 * (1.0 - t) * t * mid_pos + t * t * end_pos
		points.append(p)
		
	fishing_line.points = points

func _trigger_bite() -> void:
	# Roll fish based on equipped bait (or bare hook if none)
	pending_fish = GameManager.roll_fish_bite(GameManager.equipped_bait)
	var tier = pending_fish.get("tier", 1)
	var tier_color = GameManager.TIER_COLORS.get(tier, Color.WHITE)
	
	# Consume 1 bait only if bait is currently equipped
	if not GameManager.equipped_bait.is_empty() and GameManager.inventory.get(GameManager.equipped_bait, 0) > 0:
		GameManager.consume_equipped_bait()
	_update_bait_display()
	
	# Configure exclamation mark '!'
	alert_icon.modulate = tier_color
	alert_icon.visible = true
	alert_icon.scale = Vector2(0.2, 0.2)
	
	var alert_tween = create_tween()
	alert_tween.tween_property(alert_icon, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	alert_tween.tween_property(alert_icon, "scale", Vector2.ONE, 0.1)
	
	# Ripple water violently
	_spawn_water_ripple()
	if GameManager:
		GameManager.play_sfx(GameManager.SFX_BOBBER_PLOP, 1.0, 1.15)
	
	_set_state(FishingState.BITING)
	
	# Auto-hook: Instantly enters reeling minigame without requiring an extra tap!
	get_tree().create_timer(0.4).timeout.connect(func():
		if current_state == FishingState.BITING:
			_hook_fish()
	)

func _hook_fish() -> void:
	if current_state != FishingState.BITING:
		return
	_set_state(FishingState.REELING)
	alert_icon.visible = false
	reeling_hud.start_reeling(pending_fish)

func _fish_escaped(reason: String) -> void:
	_set_state(FishingState.ESCAPED)
	lbl_prompt.text = reason
	lbl_prompt.modulate = Color(1, 0.4, 0.35)
	
	if splash_particles:
		splash_particles.emitting = false
	_spawn_water_ripple()
	
	# Bobber gets dragged away deep into water and fades
	var tween = create_tween().set_parallel()
	tween.tween_property(bobber, "position:y", bobber.position.y - 45.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bobber, "modulate:a", 0.0, 0.35)
	await tween.finished
	bobber.visible = false
	bobber.rotation = 0.0
	
	get_tree().create_timer(1.2).timeout.connect(func():
		if current_state == FishingState.ESCAPED:
			_set_state(FishingState.IDLE)
	)

func _on_reeling_finished(success: bool, fish_data: Dictionary) -> void:
	_is_reeling_active = false
	if splash_particles:
		splash_particles.emitting = false
	bobber.rotation = 0.0
	
	if success:
		_set_state(FishingState.RESULT)
		_spawn_water_ripple()
		bobber.visible = false
		var tier = fish_data.get("tier", 1)
		var is_heavy = (tier >= 4 or (fish_data.get("category", "") == "fish" and fish_data.get("size_range", [10, 20])[1] > 100.0))
		if GameManager:
			GameManager.play_catch_splash(is_heavy)
		catch_dialog.show_catch(fish_data)
	else:
		_fish_escaped("The line snapped! The fish tore away.")

func _on_catch_dialog_closed(_action: String, _fish_data: Dictionary) -> void:
	_update_bait_display()
	_set_state(FishingState.IDLE)

func _update_bait_display() -> void:
	if not GameManager:
		return
	if lbl_cahs:
		lbl_cahs.text = "🪙 %d Cahs" % GameManager.cahs
	if not lbl_bait_info:
		return
	var bait_data = GameManager.get_equipped_bait_data()
	var qty = GameManager.inventory.get(GameManager.equipped_bait, 0)
	var has_bait = not bait_data.is_empty() and qty > 0
	if not has_bait:
		if tex_bait:
			tex_bait.visible = false
		lbl_bait_info.text = "🪝 Bare Hook (No Bait)"
	else:
		var tex_path: String = bait_data.get("icon_texture", "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			if tex_bait:
				tex_bait.texture = load(tex_path)
				tex_bait.visible = true
			lbl_bait_info.text = "%s (x%d)" % [bait_data.get("name", ""), qty]
		else:
			if tex_bait:
				tex_bait.visible = false
			lbl_bait_info.text = "%s %s (x%d)" % [bait_data.get("icon_symbol", "🎣"), bait_data.get("name", ""), qty]
		
	if current_state == FishingState.IDLE:
		if not has_bait:
			lbl_prompt.text = "💭 \"I should get bait for fish...\""
			lbl_prompt.modulate = Color(1.0, 0.9, 0.65, 0.95)
		else:
			lbl_prompt.text = "Click water to cast line"
			lbl_prompt.modulate = Color(1, 0.95, 0.85, 0.8)

func _on_tackle_pressed() -> void:
	tackle_dialog.open()

func _on_back_pressed() -> void:
	GameManager.change_scene("res://scenes/lobby/lobby.tscn")

func _on_time_updated(_time: float) -> void:
	if lbl_clock:
		lbl_clock.text = GameManager.get_time_formatted()

func _on_period_changed(_new_period: String) -> void:
	var new_bg = GameManager.get_current_period_bg_texture()
	var new_water = GameManager.get_current_period_water_texture()
	
	var tween = create_tween().set_parallel()
	
	if bg_texture_fade and new_bg:
		bg_texture_fade.texture = new_bg
		bg_texture_fade.modulate.a = 0.0
		tween.tween_property(bg_texture_fade, "modulate:a", 1.0, 1.2)
	elif bg_texture and new_bg:
		bg_texture.texture = new_bg
		
	if water_texture_fade and new_water:
		water_texture_fade.texture = new_water
		water_texture_fade.modulate.a = 0.0
		tween.tween_property(water_texture_fade, "modulate:a", 1.0, 1.2)
	elif water_texture and new_water:
		water_texture.texture = new_water
		
	await tween.finished
	
	if bg_texture and new_bg:
		bg_texture.texture = new_bg
	if bg_texture_fade:
		bg_texture_fade.modulate.a = 0.0
		
	if water_texture and new_water:
		water_texture.texture = new_water
	if water_texture_fade:
		water_texture_fade.modulate.a = 0.0
