@tool
extends EditorPlugin

const FTUEManager = preload("res://scripts/ftue_manager.gd")
const DockScene = preload("res://addons/ftue_editor/ftue_editor_dock.tscn")

var dock: Control
var current_tutorial: Dictionary = {}
var pristine_tutorial: Dictionary = {}
var current_step_index: int = -1
var ftue_manager: Node = null

signal load_requested

func _enter_tree():
	print("Plugin entering tree")
	# Create the dock
	dock = DockScene.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	
	# Connect signals
	dock.step_changed.connect(_on_step_changed)
	dock.position_updated.connect(_on_position_updated)
	dock.size_updated.connect(_on_size_updated)
	dock.radius_updated.connect(_on_radius_updated)
	dock.save_requested.connect(_on_save_requested)
	dock.highlight_type_changed.connect(_on_highlight_type_changed)
	dock.load_requested.connect(_on_load_requested)
	dock.dialog_title_changed.connect(_on_dialog_title_changed)
	dock.dialog_text_changed.connect(_on_dialog_text_changed)
	dock.dialog_image_changed.connect(_on_dialog_image_changed)
	
	# Load initial tutorial data
	_load_tutorial_data()
	
	print("FTUE Editor plugin initialized")

func _exit_tree():
	print("Plugin exiting tree")
	# Clean up
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	print("FTUE Editor plugin cleaned up")

func _find_ftue_manager() -> Node:
	# Get the current edited scene
	var edited_scene = get_editor_interface().get_edited_scene_root()
	if not edited_scene:
		return null
		
	var found = _find_ftue_manager_recursive(edited_scene)
	if found:
		return found
		
	return null

func _find_ftue_manager_recursive(node: Node) -> Node:
	# Check if this node is the FTUEManager
	if node.get_script() == FTUEManager:
		return node
		
	# Check all children recursively
	for child in node.get_children():
		var found = _find_ftue_manager_recursive(child)
		if found:
			return found
			
	return null

func _load_tutorial_data() -> void:
	print("Loading tutorial data from tutorial_data.json")
	var file = FileAccess.open("res://tutorial_data.json", FileAccess.READ)
	if file:
		var data = file.get_as_text()
		var parsed = JSON.parse_string(data)
		if typeof(parsed) == TYPE_DICTIONARY:
			current_tutorial = parsed
			pristine_tutorial = parsed.duplicate(true) # Deep copy
			current_step_index = 0
			if dock:
				dock.update_controls(current_tutorial.steps[current_step_index])
			_update_preview()
			_update_scene_highlight()
			print("Tutorial data loaded successfully")
		else:
			print("Failed to parse tutorial data")
		file.close()
	else:
		print("Could not open tutorial_data.json")

func _on_step_changed(step_index: int) -> void:
	# Restore the step from pristine_tutorial
	if pristine_tutorial.has("steps") and step_index >= 0 and step_index < pristine_tutorial.steps.size():
		current_tutorial.steps[step_index] = pristine_tutorial.steps[step_index].duplicate(true)
	current_step_index = step_index
	if current_step_index >= 0 and current_step_index < current_tutorial.steps.size():
		dock.update_controls(current_tutorial.steps[current_step_index])
		_update_preview()
		_update_scene_highlight()

func _parse_vector2_string(vector_str: String) -> Vector2:
	# Remove parentheses and split by comma
	var clean_str = vector_str.replace("(", "").replace(")", "")
	var parts = clean_str.split(",")
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2.ZERO

func _on_highlight_type_changed(type: int) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		print("DEBUG: Invalid step index: ", current_step_index)
		return
	var step = current_tutorial.steps[current_step_index]
	
	# Preserve existing position and size/radius values
	var old_position = step.highlight.get("position", Vector2(100, 100))
	if typeof(old_position) == TYPE_STRING:
		old_position = _parse_vector2_string(old_position)
	
	var old_size = step.highlight.get("size", Vector2(100, 100))
	if typeof(old_size) == TYPE_STRING:
		old_size = _parse_vector2_string(old_size)
	
	var old_radius = step.highlight.get("radius", 50)
	
	# Create new highlight data with the new type
	step.highlight = {
		"shape": type,
		"position": old_position  # Always preserve position
	}
	
	# Set size/radius based on type
	if type == 1: # Rectangle
		step.highlight["size"] = old_size
	elif type == 0: # Circle
		step.highlight["radius"] = old_radius
	
	_update_preview()
	dock.update_controls(step)
	_update_scene_highlight()

