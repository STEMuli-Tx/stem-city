@tool
extends Control

const FTUEManager = preload("res://scripts/ftue_manager.gd")

signal step_changed(step_index: int)
signal position_updated(position: Vector2)
signal size_updated(size: Vector2)
signal radius_updated(radius: float)
signal save_requested
signal highlight_type_changed(type: int)
signal load_requested
signal dialog_text_changed(new_text: String)
signal dialog_title_changed(new_title: String)
signal dialog_image_changed(new_path: String)

@onready var highlight_type_selector: OptionButton = $VBoxContainer/HighlightTypeSelector
@onready var step_selector: OptionButton = $VBoxContainer/StepSelector
@onready var x_position: SpinBox = $VBoxContainer/PositionControls/XPosition
@onready var y_position: SpinBox = $VBoxContainer/PositionControls/YPosition
@onready var width: SpinBox = $VBoxContainer/SizeControls/Width
@onready var height: SpinBox = $VBoxContainer/SizeControls/Height
@onready var radius: SpinBox = $VBoxContainer/SizeControls/Radius
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var preview_container: Control = $PreviewContainer
@onready var dialog_title_edit: LineEdit = $VBoxContainer/DialogTitleEdit
@onready var dialog_text_edit: TextEdit = $VBoxContainer/DialogTextEdit
@onready var dialog_image_edit: LineEdit = $VBoxContainer/DialogImageEdit
@onready var dialog_x: SpinBox = $VBoxContainer/DialogPositionSizeControls/DialogX
@onready var dialog_y: SpinBox = $VBoxContainer/DialogPositionSizeControls/DialogY
@onready var dialog_w: SpinBox = $VBoxContainer/DialogPositionSizeControls/DialogW
@onready var dialog_h: SpinBox = $VBoxContainer/DialogPositionSizeControls/DialogH

var step_data: Dictionary = {}

func _ready():
	print("Dock ready")
	# Connect signals
	highlight_type_selector.clear()
	highlight_type_selector.add_item("Circle", 0)
	highlight_type_selector.add_item("Rectangle", 1)
	highlight_type_selector.add_item("None", 2)
	highlight_type_selector.item_selected.connect(_on_highlight_type_selected)

	step_selector.item_selected.connect(_on_step_selected)
	x_position.value_changed.connect(_on_position_changed)
	y_position.value_changed.connect(_on_position_changed)
	width.value_changed.connect(_on_size_changed)
	height.value_changed.connect(_on_size_changed)
	radius.value_changed.connect(_on_radius_changed)
	save_button.pressed.connect(_on_save_pressed)
	dialog_title_edit.text_changed.connect(_on_dialog_title_changed)
	dialog_text_edit.text_changed.connect(_on_dialog_text_changed)
	dialog_image_edit.text_changed.connect(_on_dialog_image_changed)
	dialog_x.value_changed.connect(_on_dialog_position_size_changed)
	dialog_y.value_changed.connect(_on_dialog_position_size_changed)
	dialog_w.value_changed.connect(_on_dialog_position_size_changed)
	dialog_h.value_changed.connect(_on_dialog_position_size_changed)
	
	# Set up preview container
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add initial steps to selector
	step_selector.clear()
	step_selector.add_item("Step 1")
	step_selector.add_item("Step 2")
	step_selector.add_item("Step 3")
	
	# Select the first step
	step_selector.select(0)
	step_changed.emit(0)

func _on_highlight_type_selected(type: int) -> void:
	print("Highlight type selected: ", type)
	highlight_type_changed.emit(type)

func _on_step_selected(index: int) -> void:
	print("Step selected: ", index)
	step_changed.emit(index)

func _on_position_changed(_value: float) -> void:
	print("Position changed: ", Vector2(x_position.value, y_position.value))
	position_updated.emit(Vector2(x_position.value, y_position.value))

func _on_size_changed(_value: float) -> void:
	print("Size changed: ", Vector2(width.value, height.value))
	size_updated.emit(Vector2(width.value, height.value))

func _on_radius_changed(value: float) -> void:
	print("Radius changed: ", value)
	radius_updated.emit(value)

func _on_save_pressed() -> void:
	print("Save requested")
	save_requested.emit()

