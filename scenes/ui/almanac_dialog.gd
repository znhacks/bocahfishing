extends Control

# Fish Almanac Dialog
signal closed()

@onready var grid_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var lbl_progress: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/LblProgress
@onready var btn_close: Button = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	if GameManager:
		GameManager.fish_unlocked.connect(func(_f): refresh_almanac())
	refresh_almanac()

func open() -> void:
	visible = true
	refresh_almanac()
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func close() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()

func refresh_almanac() -> void:
	if not is_inside_tree() or not grid_container:
		return
		
	var progress = GameManager.get_almanac_progress()
	lbl_progress.text = "Discovered: %d / %d Species" % [progress["caught"], progress["total"]]
	
	for child in grid_container.get_children():
		child.queue_free()
		
	for item_id in GameManager.item_db.keys():
		var data = GameManager.item_db[item_id]
		if data.get("category") != "fish":
			continue
			
		var is_caught = GameManager.is_unlocked(item_id)
		var card = _create_fish_card(data, is_caught)
		grid_container.add_child(card)

const FONT_OUTFIT = preload("res://assets/fonts/Outfit-Bold.ttf")

func _create_fish_card(data: Dictionary, is_caught: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(330, 160)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.shadow_color = Color(0, 0, 0, 0.35)
	
	if is_caught:
		style.bg_color = Color(0.12, 0.18, 0.24, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.75, 0.9, 0.75)
	else:
		style.bg_color = Color(0.08, 0.1, 0.13, 0.8)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.25, 0.3, 0.35, 0.5)
		
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var top_box = HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 10)
	vbox.add_child(top_box)
	
	var icon_lbl = Label.new()
	icon_lbl.custom_minimum_size = Vector2(40, 40)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	
	var name_lbl = Label.new()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", FONT_OUTFIT)
	name_lbl.add_theme_font_size_override("font_size", 16)
	
	var icon_tex_path = data.get("icon_texture", "")
	if is_caught:
		name_lbl.text = data.get("name", "Fish")
		name_lbl.modulate = Color(0.95, 0.9, 0.7)
		if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path):
			var tex_rect = TextureRect.new()
			tex_rect.custom_minimum_size = Vector2(48, 44)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture = load(icon_tex_path)
			top_box.add_child(tex_rect)
		else:
			icon_lbl.text = ""
			top_box.add_child(icon_lbl)
	else:
		name_lbl.text = "??? (Undiscovered)"
		name_lbl.modulate = Color(0.5, 0.55, 0.6)
		if icon_tex_path != "" and ResourceLoader.exists(icon_tex_path):
			var tex_rect = TextureRect.new()
			tex_rect.custom_minimum_size = Vector2(48, 44)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture = load(icon_tex_path)
			tex_rect.modulate = Color(0.08, 0.12, 0.16, 0.85) # Mysterious silhouette!
			top_box.add_child(tex_rect)
		else:
			icon_lbl.text = "?"
			icon_lbl.modulate = Color(0.4, 0.45, 0.5)
			top_box.add_child(icon_lbl)
		
	top_box.add_child(name_lbl)
	
	var time_avail = data.get("time_available", "all")
	var time_tag = "Anytime"
	if time_avail == "night":
		time_tag = "Night Only"
	elif time_avail == "day":
		time_tag = "Day Only"

	var tier_lbl = Label.new()
	tier_lbl.text = "Tier %d • %s" % [data.get("tier", 1), time_tag]
	tier_lbl.modulate = Color(0.6, 0.75, 0.85, 0.8)
	tier_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(tier_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 12)
	
	if is_caught:
		desc_lbl.text = data.get("desc", "")
		desc_lbl.modulate = Color(0.85, 0.85, 0.85, 0.85)
	else:
		var pref = data.get("preferred_tags", [])
		var time_hint = " (Prowls at night)" if time_avail == "night" else (" (Active in daylight)" if time_avail == "day" else "")
		if not pref.is_empty():
			desc_lbl.text = "Hint: Tempted by [%s] bait%s." % [", ".join(pref).capitalize(), time_hint]
		else:
			desc_lbl.text = "Hint: Resting quietly in deep waters%s." % time_hint
		desc_lbl.modulate = Color(0.45, 0.6, 0.65, 0.7)
		
	vbox.add_child(desc_lbl)
	
	if is_caught:
		var tags_str = "Effective Bait: " + ", ".join(data.get("preferred_tags", ["Any"])).capitalize()
		var tag_lbl = Label.new()
		tag_lbl.text = tags_str
		tag_lbl.modulate = Color(0.4, 0.9, 0.65, 0.9)
		tag_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(tag_lbl)
		
	return card