func _on_position_updated(position: Vector2) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	var step = current_tutorial.steps[current_step_index]
	var highlight = step.highlight
	match highlight.shape:
		FTUEManager.HighlightShape.CIRCLE:
			highlight.position = position
		FTUEManager.HighlightShape.RECTANGLE:
			highlight.position = position
	_update_preview()
	_update_scene_highlight()

func _on_size_updated(size: Vector2) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	var step = current_tutorial.steps[current_step_index]
	if step.highlight.shape == FTUEManager.HighlightShape.RECTANGLE:
		step.highlight.size = size
	_update_preview()
	_update_scene_highlight()

func _on_radius_updated(radius: float) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	var step = current_tutorial.steps[current_step_index]
	if step.highlight.shape == FTUEManager.HighlightShape.CIRCLE:
		step.highlight.radius = radius
	_update_preview()
	_update_scene_highlight()

func _on_save_requested() -> void:
	print("Saving tutorial data")
	var file = FileAccess.open("res://tutorial_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(current_tutorial, "  "))
	file.close()
	print("Tutorial data saved to tutorial_data.json")
	pristine_tutorial = current_tutorial.duplicate(true) # Deep copy after save

func _on_load_requested() -> void:
	print("Loading tutorial data")
	var file = FileAccess.open("res://tutorial_data.json", FileAccess.READ)
	if file:
		var data = file.get_as_text()
		var parsed = JSON.parse_string(data)
		if typeof(parsed) == TYPE_DICTIONARY:
			current_tutorial = parsed
			pristine_tutorial = parsed.duplicate(true) # Deep copy
			current_step_index = 0
			if dock:
				dock.update_controls(current_tutorial.steps[current_step_index])
			_update_preview()
			_update_scene_highlight()
			print("Tutorial data loaded from tutorial_data.json")
		else:
			print("Failed to parse tutorial data")
		file.close()
	else:
		print("Could not open tutorial_data.json")

func _on_dialog_title_changed(new_title: String) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	current_tutorial.steps[current_step_index].title = new_title
	_update_preview()
	_update_scene_highlight()

func _on_dialog_text_changed(new_text: String) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	current_tutorial.steps[current_step_index].text = new_text
	_update_preview()
	_update_scene_highlight()

func _on_dialog_image_changed(new_path: String) -> void:
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
	current_tutorial.steps[current_step_index].image = new_path
	_update_preview()
	_update_scene_highlight()

func _update_preview() -> void:
	if not dock or current_step_index < 0:
		return
	var preview = dock.get_node("PreviewContainer")
	if preview:
		var step = current_tutorial.steps[current_step_index].duplicate(true)
		print("Updating preview with step data: ", step)
		
		# Convert string positions to Vector2
		if typeof(step.dialog_position) == TYPE_STRING:
			step.dialog_position = _parse_vector2_string(step.dialog_position)
		
		if step.highlight.has("position") and typeof(step.highlight.position) == TYPE_STRING:
			step.highlight.position = _parse_vector2_string(step.highlight.position)
		
		if step.highlight.has("size") and typeof(step.highlight.size) == TYPE_STRING:
			step.highlight.size = _parse_vector2_string(step.highlight.size)
		
		print("Sending to preview: ", step)
		preview.set_step_data(step)

func _update_scene_highlight() -> void:
	print("DEBUG: Updating scene highlight")
	# Find the FTUEManager in the current scene
	ftue_manager = _find_ftue_manager()
	if not ftue_manager:
		return
		
	if current_step_index < 0 or current_step_index >= current_tutorial.steps.size():
		return
		
	# Update the highlight in the scene
	var step = current_tutorial.steps[current_step_index]
	ftue_manager._update_highlight(step.highlight)

func show_text_panel(title: String, body: String, image: Texture = null, button_text: String = "Continue", button_callback: Callable = Callable()):
	var panel = $FTUETextPanel
	panel.visible = true
	panel.z_index = 1000
	panel.get_node("VBoxContainer/TitleLabel").text = title
	panel.get_node("VBoxContainer/BodyText").text = body
	panel.get_node("VBoxContainer/ImageRect").texture = image
	panel.get_node("VBoxContainer/ImageRect").visible = image != null
	var btn = panel.get_node("VBoxContainer/ActionButton")
	btn.text = button_text
	btn.pressed.disconnect_all()
	if button_callback.is_valid():
		btn.pressed.connect(button_callback)

func hide_text_panel():
	$FTUETextPanel.visible = false

func _on_load_pressed() -> void:
	print("Load requested")
	load_requested.emit()
