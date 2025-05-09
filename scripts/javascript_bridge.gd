@tool
extends Node

# Make this a singleton
static var instance = null

# Signals
signal init_data_received(data)
signal init_check_received
signal mission_progress_updated(data)
signal mission_completed(data)
signal open_react_graph(data)
signal open_react_table(data)

# Variables
var _interface = null
var _init_data = null
var _init_check_received = false
var _pending_signals = []
var window = null

func _init():
	instance = self

# This script provides a bridge to JavaScript functionality
# while gracefully handling platforms that don't support it

func _ready():
	# Only set up JavaScript interface if we're in a web export
	if OS.has_feature("web"):
		_setup_javascript_interface()
	else:
		print("JavaScript bridge initialized in non-web environment")

func _setup_javascript_interface():
	if not Engine.has_singleton("JSBridge"):
		push_error("JSBridge singleton not available")
		return
		
	var js = Engine.get_singleton("JSBridge")
	window = js.get_interface("window")
	
	# Wait for the interface to be available
	await get_tree().process_frame
	receive_init_data("test")

	# Set up message listener and interface
	js.eval("""
		window.addEventListener('message', function(event) {
			if (event.data && event.data.source === 'react-app') {
				window.godot_interface.emit_signal(event.data.type, event.data.data);
			}
		});
	""")

	# Set up the interface
	_interface = js.get_interface()
	print("JavaScript interface initialized")

	# Set up callbacks in JavaScript
	js.eval("""
		window.godot_interface._callbacks.init_data_received = function(data) {
			console.log('Emitting init_data_received signal with data:', data);
			// Don't re-emit the signal to avoid recursion
			window.godot_interface._callbacks.init_data_received = null;
		};
		window.godot_interface._callbacks.init_check_received = function() {
			console.log('Emitting init_check_received signal');
			// Don't re-emit the signal to avoid recursion
			window.godot_interface._callbacks.init_check_received = null;
		};
		window.godot_interface._callbacks.mission_progress_updated = function(data) {
			window.godot_interface.emit_signal('mission_progress_updated', data);
		};
		window.godot_interface._callbacks.mission_completed = function(data) {
			window.godot_interface.emit_signal('mission_completed', data);
		};
		window.godot_interface._callbacks.open_react_graph = function(data) {
			window.godot_interface.emit_signal('open_react_graph', data);
		};
		window.godot_interface._callbacks.open_react_table = function(data) {
			window.godot_interface.emit_signal('open_react_table', data);
		};
	""")
	print("JavaScript callbacks set up")

	# Process any pending signals
	_process_pending_signals()

func receive_init_data(missions_data):
	# First, let's properly log the missions_data itself
	print("Received missions data:", JSON.stringify(missions_data))

	# To get URL information, we need to extract specific properties from window.location
	if window and window.location:
		# Access specific properties of the location object
		var js = Engine.get_singleton("JSBridge")
		var href = js.eval("window.location.href")
		var search = js.eval("window.location.search")
		var hostname = js.eval("window.location.hostname")

		print("URL href:", href)
		print("URL search params:", search)
		print("URL hostname:", hostname)

		# Parse URL parameters more directly
		var params_str = js.eval("""
			(function() {
				var result = {};
				var params = new URLSearchParams(window.location.search);
				params.forEach(function(value, key) {
					result[key] = value;
				});
				return JSON.stringify(result);
			})()
		""")

		# Parse the JSON string to get a Dictionary
		var params = JSON.parse_string(params_str)
		print("URL parameters:", params)

		# Now access and process the missions parameter if it exists
		if params and "missions" in params:
			var missions_json = params["missions"]
			var missions = JSON.parse_string(missions_json)
			print("Missions from URL:", missions)
			var mission_data = {"missions": missions}
			get_node("/root/Globals").receive_data_from_browser(mission_data)

	# Also process the directly passed missions_data
	if missions_data and missions_data != "test":
		print("Processing passed missions data")
		emit_signal("init_data_received", missions_data)

func _process_pending_signals():
	if _pending_signals.size() > 0:
		print("Processing pending signals...")
		for signal_data in _pending_signals:
			emit_signal(signal_data.signal_name, signal_data.data)
		_pending_signals.clear()
		print("All pending signals processed")

# Static methods for interface checks
static func has_interface() -> bool:
	return Engine.has_singleton("JSBridge")

static func get_interface():
	return Engine.get_singleton("JSBridge")
	
# Helper method to convert Godot Dictionary to JSON string
static func JSON_stringify(data) -> String:
	return JSON.stringify(data)

static func send_open_graph(graph_data: Dictionary):
	if not instance:
		push_error("JSBridge not initialized; cannot send_open_graph")
		return
		
	# Format the message to match what React expects
	var message = {
		"source": "godot-game",
		"type": "open_react_graph",
		"data": graph_data
	}
	
	# Then, send the message directly to React via postMessage for external listeners
	if OS.has_feature("web"):
		var message_json = JSON_stringify(message)
		var script = """
		(function() {
			try {
				if (window.parent) {
					console.log('Sending missionStarted message to parent window');
					window.parent.postMessage({ 
						type: 'open_react_graph',
						data: %s,
						source: 'godot-game',
						timestamp: Date.now()
					}, '*');
				} else {
					console.log('No parent window found for missionStarted event');
				}
			} catch (e) {
				console.error('Error sending missionStarted via postMessage:', e);
			}
		})();
		""" % message_json

		if Engine.has_singleton("JSBridge"):
			var js = Engine.get_singleton("JSBridge")
			js.eval(script)

static func send_open_table(table_data: Dictionary):
	if not instance:
		push_error("JSBridge not initialized; cannot send_open_table")
		return
		
	# Format the message to match what React expects
	var message = {
		"source": "godot-game", 
		"type": "open_react_table",
		"data": table_data
	}
	
	# Then, send the message directly to React via postMessage for external listeners
	if OS.has_feature("web"):
		var message_json = JSON_stringify(message)
		var script = """
		(function() {
			try {
				if (window.parent) {
					console.log('Sending missionStarted message to parent window');
					window.parent.postMessage({ 
						type: 'open_react_table',
						data: %s,
						source: 'godot-game',
						timestamp: Date.now()
					}, '*');
				} else {
					console.log('No parent window found for missionStarted event');
				}
			} catch (e) {
				console.error('Error sending missionStarted via postMessage:', e);
			}
		})();
		""" % message_json

		if Engine.has_singleton("JSBridge"):
			var js = Engine.get_singleton("JSBridge")
			js.eval(script)
		else:
			print("JSBridge singleton not available")
		
	else:
		# For non-web platforms, add to pending signals
		instance._pending_signals.append({"signal_name": "open_react_table", "data": table_data})
