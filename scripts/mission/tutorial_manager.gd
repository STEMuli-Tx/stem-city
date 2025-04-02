extends Node
class_name TutorialManager

signal tutorial_started(tutorial_id: String)
signal tutorial_completed(tutorial_id: String)
signal step_activated(step_index: int)
signal step_completed(step_index: int)

@export var tutorials: Array[TutorialData] = []
@export var active_on_start: bool = true  # Whether to start the welcome tutorial automatically

# UI elements
var modal_container: ColorRect
var modal_panel: PanelContainer
var modal_content: Label
var modal_button: Button
var tooltip_container: Control
var tooltip_panel: Panel
var tooltip_content: Label
var tooltip_pointer: Polygon2D
var highlight_rect: Control

# State tracking
var current_tutorial: TutorialData
var current_step_index: int = -1
var is_tutorial_active: bool = false
var step_completed_callbacks: Dictionary = {}
var delayed_tooltips: Dictionary = {}
var tooltip_timer: Timer
var mission_manager: MissionManager

func _ready():
	# Create the UI elements for tutorials
	_create_ui_elements()
	
	# Start initial tutorial if configured
	if active_on_start:
		# Wait for scene to fully initialize
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Find and start the welcome tutorial
		for tutorial in tutorials:
			if tutorial.id == "welcome":
				start_tutorial(tutorial)
				break

# Create all UI elements for tutorials
func _create_ui_elements():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "TutorialLayer"
	canvas_layer.layer = 10  # Put on top of other UI
	add_child(canvas_layer)
	
	# Create modal elements
	_create_modal_elements(canvas_layer)
	
	# Create tooltip elements
	_create_tooltip_elements(canvas_layer)
	
	# Create highlight elements
	_create_highlight_elements(canvas_layer)
	
	# Create timer for delayed tooltips
	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)

# Create modal dialog elements
func _create_modal_elements(parent: Node):
	# Modal background overlay
	modal_container = ColorRect.new()
	modal_container.name = "ModalContainer"
	modal_container.anchor_right = 1.0
	modal_container.anchor_bottom = 1.0
	modal_container.color = Color(0, 0, 0, 0.7)
	modal_container.visible = false
	parent.add_child(modal_container)
	
	# Center container to position the panel
	var center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	modal_container.add_child(center_container)
	
	# Modal panel
	modal_panel = PanelContainer.new()
	modal_panel.name = "ModalPanel"
	modal_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	modal_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	modal_panel.custom_minimum_size = Vector2(600, 300)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.376, 0.760, 0.658, 1.0)  # Teal border
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 5
	
	modal_panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(modal_panel)
	
	# VBox container for content
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(580, 0)
	vbox.add_theme_constant_override("separation", 20)
	modal_panel.add_child(vbox)
	
	# Margin container for the content
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	vbox.add_child(margin)
	
	# Content label
	modal_content = Label.new()
	modal_content.name = "ContentLabel"
	modal_content.text = "Welcome to Stem City!"
	modal_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_content.add_theme_font_size_override("font_size", 24)
	modal_content.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	modal_content.custom_minimum_size = Vector2(500, 150)
	margin.add_child(modal_content)
	
	# Center container for button
	var button_container = CenterContainer.new()
	button_container.name = "ButtonContainer"
	button_container.size_flags_vertical = Control.SIZE_SHRINK_END
	vbox.add_child(button_container)
	
	# Continue button
	modal_button = Button.new()
	modal_button.name = "ContinueButton"
	modal_button.text = "CONTINUE"
	modal_button.custom_minimum_size = Vector2(200, 60)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.376, 0.760, 0.658, 0.25)  # Teal with transparency
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.376, 0.760, 0.658, 1.0)  # Teal border
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	
	modal_button.add_theme_stylebox_override("normal", button_style)
	modal_button.add_theme_font_size_override("font_size", 24)
	modal_button.add_theme_color_override("font_color", Color(0.376, 0.760, 0.658, 1.0))  # Teal text
	modal_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1.0))  # White text on hover
	
	button_container.add_child(modal_button)
	
	# Connect button signal
	modal_button.pressed.connect(_on_modal_button_pressed)

