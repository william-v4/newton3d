extends Spatial
# body class
onready var body = preload("res://Body.tscn")
# or you'll be trapped forever
var paused : bool
# Obstacle class
onready var obstacle = preload("res://Obstacle.tscn")
# set up the world
func _ready():
	# make new a body class that will be you
	var player = body.instance()
	add_child(player)
	# tell the body that it is to be controlled by you
	player.init(true)
	# roll the dice
	randomize()
	# get the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# set up obstacles
	addwall(Vector3(0, -100, 0), Vector3.ZERO, "C")
	addwall(Vector3(0, 100, 0), Vector3.ZERO, "Bb")
	addwall(Vector3(100, 0, 0), Vector3(0, 0, -90), "Eb")
	addwall(Vector3(-100, 0, 0), Vector3(0, 0, -90), "F")
	addwall(Vector3(0, 0, 100), Vector3(90, 0, 0), "F#")
	addwall(Vector3(0, 0, -100), Vector3(90, 0, 0), "G")

# adds obstacles with parameters
func addwall(locate : Vector3, rotate: Vector3, sound : String):
	var wall = obstacle.instance()
	# prepare obstacle sound
	var file = "res://sounds/" + sound + ".wav"
	# make obstacle
	add_child(wall)
	# move obstacle to specified location see line 19
	wall.global_transform.origin = locate
	wall.rotation_degrees = rotate
	# set obstacle sound
	wall.get_node("AudioStreamPlayer3D").stream = load(file)

# runs continuously, delta being the time per frame
func _process(delta):
	# so that you can actually exit the game
	if Input.is_action_pressed("pause"):
		paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# and get back in
	if Input.is_mouse_button_pressed(1) and paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		paused = false
	# key detection
	for i in range(1, 10):
		# to prevent spamming
		var pressed : bool
		# purge planets first
		if Input.is_action_just_pressed(str(i)):
			removeplanets()
			# then make them
			for x in range(i):
				makerandomplanet()
			# line 54
			pressed = true
		# and let you press again
		if Input.is_action_just_released(str(i)):
			pressed = false
	# this is where the fun begins...
	if Input.is_action_just_pressed("clear"):
		blowplanets()
	# make random number of planets
	if Input.is_action_just_pressed("random"):
		removeplanets()
		for i in range(0, (randi() % 100)):
			makerandomplanet()

# purges all planets
func removeplanets():
	# get all objects in scene
	for x in get_children():
		# checks if it is a body but not you
		if "Body" in x.name && !x.star:
			# deletes them
			x.free()

# like the above function, but with added "effects"
func blowplanets():
	# for immersion
	Input.start_joy_vibration(0, 1, 1, 0.5)
	for x in get_children():
		if "Body" in x.name && !x.star:
			# special function that makes planet blow up instead of just deleting it
			x.byebye()

# make a random planet at a random location
func makerandomplanet():
	# roll the dice
	var random = RandomNumberGenerator.new()
	random.randomize()
	# prepare new planet
	var planet = body.instance()
	# make new planet
	add_child(planet)
	# generate and set size (which is also mass)
	var size = random.randi_range(1, 4)
	planet.size = size
	# tell the planet that it is not player controlled
	planet.init(false)
	# teleport the planet somewhere random within the 200x200x200 box
	planet.global_transform.origin = Vector3(random.randf_range(-100, 100), random.randf_range(-100, 100), random.randf_range(-100, 100))

# similar to above but with specified location
func makeplanet(location: Vector3):
	var random = RandomNumberGenerator.new()
	random.randomize()
	var planet = body.instance()
	add_child(planet)
	var size = random.randi_range(1, 4)
	planet.size = size
	planet.init(false)
	# set location to parameter
	planet.global_transform.origin = location

# spawn just one random planet with deleting the others
func _input(event):
	if Input.is_action_just_pressed("addr"):
		makerandomplanet()
