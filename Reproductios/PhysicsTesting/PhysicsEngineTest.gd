extends Node3D

# Test configuration
@export var object_count: int = 1000
@export var object_scene: PackedScene  # Assign a RigidBody3D scene in inspector
@export var spawn_height: float = 10.0
@export var spawn_area: Vector2 = Vector2(20, 20)

# UI references
@onready var current_fps_label = $UI/MarginContainer/VBoxContainer/CurrentFPSLabel
@onready var current_frame_time_label = $UI/MarginContainer/VBoxContainer/CurrentFrameTimeLabel
@onready var final_fps_label = $UI/MarginContainer/VBoxContainer/FinalFPSLabel
@onready var final_frame_time_label = $UI/MarginContainer/VBoxContainer/FinalFrameTimeLabel
@onready var start_button = $UI/MarginContainer/VBoxContainer/StartButton

# Test state
var test_running: bool = false
var test_started: bool = false
var settle_time: float = 5.0  # Time to wait for objects to settle
var current_settle_time: float = 0.0
var frame_times: Array[float] = []
var spawned_objects: Array = []

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	current_fps_label.text = "Current FPS: --"
	current_frame_time_label.text = "Current Frame Time: -- ms"
	final_fps_label.text = "Final Average FPS: --"
	final_frame_time_label.text = "Final Average Frame Time: -- ms"

func _process(delta):
	if test_running:
		# Record frame time
		var frame_time_ms = delta * 1000.0
		frame_times.append(frame_time_ms)
		
		# Update current values
		var current_fps = Engine.get_frames_per_second()
		current_fps_label.text = "Current FPS: %d" % current_fps
		current_frame_time_label.text = "Current Frame Time: %.2f ms" % frame_time_ms
		
		# Check if objects have settled
		if test_started:
			current_settle_time += delta
			if current_settle_time >= settle_time:
				_finalize_test()

func _on_start_button_pressed():
	if test_running:
		return
	
	start_button.disabled = true
	_spawn_objects()
	test_running = true
	test_started = true
	frame_times.clear()
	current_settle_time = 0.0

func _spawn_objects():
	# Seed the random number generator for reproducible results
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed = same "random" pattern every time
	
	for i in range(object_count):
		if object_scene:
			var obj = object_scene.instantiate()
			
			# Random position with seeded RNG
			var random_x = rng.randf_range(-spawn_area.x / 2, spawn_area.x / 2)
			var random_z = rng.randf_range(-spawn_area.y / 2, spawn_area.y / 2)
			var random_y = rng.randf_range(spawn_height, spawn_height + 5.0)
			obj.position = Vector3(random_x, random_y, random_z)
			
			# Random rotation using seeded RNG
			obj.rotation = Vector3(
				rng.randf_range(0, TAU),
				rng.randf_range(0, TAU),
				rng.randf_range(0, TAU)
			)
			
			add_child(obj)
			
			# Random initial velocities using seeded RNG
			if obj is RigidBody3D:
				obj.angular_velocity = Vector3(
					rng.randf_range(-5, 5),
					rng.randf_range(-5, 5),
					rng.randf_range(-5, 5)
				)
				obj.linear_velocity = Vector3(
					rng.randf_range(-1, 1),
					0,
					rng.randf_range(-1, 1)
				)
			
			spawned_objects.append(obj)

func _finalize_test():
	test_running = false
	test_started = false
	
	# Calculate averages
	var total_frame_time: float = 0.0
	for ft in frame_times:
		total_frame_time += ft
	
	var avg_frame_time = total_frame_time / frame_times.size()
	var avg_fps = 1000.0 / avg_frame_time  # Convert ms to FPS
	
	# Display final results
	final_fps_label.text = "Final Average FPS: %.2f" % avg_fps
	final_frame_time_label.text = "Final Average Frame Time: %.2f ms" % avg_frame_time
	
	print("Test Complete!")
	print("Average FPS: %.2f" % avg_fps)
	print("Average Frame Time: %.2f ms" % avg_frame_time)
	print("Total frames recorded: %d" % frame_times.size())

# Optional: Function to clear objects and reset test
func reset_test():
	for obj in spawned_objects:
		obj.queue_free()
	spawned_objects.clear()
	frame_times.clear()
	current_settle_time = 0.0
	test_running = false
	test_started = false
	start_button.disabled = false