# Create tooltip elements
func _create_tooltip_elements(parent: Node):
	# Tooltip container
	tooltip_container = Control.new()
	tooltip_container.name = "TooltipContainer"
	tooltip_container.anchor_right = 1.0
	tooltip_container.anchor_bottom = 1.0
	tooltip_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_container.visible = false
	parent.add_child(tooltip_container)
	
	# Tooltip panel
	tooltip_panel = Panel.new()
	tooltip_panel.name = "TooltipPanel"
	tooltip_panel.custom_minimum_size = Vector2(250, 0)  # Auto height, fixed width
	tooltip_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.15, 0.15, 0.25, 0.95)  # More opaque background
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.border_color = Color(0.376, 0.760, 0.658, 1.0)  # Teal border
	tooltip_style.corner_radius_top_left = 8
	tooltip_style.corner_radius_top_right = 8
	tooltip_style.corner_radius_bottom_right = 8
	tooltip_style.corner_radius_bottom_left = 8
	
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	tooltip_container.add_child(tooltip_panel)
	
	# Tooltip content
	tooltip_content = Label.new()
	tooltip_content.name = "TooltipContent"
	tooltip_content.text = "This is a tooltip"
	tooltip_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_content.add_theme_font_size_override("font_size", 16)  # Smaller font
	tooltip_content.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	tooltip_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.name = "TooltipMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	margin.add_child(tooltip_content)
	tooltip_panel.add_child(margin)
	
	# Tooltip pointer
	tooltip_pointer = Polygon2D.new()
	tooltip_pointer.name = "TooltipPointer"
	tooltip_pointer.color = Color(0.376, 0.760, 0.658, 1.0)  # Teal border
	tooltip_pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 20)])
	tooltip_container.add_child(tooltip_pointer)

# Create highlight elements
func _create_highlight_elements(parent: Node):
	# Highlight rectangle
	highlight_rect = Control.new()
	highlight_rect.name = "HighlightRect"
	highlight_rect.visible = false
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Use a ColorRect with a hole in it as a highlight
	var highlight_shader = preload("res://shaders/highlight_shader.gdshader") if ResourceLoader.exists("res://shaders/highlight_shader.gdshader") else null
	
	if highlight_shader:
		var material = ShaderMaterial.new()
		material.shader = highlight_shader
		
		var highlight_color_rect = ColorRect.new()
		highlight_color_rect.name = "HighlightColorRect"
		highlight_color_rect.material = material
		highlight_color_rect.anchor_right = 1.0
		highlight_color_rect.anchor_bottom = 1.0
		highlight_color_rect.color = Color(0, 0, 0, 0.5)
		highlight_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		highlight_rect.add_child(highlight_color_rect)
	else:
		# Fallback solution - create a border using control nodes
		var highlight_border = Control.new()
		highlight_border.name = "HighlightBorder"
		highlight_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Add top, bottom, left, right borders
		var top_border = ColorRect.new()
		top_border.name = "TopBorder"
		top_border.color = Color(0.376, 0.760, 0.658, 1.0)  # Teal
		top_border.custom_minimum_size = Vector2(0, 3)
		top_border.anchor_right = 1.0
		top_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var bottom_border = ColorRect.new()
		bottom_border.name = "BottomBorder"
		bottom_border.color = Color(0.376, 0.760, 0.658, 1.0)  # Teal
		bottom_border.custom_minimum_size = Vector2(0, 3)
		bottom_border.anchor_top = 1.0
		bottom_border.anchor_right = 1.0
		bottom_border.anchor_bottom = 1.0
		bottom_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var left_border = ColorRect.new()
		left_border.name = "LeftBorder"
		left_border.color = Color(0.376, 0.760, 0.658, 1.0)  # Teal
		left_border.custom_minimum_size = Vector2(3, 0)
		left_border.anchor_bottom = 1.0
		left_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var right_border = ColorRect.new()
		right_border.name = "RightBorder"
		right_border.color = Color(0.376, 0.760, 0.658, 1.0)  # Teal
		right_border.custom_minimum_size = Vector2(3, 0)
		right_border.anchor_left = 1.0
		right_border.anchor_right = 1.0
		right_border.anchor_bottom = 1.0
		right_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		highlight_border.add_child(top_border)
		highlight_border.add_child(bottom_border)
		highlight_border.add_child(left_border)
		highlight_border.add_child(right_border)
		highlight_rect.add_child(highlight_border)
	
	parent.add_child(highlight_rect)

