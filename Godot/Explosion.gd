extends Node2D

func _ready():
	$Light.emitting = true
	$Bubbles.emitting = true
	$Debris.emitting = true
	
func _process(delta):
	if !$Bubbles.emitting && !$Debris.emitting && !$Light.emitting:
		queue_free()
