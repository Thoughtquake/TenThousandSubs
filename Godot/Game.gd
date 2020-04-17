extends Node2D

const LEVEL_SCENE = preload("res://Level.tscn")

const PULL_MAGNITUDE = 20

func _input(event):
	if event is InputEventMouseButton && !event.is_pressed():
		if $TitleImage.visible:
			$TitleImage.visible = false
			add_child_below_node($NoiseLayer, LEVEL_SCENE.instance())
		else:
			assert($Level)
			if $Level && $Level/HUD/EndText.visible:
				$Level.queue_free()
				remove_child($Level)
				add_child_below_node($NoiseLayer, LEVEL_SCENE.instance())
			else:
				var multiplier = PULL_MAGNITUDE if event.button_index == BUTTON_LEFT else -PULL_MAGNITUDE
				$Level.pull(event.position, multiplier)