# Start a tutorial by ID
func start_tutorial(tutorial: TutorialData):
	print("Starting tutorial: ", tutorial.id if tutorial else "NULL")
	
	# Make sure there's no active tutorial
	if is_tutorial_active:
		print("Stopping previous tutorial before starting new one")
		stop_current_tutorial()
	
	# Set up the new tutorial
	current_tutorial = tutorial
	current_step_index = -1
	is_tutorial_active = true
	
	# Validate tutorial data
	if not current_tutorial:
		push_error("Tutorial data is null!")
		return
		
	if current_tutorial.steps.size() == 0:
		push_error("Tutorial has no steps!")
		return
		
	print("Tutorial has ", current_tutorial.steps.size(), " steps")
	
	# Emit signal
	tutorial_started.emit(tutorial.id)
	
	# Start first step
	advance_to_next_step()

# Stop the current tutorial
func stop_current_tutorial():
	if is_tutorial_active:
		# Hide any active UI
		_hide_all_tutorial_ui()
		
		# Reset state
		is_tutorial_active = false
		
		# Emit signal if we had a tutorial
		if current_tutorial:
			var tutorial_id = current_tutorial.id
			current_tutorial = null
			current_step_index = -1
			tutorial_completed.emit(tutorial_id)

# Advance to the next step in the tutorial
func advance_to_next_step():
	print("Advancing to next step...")
	if not is_tutorial_active or not current_tutorial:
		print("ERROR: Tutorial not active or tutorial data missing")
		return
	
	# Hide any active UI
	_hide_all_tutorial_ui()
	
	# Clear any active timer
	if tooltip_timer.is_inside_tree() and tooltip_timer.time_left > 0:
		tooltip_timer.stop()
	
	# Move to the next step
	current_step_index += 1
	print("Moving to step index: ", current_step_index)
	
	# Check if we've completed all steps
	if current_step_index >= current_tutorial.steps.size():
		print("Completed all steps, stopping tutorial")
		stop_current_tutorial()
		return
	
	# Show the current step
	var step = current_tutorial.steps[current_step_index]
	print("Showing step type: ", step.type)
	_show_step(step)
	
	# Emit signal for step activation
	step_activated.emit(current_step_index)

# Show a specific tutorial step
func _show_step(step: TutorialStep):
	match step.type:
		TutorialStep.StepType.MODAL:
			_show_modal_step(step)
		TutorialStep.StepType.TOOLTIP:
			_show_tooltip_step(step)
		TutorialStep.StepType.HIGHLIGHT:
			_show_highlight_step(step)
		TutorialStep.StepType.OBJECTIVE:
			_setup_objective_step(step)

# Show a modal dialog for a tutorial step
func _show_modal_step(step: TutorialStep):
	# Configure the modal
	modal_content.text = step.message
	modal_button.text = "CONTINUE"
	
	# Show the modal
	modal_container.visible = true
	modal_panel.visible = true
	
	# Center the panel
	_center_modal_panel()

# Show a tooltip for a tutorial step
func _show_tooltip_step(step: TutorialStep):
	# Find the target node
	var target_node = get_node_or_null(step.target_node_path)
	
	if not target_node:
		# Try to resolve from the most common paths
		var alternative_paths = [
			"/root/Main/CanvasLayer/HUD%s" % step.target_node_path,
			"/root/Main/CanvasLayer%s" % step.target_node_path,
			"/root/Main/MissionManager/MissionPanel%s" % step.target_node_path,
			"/root/Main%s" % step.target_node_path
		]
		
		for path in alternative_paths:
			target_node = get_node_or_null(path)
			if target_node:
				break
	
	if not target_node:
		print("Could not find target node for tooltip: %s" % step.target_node_path)
		# Schedule a delayed attempt in case the node isn't loaded yet
		delayed_tooltips[current_step_index] = step
		tooltip_timer.start(0.5)
		return
	
	# Configure the tooltip
	tooltip_content.text = step.message
	
	# Position tooltip relative to the target node
	var global_rect = target_node.get_global_rect() if target_node is Control else Rect2(Vector2.ZERO, Vector2.ZERO)
	if target_node is Node3D:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var screen_point = camera.unproject_position(target_node.global_position)
			global_rect = Rect2(screen_point - Vector2(25, 25), Vector2(50, 50))
	
	# Call position tooltip with the target node path
	_position_tooltip(global_rect, step.position_offset, step.target_node_path)
	
	# Show the tooltip
	tooltip_container.visible = true
	
	# Highlight the target if it's a Control node
	if target_node is Control:
		_highlight_control(target_node)
	
	# If not waiting for input, schedule next step
	if not step.wait_for_input:
		await get_tree().create_timer(3.0).timeout
		if is_tutorial_active and current_step_index < current_tutorial.steps.size():
			advance_to_next_step()