func _on_dialog_title_changed(new_title: String):
	dialog_title_changed.emit(new_title)

func _on_dialog_text_changed():
	dialog_text_changed.emit(dialog_text_edit.text)

func _on_dialog_image_changed(new_path: String):
	dialog_image_changed.emit(new_path)

func _on_dialog_position_size_changed(_value: float) -> void:
	if not step_selector:
		return
	var idx = step_selector.selected
	if idx < 0:
		return
	# Update the local step_data and preview
	step_data.dialog_position = Vector2(dialog_x.value, dialog_y.value)
	step_data.dialog_size = Vector2(dialog_w.value, dialog_h.value)
	if preview_container:
		preview_container.set_step_data(step_data)

func _parse_vector2_string(vector_str: String) -> Vector2:
	# Remove parentheses and split by comma
	var clean_str = vector_str.replace("(", "").replace(")", "")
	var parts = clean_str.split(",")
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2.ZERO

func update_controls(new_step_data: Dictionary) -> void:
	print("Updating controls with data: ", new_step_data)
	step_data = new_step_data
	var highlight = step_data.highlight

	# Temporarily disconnect the signal
	highlight_type_selector.item_selected.disconnect(_on_highlight_type_selected)
	highlight_type_selector.select(highlight.shape)
	# Reconnect the signal
	highlight_type_selector.item_selected.connect(_on_highlight_type_selected)

	# Temporarily disconnect signals for all SpinBox controls
	x_position.value_changed.disconnect(_on_position_changed)
	y_position.value_changed.disconnect(_on_position_changed)
	width.value_changed.disconnect(_on_size_changed)
	height.value_changed.disconnect(_on_size_changed)
	radius.value_changed.disconnect(_on_radius_changed)

	# Update position controls
	if highlight.has("position"):
		var pos = highlight.position
		if typeof(pos) == TYPE_STRING:
			pos = _parse_vector2_string(pos)
		elif typeof(pos) == TYPE_DICTIONARY:
			pos = Vector2(pos.x, pos.y)
		x_position.value = pos.x
		y_position.value = pos.y
	else:
		x_position.value = 0
		y_position.value = 0

	# Update size controls based on shape
	match int(highlight.shape):
		FTUEManager.HighlightShape.CIRCLE:
			width.hide()
			height.hide()
			radius.show()
			radius.value = highlight.radius if highlight.has("radius") else 50
		FTUEManager.HighlightShape.RECTANGLE:
			width.show()
			height.show()
			radius.hide()
			var size = highlight.size
			if typeof(size) == TYPE_STRING:
				size = _parse_vector2_string(size)
			elif typeof(size) == TYPE_DICTIONARY:
				size = Vector2(size.x, size.y)
			width.value = size.x if highlight.has("size") else 100
			height.value = size.y if highlight.has("size") else 100
		FTUEManager.HighlightShape.NONE:
			width.hide()
			height.hide()
			radius.hide()

	# Reconnect signals for all SpinBox controls
	x_position.value_changed.connect(_on_position_changed)
	y_position.value_changed.connect(_on_position_changed)
	width.value_changed.connect(_on_size_changed)
	height.value_changed.connect(_on_size_changed)
	radius.value_changed.connect(_on_radius_changed)

	# Dialog position and size controls
	var dialog_pos = step_data.dialog_position if step_data.has("dialog_position") else Vector2(400, 100)
	if typeof(dialog_pos) == TYPE_STRING:
		dialog_pos = _parse_vector2_string(dialog_pos)
	dialog_x.value = dialog_pos.x
	dialog_y.value = dialog_pos.y
	var dialog_size = step_data.dialog_size if step_data.has("dialog_size") else Vector2(320, 120)
	if typeof(dialog_size) == TYPE_STRING:
		dialog_size = _parse_vector2_string(dialog_size)
	dialog_w.value = dialog_size.x
	dialog_h.value = dialog_size.y

	dialog_title_edit.text = step_data.title if step_data.has("title") else ""
	dialog_text_edit.text = step_data.text if step_data.has("text") else ""
	dialog_image_edit.text = step_data.image if step_data.has("image") else "" 