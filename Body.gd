extends Spatial
# if it is player controlled or not
var star : bool
# mouse sensitivity
var mousesens : int = 5
# stores mouse movement data
var mousemotion : Vector2

var speed : float = 0.01
# stores player movement data
var direction : Vector3
# size of body, used as mass too
var size : int
# for setting the color of a planet
var material : SpatialMaterial = SpatialMaterial.new()
# to run its last functions
var selfdestruct : bool
# joystick sensitivity
var sticksens : float = 2
# trajectory coordinates
var targetorigin : Vector3
# time for each frame, useful for interpolation
var delta : float

# setup based on if it is a star(player) or not
func init(isstar: bool):
	# sets global variable (line 3) to received parameter
	star = isstar
	# if the created body is a player
	if isstar:
		size = 5
		# a special material that looks like the sun
		$RigidBody/MeshInstance.mesh = preload("res://star.tres")
		# scales the body to size
		global_scale(Vector3(5, 5, 5))
	# if the created body is a planet
	else: 
		# prepare and play a pop sound (btw it's the scratch pop sound)
		$AudioStreamPlayer3D.stream = preload("res://sounds/Pop.wav")
		$AudioStreamPlayer3D.play(0)
		# remove camera and light cause these are exclusive to the player
		remove_child($Camera)
		remove_child($OmniLight)
		# scale the planet to the appropriate size
		global_scale(Vector3(size, size, size))
		# roll the dice
		var random = RandomNumberGenerator.new()
		random.randomize()
		# randomize color
		material.albedo_color = Color(random.randf(),random.randf(), random.randf(), 1)
		# set emission (for a subtle glow and used during boom)
		material.emission = Color(1, 1, 1)
		material.emission_enabled = true
		# limit glow
		material.emission_energy = 0.02
		# give it some reflectivity
		material.metallic = 1
		# and apply the above visual properties on the planet
		$RigidBody/MeshInstance.mesh.surface_set_material(0, material)

# run continuously, with delta being time per frame
func _process(delta):
	# set global delta line 22
	delta = delta
	# movement code in relation to local axis, see Project > Project Settings > Input Map for controls
	if star:
		if Input.is_action_pressed("forward"): 
			direction.z -= speed
			direction -= transform.basis.z.normalized()
		if Input.is_action_pressed("back"):
			direction.z += speed
			direction += transform.basis.z.normalized()
		if Input.is_action_pressed("left"):
			direction.x -= speed
			direction -= transform.basis.x.normalized()
		if Input.is_action_pressed("right"):
			direction.x += speed
			direction += transform.basis.x.normalized()
		if Input.is_action_pressed("up"):
			direction.y += speed
			direction += transform.basis.y.normalized()
		if Input.is_action_pressed("down"):
			direction.y -= speed
			direction -= transform.basis.y.normalized()
		# actually move the player
		global_transform.origin = direction
		# joystick controls
		var stickdir = Input.get_vector("camleft", "camright", "camup", "camdown")
		# left and right
		rotate_y(-deg2rad(stickdir.x)*sticksens)
		# up and down
		$Camera.rotate_x(clamp(-deg2rad(stickdir.y)*sticksens, -90, 90))
	# movement code for planets
	else: 
		# apply gravity
		for x in get_parent().get_children():
			# find bodies and limit gravity to distance
			if "Body" in x.name && global_transform.origin.distance_to(x.global_transform.origin) > 5:
				# calculate new location based on location of other bodies, distnace to them, and their gravities
				targetorigin = global_transform.origin.linear_interpolate(x.global_transform.origin, delta / (global_transform.origin.distance_to(x.global_transform.origin) * 1) * x.size)
				# face the new location
				look_at(targetorigin, Vector3.UP)
		# move the planet
		global_transform.origin = targetorigin
		# planet go boom when about to delete (when explosion sound playing and selfdestruct true)
		if $AudioStreamPlayer3D.playing and selfdestruct:
			# set explosioin color to current color
			$RigidBody/MeshInstance.mesh.surface_get_material(0).emission = $RigidBody/MeshInstance.mesh.surface_get_material(0).albedo_color
			# gradually increase brigthness
			$RigidBody/MeshInstance.mesh.surface_get_material(0).emission_energy += 16 * delta * 10
			# gradually grow radius
			$RigidBody/MeshInstance.mesh.radius += 20 * delta * 10
			# gradually grow height
			$RigidBody/MeshInstance.mesh.height = $RigidBody/MeshInstance.mesh.radius * 2

# run when user presses controls
func _input(event):
	# camera control for player
	if event is InputEventMouseMotion and star:
		# get mouse movement
		mousemotion = -event.relative
		mousemotion = mousemotion.normalized()
		# rotate camera up and down
		$Camera.rotate_x(deg2rad(clamp(mousemotion.y, -90, 90)))
		# rotate player left and right
		rotate_y(deg2rad(mousemotion.x * mousesens))
	# spawn one planet without deleting others
	if Input.is_action_just_pressed("spawn") and star:
		spawner()
	# delete nearby planet
	if Input.is_action_just_pressed("delete") and star:
		# get all adjacent planets that is not you
		for x in $Area.get_overlapping_bodies():
			if "Body" in x.name and x.get_parent() != self:
				# Among Us kill sound and turn up volume
				$AudioStreamPlayer3D.set_unit_db(20)
				$AudioStreamPlayer3D.stream = preload("res://sounds/impostor_kill.wav")
				$AudioStreamPlayer3D.play()
				# for immersize boom
				Input.start_joy_vibration(0, 1, 1, 0.5)
				# mute the explosion sound so the kill sound can be heard
				x.get_parent().get_node("AudioStreamPlayer3D").set_unit_db(-80.00)
				# explode
				x.get_parent().byebye()

# explosion code
func byebye():
	# let the planet know it's about to die (line 105)
	selfdestruct = true
	# load and play explosion sound (btw it's the Minecraft TNT explosion sound)
	$AudioStreamPlayer3D.stream = preload("res://sounds/explosion.wav")
	$AudioStreamPlayer3D.play()
	# wait until explosion done
	yield($AudioStreamPlayer3D, "finished")
	# reset volume just in case it was muted in line 140
	$AudioStreamPlayer3D.set_unit_db(0)
	# ejected
	queue_free()

# spawn a planet in your location without deleting others
func spawner():
	# get current location
	var loc = self.global_transform.origin
	# spawn planet here
	get_parent().makeplanet(loc)