# Position the tooltip relative to a target rect
func _position_tooltip(target_rect: Rect2, offset: Vector2 = Vector2.ZERO, target_node_path: String = ""):
	if tooltip_panel and tooltip_pointer:
		# Wait for tooltip panel to update its minimum size
		await get_tree().process_frame
		
		# Calculate optimal position based on screen space
		var screen_size = get_viewport().get_visible_rect().size
		
		# Get the actual size of the panel
		tooltip_panel.show()  # Temporarily show to get proper size
		var tooltip_size = tooltip_panel.get_rect().size
		tooltip_panel.hide()  # Hide it again
		
		# For mission panel (right side of screen), position to the left of the panel
		var is_mission_panel = ("MissionPanel" in target_node_path) or (target_rect.position.x > screen_size.x * 0.7)
		var position_type = 0  # 0 = below, 1 = above, 2 = left, 3 = right
		
		if is_mission_panel:
			# Special case for mission panel - position to the left
			position_type = 2
		else:
			# Default is to position below
			position_type = 0
			
			# Check if there's enough space below
			if target_rect.position.y + target_rect.size.y + tooltip_size.y + 30 > screen_size.y:
				# Not enough space below, try above
				position_type = 1
		
		var pointer_position
		var panel_position
		
		match position_type:
			0:  # Below target
				pointer_position = Vector2(
					target_rect.position.x + target_rect.size.x / 2,
					target_rect.position.y + target_rect.size.y + 5
				)
				panel_position = Vector2(
					pointer_position.x - tooltip_size.x / 2,
					pointer_position.y + 15
				)
				tooltip_pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 15)])
				
			1:  # Above target
				pointer_position = Vector2(
					target_rect.position.x + target_rect.size.x / 2,
					target_rect.position.y - 5
				)
				panel_position = Vector2(
					pointer_position.x - tooltip_size.x / 2,
					pointer_position.y - tooltip_size.y - 15
				)
				tooltip_pointer.polygon = PackedVector2Array([Vector2(0, 15), Vector2(20, 15), Vector2(10, 0)])
				
			2:  # Left of target
				pointer_position = Vector2(
					target_rect.position.x - 5,
					target_rect.position.y + target_rect.size.y / 2
				)
				panel_position = Vector2(
					pointer_position.x - tooltip_size.x - 15,
					pointer_position.y - tooltip_size.y / 2
				)
				tooltip_pointer.polygon = PackedVector2Array([Vector2(15, 0), Vector2(15, 20), Vector2(0, 10)])
				
			3:  # Right of target
				pointer_position = Vector2(
					target_rect.position.x + target_rect.size.x + 5,
					target_rect.position.y + target_rect.size.y / 2
				)
				panel_position = Vector2(
					pointer_position.x + 15,
					pointer_position.y - tooltip_size.y / 2
				)
				tooltip_pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 20), Vector2(15, 10)])
		
		# Ensure tooltip doesn't go off-screen
		if panel_position.x < 10:
			panel_position.x = 10
		if panel_position.x + tooltip_size.x > screen_size.x - 10:
			panel_position.x = screen_size.x - tooltip_size.x - 10
		if panel_position.y < 10:
			panel_position.y = 10
		if panel_position.y + tooltip_size.y > screen_size.y - 10:
			panel_position.y = screen_size.y - tooltip_size.y - 10
		
		# Apply the offset
		panel_position += offset
		pointer_position += offset
		
		# Set the positions
		tooltip_panel.position = panel_position
		tooltip_pointer.position = pointer_position

