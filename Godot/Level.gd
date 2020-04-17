extends Node2D

const EXPLOSION_SCENE = preload("res://Explosion.tscn")
const SUB_PLACEMENT = Rect2(30, 120, 860, 770)
const MINEFIELD_START = 1000
const TOP_SPEED = 200
const FALL_ACCELERATION = 100
const GROUND_HEIGHT = 920
const MIN_OPERATING_Y = 88
const MAX_OPERATING_Y = 890
const SCREEN_WIDTH = 1920
const COLLISION_DISTANCE = 20
const EXPLOSION_RANGE = 50

export var num_subs = 0
export var num_mines = 0
export var minefield_width = 0

var displacement_map = preload("res://Textures/displacement_map.png").get_data()
var displacement_map_width = int(displacement_map.get_size().x)
var displacement_map_scroll = 0

var subs = []
var mines = []
var initial_rightmost_mine = 0

# Used for both mines and submarines
class OceanObject:
	var position = Vector2()
	var velocity = Vector2()
	var depth = 0
	var destroyed = false
	
	func _init(position, depth):
		self.position = position
		self.depth = depth

func _ready():
	displacement_map.lock()
	
	# Place submarines
	
	$Submarines.multimesh.instance_count = num_subs
	for i in range(num_subs):
		var position = Vector2(rand_range(SUB_PLACEMENT.position.x, SUB_PLACEMENT.end.x),
			rand_range(SUB_PLACEMENT.position.y, SUB_PLACEMENT.end.y))
		
		var depth = 1 - float(i) / num_subs
		subs.append(OceanObject.new(position, depth))
		$Submarines.multimesh.set_instance_custom_data(i, Color(depth, 1, 1, 1))
		
	# Place mines
	
	$Mines.multimesh.instance_count = num_mines
	for i in range(num_mines):
		var position = Vector2(rand_range(MINEFIELD_START, MINEFIELD_START + minefield_width),
			rand_range(SUB_PLACEMENT.position.y, SUB_PLACEMENT.end.y))
		
		var depth = 1 - float(i) / num_mines
		mines.append(OceanObject.new(position, depth))
		$Mines.multimesh.set_instance_custom_data(i, Color(depth, 1, 1, 1))
		
		initial_rightmost_mine = max(initial_rightmost_mine, position.x)

func _process(delta):
	# Update positions in multimeshes
	
	for i in range(num_subs):
		var transform = Transform2D(0, subs[i].position)
		$Submarines.multimesh.set_instance_transform_2d(i, transform)
		
	for i in range(num_mines):
		var transform = Transform2D(0, mines[i].position)
		$Mines.multimesh.set_instance_transform_2d(i, transform)
		
func _physics_process(delta):
	displacement_map_scroll += delta
	
	# Move submarines
	
	for sub in subs:
		if sub.destroyed:
			if sub.position.y < GROUND_HEIGHT:
				# Fall
				sub.velocity.y += delta * FALL_ACCELERATION
				sub.position += sub.velocity * delta
				sub.position.y = clamp(sub.position.y, 0, GROUND_HEIGHT)
				
				# Slow horizontal movement
				sub.velocity.x -= min(sub.velocity.x, delta * 5)
				
			# Move with the ground, more or less
			sub.position.x -= delta * 100
			
		else:
			# Decelerate gradually
			var speed = sub.velocity.length()
			speed -= min(speed, delta * 5)
			sub.velocity = min(speed, TOP_SPEED) * sub.velocity.normalized()
			
			# Accelerate via water displacement map
			var displacement_sample_x = int(sub.position.x + displacement_map_scroll) % displacement_map_width
			var displacement = displacement_map.get_pixel(displacement_sample_x, sub.position.y)
			sub.velocity += Vector2(displacement.r - 0.5, displacement.g - 0.5).normalized() * delta * (3 + sub.depth * 3)
			
			# Update position
			sub.position += sub.velocity * delta
			if sub.position.y < MIN_OPERATING_Y:
				sub.position.y = MIN_OPERATING_Y
				sub.velocity.y = abs(sub.velocity.y)
			elif sub.position.y > MAX_OPERATING_Y:
				sub.position.y = MAX_OPERATING_Y
				sub.velocity.y = -abs(sub.velocity.y)
			if sub.position.x < 0:
				sub.position.x = 0
				sub.velocity.x = abs(sub.velocity.x)
			elif sub.position.x > SCREEN_WIDTH:
				sub.position.x = SCREEN_WIDTH
				sub.velocity.x = -abs(sub.velocity.x)
				
	# Move mines and check collisions
	
	var rightmost_mine = 0
	for mine in mines:
		if mine.destroyed:
			continue
			
		mine.position.x -= delta * 40
		rightmost_mine = max(rightmost_mine, mine.position.x)
		
		# Check collisions
		
		for sub in subs:
			var dist = (sub.position - mine.position).length()
			if dist < COLLISION_DISTANCE:
				# Spawn an explosion
				var boom = EXPLOSION_SCENE.instance()
				boom.set_position(mine.position)
				add_child(boom)
				
				mine.destroyed = true
				
		# Destroy nearby subs if detonated
		
		if mine.destroyed:
			for sub in subs:
				if sub.destroyed:
					continue
				
				var dist = (sub.position - mine.position).length()
				if dist < EXPLOSION_RANGE:
					sub.destroyed = true
					$HUD.sub_destroyed()
					
			mine.position.y = -100
			
	$HUD.set_progress(1 - rightmost_mine / initial_rightmost_mine)

func pull(from, magnitude):
	for sub in subs:
		if sub.destroyed:
			continue
			
		var delta = from - sub.position
		sub.velocity += delta.normalized() * magnitude
