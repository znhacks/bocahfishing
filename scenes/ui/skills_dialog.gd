extends Control

# Skills / Character Selection Dialog
# Bocah Fishing
signal closed()

@onready var btn_close: Button = $PanelContainer/Margin/VBox/HeaderBox/BtnClose
@onready var lbl_cahs: Label = $PanelContainer/Margin/VBox/HeaderBox/LblCahs
@onready var card_container: HBoxContainer = $PanelContainer/Margin/VBox/CardContainer

# Card buttons
@onready var btn_action_none: Button = $PanelContainer/Margin/VBox/CardContainer/CardNone/VBox/BtnAction
@onready var btn_action_jia: Button = $PanelContainer/Margin/VBox/CardContainer/CardJia/VBox/BtnAction
@onready var btn_action_joe: Button = $PanelContainer/Margin/VBox/CardContainer/CardJoe/VBox/BtnAction

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	btn_action_none.pressed.connect(func(): _on_char_action("none"))
	btn_action_jia.pressed.connect(func(): _on_char_action("jia"))
	btn_action_joe.pressed.connect(func(): _on_char_action("joe"))
	
	if GameManager:
		GameManager.cahs_changed.connect(func(_c): refresh_dialog())
		GameManager.character_changed.connect(func(_id): refresh_dialog())
		
	refresh_dialog()

func open() -> void:
	visible = true
	refresh_dialog()
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

func refresh_dialog() -> void:
	if not is_inside_tree() or not lbl_cahs:
		return
		
	lbl_cahs.text = "🪙 %d Cahs" % GameManager.cahs
	_update_char_button("none", btn_action_none)
	_update_char_button("jia", btn_action_jia)
	_update_char_button("joe", btn_action_joe)

func _update_char_button(char_id: String, btn: Button) -> void:
	var is_selected = (GameManager.selected_character == char_id)
	var is_unlocked = GameManager.unlocked_characters.has(char_id)
	var cost = GameManager.character_db[char_id].get("cost", 0)
	
	if is_selected:
		btn.text = "✓ Selected"
		btn.disabled = true
	elif is_unlocked:
		btn.text = "Select"
		btn.disabled = false
	else:
		btn.text = "Unlock (%d Cahs)" % cost
		btn.disabled = (GameManager.cahs < cost)

func _on_char_action(char_id: String) -> void:
	if GameManager.unlocked_characters.has(char_id):
		GameManager.select_character(char_id)
	else:
		GameManager.buy_character(char_id)
	refresh_dialog()