# Show a highlight for a tutorial step
func _show_highlight_step(step: TutorialStep):
	# Find the target node
	var target_node = get_node_or_null(step.target_node_path)
	
	if not target_node:
		# Try to resolve from the most common paths
		var alternative_paths = [
			"/root/Main/CanvasLayer/HUD%s" % step.target_node_path,
			"/root/Main/CanvasLayer%s" % step.target_node_path,
			"/root/Main/CanvasLayer/Control/MissionPanel%s" % step.target_node_path,
			"/root/Main%s" % step.target_node_path
		]
		
		for path in alternative_paths:
			target_node = get_node_or_null(path)
			if target_node:
				break
	
	if not target_node or not (target_node is Control):
		print("Could not find target Control node for highlight: %s" % step.target_node_path)
		# Try again later
		delayed_tooltips[current_step_index] = step
		tooltip_timer.start(0.5)
		return
	
	# Highlight the control
	_highlight_control(target_node)
	
	# If not waiting for input, schedule next step
	if not step.wait_for_input:
		await get_tree().create_timer(2.0).timeout
		if is_tutorial_active and current_step_index < current_tutorial.steps.size():
			advance_to_next_step()

# Setup an objective step
func _setup_objective_step(step: TutorialStep):
	# Get the mission manager if needed
	if not mission_manager:
		mission_manager = get_node_or_null("/root/Main/MissionManager")
		if not mission_manager:
			print("Could not find mission manager for objective step")
			advance_to_next_step()  # Skip this step
			return
	
	# Attach to mission signals if needed
	if mission_manager.has_signal("objective_completed") and not mission_manager.is_connected("objective_completed", Callable(self, "_on_objective_completed")):
		mission_manager.connect("objective_completed", Callable(self, "_on_objective_completed"))
	
	# Store callback for this objective type
	step_completed_callbacks[step.objective_type] = current_step_index
	
	# Show tooltip if target node is provided
	if not step.target_node_path.is_empty():
		_show_tooltip_step(step)

# Highlight a control node
func _highlight_control(control: Control):
	if highlight_rect:
		# Get global rect of control
		var global_rect = control.get_global_rect()
		
		# Get the shader material if available
		var shader_rect = highlight_rect.get_node_or_null("HighlightColorRect")
		if shader_rect and shader_rect.material:
			# Set shader parameters for highlight position and size
			shader_rect.material.set_shader_parameter("highlight_position", global_rect.position)
			shader_rect.material.set_shader_parameter("highlight_size", global_rect.size)
		else:
			# Use the fallback border approach
			var border = highlight_rect.get_node_or_null("HighlightBorder")
			if border:
				border.position = global_rect.position
				border.size = global_rect.size
		
		# Show the highlight
		highlight_rect.visible = true

# Hide all tutorial UI elements
func _hide_all_tutorial_ui():
	modal_container.visible = false
	tooltip_container.visible = false
	highlight_rect.visible = false

# Center the modal panel in the viewport
func _center_modal_panel():
	# Panel is now automatically centered by the CenterContainer
	# This method is kept for compatibility but does nothing
	pass

# Event handlers
func _on_modal_button_pressed():
	print("Modal button pressed!")
	advance_to_next_step()

func _on_objective_completed(objective):
	# Check if we have a callback for this objective type
	if objective and step_completed_callbacks.has(objective.type):
		var step_index = step_completed_callbacks[objective.type]
		if step_index == current_step_index:
			# Remove the callback
			step_completed_callbacks.erase(objective.type)
			
			# Complete this step
			step_completed.emit(current_step_index)
			advance_to_next_step()

func _on_tooltip_timer_timeout():
	# Try to show delayed tooltips
	if delayed_tooltips.has(current_step_index):
		var step = delayed_tooltips[current_step_index]
		delayed_tooltips.erase(current_step_index)
		
		match step.type:
			TutorialStep.StepType.TOOLTIP:
				_show_tooltip_step(step)
			TutorialStep.StepType.HIGHLIGHT:
				_show_highlight_step(step)
	
	# If we still have delayed tooltips, try again soon
	if delayed_tooltips.size() > 0:
		tooltip_timer.start(0.5)