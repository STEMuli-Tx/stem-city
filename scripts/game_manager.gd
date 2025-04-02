extends Node

# This script handles overall game management tasks

# Components
var controls_panel
var hud
var mission_manager
var tutorial_manager
var builder

func _ready():
	# References to key components
	controls_panel = $CanvasLayer/ControlsPanel
	hud = $CanvasLayer/HUD
	mission_manager = $MissionManager
	tutorial_manager = $TutorialManagerScene
	builder = $Builder
	
	# Set up the HUD's reference to the controls panel
	if hud and controls_panel:
		hud.controls_panel = controls_panel
		
	# Register tooltips with the tutorial manager
	if tutorial_manager:
		# Find all the tooltips in the scene and register them with their parent paths
		_register_tooltips_with_manager()
	
	# Wait for a short delay before starting tutorials
	# This gives the scene time to fully load and render
	await get_tree().create_timer(0.5).timeout
	
	# Don't auto-show controls if tutorial is active
	if controls_panel:
		# Only connect the signal, don't show the panel
		controls_panel.closed.connect(_on_controls_panel_closed)
		
		# We'll show the controls panel after the tutorial is completed
		# controls_panel.show_panel()
	
	# Connect tutorial manager signals
	if tutorial_manager:
		tutorial_manager.tutorial_started.connect(_on_tutorial_started)
		tutorial_manager.tutorial_completed.connect(_on_tutorial_completed)
		
		# Set mission manager reference
		if mission_manager:
			tutorial_manager.mission_manager = mission_manager

# This function is called when the controls panel is closed
func _on_controls_panel_closed():
	print("Controls panel closed by player")

# Tutorial system signal handlers
func _on_tutorial_started(tutorial_id: String):
	print("Tutorial started: ", tutorial_id)
	
	# Disable builder while tutorial is active
	if builder:
		builder.disabled = true

func _on_tutorial_completed(tutorial_id: String):
	print("Tutorial completed: ", tutorial_id)
	
	# Re-enable builder when tutorial ends
	if builder:
		builder.disabled = false
		
	# Show controls panel after tutorial completes
	if controls_panel and tutorial_id == "welcome":
		controls_panel.show_panel()

# Function to register tooltips with the tutorial manager
func _register_tooltips_with_manager():
	# Register the mission panel tooltip
	var mission_panel_tooltip = get_node_or_null("/root/Main/MissionManager/MissionPanel/Tooltip")
	if mission_panel_tooltip:
		tutorial_manager.register_tooltip("/root/Main/MissionManager/MissionPanel", mission_panel_tooltip)
	
	# Register the stats panel tooltip
	var stats_tooltip = get_node_or_null("/root/Main/CanvasLayer/HUD/HBoxContainer/Tooltip")
	if stats_tooltip:
		tutorial_manager.register_tooltip("/root/Main/CanvasLayer/HUD/HBoxContainer", stats_tooltip)
	
	# Register the electricity tooltip
	var electricity_tooltip = get_node_or_null("/root/Main/CanvasLayer/HUD/HBoxContainer/ElectricityItem/Tooltip")
	if electricity_tooltip:
		tutorial_manager.register_tooltip("/root/Main/CanvasLayer/HUD/HBoxContainer/ElectricityItem", electricity_tooltip)
	
	# Register the help button tooltip
	var help_tooltip = get_node_or_null("/root/Main/CanvasLayer/HUD/HBoxContainer/HelpItem/HelpButton/Tooltip")
	if help_tooltip:
		tutorial_manager.register_tooltip("/root/Main/CanvasLayer/HUD/HBoxContainer/HelpItem/HelpButton", help_tooltip)