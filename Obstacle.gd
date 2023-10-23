extends Spatial
# time after every frame, useful for interpolation
var delta
# transparency of obstacle
var alpha : float

# run as soon as scene loaded
func _ready():
	# set transparancy
	alpha = 0.01

# run continuously
func _process(delta):
	# set global delta to delta
	delta = delta
	# see who's colliding
	for x in $Area.get_overlapping_bodies():
		# make sure it's a body
		if "Body" in x.get_parent().name:
			# turn opaque
			alpha = 0.5
			# play note (if not playing to prevent spamming)
			if !$AudioStreamPlayer3D.is_playing():
				$AudioStreamPlayer3D.play()
			# bounce body if it's not the player
			if !x.get_parent().star:
				# invert trajectory and divide by 2
				x.get_parent().global_transform.origin = -x.get_parent().targetorigin / 2
				# roll the dice
				var random = RandomNumberGenerator.new()
				random.randomize()
				# change the color of planet to another random color upon collision
				x.get_node("MeshInstance").mesh.surface_get_material(0).albedo_color = Color(random.randf(), random.randf(), random.randf(), 1)
	# gradually regain transparency after collision (it's cool)
	if alpha > 0.01:
		alpha -= 0.01
	# and make sure it's not invisible
	if alpha == 0:
		alpha = 0.01
	# actually apply the transparency to the obstacle
	$MeshInstance.mesh.surface_get_material(0).set_shader_param("alpha", alpha)
