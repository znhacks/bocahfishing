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

func _create_fish_card(data: Dictionary, is_caught: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(330, 160)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	
	if is_caught:
		style.bg_color = Color(0.12, 0.18, 0.22, 0.9)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.35, 0.65, 0.8, 0.5)
	else:
		style.bg_color = Color(0.08, 0.1, 0.12, 0.75)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.2, 0.25, 0.3, 0.3)
		
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
	name_lbl.add_theme_font_size_override("font_size", 16)
	
	if is_caught:
		icon_lbl.text = data.get("icon_symbol", "🐟")
		name_lbl.text = data.get("name", "Fish")
		name_lbl.modulate = Color(0.95, 0.9, 0.7)
	else:
		icon_lbl.text = "❓"
		icon_lbl.modulate = Color(0.4, 0.45, 0.5)
		name_lbl.text = "??? (Undiscovered)"
		name_lbl.modulate = Color(0.5, 0.55, 0.6)
		
	top_box.add_child(icon_lbl)
	top_box.add_child(name_lbl)
	
	var tier_lbl = Label.new()
	tier_lbl.text = "Lake Depth: Tier %d" % data.get("tier", 1)
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
		if not pref.is_empty():
			desc_lbl.text = "Hint: Tempted by bait with [%s] attributes." % ", ".join(pref).capitalize()
		else:
			desc_lbl.text = "Hint: Resting quietly in the deep calm waters."
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
