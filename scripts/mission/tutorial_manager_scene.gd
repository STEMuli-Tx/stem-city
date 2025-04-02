extends Node
class_name TutorialManagerScene

signal tutorial_started(tutorial_id: String)
signal tutorial_completed(tutorial_id: String)
signal step_activated(step_index: int)
signal step_completed(step_index: int)

@export var tutorials: Array[TutorialData] = []
@export var active_on_start: bool = true  # Whether to start the welcome tutorial automatically

# References to UI components (obtained from the scene tree, not created)
var modal: Control
var tooltips: Dictionary = {}  # node_path: tooltip_control
var mission_manager: MissionManager

# State tracking
var current_tutorial: TutorialData
var current_step_index: int = -1
var is_tutorial_active: bool = false
var step_completed_callbacks: Dictionary = {}

func _ready():
	# Get the modal reference (child of the TutorialLayer)
	modal = $TutorialLayer/TutorialModal
	
	# Connect to modal signals
	if modal and modal.has_signal("continue_pressed"):
		if not modal.is_connected("continue_pressed", Callable(self, "_on_modal_continue_pressed")):
			modal.continue_pressed.connect(_on_modal_continue_pressed)
	
	# Start the first tutorial if configured
	if active_on_start:
		# Wait for scene to fully initialize
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Find and start the welcome tutorial
		for tutorial in tutorials:
			if tutorial.id == "welcome":
				start_tutorial(tutorial)
				break

# Called to register a tooltip UI element with the manager
func register_tooltip(node_path: String, tooltip: Control):
	tooltips[node_path] = tooltip

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
	if modal:
		modal.show_modal(step.message)

# Show a tooltip for a tutorial step
func _show_tooltip_step(step: TutorialStep):
	var tooltip = _get_tooltip_for_path(step.target_node_path)
	if tooltip:
		# Set tooltip message and show it
		tooltip.message = step.message
		tooltip.show_tooltip()
		
		# If not waiting for input, schedule next step
		if not step.wait_for_input:
			await get_tree().create_timer(3.0).timeout
			if is_tutorial_active and current_step_index < current_tutorial.steps.size():
				advance_to_next_step()
	else:
		print("Could not find tooltip for: ", step.target_node_path)
		# Skip this step since we can't show the tooltip
		advance_to_next_step()

# Show a highlight for a tutorial step
func _show_highlight_step(step: TutorialStep):
	var tooltip = _get_tooltip_for_path(step.target_node_path)
	if tooltip:
		# Show the tooltip without message
		tooltip.message = ""
		tooltip.show_tooltip()
		
		# If not waiting for input, schedule next step
		if not step.wait_for_input:
			await get_tree().create_timer(2.0).timeout
			if is_tutorial_active and current_step_index < current_tutorial.steps.size():
				advance_to_next_step()
	else:
		print("Could not find tooltip for highlight: ", step.target_node_path)
		# Skip this step since we can't highlight
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
		mission_manager.objective_completed.connect(_on_objective_completed)
	
	# Store callback for this objective type
	step_completed_callbacks[step.objective_type] = current_step_index
	
	# Show tooltip if target node is provided
	if not step.target_node_path.is_empty():
		_show_tooltip_step(step)

# Get tooltip for a specific path or try to find it
func _get_tooltip_for_path(path: String) -> Control:
	# Check if we already have this tooltip registered
	if tooltips.has(path):
		return tooltips[path]
	
	# Try to find the tooltip at the node's path with "Tooltip" appended
	var tooltip_path = path + "/Tooltip"
	var tooltip = get_node_or_null(tooltip_path)
	
	if tooltip:
		# Register it for future use
		tooltips[path] = tooltip
		return tooltip
	
	# Try with common path prefixes
	var common_prefixes = [
		"/root/Main/",
		"/root/Main/CanvasLayer/",
		"/root/Main/MissionManager/"
	]
	
	for prefix in common_prefixes:
		tooltip_path = prefix + path + "/Tooltip"
		tooltip = get_node_or_null(tooltip_path)
		if tooltip:
			tooltips[path] = tooltip
			return tooltip
	
	# Not found
	return null

# Hide all tutorial UI elements
func _hide_all_tutorial_ui():
	# Hide modal
	if modal:
		modal.hide_modal()
	
	# Hide all tooltips
	for tooltip in tooltips.values():
		if tooltip and tooltip.has_method("hide_tooltip"):
			tooltip.hide_tooltip()

# Event handlers
func _on_modal_continue_pressed():
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